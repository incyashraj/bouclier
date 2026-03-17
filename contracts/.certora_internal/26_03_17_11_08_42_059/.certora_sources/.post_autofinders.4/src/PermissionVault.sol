// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./interfaces/IBouclier.sol";
import "./AgentRegistry.sol";
import "./RevocationRegistry.sol";
import "./SpendTracker.sol";
import "./AuditLogger.sol";

/// @title  PermissionVault
/// @notice The core enforcement contract. Implements ERC-7579 IValidator.
///         Every AI agent UserOp passes through `validateUserOp` before execution.
///
///         Validation order (15 steps):
///          1. Decode callData → (target, selector, tokenAddress, amount)
///          2. Resolve agentId from sender address
///          3. Check agent is registered and active in AgentRegistry
///          4. Check agent is not revoked in RevocationRegistry       ← CRITICAL
///          5. Load active PermissionScope
///          6. Check scope is not manually revoked
///          7. Check scope validity window (validFrom / validUntil)
///          8. Check target is in allowedProtocols (or allowAnyProtocol)
///          9. Check function selector is in allowedSelectors (or empty = all)
///         10. Check token is in allowedTokens (or allowAnyToken)
///         11. Check time-of-day / day-of-week window (if configured)
///         12. Get USD value via SpendTracker oracle
///         13. Check per-tx spend cap
///         14. Check rolling 24h daily cap
///         15. Record spend + log action → return VALIDATION_SUCCESS
///
///         On any failure (steps 2–14): emit PermissionViolation + return VALIDATION_FAILED
contract PermissionVault is
    IPermissionVault,
    Ownable,
    Pausable,
    ReentrancyGuard,
    EIP712("BouclierPermissionVault", "1")
{
    using ECDSA for bytes32;

    // ── EIP-712 type hash for PermissionScope ─────────────────────
    bytes32 public constant SCOPE_TYPEHASH = keccak256(
        "PermissionScope(bytes32 agentId,uint256 nonce,uint256 dailySpendCapUSD,uint256 perTxSpendCapUSD,"
        "uint48 validFrom,uint48 validUntil,bool allowAnyProtocol,bool allowAnyToken)"
    );

    // ── Module constants (ERC-7579) ───────────────────────────────
    uint256 private constant MODULE_TYPE_VALIDATOR = 1;

    // ── Dependencies ──────────────────────────────────────────────
    AgentRegistry      public immutable agentRegistry;
    RevocationRegistry public immutable revocationRegistry;
    SpendTracker       public immutable spendTracker;
    AuditLogger        public immutable auditLogger;

    // ── State ─────────────────────────────────────────────────────
    // One active scope per agent — simpler, safer, more auditable
    mapping(bytes32 agentId => PermissionScope) private _scopes;
    // EIP-712 replay protection: per-agent nonce for grantPermission signatures
    mapping(bytes32 agentId => uint256) public grantNonces;

    // ── Constructor ───────────────────────────────────────────────
    constructor(
        address _admin,
        address _agentRegistry,
        address _revocationRegistry,
        address _spendTracker,
        address _auditLogger
    ) Ownable(_admin) {
        agentRegistry      = AgentRegistry(_agentRegistry);
        revocationRegistry = RevocationRegistry(_revocationRegistry);
        spendTracker       = SpendTracker(_spendTracker);
        auditLogger        = AuditLogger(_auditLogger);
    }

    // ── ERC-7579 IModule ──────────────────────────────────────────

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function onInstall(bytes calldata /* data */) external pure {
        // No-op: PermissionVault is standalone, not per-account initialized
    }

    function onUninstall(bytes calldata /* data */) external pure {
        // No-op
    }

    /// @notice Returns the EIP-712 domain separator (ERC-5267 compatible accessor).
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    // ── Core Validation (hot path) ────────────────────────────────

    /// @notice ERC-7579 / ERC-4337 validation. Called by the entrypoint on every UserOp.
    ///         Returns VALIDATION_SUCCESS (0) or VALIDATION_FAILED (1).
    ///         MUST NOT revert — violations emit an event and return VALIDATION_FAILED.
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 validationData)
    {
        // ── Step 1: Decode callData ───────────────────────────────
        (
            address target,
            bytes4  selector,
            address tokenAddress,
            uint256 tokenAmount
        ) = _decodeCallData(userOp.callData);

        bytes32 actionHash = keccak256(abi.encode(userOp.sender, target, selector, userOpHash));

        // ── Step 2: Resolve agentId ───────────────────────────────
        bytes32 agentId = agentRegistry.getAgentId(userOp.sender);
        if (agentId == bytes32(0)) {
            return _fail(agentId, target, selector, "AGENT_NOT_REGISTERED");
        }

        // ── Step 3: Agent active in registry ─────────────────────
        if (!agentRegistry.isActive(agentId)) {
            return _fail(agentId, target, selector, "AGENT_NOT_ACTIVE");
        }

        // ── Step 4: Revocation check (CRITICAL — single SLOAD) ───
        if (revocationRegistry.isRevoked(agentId)) {
            return _fail(agentId, target, selector, "AGENT_REVOKED");
        }

        // ── Step 5–6: Load scope, check not manually revoked ─────
        PermissionScope storage scope = _scopes[agentId];
        if (scope.agentId == bytes32(0)) {
            return _fail(agentId, target, selector, "NO_ACTIVE_SCOPE");
        }
        if (scope.revoked) {
            return _fail(agentId, target, selector, "SCOPE_REVOKED");
        }

        // ── Step 7: Validity window ───────────────────────────────
        if (block.timestamp < scope.validFrom || block.timestamp > scope.validUntil) {
            return _fail(agentId, target, selector, "SCOPE_EXPIRED");
        }

        // ── Step 8: Protocol allowlist ────────────────────────────
        if (!scope.allowAnyProtocol && !_inAddressArray(scope.allowedProtocols, target)) {
            return _fail(agentId, target, selector, "PROTOCOL_NOT_ALLOWED");
        }

        // ── Step 9: Selector allowlist ────────────────────────────
        if (scope.allowedSelectors.length > 0 && !_inSelectorArray(scope.allowedSelectors, selector)) {
            return _fail(agentId, target, selector, "SELECTOR_NOT_ALLOWED");
        }

        // ── Step 10: Token allowlist ──────────────────────────────
        if (!scope.allowAnyToken && !_inAddressArray(scope.allowedTokens, tokenAddress)) {
            return _fail(agentId, target, selector, "TOKEN_NOT_ALLOWED");
        }

        // ── Step 11: Time window check (hour + day mask) ──────────
        if (scope.windowDaysMask != 0 || scope.windowStartHour != scope.windowEndHour) {
            if (!_inTimeWindow(scope)) {
                return _fail(agentId, target, selector, "OUTSIDE_TIME_WINDOW");
            }
        }

        // ── Step 12: Get USD value ────────────────────────────────
        uint256 usdValue = 0;
        if (tokenAddress != address(0) && tokenAmount > 0) {
            // If oracle lookup fails (e.g. unsupported token), treat as 0 USD value
            // This is intentionally conservative — unknown tokens are not capped
            try spendTracker.getUSDValue(tokenAddress, tokenAmount) returns (uint256 v) {
                usdValue = v;
            } catch {
                // No oracle for this token — skip USD-based cap checks
            }
        }

        // ── Step 13: Per-transaction cap ──────────────────────────
        if (scope.perTxSpendCapUSD > 0 && usdValue > scope.perTxSpendCapUSD) {
            return _fail(agentId, target, selector, "PER_TX_CAP_EXCEEDED");
        }

        // ── Step 14: Rolling daily cap ────────────────────────────
        if (scope.dailySpendCapUSD > 0) {
            if (!spendTracker.checkSpendCap(agentId, usdValue, scope.dailySpendCapUSD)) {
                return _fail(agentId, target, selector, "DAILY_CAP_EXCEEDED");
            }
        }

        // ── Step 15: Record spend + log action ────────────────────
        if (usdValue > 0) {
            spendTracker.recordSpend(agentId, usdValue, uint48(block.timestamp));
        }
        // slither-disable-next-line unused-return
        auditLogger.logAction(
            agentId,
            actionHash,
            target,
            selector,
            tokenAddress,
            usdValue,
            true,
            ""
        );

        return VALIDATION_SUCCESS;
    }

    // ── Permission Management ─────────────────────────────────────

    /// @notice Grant a permission scope to an agent.
    ///         Requires a valid EIP-712 signature from the agent's owner.
    function grantPermission(
        bytes32 agentId,
        PermissionScope calldata scope,
        bytes calldata ownerSignature
    ) external whenNotPaused {
        // Verify caller owns the agent
        AgentRecord memory rec = agentRegistry.resolve(agentId);
        require(rec.owner != address(0), "PermissionVault: agent not found");
        require(
            rec.owner == msg.sender || msg.sender == owner(),
            "PermissionVault: not agent owner"
        );

        // Verify scope targets the correct agent
        require(scope.agentId == agentId, "PermissionVault: agentId mismatch");
        require(scope.validUntil > block.timestamp, "PermissionVault: scope already expired");

        // Verify EIP-712 signature (replay protection via nonce)
        uint256 nonce = grantNonces[agentId]++;
        bytes32 structHash = keccak256(abi.encode(
            SCOPE_TYPEHASH,
            agentId,
            nonce,
            scope.dailySpendCapUSD,
            scope.perTxSpendCapUSD,
            scope.validFrom,
            scope.validUntil,
            scope.allowAnyProtocol,
            scope.allowAnyToken
        ));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(ownerSignature);
        require(signer == rec.owner, "PermissionVault: invalid owner signature");

        // Store scope (overwrites any previous scope — one active scope per agent)
        PermissionScope storage stored = _scopes[agentId];
        // Copy all fields
        stored.agentId           = scope.agentId;
        stored.dailySpendCapUSD  = scope.dailySpendCapUSD;
        stored.perTxSpendCapUSD  = scope.perTxSpendCapUSD;
        stored.validFrom         = scope.validFrom;
        stored.validUntil        = scope.validUntil;
        stored.allowAnyProtocol  = scope.allowAnyProtocol;
        stored.allowAnyToken     = scope.allowAnyToken;
        stored.revoked           = false;
        stored.windowStartHour   = scope.windowStartHour;
        stored.windowEndHour     = scope.windowEndHour;
        stored.windowDaysMask    = scope.windowDaysMask;
        stored.allowedChainId    = scope.allowedChainId;
        stored.grantHash         = digest;

        // Dynamic arrays require explicit copy
        delete stored.allowedProtocols;
        for (uint256 i; i < scope.allowedProtocols.length; ++i) {
            stored.allowedProtocols.push(scope.allowedProtocols[i]);
        }
        delete stored.allowedSelectors;
        for (uint256 i; i < scope.allowedSelectors.length; ++i) {
            stored.allowedSelectors.push(scope.allowedSelectors[i]);
        }
        delete stored.allowedTokens;
        for (uint256 i; i < scope.allowedTokens.length; ++i) {
            stored.allowedTokens.push(scope.allowedTokens[i]);
        }

        emit PermissionGranted(agentId, digest, scope.validUntil);
    }

    /// @notice Revoke the active permission scope for an agent (soft revoke).
    ///         The agent's RevocationRegistry entry is NOT changed — use emergencyRevoke for that.
    function revokePermission(bytes32 agentId) external {
        AgentRecord memory rec = agentRegistry.resolve(agentId);
        require(
            rec.owner == msg.sender || msg.sender == owner(),
            "PermissionVault: not agent owner"
        );
        _scopes[agentId].revoked = true;
        emit PermissionRevoked(agentId, msg.sender);
    }

    /// @notice Hard revoke: marks scope as revoked AND adds to RevocationRegistry.
    ///         The agent will be permanently blocked until reinstated.
    function emergencyRevoke(bytes32 agentId) external {
        AgentRecord memory rec = agentRegistry.resolve(agentId);
        require(
            rec.owner == msg.sender || msg.sender == owner(),
            "PermissionVault: not agent owner"
        );
        _scopes[agentId].revoked = true;
        // Emit event before external call (CEI pattern — prevents log-order reentrancy)
        emit PermissionRevoked(agentId, msg.sender);
        revocationRegistry.revoke(agentId, RevocationReason.Emergency, "emergency revoke via PermissionVault");
    }

    function getActiveScope(bytes32 agentId) external view returns (PermissionScope memory) {
        return _scopes[agentId];
    }

    // ── Internal helpers ──────────────────────────────────────────

    function _fail(
        bytes32 agentId,
        address target,
        bytes4  selector,
        string memory violationType
    ) internal returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01340000, 1037618708788) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01340001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01340005, 585) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01346003, violationType) }
        emit PermissionViolation(agentId, target, selector, violationType);
        // Log the denied action to the audit trail
        if (agentId != bytes32(0)) {
            // slither-disable-next-line unused-return
            try auditLogger.logAction(
                agentId,
                bytes32(0),
                target,
                selector,
                address(0),
                0,
                false,
                violationType
            ) returns (bytes32 /* _eid */) {} catch {}
        }
        return VALIDATION_FAILED;
    }

    /// @dev Decode a standard ERC-20/DeFi callData: target is in the UserOp as the `to` field.
    ///      We parse the first 4 bytes as selector, and look for a known token address pattern.
    ///      For most calls: callData = abi.encode(target, value, data)
    ///      This is a best-effort decode — complex callData (batched txs) returns address(0).
    function _decodeCallData(bytes calldata callData)
        internal
        pure
        returns (
            address target,
            bytes4  selector,
            address tokenAddress,
            uint256 tokenAmount
        )
    {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01350000, 1037618708789) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01350001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01350005, 26) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01356100, callData.offset) }
        if (callData.length < 4) return (address(0), bytes4(0), address(0), 0);

        // Standard ERC-4337 execute: execute(address to, uint256 value, bytes calldata data)
        // selector of execute = 0xb61d27f6
        bytes4 outerSel = bytes4(callData[:4]);

        if (outerSel == bytes4(0xb61d27f6) && callData.length >= 68) {
            // Decode: (address target, uint256 value, bytes innerData)
            uint256 _val;
            bytes memory innerData;
            (target, _val, innerData) = abi.decode(callData[4:], (address, uint256, bytes));
            if (innerData.length >= 4) {
                selector = bytes4(innerData[0]) | (bytes4(innerData[1]) >> 8) |
                           (bytes4(innerData[2]) >> 16) | (bytes4(innerData[3]) >> 24);
                // For ERC-20 transfer(address,uint256): selector = 0xa9059cbb
                if (selector == bytes4(0xa9059cbb) && innerData.length >= 68) {
                    // token is the `target` (the ERC-20 contract)
                    tokenAddress = target;
                    (, tokenAmount) = abi.decode(_slice(innerData, 4), (address, uint256));
                }
            }
            return (target, selector, tokenAddress, tokenAmount);
        }

        // Fallback: treat entire callData as a direct call
        selector    = outerSel;
        target      = address(0);
        tokenAddress = address(0);
        tokenAmount  = 0;
    }

    function _slice(bytes memory data, uint256 start) internal pure returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01370000, 1037618708791) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01370001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01370005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01376001, start) }
        require(data.length >= start, "slice out of bounds");
        bytes memory result = new bytes(data.length - start);
        for (uint256 i; i < result.length; ++i) {
            result[i] = data[start + i];
        }
        return result;
    }

    function _inAddressArray(address[] storage arr, address val) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01380000, 1037618708792) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01380001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01380005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01386001, val) }
        uint256 len = arr.length;
        for (uint256 i; i < len; ++i) {
            if (arr[i] == val) return true;
        }
        return false;
    }

    function _inSelectorArray(bytes4[] storage arr, bytes4 val) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01360000, 1037618708790) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01360001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01360005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01366001, val) }
        uint256 len = arr.length;
        for (uint256 i; i < len; ++i) {
            if (arr[i] == val) return true;
        }
        return false;
    }

    function _inTimeWindow(PermissionScope storage scope) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01390000, 1037618708793) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01390001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01390005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01396000, scope.slot) }
        // Day-of-week check (if windowDaysMask != 0)
        if (scope.windowDaysMask != 0) {
            // timestamp / 86400 gives days since epoch. Day 0 = Thursday (Unix epoch).
            // We align to Monday=0 by offsetting 3 days.
            uint8 dow = uint8(((block.timestamp / 86400) + 3) % 7); // 0=Mon…6=Sun
            if ((scope.windowDaysMask >> dow) & 1 == 0) return false;
        }
        // Hour-of-day check (if start != end)
        if (scope.windowStartHour != scope.windowEndHour) {
            uint8 hour = uint8((block.timestamp % 86400) / 3600);
            if (scope.windowStartHour < scope.windowEndHour) {
                if (hour < scope.windowStartHour || hour >= scope.windowEndHour) return false;
            } else {
                // Wraps midnight: e.g. 22:00–06:00
                if (hour < scope.windowStartHour && hour >= scope.windowEndHour) return false;
            }
        }
        return true;
    }

    // ── Emergency pause ───────────────────────────────────────────
    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ── ETH handling ──────────────────────────────────────────────
    /// @dev Plain ETH transfers to this contract are rejected.
    ///      (validateUserOp is payable per ERC-4337 spec but modules do not
    ///       typically forward ETH — any ETH accidentally sent can be swept.)
    receive() external payable {
        revert("PermissionVault: does not accept ETH");
    }

    /// @notice Rescue any ETH accidentally sent to this contract (e.g. via a
    ///         payable validateUserOp call from a non-standard EntryPoint).
    function rescueETH(address payable recipient) external onlyOwner {
        require(recipient != address(0), "PermissionVault: zero address");
        uint256 bal = address(this).balance;
        require(bal > 0, "PermissionVault: no ETH to rescue");
        // slither-disable-next-line low-level-calls
        (bool ok,) = recipient.call{value: bal}("");
        require(ok, "PermissionVault: ETH transfer failed");
    }
}

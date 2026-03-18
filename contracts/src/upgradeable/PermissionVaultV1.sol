// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "../interfaces/IBouclier.sol";
import "../AgentRegistry.sol";
import "../RevocationRegistry.sol";
import "../SpendTracker.sol";
import "../AuditLogger.sol";

/// @title  PermissionVaultV1
/// @notice UUPS-upgradeable version of PermissionVault.
///         Replace `immutable` dependency references with mutable state variables
///         (immutables cannot be used in proxy implementations).
///         All 15-step validation logic is identical to PermissionVault.
///
///         Upgrade workflow:
///           1. Deploy implementation: new PermissionVaultV1()
///           2. Deploy proxy:          new ERC1967Proxy(impl, initData)
///           3. Grant UPGRADER_ROLE to BouclierProxyAdmin (TimelockController)
///           4. Future upgrades go through 48-hour timelock proposal
contract PermissionVaultV1 is
    IPermissionVault,
    Initializable,
    UUPSUpgradeable,
    AccessControl,
    Pausable,
    ReentrancyGuard,
    EIP712("BouclierPermissionVault", "1")
{
    using ECDSA for bytes32;

    // ── Roles ─────────────────────────────────────────────────────
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // ── EIP-712 type hash for PermissionScope ─────────────────────
    bytes32 public constant SCOPE_TYPEHASH = keccak256(
        "PermissionScope(bytes32 agentId,uint256 nonce,uint256 dailySpendCapUSD,uint256 perTxSpendCapUSD,"
        "uint48 validFrom,uint48 validUntil,bool allowAnyProtocol,bool allowAnyToken)"
    );

    // ── Module constants (ERC-7579) ───────────────────────────────
    uint256 private constant MODULE_TYPE_VALIDATOR = 1;

    // ── Dependencies (mutable — no immutable in proxies) ──────────
    AgentRegistry      public agentRegistry;
    RevocationRegistry public revocationRegistry;
    SpendTracker       public spendTracker;
    AuditLogger        public auditLogger;

    // ── State ─────────────────────────────────────────────────────
    mapping(bytes32 agentId => PermissionScope) private _scopes;
    mapping(bytes32 agentId => uint256) public grantNonces;

    // ── Storage gap for future upgrades (50 slots) ────────────────
    uint256[46] private __gap;

    // ── Constructor: disable initializers on the implementation ───
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ── Initializer (replaces constructor for proxy deployments) ──
    function initialize(
        address admin,
        address _agentRegistry,
        address _revocationRegistry,
        address _spendTracker,
        address _auditLogger
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        agentRegistry      = AgentRegistry(_agentRegistry);
        revocationRegistry = RevocationRegistry(_revocationRegistry);
        spendTracker       = SpendTracker(_spendTracker);
        auditLogger        = AuditLogger(_auditLogger);
    }

    // ── UUPS upgrade authorization ────────────────────────────────
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // ── ERC-7579 IModule ──────────────────────────────────────────

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function onInstall(bytes calldata /* data */) external pure {
        // No-op: PermissionVaultV1 is standalone, not per-account initialized
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

    function grantPermission(
        bytes32 agentId,
        PermissionScope calldata scope,
        bytes calldata ownerSignature
    ) external whenNotPaused {
        AgentRecord memory rec = agentRegistry.resolve(agentId);
        require(rec.owner != address(0), "PermissionVaultV1: agent not found");
        require(
            rec.owner == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PermissionVaultV1: not agent owner"
        );

        require(scope.agentId == agentId, "PermissionVaultV1: agentId mismatch");
        require(scope.validUntil > block.timestamp, "PermissionVaultV1: scope already expired");

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
        require(signer == rec.owner, "PermissionVaultV1: invalid owner signature");

        PermissionScope storage stored = _scopes[agentId];
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

    function revokePermission(bytes32 agentId) external {
        AgentRecord memory rec = agentRegistry.resolve(agentId);
        require(
            rec.owner == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PermissionVaultV1: not agent owner"
        );
        _scopes[agentId].revoked = true;
        emit PermissionRevoked(agentId, msg.sender);
    }

    function emergencyRevoke(bytes32 agentId) external {
        AgentRecord memory rec = agentRegistry.resolve(agentId);
        require(
            rec.owner == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PermissionVaultV1: not agent owner"
        );
        _scopes[agentId].revoked = true;
        emit PermissionRevoked(agentId, msg.sender);
        revocationRegistry.revoke(agentId, RevocationReason.Emergency, "emergency revoke via PermissionVaultV1");
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
    ) internal returns (uint256) {
        emit PermissionViolation(agentId, target, selector, violationType);
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

    function _decodeCallData(bytes calldata callData)
        internal
        pure
        returns (
            address target,
            bytes4  selector,
            address tokenAddress,
            uint256 tokenAmount
        )
    {
        if (callData.length < 4) return (address(0), bytes4(0), address(0), 0);

        bytes4 outerSel = bytes4(callData[:4]);

        if (outerSel == bytes4(0xb61d27f6) && callData.length >= 68) {
            uint256 _val;
            bytes memory innerData;
            (target, _val, innerData) = abi.decode(callData[4:], (address, uint256, bytes));
            if (innerData.length >= 4) {
                selector = bytes4(innerData[0]) | (bytes4(innerData[1]) >> 8) |
                           (bytes4(innerData[2]) >> 16) | (bytes4(innerData[3]) >> 24);
                if (selector == bytes4(0xa9059cbb) && innerData.length >= 68) {
                    tokenAddress = target;
                    (, tokenAmount) = abi.decode(_slice(innerData, 4), (address, uint256));
                }
            }
            return (target, selector, tokenAddress, tokenAmount);
        }

        selector    = outerSel;
        target      = address(0);
        tokenAddress = address(0);
        tokenAmount  = 0;
    }

    function _slice(bytes memory data, uint256 start) internal pure returns (bytes memory) {
        require(data.length >= start, "slice out of bounds");
        bytes memory result = new bytes(data.length - start);
        for (uint256 i; i < result.length; ++i) {
            result[i] = data[start + i];
        }
        return result;
    }

    function _inAddressArray(address[] storage arr, address val) internal view returns (bool) {
        uint256 len = arr.length;
        for (uint256 i; i < len; ++i) {
            if (arr[i] == val) return true;
        }
        return false;
    }

    function _inSelectorArray(bytes4[] storage arr, bytes4 val) internal view returns (bool) {
        uint256 len = arr.length;
        for (uint256 i; i < len; ++i) {
            if (arr[i] == val) return true;
        }
        return false;
    }

    function _inTimeWindow(PermissionScope storage scope) internal view returns (bool) {
        if (scope.windowDaysMask != 0) {
            uint8 dow = uint8(((block.timestamp / 86400) + 3) % 7);
            if ((scope.windowDaysMask >> dow) & 1 == 0) return false;
        }
        if (scope.windowStartHour != scope.windowEndHour) {
            uint8 hour = uint8((block.timestamp % 86400) / 3600);
            if (scope.windowStartHour < scope.windowEndHour) {
                if (hour < scope.windowStartHour || hour >= scope.windowEndHour) return false;
            } else {
                if (hour < scope.windowStartHour && hour >= scope.windowEndHour) return false;
            }
        }
        return true;
    }

    // ── Admin ─────────────────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    function rescueETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "PermissionVaultV1: zero address");
        uint256 bal = address(this).balance;
        require(bal > 0, "PermissionVaultV1: no ETH to rescue");
        // slither-disable-next-line low-level-calls
        (bool ok,) = recipient.call{value: bal}("");
        require(ok, "PermissionVaultV1: ETH transfer failed");
    }

    receive() external payable {
        revert("PermissionVaultV1: does not accept ETH");
    }
}

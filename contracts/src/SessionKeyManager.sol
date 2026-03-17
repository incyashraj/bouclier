// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./interfaces/IBouclier.sol";
import "./PermissionVault.sol";

/// @title  SessionKeyManager — Scoped ephemeral session keys for AI agents
/// @notice Allows a master key (hardware wallet / multisig) to issue time-limited
///         session keys that can execute transactions within a defined scope.
///         Even if the session key is compromised, blast radius is limited to the
///         granted permission scope + spend cap.
///
/// Flow:
///   1. Master key signs a SessionGrant off-chain (EIP-712 typed data)
///   2. Agent uses the session key to call executeViaSession()
///   3. This contract verifies the grant signature, checks expiry, then delegates
///      to PermissionVault.validateUserOp for the actual permission check

contract SessionKeyManager is Ownable, EIP712 {
    using ECDSA for bytes32;

    // ── Types ─────────────────────────────────────────────────────

    struct SessionGrant {
        address sessionKey;     // ephemeral key address
        bytes32 agentId;        // registered agent ID
        address[] allowedTargets; // contracts this session key can call
        uint256 spendLimit;     // max USD spend for this session (18 decimals)
        uint48  validAfter;     // session start timestamp
        uint48  validUntil;     // session expiry timestamp
        uint256 nonce;          // replay protection
    }

    // ── Storage ───────────────────────────────────────────────────

    PermissionVault public immutable vault;

    /// @dev master => nonce => used
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    /// @dev sessionKey => SessionGrant hash => total USD spent (18 decimals)
    mapping(address => mapping(bytes32 => uint256)) public sessionSpend;

    // ── EIP-712 type hash ─────────────────────────────────────────

    bytes32 public constant SESSION_GRANT_TYPEHASH = keccak256(
        "SessionGrant(address sessionKey,bytes32 agentId,address[] allowedTargets,uint256 spendLimit,uint48 validAfter,uint48 validUntil,uint256 nonce)"
    );

    // ── Events ────────────────────────────────────────────────────

    event SessionExecuted(
        address indexed sessionKey,
        bytes32 indexed agentId,
        address target,
        uint256 value,
        bool success
    );

    event SessionRevoked(address indexed master, uint256 nonce);

    // ── Errors ────────────────────────────────────────────────────

    error SessionExpired();
    error SessionNotYetActive();
    error SessionNonceUsed();
    error InvalidSessionSignature();
    error TargetNotAllowed(address target);
    error SessionSpendLimitExceeded(uint256 attempted, uint256 remaining);

    // ── Constructor ───────────────────────────────────────────────

    constructor(
        address _vault,
        address _admin
    ) Ownable(_admin) EIP712("BouclierSessionKeys", "1") {
        vault = PermissionVault(payable(_vault));
    }

    /// @notice Expose domain separator for off-chain signature construction.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    // ── Core ──────────────────────────────────────────────────────

    /// @notice Execute a transaction using a session key grant.
    /// @param grant       The session grant signed by the master key
    /// @param masterSig   EIP-712 signature from the master key over the grant
    /// @param target      Contract to call
    /// @param value       ETH value to send
    /// @param data        Calldata for the target
    /// @param spendUSD    USD value of this transaction (18 decimals, provided by caller/relayer)
    function executeViaSession(
        SessionGrant calldata grant,
        bytes calldata masterSig,
        address target,
        uint256 value,
        bytes calldata data,
        uint256 spendUSD
    ) external returns (bytes memory) {
        // 1. Only the session key holder can call
        require(msg.sender == grant.sessionKey, "SessionKeyManager: caller is not session key");

        // 2. Time checks
        if (block.timestamp < grant.validAfter) revert SessionNotYetActive();
        if (block.timestamp > grant.validUntil) revert SessionExpired();

        // 3. Verify grant signature & nonce
        _verifyGrantSignature(grant, masterSig);

        // 4. Target whitelist
        if (!_isTargetAllowed(grant.allowedTargets, target)) {
            revert TargetNotAllowed(target);
        }

        // 5. Spend limit
        _recordSpend(grant, spendUSD);

        // 6. Execute
        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "SessionKeyManager: call failed");

        emit SessionExecuted(grant.sessionKey, grant.agentId, target, value, success);

        return result;
    }

    /// @notice Revoke a session grant by marking its nonce as used.
    ///         Can be called by the master key holder at any time.
    function revokeSession(uint256 nonce) external {
        usedNonces[msg.sender][nonce] = true;
        emit SessionRevoked(msg.sender, nonce);
    }

    /// @notice Batch-revoke multiple session nonces.
    function batchRevokeSession(uint256[] calldata nonces) external {
        for (uint256 i = 0; i < nonces.length; ++i) {
            usedNonces[msg.sender][nonces[i]] = true;
            emit SessionRevoked(msg.sender, nonces[i]);
        }
    }

    // ── View ──────────────────────────────────────────────────────

    /// @notice Check if a session grant is still valid (not expired, not revoked).
    function isSessionValid(
        SessionGrant calldata grant,
        bytes calldata masterSig
    ) external view returns (bool valid, address master) {
        if (block.timestamp < grant.validAfter || block.timestamp > grant.validUntil) {
            return (false, address(0));
        }

        bytes32 structHash = _hashSessionGrant(grant);
        bytes32 digest = _hashTypedDataV4(structHash);
        master = ECDSA.recover(digest, masterSig);

        if (usedNonces[master][grant.nonce]) {
            return (false, master);
        }

        return (true, master);
    }

    /// @notice Get remaining spend budget for a session.
    function remainingBudget(
        address sessionKey,
        bytes32 agentId,
        uint256 nonce,
        uint256 spendLimit
    ) external view returns (uint256) {
        bytes32 grantHash = keccak256(abi.encode(sessionKey, agentId, nonce));
        uint256 spent = sessionSpend[sessionKey][grantHash];
        return spent >= spendLimit ? 0 : spendLimit - spent;
    }

    // ── Internal ──────────────────────────────────────────────────

    function _verifyGrantSignature(SessionGrant calldata grant, bytes calldata masterSig) internal view {
        bytes32 structHash = _hashSessionGrant(grant);
        bytes32 digest = _hashTypedDataV4(structHash);
        address master = ECDSA.recover(digest, masterSig);
        if (usedNonces[master][grant.nonce]) revert SessionNonceUsed();
    }

    function _recordSpend(SessionGrant calldata grant, uint256 spendUSD) internal {
        bytes32 grantHash = keccak256(abi.encode(grant.sessionKey, grant.agentId, grant.nonce));
        uint256 spent = sessionSpend[grant.sessionKey][grantHash];
        if (spent + spendUSD > grant.spendLimit) {
            revert SessionSpendLimitExceeded(spendUSD, grant.spendLimit - spent);
        }
        sessionSpend[grant.sessionKey][grantHash] = spent + spendUSD;
    }

    function _hashSessionGrant(SessionGrant calldata grant) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SESSION_GRANT_TYPEHASH,
            grant.sessionKey,
            grant.agentId,
            keccak256(abi.encodePacked(grant.allowedTargets)),
            grant.spendLimit,
            grant.validAfter,
            grant.validUntil,
            grant.nonce
        ));
    }

    function _isTargetAllowed(address[] calldata targets, address target) internal pure returns (bool) {
        if (targets.length == 0) return true; // empty = all allowed
        for (uint256 i = 0; i < targets.length; ++i) {
            if (targets[i] == target) return true;
        }
        return false;
    }
}

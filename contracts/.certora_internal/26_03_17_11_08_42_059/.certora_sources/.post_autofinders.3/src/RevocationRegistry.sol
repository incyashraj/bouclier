// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IBouclier.sol";

/// @title  RevocationRegistry
/// @notice Append-only revocation store. Tracks which agentIds are revoked.
///         `isRevoked()` is the hot-path: single SLOAD, ~2,200 gas.
///         Reinstatement enforces a mandatory 24-hour timelock.
contract RevocationRegistry is IRevocationRegistry, AccessControl, Pausable {
    // ── Roles ─────────────────────────────────────────────────────
    bytes32 public constant REVOKER_ROLE  = keccak256("REVOKER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // ── State ─────────────────────────────────────────────────────
    /// @dev Packed: revoked(bool) + revokedAt(uint48) = 7 bytes in slot 0
    mapping(bytes32 agentId => RevocationRecord) private _records;

    uint48 public constant REINSTATEMENT_DELAY = 24 hours;

    // ── Constructor ───────────────────────────────────────────────
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REVOKER_ROLE,  admin);
        _grantRole(GUARDIAN_ROLE, admin);
    }

    // ── Revoke ────────────────────────────────────────────────────

    /// @notice Revoke a single agent. Caller must have REVOKER_ROLE.
    function revoke(
        bytes32 agentId,
        RevocationReason reason,
        string calldata notes
    ) external onlyRole(REVOKER_ROLE) whenNotPaused {
        _revoke(agentId, reason, notes);
    }

    /// @notice Revoke multiple agents in one call. Caller must have GUARDIAN_ROLE.
    function batchRevoke(
        bytes32[] calldata agentIds,
        RevocationReason reason,
        string calldata notes
    ) external onlyRole(GUARDIAN_ROLE) whenNotPaused {
        uint256 len = agentIds.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000004e,len)}
        for (uint256 i; i < len; ++i) {
            _revoke(agentIds[i], reason, notes);
        }
    }

    function _revoke(
        bytes32 agentId,
        RevocationReason reason,
        string calldata notes
    ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430000, 1037618708547) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430005, 602) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00436102, notes.offset) }
        RevocationRecord storage rec = _records[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001004f,0)}
        // Idempotent — revoking an already-revoked agent is a no-op
        if (rec.revoked) return;

        rec.revoked     = true;bool certora_local82 = rec.revoked;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000052,certora_local82)}
        rec.revokedAt   = uint48(block.timestamp);uint48 certora_local83 = rec.revokedAt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000053,certora_local83)}
        rec.revokedBy   = msg.sender;address certora_local84 = rec.revokedBy;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000054,certora_local84)}
        rec.reason      = reason;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020055,0)}
        rec.notes       = notes;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020056,0)}
        rec.reinstatedAt = 0;uint48 certora_local87 = rec.reinstatedAt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000057,certora_local87)}

        emit AgentRevoked(agentId, msg.sender, reason, uint48(block.timestamp));
    }

    // ── Reinstate ─────────────────────────────────────────────────

    /// @notice Reinstate a revoked agent. Enforces a 24-hour timelock after revocation.
    ///         GUARDIAN_ROLE can bypass the timelock via `emergencyReinstate`.
    function reinstate(
        bytes32 agentId,
        string calldata notes
    ) external onlyRole(REVOKER_ROLE) whenNotPaused {
        RevocationRecord storage rec = _records[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010050,0)}
        require(rec.revoked, "RevocationRegistry: agent not revoked");
        require(
            block.timestamp >= rec.revokedAt + REINSTATEMENT_DELAY,
            "RevocationRegistry: reinstatement timelock not expired"
        );
        _reinstate(agentId, rec, notes);
    }

    /// @notice Emergency reinstatement — bypasses the 24h timelock. GUARDIAN_ROLE only.
    function emergencyReinstate(
        bytes32 agentId,
        string calldata notes
    ) external onlyRole(GUARDIAN_ROLE) whenNotPaused {
        RevocationRecord storage rec = _records[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010051,0)}
        require(rec.revoked, "RevocationRegistry: agent not revoked");
        _reinstate(agentId, rec, notes);
    }

    function _reinstate(
        bytes32 agentId,
        RevocationRecord storage rec,
        string calldata notes
    ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00440000, 1037618708548) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00440001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00440005, 602) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00446102, notes.offset) }
        rec.revoked      = false;bool certora_local88 = rec.revoked;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000058,certora_local88)}
        rec.reinstatedAt = uint48(block.timestamp);uint48 certora_local89 = rec.reinstatedAt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000059,certora_local89)}
        rec.notes        = notes;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002005a,0)}

        emit AgentReinstated(agentId, msg.sender, uint48(block.timestamp));
    }

    // ── Views ─────────────────────────────────────────────────────

    /// @notice Hot-path: single SLOAD, ~2,200 gas. Used by PermissionVault on every UserOp.
    function isRevoked(bytes32 agentId) external view returns (bool) {
        return _records[agentId].revoked;
    }

    function getRevocationRecord(bytes32 agentId) external view returns (RevocationRecord memory) {
        return _records[agentId];
    }

    // ── Emergency pause ───────────────────────────────────────────
    function pause()   external onlyRole(GUARDIAN_ROLE) { _pause(); }
    function unpause() external onlyRole(GUARDIAN_ROLE) { _unpause(); }
}

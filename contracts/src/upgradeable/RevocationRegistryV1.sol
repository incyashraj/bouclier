// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IBouclier.sol";

/// @title  RevocationRegistryV1
/// @notice UUPS-upgradeable version of RevocationRegistry.
///         Append-only revocation store with 24-hour reinstatement timelock.
contract RevocationRegistryV1 is Initializable, UUPSUpgradeable, AccessControl, Pausable, IRevocationRegistry {

    bytes32 public constant REVOKER_ROLE   = keccak256("REVOKER_ROLE");
    bytes32 public constant GUARDIAN_ROLE  = keccak256("GUARDIAN_ROLE");
    bytes32 public constant UPGRADER_ROLE  = keccak256("UPGRADER_ROLE");

    mapping(bytes32 agentId => RevocationRecord) private _records;
    uint48 public constant REINSTATEMENT_DELAY = 24 hours;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address _admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(REVOKER_ROLE,  _admin);
        _grantRole(GUARDIAN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    // ── Revoke ────────────────────────────────────────────────────

    function revoke(bytes32 agentId, RevocationReason reason, string calldata notes)
        external onlyRole(REVOKER_ROLE) whenNotPaused
    {
        _revoke(agentId, reason, notes);
    }

    function batchRevoke(bytes32[] calldata agentIds, RevocationReason reason, string calldata notes)
        external onlyRole(GUARDIAN_ROLE) whenNotPaused
    {
        for (uint256 i; i < agentIds.length; ++i) {
            _revoke(agentIds[i], reason, notes);
        }
    }

    function _revoke(bytes32 agentId, RevocationReason reason, string calldata notes) internal {
        RevocationRecord storage rec = _records[agentId];
        if (rec.revoked) return;
        rec.revoked      = true;
        rec.revokedAt    = uint48(block.timestamp);
        rec.revokedBy    = msg.sender;
        rec.reason       = reason;
        rec.notes        = notes;
        rec.reinstatedAt = 0;
        emit AgentRevoked(agentId, msg.sender, reason, uint48(block.timestamp));
    }

    // ── Reinstate ─────────────────────────────────────────────────

    function reinstate(bytes32 agentId, string calldata notes)
        external onlyRole(REVOKER_ROLE) whenNotPaused
    {
        RevocationRecord storage rec = _records[agentId];
        require(rec.revoked, "RevocationRegistry: not revoked");
        require(
            block.timestamp >= rec.revokedAt + REINSTATEMENT_DELAY,
            "RevocationRegistry: timelock active"
        );
        rec.revoked      = false;
        rec.reinstatedAt = uint48(block.timestamp);
        emit AgentReinstated(agentId, msg.sender, uint48(block.timestamp));
    }

    function emergencyReinstate(bytes32 agentId, string calldata notes)
        external onlyRole(GUARDIAN_ROLE) whenNotPaused
    {
        RevocationRecord storage rec = _records[agentId];
        require(rec.revoked, "RevocationRegistry: not revoked");
        rec.revoked      = false;
        rec.reinstatedAt = uint48(block.timestamp);
        emit AgentReinstated(agentId, msg.sender, uint48(block.timestamp));
    }

    // ── Views ─────────────────────────────────────────────────────

    function isRevoked(bytes32 agentId) external view returns (bool) {
        return _records[agentId].revoked;
    }

    function getRevocationRecord(bytes32 agentId) external view returns (RevocationRecord memory) {
        return _records[agentId];
    }

    // ── Pause ─────────────────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}

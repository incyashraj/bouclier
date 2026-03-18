// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IBouclier.sol";

/// @title  RevocationReceiver
/// @notice Cross-chain revocation endpoint — Item 7.
///
///         Architecture:
///           Source chain (Base):   RevocationRegistry emits a message via a bridge
///           Destination chains:    RevocationReceiver receives the message and marks the agent revoked
///
///         Bridge-agnostic: The `receive` function accepts structured messages from any
///         authorized bridge adapter (BRIDGE_ROLE). Adapter contracts for LayerZero,
///         Axelar, etc. are deployed separately and granted BRIDGE_ROLE.
///
///         Deployment:
///           - Deploy one RevocationReceiver per destination chain
///           - Grant BRIDGE_ROLE to the LayerZero/Axelar adapter on that chain
///           - The source RevocationRegistry calls the adapter on revocation
///
/// @dev    To integrate LayerZero V2:
//          1. Add `layerzerolabs/oapp-evm` to foundry.toml remappings
//          2. Inherit OApp instead of AccessControl
//          3. Override `_lzReceive` to call `_applyRevocation`
contract RevocationReceiver is AccessControl, IRevocationRegistry {

    // ── Roles ─────────────────────────────────────────────────────
    bytes32 public constant BRIDGE_ROLE   = keccak256("BRIDGE_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // ── State ─────────────────────────────────────────────────────
    mapping(bytes32 agentId => RevocationRecord) private _records;

    /// @notice Source chain ID where the master RevocationRegistry lives.
    uint256 public immutable sourceChainId;

    // ── Errors ────────────────────────────────────────────────────
    error NotRevoked(bytes32 agentId);

    // ── Events ────────────────────────────────────────────────────
    event CrossChainRevocationReceived(
        bytes32 indexed agentId,
        uint256 indexed sourceChain,
        address revokedBy,
        RevocationReason reason
    );

    constructor(address admin, uint256 _sourceChainId) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GUARDIAN_ROLE,      admin);
        sourceChainId = _sourceChainId;
    }

    // ── Bridge entry point ────────────────────────────────────────

    /// @notice Called by a bridge adapter (BRIDGE_ROLE) when a cross-chain
    ///         revocation message arrives from the source chain.
    ///
    ///         Expected message encoding:
    ///           abi.encode(agentId, revokedBy, reason, notes)
    function receiveRevocation(bytes calldata message)
        external
        onlyRole(BRIDGE_ROLE)
    {
        (bytes32 agentId, address revokedBy, RevocationReason reason, string memory notes) =
            abi.decode(message, (bytes32, address, RevocationReason, string));

        _applyRevocation(agentId, revokedBy, reason, notes);
    }

    function _applyRevocation(
        bytes32 agentId,
        address revokedBy,
        RevocationReason reason,
        string memory notes
    ) internal {
        RevocationRecord storage rec = _records[agentId];
        if (rec.revoked) return; // idempotent

        rec.revoked    = true;
        rec.revokedAt  = uint48(block.timestamp);
        rec.revokedBy  = revokedBy;
        rec.reason     = reason;
        rec.notes      = notes;

        emit AgentRevoked(agentId, revokedBy, reason, uint48(block.timestamp));
        emit CrossChainRevocationReceived(agentId, sourceChainId, revokedBy, reason);
    }

    // ── Emergency reinstate ───────────────────────────────────────

    /// @notice Guardian can reinstate on destination chain without cross-chain message.
    function emergencyReinstate(bytes32 agentId, string calldata /* notes */)
        external
        onlyRole(GUARDIAN_ROLE)
    {
        RevocationRecord storage rec = _records[agentId];
        if (!rec.revoked) revert NotRevoked(agentId);
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

    // ── Not implemented (source-chain only operations) ────────────
    function revoke(bytes32, RevocationReason, string calldata) external pure {
        revert("RevocationReceiver: use source chain");
    }
    function batchRevoke(bytes32[] calldata, RevocationReason, string calldata) external pure {
        revert("RevocationReceiver: use source chain");
    }
    function reinstate(bytes32, string calldata) external pure {
        revert("RevocationReceiver: use source chain");
    }
}

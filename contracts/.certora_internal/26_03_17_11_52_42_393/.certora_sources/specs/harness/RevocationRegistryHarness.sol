// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/RevocationRegistry.sol";
import "../../src/interfaces/IBouclier.sol";

/// @title Certora verification harness — exposes struct fields as individual getters
contract RevocationRegistryHarness is RevocationRegistry {
    constructor(address admin) RevocationRegistry(admin) {}

    function getRevoked(bytes32 agentId) external view returns (bool) {
        return this.getRevocationRecord(agentId).revoked;
    }

    function getRevokedAt(bytes32 agentId) external view returns (uint48) {
        return this.getRevocationRecord(agentId).revokedAt;
    }

    /// @dev Wrapper for Certora — CVL cannot resolve enum RevocationReason from uint8
    function revokeWithReason(bytes32 agentId, uint8 reason, string calldata notes) external {
        this.revoke(agentId, RevocationReason(reason), notes);
    }
}

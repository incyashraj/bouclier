// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/PermissionVault.sol";
import "../../src/interfaces/IBouclier.sol";

/// @title Certora verification harness — exposes struct fields as individual getters
contract PermissionVaultHarness is PermissionVault {
    constructor(
        address _admin,
        address _agentRegistry,
        address _revocationRegistry,
        address _spendTracker,
        address _auditLogger
    ) PermissionVault(_admin, _agentRegistry, _revocationRegistry, _spendTracker, _auditLogger) {}

    function getScopeRevoked(bytes32 agentId) external view returns (bool) {
        return this.getActiveScope(agentId).revoked;
    }

    function getScopeValidUntil(bytes32 agentId) external view returns (uint48) {
        return this.getActiveScope(agentId).validUntil;
    }

    function getScopeAgentId(bytes32 agentId) external view returns (bytes32) {
        return this.getActiveScope(agentId).agentId;
    }
}

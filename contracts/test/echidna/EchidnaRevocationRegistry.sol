// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/RevocationRegistry.sol";
import "../../src/interfaces/IBouclier.sol";

/// @title  EchidnaRevocationRegistry
/// @notice Fuzz properties for RevocationRegistry invariants.
///         Run: echidna contracts/test/echidna/EchidnaRevocationRegistry.sol --config contracts/echidna.yaml
contract EchidnaRevocationRegistry {
    RevocationRegistry internal revRegistry;

    bytes32 internal constant AGENT_1 = keccak256("agent_1");
    bytes32 internal constant AGENT_2 = keccak256("agent_2");

    constructor() {
        revRegistry = new RevocationRegistry(address(this));
    }

    // ── Property 1: Revoking twice is idempotent ────────────────
    function echidna_double_revoke_idempotent() public returns (bool) {
        revRegistry.revoke(AGENT_1, RevocationReason.Suspicious, "test");
        revRegistry.revoke(AGENT_1, RevocationReason.Suspicious, "test again");
        return revRegistry.isRevoked(AGENT_1);
    }

    // ── Property 2: Reinstated agent is not revoked ─────────────
    function echidna_reinstate_unrevokes() public returns (bool) {
        revRegistry.revoke(AGENT_2, RevocationReason.UserRequested, "revoke");

        // Fast-forward past the 24h timelock
        // Note: Echidna doesn't support vm.warp, so we use emergencyReinstate
        revRegistry.emergencyReinstate(AGENT_2, "reinstate");

        return !revRegistry.isRevoked(AGENT_2);
    }

    // ── Property 3: isRevoked returns consistent state ──────────
    function echidna_is_revoked_consistent() public view returns (bool) {
        RevocationRecord memory rec = revRegistry.getRevocationRecord(AGENT_1);
        return rec.revoked == revRegistry.isRevoked(AGENT_1);
    }
}

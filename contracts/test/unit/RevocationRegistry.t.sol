// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";

/// @title RevocationRegistry Unit Tests
/// Covers: revoke, batchRevoke, reinstate (timelock), emergencyReinstate, pause, roles
contract RevocationRegistryTest is BouclierTestBase {

    // ── revoke ────────────────────────────────────────────────────

    function test_revoke_setsFlag() public {
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "test");
        assertTrue(revRegistry.isRevoked(agentId));
    }

    function test_revoke_emitsEvent() public {
        vm.expectEmit(true, true, false, false);
        // Only indexed fields checked (agentId, revokedBy); reason + revokedAt unchecked
        emit IRevocationRegistry.AgentRevoked(agentId, address(this), RevocationReason.UserRequested, 0);
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "test");
    }

    function test_revoke_idempotent() public {
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "first");
        // Second call should not revert or change state
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "second");
        assertTrue(revRegistry.isRevoked(agentId));
    }

    function test_revoke_revertsWithoutRole() public {
        vm.prank(stranger);
        vm.expectRevert();
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "test");
    }

    // ── batchRevoke ───────────────────────────────────────────────

    function test_batchRevoke_revokesAll() public {
        bytes32 id2 = bytes32(uint256(agentId) + 1);
        bytes32[] memory ids = new bytes32[](2);
        ids[0] = agentId;
        ids[1] = id2;

        revRegistry.batchRevoke(ids, RevocationReason.Emergency, "batch test");

        assertTrue(revRegistry.isRevoked(agentId));
        assertTrue(revRegistry.isRevoked(id2));
    }

    function test_batchRevoke_requiresGuardianRole() public {
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = agentId;

        // Give agentWallet REVOKER but not GUARDIAN — batchRevoke needs GUARDIAN
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(), agentWallet);
        vm.prank(agentWallet);
        vm.expectRevert();
        revRegistry.batchRevoke(ids, RevocationReason.Emergency, "test");
    }

    // ── reinstate (with timelock) ─────────────────────────────────

    function test_reinstate_revertsIfNotRevoked() public {
        vm.expectRevert();
        revRegistry.reinstate(agentId, "not revoked");
    }

    function test_reinstate_revertsBeforeTimelock() public {
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "test");
        // Try to reinstate immediately — 24h timelock not elapsed
        vm.expectRevert();
        revRegistry.reinstate(agentId, "too soon");
    }

    function test_reinstate_succeedsAfterTimelock() public {
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "test");
        vm.warp(block.timestamp + 25 hours);

        revRegistry.reinstate(agentId, "after timelock");
        assertFalse(revRegistry.isRevoked(agentId));
    }

    // ── emergencyReinstate (bypass timelock) ──────────────────────

    function test_emergencyReinstate_bypassesTimelock() public {
        revRegistry.revoke(agentId, RevocationReason.Emergency, "emergency");
        // No time warp — immediately reinstate via guardian path
        revRegistry.emergencyReinstate(agentId, "guardian override");
        assertFalse(revRegistry.isRevoked(agentId));
    }

    function test_emergencyReinstate_requiresGuardianRole() public {
        revRegistry.revoke(agentId, RevocationReason.Emergency, "test");
        vm.prank(stranger);
        vm.expectRevert();
        revRegistry.emergencyReinstate(agentId, "should fail");
    }

    // ── isRevoked (gas check) ─────────────────────────────────────

    /// @dev isRevoked must be a single SLOAD — measure via gasleft delta
    function test_isRevoked_gasUnderLimit() public {
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "test");
        uint256 gasBefore = gasleft();
        bool result = revRegistry.isRevoked(agentId);
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(result);
        assertLt(gasUsed, 5_000); // single SLOAD + overhead should be well under 5k
    }

    // ── pause ─────────────────────────────────────────────────────

    function test_pause_blocksRevoke() public {
        revRegistry.pause(); // admin also has GUARDIAN
        vm.expectRevert();
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "while paused");
    }

    function test_unpause_restoresRevoke() public {
        revRegistry.pause();
        revRegistry.unpause();
        revRegistry.revoke(agentId, RevocationReason.UserRequested, "after unpause");
        assertTrue(revRegistry.isRevoked(agentId));
    }

    // ── getRecord ─────────────────────────────────────────────────

    function test_getRecord_populatedAfterRevoke() public {
        revRegistry.revoke(agentId, RevocationReason.Suspicious, "sus");
        RevocationRecord memory rec = revRegistry.getRevocationRecord(agentId);
        assertTrue(rec.revoked);
        assertEq(rec.revokedBy, address(this));
        assertEq(uint256(rec.reason), uint256(RevocationReason.Suspicious));
        assertGt(rec.revokedAt, 0);
    }
}

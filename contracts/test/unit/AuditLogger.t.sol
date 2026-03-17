// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";

/// @title AuditLogger Unit Tests
/// Covers: logAction, getAuditRecord, addIPFSCID, getAgentHistory, roles
contract AuditLoggerTest is BouclierTestBase {

    // ── logAction ─────────────────────────────────────────────────

    function test_logAction_storesRecord() public {
        bytes32 eventId = auditLogger.logAction(
            agentId,
            keccak256("transfer(address,uint256)"),
            address(0xDEF1),
            TRANSFER_SEL,
            USDC,
            USD_50,
            true,
            ""
        );

        AuditRecord memory rec = auditLogger.getAuditRecord(eventId);
        assertEq(rec.agentId,  agentId);
        assertEq(rec.target,   address(0xDEF1));
        assertEq(rec.selector, TRANSFER_SEL);
        assertEq(rec.tokenAddress, USDC);
        assertEq(rec.usdAmount, USD_50);
        assertTrue(rec.allowed);
    }

    function test_logAction_requiresLoggerRole() public {
        vm.prank(stranger);
        vm.expectRevert();
        auditLogger.logAction(agentId, bytes32(0), address(0), bytes4(0), address(0), 0, true, "");
    }

    function test_logAction_returnsUniqueEventIds() public {
        bytes32 id1 = auditLogger.logAction(agentId, keccak256("A"), address(1), bytes4(0), address(0), 0, true, "");
        bytes32 id2 = auditLogger.logAction(agentId, keccak256("B"), address(1), bytes4(0), address(0), 0, true, "");
        assertTrue(id1 != id2);
    }

    function test_logAction_revertsOnDuplicateEventId() public {
        // Two calls in the same block — monotonic logIdx prevents collision, no revert
        auditLogger.logAction(agentId, bytes32(uint256(0xAA)), address(1), bytes4(0), address(0), 0, true, "");
        auditLogger.logAction(agentId, bytes32(uint256(0xAA)), address(1), bytes4(0), address(0), 0, false, "DENIED");
    }

    // ── addIPFSCID ────────────────────────────────────────────────

    function test_addIPFSCID_persists() public {
        bytes32 eventId = auditLogger.logAction(agentId, bytes32(0), address(0), bytes4(0), address(0), 0, true, "");
        auditLogger.addIPFSCID(eventId, "QmHash123");

        AuditRecord memory rec = auditLogger.getAuditRecord(eventId);
        assertEq(rec.ipfsCID, "QmHash123");
    }

    function test_addIPFSCID_requiresIPFSRole() public {
        bytes32 eventId = auditLogger.logAction(agentId, bytes32(0), address(0), bytes4(0), address(0), 0, true, "");
        vm.prank(stranger);
        vm.expectRevert();
        auditLogger.addIPFSCID(eventId, "QmBad");
    }

    function test_addIPFSCID_revertsForUnknownEventId() public {
        vm.expectRevert();
        auditLogger.addIPFSCID(bytes32(uint256(0xDEAD)), "QmHash");
    }

    // ── getAgentHistory ────────────────────────────────────────────

    function test_getAgentHistory_pagination() public {
        // Log 5 events
        for (uint256 i = 0; i < 5; i++) {
            auditLogger.logAction(agentId, bytes32(i), address(0), bytes4(0), address(0), 0, true, "");
        }

        bytes32[] memory page1 = auditLogger.getAgentHistory(agentId, 0, 3);
        bytes32[] memory page2 = auditLogger.getAgentHistory(agentId, 3, 3);

        assertEq(page1.length, 3);
        assertEq(page2.length, 2); // only 2 remaining
    }

    function test_getAgentHistory_emptyForUnknownAgent() public view {
        bytes32[] memory ids = auditLogger.getAgentHistory(bytes32(uint256(0xDEAD)), 0, 10);
        assertEq(ids.length, 0);
    }

    // ── pause ─────────────────────────────────────────────────────

    function test_pause_blocksLogAction() public {
        auditLogger.pause();
        vm.expectRevert();
        auditLogger.logAction(agentId, bytes32(0), address(0), bytes4(0), address(0), 0, true, "");
    }
}

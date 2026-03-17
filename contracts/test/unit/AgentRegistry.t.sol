// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";

/// @title AgentRegistry Unit Tests
/// Covers: register, resolve, getAgentId, updateStatus, DID format, uniqueness
contract AgentRegistryTest is BouclierTestBase {

    // ── register ──────────────────────────────────────────────────

    function test_register_storesRecord() public {
        AgentRecord memory rec = agentReg.resolve(agentId);
        assertEq(rec.agentAddress, agentWallet);
        assertEq(rec.owner,        enterprise);
        assertEq(uint256(rec.status), uint256(AgentStatus.Active));
        assertEq(rec.model,  "gpt-4o");
        assertEq(rec.metadataCID, "QmTestCID");
        assertEq(rec.parentAgentId, bytes32(0));
    }

    function test_register_returnsDid() public view {
        AgentRecord memory rec = agentReg.resolve(agentId);
        // DID should start with "did:ethr:anvil:0x" in local test environment
        assertTrue(bytes(rec.did).length > 0);
        assertEq(rec.did, string(abi.encodePacked("did:ethr:anvil:0x", _toLower40(agentWallet))));
    }

    function test_register_revertsForZeroAddress() public {
        vm.prank(enterprise);
        vm.expectRevert();
        agentReg.register(address(0), "gpt-4o", bytes32(0), "");
    }

    function test_register_revertsForDuplicateWallet() public {
        vm.prank(enterprise);
        vm.expectRevert();
        agentReg.register(agentWallet, "gpt-4o", bytes32(0), "");
    }

    function test_register_incrementsTotal() public view {
        assertEq(agentReg.totalAgents(), 1);
    }

    function test_register_differentOwnersCanShareWalletFails() public {
        // A wallet can only be registered to one owner
        vm.prank(stranger);
        vm.expectRevert();
        agentReg.register(agentWallet, "gpt-4o", bytes32(0), "");
    }

    // ── getAgentId / getAgentsByOwner ─────────────────────────────

    function test_getAgentId_reverseMapping() public view {
        assertEq(agentReg.getAgentId(agentWallet), agentId);
    }

    function test_getAgentsByOwner_returnsList() public view {
        bytes32[] memory ids = agentReg.getAgentsByOwner(enterprise);
        assertEq(ids.length, 1);
        assertEq(ids[0], agentId);
    }

    function test_getAgentsByOwner_emptyForUnknownOwner() public view {
        bytes32[] memory ids = agentReg.getAgentsByOwner(stranger);
        assertEq(ids.length, 0);
    }

    // ── updateStatus ──────────────────────────────────────────────

    function test_updateStatus_byOwner() public {
        vm.prank(enterprise);
        agentReg.updateStatus(agentId, AgentStatus.Suspended);
        assertEq(uint256(agentReg.resolve(agentId).status), uint256(AgentStatus.Suspended));
    }

    function test_updateStatus_byAdmin() public {
        // admin = address(this). No prank — called directly as admin
        agentReg.updateStatus(agentId, AgentStatus.Revoked);
        assertEq(uint256(agentReg.resolve(agentId).status), uint256(AgentStatus.Revoked));
    }

    function test_updateStatus_revertsForStranger() public {
        vm.prank(stranger);
        vm.expectRevert();
        agentReg.updateStatus(agentId, AgentStatus.Suspended);
    }

    function test_updateStatus_revertsForUnknownAgent() public {
        vm.prank(enterprise);
        vm.expectRevert();
        agentReg.updateStatus(bytes32(uint256(0xDEAD)), AgentStatus.Suspended);
    }

    // ── isActive ─────────────────────────────────────────────────

    function test_isActive_trueForActiveAgent() public view {
        assertTrue(agentReg.isActive(agentId));
    }

    function test_isActive_falseAfterSuspend() public {
        vm.prank(enterprise);
        agentReg.updateStatus(agentId, AgentStatus.Suspended);
        assertFalse(agentReg.isActive(agentId));
    }

    // ── multi-agent per owner ─────────────────────────────────────

    function test_multiAgent_uniqueIds() public {
        address wallet2 = vm.addr(0xCAFE);
        vm.prank(enterprise);
        bytes32 agentId2 = agentReg.register(wallet2, "claude-3", bytes32(0), "");
        assertTrue(agentId2 != agentId);
        assertEq(agentReg.totalAgents(), 2);
        assertEq(agentReg.getAgentsByOwner(enterprise).length, 2);
    }

    // ── Helper (mirrors AgentRegistry internal) ──────────────────

    function _toLower40(address addr) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        uint160 value = uint160(addr);
        bytes memory buf = new bytes(40);
        for (uint256 i = 40; i > 0; ) {
            unchecked { i--; }
            buf[i] = hexChars[value & 0xf];
            value >>= 4;
        }
        return string(buf);
    }
}

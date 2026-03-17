// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";

/// @title PermissionVault Unit Tests
/// Covers: grantPermission (EIP-712), validateUserOp (15 steps), revokePermission,
///         emergencyRevoke, getActiveScope, pause
contract PermissionVaultTest is BouclierTestBase {
    // ── grantPermission ───────────────────────────────────────────

    function test_grantPermission_storesScope() public {
        _grantDefaultScope();
        PermissionScope memory s = vault.getActiveScope(agentId);
        assertEq(s.agentId, agentId);
        assertTrue(s.allowAnyProtocol);
        assertTrue(s.allowAnyToken);
        assertEq(s.dailySpendCapUSD, USD_1000);
        assertFalse(s.revoked);
    }

    function test_grantPermission_incrementsNonce() public {
        assertEq(vault.grantNonces(agentId), 0);
        _grantDefaultScope();
        assertEq(vault.grantNonces(agentId), 1);
    }

    function test_grantPermission_revertsForWrongOwner() public {
        address[] memory noList = new address[](0);
        bytes4[]  memory noSel  = new bytes4[](0);
        (PermissionScope memory scope,) =
            _buildAndSignScope(noList, noSel, noList, USD_1000, USD_100, true, true);

        // Sign with stranger's key — should be rejected
        bytes memory wrongSig = _signScope(scope, STRANGER_KEY);

        vm.prank(stranger);
        vm.expectRevert();
        vault.grantPermission(agentId, scope, wrongSig);
    }

    function test_grantPermission_revertsForReplayedSig() public {
        address[] memory noList = new address[](0);
        bytes4[]  memory noSel  = new bytes4[](0);
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(noList, noSel, noList, USD_1000, USD_100, true, true);

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Attempt to replay the same signature — nonce has advanced
        vm.prank(enterprise);
        vm.expectRevert();
        vault.grantPermission(agentId, scope, sig);
    }

    function test_grantPermission_revertsForExpiredScope() public {
        address[] memory noList = new address[](0);
        bytes4[]  memory noSel  = new bytes4[](0);
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(noList, noSel, noList, USD_1000, USD_100, true, true);

        // Warp past validUntil
        vm.warp(scope.validUntil + 1);
        vm.prank(enterprise);
        vm.expectRevert();
        vault.grantPermission(agentId, scope, sig);
    }

    // ── validateUserOp — success path ─────────────────────────────

    function test_validateUserOp_succeedsWithPermissiveScope() public {
        _grantDefaultScope();

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        uint256 result = vault.validateUserOp(op, bytes32(0));
        assertEq(result, VALIDATION_SUCCESS);
    }

    // ── validateUserOp step 2: agent not registered ───────────────

    function test_validateUserOp_failsForUnregisteredAgent() public {
        _grantDefaultScope();
        // Use a wallet that is NOT registered
        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        op.sender = stranger;
        uint256 result = vault.validateUserOp(op, bytes32(0));
        assertEq(result, VALIDATION_FAILED);
    }

    // ── validateUserOp step 3: agent not active ───────────────────

    function test_validateUserOp_failsForSuspendedAgent() public {
        _grantDefaultScope();
        vm.prank(enterprise);
        agentReg.updateStatus(agentId, AgentStatus.Suspended);

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    // ── validateUserOp step 4: revocation ────────────────────────

    function test_validateUserOp_failsForRevokedAgent() public {
        _grantDefaultScope();
        revRegistry.revoke(agentId, RevocationReason.Emergency, "test");

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    // ── validateUserOp step 5/6: no scope / scope revoked ────────

    function test_validateUserOp_failsForNoScope() public {
        // No scope granted — agentId registered but no scope
        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    function test_validateUserOp_failsForRevokedScope() public {
        _grantDefaultScope();
        vm.prank(enterprise);
        vault.revokePermission(agentId);

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    // ── validateUserOp step 7: validity window ────────────────────

    function test_validateUserOp_failsBeforeValidFrom() public {
        address[] memory noList = new address[](0);
        bytes4[]  memory noSel  = new bytes4[](0);
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(noList, noSel, noList, USD_1000, USD_100, true, true);

        // Set validFrom to the future
        scope.validFrom = uint48(block.timestamp + 1 days);
        scope.validUntil = uint48(block.timestamp + 30 days);
        sig = _signScope(scope, ENTERPRISE_KEY);

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    function test_validateUserOp_failsAfterValidUntil() public {
        _grantDefaultScope();
        vm.warp(block.timestamp + 31 days); // past validUntil

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    // ── validateUserOp step 8: protocol allowlist ─────────────────

    function test_validateUserOp_failsForDisallowedProtocol() public {
        address[] memory protocols = new address[](1);
        protocols[0] = address(0xAABB); // only this target allowed
        bytes4[]  memory noSel  = new bytes4[](0);
        address[] memory noTokens = new address[](0);
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(protocols, noSel, noTokens, USD_1000, USD_100, false, true);

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Call to a DIFFERENT target — should fail
        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    function test_validateUserOp_succeedsForAllowedProtocol() public {
        address targetAddr = address(0xAABB);
        address[] memory protocols = new address[](1);
        protocols[0] = targetAddr;
        bytes4[]  memory noSel    = new bytes4[](0);
        address[] memory noTokens = new address[](0);
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(protocols, noSel, noTokens, USD_1000, USD_100, false, true);

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        PackedUserOperation memory op = _buildUserOp(targetAddr, 0, "");
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_SUCCESS);
    }

    // ── validateUserOp step 9: selector filter ────────────────────

    function test_validateUserOp_failsForDisallowedSelector() public {
        address[] memory noList = new address[](0);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = APPROVE_SEL;
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(noList, selectors, noList, USD_1000, USD_100, true, true);

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Build a UserOp that calls execute(target, 0, transfer(...)) — selector = TRANSFER_SEL
        bytes memory inner = abi.encodeWithSelector(TRANSFER_SEL, address(0xABCD), 100e6);
        PackedUserOperation memory op = _buildUserOp(USDC, 0, inner);
        assertEq(vault.validateUserOp(op, bytes32(0)), VALIDATION_FAILED);
    }

    // ── revokePermission ──────────────────────────────────────────

    function test_revokePermission_byOwner() public {
        _grantDefaultScope();
        vm.prank(enterprise);
        vault.revokePermission(agentId);
        assertTrue(vault.getActiveScope(agentId).revoked);
    }

    function test_revokePermission_revertsForStranger() public {
        _grantDefaultScope();
        vm.prank(stranger);
        vm.expectRevert();
        vault.revokePermission(agentId);
    }

    // ── emergencyRevoke ───────────────────────────────────────────

    function test_emergencyRevoke_setsRevocationRegistry() public {
        _grantDefaultScope();
        vault.emergencyRevoke(agentId); // called as owner (admin)
        assertTrue(revRegistry.isRevoked(agentId));
        assertTrue(vault.getActiveScope(agentId).revoked);
    }

    // ── pause ─────────────────────────────────────────────────────

    function test_pause_blocksValidateUserOp() public {
        _grantDefaultScope();
        vault.pause();

        PackedUserOperation memory op = _buildUserOp(address(0xDEF1), 0, "");
        vm.expectRevert();
        vault.validateUserOp(op, bytes32(0));
    }

    // ── getActiveScope ────────────────────────────────────────────

    function test_getActiveScope_returnsEmptyForUnknownAgent() public view {
        PermissionScope memory s = vault.getActiveScope(bytes32(uint256(0xDEAD)));
        assertEq(s.agentId, bytes32(0));
    }
}

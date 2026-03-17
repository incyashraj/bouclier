// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../helpers/TestBase.sol";
import "../../src/ERC6900Adapter.sol";

contract ERC6900AdapterTest is BouclierTestBase {
    ERC6900Adapter internal adapter;

    function setUp() public override {
        super.setUp();
        adapter = new ERC6900Adapter(address(vault));
    }

    // ── Module identity ─────────────────────────────────────────

    function test_moduleId() public view {
        assertEq(adapter.moduleId(), "bouclier.permission-vault.v1");
    }

    // ── Install / Uninstall ─────────────────────────────────────

    function test_onInstall_tracksAccount() public {
        assertFalse(adapter.installed(address(this)));
        adapter.onInstall("");
        assertTrue(adapter.installed(address(this)));
    }

    function test_onUninstall_removesAccount() public {
        adapter.onInstall("");
        assertTrue(adapter.installed(address(this)));
        adapter.onUninstall("");
        assertFalse(adapter.installed(address(this)));
    }

    // ── validateUserOp delegation ───────────────────────────────

    function test_validateUserOp_delegatesToVault_agentNotRegistered() public {
        // Build a UserOp from an unregistered address
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(0xDEAD),
            nonce: 0,
            initCode: "",
            callData: abi.encodeWithSelector(bytes4(0xb61d27f6), address(0x1234), uint256(0), ""),
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });

        uint256 result = adapter.validateUserOp(0, userOp, keccak256("test"));
        assertEq(result, VALIDATION_FAILED, "Unregistered agent should fail");
    }

    function test_validateUserOp_delegatesToVault_noScope() public {
        // agentWallet is registered but has no scope
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: agentWallet,
            nonce: 0,
            initCode: "",
            callData: abi.encodeWithSelector(bytes4(0xb61d27f6), address(0x1234), uint256(0), ""),
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });

        uint256 result = adapter.validateUserOp(0, userOp, keccak256("test"));
        assertEq(result, VALIDATION_FAILED, "Agent without scope should fail");
    }

    function test_validateUserOp_delegatesToVault_withScope() public {
        // Grant a broad scope
        address[] memory protocols = new address[](0);
        bytes4[]  memory selectors = new bytes4[](0);
        address[] memory tokens    = new address[](0);

        (PermissionScope memory scope, bytes memory sig) = _buildAndSignScope(
            protocols, selectors, tokens,
            USD_1000, USD_100,
            true,  // anyProtocol
            true   // anyToken
        );

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Now validate through the adapter
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: agentWallet,
            nonce: 0,
            initCode: "",
            callData: abi.encodeWithSelector(bytes4(0xb61d27f6), address(0x1234), uint256(0), ""),
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });

        uint256 result = adapter.validateUserOp(0, userOp, keccak256("test"));
        assertEq(result, VALIDATION_SUCCESS, "Agent with valid scope should succeed");
    }

    // ── Runtime validation ──────────────────────────────────────

    function test_validateRuntime_reverts() public {
        vm.expectRevert("ERC6900Adapter: runtime validation not supported - use UserOp flow");
        adapter.validateRuntime(address(this), 0, address(this), 0, "", "");
    }

    // ── Signature validation ────────────────────────────────────

    function test_validateSignature_returnsFailure() public view {
        bytes4 result = adapter.validateSignature(address(this), 0, address(this), bytes32(0), "");
        assertEq(result, bytes4(0xffffffff));
    }
}

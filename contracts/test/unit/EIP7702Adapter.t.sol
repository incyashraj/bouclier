// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../helpers/TestBase.sol";
import "../../src/EIP7702Adapter.sol";

contract EIP7702AdapterTest is BouclierTestBase {
    EIP7702Adapter internal adapter;

    // Delegator (EOA owner) — separate from enterprise (agent owner)
    uint256 internal constant DELEGATOR_KEY = 0xDE1E6;
    address internal delegator;

    function setUp() public override {
        super.setUp();
        delegator = vm.addr(DELEGATOR_KEY);

        adapter = new EIP7702Adapter(
            address(this),
            address(vault),
            address(agentReg)
        );
    }

    // ── Helpers ──────────────────────────────────────────────────

    function _signDelegation(
        address _delegator,
        address _agent,
        uint256 nonce,
        uint48  expiry,
        uint256 signerKey
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(
            adapter.DELEGATION_TYPEHASH(),
            _delegator,
            _agent,
            nonce,
            expiry
        ));
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            adapter.DOMAIN_SEPARATOR(),
            structHash
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // ── Tests ────────────────────────────────────────────────────

    function test_createDelegation_success() public {
        uint48 expiry = uint48(block.timestamp + 1 days);
        bytes memory sig = _signDelegation(delegator, agentWallet, 0, expiry, DELEGATOR_KEY);

        vm.prank(delegator);
        adapter.createDelegation(agentWallet, expiry, sig);

        assertTrue(adapter.isDelegationActive(delegator, agentWallet));
    }

    function test_createDelegation_revert_unregisteredAgent() public {
        address fakeAgent = address(0xFAFAFA);
        uint48 expiry = uint48(block.timestamp + 1 days);
        bytes memory sig = _signDelegation(delegator, fakeAgent, 0, expiry, DELEGATOR_KEY);

        vm.prank(delegator);
        vm.expectRevert("EIP7702Adapter: agent not registered");
        adapter.createDelegation(fakeAgent, expiry, sig);
    }

    function test_createDelegation_revert_expiredExpiry() public {
        uint48 expiry = uint48(block.timestamp - 1);
        bytes memory sig = _signDelegation(delegator, agentWallet, 0, expiry, DELEGATOR_KEY);

        vm.prank(delegator);
        vm.expectRevert("EIP7702Adapter: delegation already expired");
        adapter.createDelegation(agentWallet, expiry, sig);
    }

    function test_revokeDelegation() public {
        uint48 expiry = uint48(block.timestamp + 1 days);
        bytes memory sig = _signDelegation(delegator, agentWallet, 0, expiry, DELEGATOR_KEY);

        vm.prank(delegator);
        adapter.createDelegation(agentWallet, expiry, sig);
        assertTrue(adapter.isDelegationActive(delegator, agentWallet));

        vm.prank(delegator);
        adapter.revokeDelegation(agentWallet);
        assertFalse(adapter.isDelegationActive(delegator, agentWallet));
    }

    function test_revokeDelegation_revert_noDelegation() public {
        vm.prank(delegator);
        vm.expectRevert("EIP7702Adapter: no active delegation");
        adapter.revokeDelegation(agentWallet);
    }

    function test_validateDelegatedOp_failsWithoutDelegation() public {
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

        uint256 result = adapter.validateDelegatedOp(delegator, userOp, keccak256("test"));
        assertEq(result, VALIDATION_FAILED);
    }

    function test_validateDelegatedOp_failsWhenExpired() public {
        uint48 expiry = uint48(block.timestamp + 1 hours);
        bytes memory sig = _signDelegation(delegator, agentWallet, 0, expiry, DELEGATOR_KEY);

        vm.prank(delegator);
        adapter.createDelegation(agentWallet, expiry, sig);

        // Fast forward past expiry
        vm.warp(block.timestamp + 2 hours);

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

        uint256 result = adapter.validateDelegatedOp(delegator, userOp, keccak256("test"));
        assertEq(result, VALIDATION_FAILED);

        // Delegation should be auto-expired
        assertFalse(adapter.isDelegationActive(delegator, agentWallet));
    }

    function test_delegationNonceIncrements() public {
        uint48 expiry = uint48(block.timestamp + 1 days);

        bytes memory sig1 = _signDelegation(delegator, agentWallet, 0, expiry, DELEGATOR_KEY);
        vm.prank(delegator);
        adapter.createDelegation(agentWallet, expiry, sig1);

        assertEq(adapter.delegationNonces(delegator), 1);

        // Revoke and create again with new nonce
        vm.prank(delegator);
        adapter.revokeDelegation(agentWallet);

        bytes memory sig2 = _signDelegation(delegator, agentWallet, 1, expiry, DELEGATOR_KEY);
        vm.prank(delegator);
        adapter.createDelegation(agentWallet, expiry, sig2);

        assertEq(adapter.delegationNonces(delegator), 2);
    }

    function test_pause_blocksDelegation() public {
        adapter.pause();

        uint48 expiry = uint48(block.timestamp + 1 days);
        bytes memory sig = _signDelegation(delegator, agentWallet, 0, expiry, DELEGATOR_KEY);

        vm.prank(delegator);
        vm.expectRevert();
        adapter.createDelegation(agentWallet, expiry, sig);
    }
}

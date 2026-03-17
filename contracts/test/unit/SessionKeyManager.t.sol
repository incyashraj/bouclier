// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";
import "../../src/SessionKeyManager.sol";

contract SessionKeyManagerTest is BouclierTestBase {
    SessionKeyManager public skm;

    // Session key holder (ephemeral key)
    uint256 internal constant SESSION_PRIV = 0xC0FFEE;
    address internal sessionKey;

    // Master key (hardware wallet) — reuse ENTERPRISE_KEY from Constants
    uint256 internal masterPriv = ENTERPRISE_KEY;
    address internal masterAddr;

    address internal sessionTarget;

    function setUp() public override {
        super.setUp();
        skm = new SessionKeyManager(address(vault), admin);
        sessionKey = vm.addr(SESSION_PRIV);
        masterAddr = vm.addr(masterPriv);
        sessionTarget = address(0xBEEF);

        // Fund session key to pay for gas
        vm.deal(sessionKey, 10 ether);
    }

    // ── Helpers ───────────────────────────────────────────────────

    function _makeGrant(
        uint48 validAfter,
        uint48 validUntil,
        uint256 spendLimit,
        uint256 nonce
    ) internal view returns (SessionKeyManager.SessionGrant memory) {
        address[] memory targets = new address[](1);
        targets[0] = sessionTarget;
        return SessionKeyManager.SessionGrant({
            sessionKey: sessionKey,
            agentId: agentId,
            allowedTargets: targets,
            spendLimit: spendLimit,
            validAfter: validAfter,
            validUntil: validUntil,
            nonce: nonce
        });
    }

    function _signGrant(
        SessionKeyManager.SessionGrant memory grant,
        uint256 privKey
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(
            skm.SESSION_GRANT_TYPEHASH(),
            grant.sessionKey,
            grant.agentId,
            keccak256(abi.encodePacked(grant.allowedTargets)),
            grant.spendLimit,
            grant.validAfter,
            grant.validUntil,
            grant.nonce
        ));

        bytes32 domainSeparator = skm.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // ── Tests ─────────────────────────────────────────────────────

    function test_executeViaSession_succeeds() public {
        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 hours),
            1000e18, // $1000 limit
            1
        );
        bytes memory sig = _signGrant(grant, masterPriv);

        // Deploy a simple receiver contract
        SimpleReceiver receiver = new SimpleReceiver();
        address[] memory targets = new address[](1);
        targets[0] = address(receiver);
        grant.allowedTargets = targets;
        sig = _signGrant(grant, masterPriv);

        vm.prank(sessionKey);
        skm.executeViaSession(grant, sig, address(receiver), 0, "", 100e18);

        assertTrue(receiver.called());
    }

    function test_executeViaSession_revertsIfExpired() public {
        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 2 hours),
            uint48(block.timestamp - 1 hours), // already expired
            1000e18,
            2
        );
        bytes memory sig = _signGrant(grant, masterPriv);

        vm.prank(sessionKey);
        vm.expectRevert(SessionKeyManager.SessionExpired.selector);
        skm.executeViaSession(grant, sig, sessionTarget, 0, "", 0);
    }

    function test_executeViaSession_revertsIfNotYetActive() public {
        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp + 1 hours), // not yet active
            uint48(block.timestamp + 2 hours),
            1000e18,
            3
        );
        bytes memory sig = _signGrant(grant, masterPriv);

        vm.prank(sessionKey);
        vm.expectRevert(SessionKeyManager.SessionNotYetActive.selector);
        skm.executeViaSession(grant, sig, sessionTarget, 0, "", 0);
    }

    function test_executeViaSession_revertsOnWrongTarget() public {
        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 hours),
            1000e18,
            4
        );
        bytes memory sig = _signGrant(grant, masterPriv);

        vm.prank(sessionKey);
        vm.expectRevert(abi.encodeWithSelector(
            SessionKeyManager.TargetNotAllowed.selector, address(0xDEAD)
        ));
        skm.executeViaSession(grant, sig, address(0xDEAD), 0, "", 0);
    }

    function test_executeViaSession_revertsOnSpendLimitExceeded() public {
        SimpleReceiver receiver = new SimpleReceiver();
        address[] memory targets = new address[](1);
        targets[0] = address(receiver);

        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 hours),
            100e18, // $100 limit
            5
        );
        grant.allowedTargets = targets;
        bytes memory sig = _signGrant(grant, masterPriv);

        vm.prank(sessionKey);
        vm.expectRevert(abi.encodeWithSelector(
            SessionKeyManager.SessionSpendLimitExceeded.selector, 200e18, 100e18
        ));
        skm.executeViaSession(grant, sig, address(receiver), 0, "", 200e18);
    }

    function test_revokeSession_preventsExecution() public {
        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 hours),
            1000e18,
            6
        );
        bytes memory sig = _signGrant(grant, masterPriv);

        // Master revokes before session key uses it
        vm.prank(masterAddr);
        skm.revokeSession(6);
        assertTrue(skm.usedNonces(masterAddr, 6));

        vm.prank(sessionKey);
        vm.expectRevert(SessionKeyManager.SessionNonceUsed.selector);
        skm.executeViaSession(grant, sig, sessionTarget, 0, "", 0);
    }

    function test_isSessionValid_returnsCorrectly() public {
        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 hours),
            1000e18,
            7
        );
        bytes memory sig = _signGrant(grant, masterPriv);

        (bool valid, address master) = skm.isSessionValid(grant, sig);
        assertTrue(valid);
        assertEq(master, masterAddr);
    }

    function test_remainingBudget_tracksSpend() public {
        SimpleReceiver receiver = new SimpleReceiver();
        address[] memory targets = new address[](1);
        targets[0] = address(receiver);

        SessionKeyManager.SessionGrant memory grant = _makeGrant(
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 hours),
            500e18,
            8
        );
        grant.allowedTargets = targets;
        bytes memory sig = _signGrant(grant, masterPriv);

        assertEq(skm.remainingBudget(sessionKey, agentId, 8, 500e18), 500e18);

        vm.prank(sessionKey);
        skm.executeViaSession(grant, sig, address(receiver), 0, "", 200e18);

        assertEq(skm.remainingBudget(sessionKey, agentId, 8, 500e18), 300e18);
    }

    function test_batchRevokeSession() public {
        uint256[] memory nonces = new uint256[](3);
        nonces[0] = 10;
        nonces[1] = 11;
        nonces[2] = 12;

        vm.prank(masterAddr);
        skm.batchRevokeSession(nonces);

        assertTrue(skm.usedNonces(masterAddr, 10));
        assertTrue(skm.usedNonces(masterAddr, 11));
        assertTrue(skm.usedNonces(masterAddr, 12));
    }
}

/// @dev Minimal receiver contract for session key execution tests
contract SimpleReceiver {
    bool public called;

    fallback() external payable {
        called = true;
    }

    receive() external payable {
        called = true;
    }
}

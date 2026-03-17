// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";
import "../../src/FeeCollector.sol";

contract FeeCollectorTest is BouclierTestBase {
    FeeCollector public fc;
    address internal treasury;

    function setUp() public override {
        super.setUp();
        treasury = makeAddr("treasury");
        fc = new FeeCollector(admin, treasury);
        // Grant COLLECTOR_ROLE to this test contract so we can call collectFee
        fc.grantRole(fc.COLLECTOR_ROLE(), address(this));
    }

    // ── Fee setting ───────────────────────────────────────────────

    function test_setFee_setsGrantFee() public {
        fc.setFee(FeeCollector.FeeType.Grant, 0.005 ether);
        assertEq(fc.fees(FeeCollector.FeeType.Grant), 0.005 ether);
    }

    function test_setFee_revertsAboveMax() public {
        vm.expectRevert(abi.encodeWithSelector(
            FeeCollector.FeeExceedsMaximum.selector,
            FeeCollector.FeeType.Grant,
            0.02 ether,
            fc.MAX_GRANT_FEE()
        ));
        fc.setFee(FeeCollector.FeeType.Grant, 0.02 ether); // MAX is 0.01
    }

    function test_setFee_revertsForNonAdmin() public {
        vm.prank(stranger);
        vm.expectRevert();
        fc.setFee(FeeCollector.FeeType.Grant, 0.001 ether);
    }

    // ── Fee collection ────────────────────────────────────────────

    function test_collectFee_succeeds() public {
        fc.setFee(FeeCollector.FeeType.Grant, 0.001 ether);

        fc.collectFee{value: 0.001 ether}(FeeCollector.FeeType.Grant, address(this));

        assertEq(fc.totalCollected(), 0.001 ether);
        assertEq(address(fc).balance, 0.001 ether);
    }

    function test_collectFee_refundsExcess() public {
        fc.setFee(FeeCollector.FeeType.Grant, 0.001 ether);

        uint256 balBefore = address(this).balance;
        fc.collectFee{value: 0.005 ether}(FeeCollector.FeeType.Grant, address(this));

        // Should have refunded 0.004 ether
        assertEq(address(fc).balance, 0.001 ether);
        assertEq(fc.totalCollected(), 0.001 ether);
    }

    function test_collectFee_noopWhenFeeIsZero() public {
        // Fee defaults to 0 — should be a no-op
        fc.collectFee{value: 0}(FeeCollector.FeeType.Grant, address(this));
        assertEq(fc.totalCollected(), 0);
    }

    function test_collectFee_revertsOnInsufficientFee() public {
        fc.setFee(FeeCollector.FeeType.Anchor, 0.002 ether);

        vm.expectRevert(abi.encodeWithSelector(
            FeeCollector.InsufficientFee.selector, 0.002 ether, 0.001 ether
        ));
        fc.collectFee{value: 0.001 ether}(FeeCollector.FeeType.Anchor, address(this));
    }

    // ── Withdrawal ────────────────────────────────────────────────

    function test_withdraw_sendToTreasury() public {
        fc.setFee(FeeCollector.FeeType.Registration, 0.01 ether);
        fc.collectFee{value: 0.01 ether}(FeeCollector.FeeType.Registration, address(this));

        uint256 treasuryBefore = treasury.balance;
        fc.withdraw();

        assertEq(address(fc).balance, 0);
        assertEq(treasury.balance, treasuryBefore + 0.01 ether);
    }

    function test_withdraw_revertsForNonTreasury() public {
        vm.prank(stranger);
        vm.expectRevert();
        fc.withdraw();
    }

    // ── Treasury update ───────────────────────────────────────────

    function test_setTreasury_updates() public {
        address newTreasury = address(0xBEEF);
        fc.setTreasury(newTreasury);
        assertEq(fc.treasury(), newTreasury);
    }

    function test_setTreasury_revertsOnZero() public {
        vm.expectRevert(FeeCollector.ZeroAddress.selector);
        fc.setTreasury(address(0));
    }

    // ── Pause ─────────────────────────────────────────────────────

    function test_collectFee_revertsWhenPaused() public {
        fc.setFee(FeeCollector.FeeType.Grant, 0.001 ether);
        fc.pause();

        vm.expectRevert();
        fc.collectFee{value: 0.001 ether}(FeeCollector.FeeType.Grant, address(this));
    }

    // ── Receive ETH ───────────────────────────────────────────────
    receive() external payable {}
}

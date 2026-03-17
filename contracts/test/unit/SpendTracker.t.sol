// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/TestBase.sol";

/// @dev Minimal Chainlink AggregatorV3 mock for tests.
contract MockAggregatorV3 {
    int256  public latestAnswer;
    uint256 public latestUpdatedAt;
    uint8   public feedDecimals;

    constructor(int256 _answer, uint8 _decimals) {
        latestAnswer    = _answer;
        latestUpdatedAt = block.timestamp;
        feedDecimals    = _decimals;
    }

    function decimals() external view returns (uint8) { return feedDecimals; }

    function latestRoundData()
        external view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, latestAnswer, 0, latestUpdatedAt, 0);
    }

    function setAnswer(int256 _answer) external { latestAnswer = _answer; }
    function setUpdatedAt(uint256 _t)  external { latestUpdatedAt = _t; }
}

/// @title SpendTracker Unit Tests
/// Covers: recordSpend, checkSpendCap, getRollingSpend, getUSDValue (mock oracle), stale feed
contract SpendTrackerTest is BouclierTestBase {
    MockAggregatorV3 internal ethFeed;
    address internal constant WETH_LOCAL = address(0xEEEE);

    function setUp() public override {
        super.setUp();
        // ETH/USD at $3,000 (8-decimal Chainlink feed)
        ethFeed = new MockAggregatorV3(3000e8, 8);
        spendTracker.setPriceFeed(WETH_LOCAL, address(ethFeed));
    }

    // ── recordSpend ───────────────────────────────────────────────

    function test_recordSpend_byVaultRole() public {
        // admin currently holds VAULT_ROLE — record via admin (this contract)
        spendTracker.recordSpend(agentId, USD_50, uint48(block.timestamp));
        assertEq(spendTracker.getRollingSpend(agentId, 86400), USD_50);
    }

    function test_recordSpend_revertsWithoutRole() public {
        vm.prank(stranger);
        vm.expectRevert();
        spendTracker.recordSpend(agentId, USD_50, uint48(block.timestamp));
    }

    function test_recordSpend_revertsOnOverflow() public {
        uint256 tooBig = uint256(type(uint208).max) + 1;
        vm.expectRevert("SpendTracker: amount overflow");
        spendTracker.recordSpend(agentId, tooBig, uint48(block.timestamp));
    }

    function test_recordSpend_accumulatesRolling() public {
        spendTracker.recordSpend(agentId, USD_50, uint48(block.timestamp));
        spendTracker.recordSpend(agentId, USD_50, uint48(block.timestamp));
        assertEq(spendTracker.getRollingSpend(agentId, 86400), USD_50 + USD_50);
    }

    // ── rolling window ────────────────────────────────────────────

    function test_rollingSpend_excludesOldEntries() public {
        // Record now
        spendTracker.recordSpend(agentId, USD_100, uint48(block.timestamp));
        // Advance time by 25 hours — entry falls outside 24h window
        vm.warp(block.timestamp + 25 hours);
        assertEq(spendTracker.getRollingSpend(agentId, 86400), 0);
    }

    function test_rollingSpend_includesRecentEntries() public {
        spendTracker.recordSpend(agentId, USD_100, uint48(block.timestamp));
        vm.warp(block.timestamp + 12 hours);
        spendTracker.recordSpend(agentId, USD_50, uint48(block.timestamp));
        // Both within 24h window
        assertEq(spendTracker.getRollingSpend(agentId, 86400), USD_100 + USD_50);
    }

    // ── checkSpendCap ─────────────────────────────────────────────

    function test_checkSpendCap_trueWhenWithin() public {
        spendTracker.recordSpend(agentId, USD_50, uint48(block.timestamp));
        bool ok = spendTracker.checkSpendCap(agentId, USD_50, USD_1000);
        assertTrue(ok);
    }

    function test_checkSpendCap_falseWhenExceeded() public {
        spendTracker.recordSpend(agentId, USD_1000, uint48(block.timestamp));
        bool ok = spendTracker.checkSpendCap(agentId, USD_1, USD_1000);
        assertFalse(ok);
    }

    function test_checkSpendCap_zeroCapMeansNoLimit() public view {
        assertTrue(spendTracker.checkSpendCap(agentId, type(uint128).max, 0));
    }

    // ── getUSDValue (mock oracle) ─────────────────────────────────

    function test_getUSDValue_eth() public view {
        // 1 ETH = $3,000 — token decimals = 18, feed decimals = 8
        uint256 usd = spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
        assertEq(usd, 3000e18);
    }

    function test_getUSDValue_revertsForNoFeed() public {
        vm.expectRevert("SpendTracker: no price feed for token");
        spendTracker.getUSDValue(address(0xBEEF), 1 ether);
    }

    function test_getUSDValue_revertsOnNegativePrice() public {
        ethFeed.setAnswer(-1);
        vm.expectRevert("SpendTracker: negative or zero oracle price");
        spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
    }

    function test_getUSDValue_revertsOnStaleOracle() public {
        ethFeed.setUpdatedAt(block.timestamp - 4000); // > MAX_FEED_AGE (3600)
        vm.expectRevert("SpendTracker: stale oracle price");
        spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
    }

    // ── ring buffer wrap ──────────────────────────────────────────

    function test_ringBuffer_wrapsCorrectly() public {
        // SpendTracker.MAX_ENTRIES = 1000; fill 1001 entries and check oldest is evicted
        uint256 MAX = 1000;
        for (uint256 i = 0; i <= MAX; i++) {
            spendTracker.recordSpend(agentId, USD_1, uint48(block.timestamp));
        }
        // Ring wrapped: rolling spend = MAX * USD_1 (oldest was overwritten)
        assertEq(spendTracker.getRollingSpend(agentId, 86400), MAX * USD_1);
    }

    // ── circuit breaker ───────────────────────────────────────────

    function test_circuitBreaker_setsAnchorOnSetPriceFeed() public view {
        // setPriceFeed was called in setUp — anchor should be set
        assertEq(spendTracker.getAnchorPrice(WETH_LOCAL), 3000e18);
    }

    function test_circuitBreaker_passesWithinThreshold() public {
        // 5% of 3000 = 150. Change price to 3149 (< 5% deviation)
        ethFeed.setAnswer(3149e8);
        uint256 usd = spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
        assertEq(usd, 3149e18);
    }

    function test_circuitBreaker_passesAtExactThreshold() public view {
        // Exactly 5% above: 3000 * 1.05 = 3150
        // anchor=3000e18, price=3150e18, diff=150e18
        // diff * 10000 = 150e18 * 10000 = 1500000e18
        // anchor * 500 = 3000e18 * 500 = 1500000e18 — equal, so passes
        uint256 usd = spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
        assertEq(usd, 3000e18); // default price, within threshold
    }

    function test_circuitBreaker_revertsAboveThreshold() public {
        // 6% above anchor: 3000 * 1.06 = 3180
        ethFeed.setAnswer(3180e8);
        vm.expectRevert("SpendTracker: oracle price deviation exceeds threshold");
        spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
    }

    function test_circuitBreaker_revertsOnLargeDrop() public {
        // 10% below anchor: 3000 * 0.90 = 2700
        ethFeed.setAnswer(2700e8);
        vm.expectRevert("SpendTracker: oracle price deviation exceeds threshold");
        spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
    }

    function test_circuitBreaker_refreshAnchorUnlocksNewPrice() public {
        // Price moves 10% — circuit breaker trips
        ethFeed.setAnswer(3300e8);
        vm.expectRevert("SpendTracker: oracle price deviation exceeds threshold");
        spendTracker.getUSDValue(WETH_LOCAL, 1 ether);

        // Admin refreshes anchor to accept the new price
        spendTracker.refreshAnchorPrice(WETH_LOCAL);
        assertEq(spendTracker.getAnchorPrice(WETH_LOCAL), 3300e18);

        // Now the query succeeds
        uint256 usd = spendTracker.getUSDValue(WETH_LOCAL, 1 ether);
        assertEq(usd, 3300e18);
    }

    function test_circuitBreaker_refreshAnchorRevertsForNonAdmin() public {
        vm.prank(stranger);
        vm.expectRevert();
        spendTracker.refreshAnchorPrice(WETH_LOCAL);
    }

    function test_circuitBreaker_refreshAnchorRevertsForNoFeed() public {
        vm.expectRevert("SpendTracker: no price feed for token");
        spendTracker.refreshAnchorPrice(address(0xDEAD));
    }
}

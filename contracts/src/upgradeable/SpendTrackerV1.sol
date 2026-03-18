// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IBouclier.sol";

/// @dev Minimal Chainlink AggregatorV3 interface
interface IAggV3 {
    function latestRoundData() external view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

/// @title  SpendTrackerV1
/// @notice UUPS-upgradeable version of SpendTracker.
///         Tracks rolling 24-hour USD spend per agent using a ring buffer.
contract SpendTrackerV1 is Initializable, UUPSUpgradeable, AccessControl, Pausable, ISpendTracker {

    bytes32 public constant VAULT_ROLE    = keccak256("VAULT_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant MAX_ENTRIES = 1000;

    struct SpendEntry {
        uint48  timestamp;
        uint208 usdAmount18;
    }

    mapping(bytes32 agentId => SpendEntry[MAX_ENTRIES]) private _ring;
    mapping(bytes32 agentId => uint256)                 private _head;
    mapping(address => address) private _priceFeeds;
    mapping(address => uint256) private _anchorPrices;

    uint256 public constant MAX_FEED_AGE   = 3600;
    uint256 public constant DEVIATION_BPS  = 500;
    uint256 public constant TWAP_ROUNDS    = 4;
    bool    public twapFallbackEnabled     = true;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address _admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VAULT_ROLE,    _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    // ── Spend recording ───────────────────────────────────────────

    function recordSpend(bytes32 agentId, uint256 usdAmount18, uint48 timestamp)
        external onlyRole(VAULT_ROLE) whenNotPaused
    {
        uint256 head = _head[agentId];
        require(usdAmount18 <= type(uint208).max, "SpendTrackerV1: amount overflow");
        _ring[agentId][head % MAX_ENTRIES] = SpendEntry({
            timestamp:   timestamp,
            usdAmount18: uint208(usdAmount18)
        });
        _head[agentId] = head + 1;
    }

    // ── Rolling spend ─────────────────────────────────────────────

    function getRollingSpend(bytes32 agentId, uint256 windowSeconds)
        external view returns (uint256 total)
    {
        uint256 head      = _head[agentId];
        uint256 cutoff    = block.timestamp - windowSeconds;
        uint256 entries   = head < MAX_ENTRIES ? head : MAX_ENTRIES;

        for (uint256 i = 0; i < entries; i++) {
            SpendEntry storage entry = _ring[agentId][i];
            if (entry.timestamp >= cutoff) {
                total += entry.usdAmount18;
            }
        }
    }

    function checkSpendCap(bytes32 agentId, uint256 proposedUsd, uint256 capUsd)
        external view returns (bool)
    {
        uint256 rolling = this.getRollingSpend(agentId, 86400);
        return rolling + proposedUsd <= capUsd;
    }

    // ── Feed management ───────────────────────────────────────────

    function getUSDValue(address token, uint256 amount) external view returns (uint256 usdValue18) {
        address feedAddr = _priceFeeds[token];
        require(feedAddr != address(0), "SpendTrackerV1: no price feed for token");
        IAggV3 feed = IAggV3(feedAddr);
        (, int256 answer, , uint256 updatedAt,) = feed.latestRoundData();
        require(block.timestamp - updatedAt <= MAX_FEED_AGE, "SpendTrackerV1: stale oracle");
        require(answer > 0, "SpendTrackerV1: bad oracle price");
        uint8 dec = feed.decimals();
        uint256 price18 = uint256(answer) * (10 ** (18 - dec));
        return (amount * price18) / 1e18;
    }

    function setPriceFeed(address token, address feed, uint256 anchorPrice)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _priceFeeds[token]   = feed;
        _anchorPrices[token] = anchorPrice;
    }

    function getPriceFeed(address token) external view returns (address) {
        return _priceFeeds[token];
    }

    function setTwapFallback(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        twapFallbackEnabled = enabled;
    }

    // ── Pause ─────────────────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IBouclier.sol";

/// @dev Minimal Chainlink AggregatorV3 interface — avoids importing the full package
interface IAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (
            uint80  roundId,
            int256  answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80  answeredInRound
        );
}

/// @title  SpendTracker
/// @notice Tracks rolling 24-hour USD spend per agent using a ring buffer.
///         Uses Chainlink price feeds to convert token amounts to USD.
///
///         Design decisions:
///         - Sliding window (not fixed reset) to prevent cap-doubling attack
///         - Ring buffer with MAX_ENTRIES=1000: O(1) write, O(n≤1000) read
///         - Only PermissionVault (VAULT_ROLE) can call `recordSpend`
contract SpendTracker is ISpendTracker, AccessControl, Pausable {
    // ── Roles ─────────────────────────────────────────────────────
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE"); // PermissionVault only

    // ── Ring buffer ───────────────────────────────────────────────
    uint256 public constant MAX_ENTRIES = 1000;

    struct SpendEntry {
        uint48  timestamp;
        uint208 usdAmount18; // 18-decimal USD (up to ~4e17 ≈ ~$400T — safe)
    }

    mapping(bytes32 agentId => SpendEntry[MAX_ENTRIES]) private _ring;
    mapping(bytes32 agentId => uint256)                 private _head;  // next write position

    // ── Chainlink price feeds ──────────────────────────────────────
    // token address → Chainlink feed address
    mapping(address => address) private _priceFeeds;

    // token address → anchor price in 18 decimals (for circuit breaker)
    mapping(address => uint256) private _anchorPrices;

    // Max age of a Chainlink answer before we consider it stale
    uint256 public constant MAX_FEED_AGE = 3600; // 1 hour

    // Circuit breaker threshold — revert if price deviates > 5% from anchor
    uint256 public constant DEVIATION_BPS = 500; // 5%

    // ── Constructor ───────────────────────────────────────────────
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_ROLE, admin); // PermissionVault will be granted this role post-deploy
    }

    // ── Feed management ───────────────────────────────────────────

    /// @notice Register a Chainlink price feed for a token. Admin only.
    ///         Sets the initial anchor price for the circuit breaker.
    function setPriceFeed(address token, address feed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _priceFeeds[token] = feed;
        // Set initial anchor price from the feed for circuit breaker
        if (feed != address(0)) {
            IAggregatorV3 f = IAggregatorV3(feed);
            // slither-disable-next-line unused-return
            (, int256 answer,,,) = f.latestRoundData();
            if (answer > 0) {
                uint8 feedDecimals = f.decimals();
                _anchorPrices[token] = uint256(answer) * (10 ** (18 - feedDecimals));
            }
        }
    }

    function getPriceFeed(address token) external view returns (address) {
        return _priceFeeds[token];
    }

    /// @notice Refresh the anchor price for a token. Call after legitimate price moves.
    function refreshAnchorPrice(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address feedAddr = _priceFeeds[token];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,feedAddr)}
        require(feedAddr != address(0), "SpendTracker: no price feed for token");
        IAggregatorV3 feed = IAggregatorV3(feedAddr);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010002,0)}
        // slither-disable-next-line unused-return
        (, int256 answer,,,) = feed.latestRoundData();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010003,0)}
        require(answer > 0, "SpendTracker: negative or zero oracle price");
        uint8 feedDecimals = feed.decimals();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,feedDecimals)}
        _anchorPrices[token] = uint256(answer) * (10 ** (18 - feedDecimals));
    }

    /// @notice Get the current anchor price for a token (18 decimals).
    function getAnchorPrice(address token) external view returns (uint256) {
        return _anchorPrices[token];
    }

    // ── Spend recording ───────────────────────────────────────────

    /// @notice Record a spend event. Only callable by PermissionVault (VAULT_ROLE).
    function recordSpend(
        bytes32 agentId,
        uint256 usdAmount18,
        uint48  timestamp
    ) external onlyRole(VAULT_ROLE) whenNotPaused {
        uint256 pos = _head[agentId] % MAX_ENTRIES;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,pos)}
        require(usdAmount18 <= type(uint208).max, "SpendTracker: amount overflow");
        _ring[agentId][pos] = SpendEntry({
            timestamp:  timestamp,
            // forge-lint: disable-next-line(unsafe-typecast) -- bounds checked above
            usdAmount18: uint208(usdAmount18)
        });
        _head[agentId]++;

        uint256 rolling = _getRollingSpend(agentId, 86400);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,rolling)}
        emit SpendRecorded(agentId, usdAmount18, rolling);
    }

    // ── Spend queries ─────────────────────────────────────────────

    /// @notice Check if a proposed spend would remain within the cap.
    ///         Returns false if (rolling + proposed) > cap.
    function checkSpendCap(
        bytes32 agentId,
        uint256 proposedUSD,
        uint256 capUSD
    ) external view returns (bool withinCap) {
        if (capUSD == 0) return true; // 0 = no cap
        uint256 rolling = _getRollingSpend(agentId, 86400);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,rolling)}
        return rolling + proposedUSD <= capUSD;
    }

    /// @notice Sum all spend records within windowSeconds of the current time.
    function getRollingSpend(bytes32 agentId, uint256 windowSeconds) external view returns (uint256) {
        return _getRollingSpend(agentId, windowSeconds);
    }

    function _getRollingSpend(bytes32 agentId, uint256 windowSeconds) internal view returns (uint256 total) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023c0000, 1037618709052) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023c0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023c0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023c6001, windowSeconds) }
        uint256 cutoff = block.timestamp - windowSeconds;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,cutoff)}
        uint256 count  = _head[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000009,count)}
        uint256 entries = count < MAX_ENTRIES ? count : MAX_ENTRIES;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000a,entries)}

        for (uint256 i; i < entries; ++i) {
            SpendEntry storage entry = _ring[agentId][i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010013,0)}
            if (entry.timestamp > cutoff) {
                total += entry.usdAmount18;
            }
        }
    }

    // ── USD valuation via Chainlink ───────────────────────────────

    /// @notice Convert a token amount to USD (18 decimals).
    ///         Reverts if: feed not registered, stale price, or negative price.
    function getUSDValue(
        address token,
        uint256 amount
    ) external view returns (uint256 usdValue18) {
        return _getUSDValue(token, amount);
    }

    function _getUSDValue(address token, uint256 amount) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023d0000, 1037618709053) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023d0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023d6001, amount) }
        address feedAddr = _priceFeeds[token];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000b,feedAddr)}
        require(feedAddr != address(0), "SpendTracker: no price feed for token");

        IAggregatorV3 feed = IAggregatorV3(feedAddr);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000c,0)}
        // slither-disable-next-line unused-return
        (
            /* roundId */,
            int256 answer,
            /* startedAt */,
            uint256 updatedAt,
            /* answeredInRound */
        ) = feed.latestRoundData();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000d,0)}

        require(answer > 0, "SpendTracker: negative or zero oracle price");
        require(
            block.timestamp - updatedAt <= MAX_FEED_AGE,
            "SpendTracker: stale oracle price"
        );

        uint8 feedDecimals   = feed.decimals();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000e,feedDecimals)}        // Chainlink uses 8 decimals
        uint8 tokenDecimals  = _tokenDecimals(token);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000f,tokenDecimals)}  // USDC=6, ETH=18, WBTC=8

        // Normalise to 18 decimals:
        // price18 = answer * 10^(18 - feedDecimals)
        // usd18   = amount * price18 / 10^tokenDecimals
        // answer > 0 already verified above; safe to cast
        uint256 price18 = uint256(answer) * (10 ** (18 - feedDecimals));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000010,price18)}

        // Circuit breaker: revert if price deviates > DEVIATION_BPS from anchor
        uint256 anchor = _anchorPrices[token];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,anchor)}
        if (anchor != 0) {
            uint256 diff = price18 > anchor ? price18 - anchor : anchor - price18;
            require(
                diff * 10000 <= anchor * DEVIATION_BPS,
                "SpendTracker: oracle price deviation exceeds threshold"
            );
        }

        uint256 usd18   = (amount * price18) / (10 ** tokenDecimals);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,usd18)}
        return usd18;
    }

    /// @dev Returns known token decimals. Unknown tokens default to 18.
    function _tokenDecimals(address token) internal pure returns (uint8) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023e0000, 1037618709054) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff023e6000, token) }
        // USDC on Base mainnet and Sepolia
        if (token == 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) return 6;  // Base mainnet
        if (token == 0x036CbD53842c5426634e7929541eC2318f3dCF7e) return 6;  // Base Sepolia
        // WBTC (8 decimals everywhere)
        if (token == 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c) return 8;  // Base
        return 18; // Default (ETH, WETH, most ERC-20s)
    }

    // ── Emergency pause ───────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}

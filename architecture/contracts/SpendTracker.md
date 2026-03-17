# SpendTracker.sol — Contract Architecture

> **Contract:** `SpendTracker.sol`  
> **Layer:** Enforcement Layer  
> **Dependencies:** Chainlink Price Feed Oracle  
> **Used by:** `PermissionVault.sol`

---

## Purpose

`SpendTracker` tracks the cumulative USD spending of each agent using a **sliding window algorithm**. It prevents agents from exceeding their allocated spend caps, with separate limits at the per-transaction and per-rolling-window level.

This contract is called on every validated transaction by `PermissionVault` — it is a hot-path contract and must be gas-efficient.

---

## Why Sliding Window (Not Fixed Daily Reset)

A fixed daily reset (midnight UTC) creates a predictable gaming opportunity:

```
Example — Fixed Reset Attack:
  Agent has $500/day cap
  23:58 UTC: Agent spends $499 → total = $499 (under cap ✓)
  00:02 UTC: Cap resets → Agent spends $499 again → total = $499 (under cap ✓)
  Net: $998 spent in 4 minutes, double the intended limit
```

A sliding window prevents this:

```
Example — Sliding Window (correct):
  Agent has $500/24h cap
  23:58 UTC: Agent spends $499 → rolling 24h total = $499 ✓
  00:02 UTC: Agent tries $200 → rolling 24h total would be $699 → BLOCKED ✗
  (The 23:58 spend is still within the 24h lookback window)
```

---

## Full Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISpendTracker {

    // ─────────────────────────────────────────────────────────────────
    // STRUCTS
    // ─────────────────────────────────────────────────────────────────

    struct SpendEntry {
        uint256 amountUSD;   // Amount in USD (18 decimals = 1e18 per $1)
        uint48  timestamp;   // When this spend occurred (block.timestamp)
    }

    struct SpendSummary {
        uint256 rollingTotal;    // Total in the current 24h rolling window
        uint256 lastTxAmount;    // Amount of the most recent transaction
        uint48  lastTxAt;        // Timestamp of the most recent transaction
        uint256 txCount24h;      // Number of transactions in rolling 24h window
    }

    // ─────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────

    event SpendRecorded(
        bytes32 indexed agentId,
        uint256 amountUSD,
        uint256 rollingTotal,
        uint48  timestamp
    );

    event SpendCapViolationAttempt(
        bytes32 indexed agentId,
        uint256 attemptedUSD,
        uint256 currentRollingTotal,
        uint256 dailyCap,
        uint48  timestamp
    );

    event OraclePriceUsed(
        address indexed tokenAddress,
        uint256 priceUSD,
        uint80  roundId,
        uint48  timestamp
    );

    // ─────────────────────────────────────────────────────────────────
    // WRITE FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Records a spend event for an agent
     * @dev ONLY callable by PermissionVault (access-controlled)
     *      Called AFTER all validation checks pass in validateUserOp
     *      Appends to the agent's spend history ring buffer
     * @param agentId    The agent that spent
     * @param amountUSD  USD value spent (18 decimals)
     * @param timestamp  block.timestamp at the time of the action
     */
    function recordSpend(
        bytes32 agentId,
        uint256 amountUSD,
        uint48  timestamp
    ) external;

    // ─────────────────────────────────────────────────────────────────
    // READ FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Checks if a proposed spend is within the agent's cap
     * @dev READ-ONLY — does NOT record. Called by PermissionVault before recording.
     * @param agentId      The agent attempting to spend
     * @param proposedUSD  The USD value of the proposed transaction
     * @param dailyCapUSD  The agent's configured daily cap (passed in from scope)
     * @return allowed     True if (rollingTotal + proposedUSD) <= dailyCapUSD
     */
    function checkSpendCap(
        bytes32 agentId,
        uint256 proposedUSD,
        uint256 dailyCapUSD
    ) external view returns (bool allowed);

    /**
     * @notice Gets the rolling spend total for an agent over a custom window
     * @param agentId           The agent to query
     * @param windowSeconds     Size of the rolling window (e.g. 86400 = 24h)
     * @return totalUSD         Total USD spent within the window
     */
    function getRollingSpend(
        bytes32 agentId,
        uint32  windowSeconds
    ) external view returns (uint256 totalUSD);

    /**
     * @notice Full spend summary for dashboard/compliance display
     * @param agentId   The agent to query
     * @return summary  SpendSummary struct
     */
    function getSpendSummary(bytes32 agentId) external view returns (SpendSummary memory summary);

    /**
     * @notice Gets raw spend entries for an agent in a time range
     * @dev Used by compliance export, not the execution path
     * @param agentId    The agent
     * @param fromTime   Start of range (unix timestamp)
     * @param toTime     End of range (unix timestamp), 0 = now
     * @return entries   Array of SpendEntry structs
     */
    function getSpendHistory(
        bytes32 agentId,
        uint48  fromTime,
        uint48  toTime
    ) external view returns (SpendEntry[] memory entries);

    // ─────────────────────────────────────────────────────────────────
    // ORACLE FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Gets current USD price of a token via Chainlink
     * @dev Returns 18-decimal USD price. Reverts if feed is stale (> 1 hour old)
     * @param tokenAddress  ERC-20 token contract address
     * @return priceUSD     Current price in USD (18 decimals)
     */
    function getTokenPriceUSD(address tokenAddress) external view returns (uint256 priceUSD);

    /**
     * @notice Calculates USD value of a given token amount
     * @param tokenAddress  ERC-20 token
     * @param amount        Token amount (in token's native decimals)
     * @return valueUSD     Value in USD (18 decimals)
     */
    function calculateUSDValue(
        address tokenAddress,
        uint256 amount
    ) external view returns (uint256 valueUSD);
}
```

---

## Sliding Window Algorithm

The sliding window is implemented as a **ring buffer** of spend entries per agent. On every `checkSpendCap` or `getRollingSpend` call, expired entries (older than 24h) are skipped.

```solidity
// Pseudocode for sliding window calculation

function getRollingSpend(bytes32 agentId, uint32 windowSeconds) internal view returns (uint256) {
    SpendEntry[] storage entries = _spendHistory[agentId];
    uint256 cutoff = block.timestamp - windowSeconds;
    uint256 total = 0;
    
    // Iterate from most recent, stop when entry is older than window
    // Ring buffer: start from _cursor[agentId], wrap around
    for (uint256 i = entries.length; i > 0; i--) {
        SpendEntry storage entry = entries[i - 1];
        if (entry.timestamp < cutoff) break;  // Entries are in chronological order
        total += entry.amountUSD;
    }
    
    return total;
}
```

**Ring buffer implementation (gas-efficient):**

```solidity
// Max entries per agent = 1000 (covers high-frequency trading agents)
// When full, oldest entries are overwritten (cursor wraps around)
uint256 constant MAX_ENTRIES = 1000;

mapping(bytes32 => SpendEntry[MAX_ENTRIES]) private _spendRingBuffer;
mapping(bytes32 => uint256) private _cursor;  // Points to next write position

// On recordSpend:
function recordSpend(bytes32 agentId, uint256 amountUSD, uint48 timestamp) external {
    uint256 cursor = _cursor[agentId];
    _spendRingBuffer[agentId][cursor] = SpendEntry(amountUSD, timestamp);
    _cursor[agentId] = (cursor + 1) % MAX_ENTRIES;
}
```

**Why a ring buffer?**
- Fixed memory per agent (no unbounded storage growth)
- O(1) writes
- O(n) reads where n ≤ MAX_ENTRIES = 1000 (bounded and predictable gas)

---

## Chainlink Oracle Integration

### Price Feed Addresses (Base Sepolia)

```solidity
// Chainlink price feeds — Base Sepolia testnet
address constant ETH_USD_FEED    = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
address constant USDC_USD_FEED   = 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165;
address constant WBTC_USD_FEED   = 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298;

// Chainlink price feeds — Base mainnet
address constant ETH_USD_FEED_MAINNET  = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
address constant USDC_USD_FEED_MAINNET = 0x7e860098F58bBFC8648a4311b374B1D669a2bc9;
address constant WBTC_USD_FEED_MAINNET = 0xCCADC697c55bbB68dc5bCdf8d3CBe83CdD4E071E;
```

### Price Validation Logic

```solidity
function _getValidatedPrice(address feed) internal view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);
    (
        uint80 roundId,
        int256 price,
        ,
        uint256 updatedAt,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    // Staleness check: reject if data is older than 1 hour
    require(updatedAt > block.timestamp - 3600, "SpendTracker: stale oracle");
    
    // Answer validity: reject negative/zero prices
    require(price > 0, "SpendTracker: invalid oracle price");
    
    // Round completeness check
    require(answeredInRound >= roundId, "SpendTracker: incomplete oracle round");
    
    // Convert to 18 decimals (Chainlink feeds are 8 decimals)
    return uint256(price) * 1e10;
}
```

### Multi-Oracle Validation (for high-value transactions)

For transactions > $10,000 USD equivalent, use a second oracle source as a sanity check:

```solidity
// If Chainlink price deviates > 5% from a secondary source (e.g. TWAP from Uniswap v3),
// reject the transaction — potential oracle manipulation
function _validatePriceDeviation(
    uint256 chainlinkPriceUSD,
    uint256 twapPriceUSD
) internal pure returns (bool) {
    uint256 deviation = chainlinkPriceUSD > twapPriceUSD
        ? ((chainlinkPriceUSD - twapPriceUSD) * 1e18) / twapPriceUSD
        : ((twapPriceUSD - chainlinkPriceUSD) * 1e18) / twapPriceUSD;
    
    return deviation <= 5e16; // 5% in 18-decimal fixed point
}
```

---

## Storage Layout

```solidity
// SpendTracker.sol storage

// Agent spend ring buffer (fixed-size, bounded gas)
mapping(bytes32 => SpendEntry[1000]) private _spendRingBuffer;
mapping(bytes32 => uint256) private _cursor;      // Current write position

// Chainlink feed registry (token → AggregatorV3Interface address)
mapping(address => address) private _priceFeeds;

// Access control
address private _permissionVault;  // Only this address can call recordSpend()
```

---

## Access Control

```
recordSpend()           → PermissionVault only (set at deployment)
checkSpendCap()         → Anyone (public read — used by SDK pre-flight)
getRollingSpend()       → Anyone (public read)
getSpendHistory()       → Anyone (public read)
getSpendSummary()       → Anyone (public read)
getTokenPriceUSD()      → Anyone (public read)
calculateUSDValue()     → Anyone (public read)
setPriceFeed()          → Contract admin only (add new token oracles)
setPermissionVault()    → Contract admin only (set at deployment, one-time)
```

---

## Security Considerations

| Risk | Description | Mitigation |
|---|---|---|
| Oracle price manipulation | Attacker manipulates Chainlink feed to inflate token price, allowing larger real spend | Stale check + multi-oracle validation + deviation circuit breaker |
| Integer overflow in spend calc | Large token amounts could overflow uint256 before USD conversion | SafeMath patterns + explicit overflow checks at uint128 boundaries |
| Ring buffer cursor corruption | Malicious input causes cursor to point to wrong slot | Cursor is `% MAX_ENTRIES` — always bounded |
| Block timestamp manipulation | Miner has ~15s variance in timestamp | 5-minute granularity window (15s variance is negligible vs 5 min) |
| recordSpend called by non-vault | External caller injects fake spend records | `onlyPermissionVault` modifier — revert if msg.sender != _permissionVault |
| Missing price feed | Token has no registered Chainlink feed | `require(_priceFeeds[token] != address(0), "no oracle")` — reject unknown tokens |

---

## Test Cases Required

```
✓ recordSpend — only PermissionVault can call (access control)
✓ recordSpend — SpendRecorded event emitted with correct args
✓ recordSpend — getRollingSpend reflects new entry immediately
✓ checkSpendCap — returns true when proposed + rolling < cap
✓ checkSpendCap — returns false when proposed + rolling > cap
✓ checkSpendCap — returns false when proposed + rolling == cap exactly (edge case: at cap = allowed)
✓ getRollingSpend — entries older than windowSeconds are excluded
✓ getRollingSpend — entries exactly at windowSeconds boundary (inclusive)
✓ getRollingSpend — returns 0 for agent with no history
✓ Ring buffer — wraps correctly at MAX_ENTRIES
✓ Ring buffer — after wrap, old entries correctly excluded from window
✓ Oracle — reverts if feed is stale (updatedAt > 1 hour ago)
✓ Oracle — reverts if price is negative or zero
✓ calculateUSDValue — correct for ETH (18 decimals)
✓ calculateUSDValue — correct for USDC (6 decimals)
✓ calculateUSDValue — correct for WBTC (8 decimals)
✗ FUZZ: (rollingSpend + proposedSpend) NEVER exceeds cap if checkSpendCap() returns true
✗ FUZZ: random spend sequences — rolling window always reflects only last 24h worth of entries
✗ INVARIANT: getRollingSpend(agentId, 86400) after N recordSpend calls = sum of last 24h entries only
```

---

## Gas Estimates

| Function | Estimated Gas |
|---|---|
| `recordSpend()` | ~25,000 (1 array write + 1 cursor increment + event) |
| `checkSpendCap()` | ~15,000 (up to 1000 ring buffer reads in worst case — but only reads within window) |
| `getTokenPriceUSD()` | ~8,000 (Chainlink external call) |
| `calculateUSDValue()` | ~12,000 (Chainlink + math) |

The `checkSpendCap()` read cost improves in practice: most agents have < 50 transactions in a 24h window, so the loop terminates early.

---

*Last Updated: March 2026*

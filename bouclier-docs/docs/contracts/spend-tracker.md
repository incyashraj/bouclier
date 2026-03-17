---
sidebar_position: 4
---

# SpendTracker

`SpendTracker.sol` tracks USD-denominated spending per agent using a sliding-window ring buffer and Chainlink price feeds.

**Address (Base Sepolia):** `0x930Eb18B9962c30b388f900ba9AE62386191cD48`

---

## Design

- **Ring buffer** — `MAX_ENTRIES = 1000` entries per agent, circular overwrite
- **Chainlink oracle** — converts token amounts to USD at call time
- **Stale price protection** — reverts if oracle data is older than 1 hour
- **Only PermissionVault** can call `recordSpend` — enforced on-chain

## Write Functions

### `recordSpend`

```solidity
function recordSpend(
    bytes32 agentId,
    uint256 usdAmount,
    uint256 timestamp
) external
```

Records a spend entry. **Only callable by `PermissionVault`.**

## Read Functions

### `checkSpendCap`

```solidity
function checkSpendCap(
    bytes32 agentId,
    uint256 proposedUSD,
    uint256 capUSD
) external view returns (bool withinCap)
```

Returns `true` if `getRollingSpend(agentId, 86400) + proposedUSD ≤ capUSD`.

### `getRollingSpend`

```solidity
function getRollingSpend(
    bytes32 agentId,
    uint256 windowSeconds
) external view returns (uint256 totalUSD)
```

Iterates the ring buffer and sums all entries within `windowSeconds` of `block.timestamp`.

### `getUSDValue`

```solidity
function getUSDValue(
    address tokenAddress,
    uint256 amount
) external view returns (uint256 usdValue18)
```

Converts a token amount to USD with 18 decimal precision using the configured Chainlink feed.

## Supported Oracles (Base Mainnet)

| Token | Feed Address |
|---|---|
| ETH | `0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70` |
| USDC | `0x7e860098F58bBFC8648a4311b374B1D669a2bc9` |
| WBTC | `0xCCADC697c55bbB68dc5bCdf8d3CBe83CdD4E071E` |

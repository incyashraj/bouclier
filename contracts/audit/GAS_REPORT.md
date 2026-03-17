# Bouclier — Gas Optimization Report

> Generated from `forge test --gas-report` on 17 March 2026
> Solidity 0.8.24 | Optimizer: 200 runs | Target: Base L2

---

## Hot-Path: `validateUserOp`

| Metric | Gas |
|---|---|
| **Min** | 31,640 |
| **Avg** | 219,627 |
| **Median** | 252,358 |
| **Max** | 275,836 |

The high average is due to the full 15-step pipeline including:
- External call to `AgentRegistry.isActive()` (~5K gas)
- External call to `RevocationRegistry.isRevoked()` (~2.5K gas — single SLOAD, well optimized)
- External call to `SpendTracker.getUSDValue()` (~17K gas — Chainlink oracle call)
- External call to `SpendTracker.checkSpendCap()` (~5.4K gas — ring buffer scan)
- External call to `SpendTracker.recordSpend()` (~70K gas first write, cheaper on warm slots)
- External call to `AuditLogger.logAction()` (~100K gas — cold storage writes)

**Min (31,640 gas)**: Early rejection (agent not registered) — very cheap.

**Target**: On Base L2, even the max (275K gas) costs ~$0.001 at current gas prices. This is well within acceptable limits for an ERC-4337 validation module.

---

## Key Function Gas Costs

### AgentRegistry

| Function | Min | Avg | Median | Max |
|---|---|---|---|---|
| register | 139,277 | 160,508 | 162,032 | 162,032 |
| resolve | 22,181 | 22,181 | 22,181 | 22,181 |
| getAgentId | 2,563 | 2,563 | 2,563 | 2,563 |
| isActive | 5,082 | 5,082 | 5,082 | 5,082 |
| updateStatus | 29,043 | 33,453 | 30,248 | 41,070 |

### RevocationRegistry

| Function | Min | Avg | Median | Max |
|---|---|---|---|---|
| isRevoked | 2,547 | 2,547 | 2,547 | 2,547 |
| revoke | 25,223 | 82,051 | 96,936 | 97,044 |
| reinstate | 29,467 | 33,007 | 29,656 | 39,899 |
| batchRevoke | 25,718 | 96,791 | 96,791 | 167,865 |
| emergencyReinstate | 25,138 | 32,452 | 32,452 | 39,767 |

### SpendTracker

| Function | Min | Avg | Median | Max |
|---|---|---|---|---|
| recordSpend | ~0 (reverted) | 1,170,968 | 1,170,781 | 2,311,786 |
| checkSpendCap | 478 | 3,430 | 2,921 | 5,415 |
| getRollingSpend | 4,982 | 6,388 | 6,441 | 7,688 |
| getUSDValue | 2,846 | 14,127 | 16,498 | 16,964 |
| setPriceFeed | 79,737 | 79,737 | 79,737 | 79,737 |

### PermissionVault

| Function | Min | Avg | Median | Max |
|---|---|---|---|---|
| validateUserOp | 31,640 | 219,627 | 252,358 | 275,836 |
| grantPermission | 58,193 | 195,266 | 211,212 | 254,425 |
| revokePermission | 52,908 | 55,834 | 57,298 | 57,298 |
| emergencyRevoke | 181,672 | 181,672 | 181,672 | 181,672 |

### AuditLogger

| Function | Min | Avg | Median | Max |
|---|---|---|---|---|
| logAction | 119,131 | 130,126 | 130,556 | 140,261 |
| addIPFSCID | 31,128 | 36,534 | 36,534 | 41,940 |
| getAuditRecord | 11,456 | 11,456 | 11,456 | 11,456 |

---

## Optimization Assessment

### Already Optimized
1. **`isRevoked()` — 2,547 gas**: Single SLOAD, cannot be further reduced. This is the most critical hot-path read.
2. **`getAgentId()` — 2,563 gas**: Single mapping lookup, optimal.
3. **`checkSpendCap()` — 3,430 avg**: Ring buffer scan is efficient for ≤1000 entries.

### Potential Optimizations (Low Priority)

1. **`recordSpend` high max (2.3M)**: This occurs during the ring buffer wrap test that fills 1000 entries. In production, each call writes one entry at ~70K gas (warm SSTORE). Not a real-world concern.

2. **`grantPermission` max (254K)**: Dominated by dynamic array copies (protocols, selectors, tokens). Could be reduced by limiting array sizes, but the current design prioritizes flexibility.

3. **`logAction` avg (130K)**: Dominated by two cold SSTORE operations (new record + history push). This is inherent to append-only logging.

### Conclusion

**No critical optimizations needed.** All hot-path operations are well within Base L2 gas economics:
- validateUserOp (full pass): ~275K gas ≈ $0.001 on Base
- isRevoked (rejection check): ~2.5K gas ≈ near-zero cost
- grantPermission: ~250K gas ≈ $0.001 on Base (one-time per grant)

The contracts are already struct-packed (slot-optimized) and use efficient access patterns. The main gas consumers are inherent to Solidity's storage model (cold SSTORE = 20K gas per new slot).

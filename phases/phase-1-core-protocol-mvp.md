# Phase 1: Core Protocol MVP

> **Weeks 4–10 · Goal:** All 5 smart contracts deployed to Base Sepolia, TypeScript SDK v0.1 published, basic Next.js dashboard running, full end-to-end Uniswap v3 fork integration test passing.
>
> **Success Criterion:** A developer can call `wrapAgent(claude)`, issue a signed `UserOp` calling `swap()` on Uniswap, and the PermissionVault correctly validates, records spend, and logs the action — all verified by a passing integration test.

---

## Progress Tracker

| Milestone | Status | Completed |
|---|---|---|
| RevocationRegistry deployed | 🟢 Deployed | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` |
| AgentRegistry deployed | 🟢 Deployed | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` |
| SpendTracker deployed | 🟢 Deployed | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` |
| AuditLogger deployed | 🟢 Deployed | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` |
| PermissionVault deployed | 🟢 Deployed | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` |
| TypeScript SDK v0.1 published | � Published | `@bouclier/sdk@0.1.0` on npm (Session 7) |
| Python SDK v0.1.0 | 🟢 Published | `bouclier-sdk@0.1.0` on PyPI (Session 8) |
| Basic dashboard live | 🟢 Deployed | Vercel: dashboard-o08okyf0p-incyashrajs-projects.vercel.app |
| The Graph subgraph built | 🟢 Deployed | The Graph Studio: bouclier-base-sepolia/v0.0.1 |
| E2E integration test passing | 🟢 Passing | 7/7 fork tests pass against live Base Sepolia |

### Phase 1 Pre-work (Done in Phase 0)

> These items were completed ahead of schedule during Phase 0 Sessions 2–3:

| Deliverable | Status |
|---|---|
| All 5 contracts written + 76/76 unit tests passing | ✅ |
| Deploy script `contracts/script/Deploy.s.sol` | ✅ |
| TypeScript SDK `@bouclier/sdk` v0.1.0 (`tsc --noEmit` clean) | ✅ |
| Fork integration test file (4 scenarios) | ✅ |
| CI pipeline (forge + Slither + fmt) | ✅ |

---

## Contract Implementation Order

> Implement in this exact order. Each contract depends on the previous one being stable.

```
1. RevocationRegistry  ← No dependencies. Simplest contract. Build confidence.
2. AgentRegistry       ← Depends on knowing RevocationRegistry address
3. SpendTracker        ← Depends on PermissionVault address (caller check)
4. AuditLogger         ← Depends on PermissionVault address (caller check)
5. PermissionVault     ← Orchestrates all others. Most complex. Last.
```

---

## Week 4: RevocationRegistry

**Spec:** [architecture/contracts/RevocationRegistry.md](../architecture/contracts/RevocationRegistry.md)

### Implementation Checklist

```bash
# Create file
touch contracts/src/RevocationRegistry.sol
touch contracts/test/unit/RevocationRegistry.t.sol
```

- [ ] Storage layout: `mapping(bytes32 => RevocationRecord)`, no other state
- [ ] `revoke(agentId, reason, notes)` — sets `revokedAt`, emits `AgentRevoked`
- [ ] `batchRevoke(agentIds[], reason, notes)` — loops over `revoke()`
- [ ] `reinstate(agentId, notes)` — enforces 24h timelock, emits `AgentReinstated`
- [ ] `isRevoked(agentId) external view returns (bool)` — reads single SLOAD (gas critical: ≤ 2,200 gas)
- [ ] `getRevocationRecord(agentId)` — returns `RevocationRecord` struct
- [ ] Access control: `revoke` → REVOKER_ROLE or owner; `batchRevoke` → GUARDIAN_ROLE only
- [ ] Implement `AccessControl` from OpenZeppelin
- [ ] `GUARDIAN_ROLE` can bypass 24h reinstatement timelock (emergency flag)

### Unit Tests

```bash
forge test --match-contract "RevocationRegistryTest" -vvv
```

All 14 test cases from [testing-strategy.md](../testing/testing-strategy.md#revocationregistry-unit-tests) must pass.

### Gas Target

```bash
forge test --match-contract "RevocationRegistryTest" --gas-report
# isRevoked() must be ≤ 2,200 gas
# revoke()    must be ≤ 50,000 gas
```

---

## Week 5: AgentRegistry + SpendTracker

### AgentRegistry

**Spec:** [architecture/contracts/AgentRegistry.md](../architecture/contracts/AgentRegistry.md)

- [ ] `AgentRecord` struct — pack into 3 storage slots (validate with `forge inspect`)
- [ ] `register(agentWallet, model, parentAgentId, metadataCID)` — derives `agentId`, generates DID
- [ ] `agentId = keccak256(abi.encode(owner, agentWallet, nonce))` — exactly this derivation
- [ ] DID format: `did:ethr:base:0x{agentAddress}` (lowercase hex, no checksum in DID)
- [ ] `resolve(agentId)` → `AgentRecord`
- [ ] `getAgentId(agentAddress)` → reverse lookup
- [ ] `getAgentsByOwner(owner)` → `bytes32[]`
- [ ] `isActive(agentId)` → `bool`
- [ ] `setPermissionVault(agentId, vault)` — only owner
- [ ] `updateStatus(agentId, newStatus)` — only owner
- [ ] `totalAgents()` counter

```bash
forge test --match-contract "AgentRegistryTest" -vvv
# All tests from architecture spec must pass
```

### SpendTracker

**Spec:** [architecture/contracts/SpendTracker.md](../architecture/contracts/SpendTracker.md)

- [ ] Ring buffer: `mapping(bytes32 => SpendEntry[MAX_ENTRIES])` + head pointer
- [ ] `MAX_ENTRIES = 1000` (constant)
- [ ] `recordSpend(agentId, usdAmount18, timestamp)` — only callable by PermissionVault
- [ ] `checkSpendCap(agentId, proposedUSD, cap)` — sliding window lookup
- [ ] `getRollingSpend(agentId, windowSeconds)` — iterates ring buffer
- [ ] Chainlink integration: `getUSDValue(tokenAddress, amount)` using `AggregatorV3Interface`
- [ ] Stale oracle protection: revert if `updatedAt < block.timestamp - 3600`
- [ ] Negative price protection: revert if `answer <= 0`
- [ ] Supported tokens + oracle addresses (from architecture spec):

```solidity
// Base mainnet
// ETH/USD:  0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70
// USDC/USD: 0x7e860098F58bBFC8648a4311b374B1D669a2bc9
// WBTC/USD: 0xCCADC697c55bbB68dc5bCdf8d3CBe83CdD4E071E
```

```bash
forge test --match-contract "SpendTrackerTest" -vvv
```

---

## Week 6: AuditLogger

**Spec:** [architecture/contracts/AuditLogger.md](../architecture/contracts/AuditLogger.md)

- [ ] `AuditRecord` struct
- [ ] `logAction(agentId, actionHash, target, selector, tokenAddress, usdAmount)` — phase 1 (no IPFS yet)
- [ ] Returns `eventId = keccak256(abi.encode(agentId, actionHash, block.number, logIndex))`
- [ ] Append-only: records are NEVER modified after creation (verify with invariant test)
- [ ] `addIPFSCID(eventId, cid)` — phase 2, adds IPFS CID to existing record (only callable by backend)
- [ ] `getAuditRecord(eventId)` → `AuditRecord`
- [ ] `getAgentHistory(agentId, offset, limit)` → paginated `eventId[]`
- [ ] `getTotalEvents(agentId)` → `uint256`
- [ ] Access control: `logAction` → only PermissionVault; `addIPFSCID` → IPFS_ROLE

**Invariant test — critical:**
```solidity
// INVARIANT: audit records are never modified after creation
function invariant_auditRecordsImmutable() public view {
    // For all known eventIds, the stored record equals the initially created record
    ...
}
```

```bash
forge test --match-contract "AuditLoggerTest" -vvv
```

---

## Week 7–8: PermissionVault (Core)

**Spec:** [architecture/contracts/PermissionVault.md](../architecture/contracts/PermissionVault.md)

This is the most critical contract. Build it in two sub-phases:

### Sub-phase A (Week 7): Storage + Scope Management

- [ ] `PermissionScope` struct (full, as in spec)
- [ ] `mapping(bytes32 agentId => PermissionScope)` — one active scope per agent
- [ ] `grantPermission(agentId, scope, ownerSignature)` — validates EIP-712 signature, stores scope
- [ ] `getActiveScope(agentId)` → `PermissionScope`
- [ ] `revokePermission(agentId)` — sets `scope.revoked = true`
- [ ] `emergencyRevoke(agentId)` — calls `revokePermission` + calls `revocationRegistry.revoke()`
- [ ] Constructor takes `agentRegistry`, `revocationRegistry`, `spendTracker`, `auditLogger` addresses

### Sub-phase B (Week 8): `validateUserOp` — the hot path

Implement the 15-step validation (from architecture spec) in order:

1. Decode `userOp.callData` to extract `target`, `selector`, `value`, `tokenAddress`, `amount`
2. Resolve `agentId = agentRegistry.getAgentId(userOp.sender)`
3. Check `agentRegistry.isActive(agentId)` — revert if false
4. Check `!revocationRegistry.isRevoked(agentId)` — **return `SIG_VALIDATION_FAILED` if revoked**
5. Load `activeScope = getActiveScope(agentId)`
6. Check `!scope.revoked` — return failed if revoked
7. Check `block.timestamp >= scope.validFrom && block.timestamp <= scope.validUntil`
8. Check protocol allowlist: `target ∈ scope.allowedProtocols || scope.allowAnyProtocol`
9. Check selector allowlist: `selector ∈ scope.allowedSelectors || scope.allowedSelectors.length == 0`
10. Check token allowlist: `tokenAddress ∈ scope.allowedTokens || scope.allowAnyToken`
11. Check time window (if `scope.windowDaysMask != 0`)
12. Compute USD value via `spendTracker.getUSDValue(tokenAddress, amount)`
13. Check per-tx cap: `usdValue <= scope.perTxSpendCapUSD`
14. Check rolling daily cap: `spendTracker.checkSpendCap(agentId, usdValue, scope.dailySpendCapUSD)`
15. **If all pass:** `spendTracker.recordSpend(...)` + `auditLogger.logAction(...)` → **return `SIG_VALIDATION_SUCCESS` (0)**

On any failure between steps 1–14: emit `PermissionViolation` event with appropriate `violationType` string, return `SIG_VALIDATION_FAILED` (1).

```bash
# Unit tests (all cases from testing-strategy.md)
forge test --match-contract "PermissionVaultTest" -vvv

# Gas check
forge test --match-contract "PermissionVaultTest" --gas-report
# validateUserOp must be ≤ 150,000 gas (happy path)
```

---

## Week 9: TypeScript SDK v0.1

**Spec:** [architecture/sdk/typescript-sdk.md](../architecture/sdk/typescript-sdk.md)

```bash
cd packages/sdk
bun init
```

### Scope for v0.1

Implement only these functions (ignore advanced features for now):
- [ ] `registerAgent(config)` → calls `AgentRegistry.register()`
- [ ] `grantPermission(agentId, scope, signature)` → calls `PermissionVault.grantPermission()`
- [ ] `revokeAgent(agentId)` → calls `RevocationRegistry.revoke()`
- [ ] `checkPermission(agentId, action)` → simulates `validateUserOp` off-chain
- [ ] `wrapAgent(agent, shield)` → wraps any async function with pre/post checks
- [ ] `getAuditTrail(agentId, options)` → queries subgraph (or fallback to contract events)

### Publishing

```bash
# Bump version
bun x bump-version patch

# Build
bun run build

# Publish to npm
bun publish --access public

# Package name: @bouclier/sdk
# Required: npm account, 2FA enabled
```

---

## Week 10: Basic Dashboard + E2E Test

### Dashboard (Next.js 15)

```bash
cd dashboard
bunx create-next-app@latest . --typescript --tailwind --app
bun add wagmi viem @rainbow-me/rainbowkit

# Install shadcn/ui
bunx shadcn-ui@latest init
```

**MVP screens (3 pages only):**
1. `/dashboard` — agent list with status badges
2. `/dashboard/[agentId]` — agent detail: active scope, rolling spend, recent audit events
3. `/dashboard/grant` — grant permission form (connects wallet, signs EIP-712 scope)

### E2E Integration Test

Implement the full integration test from [testing-strategy.md](../testing/testing-strategy.md#full-flow-integration-tests):

```bash
forge test --match-contract "BouclierFullFlowTest" --fork-url $BASE_MAINNET_RPC_URL -vvv

# Must see:
# [PASS] test_integration_allowedSwap_passes()
# [PASS] test_integration_dailyCapExceeded_reverts()
# [PASS] test_integration_revokedAgent_allActionsBlocked()
# [PASS] test_integration_revocationAndReinstateFlow()
```

---

## Deployment (End of Week 10)

```bash
# Deploy to Base Sepolia in this order
cd contracts

forge script script/Deploy.s.sol:DeployAll \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Expected output: all 5 contract addresses
# Record them in .env.sepolia
```

**Post-Deploy Verification:**
```bash
# Verify AgentRegistry resolves correctly
cast call $AGENT_REGISTRY_ADDRESS \
  "totalAgents()(uint256)" \
  --rpc-url $BASE_SEPOLIA_RPC_URL
# Expected: 0 (freshly deployed)

# Verify PermissionVault can receive a UserOp (call with a fake op, expect revert with "not registered")
```

---

## Phase 1 Complete When

- [x] `forge test` — all unit tests passing (76/76 across all contracts)
- [x] `forge test --fork-url` — all 7 integration tests passing
- [x] All 5 contracts deployed to Base Sepolia, addresses recorded
- [x] Basescan shows verified source code for all 5 contracts
- [x] `bun test` in `packages/sdk` — all SDK tests passing (13/13)
- [x] Dashboard deployed to Vercel, shows agent list
- [x] `@bouclier/sdk@0.1.0` published to npm

---

*Last Updated: Session 10*  
*Phase Status: 🟢 Complete (100%)*

# Phase 3: Security Audit & Hardening

> **Weeks 17–20 · Goal:** All contracts pass automated security tools with zero critical/high findings; Code4rena community audit complete; Immunefi bug bounty live; Certora formal verification proofs generated; contracts ready for mainnet deployment.
>
> **Success Criterion:** No critical or high severity findings remain open. Medium findings are either fixed or have accepted risk explanations. Formal proofs cover the 3 critical invariants. Immunefi bounty is live.

---

## Progress Tracker

| Milestone | Status | Completed |
|---|---|---|
| Slither — zero high/critical | ✅ Complete | 4 findings fixed, 0 remaining |
| Mythril — zero critical paths | ✅ Complete | 5/5 contracts, 0 real vulns |
| Foundry invariant tests — 128K calls | ✅ Complete | 9/9 properties hold |
| Certora — specs written | ✅ Complete | 3 files, 15+ rules |
| Certora — cloud verification run | ✅ Complete | **19/19 rules verified**: SpendTracker 4/4, RevocationRegistry 6/6, PermissionVault 9/9 |
| Tenderly monitoring — contracts imported | ✅ Complete | 5/5 contracts on Base Sepolia |
| Code4rena audit complete | ⬜ Not Started | — |
| All C4 findings fixed | ⬜ Not Started | — |
| Immunefi bounty live | ⬜ Not Started | — |

---

## Security Tool Checklist

### Tool 1: Slither (Static Analysis)

```bash
# Install
pip install slither-analyzer

# Run on all contracts
cd contracts
slither src/ --config-file slither.config.json

# Run with specific detectors
slither src/ --detect reentrancy-eth,reentrancy-no-eth,reentrancy-events,reentrancy-benign \
             --json output/slither-reentrancy.json

# Generate summary report
slither src/ --print human-summary
```

**`slither.config.json`:**
```json
{
  "detectors_to_exclude": [],
  "exclude_informational": false,
  "exclude_low": false,
  "filter_paths": "lib,test",
  "solc_remaps": ["@openzeppelin=lib/openzeppelin-contracts/contracts"]
}
```

**Triage criteria:**
| Severity | Action |
|---|---|
| Critical | Fix immediately before proceeding |
| High | Fix immediately before proceeding |
| Medium | Fix or document accepted risk with rationale |
| Low | Fix if < 1 hour effort, else document |
| Informational | Review and tag as Acknowledged |

**Specific checks for Bouclier's threat model:**

- [x] `reentrancy-eth` — PermissionVault's `validateUserOp` is not reentrant (Slither + Mythril confirmed)
- [x] `tx-origin` — No `tx.origin` usage anywhere (Slither confirmed)
- [x] `arbitrary-send-eth` — No unprotected ETH sends (`rescueETH` is `onlyOwner`)
- [x] `controlled-delegatecall` — No delegatecall to untrusted addresses (Slither confirmed)
- [x] `unchecked-low-level-call` — All low-level calls check return values (Slither + annotated)
- [x] `suicidal` — No `selfdestruct` (Slither confirmed)
- [x] `uninitialized-local` — All variables initialized (Slither confirmed)
- [x] `integer-overflow` — Solidity 0.8.24 handles this; no unchecked blocks in production code
- [x] `incorrect-equality` — No `== 0` for addresses where `!= address(0)` is intended

### Tool 2: Mythril (Symbolic Execution)

```bash
# Install
pip install mythril

# Full analysis on PermissionVault (most critical)
myth analyze src/PermissionVault.sol --solc-json remappings.json --max-depth 22 --execution-timeout 120

# Analyze all contracts
for contract in AgentRegistry PermissionVault SpendTracker AuditLogger RevocationRegistry; do
    myth analyze src/$contract.sol --solc-json remappings.json \
         --json > output/mythril-$contract.json
done
```

**Priority vulnerability classes to check:**
1. **Integer overflow in SpendTracker** — can `rollingSpend` be wrapped to 0?
2. **Timestamp manipulation in PermissionVault** — can `validUntil` check be bypassed?
3. **Signature replay in PermissionVault** — can the same `grantPermission` signature be used twice?
4. **Access control bypass in RevocationRegistry** — can a non-owner call `reinstate()` before 24h?
5. **Oracle manipulation in SpendTracker** — can a price feed be manipulated to bypass USD caps?

### Tool 3: Echidna (Property-Based Fuzzing)

```bash
# Install
brew install echidna

# Run 10M iterations
echidna test/echidna/PermissionVaultEchidna.sol --config echidna.yaml \
         --contract PermissionVaultEchidna \
         --test-limit 10000000

# Expected: no property violations
# If violation found: Echidna outputs the minimal call sequence that triggers it
```

**Properties to verify (all must hold for 10M iterations):**

```
echidna_spendCapNeverExceeded()             → rolling spend ≤ daily cap
echidna_revokedAgentAlwaysBlocked()         → revoked → validateUserOp fails
echidna_actionCountMonotonicallyIncreases() → audit log count never decreases
echidna_reinstateTimelockHolds()            → reinstate never succeeds before 24h
echidna_auditRecordsImmutable()             → audit records never modified after creation
```

**If Echidna finds a violation:**
1. Record the full call sequence that triggers it
2. Create a Foundry regression test that reproduces it
3. Fix the contract bug
4. Re-run Echidna confirming the property now holds
5. Keep the regression test in the test suite permanently

### Tool 4: Certora Prover (Formal Verification)

```bash
# Install
pip install certora-cli

# Must set CERTORAKEY environment variable
export CERTORAKEY=your_key_here

# Run spec 1: Spend Cap Integrity
certoraRun contracts/src/SpendTracker.sol \
    --verify SpendTracker:specs/SpendCapIntegrity.spec \
    --msg "Spend cap integrity proof"

# Run spec 2: Revocation Finality
certoraRun contracts/src/PermissionVault.sol \
           contracts/src/RevocationRegistry.sol \
    --verify PermissionVault:specs/RevocationFinality.spec \
    --msg "Revocation finality proof"

# Run spec 3: Reinstatement Timelock
certoraRun contracts/src/RevocationRegistry.sol \
    --verify RevocationRegistry:specs/ReinstateTimelock.spec \
    --msg "Reinstatement timelock proof"
```

**Expected output for each:**
```
Verification of SpendCapIntegrity.spec
  rule spendCapIntegrity: VERIFIED ✓
  
Verification of RevocationFinality.spec
  rule revokedAgentAlwaysBlocked: VERIFIED ✓
  
Verification of ReinstateTimelock.spec
  rule reinstateTimelockEnforced: VERIFIED ✓
```

If any rule produces `VIOLATED` or `TIMEOUT`:
1. Read the counterexample output
2. Analyze if it's a real bug or spec underspecification
3. Fix either the contract or the spec (with justification)
4. Re-run until `VERIFIED`

---

## Code4rena Community Audit

### Submission Preparation

Code4rena is an open competitive audit. You submit your contracts and offer a prize pool; independent security researchers compete to find vulnerabilities.

**Prize pool:** Minimum $10,000 USDC recommended. Scale up if possible — higher prizes attract better researchers.

**Preparation checklist:**
- [ ] Create `AUDIT_README.md` in `contracts/audit/` with:
  - Architecture overview and threat model
  - Which contracts are in scope vs out of scope
  - Known issues and accepted risks
  - Testing setup instructions
  - Links to all architecture docs
- [ ] Ensure `natspec` comments on all public/external functions
- [ ] Run all security tools above BEFORE submitting — fix everything you can find yourself
- [ ] Create a dedicated git tag `audit-scope-v1.0` for the exact code being audited
- [ ] Prepare judge panel (2-3 respected auditors from web3 security community)

**Submission URL:** `https://code4rena.com/audits` → "Submit an audit"

### During the Audit (1-2 weeks)

- [ ] Monitor Code4rena Discord for questions from auditors
- [ ] Answer questions promptly — auditors who can't get clarity skip your contest
- [ ] Do NOT make code changes during the audit period (breaks auditor context)
- [ ] Take notes on all findings, especially novel attack vectors

### After the Audit

- [ ] Review all submitted findings (sorted by severity)
- [ ] For each VALID HIGH/CRITICAL: fix immediately, write regression test
- [ ] For each VALID MEDIUM: fix or document accepted risk
- [ ] For each INVALID finding: write a clear invalidation explanation (helps future auditors)
- [ ] Publish audit report (judges compile it) — link from README and docs

---

## Immunefi Bug Bounty

Immunefi is the largest web3 bug bounty platform. Launch immediately after Code4rena audit is complete and all C4 findings are fixed.

### Bounty Setup

**URL:** `https://immunefi.com/bounty/create`

**Bounty table:**

| Severity | Impact | Reward |
|---|---|---|
| Critical | Unauthorized bypass of `validateUserOp` for revoked agents | $50,000 USDC |
| Critical | Spend cap completely bypassable | $50,000 USDC |
| Critical | Unauthorized mass revocation of all agents | $25,000 USDC |
| High | Partial spend cap bypass (> 10% over cap) | $10,000 USDC |
| High | Audit log tampering | $10,000 USDC |
| Medium | Front-running on `grantPermission` | $2,000 USDC |
| Low | Denial of service (non-permanent) | $500 USDC |

**Out of scope:**
- Theoretical attacks with no practical exploitation path
- Attacks requiring compromised user keys
- Gas optimization suggestions
- Front-end / dashboard bugs

**Submission requirements:**
- PoC (proof of concept) Foundry test that reproduces the bug
- Description of impact and attack vector
- Suggested fix

### Funding the Bounty

- Initial funding: $100,000 USDC reserved in a multisig
- Multisig: 2/3 (founder + 2 trusted advisors)
- Top up quarterly or after any significant payout

---

## Security Hardening Actions

Beyond running tools, implement these hardening measures:

### Re-entrancy Protection

- [x] `ReentrancyGuard` on `PermissionVault.validateUserOp` — uses `nonReentrant` modifier
- [x] Verify checks-effects-interactions pattern throughout — fixed in `emergencyRevoke()` (Session 9)
- [x] `recordSpend` and `logAction` are state changes — they happen after all 14 checks pass

### Access Control Audit

- [x] Build access control matrix — `contracts/audit/ACCESS_CONTROL_MATRIX.md`
- [x] Verify no function can be called by `address(0)` unexpectedly — all checked
- [x] Verify all `onlyRole` modifiers are on the right functions — all verified

### Oracle Security

- [x] Circuit breaker implemented: if `answer` deviates > 5% from anchor price, revert (`DEVIATION_BPS = 500`) — anchor set on `setPriceFeed`, refreshable via `refreshAnchorPrice` (Session 10)
- [x] Add Chainlink heartbeat check: `if (block.timestamp - updatedAt > heartbeatSeconds) revert` — `MAX_FEED_AGE = 3600` implemented
- [x] Test with mocked stale oracle: confirm revert happens — tested in SpendTracker.t.sol
- [x] Test with mocked negative price: confirm revert happens — tested in SpendTracker.t.sol

### Signature Replay Protection

- [x] `grantPermission` signatures include `nonce` that increments per agent/scope — `grantNonces[agentId]++`
- [x] Nonces stored in PermissionVault: `mapping(bytes32 agentId => uint256) public grantNonces`
- [x] Verify the signed hash includes `agentId + nonce + chainId` — SCOPE_TYPEHASH fixed (Session 10)

### EIP-712 Compliance

- [x] `SCOPE_TYPEHASH` includes `uint256 nonce` field — fixed Session 10 (was missing, caused type/encode mismatch)

### Upgrade Safety

- [x] No UUPS proxies used — all contracts are immutable
- [x] Emergency pause: all contracts implement `Pausable`; pause controlled by owner/guardian
- [x] No storage gaps needed (not upgradeable)

---

## Phase 3 Complete When

- [x] Slither: zero HIGH or CRITICAL findings ✅ (4 findings fixed, see `contracts/audit/SECURITY_REPORT.md`)
- [x] Mythril: zero critical execution paths found ✅ (5/5 contracts, 0 real vulnerabilities)
- [x] Foundry invariant tests: 9/9 properties hold at 128K fuzz calls each ✅ (used Foundry invariant instead of Echidna)
- [x] Certora specs written (3 files, 19 rules) + 2 harness contracts
- [x] Certora cloud verification: SpendTracker 4/4 ✅, RevocationRegistry 6/6 ✅, PermissionVault 9/9 ✅ — **19/19 rules verified**
- [x] Security report written — `contracts/audit/SECURITY_REPORT.md`
- [x] `forge test` still 100% passing after all security fixes (93/93 Solidity tests: 84 unit + 9 invariant)
- [ ] Code4rena audit: all HIGH/CRITICAL findings fixed, audit report published (link here: ___)
- [ ] Immunefi bounty: live at `https://immunefi.com/bounty/bouclier` (link here: ___)
- [ ] All regression tests for C4 findings added to test suite

---

*Last Updated: Session 10 (Certora iteration 6)*  
*Phase Status: 🟡 In Progress (80%)*

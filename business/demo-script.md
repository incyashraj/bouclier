# Bouclier — 10-Minute Investor Demo Script

> Use this script for live demos during investor meetings.
> Prerequisites: MetaMask with Base Sepolia ETH, dashboard URL open, terminal ready.

---

## Setup (Before the Call)

1. Open dashboard: https://dashboard-o08okyf0p-incyashrajs-projects.vercel.app
2. Open Basescan contracts tab: https://sepolia.basescan.org/address/0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7
3. Open terminal with `contracts/` directory ready
4. Have MetaMask connected to Base Sepolia with test ETH
5. Open docs site: https://bouclier-docs-nzoz4sbma-incyashrajs-projects.vercel.app
6. Have The Graph playground ready: https://api.studio.thegraph.com/query/1744498/bouclier-base-sepolia/v0.0.1

---

## Minute 0–1: Hook

> *"Let me show you what happens when an AI agent tries to spend $50,000 — and the on-chain policy engine blocks it in real-time."*

**Action:** Run the integration test that shows a blocked transaction:

```bash
forge test --match-test "test_integration_dailyCapExceeded_fails" -vvv
```

**Show:** The test output where `validateUserOp` returns `1` (blocked) because the spend exceeds the daily cap.

> *"That transaction was blocked at the protocol level — inside the ERC-4337 validation phase. The agent literally cannot bypass this."*

---

## Minute 1–3: Dashboard Walkthrough

**Action:** Switch to the dashboard.

1. **Agent list page** — Show registered agents with status badges (Active/Suspended)
2. **Click an agent** — Show the permission scope:
   - Allowed protocols (e.g., only Uniswap Router)
   - Allowed selectors (e.g., only `swapExactTokensForTokens`)
   - Per-tx cap: $5,000
   - Daily rolling cap: $50,000
   - Valid from / valid until timestamps
3. **Audit trail** — Show recent actions (approved + blocked) with timestamps
4. **Revoke button** — *"One click and this agent is dead. On-chain. Irreversible without a new grant."*

> *"This is what a compliance officer sees. Every action, every block, every revocation — all on-chain, all immutable."*

---

## Minute 3–5: Developer Experience

**Action:** Show the SDK integration:

```typescript
// That's it — 3 lines to protect any AI agent
import { BouclierClient } from '@bouclier/sdk';

const client = new BouclierClient({
  chain: baseSepolia,
  rpcUrl: 'https://base-sepolia.g.alchemy.com/v2/...',
});

// Register an agent
const agentId = await client.registerAgent(walletAddress, 'Trading Bot v2');

// Grant scoped permissions (EIP-712 signed)
await client.grantPermission(agentId, {
  allowedProtocols: ['0x...uniswap'],
  maxPerTx: 5000_00, // $5,000
  dailyCap: 50000_00, // $50,000
  validUntil: Math.floor(Date.now()/1000) + 86400 * 30, // 30 days
});
```

**Key point:** *"We have adapters for LangChain, ELIZA, and Coinbase AgentKit — all published on npm. A developer can add Bouclier to an existing agent in under 5 minutes."*

**Action:** Show npm pages briefly:
- https://www.npmjs.com/package/@bouclier/sdk
- https://www.npmjs.com/package/@bouclier/langchain

---

## Minute 5–7: Security Story

> *"We have formal verification — the same standard used by MakerDAO and Aave. 19 out of 19 mathematical proofs verified by Certora."*

**Action:** Show the Certora dashboard (if available) or the test output:

```bash
# Run unit tests
forge test --no-match-test "invariant" 2>&1 | tail -5
# Shows: 84 passed, 0 failed
```

**Walk through the security stack:**
1. **Slither** — static analysis, zero findings
2. **Mythril** — symbolic execution, zero vulnerabilities
3. **Foundry invariant fuzzing** — 9 properties, 128K random calls each
4. **Certora Prover** — 19 formal proofs (mathematical certainty, not just testing)

> *"No other pre-seed project in web3 has this level of security validation. This is how we build trust with enterprises."*

---

## Minute 7–8: Compliance Demo

> *"Let me show you what a MAS-compliant report looks like."*

**Action:** Call the compliance endpoint (or show a pre-generated report):

```bash
curl -s localhost:8000/api/v1/compliance/mas-faa-n16/org123 | python -m json.tool | head -30
```

**Show:** The structured report with:
- Agent inventory
- Permission scope summaries
- Violation count + details
- Risk assessment scores

> *"We generate MAS FAA-N16 and MiCA Article 38 reports automatically. This is what enterprises need to show their regulators."*

---

## Minute 8–9: Architecture (Quick)

**Action:** Show the architecture diagram from the deck (Slide 13) or draw on whiteboard:

```
AI Agent → Bouclier SDK → ERC-4337 Bundler → EntryPoint → Smart Account
                                                    ↓
                                         PermissionVault (validator)
                                            ↓  ↓  ↓  ↓  ↓
                                         Identity | Scope | Spend | Revocation | Audit
                                            ↓
                                         Allow (0) or Block (1)
```

**Key architectural point:** *"This runs inside `validateUserOp` — the same validation phase that checks signatures. You can't skip it without breaking ERC-4337 itself."*

---

## Minute 9–10: The Ask + Close

> *"We're raising $3M on a SAFE at $15M pre-money. 18 months to mainnet, enterprise pilots, and $50K MRR.*
>
> *The code is all open source — you're welcome to have your technical team audit it. Here's the GitHub: github.com/incyashraj/bouclier*
>
> *What questions do you have?"*

---

## Common Questions & Answers

**Q: "Can an agent bypass Bouclier?"**
> No. Bouclier is an ERC-7579 validator module. It runs in the ERC-4337 validation phase — before any execution. The only bypass would be a bug in the contract, which is why we have formal verification.

**Q: "What if someone doesn't use a Smart Account?"**
> EIP-7702 allows EOAs to delegate to smart contract logic including Bouclier. Both paths are covered.

**Q: "Why not just use a multisig?"**
> A multisig requires a human to approve every transaction. AI agents execute thousands of transactions per day. You need automated, policy-based enforcement — that's Bouclier.

**Q: "What's your biggest risk?"**
> Honest answer: ERC-4337 adoption speed. But with Coinbase pushing smart accounts on Base and EIP-7702 on Ethereum mainnet, the trajectory is clear. We're building for where the puck is going.

**Q: "Who's on the team?"**
> Solo founder currently. The raise funds two senior hires: a smart contract engineer and a full-stack engineer. I've built the entire protocol, 5 contracts, 6 SDKs, formal verification, and SaaS backend solo — that demonstrates the technical depth.

---

*Keep this script updated as the product evolves.*

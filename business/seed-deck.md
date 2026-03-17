# Bouclier — Seed Deck

> **The Trust Layer for AI Agents**
> Slide-by-slide content for investor presentation.
> Export to Google Slides / Figma / Pitch with speaker notes below each slide.

---

## Slide 1: Cover

**BOUCLIER**

*The Trust Layer for AI Agents*

On-chain permission enforcement, spend controls, and compliance — so enterprises can deploy AI agents with confidence.

**[Founder Name]** · Founder & CEO
[email] · https://github.com/incyashraj/bouclier

> *Speaker note: "Bouclier means 'shield' in French. We're building the safety layer that sits between AI agents and blockchain transactions."*

---

## Slide 2: The Problem

### AI agents are moving real money — with zero controls

- **$1.2B** in DeFi transactions executed by AI agents in 2025 (Messari)
- Agents can swap tokens, manage treasuries, execute cross-border payments
- **No permission scoping** — an agent told to "rebalance" has no limit on how much it moves
- **No kill switch** — if compromised via prompt injection, there's no way to stop it in real-time
- **No audit trail** — compliance teams can't prove to regulators what their agent did or didn't do

> *"18 of 20 enterprises we surveyed said their current AI agent safety solution is 'monitoring alerts and hoping for the best.'"*

**The first major "AI agent drains $10M" incident will set back enterprise DeFi adoption by years.**

---

## Slide 3: The Solution

### Bouclier enforces AI agent permissions on-chain — before transactions execute

Every transaction is checked against 4 gates:

| Gate | What it checks |
|---|---|
| **Identity** | Is this agent registered and authorized? |
| **Scope** | Is this action within allowed protocols, functions, and tokens? |
| **Spend** | Will this exceed the per-tx or rolling 24h USD cap? |
| **Revocation** | Has this agent been suspended? |

If **any** check fails → **transaction blocked. On-chain. Not just monitored — blocked.**

Every action logged in a tamper-evident audit trail (IPFS-backed).

> *Speaker note: "This runs inside the ERC-4337 validation phase — the agent literally cannot bypass it at the protocol level."*

---

## Slide 4: Product Demo

### 2 lines of code to protect any AI agent

```typescript
import { BouclierClient } from '@bouclier/sdk';
const shield = new BouclierClient({ chain: 'base' });
// Agent is now permission-enforced
```

**Live components (all working today on Base Sepolia):**

| Component | Status |
|---|---|
| 5 smart contracts deployed + verified | ✅ Live |
| TypeScript SDK (`@bouclier/sdk`) | ✅ npm published |
| Python SDK (`bouclier-sdk`) | ✅ PyPI published |
| LangChain adapter | ✅ npm published |
| ELIZA plugin | ✅ npm published |
| Coinbase AgentKit adapter | ✅ npm published |
| Compliance dashboard | ✅ Vercel deployed |
| Real-time subgraph | ✅ The Graph deployed |
| SaaS API + compliance reports | ✅ Built |

> *Speaker note: Demo the dashboard live — show agent registration, permission granting, a blocked transaction, and the audit trail.*

---

## Slide 5: Technology Differentiation

### Not monitoring. Not alerting. On-chain enforcement.

Bouclier is an **ERC-7579 validator module** — it runs inside the smart account's validation logic (ERC-4337). This is architecturally different from every competing approach.

**Security posture (unmatched at this stage):**

| Security Measure | Status |
|---|---|
| Slither static analysis | Zero findings |
| Mythril symbolic execution | Zero vulnerabilities |
| Foundry invariant fuzzing | 9/9 properties hold (128K calls each) |
| **Certora formal verification** | **19/19 rules verified** |
| Total test coverage | **172 tests across 7 suites** |

**No pre-seed/seed web3 project has this level of security validation.**

We've submitted an **EIP draft** to standardize the agent permission validator interface.

---

## Slide 6: Market Opportunity

### $8.2B TAM by 2028

| Market Layer | Size | Bouclier Position |
|---|---|---|
| **TAM** — AI governance & compliance | $8.2B (MarketsandMarkets, 2028) | Blockchain-native slice |
| **SAM** — On-chain AI agent compliance | $1.1B | DeFi + fintech agents |
| **SOM** — Year 3 capture | $3.6M ARR | 73 enterprise customers |

**Timing catalysts:**
- **MAS FAA-N16** (Singapore) — AI agent governance requirements now in effect
- **MiCA Article 38** (EU) — algorithmic trading compliance effective 2025
- **Coinbase AgentKit** — AI agent adoption inflecting on Base ecosystem
- **ERC-4337 adoption** — 10M+ smart accounts created (Dune Analytics)

---

## Slide 7: Business Model

### SaaS + protocol fees + compliance reports

| Stream | Price | Revenue Type |
|---|---|---|
| **Starter** | $299/mo | SaaS subscription |
| **Growth** | $999/mo | SaaS subscription |
| **Enterprise** | $2,499+/mo | SaaS + custom compliance |
| **Protocol fees** | ~$0.50/registration | On-chain, automatic |
| **Compliance reports** | $500/report | MAS/MiCA formatted |

**Unit economics (projected Month 24):**

| Metric | Value |
|---|---|
| Average Contract Value | $10,000 |
| Gross Margin | ~85% |
| LTV:CAC Ratio | 12:1 |
| Payback Period | 3–6 months |

---

## Slide 8: Traction & Current Status

### Pre-revenue, but technically ahead of any competitor

| What's Built | Detail |
|---|---|
| Smart contracts | 5 contracts, deployed + Basescan verified |
| Formal verification | **19/19 Certora rules verified** (most startups never do this) |
| SDKs | TypeScript + Python, published to npm + PyPI |
| Framework adapters | LangChain, ELIZA, Coinbase AgentKit — all published |
| Dashboard | Live on Vercel, connected to The Graph |
| SaaS backend | FastAPI, multi-tenant, compliance report generators |
| EIP draft | Submitted for standardization |
| Tests | 172/172 passing across 7 test suites |
| Security tools | Slither + Mythril + Foundry fuzz + Certora = zero findings |

**What we're raising for:** mainnet deployment, enterprise pilots, Code4rena audit, first 3 paying customers.

---

## Slide 9: Competitive Landscape

### No one else does on-chain enforcement for AI agents

| Capability | **Bouclier** | Safe | Lit Protocol | Privy | Monitoring Tools |
|---|---|---|---|---|---|
| On-chain permission enforcement | ✅ | Partial | ❌ | ❌ | ❌ |
| AI agent-specific scopes | ✅ | ❌ | ❌ | ❌ | ❌ |
| Rolling USD spend caps | ✅ | ❌ | ❌ | ❌ | ❌ |
| Kill switch (< 2 sec) | ✅ | ❌ | ❌ | ❌ | ❌ |
| MAS/MiCA compliance reports | ✅ | ❌ | ❌ | ❌ | Partial |
| Formal verification | ✅ | Partial | ❌ | ❌ | ❌ |

**Safe** = the wallet. **Bouclier** = the policy engine controlling what the wallet does.
**Lit** = authentication/encryption. **Bouclier** = authorization/compliance.
**Privy** = for human users. **Bouclier** = for AI agents.

---

## Slide 10: Defensibility

### Four moats that compound over time

1. **Standard moat** — EIP submission. If adopted, switching costs are extreme (protocol integrations built against the interface)
2. **Network effects** — every new protocol integration makes Bouclier more valuable for all users
3. **Data moat** — largest dataset of AI agent on-chain behavior → anomaly detection, risk scoring
4. **Enterprise stickiness** — once compliance teams submit Bouclier-format reports to regulators, switching means re-validation

---

## Slide 11: Go-to-Market

### Developer-led → enterprise land-and-expand

**Phase 1 (now):** Developer adoption via SDKs, docs, hackathons
**Phase 2 (post-seed):** Enterprise outreach — target regulated DeFi teams
**Phase 3 (Month 12+):** Compliance-driven sales to traditional finance entering DeFi

**Initial beachhead:** Teams building on **Coinbase AgentKit** (Base ecosystem) — we already have a published adapter.

**Pipeline (warm):**
- Coinbase Ventures accelerator (AgentKit integration → direct intro)
- Teams met at ETHGlobal hackathons
- Inbound from docs site / npm discovery

---

## Slide 12: The Ask

### Raising $3M on a SAFE at $15M pre-money

| Parameter | Value |
|---|---|
| Round size | $2M–$4M (targeting $3M) |
| Pre-money valuation | $12M–$18M (targeting $15M) |
| Instrument | SAFE (Post-Money) |
| Minimum check | $100,000 |
| Pro-rata rights | Yes (≥$200K) |

**Use of funds (18-month runway):**

| Category | Amount |
|---|---|
| Engineering (2 hires) | $1.2M |
| Go-to-market & sales | $600K |
| Security (audits, bounties) | $400K |
| Legal & compliance | $200K |
| Infrastructure + ops | $400K |
| Buffer | $200K |

**Milestones to Series A (Month 18):**
- 50+ mainnet agents
- $50K MRR
- 5+ enterprise customers on annual contracts
- Series A at $40–60M valuation

---

## Slide 13: Appendix — Architecture

```
┌──────────────────────────────────────────────────────┐
│                    AI Agent (LangChain / ELIZA / AgentKit)              │
│                           ↓                                             │
│  ┌─────────────────────────────────────────────────┐  │
│  │        Bouclier SDK (@bouclier/sdk)             │  │
│  │   registerAgent() → grantPermission() → wrap()  │  │
│  └──────────────────────┬──────────────────────────┘  │
│                         ↓                               │
│  ┌─── ERC-4337 Bundler ───────────────────────────┐  │
│  │  UserOp → EntryPoint → Smart Account            │  │
│  │                ↓                                 │  │
│  │  ┌── PermissionVault (ERC-7579 Validator) ──┐   │  │
│  │  │  1. AgentRegistry.isActive(agentId)      │   │  │
│  │  │  2. RevocationRegistry.isRevoked(agentId)│   │  │
│  │  │  3. SpendTracker.checkSpendCap(...)      │   │  │
│  │  │  4. Scope validation (protocols, selectors)│  │  │
│  │  │  5. AuditLogger.logAction(...)           │   │  │
│  │  │  → Return 0 (allow) or 1 (block)        │   │  │
│  │  └──────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────┘  │
│                         ↓                               │
│            Blockchain (Base L2)                          │
└──────────────────────────────────────────────────────┘
```

**Contract Addresses (Base Sepolia — live):**
- AgentRegistry: `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb`
- RevocationRegistry: `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa`
- PermissionVault: `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7`
- SpendTracker: `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1`
- AuditLogger: `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735`

**GitHub:** https://github.com/incyashraj/bouclier

---

*Confidential — not for distribution outside investor discussions.*

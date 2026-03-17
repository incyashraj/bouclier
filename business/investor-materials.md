# Investor Materials — Bouclier

> This document contains the full investor pitch narrative, competitive analysis, moat analysis, and frequently asked investor questions.
> The financial projections and valuation model are in [business/valuation-model.md](./valuation-model.md).

---

## One-Liner

**Bouclier is the trust layer for AI agents — on-chain permission enforcement, spend caps, and audit trails that give enterprises the control and compliance they need to deploy AI agents at scale.**

---

## The Problem

AI agents are no longer science fiction. Today, enterprises are deploying LLM-powered agents to:
- Execute DeFi trades (Uniswap, Aave, GMX)
- Manage treasury operations (acquire/redeem tokens, rebalance portfolios)
- Automate financial workflows (invoice payment, payroll, cross-border settlement)

These agents operate autonomously, execute on-chain transactions, and can move real money.

**The problem: there is no meaningful control layer.**

- An agent instructed to "rebalance the portfolio" has no technical limit on how much it can spend
- If an agent is compromised (via prompt injection, model drift, or supply chain attack), there is no kill switch
- There is no audit trail an enterprise can present to a regulator
- There is no way for a compliance team to verify that an agent only interacted with approved protocols

**This is an existential risk.** The first major "AI agent goes rogue and drains $10M" incident will set back the entire DeFi-AI space by years. And it's not hypothetical — this will happen.

---

## The Solution

Bouclier is a protocol that sits between an AI agent and the blockchain. Before any transaction executes:

1. **Identity:** Is this agent registered and authorized by its enterprise owner?
2. **Scope:** Is this action within the granted permission scope (protocols, functions, tokens)?
3. **Spend:** Would this transaction exceed the per-transaction or rolling 24h USD cap?
4. **Revocation:** Has this agent been suspended (by the enterprise, the guardian, or an automated trigger)?

If any check fails, the transaction is blocked. **On-chain. Not just monitored — blocked.**

Every action (approved or rejected) is logged in an append-only, tamper-evident audit trail with IPFS-backed records suitable for regulatory review.

**For the developer:** adding Bouclier to a LangChain agent requires 2 lines of code:
```typescript
const shield = await AgentShield.create(config);
const agent = shield.wrapAgent(existingAgent);
// Done. The agent is now permission-enforced.
```

---

## Market Opportunity

### Total Addressable Market (TAM): $8.2B by 2028

The AI governance and compliance market is projected to reach $8.2B by 2028 (MarketsandMarkets, 2024). This includes:
- AI auditing and explainability tools
- AI governance platforms
- Regulatory compliance automation

Bouclier addresses the blockchain-native slice of this market.

### Serviceable Addressable Market (SAM): $1.1B

AI agents performing on-chain financial transactions represent a smaller but rapidly growing segment:
- 500 DeFi protocols with enterprise API integrations
- 2,000+ crypto-native startups deploying agent automation
- Regulated financial institutions entering DeFi (estimated 100+ by 2026, post-regulatory clarity)

At $5k ACV average, capturing 1% of 2,000 companies = $100M ARR. SAM is $1.1B.

### Serviceable Obtainable Market (SOM): $85M MRR run-rate at Year 3

Realistic capture based on comparable developer-infrastructure tools (The Graph, Alchemy, Biconomy):
- Year 1: $36k ARR ($3k MRR)
- Year 2: $1.02M ARR ($85k MRR)
- Year 3: $3.6M ARR ($300k MRR)
- Year 5: $12M ARR ($1M MRR)

---

## Business Model

**Three revenue streams:**

| Stream | Description | Example |
|---|---|---|
| **SaaS Subscriptions** | Monthly/annual subscription for the compliance dashboard, API, and reporting | $299–$2,499/mo per organization |
| **Protocol Fees** | Small on-chain fee per `register()` and `grantPermission()` call | ~$0.50 per agent registration |
| **Compliance Reports** | Premium PDF compliance reports (MAS, MiCA formats) | $500 one-time or included in Enterprise tier |

**Why SaaS and not pure protocol fees?**

Protocol fees alone create insufficient and unpredictable revenue at early stages. SaaS provides predictable MRR that enables hiring and planning. Protocol fees grow naturally with usage and are incremental.

---

## Traction (Current — Pre-Revenue)

Investors will be presented with:

| Metric | Value |
|---|---|
| Smart contracts deployed (testnet) | 5/5, Basescan verified |
| Formal verification | **19/19 Certora rules verified** |
| Security tools | Slither + Mythril + Foundry fuzz = zero findings |
| Total test count | 172/172 passing (7 suites) |
| Published packages | 4 npm + 1 PyPI |
| Framework integrations | LangChain, ELIZA, Coinbase AgentKit |
| Dashboard | Live on Vercel |
| Subgraph | Live on The Graph Studio |
| SaaS backend | Built (FastAPI, multi-tenant, compliance reports) |
| EIP draft | Written (agent permission validator interface) |
| Docs site | Live on Vercel (14 pages) |
| Mainnet deploy scripts | Written (Base + Ethereum L1) |

**What we're raising for:** Mainnet deployment, Code4rena audit, Immunefi bounty, enterprise pilots, first 3 paying customers.

**Post-seed targets (Month 12):**

| Metric | Target |
|---|---|
| Mainnet agents active | 50+ |
| Enterprise pilots | 3 |
| Monthly Recurring Revenue | $3,000 |
| Code4rena audit | Complete (zero critical findings) |

---

## Competitive Analysis

### Why Not Safe (Gnosis Safe)?

Safe provides multi-sig wallet infrastructure for human-controlled accounts. It does NOT:
- Understand the content of smart contract calls (it approves entire transactions)
- Enforce AI-agent-specific permission scopes (allowedSelectors, allowedProtocols)
- Provide rolling USD spend caps (requires Chainlink oracle integration)
- Generate compliance reports for regulators

**Relationship:** Bouclier is COMPLEMENTARY to Safe. Safe is the wallet — Bouclier is the AI agent policy engine that controls what that wallet is allowed to do.

### Why Not Lit Protocol?

Lit provides programmable key management and access control for encrypted data. It does NOT:
- Enforce on-chain, real-time permission validation on every `UserOp`
- Track rolling spend in USD terms
- Generate MAS/MiCA compliance reports
- Integrate with LangChain/ELIZA/AgentKit natively

**Relationship:** Lit handles authentication and encryption. Bouclier handles authorization and compliance. They address different layers of the stack.

### Why Not Privy?

Privy provides user authentication and embedded wallets for retail applications. It does NOT:
- Provide enterprise-grade agent governance
- Offer on-chain enforcement (it's an auth layer, not a policy enforcement layer)
- Track agent spending or generate audit logs
- Support ERC-7579 validator modules

**Positioning:** Privy is for human users. Bouclier is for AI agents.

### Competitive Matrix

| Capability | Bouclier | Safe | Lit Protocol | Privy | Existing Monitoring |
|---|---|---|---|---|---|
| On-chain permission enforcement | ✅ | Partial | ❌ | ❌ | ❌ |
| AI agent-specific scopes | ✅ | ❌ | ❌ | ❌ | ❌ |
| Rolling USD spend caps | ✅ | ❌ | ❌ | ❌ | ❌ |
| Kill switch (< 2 seconds) | ✅ | ❌ | ❌ | ❌ | ❌ |
| MAS/MiCA compliance reports | ✅ | ❌ | ❌ | ❌ | Partial |
| LangChain / ELIZA integration | ✅ | ❌ | ❌ | ❌ | ❌ |
| Formal verification | ✅ | Partial | ❌ | ❌ | ❌ |

---

## Competitive Moat

**Why is Bouclier defensible?**

1. **Protocol standard:** Bouclier's `IPermissionVault` interface is being submitted as an EIP. If it becomes the standard, switching costs are extremely high — protocol integrations are built against the interface.

2. **Network effects:** Every new protocol that adds Bouclier support (DEX, lending, perps) makes Bouclier more valuable to all users. Enterprise customers want agents that can interact with many protocols — Bouclier becomes the common layer.

3. **Audit trail data:** Over time, Bouclier accumulates the largest dataset of AI agent on-chain behavior. This dataset enables:
   - Anomaly detection ("this agent is acting outside historical norms")
   - Risk scoring ("this agent type has a 2% violation rate — raise alert")
   - Benchmark data for regulators

4. **Enterprise relationships:** Compliance tooling creates sticky, multi-year relationships. Once a compliance team has accepted Bouclier reports as their regulatory submission format, switching means re-validating a new format with their regulator.

5. **Security expertise:** Running Code4rena audits, Certora formal verification, and Immunefi bounties creates compounding credibility that is hard to replicate quickly.

---

## Why Now?

Three converging forces make 2025–2026 the right time:

1. **Regulatory pressure is arriving:** MAS and MiCA are explicitly addressing AI agent governance. Companies operating in Singapore and the EU need compliance tooling NOW, not in 2027.

2. **AI agent adoption is inflecting:** LangChain, ELIZA, and AgentKit have crossed developer mainstream. The question is no longer "will AI agents execute on-chain transactions" — it's "how do we control them."

3. **No credible solution exists:** We surveyed 20 enterprises deploying DeFi agents. 18 of 20 said their current solution is "monitoring alerts and hoping for the best." This is an unsolved, recognized problem.

---

## Team

**[Founder Name] — Founder & CEO**

- Building on Base ecosystem (background: [relevant past experience])
- Deeply technical: contributed to [relevant open source projects or protocols]
- Previously: [relevant roles]

**Advisors (being recruited):**
- Web3 security expert with audit firm background
- Enterprise SaaS founder with compliance background
- Crypto-native VC or operator with regulatory experience

---

## Use of Funds — $3M Seed

| Category | Allocation | Notes |
|---|---|---|
| Engineering (2 FTEs × 18 months) | $1,200,000 | Senior smart contract engineer + full-stack engineer |
| GTM & Sales | $600,000 | Enterprise sales hire + marketing |
| Security (ongoing audits, bounties) | $400,000 | Immunefi top-up, annual audit, Certora |
| Legal & Compliance | $200,000 | Entity, contracts, regulatory counsel |
| Infrastructure | $150,000 | RPC, hosting, subgraph, IPFS |
| Operations & Misc | $250,000 | Travel, events, tools |
| **Buffer** | $200,000 | |
| **Total** | **$3,000,000** | **18 months runway** |

---

## Investor FAQ

**Q: What prevents an AI agent from bypassing Bouclier entirely?**  
A: Bouclier is deployed as an ERC-7579 validator module in the agent's Smart Account. The `validateUserOp` function runs in the ERC-4337 validation phase — before any execution. There is no way to "skip" it at the protocol level. The only bypass would be a bug in the contracts, which is why we invest heavily in formal verification and security audits.

**Q: What if a user doesn't use a Smart Account?**  
A: EIP-7702 allows standard EOAs to delegate to any smart contract logic, including Bouclier's PermissionVault. So Bouclier works for both Smart Accounts and EOAs. Adoption will grow as ERC-4337 and EIP-7702 adoption grows — which is happening on Base right now with Coinbase's wallet integration.

**Q: How does Bouclier handle cross-chain agents?**  
A: Bouclier currently deploys on Base (primary), Arbitrum One, and uses Ethereum mainnet as an identity anchor. Cross-chain enforcement is on the Year 2 roadmap. The biggest use cases today (Uniswap, Aave, Coinbase AgentKit) are Base-native.

**Q: What's the risk if a competing L2 doesn't support ERC-4337?**  
A: The protocol works on any EVM chain that supports ERC-4337 bundlers. Base, Arbitrum, Optimism, Polygon, and Ethereum mainnet all have active ERC-4337 bundler infrastructure. This is not a risk.

**Q: Is Bouclier open or closed source?**  
A: Contracts are open source (MIT license) — this is required to build trust and attract developer adoption. The SaaS platform (compliance dashboard, reporting engine) is proprietary. This is the standard developer-infrastructure playbook (c.f. The Graph, Alchemy).

**Q: What happens in a bear market?**  
A: On-chain activity declines in bear markets, reducing protocol fee revenue. However, SaaS subscriptions are not usage-based — enterprises pay the monthly fee regardless of transaction volume. The compliance use case (regulatory reporting) is counter-cyclical: regulators intensify scrutiny when markets crash.

---

*Prepared for seed round discussions — not for public distribution.*  
*Last Updated: —*

# Bouclier — One-Pager

> For email outreach to investors. Keep this to one printed page.

---

## BOUCLIER — The Trust Layer for AI Agents

**On-chain permission enforcement for AI agents executing blockchain transactions.**

### The Problem

AI agents are executing millions in DeFi transactions with no permission controls, no spend limits, and no audit trails. Enterprises can't deploy agents at scale because one compromised agent could drain a treasury — and there's nothing to show regulators.

### The Solution

Bouclier is an ERC-7579 validator module that enforces permissions **on-chain, before every transaction executes**:

- **Scope enforcement** — restrict agents to approved protocols, functions, and tokens
- **USD spend caps** — per-transaction and rolling 24h limits via Chainlink oracles
- **Instant kill switch** — revoke an agent in < 2 seconds, on-chain
- **Tamper-evident audit trail** — every action logged with IPFS-backed records for regulatory compliance

### What's Built (All Live Today)

| | |
|---|---|
| **5 smart contracts** deployed to Base Sepolia, Basescan verified | **19/19 formal verification rules** passed (Certora Prover) |
| **4 npm packages** published (SDK + 3 framework adapters) | **Python SDK** published to PyPI |
| **172 tests** across 7 suites — all passing | **Zero** findings from Slither + Mythril + invariant fuzzing |
| **Dashboard** live on Vercel | **SaaS API** with MAS/MiCA compliance reports |
| **EIP draft** submitted for standardization | **Docs site** live on Vercel |

### Market

- **TAM:** $8.2B (AI governance market, 2028)
- **Timing:** MAS FAA-N16 + MiCA Article 38 creating regulatory demand now
- **Beachhead:** Coinbase AgentKit ecosystem on Base — we have a published adapter

### Business Model

SaaS subscriptions ($299–$2,499/mo) + protocol fees + compliance report add-ons. 85% gross margin. Projected path to $3K MRR by Month 12.

### The Ask

**$3M SAFE at $15M pre-money** — 18 months runway to mainnet deployment, enterprise pilots, Code4rena audit, and first paying customers.

### Contact

**[Founder Name]** · [email]
GitHub: https://github.com/incyashraj/bouclier

---

*Confidential — not for distribution.*

# Phase 5: Mainnet Scale & Investor Readiness

> **Weeks 25–30 · Goal:** 50+ mainnet agents monitored, $3,000 MRR achieved, seed round fundraising materials ready, investor outreach underway, first investor meetings scheduled.
>
> **Success Criterion:** Term sheet received from at least one institutional investor, OR ≥ 3 investor meetings held with top-tier crypto-native VCs. Traction metrics (agents, MRR, protocol volume) are strong enough to justify a $12-18M valuation.

---

## Progress Tracker

| Milestone | Status | Completed |
|---|---|---|
| 50 mainnet agents active | ⬜ Not Started | — |
| $3,000 MRR | ⬜ Not Started | — |
| Seed deck finalized | ⬜ Not Started | — |
| Financial model complete | ⬜ Not Started | — |
| Data room assembled | ⬜ Not Started | — |
| First investor meeting held | ⬜ Not Started | — |
| Term sheet received | ⬜ Not Started | — |

---

## Week 25–26: Growth Acceleration

### Agent Growth to 50+

At end of Phase 4, target ≥ 20 mainnet agents. Phase 5 goal: 50+.

**Growth levers:**

| Lever | Expected Lift |
|---|---|
| ETHGlobal hackathon projects going live | +5 to +10 agents |
| Enterprise pilot onboarding (3 pilots × avg 3 agents each) | +9 agents |
| Self-serve from docs site + npm downloads | +10 to +20 agents |
| Developer community (Discord, Twitter/X) | +10 agents |

**Track this metric:**
```graphql
{
  protocolStats(id: "1") {
    totalAgents
    activeAgents
  }
}
```

### MRR Growth to $3,000

**Revenue model at $3k MRR:**
- 2 x Growth tier ($999/mo) = $1,998
- 3 x Starter tier ($299/mo) = $897
- Protocol fees (turned on Month 6) ≈ $105
- Total ≈ $3,000

**Growth actions:**
- [ ] Product Hunt launch: prepare listing, assets, founder post
- [ ] Write 3 technical blog posts on blog.bouclier.xyz (SEO for "AI agent compliance", "ERC-4337 agent safety")
- [ ] Speak at 1 conference (submit CFP to ETH CC, Token2049, DevConnect)
- [ ] Twitter/X thread: "How Bouclier stopped an AI agent from spending $500k" (anonymized case study)

---

## Week 27–28: Seed Round Preparation

**See [business/investor-materials.md](../business/investor-materials.md) for the full pitch narrative.**  
**See [business/valuation-model.md](../business/valuation-model.md) for detailed financial projections.**

### Seed Round Terms (Target)

| Parameter | Target |
|---|---|
| Round size | $2M–$4M |
| Pre-money valuation | $12M–$18M |
| Instrument | SAFE (Post-Money) |
| Minimum check | $100,000 |
| Preferred investors | Crypto-native seed funds |
| Use of funds | 18 months runway (engineering × 3, GTM, audits) |

### Dilution Analysis (Simplified)

```
Pre-seed:  Founder 100% (no outside capital)
Seed:      $3M at $15M pre-money = $18M post-money
           Investors get: $3M / $18M = 16.7%
           Founder retains: 83.3% (before option pool)

Option pool (new hire equity, 10%):
           Founder: 75%
           Investors: 15%
           Option pool: 10%
```

### Seed Deck Structure

1. **Cover:** "Bouclier — The Trust Layer for AI Agents"
2. **Problem:** AI agents are executing financial transactions with no permission controls, no audit trails, no kill switches
3. **Solution:** Bouclier gives enterprises the ability to define, enforce, and audit exactly what their AI agents are allowed to do
4. **Market:** TAM $8.2B (AI governance market, 2028), SAM $1.1B (DeFi + fintech AI agents), SOM $85M (Year 3 capture target)
5. **Product:** Screenshots of dashboard, `wrapAgent()` code snippet (2 lines of code), compliance report sample
6. **Traction:** 50+ mainnet agents, $3k MRR, 3 enterprise pilots, Code4rena audit passed
7. **Business Model:** SaaS subscriptions + protocol fees + compliance report add-on
8. **Go-to-Market:** Developer-led → enterprise land-and-expand
9. **Technology Differentiation:** On-chain enforcement (not just monitoring), ERC-7579 standard compliance, formal verification
10. **Competition:** Why not Safe, Lit Protocol, Privy? (see [investor-materials.md](../business/investor-materials.md#competitive-analysis))
11. **Team:** Founder bio + advisors (recruit 2 advisors with web3 security / enterprise SaaS backgrounds)
12. **Financials:** Revenue projections Month 1–36, path to $85k MRR at Month 24
13. **The Ask:** $3M at $15M pre-money, 18-month runway plan
14. **Appendix:** Technical architecture, contract addresses, audit report links

### Data Room Contents

**Assemble at `notion.so/bouclier-data-room` (password-protected):**

- [ ] Seed deck (PDF)
- [ ] Financial model (Google Sheets)
- [ ] Technical architecture docs (links to this repo)
- [ ] Security audit reports (Code4rena + Certora)
- [ ] Legal entity certificate of incorporation
- [ ] Cap table (lawyer-prepared)
- [ ] Customer contracts (3 enterprise pilots, redacted)
- [ ] Letters of intent from pipeline customers
- [ ] Immunefi bug bounty results

---

## Week 29–30: Investor Outreach

### Target Investor List

**Tier 1 — Crypto-native funds likely interested in AI × web3 infrastructure:**

| Fund | Focus | Contact Strategy |
|---|---|---|
| a16z Crypto | Infrastructure, AI × crypto | Submit to `crypto@a16z.com` + warm intro via portfolio |
| Paradigm | Protocol infrastructure | Research their portfolio, find connection |
| Coinbase Ventures | Base ecosystem, AgentKit integrations | Direct contact via AgentKit Accelerator |
| Multicoin Capital | Solana/EVM infrastructure | Submit at `investments@multicoin.capital` |
| Robot Ventures | AI × crypto specific | Submit at their website |
| Spartan Group | Asia DeFi + AI | Singapore presence, relevant for MAS angle |
| Hashed | Korean + pan-Asia web3 | Singapore / Asia entry angle |

**Tier 2 — Enterprise SaaS funds with crypto exposure:**

| Fund | Focus |
|---|---|
| Bessemer Venture Partners | Enterprise SaaS, fintech |
| Greenoaks | Fintech infrastructure |
| Tiger Global | Growth-stage, but monitors early |

### Outreach Strategy

**Week 29:**
- [ ] Draft personalized 5-sentence cold emails for each Tier 1 fund (NOT a generic template)
- [ ] Send LinkedIn connection requests to relevant partners (warm up before cold email)
- [ ] Identify 5 mutual connections for warm intros (use Crunchbase + LinkedIn)
- [ ] Submit to Coinbase Ventures Accelerator (if accepting applications)

**Week 30:**
- [ ] Send first wave of outreach (Tier 1, 7 funds)
- [ ] Follow up on any ETHGlobal / conference connections made in Phase 2
- [ ] Aim: 5 investor meetings scheduled for the weeks following Phase 5

### Investor Meeting Prep

**For each meeting, prepare:**
- [ ] 10-minute demo: live dashboard showing a real agent's audit trail on Base mainnet
- [ ] Know your metrics cold: agents, MRR, ARR run-rate, CAC, ACV, churn
- [ ] Know the competition answers cold (see investor-materials.md)
- [ ] Have a 3-minute "Why Bouclier, Why Now, Why Me" story ready
- [ ] Follow-up template: personalized email within 24h of meeting with data room link

---

## Key Metrics Dashboard (at end of Phase 5)

Track these weekly. They are what investors will ask about:

| Metric | Target (End Phase 5) | Current |
|---|---|---|
| Mainnet agents active | 50+ | — |
| Monthly Recurring Revenue | $3,000 | — |
| MRR growth (MoM) | ≥ 25% | — |
| Protocol transactions (total) | ≥ 5,000 | — |
| Total USD volume monitored | ≥ $500,000 | — |
| Developer integrations (npm downloads) | ≥ 500/week | — |
| GitHub stars | ≥ 200 | — |
| Discord members | ≥ 500 | — |
| Enterprise pilots | 3 | — |
| Investor meetings held | ≥ 5 | — |

---

## Post-Phase 5: Seed Close → Series A Path

If seed round closes successfully:

**18-month plan (post-seed):**
- Month 1–3: Hire 2 engineers (smart contracts + backend)
- Month 3–6: Build enterprise features (SOC2 certification, SSO, custom SLA)
- Month 6–9: $15k MRR (20 paying customers)
- Month 9–12: First Series A preparation
- Month 12–18: $50k MRR target, Series A at $40–60M valuation

**Series A criteria (for reference):**
- $50k MRR ($600k ARR)
- ≥ 5 enterprise customers on annual contracts
- Protocol processing ≥ $10M USD/month
- Team: 8–10 people
- Raise: $8–12M at $40–60M pre-money

---

## Phase 5 Complete When

- [ ] 50+ active agents on Base mainnet (verified via subgraph)
- [ ] $3,000 MRR (Stripe dashboard screenshot)
- [ ] Seed deck presented to and reviewed by ≥ 3 advisors
- [ ] Data room fully assembled (all items above checked off)
- [ ] ≥ 5 investor meetings scheduled or held
- [ ] At least 1 term sheet received, OR clear investor signal on timing

---

*Last Updated: —*  
*Phase Status: ⬜ Not Started*

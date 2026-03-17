# Phase 4: Enterprise Pilot

> **Weeks 21–24 · Goal:** Contracts deployed to Base mainnet; SaaS platform live; MAS compliance report template validated; 3 enterprise pilot agreements signed; first recurring revenue ($1,000+ MRR).
>
> **Success Criterion:** 3 paying enterprise customers using Bouclier on mainnet, receiving compliance reports, and renewing monthly subscriptions. $1,000 MRR achieved.

---

## Progress Tracker

| Milestone | Status | Completed |
|---|---|---|
| Base mainnet deployment script | ✅ Complete | Session 10 — `DeployMainnet.s.sol` |
| Ethereum mainnet deployment script | ✅ Complete | Session 10 — `DeployRegistryOnly.s.sol` |
| Arbitrum One deployment | ⬜ Not Started | — |
| SaaS platform (FastAPI backend) | ✅ Complete | Session 10 — 14/14 tests |
| MAS compliance template validated | ✅ Complete | Session 10 — FAA-N16 JSON+CSV |
| MiCA compliance template | ✅ Complete | Session 10 — Article 38 JSON+CSV |
| Base mainnet deployment (execute) | ⬜ Not Started | Needs ETH + multisig |
| Ethereum mainnet deployment (execute) | ⬜ Not Started | Needs ETH |
| Stripe billing integration | ⬜ Not Started | Needs Stripe account |
| SaaS platform deployed to production | ⬜ Not Started | — |
| Pilot #1 signed | ⬜ Not Started | — |
| Pilot #2 signed | ⬜ Not Started | — |
| Pilot #3 signed | ⬜ Not Started | — |
| $1,000 MRR achieved | ⬜ Not Started | — |

---

## Week 21: Mainnet Deployments

### Pre-Deployment Checklist

Before deploying to any mainnet, ALL of the following must be true:

- [ ] Phase 3 complete (all security audits passed, zero critical/high findings outstanding)
- [ ] All Foundry unit + integration tests passing
- [ ] Formal verification proofs generated
- [ ] Deployment multisig set up (2-of-3 Gnosis Safe)
- [ ] Ownership plan decided: deployer → multisig handoff immediately after deployment
- [ ] Emergency pause functionality tested on testnet

### Base Mainnet (Primary)

```bash
# Check wallet balance (need ~0.1 ETH for deployment gas)
cast balance $DEPLOYER_ADDRESS --rpc-url $BASE_MAINNET_RPC_URL --ether

# Dry run simulation first
forge script script/Deploy.s.sol:DeployAll \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --simulate

# Real deployment (requires explicit confirmation)
forge script script/Deploy.s.sol:DeployAll \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  --slow   # --slow sends txs sequentially, safer for mainnet
```

**Gas estimates (from test runs):**
| Contract | Gas (deploy) | Cost at 0.1 gwei Base |
|---|---|---|
| AgentRegistry | ~2,800,000 | ~$0.28 |
| PermissionVault | ~4,200,000 | ~$0.42 |
| SpendTracker | ~2,100,000 | ~$0.21 |
| AuditLogger | ~1,800,000 | ~$0.18 |
| RevocationRegistry | ~1,500,000 | ~$0.15 |
| **Total** | ~12,400,000 | **~$1.24** |

**Post-deployment actions:**
- [ ] Transfer ownership to 2-of-3 multisig
- [ ] Set `GUARDIAN_ROLE` on multisig
- [ ] Verify all contracts on Basescan (Sourcify + Etherscan)
- [ ] Record contract addresses in `.env.mainnet` and in `architecture/system-overview.md`
- [ ] Deploy subgraph against Base mainnet contracts

### Arbitrum One

```bash
forge script script/Deploy.s.sol:DeployAll \
  --rpc-url $ARBITRUM_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY
```

**Note:** Arbitrum deployment is secondary. Start with Base only; Arbitrum adds cross-chain reach for enterprise customers who prefer it.

### Ethereum Mainnet (Identity Anchor Only)

Deploy ONLY `AgentRegistry` on Ethereum mainnet. This provides an eternal identity anchor for DIDs that resolves on the most battle-tested chain.

```bash
forge script script/DeployRegistry.s.sol:DeployRegistryOnly \
  --rpc-url $ETH_MAINNET_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify
```

---

## Week 22: SaaS Platform

### Pricing Model

Three tiers, billed monthly (annual discount: 20%):

| Tier | Price/mo | Agents | API Calls/mo | Compliance Reports |
|---|---|---|---|---|
| **Starter** | $299 | up to 5 | 100,000 | Self-serve |
| **Growth** | $999 | up to 25 | 1,000,000 | Automatic monthly |
| **Enterprise** | $2,499+ | Unlimited | Unlimited | Custom cadence + SLA |

**On-chain revenue (gas fees):** Each `register()` and `grantPermission()` call collects a small protocol fee. Initially 0 (waived to grow adoption) — turn on at Month 6.

### Platform Stack

**Backend:** FastAPI (from [architecture/infrastructure/api.md](../architecture/infrastructure/api.md))

```bash
cd api
pip install fastapi uvicorn[standard] sqlalchemy alembic stripe

# Start
uvicorn app.main:app --reload

# Production
docker build -t bouclier-api .
docker push ghcr.io/bouclier/api:latest
```

**Payment Infrastructure:**
- [ ] Stripe account set up (business verified)
- [ ] Stripe subscription products created (Starter $299, Growth $999, Enterprise custom)
- [ ] Webhook handler for `invoice.payment_succeeded`, `customer.subscription.deleted`
- [ ] In-app billing portal (Stripe Customer Portal)

### Tenant Isolation:
- [x] Each customer gets an `organizationId` UUID
- [x] All API queries (audit events, spend, agents) scoped to `organizationId`
- [x] `organizationId` maps to a list of `agentId`s the org has registered

**API Key Management:**
- [x] Customers get an `sk_live_*` API key on signup
- [x] Key hashed (bcrypt) before storage in PostgreSQL — never store plaintext
- [ ] Key rotation UI in dashboard
- [ ] Rate limiting: Starter 100 rps, Growth 1000 rps, Enterprise 10,000 rps

### Dashboard for Enterprise

Additional features beyond Phase 1 MVP:

- [ ] Compliance report generation (PDF via WeasyPrint or Puppeteer)
- [ ] Webhook configuration UI (set endpoints for `permission.violation`, `spend.cap_warning`)
- [ ] Team members: invite with role (Admin, Viewer, Auditor)
- [ ] Audit trail export: CSV, JSON (for SIEM integration)
- [ ] Spend analytics: stacked bar chart by token, by agent, by protocol

---

## Week 23: Compliance Templates

### MAS (Monetary Authority of Singapore)

The Monetary Authority of Singapore has issued guidelines on AI agent governance (MAS Notice FAA-N16). Bouclier's audit trail directly maps to their reporting requirements.

**MAS Report Template fields:**

| MAS Requirement | Bouclier Field | Contract |
|---|---|---|
| Agent identification | `agentId`, `did`, `model` | AgentRegistry |
| Authorization scope | `allowedProtocols`, `perTxSpendCapUSD`, `dailySpendCapUSD` | PermissionVault |
| Action log with timestamps | `eventId`, `timestamp`, `target`, `selector` | AuditLogger |
| Spend records | `usdAmount`, `tokenAddress`, `cumulativeUSD` | SpendTracker |
| Revocation events | `revokedAt`, `reason`, `revokedBy` | RevocationRegistry |
| Reinstatement evidence | `reinstatedAt`, `reinstatement_notes` | RevocationRegistry |

**Generate MAS Report:**
```bash
# Via API
POST /v1/compliance/report
{
  "organizationId": "...",
  "reportType": "MAS",
  "dateRange": { "from": "2025-01-01", "to": "2025-01-31" },
  "format": "pdf"
}
# Returns a signed PDF conforming to MAS FAA-N16 format
```

### MiCA (EU Markets in Crypto-Assets)

MiCA Article 38 requires AI systems used for crypto-asset services to maintain audit logs. Bouclier's IPFS-backed audit trail is a direct compliance solution.

**MiCA Report Template includes:**
- [ ] Agent DID and registration timestamp
- [ ] All permission changes (grants + revocations) with timestamps
- [ ] All transactions attempted (approved + rejected) with USD values
- [ ] Total spend by asset class
- [ ] Any compliance violations (exceeded caps, blocked protocols)
- [ ] Cryptographic integrity proof (IPFS CID chain)

**Legal Review:**
- [ ] Have a Singapore-licensed legal firm review the MAS report template before offering it as compliance tooling
- [ ] Have an EU-licensed attorney review the MiCA template
- [ ] Add legal disclaimers: Bouclier provides audit trails but does not constitute legal advice

### Pilot Onboarding Process

For each enterprise pilot:

1. **Discovery call (30 min):** Understand their agent use case, current compliance burden
2. **Technical kickoff (1 hour):** Walk through integration, answer engineering questions
3. **Integration support (1 week):** Dedicated Slack channel, daily check-ins
4. **First compliance report review (1 hour):** Verify their compliance team accepts the format
5. **Contract signing:** Standard 12-month SaaS agreement (get a lawyer to draft this)
6. **Go-live:** Agent actively monitored on Bouclier mainnet

---

## Week 24: Sales & Pipeline

### Target Customer Profiles (ICP)

**Primary ICP:** Fintech companies using LLM agents to execute DeFi transactions or financial workflows on behalf of clients. Regulatory pressure (MAS, MiCA) makes compliance tooling mandatory.

**Secondary ICP:** Crypto-native protocols deploying autonomous agents (e.g., treasury management bots, liquidity managers) who need kill switches and audit trails for DAO governance.

### Outreach Channels

- [ ] LinkedIn: "Head of Compliance", "CTO", "Director of Engineering" at fintech companies with Singapore/EU presence
- [ ] Conferences: TOKEN2049 Singapore, ETH CC Brussels, Permissionless — attend with demo
- [ ] Intro via VCs who have portfolio companies using DeFi agents (warm leads)
- [ ] Cold email: personalized, reference their specific AI agent news/blog posts

### Pilot Pricing

For the 3 Phase 4 pilots, offer:
- **6 months free** on Enterprise tier
- In exchange: case study rights, reference customer testimonial, co-marketing

The $1,000+ MRR in Phase 4 comes from Starter/Growth tier signups (not pilots), who found Bouclier via ETHGlobal exposure.

### Legal Prerequisites

- [ ] Form legal entity (Singapore Pte Ltd recommended for MAS proximity; or Delaware C-Corp for US investors)
- [ ] SaaS subscription agreement (lawyer-drafted)
- [ ] Data Processing Agreement (DPA) for GDPR/PDPA compliance
- [ ] Privacy Policy + Terms of Service for docs site

---

## Phase 4 Complete When

- [ ] All contracts live on Base mainnet (addresses recorded in architecture/system-overview.md)
- [ ] Basescan shows verified source + audit report link
- [ ] SaaS platform accessible at production domain (e.g., `app.bouclier.xyz`)
- [ ] Stripe billing working (test a real $299/mo subscription)
- [ ] MAS compliance report generated and reviewed by a legal professional
- [ ] 3 enterprise pilot agreements signed (company names + MRR TBD)
- [ ] $1,000 MRR achieved (screenshot of Stripe dashboard as evidence)
- [ ] Legal entity formed, SaaS agreement in place

---

*Last Updated: Session 10*  
*Phase Status: 🟡 In Progress (25%)*

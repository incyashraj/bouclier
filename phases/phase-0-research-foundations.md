# Phase 0: Research & Foundations

> **Weeks 1–3 · Goal:** Development environment fully configured, all relevant EIPs/standards studied with gap analysis complete, toy contract running on local anvil, CI/CD pipeline live.
>
> **Success Criterion:** `forge test` passes on a basic `BasicPermissionVault.sol`, Base Sepolia RPC is accessible from the dev machine, and a GitHub Action runs on every push.

---

## Progress Tracker

| Milestone | Status | Completed |
|---|---|---|
| Dev environment setup | ✅ Complete | Session 2 |
| EIP/standard study + gap analysis | ✅ Complete | Session 3 |
| Full contract implementation (advanced beyond toy) | ✅ Complete | Session 2 |
| CI/CD pipeline | ✅ Complete | Session 2 |

### Phase 0 Summary — What Was Actually Built

> Phase 0 went significantly further than planned. Instead of a toy `BasicPermissionVault.sol`, all 5 production-quality contracts were implemented, tested (76/76 unit tests), and the full CI pipeline was live by the end of Session 2.

| Deliverable | Status | Notes |
|---|---|---|
| Foundry 1.5.1 + Bun 1.3.10 + Node v22.18.0 + Python 3.12 | ✅ | All installed |
| Monorepo structure | ✅ | `contracts/`, `packages/sdk/`, `packages/dashboard/` |
| `IBouclier.sol` — all shared types + interfaces | ✅ | 6 structs, 2 enums |
| `RevocationRegistry.sol` — 15 unit tests | ✅ | REVOKER/GUARDIAN roles, 24h timelock |
| `AgentRegistry.sol` — 12 unit tests | ✅ | DID `did:ethr:base:0x…`, hierarchy |
| `AuditLogger.sol` — 10 unit tests | ✅ | IPFS CID anchoring, ring buffer |
| `SpendTracker.sol` — 14 unit tests | ✅ | Chainlink oracle, sliding window |
| `PermissionVault.sol` — 21 unit tests | ✅ | ERC-7579 IValidator, EIP-712 |
| `forge build` clean (49 files, exit 0) | ✅ | |
| **76/76 unit tests pass** | ✅ | |
| Deploy script `contracts/script/Deploy.s.sol` | ✅ | |
| GitHub Actions CI `.github/workflows/test.yml` | ✅ | forge + Slither + fmt |
| TypeScript SDK `@bouclier/sdk` v0.1.0 | ✅ | viem v2, tsc --noEmit clean |
| Standards gap analysis docs (`docs/standards/`) | ✅ | ERC-7579, ERC-4337, DID |
| Fork integration tests | ✅ | 4 scenarios written, pending live RPC |
| Base Sepolia RPC + IPFS config | ⬜ | Phase 1 item |

---

## Week 1: Development Environment

### 1.1 System Setup

```bash
# Install Foundry (Solidity toolchain)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify
forge --version   # forge 0.2.0 (...)
cast  --version
anvil --version

# Install Bun (TypeScript/JS runtime + package manager)
curl -fsSL https://bun.sh/install | bash
bun --version     # ≥1.1.0

# Install Node 20 (for tools that need it)
brew install node@20
node --version    # v20.x.x

# Python 3.12 (for Python SDK + Certora)
brew install python@3.12
python3.12 --version

# Install Certora Prover
pip3 install certora-cli
certoraRun --version
```

### 1.2 Repository Structure

```bash
# Create the monorepo
mkdir -p Bouclier && cd Bouclier
git init

# Contracts
mkdir -p contracts/src
mkdir -p contracts/test/unit
mkdir -p contracts/test/integration
mkdir -p contracts/test/invariant
mkdir -p contracts/test/echidna
mkdir -p contracts/test/helpers
mkdir -p contracts/script
mkdir -p contracts/specs   # Certora .spec files

# TypeScript SDK
mkdir -p packages/sdk/src/__tests__
mkdir -p packages/sdk/adapters

# Python SDK
mkdir -p python-sdk/bouclier_sdk
mkdir -p python-sdk/tests

# Subgraph
mkdir -p subgraph/src
mkdir -p subgraph/abis

# Backend API
mkdir -p api/app/routes
mkdir -p api/app/models
mkdir -p api/tests

# Frontend dashboard
mkdir -p dashboard/app
mkdir -p dashboard/components

# Documentation
mkdir -p docs

# CI/CD
mkdir -p .github/workflows
```

### 1.3 Foundry Project Initialization

```bash
cd contracts
forge init --no-git       # --no-git since we're in a monorepo git root

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install eth-infinitism/account-abstraction --no-commit  # ERC-4337 interfaces
forge install erc7579/erc7579-ref-implementation --no-commit   # ERC-7579 interfaces
```

**`contracts/foundry.toml`** (from testing-strategy.md — copy exactly)

### 1.4 Environment Variables

```bash
# Create .env (add to .gitignore immediately)
cat > .env << 'EOF'
# RPC Endpoints
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_MAINNET_RPC_URL=https://mainnet.base.org
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc

# API Keys
BASESCAN_API_KEY=
ETHERSCAN_API_KEY=

# Wallet (test wallet only — never mainnet privkey here)
DEPLOYER_PRIVATE_KEY=

# IPFS
PINATA_API_KEY=
PINATA_SECRET_KEY=

# The Graph
GRAPH_NODE_URL=https://api.studio.thegraph.com/deploy/
SUBGRAPH_NAME=bouclier-base-sepolia
EOF

# Guard it
echo ".env" >> .gitignore
echo ".env.*" >> .gitignore
```

### 1.5 Get Testnet ETH and USDC

- Visit `https://www.coinbase.com/faucets/base-ethereum-goerli-faucet` → get Base Sepolia ETH
- Bridge USDC: `https://bridge.base.org` → switch to Sepolia
- Verify Chainlink feeds work: [Base Sepolia ETH/USD](https://sepolia.basescan.org/address/0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1)

---

## Week 2: Standards Research + Gap Analysis

### 2.1 Standards to Study

For each standard, read the EIP, identify which Bouclier contracts reference it, and document any edge cases or gaps.

| Standard | Read | Applied To | Gap Analysis Done |
|---|---|---|---|
| [ERC-4337: Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337) | ⬜ | PermissionVault (`validateUserOp`) | ⬜ |
| [ERC-7579: Modular Smart Accounts](https://eips.ethereum.org/EIPS/eip-7579) | ⬜ | PermissionVault (IValidator interface) | ⬜ |
| [EIP-7702: EOA Extension](https://eips.ethereum.org/EIPS/eip-7702) | ⬜ | PermissionVault (future EOA support) | ⬜ |
| [EIP-712: Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712) | ⬜ | All contracts (signatures) | ⬜ |
| [W3C DID Core](https://www.w3.org/TR/did-core/) | ⬜ | AgentRegistry (DID generation) | ⬜ |
| [did:ethr Method](https://github.com/decentralized-identity/ethr-did-resolver) | ⬜ | AgentRegistry (DID format) | ⬜ |
| [W3C Verifiable Credentials](https://www.w3.org/TR/vc-data-model/) | ⬜ | AuditLogger (compliance records) | ⬜ |

### 2.2 Gap Analysis Template

For each standard, answer:
1. Which function in which contract implements this?
2. What assumptions does our implementation make?
3. What edge cases exist that we must handle?
4. What does the standard say about upgradeability? How does our proxy strategy interact?

### 2.3 Key Research Questions to Answer

- [ ] **ERC-4337:** What is the exact `PackedUserOperation` struct layout in v0.7? (It changed from v0.6)
- [ ] **ERC-7579:** What is the `IValidator.validateUserOp` return type exactly? Does it differ from ERC-4337's?
- [ ] **EIP-7702:** Which chain primitives does it require? Is it available on Base Sepolia yet?
- [ ] **did:ethr:** What is the correct chain ID identifier for `base`? Is it `base`, `base:mainnet`, or the numeric chain ID?
- [ ] **Chainlink:** Confirm decimal precision for each feed on Base mainnet vs Sepolia (some feeds return 8 decimals, some 18)

---

## Week 3: Toy Contract + CI/CD

### 3.1 Toy Contract Implementation

Build a simplified `BasicPermissionVault.sol` that implements ONLY the core validation path:
- No spend tracking
- No IPFS audit logs
- Only: is the agent registered? is the protocol allowed? is the scope active?

This exists purely to validate that the Foundry workflow, ERC-7579 interfaces, and UserOp flow are working correctly before building the full contracts.

```bash
# Create file
touch contracts/src/BasicPermissionVault.sol

# Run initial tests
forge test --match-contract "BasicPermissionVault" -vvvv

# Expected output: at least 3 test cases passing
```

**Acceptance criteria for toy contract:**
- [ ] `forge build` compiles with 0 errors
- [ ] `forge test` runs 5+ tests with all passing
- [ ] Test includes a fork test against Base Sepolia
- [ ] Gas usage of `validateUserOp` is < 200,000 gas (budget to optimize later)

### 3.2 CI/CD Pipeline

**`.github/workflows/test.yml`** — copy from [testing-strategy.md](../testing/testing-strategy.md#ci-pipeline). Must include:
- [ ] `forge test` on unit tests
- [ ] `forge test --fork-url` on integration tests (uses GitHub secret `BASE_MAINNET_RPC_URL`)
- [ ] `forge coverage` with minimum thresholds
- [ ] Slither security scan

**`.github/workflows/deploy.yml`** — deployment workflow (runs on git tag):
- [ ] Deploys to Base Sepolia on push to `develop` branch
- [ ] Deploys to Base mainnet on release tag `v*.*.*`
- [ ] Requires 2 manual approvals for mainnet

### 3.3 Verification Checklist

Run these commands and capture the output as evidence that Phase 0 is complete:

```bash
# 1. All tools installed
forge --version && bun --version && python3.12 --version

# 2. Tests pass
cd contracts && forge test --match-contract "BasicPermissionVault" -vvv

# 3. RPC connectivity
cast block latest --rpc-url $BASE_SEPOLIA_RPC_URL | head -5

# 4. Chainlink oracle readable (confirms ABI + address correct)
cast call 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1 \
  "latestRoundData()(uint80,int256,uint256,uint256,uint80)" \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# 5. CI passes — push a commit and confirm GitHub Action ✅
```

---

## Decisions to Make in Phase 0

| Decision | Options | Notes |
|---|---|---|
| Proxy pattern | UUPS vs Transparent vs no proxy | Lean toward UUPS (cheaper upgrades), but immutable contracts are simpler |
| ERC-7579 entry point version | v0.6 vs v0.7 | v0.7 uses `PackedUserOperation` — check which bundlers support it |
| DID method chain identifier | `base` vs `eip155:8453` | Check `did:ethr` resolver registry for Base support |
| IPFS pinning service | Pinata vs Web3.Storage vs Infura IPFS | Pinata has better uptime SLA |

---

## Phase 0 Complete When

- [ ] `forge test` has ≥ 5 passing tests on BasicPermissionVault
- [ ] Base Sepolia RPC accessible, Chainlink oracle query returns a price
- [ ] GitHub Action passes (green checkmark) on a push
- [ ] All 7 standards studied, gap analysis documented (even brief notes)
- [ ] All proxy/version decisions above are made and documented

---

*Last Updated: —*  
*Phase Status: ⬜ Not Started*

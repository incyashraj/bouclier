# Bouclier — Investor Demo Guide

## Real-Time Testing on Base Sepolia

### Prerequisites

- **Wallet**: MetaMask (or any WalletConnect wallet) with Base Sepolia network
- **Gas**: Free Base Sepolia ETH from https://www.alchemy.com/faucets/base-sepolia
- **Foundry**: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- **Dashboard**: Running locally (`cd dashboard && npm run dev`) or deployed

---

## Pre-Demo Setup (One-Time)

### 1. Register an AI Agent via CLI

```bash
export PRIVATE_KEY=0x_YOUR_PRIVATE_KEY_HERE

# Register agent — use a unique wallet address per agent
cast send 0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb \
  "register(address,string,bytes32,string)" \
  0x1111000000000000000000000000000000000001 \
  "gpt-4-turbo" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  "" \
  --rpc-url https://base-sepolia.g.alchemy.com/v2/YOUR_KEY \
  --private-key $PRIVATE_KEY
```

### 2. Get Your Agent ID

```bash
cast keccak "did:bouclier:demo-agent-001"
# Output: 0x... (save this bytes32 hash)
```

### 3. Verify Registration

```bash
cast call 0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb \
  "resolve(bytes32)" YOUR_AGENT_ID \
  --rpc-url https://sepolia.base.org
```

---

## Demo Recording Script (5-8 minutes)

### Scene 1: Landing Page (30s)

1. Open `http://localhost:3000`
2. Briefly scroll the landing page — point out the "Why Bouclier?" comparison table
3. Click **"+ Launch App"** in the top navigation

> **Say**: "Bouclier is the trust layer for AI agents. Every agent action is bounded on-chain — not by the AI, but by verifiable smart contracts."

### Scene 2: Connect Wallet (30s)

1. Click **Connect Wallet** (RainbowKit modal)
2. Choose MetaMask → approve connection
3. Ensure you're on **Base Sepolia** (switch if needed)

> **Say**: "We're connecting to Base Sepolia testnet where our 5 verified smart contracts are deployed."

### Scene 3: Agent Control Plane (45s)

1. You should see your registered agent(s) with:
   - Green **"Active"** status badge
   - DID: `did:bouclier:demo-agent-001`
   - Model: `gpt-4-turbo`
2. Point out this is a **live on-chain read** — no backend database

> **Say**: "Every AI agent has a deterministic on-chain identity. Enterprises see all agents in real-time — registered, active, or revoked."

### Scene 4: Grant Permission Scope (90s)

1. Click **"+ New Agent Policy"**
2. **Step 1**: Paste your agent hash ID
3. **Step 2**: Set:
   - Daily Spend Limit: **$1,000**
   - Per-Transaction Cap: **$100**
   - Leave "Allow Universal" **unchecked**
4. **Step 3**: Click **"Generate Policy Signature"**
5. MetaMask pops up → **Sign the transaction**
6. Wait ~3 seconds for block confirmation
7. See green **"Policy Active"** confirmation with tx hash

> **Say**: "In 15 seconds, we just set deterministic spending boundaries for this agent — $1,000/day, $100/tx. Enforced by the blockchain, not by the AI."

### Scene 5: Agent Telemetry & Audit Feed (60s)

1. Navigate to the agent detail page
2. Walk through each section:
   - **Agent Telemetry**: Model hash, 24h rolling spend ($0 for new agent), total events
   - **Active Protocol Bounds**: Shows your scope — $1K/day, $100/tx, valid dates
   - **Cryptographic Audit Feed**: Every action the agent attempted (green = approved, red = blocked)

> **Say**: "Full telemetry — every dollar spent, every action taken, every denial. All immutable on-chain. This is compliance officers' dream."

### Scene 6: Emergency Revoke — Kill Switch (45s)

1. Click the red **"Revoke Entire Scope"** button
2. MetaMask pops up → **Sign**
3. Status changes to **"Revoked"** (red badge)
4. The agent CANNOT execute any further transactions

> **Say**: "Instant kill switch — 129,000 gas, about 4 milliseconds. If an AI agent goes rogue, one click stops everything."

### Scene 7: Verified Contracts on Basescan (30s)

Open in browser tabs:
- AgentRegistry: `https://sepolia.basescan.org/address/0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb#code`
- PermissionVault: `https://sepolia.basescan.org/address/0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7#code`

> **Say**: "All contracts verified and open-source. 140+ tests, formal verification with Certora Prover — zero violations found."

---

## Pre-Recording Checklist

- [ ] MetaMask on Base Sepolia with ETH balance
- [ ] Agent registered (run `cast send` above)
- [ ] Agent hash ID in clipboard
- [ ] Dashboard running (`npm run dev`)
- [ ] Screen recorder ready (OBS / Loom / QuickTime)
- [ ] Browser at 100% zoom, no interfering extensions
- [ ] Sensitive tabs closed
- [ ] Base Sepolia RPC responding (test: `cast block-number --rpc-url https://sepolia.base.org`)

---

## Contract Addresses (Base Sepolia)

| Contract | Address |
|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` |

---

## Quick CLI Verification (Optional)

Run the full Foundry test suite to verify everything works:

```bash
cd contracts

# Run E2E test (register → scope → block → revoke)
forge test --match-contract E2EFullFlow -vvv

# Run full suite (140 tests)
forge test

# Gas report
forge test --gas-report
```

---

## Key Metrics for Investors

- **5 core smart contracts** deployed and verified on Base Sepolia
- **140+ Solidity tests** passing (including E2E flow)
- **15/15 Certora Prover rules** verified — zero violations
- **Emergency revoke**: 129,262 gas (~4ms at 30M gas/s)
- **Open source**: MIT License, GitHub at github.com/incyashraj/bouclier
- **TypeScript + Python SDKs** for integration
- **EIP-7702 & ERC-6900** adapter support

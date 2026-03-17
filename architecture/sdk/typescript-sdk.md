# TypeScript SDK — Architecture & API Reference

> **Package:** `@bouclier/sdk`  
> **Runtime:** Node.js 20 LTS, Bun  
> **Language:** TypeScript 5.x (strict mode)  
> **License:** MIT

---

## Overview

The Bouclier TypeScript SDK is the primary developer interface for the entire protocol. It abstracts all smart contract interactions, off-chain caching, and agent framework integrations into a clean, typed API.

**Design principle:** The SDK should feel like a first-class developer tool, not a thin contract wrapper. It handles:
- RPC connection management (with fallback)
- EIP-712 structured signing
- Redis-backed fast revocation checking
- Pre-flight permission validation before any UserOp is built
- Agent framework adapters (`wrapAgent()` pattern)

---

## Package Structure

```
packages/sdk/
├── src/
│   ├── index.ts              ← Main export (AgentShield class)
│   ├── core/
│   │   ├── AgentShield.ts    ← Main class
│   │   ├── contracts.ts      ← Contract ABI + address registry
│   │   ├── signing.ts        ← EIP-712 signing utilities
│   │   └── oracle.ts         ← Off-chain price estimation
│   ├── agent/
│   │   ├── wrapper.ts        ← wrapAgent() implementation
│   │   ├── session-keys.ts   ← Session key creation + management
│   │   └── preflight.ts      ← Pre-flight permission check
│   ├── types/
│   │   ├── PermissionScope.ts
│   │   ├── AuditEvent.ts
│   │   ├── AgentRecord.ts
│   │   └── index.ts
│   └── utils/
│       ├── did.ts             ← DID construction + parsing
│       └── errors.ts          ← Typed error classes
├── package.json
└── tsconfig.json
```

---

## Full API Reference

### Initialisation

```typescript
import { AgentShield } from '@bouclier/sdk';

const shield = new AgentShield({
  // Required
  chain: 'base',                        // 'base' | 'base-sepolia' | 'arbitrum' | 'ethereum'
  rpcUrl: process.env.RPC_URL!,
  apiKey: process.env.BOUCLIER_API_KEY!, // Issued by Bouclier dashboard

  // Optional
  contracts?: {                          // Override deployed contract addresses (for forks/testing)
    agentRegistry?: `0x${string}`;
    permissionVault?: `0x${string}`;
    spendTracker?: `0x${string}`;
    auditLogger?: `0x${string}`;
    revocationRegistry?: `0x${string}`;
  };
  redisUrl?: string;                     // Redis URL for fast revocation cache (recommended for prod)
  privateKey?: `0x${string}`;            // If provided, SDK can sign transactions directly
  walletClient?: WalletClient;           // viem WalletClient (alternative to privateKey)
  logLevel?: 'silent' | 'info' | 'debug'; // Default: 'info'
});
```

---

### Agent Registration

```typescript
/**
 * Registers a new AI agent with the Bouclier protocol.
 * Deploys a PermissionVault module for the agent and anchors identity on-chain.
 *
 * @returns agentId (bytes32 identifier) and DID
 */
async registerAgent(params: {
  agentAddress: `0x${string}`;  // The wallet address the agent will sign txs with
  model: string;                 // e.g. 'claude-sonnet-4-6', 'gpt-4o'
  modelHash?: `0x${string}`;    // sha256 of weights (optional — use 0x00 if not verifiable)
  metadata?: {
    description?: string;
    version?: string;
    tags?: string[];
  };
}): Promise<{
  agentId: `0x${string}`;       // bytes32 agent identifier
  did: string;                   // 'did:ethr:base:0x...'
  txHash: `0x${string}`;        // Registration transaction hash
  permissionVaultAddress: `0x${string}`;
}>

// Example
const agent = await shield.registerAgent({
  agentAddress: '0xAGENT_WALLET',
  model: 'claude-sonnet-4-6',
});
// { agentId: '0x...', did: 'did:ethr:base:0x...', txHash: '0x...', permissionVaultAddress: '0x...' }
```

---

### Permission Management

```typescript
/**
 * Grants a permission scope to a registered agent.
 * Constructs and signs an EIP-712 permission grant, broadcasts on-chain.
 */
async grantPermission(
  agentId: `0x${string}`,
  scope: PermissionScope
): Promise<{
  scopeId: `0x${string}`;  // Unique scope identifier
  txHash: `0x${string}`;
  active: boolean;
}>

// PermissionScope type
interface PermissionScope {
  // Protocol restrictions
  allowedProtocols: `0x${string}`[];    // Contract addresses (use addressOf('uniswap_v3') helper)
  allowedSelectors?: `0x${string}`[];   // Function selectors e.g. ['0x04e45aaf']

  // Spend limits
  dailySpendCapUSD: number;             // Maximum USD per rolling 24h window
  perTxSpendCapUSD: number;             // Maximum USD per single transaction

  // Asset restrictions
  allowedTokens: `0x${string}`[];       // ERC-20 addresses (use tokenAddressOf('USDC') helper)
  allowAnyToken?: boolean;              // Override: remove token restriction

  // Time restrictions
  validFrom?: Date;                     // Default: now
  validUntil?: Date;                    // Default: no expiry
  timeWindow?: {
    startHour: number;                  // UTC hour 0–23
    endHour: number;                    // UTC hour 0–23
    daysOfWeek: Array<'mon'|'tue'|'wed'|'thu'|'fri'|'sat'|'sun'>;
  };

  // Chain restriction
  chainId?: number;                     // Default: current chain
}

// Example
const scope = await shield.grantPermission(agent.agentId, {
  allowedProtocols: [
    shield.addressOf('uniswap_v3', 'router'),
    shield.addressOf('aave_v3', 'pool'),
  ],
  dailySpendCapUSD: 2000,
  perTxSpendCapUSD: 500,
  allowedTokens: [
    shield.tokenAddressOf('USDC'),
    shield.tokenAddressOf('ETH'),
    shield.tokenAddressOf('WBTC'),
  ],
  validUntil: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days
});
```

---

### Agent Revocation

```typescript
/**
 * Revokes an agent — sets Redis flag immediately, broadcasts on-chain in parallel.
 * After this call returns, the agent cannot execute any further actions.
 */
async revokeAgent(
  agentId: `0x${string}`,
  options: {
    reason: 'suspicious' | 'compromised' | 'expired' | 'policy' | 'requested' | 'regulatory' | 'other';
    customReason?: string;   // Human-readable detail (stored on-chain)
    immediate?: boolean;     // Default: true — set Redis flag first, then broadcast
  }
): Promise<{
  revokedAt: Date;
  txHash: `0x${string}`;
}>

// Example
await shield.revokeAgent(agent.agentId, {
  reason: 'suspicious',
  customReason: 'Agent made 50+ trades in 10 minutes, highly anomalous pattern',
});
```

---

### Agent Wrapping (Core Developer Feature)

```typescript
/**
 * Wraps an existing agent (any framework) so that every action it attempts
 * passes through Bouclier permission validation before execution.
 *
 * The developer does NOT need to change their agent's logic.
 * The wrapper intercepts at the transaction construction layer.
 */
wrapAgent<T extends BaseAgent>(
  agent: T,
  config: {
    agentId: `0x${string}`;
    enforceOnChain: boolean;   // true = check on-chain; false = SDK-only (testing mode)
    dryRun?: boolean;          // If true, simulate but never broadcast
    onViolation?: (violation: PermissionViolation) => void;  // Hook for alerts
  }
): WrappedAgent<T>

interface WrappedAgent<T> extends T {
  // All original agent methods preserved
  // Plus:
  getPermissionStatus(): Promise<PermissionScopeStatus>;
  getRemainingDailyCap(): Promise<number>;
  getAuditTrail(limit?: number): Promise<AuditEvent[]>;
}

// Example (LangChain agent)
import { createReactAgent } from 'langchain/agents';

const rawAgent = createReactAgent({ ... });

const protectedAgent = shield.wrapAgent(rawAgent, {
  agentId: agent.agentId,
  enforceOnChain: true,
  onViolation: (v) => {
    console.error(`Blocked: ${v.type} — attempted ${v.attemptedUSD} USD`);
    sendSlackAlert(v);
  },
});

// Now every action goes through Bouclier
await protectedAgent.invoke({ input: "Swap 300 USDC for ETH on Uniswap" });
```

---

### Pre-flight Check

```typescript
/**
 * Checks whether a specific action would be permitted, without executing it.
 * Use this for early validation before building a UserOp.
 */
async checkPermission(
  agentId: `0x${string}`,
  action: {
    target: `0x${string}`;     // Contract address to call
    selector: `0x${string}`;   // Function selector (4 bytes)
    estimatedValueUSD: number;  // Your estimate of USD value
    tokens?: `0x${string}`[];  // Tokens this action touches
  }
): Promise<{
  allowed: boolean;
  rejectReason?: string;       // If !allowed: one of the ViolationType constants
  remainingDailyCapUSD?: number;
  remainingDailyCapPercent?: number;
}>

// Example
const check = await shield.checkPermission(agent.agentId, {
  target: shield.addressOf('uniswap_v3', 'router'),
  selector: '0x04e45aaf',   // exactInputSingle
  estimatedValueUSD: 300,
  tokens: [shield.tokenAddressOf('USDC'), shield.tokenAddressOf('ETH')],
});

if (!check.allowed) {
  console.log(`Blocked: ${check.rejectReason}`); // e.g. "DAILY_CAP_EXCEEDED"
}
```

---

### Audit Trail

```typescript
/**
 * Gets the audit trail for an agent (reads from The Graph + Bouclier API)
 */
async getAuditTrail(
  agentId: `0x${string}`,
  options?: {
    from?: Date;
    to?: Date;
    limit?: number;        // Default 100, max 1000
    outcomeFilter?: 'success' | 'violation' | 'all'; // Default 'all'
    includeIpfsDetail?: boolean;  // Fetch full IPFS records (slower)
  }
): Promise<{
  events: AuditEvent[];
  total: number;
  hasMore: boolean;
}>

interface AuditEvent {
  eventId: `0x${string}`;
  agentId: `0x${string}`;
  userOpHash: `0x${string}`;
  txHash?: `0x${string}`;
  targetContract: `0x${string}`;
  functionSelector: `0x${string}`;
  functionName?: string;         // Resolved if ABI is known (Uniswap, Aave, etc.)
  valueUSD: number;
  outcome: 'success' | 'violation';
  violationType?: string;
  timestamp: Date;
  blockNumber: bigint;
  permissionScopeId: `0x${string}`;
  ipfsDetails?: FullAuditRecord; // Only if includeIpfsDetail = true
}
```

---

### Spend Summary

```typescript
/**
 * Gets spending summary for an agent
 */
async getSpendSummary(
  agentId: `0x${string}`,
  options?: {
    granularity?: 'hourly' | 'daily' | 'weekly';  // Default 'daily'
    lookbackDays?: number;                         // Default 30
  }
): Promise<{
  rolling24hUSD: number;
  dailyCapUSD: number;
  percentageUsed: number;         // 0–100
  periodBreakdown: Array<{
    period: string;               // ISO date or hour string
    spentUSD: number;
    txCount: number;
    violations: number;
  }>;
}>
```

---

### Helper Utilities

```typescript
/**
 * Resolves known protocol names to contract addresses on the current chain
 * Prevents hardcoding addresses across teams
 */
addressOf(
  protocol: 'uniswap_v3' | 'uniswap_v2' | 'aave_v3' | 'aave_v2' | 'curve' | 'compound_v3' | ...,
  component?: 'router' | 'pool' | 'factory' | 'quoter' // default: main contract
): `0x${string}`

/**
 * Resolves known token symbols to addresses on the current chain
 */
tokenAddressOf(
  symbol: 'USDC' | 'USDT' | 'ETH' | 'WETH' | 'WBTC' | 'DAI' | 'cbETH' | ...
): `0x${string}`

/**
 * DID utilities
 */
did.fromAgentId(agentId: `0x${string}`): string
did.toAgentId(did: string): `0x${string}`
did.isValid(did: string): boolean
```

---

## Error Types

```typescript
// All Bouclier errors are typed and catchable

class BouclierError extends Error {
  code: BouclierErrorCode;
  agentId?: `0x${string}`;
}

enum BouclierErrorCode {
  AGENT_NOT_REGISTERED     = 'AGENT_NOT_REGISTERED',
  AGENT_REVOKED            = 'AGENT_REVOKED',
  NO_ACTIVE_SCOPE          = 'NO_ACTIVE_SCOPE',
  SCOPE_EXPIRED            = 'SCOPE_EXPIRED',
  PROTOCOL_NOT_ALLOWED     = 'PROTOCOL_NOT_ALLOWED',
  SELECTOR_NOT_ALLOWED     = 'SELECTOR_NOT_ALLOWED',
  SPEND_CAP_EXCEEDED       = 'SPEND_CAP_EXCEEDED',
  PER_TX_CAP_EXCEEDED      = 'PER_TX_CAP_EXCEEDED',
  TOKEN_NOT_ALLOWED        = 'TOKEN_NOT_ALLOWED',
  OUTSIDE_TIME_WINDOW      = 'OUTSIDE_TIME_WINDOW',
  ORACLE_STALE             = 'ORACLE_STALE',
  RPC_ERROR                = 'RPC_ERROR',
  SIGNATURE_INVALID        = 'SIGNATURE_INVALID',
}

// Usage
try {
  await protectedAgent.invoke({ input: "Swap 1000000 USDC for ETH" });
} catch (e) {
  if (e instanceof BouclierError && e.code === BouclierErrorCode.SPEND_CAP_EXCEEDED) {
    console.log('Blocked by spend cap');
  }
}
```

---

## Framework Integrations

### LangChain (`@bouclier/langchain`)

```typescript
import { BouclierCallbackHandler, BouclierToolWrapper } from '@bouclier/langchain';

// Option A: Callback handler (wraps all tools in an existing chain)
const agent = AgentExecutor.fromAgentAndTools({
  agent: myAgent,
  tools: myTools,
  callbacks: [new BouclierCallbackHandler({ shield, agentId })],
});

// Option B: Wrap individual tools
const protectedUniswapTool = BouclierToolWrapper.wrap(uniswapSwapTool, { shield, agentId });
```

### ELIZA (`@bouclier/eliza-plugin`)

```typescript
import { bouclierPlugin } from '@bouclier/eliza-plugin';

const character = {
  ...myCharacter,
  plugins: [
    bouclierPlugin({
      agentId: '0x...',
      apiKey: process.env.BOUCLIER_API_KEY,
      chain: 'base',
    }),
  ],
};
```

### Coinbase AgentKit (`@bouclier/agentkit`)

```typescript
import { withBouclier } from '@bouclier/agentkit';
import { AgentKit } from '@coinbase/agentkit';

const agentKit = AgentKit.from({ walletData: ... });
const protectedKit = withBouclier(agentKit, { shield, agentId });
```

---

## SDK Testing Guide

```typescript
// Use testnet mode for all tests
const shield = new AgentShield({
  chain: 'base-sepolia',
  rpcUrl: process.env.BASE_SEPOLIA_RPC,
  apiKey: 'test-key',
});

// Mock permission vault for pure unit tests
import { MockPermissionVault } from '@bouclier/sdk/test-utils';
const mockShield = AgentShield.withMock({
  permissionVault: new MockPermissionVault({
    agentId: '0xtestAgent',
    grantAll: true,  // All actions allowed
  }),
});
```

---

## Configuration Reference

```typescript
// Full configuration type
interface AgentShieldConfig {
  chain: 'base' | 'base-sepolia' | 'arbitrum' | 'arbitrum-sepolia' | 'ethereum' | 'localhost';
  rpcUrl: string;
  apiKey: string;
  
  // Contract addresses (auto-resolved from chain if not provided)
  contracts?: Partial<ContractAddresses>;
  
  // Wallet configuration (one of the following)
  privateKey?: `0x${string}`;
  walletClient?: WalletClient;
  
  // Performance
  redisUrl?: string;               // Enable fast revocation cache
  cacheRevocationTTL?: number;     // Seconds to cache revocation status (default: 30)
  
  // Monitoring
  logLevel?: 'silent' | 'error' | 'warn' | 'info' | 'debug';
  onViolation?: (v: PermissionViolation) => void;  // Global violation hook
  webhookUrl?: string;             // POST violations + revocations to this URL
  
  // Advanced
  maxRetries?: number;             // RPC retry count (default: 3)
  timeout?: number;                // RPC timeout ms (default: 10000)
  ipfsGateway?: string;            // IPFS gateway for fetching full audit records
}
```

---

*Last Updated: March 2026*

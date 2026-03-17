---
sidebar_position: 1
---

# TypeScript SDK

`@bouclier/sdk` is the primary TypeScript client for the Bouclier protocol. It wraps all 5 contracts using [viem v2](https://viem.sh).

```bash
npm install @bouclier/sdk viem
# or
bun add @bouclier/sdk viem
```

---

## Initialisation

```typescript
import { BouclierClient } from "@bouclier/sdk";
import { baseSepolia } from "viem/chains";

const client = new BouclierClient({
  chain: baseSepolia,
  rpcUrl: "https://base-sepolia.g.alchemy.com/v2/YOUR_KEY",
  contracts: {
    agentRegistry:       "0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb",
    revocationRegistry:  "0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa",
    permissionVault:     "0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7",
    spendTracker:        "0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1",
    auditLogger:         "0x42FDFC97CC5937E5c654dFE9494AA278A17D2735",
  },
  // optional — needed for write calls
  walletClient: myViemWalletClient,
});
```

---

## API Reference

### `registerAgent(config)`

Registers a new agent on `AgentRegistry`.

```typescript
const { agentId, txHash } = await client.registerAgent({
  agentWallet: "0x...",
  model: "gpt-4o",
  parentAgentId: "0x0000000000000000000000000000000000000000000000000000000000000000",
  metadataCID: "",
});
```

### `grantPermission(params)`

Grants a signed permission scope.

```typescript
const txHash = await client.grantPermission({
  agentId: "0x...",
  scope: {
    allowedProtocols: ["0xUniswapRouter"],
    allowedTokens:    ["0xUSDC"],
    allowedSelectors: ["0x414bf389"],
    perTxSpendCapUSD: parseUnits("100", 18),
    dailySpendCapUSD: parseUnits("500", 18),
    validFrom:  BigInt(Math.floor(Date.now() / 1000)),
    validUntil: BigInt(Math.floor(Date.now() / 1000) + 86400 * 30),
    allowAnyProtocol: false,
    allowAnyToken: false,
  },
});
```

### `checkPermission(agentId, action)`

Simulates `validateUserOp` off-chain. Zero gas cost.

```typescript
const result = await client.checkPermission(agentId, {
  target:            "0xUniswapRouter",
  selector:          "0x414bf389",
  tokenAddress:      "0xUSDC",
  estimatedValueUSD: parseUnits("50", 18),
});
// result: { allowed: boolean, reason?: string }
```

### `revokeAgent(agentId, notes?)`

Revokes an agent via `RevocationRegistry`.

```typescript
await client.revokeAgent(agentId, "Anomaly detected");
```

### `isRevoked(agentId)`

```typescript
const revoked = await client.isRevoked(agentId);
```

### `getActiveScope(agentId)`

```typescript
const scope = await client.getActiveScope(agentId);
```

### `getAgentId(agentWallet)`

Reverse lookup: wallet → agentId.

```typescript
const agentId = await client.getAgentId("0xAgentWallet");
```

### `getAuditTrail(agentId, options?)`

```typescript
const events = await client.getAuditTrail(agentId, { limit: 20, offset: 0 });
```

---

## Types

```typescript
import type { PermissionScope, AgentRecord, AuditEvent, CheckResult } from "@bouclier/sdk";
```

All types are exported from the package root with full TypeScript definitions.

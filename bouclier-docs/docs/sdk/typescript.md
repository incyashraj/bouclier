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
    agentRegistry:       "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
    revocationRegistry:  "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
    permissionVault:     "0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
    spendTracker:        "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
    auditLogger:         "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE",
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

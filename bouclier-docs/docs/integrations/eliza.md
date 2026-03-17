---
sidebar_position: 2
---

# ELIZA Plugin

`@bouclier/eliza-plugin` integrates Bouclier into [ELIZA / ElizaOS](https://github.com/elizaos/eliza) as a native plugin with a provider and evaluator.

```bash
npm install @bouclier/eliza-plugin @bouclier/sdk
```

---

## How It Works

The plugin registers two components:

| Component | Type | Role |
|---|---|---|
| `BouclierPermissionProvider` | Provider | Injects current permission state into every ELIZA context |
| `BouclierActionEvaluator` | Evaluator | Validates every proposed action before execution |

The evaluator returns `DENY` if:
- The agent is revoked
- The action target is not in the allowlist
- The estimated value exceeds the per-tx cap

---

## Setup

### 1. Add to your ELIZA character file

```json
{
  "name": "MyDeFiAgent",
  "plugins": ["@bouclier/eliza-plugin"],
  "settings": {
    "bouclier": {
      "rpcUrl": "https://base-sepolia.g.alchemy.com/v2/YOUR_KEY",
      "agentWallet": "0xYourAgentWallet",
      "contracts": {
        "agentRegistry":      "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
        "revocationRegistry": "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
        "permissionVault":    "0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
        "spendTracker":       "0x930Eb18B9962c30b388f900ba9AE62386191cD48",
        "auditLogger":        "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE"
      }
    }
  }
}
```

### 2. Programmatic setup

```typescript
import { createBouclierPlugin } from "@bouclier/eliza-plugin";
import { BouclierClient } from "@bouclier/sdk";

const bouclier = new BouclierClient({ /* config */ });
const agentId  = await bouclier.getAgentId(AGENT_WALLET);

const plugin = createBouclierPlugin(bouclier, agentId);

// Register with your ELIZA runtime
runtime.registerPlugin(plugin);
```

---

## Context Injection

The `BouclierPermissionProvider` adds the following to ELIZA's state on every turn:

```typescript
{
  bouclierPermissions: {
    agentId: "0x...",
    isRevoked: false,
    scope: {
      allowedProtocols: [...],
      dailySpendRemaining: "450.00",   // USD, formatted
      validUntil: "2026-04-17T...",
    }
  }
}
```

Your ELIZA character's system prompt can reference this state to self-constrain.

---

## Plugin Object

```typescript
import type { Plugin } from "@elizaos/core";

export const bouclierPlugin: Plugin = {
  name: "bouclier",
  description: "AI agent trust layer — enforce on-chain permissions on all ELIZA actions",
  actions:    [],
  providers:  [BouclierPermissionProvider],
  evaluators: [BouclierActionEvaluator],
};
```

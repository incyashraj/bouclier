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
        "agentRegistry":      "0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb",
        "revocationRegistry": "0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa",
        "permissionVault":    "0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7",
        "spendTracker":       "0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1",
        "auditLogger":        "0x42FDFC97CC5937E5c654dFE9494AA278A17D2735"
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

---
sidebar_position: 3
---

# Coinbase AgentKit Integration

`@bouclier/agentkit` wraps the [Coinbase AgentKit](https://docs.cdp.coinbase.com/agentkit/docs/welcome) `AgentKit` instance to enforce on-chain permission scopes on every wallet action.

```bash
npm install @bouclier/agentkit @bouclier/sdk
```

---

## How It Works

`BouclierAgentKitWrapper` proxies every method of the `AgentKit` instance. Before any action is executed:

1. `checkPermission` is called with the target contract and estimated value
2. If denied → throws `BouclierPermissionError` with violation reason
3. If allowed → the original `AgentKit` method is called normally

---

## Quickstart

```typescript
import { AgentKit } from "@coinbase/agentkit";
import { BouclierAgentKitWrapper } from "@bouclier/agentkit";
import { BouclierClient } from "@bouclier/sdk";

// 1. Set up Bouclier client
const bouclier = new BouclierClient({
  chain: baseSepolia,
  rpcUrl: process.env.BASE_SEPOLIA_RPC_URL!,
  contracts: { /* contract addresses */ },
});

const agentId = await bouclier.getAgentId(process.env.AGENT_WALLET!);

// 2. Create standard AgentKit instance
const kit = await AgentKit.configureWithWallet({
  wallet,
  cdpApiKeyName:        process.env.CDP_KEY_NAME!,
  cdpApiKeyPrivateKey:  process.env.CDP_KEY_PRIVATE!,
});

// 3. Wrap with Bouclier
const protectedKit = new BouclierAgentKitWrapper(kit, bouclier, agentId);

// 4. Use exactly like a normal AgentKit instance
// All actions are now permission-enforced
const tools = protectedKit.getTools();
```

---

## Intercepted Actions

| Action | Check Applied |
|---|---|
| `wallet.sendTransaction` | Protocol + selector + value check |
| `trade` / `buy` / `sell` | Token allowlist + spend cap check |
| `deploy` | Protocol allowlist check |
| `getBalance` / `getAddress` | Pass-through (read-only) |

---

## Error Handling

```typescript
import { BouclierPermissionError } from "@bouclier/agentkit";

try {
  await protectedKit.trade({ fromAsset: "ETH", toAsset: "USDC", amount: "1" });
} catch (err) {
  if (err instanceof BouclierPermissionError) {
    console.error("Blocked:", err.violationType, err.message);
    // violationType: "DAILY_CAP_EXCEEDED" | "PROTOCOL_NOT_ALLOWED" | "AGENT_REVOKED" | ...
  }
}
```

---

## API

### `new BouclierAgentKitWrapper(kit, client, agentId)`

| Param | Type | Description |
|---|---|---|
| `kit` | `AgentKit` | Configured Coinbase AgentKit instance |
| `client` | `BouclierClient` | Initialised Bouclier SDK client |
| `agentId` | `Hex` | The agent's on-chain ID |

### `getTools()`

Returns the full array of LangChain-compatible tools from the underlying `AgentKit`, each wrapped with Bouclier validation. Use this with a LangChain `AgentExecutor`.

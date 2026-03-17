---
sidebar_position: 2
---

# Quickstart

Integrate Bouclier into your AI agent in under 10 minutes.

## Prerequisites

- Node.js 22 LTS or Bun 1.3+
- A Base Sepolia RPC URL (free tier from [Alchemy](https://alchemy.com) or [QuickNode](https://quicknode.com))
- A wallet with a small amount of Base Sepolia ETH (for write calls)

---

## 1. Install the SDK

```bash
# npm
npm install @bouclier/sdk viem

# bun
bun add @bouclier/sdk viem
```

## 2. Initialise the client

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
});
```

## 3. Register an agent

```typescript
const AGENT_WALLET = "0xYourAgentWalletAddress";

const { agentId } = await client.registerAgent({
  agentWallet: AGENT_WALLET,
  model: "gpt-4o",
  metadataCID: "",          // optional IPFS CID for agent metadata
});

console.log("Agent DID:", `did:ethr:base:${AGENT_WALLET}`);
console.log("Agent ID:", agentId);
```

## 4. Grant a permission scope

```typescript
import { parseUnits } from "viem";

await client.grantPermission({
  agentId,
  scope: {
    allowedProtocols: ["0xUniswapV3RouterAddress"],
    allowedTokens:    ["0xUSDCAddress"],
    allowedSelectors: ["0x414bf389"],   // exactInputSingle
    perTxSpendCapUSD: parseUnits("100", 18),    // $100 per tx
    dailySpendCapUSD: parseUnits("500", 18),    // $500/day rolling
    validFrom: BigInt(Math.floor(Date.now() / 1000)),
    validUntil: BigInt(Math.floor(Date.now() / 1000) + 86400 * 30), // 30 days
    allowAnyProtocol: false,
    allowAnyToken:    false,
  },
});

console.log("Permission granted!");
```

## 5. Check permission and wrap your agent

```typescript
// Check before any action
const result = await client.checkPermission(agentId, {
  target:            "0xUniswapV3RouterAddress",
  selector:          "0x414bf389",
  tokenAddress:      "0xUSDCAddress",
  estimatedValueUSD: parseUnits("50", 18),
});

if (!result.allowed) {
  console.error("Action blocked:", result.reason);
}
```

## 6. Revoke instantly

```typescript
await client.revokeAgent(agentId, "Anomaly detected");
console.log("Agent revoked. All future actions will be blocked.");
```

---

## LangChain (2 lines)

```bash
npm install @bouclier/langchain
```

```typescript
import { BouclierCallbackHandler } from "@bouclier/langchain";

const executor = await AgentExecutor.fromAgentAndTools({
  agent, tools,
  callbacks: [new BouclierCallbackHandler(client, agentId)],
});
```

Any tool call by a revoked agent is intercepted before the LLM is even called.

---

## Python

```bash
pip install bouclier-sdk
```

```python
from bouclier import BouclierClient

client = BouclierClient(
    rpc_url="https://base-sepolia.g.alchemy.com/v2/YOUR_KEY",
    agent_registry="0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
    permission_vault="0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
    revocation_registry="0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
)

agent_id = client.get_agent_id("0xYourAgentWallet")
result = client.check_permission(agent_id, action)
```

---

## Next Steps

- [TypeScript SDK API reference →](./sdk/typescript)
- [Python SDK reference →](./sdk/python)
- [LangChain integration guide →](./integrations/langchain)
- [Contract architecture →](./contracts/overview)

---
sidebar_position: 1
---

# LangChain Integration

`@bouclier/langchain` provides a `BouclierCallbackHandler` that plugs into any LangChain `AgentExecutor` and enforces on-chain permission scopes before every tool call.

```bash
npm install @bouclier/langchain @bouclier/sdk viem
```

---

## How It Works

The `BouclierCallbackHandler` hooks into:

| LangChain Callback | Bouclier Action |
|---|---|
| `handleLLMStart` | Checks if agent is revoked — throws before any LLM call |
| `handleToolStart` | Calls `checkPermission(agentId, { target: toolName, ... })` — blocks tool if denied |
| `handleToolEnd` | Logs successful execution to audit trail |
| `handleToolError` | Logs blocked/errored action |
| `handleAgentAction` | Validates every action the agent decides to take |

---

## Quickstart

```typescript
import { BouclierClient } from "@bouclier/sdk";
import { BouclierCallbackHandler } from "@bouclier/langchain";
import { AgentExecutor, createOpenAIFunctionsAgent } from "langchain/agents";
import { ChatOpenAI } from "@langchain/openai";
import { baseSepolia } from "viem/chains";

// 1. Set up Bouclier client
const bouclier = new BouclierClient({
  chain: baseSepolia,
  rpcUrl: process.env.BASE_SEPOLIA_RPC_URL!,
  contracts: { /* contract addresses */ },
});

// 2. Get agent ID
const agentId = await bouclier.getAgentId(process.env.AGENT_WALLET!);

// 3. Attach callback handler to LangChain executor
const handler = new BouclierCallbackHandler(bouclier, agentId);

const executor = await AgentExecutor.fromAgentAndTools({
  agent: await createOpenAIFunctionsAgent({ llm, tools, prompt }),
  tools,
  callbacks: [handler],
  verbose: true,
});

// 4. Run — all tool calls are now enforced on-chain
const result = await executor.invoke({ input: "Swap 50 USDC for ETH on Uniswap" });
```

---

## Revoked Agent Behaviour

If the agent is revoked **before** the LLM is called, the handler throws immediately — no tokens are consumed:

```
BouclierPermissionError: Agent 0x... is revoked. All actions blocked.
```

If revoked **during** an agentic loop, the next `handleToolStart` will catch it.

---

## Custom Spend Estimation

By default, `BouclierCallbackHandler` estimates tool spend as `$0` when no token/value info is available. You can override this:

```typescript
const handler = new BouclierCallbackHandler(bouclier, agentId, {
  estimateToolValue: async (tool, input) => {
    // Parse input and return estimated USD value as bigint (18 decimals)
    if (tool.name === "swap_usdc") return parseUnits("50", 18);
    return 0n;
  },
});
```

---

## API

### `new BouclierCallbackHandler(client, agentId, options?)`

| Param | Type | Description |
|---|---|---|
| `client` | `BouclierClient` | Initialised SDK client |
| `agentId` | `Hex` | The agent's on-chain ID |
| `options.estimateToolValue` | `function` | Optional async function returning estimated USD value |
| `options.onViolation` | `function` | Optional callback when a permission violation is detected |

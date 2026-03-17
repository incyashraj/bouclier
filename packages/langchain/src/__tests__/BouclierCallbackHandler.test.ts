import { describe, it, expect, mock } from "bun:test";
import { BouclierCallbackHandler, BouclierPermissionError } from "../BouclierCallbackHandler.js";
import type { BouclierClient, PermissionScope } from "@bouclier/sdk";
import { parseUnits, zeroHash } from "viem";

// ── Fixtures ──────────────────────────────────────────────────────

const AGENT_ID = "0xaabb000000000000000000000000000000000000000000000000000000000000" as const;

const ACTIVE_SCOPE: PermissionScope = {
  agentId:           AGENT_ID,
  allowedProtocols:  [],
  allowedSelectors:  [],
  allowedTokens:     [],
  dailySpendCapUSD:  parseUnits("1000", 18),
  perTxSpendCapUSD:  parseUnits("100", 18),
  validFrom:         0n,
  validUntil:        9_999_999_999n,
  allowAnyProtocol:  false,
  allowAnyToken:     false,
  revoked:           false,
  grantHash:         zeroHash,
  windowStartHour:   0,
  windowEndHour:     23,
  windowDaysMask:    0,
  allowedChainId:    0n,
};

function makeClient(overrides: Partial<{
  isRevoked: boolean;
  scope: PermissionScope | null;
}>): BouclierClient {
  return {
    isRevoked: mock(() => Promise.resolve(overrides.isRevoked ?? false)),
    getActiveScope: mock(() =>
      overrides.scope === null
        ? Promise.reject(new Error("No scope"))
        : Promise.resolve(overrides.scope ?? ACTIVE_SCOPE)
    ),
  } as unknown as BouclierClient;
}

const DUMMY_SERIALIZED = { id: ["test"], lc: 1, type: "not_implemented" } as any;
const DUMMY_LLM_RESULT = { generations: [], llmOutput: {} } as any;

// ── Tests ─────────────────────────────────────────────────────────

describe("BouclierCallbackHandler.handleLLMStart", () => {
  it("allows LLM start for an active agent", async () => {
    const client = makeClient({});
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleLLMStart(DUMMY_SERIALIZED, ["Hello"], "run-1")
    ).resolves.toBeUndefined();
  });

  it("throws BouclierPermissionError when agent is revoked", async () => {
    const client = makeClient({ isRevoked: true });
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleLLMStart(DUMMY_SERIALIZED, ["Hello"], "run-2")
    ).rejects.toThrow(BouclierPermissionError);
  });
});

describe("BouclierCallbackHandler.handleToolStart", () => {
  it("allows tool execution for active agent with valid scope", async () => {
    const client = makeClient({});
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleToolStart(DUMMY_SERIALIZED, '{"query":"price of ETH"}', "run-3", undefined, undefined, undefined, "get_price")
    ).resolves.toBeUndefined();
  });

  it("blocks tool when agent is revoked", async () => {
    const client = makeClient({ isRevoked: true });
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleToolStart(DUMMY_SERIALIZED, "{}", "run-4", undefined, undefined, undefined, "uniswap_swap")
    ).rejects.toThrow(BouclierPermissionError);
  });

  it("blocks tool when no active scope exists", async () => {
    const client = makeClient({ scope: null });
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleToolStart(DUMMY_SERIALIZED, "{}", "run-5", undefined, undefined, undefined, "transfer_tokens")
    ).rejects.toThrow(BouclierPermissionError);
  });

  it("blocks tool when scope is revoked", async () => {
    const client = makeClient({ scope: { ...ACTIVE_SCOPE, revoked: true } });
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleToolStart(DUMMY_SERIALIZED, "{}", "run-6", undefined, undefined, undefined, "transfer_tokens")
    ).rejects.toThrow(BouclierPermissionError);
  });

  it("blocks tool when scope has expired", async () => {
    const expiredScope = { ...ACTIVE_SCOPE, validUntil: 1_000_000n }; // ancient timestamp
    const client = makeClient({ scope: expiredScope });
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    await expect(
      handler.handleToolStart(DUMMY_SERIALIZED, "{}", "run-7", undefined, undefined, undefined, "swap")
    ).rejects.toThrow(BouclierPermissionError);
  });

  it("calls onBlock hook and does NOT throw when hook returns false", async () => {
    const client = makeClient({ isRevoked: true });
    const onBlock = mock(() => false); // log-only
    const handler = new BouclierCallbackHandler(client, AGENT_ID, { onBlock });
    await expect(
      handler.handleToolStart(DUMMY_SERIALIZED, "{}", "run-8", undefined, undefined, undefined, "tool")
    ).resolves.toBeUndefined();
    expect(onBlock).toHaveBeenCalledWith("tool", expect.stringContaining("revoked"), "run-8");
  });
});

describe("BouclierCallbackHandler.handleAgentAction", () => {
  it("throws for revoked agent", async () => {
    const client = makeClient({ isRevoked: true });
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    const action = { tool: "uniswap_swap", toolInput: {}, log: "", messageLog: [] } as any;
    await expect(handler.handleAgentAction(action, "run-9")).rejects.toThrow(BouclierPermissionError);
  });

  it("passes for active agent", async () => {
    const client = makeClient({});
    const handler = new BouclierCallbackHandler(client, AGENT_ID);
    const action = { tool: "get_price", toolInput: {}, log: "", messageLog: [] } as any;
    await expect(handler.handleAgentAction(action, "run-10")).resolves.toBeUndefined();
  });
});

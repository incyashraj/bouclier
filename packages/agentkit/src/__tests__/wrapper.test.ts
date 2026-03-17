import { describe, it, expect, mock } from "bun:test";
import { BouclierAgentKitWrapper, BouclierAgentKitError } from "../wrapper.js";
import type { BouclierClient, PermissionScope } from "@bouclier/sdk";
import type { AgentKitLike, AgentKitAction } from "../wrapper.js";
import { parseUnits, zeroHash } from "viem";

// ── Fixtures ──────────────────────────────────────────────────────

const AGENT_ID = "0xccdd000000000000000000000000000000000000000000000000000000000000" as const;

const ACTIVE_SCOPE: PermissionScope = {
  agentId:           AGENT_ID,
  allowedProtocols:  [],
  allowedSelectors:  [],
  allowedTokens:     [],
  dailySpendCapUSD:  parseUnits("2000", 18),
  perTxSpendCapUSD:  parseUnits("200", 18),
  validFrom:         0n,
  validUntil:        9_999_999_999n,
  allowAnyProtocol:  true,
  allowAnyToken:     true,
  revoked:           false,
  grantHash:         zeroHash,
  windowStartHour:   0,
  windowEndHour:     23,
  windowDaysMask:    0,
  allowedChainId:    0n,
};

function makeClient(overrides: Partial<{ isRevoked: boolean; scope: PermissionScope | null }>): BouclierClient {
  return {
    isRevoked: mock(() => Promise.resolve(overrides.isRevoked ?? false)),
    getActiveScope: mock(() =>
      overrides.scope === null
        ? Promise.reject(new Error("no scope"))
        : Promise.resolve(overrides.scope ?? ACTIVE_SCOPE)
    ),
  } as unknown as BouclierClient;
}

function makeKit(actions: AgentKitAction[]): AgentKitLike {
  return { getActions: () => actions };
}

function makeAction(name: string, result = "ok"): AgentKitAction {
  return {
    name,
    description: `Test action: ${name}`,
    invoke: mock(() => Promise.resolve(result)),
  };
}

// ── validateAction ────────────────────────────────────────────────

describe("BouclierAgentKitWrapper.validateAction", () => {
  it("allows active agent with valid scope", async () => {
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({}), AGENT_ID);
    const result = await wrapper.validateAction("uniswap_swap");
    expect(result.allowed).toBe(true);
  });

  it("denies revoked agent", async () => {
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({ isRevoked: true }), AGENT_ID);
    const result = await wrapper.validateAction("uniswap_swap");
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain("revoked");
  });

  it("denies when no scope exists", async () => {
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({ scope: null }), AGENT_ID);
    const result = await wrapper.validateAction("transfer");
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain("scope");
  });

  it("denies when scope has expired", async () => {
    const expiredScope = { ...ACTIVE_SCOPE, validUntil: 1_000_000n };
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({ scope: expiredScope }), AGENT_ID);
    const result = await wrapper.validateAction("transfer");
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain("expired");
  });
});

// ── getActions (wrapped) ──────────────────────────────────────────

describe("BouclierAgentKitWrapper.getActions", () => {
  it("passes action through for active agent", async () => {
    const action = makeAction("get_price", "ETH: $3200");
    const wrapper = new BouclierAgentKitWrapper(makeKit([action]), makeClient({}), AGENT_ID);
    const [wrapped] = wrapper.getActions();
    const result = await wrapped.invoke({});
    expect(result).toBe("ETH: $3200");
  });

  it("throws BouclierAgentKitError for revoked agent", async () => {
    const action = makeAction("uniswap_swap");
    const wrapper = new BouclierAgentKitWrapper(makeKit([action]), makeClient({ isRevoked: true }), AGENT_ID);
    const [wrapped] = wrapper.getActions();
    await expect(wrapped.invoke({})).rejects.toThrow(BouclierAgentKitError);
  });

  it("preserves action name and description on wrapped action", () => {
    const action = makeAction("my_custom_tool");
    const wrapper = new BouclierAgentKitWrapper(makeKit([action]), makeClient({}), AGENT_ID);
    const [wrapped] = wrapper.getActions();
    expect(wrapped.name).toBe("my_custom_tool");
    expect(wrapped.description).toBe("Test action: my_custom_tool");
  });

  it("wraps multiple actions independently", () => {
    const actions = [makeAction("action_a"), makeAction("action_b"), makeAction("action_c")];
    const wrapper = new BouclierAgentKitWrapper(makeKit(actions), makeClient({}), AGENT_ID);
    expect(wrapper.getActions()).toHaveLength(3);
  });
});

// ── checkSpendBudget ──────────────────────────────────────────────

describe("BouclierAgentKitWrapper.checkSpendBudget", () => {
  it("returns true for amount within per-tx cap", async () => {
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({}), AGENT_ID);
    expect(await wrapper.checkSpendBudget(parseUnits("100", 18))).toBe(true);
  });

  it("returns false for amount exceeding per-tx cap", async () => {
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({}), AGENT_ID);
    expect(await wrapper.checkSpendBudget(parseUnits("500", 18))).toBe(false);
  });

  it("returns true when dailySpendCapUSD is 0 (no cap)", async () => {
    const noCap = { ...ACTIVE_SCOPE, dailySpendCapUSD: 0n };
    const wrapper = new BouclierAgentKitWrapper(makeKit([]), makeClient({ scope: noCap }), AGENT_ID);
    expect(await wrapper.checkSpendBudget(parseUnits("999999", 18))).toBe(true);
  });
});

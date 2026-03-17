import { describe, it, expect, mock } from "bun:test";
import {
  createPermissionProvider,
  createActionEvaluator,
  createBouclierPlugin,
} from "../plugin.js";
import type { BouclierClient, PermissionScope } from "@bouclier/sdk";
import { parseUnits, zeroHash } from "viem";

const AGENT_ID = "0xbbcc000000000000000000000000000000000000000000000000000000000000" as const;

const ACTIVE_SCOPE: PermissionScope = {
  agentId:           AGENT_ID,
  allowedProtocols:  [],
  allowedSelectors:  [],
  allowedTokens:     [],
  dailySpendCapUSD:  parseUnits("500", 18),
  perTxSpendCapUSD:  parseUnits("50", 18),
  validFrom:         0n,
  validUntil:        9_999_999_999n,
  allowAnyProtocol:  true,
  allowAnyToken:     false,
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

const DUMMY_RUNTIME = { agentId: "eliza-test" } as any;
const DUMMY_MESSAGE = { userId: "user-1", content: { text: "swap 1 ETH for USDC" } } as any;

// ── Permission Provider ───────────────────────────────────────────

describe("createPermissionProvider", () => {
  it("returns ACTIVE status when agent has a valid scope", async () => {
    const provider = createPermissionProvider(makeClient({}), AGENT_ID);
    const result = await provider.get(DUMMY_RUNTIME, DUMMY_MESSAGE);
    expect(result).toContain("ACTIVE");
    expect(result).toContain("$500");
  });

  it("returns REVOKED status when agent is revoked", async () => {
    const provider = createPermissionProvider(makeClient({ isRevoked: true }), AGENT_ID);
    const result = await provider.get(DUMMY_RUNTIME, DUMMY_MESSAGE);
    expect(result).toContain("REVOKED");
  });

  it("returns blocked status when there is no scope", async () => {
    const provider = createPermissionProvider(makeClient({ scope: null }), AGENT_ID);
    const result = await provider.get(DUMMY_RUNTIME, DUMMY_MESSAGE);
    expect(result).toContain("blocked");
  });

  it("returns expired status when scope validUntil is in the past", async () => {
    const expiredScope = { ...ACTIVE_SCOPE, validUntil: 1_000_000n };
    const provider = createPermissionProvider(makeClient({ scope: expiredScope }), AGENT_ID);
    const result = await provider.get(DUMMY_RUNTIME, DUMMY_MESSAGE);
    expect(result).toContain("expired");
  });
});

// ── Action Evaluator ──────────────────────────────────────────────

describe("createActionEvaluator", () => {
  it("validate() returns true for active agent with valid scope", async () => {
    const evaluator = createActionEvaluator(makeClient({}), AGENT_ID);
    expect(await evaluator.validate(DUMMY_RUNTIME, DUMMY_MESSAGE)).toBe(true);
  });

  it("validate() returns false when agent is revoked", async () => {
    const evaluator = createActionEvaluator(makeClient({ isRevoked: true }), AGENT_ID);
    expect(await evaluator.validate(DUMMY_RUNTIME, DUMMY_MESSAGE)).toBe(false);
  });

  it("validate() returns false when no scope exists (fail closed)", async () => {
    const evaluator = createActionEvaluator(makeClient({ scope: null }), AGENT_ID);
    expect(await evaluator.validate(DUMMY_RUNTIME, DUMMY_MESSAGE)).toBe(false);
  });

  it("validate() returns false when scope is revoked", async () => {
    const evaluator = createActionEvaluator(makeClient({ scope: { ...ACTIVE_SCOPE, revoked: true } }), AGENT_ID);
    expect(await evaluator.validate(DUMMY_RUNTIME, DUMMY_MESSAGE)).toBe(false);
  });

  it("handler() returns blocked=true and reason when called", async () => {
    const evaluator = createActionEvaluator(makeClient({ isRevoked: true }), AGENT_ID);
    const result = await evaluator.handler(DUMMY_RUNTIME, DUMMY_MESSAGE) as any;
    expect(result.blocked).toBe(true);
    expect(result.reason).toContain("revoked");
  });
});

// ── Plugin factory ────────────────────────────────────────────────

describe("createBouclierPlugin", () => {
  it("creates a plugin with correct name and structure", () => {
    const plugin = createBouclierPlugin(makeClient({}), AGENT_ID);
    expect(plugin.name).toBe("bouclier");
    expect(plugin.actions).toHaveLength(0);
    expect(plugin.providers).toHaveLength(1);
    expect(plugin.evaluators).toHaveLength(1);
    expect(plugin.evaluators[0].name).toBe("BOUCLIER_PERMISSION_CHECK");
  });
});

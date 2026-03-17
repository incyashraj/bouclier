/**
 * @bouclier/sdk — BouclierClient unit tests
 * Uses Vitest + viem mock transports (no real RPC).
 */

import { describe, it, expect, mock, beforeEach } from "bun:test";
import { parseUnits, zeroHash } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { BouclierClient } from "../BouclierClient.js";
import type { BouclierAddresses, AgentRecord, PermissionScope, AuditRecord } from "../types.js";

// ── Test fixtures ────────────────────────────────────────────────

const ADDRS: BouclierAddresses = {
  revocationRegistry: "0x1111111111111111111111111111111111111111",
  agentRegistry:      "0x2222222222222222222222222222222222222222",
  spendTracker:       "0x3333333333333333333333333333333333333333",
  auditLogger:        "0x4444444444444444444444444444444444444444",
  permissionVault:    "0x5555555555555555555555555555555555555555",
};

const AGENT_ID = "0xaabbccdd00000000000000000000000000000000000000000000000000000000" as const;
const AGENT_WALLET = "0x6666666666666666666666666666666666666666" as const;
const OWNER = "0x7777777777777777777777777777777777777777" as const;

const RAW_AGENT_RECORD = {
  agentId:       AGENT_ID,
  agentAddress:  AGENT_WALLET,
  owner:         OWNER,
  status:        0, // Active
  registeredAt:  1_700_000_000,
  did:           `did:ethr:base:${AGENT_WALLET}`,
  model:         "claude-3-5-sonnet",
  parentAgentId: zeroHash,
  metadataCID:   "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
};

const RAW_SCOPE: PermissionScope = {
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

// ── readContract mock factory ─────────────────────────────────────

function makePublicClient(readContractImpl: (args: { functionName: string }) => unknown) {
  return {
    readContract: mock(readContractImpl),
  } as unknown as ReturnType<typeof import("viem").createPublicClient>;
}

// ── Tests ─────────────────────────────────────────────────────────

describe("BouclierClient.resolveAgent", () => {
  it("maps raw contract tuple to AgentRecord", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(({ functionName }) => {
        if (functionName === "resolve") return RAW_AGENT_RECORD;
        throw new Error(`Unexpected call: ${functionName}`);
      }),
    });

    const agent = await client.resolveAgent(AGENT_ID);

    expect(agent.agentId).toBe(AGENT_ID);
    expect(agent.owner).toBe(OWNER);
    expect(agent.status).toBe("Active");
    expect(agent.model).toBe("claude-3-5-sonnet");
    expect(agent.did).toBe(`did:ethr:base:${AGENT_WALLET}`);
  });

  it("maps status=1 to Suspended", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => ({ ...RAW_AGENT_RECORD, status: 1 })),
    });
    const agent = await client.resolveAgent(AGENT_ID);
    expect(agent.status).toBe("Suspended");
  });

  it("maps status=2 to Revoked", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => ({ ...RAW_AGENT_RECORD, status: 2 })),
    });
    const agent = await client.resolveAgent(AGENT_ID);
    expect(agent.status).toBe("Revoked");
  });
});

describe("BouclierClient.getAgentId", () => {
  it("returns bytes32 agentId for a wallet address", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => AGENT_ID),
    });
    const id = await client.getAgentId(AGENT_WALLET);
    expect(id).toBe(AGENT_ID);
  });
});

describe("BouclierClient.getAgentsByOwner", () => {
  it("returns an array of bytes32 ids", async () => {
    const ids = [AGENT_ID, "0x1234" + "00".repeat(30)] as const;
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => ids),
    });
    const result = await client.getAgentsByOwner(OWNER);
    expect(result).toHaveLength(2);
    expect(result[0]).toBe(AGENT_ID);
  });
});

describe("BouclierClient.isAgentActive", () => {
  it("returns true for active agent", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => true),
    });
    expect(await client.isAgentActive(AGENT_ID)).toBe(true);
  });

  it("returns false for revoked agent", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => false),
    });
    expect(await client.isAgentActive(AGENT_ID)).toBe(false);
  });
});

describe("BouclierClient.isRevoked", () => {
  it("returns false when agent has not been revoked", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => false),
    });
    expect(await client.isRevoked(AGENT_ID)).toBe(false);
  });

  it("returns true when agent is revoked", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => true),
    });
    expect(await client.isRevoked(AGENT_ID)).toBe(true);
  });
});

describe("BouclierClient.getActiveScope", () => {
  it("returns the permission scope directly from the contract", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => RAW_SCOPE),
    });
    const scope = await client.getActiveScope(AGENT_ID);
    expect(scope.dailySpendCapUSD).toBe(parseUnits("1000", 18));
    expect(scope.allowAnyProtocol).toBe(false);
    expect(scope.revoked).toBe(false);
  });
});

describe("BouclierClient.getGrantNonce", () => {
  it("returns current nonce as bigint", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => 3n),
    });
    expect(await client.getGrantNonce(AGENT_ID)).toBe(3n);
  });
});

describe("BouclierClient.getAgentHistory", () => {
  it("returns paginated event id array", async () => {
    const eventIds = [
      "0xevent1" + "00".repeat(29),
      "0xevent2" + "00".repeat(29),
    ];
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => eventIds),
    });
    const result = await client.getAgentHistory(AGENT_ID, 0n, 20n);
    expect(result).toHaveLength(2);
  });
});

describe("BouclierClient.buildScopeSignature", () => {
  it("throws if walletClient is not provided", async () => {
    const client = new BouclierClient({
      addresses: ADDRS,
      publicClient: makePublicClient(() => null),
    });
    await expect(
      client.buildScopeSignature(
        {
          agentId: AGENT_ID,
          dailySpendCapUSD: parseUnits("500", 18),
          perTxSpendCapUSD: parseUnits("50", 18),
          validFrom:  Math.floor(Date.now() / 1000),
          validUntil: Math.floor(Date.now() / 1000) + 86400 * 30,
          allowAnyProtocol: false,
          allowAnyToken:    false,
          nonce: 0n,
        },
        privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
      )
    ).rejects.toThrow("walletClient required");
  });
});

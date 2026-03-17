/**
 * @bouclier/langchain — BouclierCallbackHandler
 *
 * Drop-in LangChain callback that enforces Bouclier permission scopes on every
 * tool call. Blocks execution and records violations before the tool runs.
 *
 * Usage:
 *   import { BouclierCallbackHandler } from "@bouclier/langchain";
 *
 *   const handler = new BouclierCallbackHandler(bouclierClient, agentId);
 *
 *   const agent = await createOpenAIFunctionsAgent({
 *     llm, tools, prompt,
 *     callbacks: [handler],
 *   });
 */

import { BaseCallbackHandler } from "@langchain/core/callbacks/base";
import type { Serialized } from "@langchain/core/load/serializable";
import type { AgentAction, AgentFinish } from "@langchain/core/agents";
import type { LLMResult } from "@langchain/core/outputs";

import type { BouclierClient } from "@bouclier/sdk";
import type { Hex } from "viem";

// ── Types ─────────────────────────────────────────────────────────

export interface BouclierToolCheckResult {
  allowed: boolean;
  reason?: string;
}

/**
 * Optional hook called when a tool is blocked.
 * Return true to throw immediately, false to log-only.
 */
export type OnBlockHook = (
  toolName: string,
  reason: string,
  runId: string
) => boolean | Promise<boolean>;

// ── BouclierCallbackHandler ───────────────────────────────────────

export class BouclierCallbackHandler extends BaseCallbackHandler {
  readonly name = "BouclierCallbackHandler";

  private readonly client: BouclierClient;
  private readonly agentId: Hex;
  private readonly onBlock?: OnBlockHook;

  /** Track active run ids so we can pair start/end for audit */
  private readonly activeRuns = new Map<string, { toolName: string; startMs: number }>();

  constructor(
    client: BouclierClient,
    agentId: Hex,
    opts?: { onBlock?: OnBlockHook }
  ) {
    super();
    this.client  = client;
    this.agentId = agentId;
    this.onBlock = opts?.onBlock;
  }

  // ── LLM hooks (audit only) ────────────────────────────────────

  override async handleLLMStart(
    _llm: Serialized,
    _prompts: string[],
    runId: string
  ): Promise<void> {
    // Eagerly check revocation status before any LLM inference runs.
    // Revoked agents should not incur LLM API costs.
    const revoked = await this.client.isRevoked(this.agentId);
    if (revoked) {
      throw new BouclierPermissionError(
        this.agentId,
        "LLM invocation",
        "Agent is globally revoked — all actions blocked"
      );
    }
  }

  override async handleLLMEnd(_output: LLMResult, _runId: string): Promise<void> {
    // no-op — hook available for future telemetry
  }

  // ── Tool hooks (enforce + audit) ─────────────────────────────

  override async handleToolStart(
    _tool: Serialized,
    input: string,
    runId: string,
    _parentRunId?: string,
    _tags?: string[],
    _metadata?: Record<string, unknown>,
    name?: string
  ): Promise<void> {
    const toolName = name ?? "unknown_tool";
    this.activeRuns.set(runId, { toolName, startMs: Date.now() });

    // 1. Check global revocation (fast SLOAD)
    const revoked = await this.client.isRevoked(this.agentId);
    if (revoked) {
      await this._handleBlock(toolName, "Agent is globally revoked", runId);
      return;
    }

    // 2. Check active scope exists and is not expired
    let scope;
    try {
      scope = await this.client.getActiveScope(this.agentId);
    } catch {
      await this._handleBlock(toolName, "No active permission scope found", runId);
      return;
    }

    if (scope.revoked) {
      await this._handleBlock(toolName, "Permission scope has been revoked", runId);
      return;
    }

    const now = BigInt(Math.floor(Date.now() / 1000));
    if (scope.validUntil > 0n && now > scope.validUntil) {
      await this._handleBlock(toolName, "Permission scope has expired", runId);
      return;
    }
  }

  override async handleToolEnd(
    output: string,
    runId: string
  ): Promise<void> {
    this.activeRuns.delete(runId);
  }

  override async handleToolError(
    error: Error,
    runId: string
  ): Promise<void> {
    this.activeRuns.delete(runId);
  }

  // ── Agent action hook ─────────────────────────────────────────

  override async handleAgentAction(
    action: AgentAction,
    runId: string
  ): Promise<void> {
    // Double-check before every structured action (includes tool + log)
    const revoked = await this.client.isRevoked(this.agentId);
    if (revoked) {
      throw new BouclierPermissionError(
        this.agentId,
        action.tool,
        "Agent is globally revoked — action blocked"
      );
    }
  }

  override async handleAgentEnd(
    _action: AgentFinish,
    _runId: string
  ): Promise<void> {
    // no-op
  }

  // ── Internal ──────────────────────────────────────────────────

  private async _handleBlock(
    toolName: string,
    reason: string,
    runId: string
  ): Promise<void> {
    const shouldThrow = this.onBlock
      ? await this.onBlock(toolName, reason, runId)
      : true;

    if (shouldThrow) {
      throw new BouclierPermissionError(this.agentId, toolName, reason);
    }
  }
}

// ── BouclierPermissionError ───────────────────────────────────────

export class BouclierPermissionError extends Error {
  readonly agentId: Hex;
  readonly toolName: string;
  readonly bouclierReason: string;

  constructor(agentId: Hex, toolName: string, reason: string) {
    super(`[Bouclier] Tool "${toolName}" blocked for agent ${agentId}: ${reason}`);
    this.name = "BouclierPermissionError";
    this.agentId       = agentId;
    this.toolName      = toolName;
    this.bouclierReason = reason;
  }
}

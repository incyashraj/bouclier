/**
 * @bouclier/eliza-plugin — Bouclier ELIZA Plugin
 *
 * Integrates the Bouclier trust layer into ELIZA agent runtimes.
 * Provides a provider (injects permission state into context) and an evaluator
 * (validates every proposed action before execution).
 *
 * Usage in an ELIZA character file:
 *   "plugins": ["@bouclier/eliza-plugin"]
 *
 * Programmatic setup:
 *   import { createBouclierPlugin } from "@bouclier/eliza-plugin";
 *   const plugin = createBouclierPlugin(bouclierClient, agentId);
 *   // pass plugin to runtime.registerPlugin(plugin)
 */

import type { BouclierClient } from "@bouclier/sdk";
import type { Hex } from "viem";

// ── ELIZA interface shims ─────────────────────────────────────────
// We use structural typing to avoid a hard dependency on @elizaos/core
// at build time. The real types come in from the peer dependency at runtime.

export interface ElizaMemory {
  userId: string;
  content: { text: string };
  [key: string]: unknown;
}

export interface ElizaState {
  [key: string]: unknown;
}

export interface ElizaRuntime {
  agentId: string;
  [key: string]: unknown;
}

export interface ElizaProvider {
  get(runtime: ElizaRuntime, message: ElizaMemory, state?: ElizaState): Promise<string>;
}

export interface ElizaEvaluator {
  name: string;
  description: string;
  similes: string[];
  examples: unknown[];
  validate(runtime: ElizaRuntime, message: ElizaMemory, state?: ElizaState): Promise<boolean>;
  handler(runtime: ElizaRuntime, message: ElizaMemory, state?: ElizaState): Promise<unknown>;
}

export interface ElizaPlugin {
  name: string;
  description: string;
  actions:    unknown[];
  providers:  ElizaProvider[];
  evaluators: ElizaEvaluator[];
}

// ── BouclierPermissionProvider ────────────────────────────────────

/**
 * Injects a human-readable permission summary into ELIZA's context window
 * at the start of every action cycle.
 *
 * The agent sees something like:
 *   "Bouclier Trust Layer: active. Daily cap: $1,000. Expires: 2025-12-31."
 */
export function createPermissionProvider(
  client: BouclierClient,
  agentId: Hex
): ElizaProvider {
  return {
    async get(_runtime, _message, _state): Promise<string> {
      try {
        const [revoked, scope] = await Promise.all([
          client.isRevoked(agentId),
          client.getActiveScope(agentId).catch(() => null),
        ]);

        if (revoked) {
          return "⛔ Bouclier Trust Layer: REVOKED. All on-chain actions are blocked.";
        }

        if (!scope || scope.revoked) {
          return "⛔ Bouclier Trust Layer: No active permission scope. On-chain actions are blocked.";
        }

        const now = BigInt(Math.floor(Date.now() / 1000));
        if (scope.validUntil > 0n && now > scope.validUntil) {
          return "⛔ Bouclier Trust Layer: Permission scope expired. On-chain actions are blocked.";
        }

        const dailyCap = Number(scope.dailySpendCapUSD / 10n ** 18n);
        const perTxCap = Number(scope.perTxSpendCapUSD / 10n ** 18n);
        const expiresAt = scope.validUntil > 0n
          ? new Date(Number(scope.validUntil) * 1000).toISOString().split("T")[0]
          : "no expiry";

        return [
          "✅ Bouclier Trust Layer: ACTIVE.",
          `Daily spend cap: $${dailyCap.toLocaleString()}.`,
          `Per-tx spend cap: $${perTxCap.toLocaleString()}.`,
          `Scope expires: ${expiresAt}.`,
          scope.allowAnyProtocol
            ? "Protocol allowlist: any."
            : `Allowed protocols: ${scope.allowedProtocols.length} address(es).`,
        ].join(" ");
      } catch {
        return "⚠️ Bouclier Trust Layer: Unable to fetch permission state. Proceed with caution.";
      }
    },
  };
}

// ── BouclierActionEvaluator ───────────────────────────────────────

/**
 * Evaluator that runs before every ELIZA action.
 * Returns false (DENY) if:
 *   - Agent is globally revoked
 *   - No active scope exists or scope is revoked/expired
 *
 * When this evaluator returns false, ELIZA will not execute the action
 * and the handler records audit context.
 */
export function createActionEvaluator(
  client: BouclierClient,
  agentId: Hex
): ElizaEvaluator {
  return {
    name: "BOUCLIER_PERMISSION_CHECK",
    description: "Validates Bouclier permission scope before every on-chain action",
    similes: ["PERMISSION_CHECK", "TRUST_LAYER_VALIDATE"],
    examples: [],

    async validate(_runtime, _message, _state): Promise<boolean> {
      try {
        const revoked = await client.isRevoked(agentId);
        if (revoked) return false;

        const scope = await client.getActiveScope(agentId).catch(() => null);
        if (!scope || scope.revoked) return false;

        const now = BigInt(Math.floor(Date.now() / 1000));
        if (scope.validUntil > 0n && now > scope.validUntil) return false;

        return true;
      } catch {
        // Fail closed: if we can't verify permission, deny the action
        return false;
      }
    },

    async handler(_runtime, message, _state): Promise<{ blocked: boolean; reason: string }> {
      // This handler is called when validate() returns false.
      // Log the blocked attempt and return structured context.
      const revoked = await client.isRevoked(agentId).catch(() => true);
      const reason = revoked
        ? "Agent is globally revoked"
        : "No valid permission scope";

      return {
        blocked: true,
        reason: `[Bouclier] Action blocked for agent ${agentId}: ${reason}. Message: "${message.content.text}"`,
      };
    },
  };
}

// ── Plugin factory ────────────────────────────────────────────────

export function createBouclierPlugin(
  client: BouclierClient,
  agentId: Hex
): ElizaPlugin {
  return {
    name: "bouclier",
    description: "AI agent trust layer — enforce Bouclier permission scopes on all ELIZA actions",
    actions:    [], // Bouclier is enforcement-only, no user-visible actions
    providers:  [createPermissionProvider(client, agentId)],
    evaluators: [createActionEvaluator(client, agentId)],
  };
}

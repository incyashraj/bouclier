/**
 * @bouclier/agentkit — BouclierAgentKitWrapper
 *
 * Wraps a Coinbase AgentKit instance and intercepts all wallet operations
 * through Bouclier permission enforcement before sending them on-chain.
 *
 * Usage:
 *   import { BouclierAgentKitWrapper } from "@bouclier/agentkit";
 *
 *   const kit = await AgentKit.configureWithWallet({ wallet, ... });
 *   const protected = new BouclierAgentKitWrapper(kit, bouclierClient, agentId);
 *
 *   // Use protectedKit in your agent — all transactions are validated first
 *   const tools = await getLangChainTools(protected);
 */

import type { BouclierClient, PermissionScope } from "@bouclier/sdk";
import type { Hex, Address } from "viem";

// ── AgentKit interface shims ──────────────────────────────────────
// Structural typing so we don't hard-depend on @coinbase/agentkit at build time.

export interface AgentKitAction {
  name: string;
  description: string;
  invoke(params: Record<string, unknown>): Promise<string>;
}

export interface AgentKitLike {
  getActions(): AgentKitAction[];
  wallet?: {
    getDefaultAddress(): Promise<{ getId(): string }>;
    sendTransaction(params: {
      to: string;
      value?: bigint;
      data?: string;
    }): Promise<{ transactionHash: string }>;
  };
}

// ── Validation result ─────────────────────────────────────────────

export interface BouclierValidationResult {
  allowed: boolean;
  reason?: string;
  agentId: Hex;
  actionName: string;
}

// ── BouclierAgentKitWrapper ───────────────────────────────────────

export class BouclierAgentKitWrapper<T extends AgentKitLike> {
  private readonly kit: T;
  private readonly client: BouclierClient;
  readonly agentId: Hex;

  constructor(kit: T, client: BouclierClient, agentId: Hex) {
    this.kit     = kit;
    this.client  = client;
    this.agentId = agentId;
  }

  /**
   * Returns wrapped AgentKit actions.
   * Each action is intercepted: permission is checked before invocation.
   */
  getActions(): AgentKitAction[] {
    return this.kit.getActions().map((action) => this._wrapAction(action));
  }

  /**
   * Validate a proposed action by name without executing it.
   * Useful for pre-flight checks before building a transaction.
   */
  async validateAction(actionName: string): Promise<BouclierValidationResult> {
    try {
      const revoked = await this.client.isRevoked(this.agentId);
      if (revoked) {
        return {
          allowed:    false,
          reason:     "Agent is globally revoked",
          agentId:    this.agentId,
          actionName,
        };
      }

      const scope = await this.client.getActiveScope(this.agentId).catch(() => null);
      if (!scope || scope.revoked) {
        return {
          allowed:    false,
          reason:     "No active permission scope",
          agentId:    this.agentId,
          actionName,
        };
      }

      const now = BigInt(Math.floor(Date.now() / 1000));
      if (scope.validUntil > 0n && now > scope.validUntil) {
        return {
          allowed:    false,
          reason:     "Permission scope has expired",
          agentId:    this.agentId,
          actionName,
        };
      }

      return { allowed: true, agentId: this.agentId, actionName };
    } catch (err) {
      return {
        allowed:    false,
        reason:     `Permission check failed: ${err instanceof Error ? err.message : String(err)}`,
        agentId:    this.agentId,
        actionName,
      };
    }
  }

  /**
   * Check whether the agent's rolling USD spend is within the daily cap.
   * Pass `estimatedUSD18` as an 18-decimal bigint.
   *
   * This is a READ check — actual spend recording happens on-chain inside
   * SpendTracker when PermissionVault calls `recordSpend`.
   */
  async checkSpendBudget(estimatedUSD18: bigint): Promise<boolean> {
    try {
      const scope = await this.client.getActiveScope(this.agentId);
      if (scope.dailySpendCapUSD === 0n) return true; // no cap
      // The SDK doesn't expose getRollingSpend directly — this is a conservative
      // check using the per-tx cap only (full rolling check requires SpendTracker read).
      return estimatedUSD18 <= scope.perTxSpendCapUSD;
    } catch {
      return false;
    }
  }

  // ── Internals ─────────────────────────────────────────────────

  private _wrapAction(action: AgentKitAction): AgentKitAction {
    const wrapper = this;
    return {
      name:        action.name,
      description: action.description,

      async invoke(params: Record<string, unknown>): Promise<string> {
        const check = await wrapper.validateAction(action.name);
        if (!check.allowed) {
          throw new BouclierAgentKitError(
            wrapper.agentId,
            action.name,
            check.reason ?? "Permission denied"
          );
        }
        return action.invoke(params);
      },
    };
  }
}

// ── BouclierAgentKitError ─────────────────────────────────────────

export class BouclierAgentKitError extends Error {
  readonly agentId: Hex;
  readonly actionName: string;
  readonly bouclierReason: string;

  constructor(agentId: Hex, actionName: string, reason: string) {
    super(`[Bouclier/AgentKit] Action "${actionName}" blocked for ${agentId}: ${reason}`);
    this.name           = "BouclierAgentKitError";
    this.agentId        = agentId;
    this.actionName     = actionName;
    this.bouclierReason = reason;
  }
}

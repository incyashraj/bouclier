/**
 * BouclierClient — main SDK entry point.
 * Provides typed read/write operations against all five Bouclier contracts.
 */

import {
  type PublicClient,
  type WalletClient,
  type Address,
  type Hex,
  encodeAbiParameters,
  keccak256,
  signatureToHex,
  type Account,
} from "viem";

import type {
  BouclierAddresses,
  AgentRecord,
  PermissionScope,
  AuditRecord,
  RevocationRecord,
  GrantScopeParams,
} from "./types.js";

import {
  agentRegistryAbi,
  permissionVaultAbi,
  revocationRegistryAbi,
  auditLoggerAbi,
} from "./abis.js";

export class BouclierClient {
  private readonly addresses: BouclierAddresses;
  private readonly publicClient: PublicClient;
  private readonly walletClient?: WalletClient;

  constructor(opts: {
    addresses: BouclierAddresses;
    publicClient: PublicClient;
    walletClient?: WalletClient;
  }) {
    this.addresses   = opts.addresses;
    this.publicClient  = opts.publicClient;
    this.walletClient  = opts.walletClient;
  }

  // ── AgentRegistry ─────────────────────────────────────────────

  async resolveAgent(agentId: Hex): Promise<AgentRecord> {
    const raw = await this.publicClient.readContract({
      address: this.addresses.agentRegistry,
      abi:     agentRegistryAbi,
      functionName: "resolve",
      args:    [agentId],
    });
    return this._mapAgentRecord(raw as unknown as Parameters<typeof this._mapAgentRecord>[0]);
  }

  async getAgentId(agentWallet: Address): Promise<Hex> {
    return this.publicClient.readContract({
      address: this.addresses.agentRegistry,
      abi:     agentRegistryAbi,
      functionName: "getAgentId",
      args:    [agentWallet],
    });
  }

  async getAgentsByOwner(owner: Address): Promise<Hex[]> {
    return this.publicClient.readContract({
      address: this.addresses.agentRegistry,
      abi:     agentRegistryAbi,
      functionName: "getAgentsByOwner",
      args:    [owner],
    }) as Promise<Hex[]>;
  }

  async isAgentActive(agentId: Hex): Promise<boolean> {
    return this.publicClient.readContract({
      address: this.addresses.agentRegistry,
      abi:     agentRegistryAbi,
      functionName: "isActive",
      args:    [agentId],
    });
  }

  // ── PermissionVault ───────────────────────────────────────────

  async getActiveScope(agentId: Hex): Promise<PermissionScope> {
    const raw = await this.publicClient.readContract({
      address: this.addresses.permissionVault,
      abi:     permissionVaultAbi,
      functionName: "getActiveScope",
      args:    [agentId],
    });
    return raw as unknown as PermissionScope;
  }

  async getGrantNonce(agentId: Hex): Promise<bigint> {
    return this.publicClient.readContract({
      address: this.addresses.permissionVault,
      abi:     permissionVaultAbi,
      functionName: "grantNonces",
      args:    [agentId],
    });
  }

  /**
   * Build the EIP-712 typed-data signature for a grantPermission call.
   * The caller must sign with the agent owner's account.
   */
  async buildScopeSignature(
    params: GrantScopeParams,
    account: Account
  ): Promise<Hex> {
    if (!this.walletClient) {
      throw new Error("BouclierClient: walletClient required for signing");
    }

    const SCOPE_TYPEHASH = await this.publicClient.readContract({
      address: this.addresses.permissionVault,
      abi:     permissionVaultAbi,
      functionName: "SCOPE_TYPEHASH",
    });

    const domainSeparator = await this.publicClient.readContract({
      address: this.addresses.permissionVault,
      abi:     permissionVaultAbi,
      functionName: "DOMAIN_SEPARATOR",
    });

    const structHash = keccak256(
      encodeAbiParameters(
        [
          { type: "bytes32" }, // SCOPE_TYPEHASH
          { type: "bytes32" }, // agentId
          { type: "uint256" }, // nonce
          { type: "uint256" }, // dailySpendCapUSD
          { type: "uint256" }, // perTxSpendCapUSD
          { type: "uint256" }, // validFrom (uint48 encoded as uint256)
          { type: "uint256" }, // validUntil
          { type: "bool"    }, // allowAnyProtocol
          { type: "bool"    }, // allowAnyToken
        ],
        [
          SCOPE_TYPEHASH,
          params.agentId,
          params.nonce,
          params.dailySpendCapUSD,
          params.perTxSpendCapUSD,
          BigInt(params.validFrom),
          BigInt(params.validUntil),
          params.allowAnyProtocol,
          params.allowAnyToken,
        ]
      )
    );

    const digest = keccak256(
      encodeAbiParameters(
        [{ type: "bytes2" }, { type: "bytes32" }, { type: "bytes32" }],
        ["0x1901", domainSeparator, structHash]
      )
    );

    const sig = await this.walletClient.signMessage({
      account,
      message: { raw: digest },
    });

    return sig;
  }

  // ── RevocationRegistry ────────────────────────────────────────

  async isRevoked(agentId: Hex): Promise<boolean> {
    return this.publicClient.readContract({
      address: this.addresses.revocationRegistry,
      abi:     revocationRegistryAbi,
      functionName: "isRevoked",
      args:    [agentId],
    });
  }

  // ── AuditLogger ───────────────────────────────────────────────

  async getAuditRecord(eventId: Hex): Promise<AuditRecord> {
    const raw = await this.publicClient.readContract({
      address: this.addresses.auditLogger,
      abi:     auditLoggerAbi,
      functionName: "getAuditRecord",
      args:    [eventId],
    });
    return raw as unknown as AuditRecord;
  }

  async getAgentHistory(
    agentId: Hex,
    offset: bigint = 0n,
    limit: bigint = 50n
  ): Promise<Hex[]> {
    return this.publicClient.readContract({
      address: this.addresses.auditLogger,
      abi:     auditLoggerAbi,
      functionName: "getAgentHistory",
      args:    [agentId, offset, limit],
    }) as Promise<Hex[]>;
  }

  async getTotalEvents(agentId: Hex): Promise<bigint> {
    return this.publicClient.readContract({
      address: this.addresses.auditLogger,
      abi:     auditLoggerAbi,
      functionName: "getTotalEvents",
      args:    [agentId],
    }) as Promise<bigint>;
  }

  async getAuditTrail(
    agentId: Hex,
    offset: bigint = 0n,
    limit: bigint = 50n
  ): Promise<AuditRecord[]> {
    const eventIds = await this.getAgentHistory(agentId, offset, limit);
    return Promise.all(eventIds.map((id) => this.getAuditRecord(id)));
  }

  // ── Delegation helpers (Item 5) ───────────────────────────────

  /**
   * Register a child agent under a parent in the AgentRegistry.
   * parentAgentId is stored on-chain for delegation chain traversal.
   * Returns the transaction hash. Requires walletClient.
   */
  async registerChildAgent(
    parentAgentId: Hex,
    childWallet:   Address,
    model:         string,
    metadataCID:   string = ""
  ): Promise<Hex> {
    if (!this.walletClient) throw new Error("BouclierClient: walletClient required");
    const [account] = await this.walletClient.getAddresses();
    return this.walletClient.writeContract({
      address:      this.addresses.agentRegistry,
      abi:          agentRegistryAbi,
      functionName: "register",
      args:         [childWallet, model, parentAgentId, metadataCID],
      account,
      chain:        this.publicClient.chain ?? null,
    });
  }

  /**
   * Resolve the full delegation chain for an agent, from child → root.
   * Returns an ordered array starting with the given agent, ending with the root.
   */
  async getDelegationChain(agentId: Hex): Promise<AgentRecord[]> {
    const chain: AgentRecord[] = [];
    let current: Hex = agentId;
    const ZERO = "0x" + "0".repeat(64) as Hex;
    for (let depth = 0; depth < 8; depth++) {
      const rec = await this.resolveAgent(current);
      chain.push(rec);
      if (!rec.parentAgentId || rec.parentAgentId === ZERO) break;
      current = rec.parentAgentId;
    }
    return chain;
  }

  // ── Simulation (Item 6) ───────────────────────────────────────

  /**
   * Dry-run a proposed transaction against the active scope without writing to chain.
   *
   * Checks (in order):
   *   1. Agent is registered and active
   *   2. Agent is not globally revoked
   *   3. Agent has a non-expired, non-revoked permission scope
   *   4. Current time is within the allowed trade window
   *   5. Requested USD value ≤ per-tx cap
   *   6. Rolling 24h spend + value ≤ daily cap
   *
   * @param agentId     The bytes32 agent identifier
   * @param valueUSD    Estimated USD value of the transaction (18-decimal bigint, optional — 0 for checks only)
   * @returns           { allowed, reason, utilization } — utilization is 0–100 percent of daily cap used
   */
  async simulate(
    agentId:  Hex,
    valueUSD: bigint = 0n
  ): Promise<{ allowed: boolean; reason: string; utilization: number }> {
    const ZERO = "0x" + "0".repeat(64) as Hex;

    // 1. Agent registration check
    let isActive = false;
    try { isActive = await this.isAgentActive(agentId); } catch {}
    if (!isActive) {
      return { allowed: false, reason: "AgentNotRegistered", utilization: 0 };
    }

    // 2. Global revocation check
    const revoked = await this.isRevoked(agentId);
    if (revoked) {
      return { allowed: false, reason: "AgentRevoked", utilization: 100 };
    }

    // 3. Scope existence and expiry check
    const scope = await this.getActiveScope(agentId);
    if (!scope || scope.dailySpendCapUSD === 0n || scope.revoked) {
      return { allowed: false, reason: "NoActiveScope", utilization: 0 };
    }
    const nowSec = BigInt(Math.floor(Date.now() / 1000));
    if (nowSec < scope.validFrom) {
      return { allowed: false, reason: "ScopeNotYetValid", utilization: 0 };
    }
    if (nowSec > scope.validUntil) {
      return { allowed: false, reason: "ScopeExpired", utilization: 0 };
    }

    // 4. Trade window check (UTC hour)
    const nowHour = new Date().getUTCHours();
    const winStart = Number(scope.windowStartHour);
    const winEnd   = Number(scope.windowEndHour);
    const inWindow = winEnd > winStart
      ? nowHour >= winStart && nowHour < winEnd
      : nowHour >= winStart || nowHour < winEnd; // overnight window
    if (!inWindow) {
      return { allowed: false, reason: "OutsideTradeWindow", utilization: 0 };
    }

    // 5. Per-tx cap
    if (valueUSD > 0n && valueUSD > scope.perTxSpendCapUSD) {
      return { allowed: false, reason: "ExceedsPerTxCap", utilization: 100 };
    }

    // 6. Daily cap
    let rollingSpend = 0n;
    try {
      rollingSpend = await this.publicClient.readContract({
        address:      this.addresses.spendTracker,
        abi:          [{
          name: "getRollingSpend", type: "function", stateMutability: "view",
          inputs:  [{ name: "agentId", type: "bytes32" }, { name: "window", type: "uint256" }],
          outputs: [{ name: "", type: "uint256" }],
        }],
        functionName: "getRollingSpend",
        args: [agentId, 86400n],
      }) as bigint;
    } catch {}

    const projectedSpend = rollingSpend + valueUSD;
    const utilization = scope.dailySpendCapUSD > 0n
      ? Math.min(100, Number((projectedSpend * 100n) / scope.dailySpendCapUSD))
      : 0;

    if (projectedSpend > scope.dailySpendCapUSD) {
      return { allowed: false, reason: "ExceedsDailyCap", utilization };
    }

    return { allowed: true, reason: "ok", utilization };
  }

  // ── Mappers ───────────────────────────────────────────────────

  private _mapAgentRecord(raw: {
    agentAddress: Address;
    owner: Address;
    status: number;
    registeredAt: number;
    agentId: Hex;
    did: string;
    model: string;
    parentAgentId: Hex;
    metadataCID: string;
  }): AgentRecord {
    const statuses = ["Active", "Suspended", "Revoked"] as const;
    return {
      agentId:       raw.agentId,
      agentAddress:  raw.agentAddress,
      owner:         raw.owner,
      status:        statuses[raw.status] ?? "Active",
      registeredAt:  raw.registeredAt,
      did:           raw.did,
      model:         raw.model,
      parentAgentId: raw.parentAgentId,
      metadataCID:   raw.metadataCID,
    };
  }
}

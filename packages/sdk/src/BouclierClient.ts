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

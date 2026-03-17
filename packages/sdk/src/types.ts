/**
 * Bouclier SDK — shared TypeScript types.
 * Mirrors the Solidity structs in IBouclier.sol.
 */

import type { Address, Hex } from "viem";

// ── Agent status ──────────────────────────────────────────────────

export type AgentStatus = "Active" | "Suspended" | "Revoked";

export const AgentStatusEnum = {
  Active:    0,
  Suspended: 1,
  Revoked:   2,
} as const;

// ── Revocation ────────────────────────────────────────────────────

export type RevocationReason =
  | "UserRequested"
  | "Suspicious"
  | "Compromised"
  | "PolicyViolation"
  | "Emergency";

export const RevocationReasonEnum = {
  UserRequested:  0,
  Suspicious:     1,
  Compromised:    2,
  PolicyViolation: 3,
  Emergency:      4,
} as const;

// ── Agent record ──────────────────────────────────────────────────

export interface AgentRecord {
  agentId:       Hex;
  agentAddress:  Address;
  owner:         Address;
  status:        AgentStatus;
  registeredAt:  number;       // uint48 -> number in viem
  did:           string;
  model:         string;
  parentAgentId: Hex;
  metadataCID:   string;
}

// ── Permission scope ──────────────────────────────────────────────

export interface PermissionScope {
  agentId:           Hex;
  allowedProtocols:  Address[];
  allowedSelectors:  Hex[];
  allowedTokens:     Address[];
  dailySpendCapUSD:  bigint;     // 18-decimal USD, 0 = no cap
  perTxSpendCapUSD:  bigint;     // 18-decimal USD, 0 = no cap
  validFrom:         bigint;     // unix timestamp
  validUntil:        bigint;     // unix timestamp
  allowAnyProtocol:  boolean;
  allowAnyToken:     boolean;
  revoked:           boolean;
  grantHash:         Hex;
  windowStartHour:   number;     // 0-23 UTC
  windowEndHour:     number;     // 0-23 UTC
  windowDaysMask:    number;     // bitmask Mon=1..Sun=64, 0=every day
  allowedChainId:    bigint;     // 0 = current chain
}

// ── Audit record ──────────────────────────────────────────────────

export interface AuditRecord {
  eventId:       Hex;
  agentId:       Hex;
  actionHash:    Hex;
  target:        Address;
  selector:      Hex;
  tokenAddress:  Address;
  usdAmount:     bigint;
  timestamp:     number;   // uint48 -> number in viem
  allowed:       boolean;
  violationType: string;
  ipfsCID:       string;
}

// ── Revocation record ─────────────────────────────────────────────

export interface RevocationRecord {
  revoked:        boolean;
  revokedAt:      bigint;
  reinstatedAt:   bigint;
  revokedBy:      Address;
  reason:         RevocationReason;
  notes:          string;
}

// ── Contract addresses bundle ─────────────────────────────────────

export interface BouclierAddresses {
  revocationRegistry: Address;
  agentRegistry:      Address;
  spendTracker:       Address;
  auditLogger:        Address;
  permissionVault:    Address;
}

// ── Grant scope parameters (for buildScopeSignature) ─────────────

export interface GrantScopeParams {
  agentId:          Hex;
  dailySpendCapUSD: bigint;
  perTxSpendCapUSD: bigint;
  validFrom:        number;   // uint48
  validUntil:       number;   // uint48
  allowAnyProtocol: boolean;
  allowAnyToken:    boolean;
  nonce:            bigint;
}

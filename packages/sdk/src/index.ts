/**
 * @bouclier/sdk — Bouclier Agent Trust Layer TypeScript SDK
 *
 * Usage:
 *   import { BouclierClient } from "@bouclier/sdk";
 *   import { createPublicClient, http } from "viem";
 *   import { base } from "viem/chains";
 *
 *   const client = new BouclierClient({
 *     addresses: DEPLOYMENT_ADDRESSES,
 *     publicClient: createPublicClient({ chain: base, transport: http() }),
 *   });
 *
 *   const scope = await client.getActiveScope(agentId);
 */

export { BouclierClient } from "./BouclierClient.js";
export type {
  BouclierAddresses,
  AgentRecord,
  AgentStatus,
  PermissionScope,
  AuditRecord,
  RevocationRecord,
  RevocationReason,
  GrantScopeParams,
} from "./types.js";
export {
  AgentStatusEnum,
  RevocationReasonEnum,
} from "./types.js";
export {
  agentRegistryAbi,
  permissionVaultAbi,
  revocationRegistryAbi,
  auditLoggerAbi,
} from "./abis.js";

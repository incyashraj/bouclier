import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  PermissionGranted,
  PermissionRevoked,
  PermissionViolation as PermissionViolationEvent,
} from "../generated/PermissionVault/PermissionVault";
import {
  Agent,
  PermissionGrant,
  PermissionViolation,
} from "../generated/schema";

export function handlePermissionGranted(event: PermissionGranted): void {
  let agentId = event.params.agentId.toHexString();
  let grantHash = event.params.grantHash;

  // Use agentId+grantHash as the living id—last write wins
  let id = agentId + "-" + grantHash.toHexString();
  let grant = new PermissionGrant(id);
  grant.agent = agentId;
  grant.agentId = event.params.agentId;
  grant.scopeHash = grantHash;
  grant.validUntil = event.params.validUntil;
  grant.revokedAt = null;
  grant.revokedBy = null;
  grant.grantedAt = event.block.timestamp;
  grant.active = true;
  grant.save();

  // Ensure agent entity exists (may have been created before registry event)
  let agent = Agent.load(agentId);
  if (agent == null) {
    agent = new Agent(agentId);
    agent.wallet = Bytes.fromHexString("0x" + "00".repeat(20));
    agent.owner = event.transaction.from;
    agent.model = "";
    agent.metadataCID = "";
    agent.parentAgentId = Bytes.fromHexString("0x" + "00".repeat(32));
    agent.status = 0;
    agent.registeredAt = event.block.timestamp;
    agent.updatedAt = event.block.timestamp;
    agent.save();
  }
}

export function handlePermissionRevoked(event: PermissionRevoked): void {
  let agentId = event.params.agentId.toHexString();

  // Load most recent grant by agentId prefix scan is not possible in graph-ts.
  // We rely on the frontend to query all grants for this agent and find active one.
  // Here we create a revocation marker by updating agent updated timestamp.
  let agent = Agent.load(agentId);
  if (agent != null) {
    agent.updatedAt = event.block.timestamp;
    agent.save();
  }

  // Attempt to update the grant record if we can derive the id.
  // Without scopeHash in the event we cannot directly load the PermissionGrant.
  // The dashboard should re-query isRevoked() via RPC for the definitive answer.
}

export function handlePermissionViolation(
  event: PermissionViolationEvent
): void {
  let agentId = event.params.agentId.toHexString();
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  let violation = new PermissionViolation(id);
  violation.agent = agentId;
  violation.agentId = event.params.agentId;
  violation.caller = event.params.target;
  violation.selector = event.params.selector;
  violation.reason = event.params.violationType;
  violation.timestamp = event.block.timestamp;
  violation.blockNumber = event.block.number;
  violation.txHash = event.transaction.hash;
  violation.save();

  // Ensure agent entity exists
  let agent = Agent.load(agentId);
  if (agent == null) {
    agent = new Agent(agentId);
    agent.wallet = Bytes.fromHexString("0x" + "00".repeat(20));
    agent.owner = event.transaction.from;
    agent.model = "";
    agent.metadataCID = "";
    agent.parentAgentId = Bytes.fromHexString("0x" + "00".repeat(32));
    agent.status = 0;
    agent.registeredAt = event.block.timestamp;
    agent.updatedAt = event.block.timestamp;
    agent.save();
  }
}

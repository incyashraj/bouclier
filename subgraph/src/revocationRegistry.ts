import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  AgentRevoked,
  AgentReinstated,
} from "../generated/RevocationRegistry/RevocationRegistry";
import { Agent, RevocationEvent } from "../generated/schema";

export function handleAgentRevoked(event: AgentRevoked): void {
  let agentId = event.params.agentId.toHexString();

  // Upsert agent status
  let agent = Agent.load(agentId);
  if (agent != null) {
    agent.status = 2; // DEACTIVATED
    agent.updatedAt = event.block.timestamp;
    agent.save();
  }

  // Create revocation event record
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let rev = new RevocationEvent(id);
  rev.agent = agentId;
  rev.agentId = event.params.agentId;
  rev.level = event.params.reason as i32; // reason uint8 IS the RevocationLevel enum
  rev.reason = ""; // no freeform string in event
  rev.revokedBy = event.params.revokedBy;
  rev.timestamp = event.block.timestamp;
  rev.blockNumber = event.block.number;
  rev.txHash = event.transaction.hash;
  rev.save();
}

export function handleAgentReinstated(event: AgentReinstated): void {
  let agentId = event.params.agentId.toHexString();

  let agent = Agent.load(agentId);
  if (agent != null) {
    agent.status = 0; // ACTIVE
    agent.updatedAt = event.block.timestamp;
    agent.save();
  }

  // Record reinstatement as a revocation-level-0 event with level=-1 sentinel
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let rev = new RevocationEvent(id);
  rev.agent = agentId;
  rev.agentId = event.params.agentId;
  rev.level = -1; // reinstatement sentinel
  rev.reason = "";
  rev.revokedBy = event.params.reinstatedBy;
  rev.timestamp = event.block.timestamp;
  rev.blockNumber = event.block.number;
  rev.txHash = event.transaction.hash;
  rev.save();
}

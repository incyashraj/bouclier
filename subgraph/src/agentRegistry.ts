import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  AgentRegistered,
  AgentStatusUpdated,
} from "../generated/AgentRegistry/AgentRegistry";
import { Agent } from "../generated/schema";

export function handleAgentRegistered(event: AgentRegistered): void {
  let id = event.params.agentId.toHexString();
  let agent = new Agent(id);

  agent.wallet = event.params.agentAddress;
  agent.owner = event.params.owner;
  agent.model = event.params.did;
  agent.metadataCID = "";
  agent.parentAgentId = Bytes.fromHexString("0x" + "00".repeat(32));
  agent.status = 0; // ACTIVE
  agent.registeredAt = event.block.timestamp;
  agent.updatedAt = event.block.timestamp;

  agent.save();
}

export function handleAgentStatusUpdated(event: AgentStatusUpdated): void {
  let id = event.params.agentId.toHexString();
  let agent = Agent.load(id);
  if (agent == null) return;

  agent.status = event.params.newStatus;
  agent.updatedAt = event.block.timestamp;
  agent.save();
}

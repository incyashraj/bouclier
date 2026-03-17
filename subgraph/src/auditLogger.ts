import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  ActionLogged,
  IPFSCIDAdded,
} from "../generated/AuditLogger/AuditLogger";
import { Agent, AuditEvent } from "../generated/schema";

export function handleActionLogged(event: ActionLogged): void {
  let agentId = event.params.agentId.toHexString();
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  let audit = new AuditEvent(id);
  audit.agent = agentId;
  audit.agentId = event.params.agentId;
  audit.actionId = event.params.eventId;
  audit.target = event.params.target;
  audit.selector = event.params.selector;
  audit.allowed = event.params.allowed;
  audit.value = BigInt.fromI32(0); // no value field emitted
  audit.ipfsCID = null;
  audit.timestamp = event.block.timestamp;
  audit.blockNumber = event.block.number;
  audit.txHash = event.transaction.hash;
  audit.save();

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

export function handleIPFSCIDAdded(event: IPFSCIDAdded): void {
  // actionId is indexed; we stored it as id = txHash + "-" + logIndex
  // We must search by actionId field. The Graph doesn't support reverse lookup
  // without a secondary index. Store CID by creating a lookup entity keyed on actionId.
  let eventId = event.params.eventId.toHexString();

  // Update the matching AuditEvent keyed on eventId.
  let existing = AuditEvent.load(eventId);
  if (existing != null) {
    existing.ipfsCID = event.params.cid;
    existing.save();
  }
}

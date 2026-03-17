import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import { SpendRecorded } from "../generated/SpendTracker/SpendTracker";
import { Agent, SpendRecord, AgentDailySpend } from "../generated/schema";

export function handleSpendRecorded(event: SpendRecorded): void {
  let agentId = event.params.agentId.toHexString();
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  let record = new SpendRecord(id);
  let dayStart = event.block.timestamp
    .div(BigInt.fromI32(86400))
    .times(BigInt.fromI32(86400));

  record.agent = agentId;
  record.agentId = event.params.agentId;
  record.amount = event.params.usdAmount;
  record.windowStart = dayStart;
  record.timestamp = event.block.timestamp;
  record.blockNumber = event.block.number;
  record.txHash = event.transaction.hash;
  record.save();

  // Update rolling daily spend aggregate
  let windowId = agentId + "-" + dayStart.toString();
  let daily = AgentDailySpend.load(windowId);
  if (daily == null) {
    daily = new AgentDailySpend(windowId);
    daily.agentId = event.params.agentId;
    daily.windowStart = dayStart;
    daily.totalSpend = BigInt.fromI32(0);
    daily.txCount = BigInt.fromI32(0);
  }
  daily.totalSpend = daily.totalSpend.plus(event.params.usdAmount);
  daily.txCount = daily.txCount.plus(BigInt.fromI32(1));
  daily.save();

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

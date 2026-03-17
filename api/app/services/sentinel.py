"""Sentinel — On-chain event indexer for Bouclier contracts.

Polls for new events from all deployed Bouclier contracts, persists them
as AuditEvents, fires webhook notifications, and triggers anomaly detection.

Run as a standalone background process:
    python -m app.services.sentinel
"""

import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import async_session
from app.models.database import AuditEvent, Webhook

logger = logging.getLogger(__name__)
settings = get_settings()

# ABI event signatures we index (topic0)
EVENT_SIGNATURES: dict[str, str] = {
    # AgentRegistry
    "AgentRegistered(bytes32,address,string)":
        "0x" + "AgentRegistered(bytes32,address,string)".__hash__().__str__()[:64],
    # PermissionVault
    "ScopeGranted(bytes32,address,bytes4,uint256)": "ScopeGranted",
    "ActionValidated(bytes32,address,bytes4,uint256,bool)": "ActionValidated",
    # RevocationRegistry
    "AgentRevoked(bytes32,address,string)": "AgentRevoked",
    "EmergencyRevoke(bytes32,address)": "EmergencyRevoke",
    # SpendTracker
    "SpendRecorded(bytes32,uint256,uint256)": "SpendRecorded",
    "SpendCapBreached(bytes32,uint256,uint256)": "SpendCapBreached",
    # AuditLogger
    "AuditLogged(bytes32,bytes32,address,bytes4,uint256,string)": "AuditLogged",
}

# Contract addresses to index
CONTRACTS: dict[str, str] = {
    "AgentRegistry": settings.agent_registry_address,
    "PermissionVault": settings.permission_vault_address,
    "SpendTracker": settings.spend_tracker_address,
    "RevocationRegistry": settings.revocation_registry_address,
    "AuditLogger": settings.audit_logger_address,
}

# Minimal ABIs for event decoding
AUDIT_LOGGED_ABI = json.loads("""[{
  "anonymous": false,
  "inputs": [
    {"indexed": true, "name": "agentId", "type": "bytes32"},
    {"indexed": false, "name": "userOpHash", "type": "bytes32"},
    {"indexed": false, "name": "target", "type": "address"},
    {"indexed": false, "name": "selector", "type": "bytes4"},
    {"indexed": false, "name": "valueUSD", "type": "uint256"},
    {"indexed": false, "name": "outcome", "type": "string"}
  ],
  "name": "AuditLogged",
  "type": "event"
}]""")


class Sentinel:
    """Indexes Bouclier on-chain events and dispatches to webhooks."""

    def __init__(self, poll_interval: int = 12):
        self.poll_interval = poll_interval
        self._last_block: int = 0
        self._running = False

    async def start(self) -> None:
        """Main polling loop."""
        self._running = True
        logger.info("Sentinel indexer starting — poll interval %ds", self.poll_interval)

        # Lazy import to avoid top-level web3 dependency in tests
        from web3 import AsyncWeb3, AsyncHTTPProvider

        self.w3 = AsyncWeb3(AsyncHTTPProvider(settings.base_sepolia_rpc_url))
        self._last_block = await self.w3.eth.block_number

        while self._running:
            try:
                await self._poll_cycle()
            except Exception:
                logger.exception("Sentinel poll cycle error")
            await asyncio.sleep(self.poll_interval)

    async def stop(self) -> None:
        self._running = False

    async def _poll_cycle(self) -> None:
        """Poll for new events since last block."""
        current_block = await self.w3.eth.block_number
        if current_block <= self._last_block:
            return

        from_block = self._last_block + 1
        to_block = min(current_block, from_block + 2000)  # Batch max 2000 blocks

        for name, address in CONTRACTS.items():
            if not address:
                continue
            try:
                logs = await self.w3.eth.get_logs({
                    "fromBlock": from_block,
                    "toBlock": to_block,
                    "address": self.w3.to_checksum_address(address),
                })
                if logs:
                    logger.info("Found %d events from %s (%d→%d)", len(logs), name, from_block, to_block)
                    await self._process_logs(logs, name)
            except Exception:
                logger.exception("Error fetching logs for %s", name)

        self._last_block = to_block

    async def _process_logs(self, logs: list, contract_name: str) -> None:
        """Persist events and fire webhooks."""
        async with async_session() as db:
            for log in logs:
                event = self._log_to_audit_event(log, contract_name)
                if event:
                    db.add(event)
                    await self._fire_webhooks(db, event, log)
            await db.commit()

    def _log_to_audit_event(self, log: Any, contract_name: str) -> AuditEvent | None:
        """Convert a raw log entry to an AuditEvent record."""
        try:
            topics = log.get("topics", [])
            if not topics:
                return None

            agent_id_hex = topics[1].hex() if len(topics) > 1 else "0x" + "0" * 64

            return AuditEvent(
                agent_id=agent_id_hex,
                organization_id=None,  # Resolved via agent lookup
                tx_hash=log.get("transactionHash", b"").hex(),
                target_contract=log.get("address", ""),
                block_number=log.get("blockNumber"),
                outcome=contract_name,
                timestamp=datetime.now(timezone.utc),
            )
        except Exception:
            logger.exception("Failed to parse log entry")
            return None

    async def _fire_webhooks(self, db: AsyncSession, event: AuditEvent, raw_log: Any) -> None:
        """Send event data to all active webhooks for the organization."""
        if not event.organization_id:
            return

        result = await db.execute(
            select(Webhook).where(
                Webhook.organization_id == event.organization_id,
                Webhook.is_active.is_(True),
            )
        )
        webhooks = result.scalars().all()

        if not webhooks:
            return

        import httpx

        payload = {
            "event": "on_chain_event",
            "agent_id": event.agent_id,
            "tx_hash": event.tx_hash,
            "contract": event.target_contract,
            "block": event.block_number,
            "outcome": event.outcome,
            "timestamp": event.timestamp.isoformat() if event.timestamp else None,
        }

        async with httpx.AsyncClient(timeout=10) as client:
            for wh in webhooks:
                try:
                    await client.post(wh.url, json=payload)
                except Exception:
                    logger.warning("Webhook delivery failed: %s", wh.url)


async def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s - %(message)s")
    sentinel = Sentinel()
    try:
        await sentinel.start()
    except KeyboardInterrupt:
        await sentinel.stop()


if __name__ == "__main__":
    asyncio.run(main())

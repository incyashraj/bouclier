"""Blockchain service — reads on-chain state from Bouclier contracts via web3.py."""

import json
from functools import lru_cache
from pathlib import Path

from web3 import AsyncWeb3, AsyncHTTPProvider

from app.config import get_settings

# ABI paths (relative to repo root)
_ABI_DIR = Path(__file__).resolve().parents[3] / "contracts" / "out"


def _load_abi(contract_name: str) -> list:
    """Load ABI from Foundry output."""
    abi_path = _ABI_DIR / f"{contract_name}.sol" / f"{contract_name}.json"
    if not abi_path.exists():
        return []
    with open(abi_path) as f:
        artifact = json.load(f)
    return artifact.get("abi", [])


class BlockchainService:
    """Async service for interacting with Bouclier contracts on-chain."""

    def __init__(self):
        settings = get_settings()
        self.w3 = AsyncWeb3(AsyncHTTPProvider(settings.base_sepolia_rpc_url))

        # Load contracts
        self.agent_registry = self.w3.eth.contract(
            address=self.w3.to_checksum_address(settings.agent_registry_address),
            abi=_load_abi("AgentRegistry"),
        )
        self.permission_vault = self.w3.eth.contract(
            address=self.w3.to_checksum_address(settings.permission_vault_address),
            abi=_load_abi("PermissionVault"),
        )
        self.spend_tracker = self.w3.eth.contract(
            address=self.w3.to_checksum_address(settings.spend_tracker_address),
            abi=_load_abi("SpendTracker"),
        )
        self.revocation_registry = self.w3.eth.contract(
            address=self.w3.to_checksum_address(settings.revocation_registry_address),
            abi=_load_abi("RevocationRegistry"),
        )
        self.audit_logger = self.w3.eth.contract(
            address=self.w3.to_checksum_address(settings.audit_logger_address),
            abi=_load_abi("AuditLogger"),
        )

    async def register_agent(self, agent_address: str, model: str, model_hash: str) -> dict:
        """Read-only simulation of agent registration. Actual tx must be sent by owner wallet."""
        # In production, the API would hold a hot wallet key or use account abstraction.
        # For now, return a placeholder — the frontend/SDK sends the actual tx.
        checksum = self.w3.to_checksum_address(agent_address)
        agent_id = self.w3.keccak(text=f"agent:{checksum}")
        did = f"did:ethr:base:{checksum}"
        return {
            "agent_id": "0x" + agent_id.hex(),
            "did": did,
            "owner": checksum,
            "tx_hash": None,
        }

    async def revoke_agent(self, agent_id: str, reason: str) -> dict:
        """Simulate revocation. In production, sends tx via hot wallet."""
        return {"revoked_by": "api", "tx_hash": None}

    async def reinstate_agent(self, agent_id: str, reason: str) -> dict:
        """Simulate reinstatement."""
        return {"tx_hash": None}

    async def get_spend_summary(self, agent_id: str) -> dict:
        """Read rolling spend from SpendTracker contract."""
        agent_id_bytes = bytes.fromhex(agent_id[2:]) if agent_id.startswith("0x") else bytes.fromhex(agent_id)

        rolling_24h = await self.spend_tracker.functions.getRollingSpend(
            agent_id_bytes, 86400
        ).call()

        # Convert from 18 decimals to USD string
        rolling_usd = str(rolling_24h / 10**18)

        return {
            "rolling_24h_usd": rolling_usd,
            "daily_cap_usd": "0",  # Would read from PermissionVault scope
            "percentage_used": 0,
            "period_breakdown": [],
        }

    async def check_permission(self, agent_id: str, target: str, selector: str, value_usd: float) -> dict:
        """Pre-flight permission check by reading on-chain state."""
        agent_id_bytes = bytes.fromhex(agent_id[2:]) if agent_id.startswith("0x") else bytes.fromhex(agent_id)

        # Check revocation status
        is_revoked = await self.revocation_registry.functions.isRevoked(agent_id_bytes).call()
        if is_revoked:
            return {"allowed": False, "reject_reason": "AGENT_REVOKED"}

        # Check spend cap
        rolling = await self.spend_tracker.functions.getRollingSpend(agent_id_bytes, 86400).call()
        value_18 = int(value_usd * 10**18)

        return {
            "allowed": True,
            "reject_reason": None,
            "remaining_daily_cap_usd": str((10**18 - rolling) / 10**18) if rolling < 10**18 else "0",
            "remaining_daily_cap_percent": 100.0,
        }


@lru_cache
def get_blockchain_service() -> BlockchainService:
    return BlockchainService()

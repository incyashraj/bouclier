"""
bouclier_sdk — Python client for the Bouclier AI Agent Trust Layer.

Usage:
    from bouclier_sdk import BouclierClient, Addresses

    client = BouclierClient(
        rpc_url="https://sepolia.base.org",
        addresses=Addresses(
            agent_registry="0x...",
            permission_vault="0x...",
            revocation_registry="0x...",
            spend_tracker="0x...",
            audit_logger="0x...",
        ),
        private_key="0x...",   # optional, required for write operations
    )

    agent_id = client.get_agent_id("0xAgentWallet")
    scope    = client.get_active_scope(agent_id)
"""

from .client import BouclierClient
from .types import (
    Addresses,
    AgentRecord,
    AgentStatus,
    PermissionScope,
    RevocationRecord,
    AuditRecord,
    GrantScopeParams,
)

__version__ = "0.1.0"
__all__ = [
    "BouclierClient",
    "Addresses",
    "AgentRecord",
    "AgentStatus",
    "PermissionScope",
    "RevocationRecord",
    "AuditRecord",
    "GrantScopeParams",
]

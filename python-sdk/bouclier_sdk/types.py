"""Pydantic types mirroring Solidity structs from IBouclier.sol."""

from __future__ import annotations

from enum import IntEnum
from pydantic import BaseModel, Field


class AgentStatus(IntEnum):
    ACTIVE      = 0
    PAUSED      = 1
    DEACTIVATED = 2


class Addresses(BaseModel):
    """On-chain addresses for the five Bouclier contracts."""
    agent_registry:      str
    revocation_registry: str
    spend_tracker:       str
    audit_logger:        str
    permission_vault:    str


class AgentRecord(BaseModel):
    agent_id:       str           # bytes32 hex
    owner:          str           # address
    agent_wallet:   str           # address
    did:            str
    model:          str
    metadata_cid:   str
    parent_agent_id: str          # bytes32 hex
    registered_at:  int           # unix timestamp
    status:         AgentStatus
    nonce:          int


class PermissionScope(BaseModel):
    agent_id:           str       # bytes32 hex
    allowed_protocols:  list[str] # address[]
    allowed_selectors:  list[str] # bytes4[]
    allowed_tokens:     list[str] # address[]
    daily_spend_cap_usd: int      # 18-decimal USD (as int)
    per_tx_spend_cap_usd: int
    valid_from:          int      # unix timestamp
    valid_until:         int
    allow_any_protocol:  bool
    allow_any_token:     bool
    revoked:             bool
    grant_hash:          str      # bytes32 hex
    window_start_hour:   int = 0
    window_end_hour:     int = 0
    window_days_mask:    int = 0
    allowed_chain_id:    int = 0


class RevocationRecord(BaseModel):
    agent_id:     str
    revoked_at:   int
    reason:       int            # RevocationReason enum
    notes:        str
    revoked_by:   str            # address
    reinstated:   bool
    reinstate_after: int         # unix timestamp


class AuditRecord(BaseModel):
    event_id:      str           # bytes32 hex
    agent_id:      str
    action_hash:   str
    target:        str           # address
    selector:      str           # bytes4
    token_address: str           # address
    usd_amount:    int           # 18-decimal
    timestamp:     int           # unix timestamp
    allowed:       bool
    violation_type: str
    ipfs_cid:      str


class GrantScopeParams(BaseModel):
    """Parameters for building an EIP-712 signed grantPermission call."""
    agent_id:             str
    daily_spend_cap_usd:  int    # USD in 18-decimal (e.g. 1000 * 10**18)
    per_tx_spend_cap_usd: int
    valid_for_days:       int = 30
    allow_any_protocol:   bool = True
    allow_any_token:      bool = True
    allowed_protocols:    list[str] = Field(default_factory=list)
    allowed_tokens:       list[str] = Field(default_factory=list)

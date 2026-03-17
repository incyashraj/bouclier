from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


# ── Error ──────────────────────────────────────────────────────────
class ErrorDetail(BaseModel):
    code: str
    message: str
    details: dict = {}
    request_id: str | None = None


class ErrorResponse(BaseModel):
    error: ErrorDetail


# ── Agents ─────────────────────────────────────────────────────────
class AgentCreate(BaseModel):
    agent_address: str = Field(pattern=r"^0x[0-9a-fA-F]{40}$")
    model: str | None = None
    model_hash: str | None = None
    metadata: dict | None = None


class AgentResponse(BaseModel):
    agent_id: str
    did: str
    agent_address: str
    owner: str
    model: str | None
    status: str
    created_at: datetime
    updated_at: datetime
    stats: dict | None = None

    model_config = {"from_attributes": True}


class AgentListResponse(BaseModel):
    agents: list[AgentResponse]
    total: int
    page: int
    limit: int
    has_more: bool


# ── Permissions ────────────────────────────────────────────────────
class PermissionGrant(BaseModel):
    allowed_protocols: list[str] = []
    allowed_selectors: list[str] = []
    allowed_tokens: list[str] = []
    daily_spend_cap_usd: float = 0
    per_tx_spend_cap_usd: float = 0
    valid_from: datetime | None = None
    valid_until: datetime | None = None


class PermissionResponse(BaseModel):
    scope_id: str | None
    active: bool
    allowed_protocols: list[str] = []
    allowed_tokens: list[str] = []
    daily_spend_cap_usd: str
    per_tx_spend_cap_usd: str
    daily_used_usd: str
    daily_cap_remaining_usd: str
    daily_cap_percent_used: float
    valid_from: datetime | None
    valid_until: datetime | None
    created_at: datetime | None


# ── Revocation ─────────────────────────────────────────────────────
class RevokeRequest(BaseModel):
    reason: str = "suspicious"
    custom_reason: str | None = None


class RevokeResponse(BaseModel):
    revoked: bool
    revoked_at: datetime
    revoked_by: str
    tx_hash: str | None
    redis_cache_updated: bool


class ReinstateRequest(BaseModel):
    reason: str


# ── Audit ──────────────────────────────────────────────────────────
class AuditEventResponse(BaseModel):
    event_id: str
    user_op_hash: str | None
    tx_hash: str | None
    target_contract: str | None
    function_selector: str | None
    value_usd: str | None
    outcome: str
    violation_type: str | None
    block_number: int | None
    timestamp: datetime
    ipfs_cid: str | None

    model_config = {"from_attributes": True}


class AuditListResponse(BaseModel):
    events: list[AuditEventResponse]
    total: int
    has_more: bool


# ── Spend ──────────────────────────────────────────────────────────
class SpendSummary(BaseModel):
    rolling_24h_usd: str
    daily_cap_usd: str
    percentage_used: float
    period_breakdown: list[dict]


# ── Pre-flight Check ──────────────────────────────────────────────
class CheckRequest(BaseModel):
    agent_id: str
    target: str = Field(pattern=r"^0x[0-9a-fA-F]{40}$")
    selector: str = Field(pattern=r"^0x[0-9a-fA-F]{8}$")
    estimated_value_usd: float = 0
    tokens: list[str] = []


class CheckResponse(BaseModel):
    allowed: bool
    reject_reason: str | None = None
    remaining_daily_cap_usd: str | None = None
    remaining_daily_cap_percent: float | None = None


# ── Webhooks ──────────────────────────────────────────────────────
class WebhookCreate(BaseModel):
    url: str = Field(max_length=2048)
    secret: str = Field(min_length=16, max_length=255)
    events: list[str]


class WebhookResponse(BaseModel):
    id: UUID
    url: str
    events: list[str]
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Health ────────────────────────────────────────────────────────
class HealthResponse(BaseModel):
    status: str
    version: str
    chains: dict[str, str]
    subgraph: str
    redis: str
    db: str

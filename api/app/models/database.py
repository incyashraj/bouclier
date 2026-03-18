import uuid
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, Boolean, Integer, Text, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    tier: Mapped[str] = mapped_column(String(50), default="starter")  # starter, growth, enterprise
    stripe_customer_id: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    api_keys: Mapped[list["ApiKey"]] = relationship(back_populates="organization")
    agents: Mapped[list["Agent"]] = relationship(back_populates="organization")
    webhooks: Mapped[list["Webhook"]] = relationship(back_populates="organization")
    users: Mapped[list["User"]] = relationship(back_populates="organization")


class ApiKey(Base):
    __tablename__ = "api_keys"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    key_prefix: Mapped[str] = mapped_column(String(20), nullable=False)  # e.g. "bsk_live_abc1"
    key_hash: Mapped[str] = mapped_column(String(255), nullable=False)  # bcrypt hash
    label: Mapped[str] = mapped_column(String(255), default="default")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    environment: Mapped[str] = mapped_column(String(10), default="test")  # live or test
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime)

    organization: Mapped["Organization"] = relationship(back_populates="api_keys")

    __table_args__ = (Index("ix_api_keys_prefix", "key_prefix"),)


class Agent(Base):
    __tablename__ = "agents"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    agent_id: Mapped[str] = mapped_column(String(66), nullable=False, unique=True)  # bytes32 hex
    did: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    agent_address: Mapped[str] = mapped_column(String(42), nullable=False)
    owner_address: Mapped[str] = mapped_column(String(42), nullable=False)
    model: Mapped[str | None] = mapped_column(String(255))
    model_hash: Mapped[str | None] = mapped_column(String(66))
    status: Mapped[str] = mapped_column(String(20), default="active")  # active, revoked
    description: Mapped[str | None] = mapped_column(Text)
    tx_hash: Mapped[str | None] = mapped_column(String(66))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    organization: Mapped["Organization"] = relationship(back_populates="agents")

    __table_args__ = (
        Index("ix_agents_org_status", "organization_id", "status"),
        Index("ix_agents_did", "did"),
    )


class AuditEvent(Base):
    __tablename__ = "audit_events"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    agent_id: Mapped[str] = mapped_column(String(66), nullable=False, index=True)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    user_op_hash: Mapped[str | None] = mapped_column(String(66))
    tx_hash: Mapped[str | None] = mapped_column(String(66))
    target_contract: Mapped[str | None] = mapped_column(String(42))
    function_selector: Mapped[str | None] = mapped_column(String(10))
    value_usd: Mapped[str | None] = mapped_column(String(78))  # decimal string
    outcome: Mapped[str] = mapped_column(String(20), default="success")  # success, violation
    violation_type: Mapped[str | None] = mapped_column(String(50))
    block_number: Mapped[int | None] = mapped_column(Integer)
    ipfs_cid: Mapped[str | None] = mapped_column(String(100))
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        Index("ix_audit_agent_time", "agent_id", "timestamp"),
        Index("ix_audit_org_time", "organization_id", "timestamp"),
    )


class Webhook(Base):
    __tablename__ = "webhooks"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    url: Mapped[str] = mapped_column(String(2048), nullable=False)
    secret_hash: Mapped[str] = mapped_column(String(255), nullable=False)  # hashed secret
    events: Mapped[str] = mapped_column(Text, nullable=False)  # JSON array of event types
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    organization: Mapped["Organization"] = relationship(back_populates="webhooks")


class User(Base):
    """Platform user — linked to an organization via wallet address."""
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    wallet_address: Mapped[str] = mapped_column(String(42), nullable=False, unique=True)
    role: Mapped[str] = mapped_column(String(20), default="viewer")  # admin, operator, viewer
    display_name: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    organization: Mapped["Organization"] = relationship(back_populates="users")

    __table_args__ = (
        Index("ix_users_org_role", "organization_id", "role"),
        Index("ix_users_wallet", "wallet_address"),
    )


class Invite(Base):
    """Pending invitation to join an organization."""
    __tablename__ = "invites"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    invited_wallet: Mapped[str] = mapped_column(String(42), nullable=False)
    role: Mapped[str] = mapped_column(String(20), default="viewer")
    invited_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    accepted: Mapped[bool] = mapped_column(Boolean, default=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        Index("ix_invites_wallet", "invited_wallet"),
    )


class AlertRule(Base):
    """Custom alert rule — triggers a notification when metric crosses threshold."""
    __tablename__ = "alert_rules"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Metric: daily_utilization_pct | per_tx_usd | rolling_spend_usd | event_count
    metric: Mapped[str] = mapped_column(String(50), nullable=False)
    # Operator: gt | lt | gte | lte | eq
    operator: Mapped[str] = mapped_column(String(10), nullable=False, default="gt")
    threshold: Mapped[float] = mapped_column(nullable=False)
    # Severity: info | warning | critical
    severity: Mapped[str] = mapped_column(String(20), default="warning")
    notify_slack: Mapped[bool] = mapped_column(Boolean, default=False)
    notify_discord: Mapped[bool] = mapped_column(Boolean, default=False)
    # null = apply to all agents in org
    agent_id: Mapped[str | None] = mapped_column(String(66))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        Index("ix_alert_rules_org", "organization_id"),
    )


class ReportSchedule(Base):
    """Scheduled compliance report — runs on a cron expression."""
    __tablename__ = "report_schedules"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Jurisdiction: MAS | MiCA | generic
    jurisdiction: Mapped[str] = mapped_column(String(20), default="generic")
    # Format: json | csv | pdf
    format: Mapped[str] = mapped_column(String(10), default="pdf")
    # Cron expression (5-part, UTC) e.g. "0 8 * * 1" = every Monday 08:00
    cron: Mapped[str] = mapped_column(String(100), nullable=False)
    delivery_email: Mapped[str | None] = mapped_column(String(255))
    # null = all agents
    agent_id: Mapped[str | None] = mapped_column(String(66))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_run_at: Mapped[datetime | None] = mapped_column(DateTime)
    next_run_at: Mapped[datetime | None] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        Index("ix_report_schedules_org", "organization_id"),
    )

"""Alert rule management — create and list custom threshold-based alert rules."""
import uuid
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_org
from app.db import get_db
from app.models.database import AlertRule, Organization

router = APIRouter(prefix="/v1/alerts", tags=["alerts"])

VALID_METRICS = {"daily_utilization_pct", "per_tx_usd", "rolling_spend_usd", "event_count"}
VALID_OPERATORS = {"gt", "lt", "gte", "lte", "eq"}
VALID_SEVERITIES = {"info", "warning", "critical"}


class AlertRuleCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    metric: str = Field(..., description="daily_utilization_pct | per_tx_usd | rolling_spend_usd | event_count")
    operator: str = Field("gt", description="gt | lt | gte | lte | eq")
    threshold: float = Field(..., ge=0)
    severity: str = Field("warning", description="info | warning | critical")
    notify_slack: bool = False
    notify_discord: bool = False
    agent_id: str | None = Field(None, description="null = apply to all agents")


class AlertRuleResponse(BaseModel):
    id: uuid.UUID
    name: str
    metric: str
    operator: str
    threshold: float
    severity: str
    notify_slack: bool
    notify_discord: bool
    agent_id: str | None
    is_active: bool


class AlertRulePatch(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    threshold: float | None = Field(None, ge=0)
    severity: str | None = None
    notify_slack: bool | None = None
    notify_discord: bool | None = None
    is_active: bool | None = None


@router.post("/rules", response_model=AlertRuleResponse, status_code=201)
async def create_alert_rule(
    body: AlertRuleCreate,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Create a new alert rule for this organization."""
    if body.metric not in VALID_METRICS:
        raise HTTPException(status_code=422, detail={"code": "INVALID_METRIC", "valid": sorted(VALID_METRICS)})
    if body.operator not in VALID_OPERATORS:
        raise HTTPException(status_code=422, detail={"code": "INVALID_OPERATOR", "valid": sorted(VALID_OPERATORS)})
    if body.severity not in VALID_SEVERITIES:
        raise HTTPException(status_code=422, detail={"code": "INVALID_SEVERITY", "valid": sorted(VALID_SEVERITIES)})

    rule = AlertRule(
        organization_id=org.id,
        name=body.name,
        metric=body.metric,
        operator=body.operator,
        threshold=body.threshold,
        severity=body.severity,
        notify_slack=body.notify_slack,
        notify_discord=body.notify_discord,
        agent_id=body.agent_id,
    )
    db.add(rule)
    await db.commit()
    await db.refresh(rule)

    return AlertRuleResponse(
        id=rule.id, name=rule.name, metric=rule.metric, operator=rule.operator,
        threshold=rule.threshold, severity=rule.severity, notify_slack=rule.notify_slack,
        notify_discord=rule.notify_discord, agent_id=rule.agent_id, is_active=rule.is_active,
    )


@router.get("/rules", response_model=list[AlertRuleResponse])
async def list_alert_rules(
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """List all alert rules for this organization."""
    result = await db.execute(
        select(AlertRule)
        .where(AlertRule.organization_id == org.id)
        .order_by(AlertRule.created_at.desc())
    )
    rules = result.scalars().all()
    return [
        AlertRuleResponse(
            id=r.id, name=r.name, metric=r.metric, operator=r.operator,
            threshold=r.threshold, severity=r.severity, notify_slack=r.notify_slack,
            notify_discord=r.notify_discord, agent_id=r.agent_id, is_active=r.is_active,
        )
        for r in rules
    ]


@router.patch("/rules/{rule_id}", response_model=AlertRuleResponse)
async def update_alert_rule(
    rule_id: uuid.UUID,
    body: AlertRulePatch,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Update an existing alert rule."""
    result = await db.execute(
        select(AlertRule).where(AlertRule.id == rule_id, AlertRule.organization_id == org.id)
    )
    rule = result.scalar_one_or_none()
    if not rule:
        raise HTTPException(status_code=404, detail={"code": "RULE_NOT_FOUND"})

    if body.name is not None:
        rule.name = body.name
    if body.threshold is not None:
        if body.threshold < 0:
            raise HTTPException(status_code=422, detail={"code": "INVALID_THRESHOLD"})
        rule.threshold = body.threshold
    if body.severity is not None:
        if body.severity not in VALID_SEVERITIES:
            raise HTTPException(status_code=422, detail={"code": "INVALID_SEVERITY"})
        rule.severity = body.severity
    if body.notify_slack is not None:
        rule.notify_slack = body.notify_slack
    if body.notify_discord is not None:
        rule.notify_discord = body.notify_discord
    if body.is_active is not None:
        rule.is_active = body.is_active

    await db.commit()
    await db.refresh(rule)
    return AlertRuleResponse(
        id=rule.id, name=rule.name, metric=rule.metric, operator=rule.operator,
        threshold=rule.threshold, severity=rule.severity, notify_slack=rule.notify_slack,
        notify_discord=rule.notify_discord, agent_id=rule.agent_id, is_active=rule.is_active,
    )


@router.delete("/rules/{rule_id}", status_code=204)
async def delete_alert_rule(
    rule_id: uuid.UUID,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Delete an alert rule."""
    result = await db.execute(
        select(AlertRule).where(AlertRule.id == rule_id, AlertRule.organization_id == org.id)
    )
    rule = result.scalar_one_or_none()
    if not rule:
        raise HTTPException(status_code=404, detail={"code": "RULE_NOT_FOUND"})
    await db.delete(rule)
    await db.commit()

from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_org
from app.db import get_db
from app.models.database import Agent, AuditEvent, Organization
from app.models.schemas import (
    AuditEventResponse,
    AuditListResponse,
    RevokeRequest,
    RevokeResponse,
    ReinstateRequest,
    CheckRequest,
    CheckResponse,
    SpendSummary,
)
from app.services.blockchain import get_blockchain_service
from app.services.webhooks import dispatch_event

router = APIRouter(prefix="/v1/agents/{did}", tags=["agent-operations"])


# ── Revocation ────────────────────────────────────────────────────

@router.post("/revoke", response_model=RevokeResponse)
async def revoke_agent(
    did: str,
    body: RevokeRequest,
    background: BackgroundTasks,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Revoke an agent — blocks all on-chain actions immediately."""
    agent = await _get_agent_or_404(db, did, org.id)

    if agent.status == "revoked":
        raise HTTPException(status_code=403, detail={"code": "AGENT_REVOKED", "message": "Agent is already revoked"})

    blockchain = get_blockchain_service()
    result = await blockchain.revoke_agent(agent.agent_id, body.reason)

    agent.status = "revoked"
    agent.updated_at = datetime.now(timezone.utc)
    await db.commit()

    # Fire webhook in background
    background.add_task(
        dispatch_event, db, org.id, "agent.revoked",
        {"did": did, "agent_id": agent.agent_id, "reason": body.reason},
    )

    return RevokeResponse(
        revoked=True,
        revoked_at=datetime.now(timezone.utc),
        revoked_by=result.get("revoked_by", "api"),
        tx_hash=result.get("tx_hash"),
        redis_cache_updated=True,
    )


@router.post("/reinstate")
async def reinstate_agent(
    did: str,
    body: ReinstateRequest,
    background: BackgroundTasks,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Reinstate a previously revoked agent (24h timelock required)."""
    agent = await _get_agent_or_404(db, did, org.id)

    if agent.status != "revoked":
        raise HTTPException(status_code=400, detail={"code": "INVALID_SCOPE", "message": "Agent is not revoked"})

    blockchain = get_blockchain_service()
    result = await blockchain.reinstate_agent(agent.agent_id, body.reason)

    agent.status = "active"
    agent.updated_at = datetime.now(timezone.utc)
    await db.commit()

    # Fire webhook in background
    background.add_task(
        dispatch_event, db, org.id, "agent.reinstated",
        {"did": did, "agent_id": agent.agent_id, "reason": body.reason},
    )

    return {"reinstated": True, "tx_hash": result.get("tx_hash")}


# ── Audit Trail ───────────────────────────────────────────────────

@router.get("/audit", response_model=AuditListResponse)
async def get_audit_events(
    did: str,
    from_time: datetime | None = Query(None, alias="from"),
    to_time: datetime | None = Query(None, alias="to"),
    outcome: str = Query("all", pattern="^(success|violation|all)$"),
    limit: int = Query(100, ge=1, le=1000),
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Get audit trail for an agent."""
    agent = await _get_agent_or_404(db, did, org.id)

    query = select(AuditEvent).where(
        AuditEvent.agent_id == agent.agent_id,
        AuditEvent.organization_id == org.id,
    )

    if from_time:
        query = query.where(AuditEvent.timestamp >= from_time)
    if to_time:
        query = query.where(AuditEvent.timestamp <= to_time)
    if outcome != "all":
        query = query.where(AuditEvent.outcome == outcome)

    count_query = select(func.count()).select_from(
        query.subquery()
    )
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    query = query.order_by(AuditEvent.timestamp.desc()).limit(limit)
    result = await db.execute(query)
    events = result.scalars().all()

    return AuditListResponse(
        events=[
            AuditEventResponse(
                event_id=str(e.id),
                user_op_hash=e.user_op_hash,
                tx_hash=e.tx_hash,
                target_contract=e.target_contract,
                function_selector=e.function_selector,
                value_usd=e.value_usd,
                outcome=e.outcome,
                violation_type=e.violation_type,
                block_number=e.block_number,
                timestamp=e.timestamp,
                ipfs_cid=e.ipfs_cid,
            )
            for e in events
        ],
        total=total,
        has_more=total > limit,
    )


# ── Spend Analytics ───────────────────────────────────────────────

@router.get("/spend", response_model=SpendSummary)
async def get_spend_summary(
    did: str,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Get spend analytics for an agent."""
    agent = await _get_agent_or_404(db, did, org.id)

    blockchain = get_blockchain_service()
    spend_data = await blockchain.get_spend_summary(agent.agent_id)

    return SpendSummary(
        rolling_24h_usd=spend_data.get("rolling_24h_usd", "0"),
        daily_cap_usd=spend_data.get("daily_cap_usd", "0"),
        percentage_used=spend_data.get("percentage_used", 0),
        period_breakdown=spend_data.get("period_breakdown", []),
    )


# ── Pre-flight Check ─────────────────────────────────────────────

@router.post("/check", response_model=CheckResponse)
async def preflight_check(
    body: CheckRequest,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Pre-flight permission check — will this action be allowed?"""
    blockchain = get_blockchain_service()

    # Verify agent belongs to this org
    result = await db.execute(
        select(Agent).where(Agent.agent_id == body.agent_id, Agent.organization_id == org.id)
    )
    agent = result.scalar_one_or_none()
    if not agent:
        raise HTTPException(status_code=404, detail={"code": "AGENT_NOT_FOUND", "message": "Agent not found"})

    check_result = await blockchain.check_permission(
        agent_id=body.agent_id,
        target=body.target,
        selector=body.selector,
        value_usd=body.estimated_value_usd,
    )

    return CheckResponse(
        allowed=check_result["allowed"],
        reject_reason=check_result.get("reject_reason"),
        remaining_daily_cap_usd=check_result.get("remaining_daily_cap_usd"),
        remaining_daily_cap_percent=check_result.get("remaining_daily_cap_percent"),
    )


# ── Helpers ───────────────────────────────────────────────────────

async def _get_agent_or_404(db: AsyncSession, did: str, org_id) -> Agent:
    result = await db.execute(
        select(Agent).where(Agent.did == did, Agent.organization_id == org_id)
    )
    agent = result.scalar_one_or_none()
    if not agent:
        raise HTTPException(status_code=404, detail={"code": "AGENT_NOT_FOUND", "message": f"No agent with DID {did}"})
    return agent

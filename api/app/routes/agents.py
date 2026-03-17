from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_org
from app.db import get_db
from app.models.database import Agent, Organization
from app.models.schemas import AgentCreate, AgentResponse, AgentListResponse
from app.services.blockchain import get_blockchain_service

router = APIRouter(prefix="/v1/agents", tags=["agents"])


@router.post("", response_model=AgentResponse, status_code=201)
async def register_agent(
    body: AgentCreate,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Register a new AI agent on-chain and in the SaaS database."""
    blockchain = get_blockchain_service()

    # Call AgentRegistry.register() on-chain
    result = await blockchain.register_agent(
        agent_address=body.agent_address,
        model=body.model or "",
        model_hash=body.model_hash or "0x" + "0" * 64,
    )

    agent = Agent(
        organization_id=org.id,
        agent_id=result["agent_id"],
        did=result["did"],
        agent_address=body.agent_address,
        owner_address=result["owner"],
        model=body.model,
        model_hash=body.model_hash,
        description=body.metadata.get("description") if body.metadata else None,
        tx_hash=result.get("tx_hash"),
    )
    db.add(agent)
    await db.commit()
    await db.refresh(agent)

    return AgentResponse(
        agent_id=agent.agent_id,
        did=agent.did,
        agent_address=agent.agent_address,
        owner=agent.owner_address,
        model=agent.model,
        status=agent.status,
        created_at=agent.created_at,
        updated_at=agent.updated_at,
    )


@router.get("/{did}", response_model=AgentResponse)
async def get_agent(
    did: str,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Get agent details by DID."""
    result = await db.execute(
        select(Agent).where(Agent.did == did, Agent.organization_id == org.id)
    )
    agent = result.scalar_one_or_none()
    if not agent:
        raise HTTPException(status_code=404, detail={"code": "AGENT_NOT_FOUND", "message": f"No agent with DID {did}"})

    return AgentResponse(
        agent_id=agent.agent_id,
        did=agent.did,
        agent_address=agent.agent_address,
        owner=agent.owner_address,
        model=agent.model,
        status=agent.status,
        created_at=agent.created_at,
        updated_at=agent.updated_at,
    )


@router.get("", response_model=AgentListResponse)
async def list_agents(
    status: str | None = Query(None, pattern="^(active|revoked)$"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """List all agents for the authenticated organization."""
    query = select(Agent).where(Agent.organization_id == org.id)
    count_query = select(func.count()).select_from(Agent).where(Agent.organization_id == org.id)

    if status:
        query = query.where(Agent.status == status)
        count_query = count_query.where(Agent.status == status)

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    query = query.offset((page - 1) * limit).limit(limit).order_by(Agent.created_at.desc())
    result = await db.execute(query)
    agents = result.scalars().all()

    return AgentListResponse(
        agents=[
            AgentResponse(
                agent_id=a.agent_id,
                did=a.did,
                agent_address=a.agent_address,
                owner=a.owner_address,
                model=a.model,
                status=a.status,
                created_at=a.created_at,
                updated_at=a.updated_at,
            )
            for a in agents
        ],
        total=total,
        page=page,
        limit=limit,
        has_more=(page * limit) < total,
    )

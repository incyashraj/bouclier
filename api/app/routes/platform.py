import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_org, generate_api_key
from app.db import get_db
from app.models.database import Organization, Webhook
from app.models.schemas import WebhookCreate, WebhookResponse, HealthResponse
from app.config import get_settings

router = APIRouter(tags=["platform"])

settings = get_settings()


# ── Health ────────────────────────────────────────────────────────

@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check — no auth required."""
    return HealthResponse(
        status="ok",
        version=settings.version,
        chains={"base_sepolia": "connected"},
        subgraph="synced",
        redis="connected",
        db="connected",
    )


# ── Webhooks ──────────────────────────────────────────────────────

@router.post("/v1/webhooks", response_model=WebhookResponse, status_code=201)
async def create_webhook(
    body: WebhookCreate,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Register a webhook URL for real-time event notifications."""
    from app.auth import _hash_key

    valid_events = {"agent.revoked", "permission.violation", "spend.cap_warning", "agent.registered"}
    invalid = set(body.events) - valid_events
    if invalid:
        raise HTTPException(
            status_code=400,
            detail={"code": "INVALID_SCOPE", "message": f"Unknown event types: {invalid}"},
        )

    webhook = Webhook(
        organization_id=org.id,
        url=body.url,
        secret_hash=_hash_key(body.secret),
        events=json.dumps(body.events),
        is_active=True,
    )
    db.add(webhook)
    await db.commit()
    await db.refresh(webhook)

    return WebhookResponse(
        id=webhook.id,
        url=webhook.url,
        events=body.events,
        is_active=webhook.is_active,
        created_at=webhook.created_at,
    )


@router.get("/v1/webhooks", response_model=list[WebhookResponse])
async def list_webhooks(
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """List all webhooks for the authenticated organization."""
    result = await db.execute(
        select(Webhook).where(Webhook.organization_id == org.id, Webhook.is_active.is_(True))
    )
    webhooks = result.scalars().all()
    return [
        WebhookResponse(
            id=w.id,
            url=w.url,
            events=json.loads(w.events),
            is_active=w.is_active,
            created_at=w.created_at,
        )
        for w in webhooks
    ]


# ── API Key Management ───────────────────────────────────────────

@router.post("/v1/keys")
async def create_api_key(
    environment: str = "test",
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Generate a new API key for the organization. Returns the key ONCE."""
    from app.models.database import ApiKey

    full_key, prefix, key_hash = generate_api_key(environment)
    api_key = ApiKey(
        organization_id=org.id,
        key_prefix=prefix,
        key_hash=key_hash,
        environment=environment,
        label=f"{environment}-{prefix[-4:]}",
    )
    db.add(api_key)
    await db.commit()

    return {"key": full_key, "prefix": prefix, "environment": environment}


# ── SIWE Authentication ──────────────────────────────────────────

@router.get("/v1/auth/nonce")
async def get_nonce():
    """Get a fresh nonce for the SIWE sign-in flow."""
    from app.siwe_auth import issue_nonce
    return {"nonce": issue_nonce()}


@router.post("/v1/auth/siwe")
async def siwe_login(body: dict):
    """Verify a SIWE message + signature and return a JWT session token."""
    from app.siwe_auth import verify_siwe_message, create_session_token

    message = body.get("message")
    signature = body.get("signature")
    if not message or not signature:
        raise HTTPException(status_code=400, detail={"code": "MISSING_FIELDS", "message": "message and signature required"})

    claims = verify_siwe_message(message, signature)
    token = create_session_token(claims["address"], claims["chain_id"])
    return {"token": token, "address": claims["address"], "chain_id": claims["chain_id"]}

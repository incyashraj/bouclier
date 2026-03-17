"""Billing routes — Stripe checkout, portal, and webhooks."""

import hmac
import hashlib
import logging

import stripe
from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel, HttpUrl
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import get_db
from app.services import billing

logger = logging.getLogger(__name__)
settings = get_settings()

router = APIRouter(prefix="/v1/billing", tags=["billing"])


# ── Request / Response schemas ─────────────────────────────────────

class CheckoutRequest(BaseModel):
    org_id: str
    tier: str  # "growth" or "enterprise"
    success_url: HttpUrl
    cancel_url: HttpUrl


class CheckoutResponse(BaseModel):
    checkout_url: str


class PortalRequest(BaseModel):
    org_id: str
    return_url: HttpUrl


class PortalResponse(BaseModel):
    portal_url: str


# ── Endpoints ──────────────────────────────────────────────────────

@router.post("/checkout", response_model=CheckoutResponse)
async def create_checkout(body: CheckoutRequest, db: AsyncSession = Depends(get_db)):
    """Create a Stripe Checkout session for upgrading."""
    try:
        url = await billing.create_checkout_session(
            db, body.org_id, body.tier, str(body.success_url), str(body.cancel_url)
        )
        return CheckoutResponse(checkout_url=url)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/portal", response_model=PortalResponse)
async def create_portal(body: PortalRequest, db: AsyncSession = Depends(get_db)):
    """Create a Stripe Customer Portal session."""
    try:
        url = await billing.create_portal_session(db, body.org_id, str(body.return_url))
        return PortalResponse(portal_url=url)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/webhook")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(alias="stripe-signature"),
    db: AsyncSession = Depends(get_db),
):
    """Receive Stripe webhook events (signature-verified)."""
    payload = await request.body()
    endpoint_secret = settings.stripe_webhook_secret

    try:
        event = stripe.Webhook.construct_event(payload, stripe_signature, endpoint_secret)
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    await billing.handle_webhook_event(db, event)
    return {"received": True}

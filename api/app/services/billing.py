"""Stripe billing integration for Bouclier SaaS tiers."""

import logging
from typing import Any

import stripe
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.database import Organization

logger = logging.getLogger(__name__)
settings = get_settings()

stripe.api_key = settings.stripe_secret_key

# Price IDs set in env — map tier name → Stripe price ID
TIER_PRICES: dict[str, str] = {
    "growth": settings.stripe_price_growth,
    "enterprise": settings.stripe_price_enterprise,
}


async def create_checkout_session(
    db: AsyncSession, org_id: str, tier: str, success_url: str, cancel_url: str
) -> str:
    """Create a Stripe Checkout session for upgrading an org's tier."""
    price_id = TIER_PRICES.get(tier)
    if not price_id:
        raise ValueError(f"Unknown tier: {tier}")

    org = await db.get(Organization, org_id)
    if not org:
        raise ValueError("Organization not found")

    params: dict[str, Any] = {
        "mode": "subscription",
        "line_items": [{"price": price_id, "quantity": 1}],
        "success_url": success_url,
        "cancel_url": cancel_url,
        "metadata": {"org_id": str(org.id), "tier": tier},
    }

    if org.stripe_customer_id:
        params["customer"] = org.stripe_customer_id
    else:
        params["customer_email"] = None  # Let Stripe collect email

    session = stripe.checkout.Session.create(**params)
    return session.url


async def create_portal_session(db: AsyncSession, org_id: str, return_url: str) -> str:
    """Create a Stripe Customer Portal session for managing subscriptions."""
    org = await db.get(Organization, org_id)
    if not org or not org.stripe_customer_id:
        raise ValueError("No billing account found")

    session = stripe.billing_portal.Session.create(
        customer=org.stripe_customer_id,
        return_url=return_url,
    )
    return session.url


async def handle_webhook_event(db: AsyncSession, event: stripe.Event) -> None:
    """Process Stripe webhook events to sync subscription state."""
    event_type = event["type"]

    if event_type == "checkout.session.completed":
        session = event["data"]["object"]
        org_id = session["metadata"].get("org_id")
        tier = session["metadata"].get("tier", "growth")
        customer_id = session.get("customer")

        if org_id:
            org = await db.get(Organization, org_id)
            if org:
                org.stripe_customer_id = customer_id
                org.tier = tier
                await db.commit()
                logger.info("Org %s upgraded to %s", org_id, tier)

    elif event_type == "customer.subscription.deleted":
        sub = event["data"]["object"]
        customer_id = sub["customer"]
        result = await db.execute(
            select(Organization).where(Organization.stripe_customer_id == customer_id)
        )
        org = result.scalar_one_or_none()
        if org:
            org.tier = "starter"
            await db.commit()
            logger.info("Org %s downgraded to starter (subscription cancelled)", org.id)

    elif event_type == "customer.subscription.updated":
        sub = event["data"]["object"]
        customer_id = sub["customer"]
        result = await db.execute(
            select(Organization).where(Organization.stripe_customer_id == customer_id)
        )
        org = result.scalar_one_or_none()
        if org and sub["status"] == "active":
            # Check if plan changed
            price_id = sub["items"]["data"][0]["price"]["id"]
            for tier_name, pid in TIER_PRICES.items():
                if pid == price_id:
                    org.tier = tier_name
                    await db.commit()
                    logger.info("Org %s tier updated to %s", org.id, tier_name)
                    break

    elif event_type == "invoice.payment_failed":
        invoice = event["data"]["object"]
        customer_id = invoice["customer"]
        logger.warning("Payment failed for Stripe customer %s", customer_id)

"""Webhook delivery service — dispatches events to registered webhook URLs."""

import hashlib
import hmac
import json
import logging
from datetime import datetime, timezone

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.database import Webhook

logger = logging.getLogger("bouclier.webhooks")

# Supported event types
EVENT_TYPES = {
    "agent.registered",
    "agent.revoked",
    "agent.reinstated",
    "permission.granted",
    "permission.violation",
    "spend.cap_warning",
    "spend.cap_exceeded",
    "audit.event",
}

# Delivery timeout per attempt
TIMEOUT_SECONDS = 10
MAX_RETRIES = 3
RETRY_DELAYS = [1, 5, 30]  # seconds between retries


def _sign_payload(payload_bytes: bytes, secret: str) -> str:
    """Compute HMAC-SHA256 signature for webhook payload."""
    return hmac.new(secret.encode(), payload_bytes, hashlib.sha256).hexdigest()


async def dispatch_event(
    db: AsyncSession,
    org_id: str,
    event_type: str,
    payload: dict,
) -> list[dict]:
    """Deliver a webhook event to all matching endpoints for an organization.

    Returns a list of delivery results (url, status_code, success).
    """
    if event_type not in EVENT_TYPES:
        logger.warning("Unknown event type: %s", event_type)
        return []

    result = await db.execute(
        select(Webhook).where(
            Webhook.organization_id == org_id,
            Webhook.is_active.is_(True),
        )
    )
    webhooks = result.scalars().all()

    results = []
    for wh in webhooks:
        # Check if this webhook subscribes to this event
        try:
            subscribed_events = json.loads(wh.events) if isinstance(wh.events, str) else wh.events
        except (json.JSONDecodeError, TypeError):
            subscribed_events = []

        if event_type not in subscribed_events:
            continue

        delivery = await _deliver(wh, event_type, payload)
        results.append(delivery)

    return results


async def _deliver(webhook: Webhook, event_type: str, payload: dict) -> dict:
    """Attempt delivery with retries."""
    body = {
        "event": event_type,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "data": payload,
    }
    body_bytes = json.dumps(body, default=str).encode()

    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Bouclier-Webhook/1.0",
        "X-Bouclier-Event": event_type,
    }

    # Sign if webhook has a secret
    if webhook.secret_hash:
        # Use the first 32 chars of the hash as the signing key
        # (actual secret is not stored — we use the hash deterministically)
        headers["X-Bouclier-Signature"] = f"sha256={_sign_payload(body_bytes, webhook.secret_hash[:32])}"

    for attempt in range(MAX_RETRIES):
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                resp = await client.post(
                    str(webhook.url),
                    content=body_bytes,
                    headers=headers,
                )
                if resp.status_code < 300:
                    return {"url": webhook.url, "status_code": resp.status_code, "success": True, "attempt": attempt + 1}

                logger.warning(
                    "Webhook delivery failed (attempt %d/%d): %s → %d",
                    attempt + 1,
                    MAX_RETRIES,
                    webhook.url,
                    resp.status_code,
                )
        except Exception as exc:
            logger.warning(
                "Webhook delivery error (attempt %d/%d): %s → %s",
                attempt + 1,
                MAX_RETRIES,
                webhook.url,
                str(exc),
            )

        # Wait before retry (except on last attempt)
        if attempt < MAX_RETRIES - 1:
            import asyncio

            await asyncio.sleep(RETRY_DELAYS[attempt])

    return {"url": webhook.url, "status_code": None, "success": False, "attempt": MAX_RETRIES}

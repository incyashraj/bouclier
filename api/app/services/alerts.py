"""Slack & Discord alert service — sends real-time notifications for critical events."""

import json
import logging
from datetime import datetime, timezone

import httpx

from app.config import get_settings

logger = logging.getLogger("bouclier.alerts")

TIMEOUT_SECONDS = 10

# Severity → color mapping
COLORS = {
    "critical": "#FF451A",
    "warning": "#FFA500",
    "info": "#36A2EB",
}


async def send_alert(
    event_type: str,
    payload: dict,
    severity: str = "info",
) -> dict[str, bool]:
    """Send alert to configured Slack and/or Discord webhooks.

    Returns dict of {"slack": bool, "discord": bool} indicating delivery success.
    """
    settings = get_settings()
    results: dict[str, bool] = {}

    if settings.slack_webhook_url:
        results["slack"] = await _send_slack(
            settings.slack_webhook_url, event_type, payload, severity
        )
    if settings.discord_webhook_url:
        results["discord"] = await _send_discord(
            settings.discord_webhook_url, event_type, payload, severity
        )

    return results


async def _send_slack(url: str, event_type: str, payload: dict, severity: str) -> bool:
    """Send a Slack incoming webhook message."""
    color = COLORS.get(severity, COLORS["info"])
    fields = [
        {"title": k, "value": str(v)[:256], "short": len(str(v)) < 40}
        for k, v in list(payload.items())[:10]
    ]

    message = {
        "attachments": [
            {
                "color": color,
                "title": f"Bouclier Alert — {event_type}",
                "fields": fields,
                "footer": "Bouclier Protocol",
                "ts": int(datetime.now(timezone.utc).timestamp()),
            }
        ]
    }

    try:
        async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
            resp = await client.post(url, json=message)
            if resp.status_code == 200:
                return True
            logger.warning("Slack alert failed: %d %s", resp.status_code, resp.text[:200])
    except Exception as exc:
        logger.error("Slack alert error: %s", exc)
    return False


async def _send_discord(url: str, event_type: str, payload: dict, severity: str) -> bool:
    """Send a Discord webhook embed."""
    color_hex = COLORS.get(severity, COLORS["info"]).lstrip("#")
    color_int = int(color_hex, 16)

    fields = [
        {"name": k, "value": str(v)[:256], "inline": len(str(v)) < 40}
        for k, v in list(payload.items())[:10]
    ]

    message = {
        "embeds": [
            {
                "title": f"Bouclier Alert — {event_type}",
                "color": color_int,
                "fields": fields,
                "footer": {"text": "Bouclier Protocol"},
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        ]
    }

    try:
        async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
            resp = await client.post(url, json=message)
            if resp.status_code in (200, 204):
                return True
            logger.warning("Discord alert failed: %d %s", resp.status_code, resp.text[:200])
    except Exception as exc:
        logger.error("Discord alert error: %s", exc)
    return False


# Convenience helpers for common alert types

async def alert_agent_revoked(agent_id: str, reason: str, tx_hash: str = "") -> dict[str, bool]:
    return await send_alert("agent.revoked", {
        "Agent ID": agent_id,
        "Reason": reason,
        "Tx Hash": tx_hash or "N/A",
    }, severity="critical")


async def alert_spend_cap_exceeded(agent_id: str, amount_usd: str, cap_usd: str) -> dict[str, bool]:
    return await send_alert("spend.cap_exceeded", {
        "Agent ID": agent_id,
        "Attempted": f"${amount_usd}",
        "Daily Cap": f"${cap_usd}",
    }, severity="critical")


async def alert_permission_violation(agent_id: str, target: str, violation_type: str) -> dict[str, bool]:
    return await send_alert("permission.violation", {
        "Agent ID": agent_id,
        "Target Contract": target,
        "Violation": violation_type,
    }, severity="warning")

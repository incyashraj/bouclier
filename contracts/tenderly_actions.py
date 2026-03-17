"""Tenderly Web3 Actions — alert handler for Bouclier on-chain events.

This script is deployed as a Tenderly Action. It receives transaction events
from Tenderly alerts and forwards them to the Bouclier API alert system.

Setup:
  1. Install tenderly CLI: npm i -g @tenderly/actions-cli
  2. Run: tenderly actions init
  3. Copy this file to actions/
  4. Deploy: tenderly actions deploy
"""

import json
import os
from datetime import datetime, timezone

import requests

BOUCLIER_API_URL = os.environ.get("BOUCLIER_API_URL", "https://api.bouclier.xyz")
BOUCLIER_API_KEY = os.environ.get("BOUCLIER_API_KEY", "")
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

# Event signatures for decoding
EVENT_SIGS = {
    "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0": "OwnershipTransferred",
    # AgentRegistry
    "AgentRegistered": "agent.registered",
    # RevocationRegistry
    "AgentRevoked": "agent.revoked",
    "AgentReinstated": "agent.reinstated",
    # PermissionVault
    "PermissionGranted": "permission.granted",
    "ValidationFailed": "permission.violation",
    "EmergencyRevoke": "agent.revoked",
    # SpendTracker
    "SpendRecorded": "spend.recorded",
    "SpendCapExceeded": "spend.cap_exceeded",
}


def on_transaction(context, event):
    """Tenderly Action entry point — called on matching transactions."""
    tx = event.get("transaction", {})
    tx_hash = tx.get("hash", "unknown")
    logs = tx.get("logs", [])

    alerts = []
    for log in logs:
        event_name = log.get("name", "")
        if event_name in EVENT_SIGS:
            alert_type = EVENT_SIGS[event_name]
            severity = _get_severity(alert_type)
            alerts.append({
                "event_type": alert_type,
                "severity": severity,
                "tx_hash": tx_hash,
                "block_number": tx.get("block_number"),
                "contract": log.get("address", ""),
                "event_name": event_name,
                "data": log.get("inputs", {}),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            })

    for alert in alerts:
        _send_to_api(alert)
        if alert["severity"] in ("critical", "high"):
            _send_to_slack(alert)


def _get_severity(alert_type: str) -> str:
    severity_map = {
        "agent.revoked": "critical",
        "spend.cap_exceeded": "critical",
        "permission.violation": "high",
        "spend.recorded": "low",
        "agent.registered": "info",
        "agent.reinstated": "info",
        "permission.granted": "info",
    }
    return severity_map.get(alert_type, "info")


def _send_to_api(alert: dict):
    """Forward alert to Bouclier API."""
    if not BOUCLIER_API_KEY:
        return
    try:
        requests.post(
            f"{BOUCLIER_API_URL}/v1/alerts/ingest",
            json=alert,
            headers={
                "X-Bouclier-API-Key": BOUCLIER_API_KEY,
                "Content-Type": "application/json",
            },
            timeout=10,
        )
    except Exception:
        pass  # Tenderly will log the failure


def _send_to_slack(alert: dict):
    """Send critical/high alerts directly to Slack."""
    if not SLACK_WEBHOOK_URL:
        return

    color = "#FF451A" if alert["severity"] == "critical" else "#FFA500"

    message = {
        "attachments": [{
            "color": color,
            "title": f"Bouclier Alert — {alert['event_type']}",
            "fields": [
                {"title": "Severity", "value": alert["severity"].upper(), "short": True},
                {"title": "Event", "value": alert["event_name"], "short": True},
                {"title": "Tx Hash", "value": alert["tx_hash"][:16] + "...", "short": True},
                {"title": "Contract", "value": alert["contract"][:16] + "...", "short": True},
            ],
            "footer": "Bouclier × Tenderly",
            "ts": int(datetime.now(timezone.utc).timestamp()),
        }]
    }

    try:
        requests.post(SLACK_WEBHOOK_URL, json=message, timeout=10)
    except Exception:
        pass

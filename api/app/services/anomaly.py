"""Anomaly detection service — statistical detection of unusual agent behavior.

Approach: Z-score based detection against each agent's historical baseline.
Flags anomalies when current behavior deviates significantly from the agent's
rolling mean (configurable window, default 7 days).

Anomaly types:
  - spend_spike: Single transaction > 3σ above agent's average spend
  - frequency_spike: Transaction count in 1h window > 3σ above hourly average
  - new_target: Agent interacts with a contract never seen in its history
  - velocity_spike: USD/hour spend rate > 3σ above historical rate
"""

import logging
import math
from datetime import datetime, timezone, timedelta

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.database import AuditEvent

logger = logging.getLogger("bouclier.anomaly")

# Detection thresholds
Z_THRESHOLD = 3.0  # standard deviations
LOOKBACK_DAYS = 7
MIN_SAMPLES = 5  # need at least N data points to compute meaningful stats


async def detect_anomalies(
    db: AsyncSession,
    org_id: str,
    agent_id: str,
    current_event: dict,
) -> list[dict]:
    """Run anomaly checks against an agent's historical baseline.

    Args:
        db: Database session
        org_id: Organization ID
        agent_id: Agent ID (bytes32 hex)
        current_event: Dict with keys: value_usd, target_contract, timestamp

    Returns:
        List of anomaly dicts: [{type, severity, score, message, details}]
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=LOOKBACK_DAYS)
    anomalies = []

    # Fetch historical events for this agent
    result = await db.execute(
        select(AuditEvent).where(
            AuditEvent.agent_id == agent_id,
            AuditEvent.organization_id == org_id,
            AuditEvent.timestamp >= cutoff,
            AuditEvent.outcome == "success",
        ).order_by(AuditEvent.timestamp.asc())
    )
    history = result.scalars().all()

    if len(history) < MIN_SAMPLES:
        return anomalies  # not enough data for statistical analysis

    # --- Spend spike detection ---
    spend_anomaly = _check_spend_spike(history, current_event)
    if spend_anomaly:
        anomalies.append(spend_anomaly)

    # --- Frequency spike detection ---
    freq_anomaly = _check_frequency_spike(history, current_event)
    if freq_anomaly:
        anomalies.append(freq_anomaly)

    # --- New target detection ---
    target_anomaly = _check_new_target(history, current_event)
    if target_anomaly:
        anomalies.append(target_anomaly)

    # --- Velocity spike detection ---
    velocity_anomaly = _check_velocity_spike(history, current_event)
    if velocity_anomaly:
        anomalies.append(velocity_anomaly)

    return anomalies


def _check_spend_spike(history: list, event: dict) -> dict | None:
    """Detect if current transaction value is abnormally high."""
    values = [float(e.value_usd or 0) for e in history if e.value_usd]
    if len(values) < MIN_SAMPLES:
        return None

    current_value = float(event.get("value_usd", 0))
    if current_value == 0:
        return None

    mean, std = _mean_std(values)
    if std == 0:
        return None

    z_score = (current_value - mean) / std
    if z_score > Z_THRESHOLD:
        return {
            "type": "spend_spike",
            "severity": "high" if z_score > 5 else "medium",
            "z_score": round(z_score, 2),
            "message": f"Transaction ${current_value:.2f} is {z_score:.1f}σ above agent average ${mean:.2f}",
            "details": {
                "current_value": current_value,
                "mean": round(mean, 2),
                "std": round(std, 2),
                "threshold_sigma": Z_THRESHOLD,
            },
        }
    return None


def _check_frequency_spike(history: list, event: dict) -> dict | None:
    """Detect if transaction frequency in the last hour is abnormally high."""
    now = datetime.now(timezone.utc)
    one_hour_ago = now - timedelta(hours=1)

    # Count transactions per hour historically
    hourly_counts: dict[str, int] = {}
    for e in history:
        hour_key = e.timestamp.strftime("%Y-%m-%d-%H")
        hourly_counts[hour_key] = hourly_counts.get(hour_key, 0) + 1

    counts = list(hourly_counts.values())
    if len(counts) < MIN_SAMPLES:
        return None

    # Count current hour
    current_hour_count = sum(1 for e in history if e.timestamp >= one_hour_ago) + 1

    mean, std = _mean_std(counts)
    if std == 0:
        return None

    z_score = (current_hour_count - mean) / std
    if z_score > Z_THRESHOLD:
        return {
            "type": "frequency_spike",
            "severity": "medium",
            "z_score": round(z_score, 2),
            "message": f"{current_hour_count} txns in last hour vs avg {mean:.1f}/hour ({z_score:.1f}σ)",
            "details": {
                "current_count": current_hour_count,
                "mean_hourly": round(mean, 2),
                "std_hourly": round(std, 2),
            },
        }
    return None


def _check_new_target(history: list, event: dict) -> dict | None:
    """Detect interaction with a never-before-seen contract."""
    target = event.get("target_contract", "")
    if not target:
        return None

    historical_targets = {e.target_contract for e in history if e.target_contract}
    if target not in historical_targets and len(historical_targets) > 0:
        return {
            "type": "new_target",
            "severity": "low",
            "z_score": 0,
            "message": f"First interaction with contract {target[:10]}...{target[-4:]}",
            "details": {
                "new_target": target,
                "known_targets": len(historical_targets),
            },
        }
    return None


def _check_velocity_spike(history: list, event: dict) -> dict | None:
    """Detect if USD/hour spend rate is abnormally high."""
    if len(history) < MIN_SAMPLES:
        return None

    # Compute hourly spend rates
    hourly_spend: dict[str, float] = {}
    for e in history:
        hour_key = e.timestamp.strftime("%Y-%m-%d-%H")
        hourly_spend[hour_key] = hourly_spend.get(hour_key, 0) + float(e.value_usd or 0)

    rates = list(hourly_spend.values())
    if len(rates) < MIN_SAMPLES:
        return None

    # Current hour rate
    now = datetime.now(timezone.utc)
    one_hour_ago = now - timedelta(hours=1)
    current_rate = sum(float(e.value_usd or 0) for e in history if e.timestamp >= one_hour_ago)
    current_rate += float(event.get("value_usd", 0))

    mean, std = _mean_std(rates)
    if std == 0:
        return None

    z_score = (current_rate - mean) / std
    if z_score > Z_THRESHOLD:
        return {
            "type": "velocity_spike",
            "severity": "high" if z_score > 5 else "medium",
            "z_score": round(z_score, 2),
            "message": f"Spend rate ${current_rate:.2f}/hr is {z_score:.1f}σ above avg ${mean:.2f}/hr",
            "details": {
                "current_rate_usd_hr": round(current_rate, 2),
                "mean_rate": round(mean, 2),
                "std_rate": round(std, 2),
            },
        }
    return None


def _mean_std(values: list[float]) -> tuple[float, float]:
    """Compute mean and standard deviation."""
    n = len(values)
    if n == 0:
        return 0.0, 0.0
    mean = sum(values) / n
    variance = sum((x - mean) ** 2 for x in values) / n
    return mean, math.sqrt(variance)

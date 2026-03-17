"""API tests — uses SQLite in-memory for fast testing without PostgreSQL."""

import asyncio
import uuid
from datetime import datetime

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import StaticPool
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.models.database import Base, Organization, ApiKey, Agent, AuditEvent
from app.db import get_db
from app.auth import get_current_org
from app.main import app

# Use aiosqlite for testing (no PG dependency)
TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def test_db():
    engine = create_async_engine(TEST_DB_URL, connect_args={"check_same_thread": False}, poolclass=StaticPool)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def test_org(test_db: AsyncSession):
    org = Organization(name="Test Corp", tier="enterprise")
    test_db.add(org)
    await test_db.commit()
    await test_db.refresh(org)
    return org


@pytest_asyncio.fixture
async def test_agent(test_db: AsyncSession, test_org: Organization):
    agent = Agent(
        organization_id=test_org.id,
        agent_id="0x" + "ab" * 32,
        did="did:ethr:base:0x1234567890abcdef1234567890abcdef12345678",
        agent_address="0x1234567890abcdef1234567890abcdef12345678",
        owner_address="0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
        model="claude-sonnet-4-6",
        status="active",
    )
    test_db.add(agent)
    await test_db.commit()
    await test_db.refresh(agent)
    return agent


@pytest_asyncio.fixture
async def test_events(test_db: AsyncSession, test_org: Organization, test_agent: Agent):
    events = []
    for i in range(5):
        event = AuditEvent(
            agent_id=test_agent.agent_id,
            organization_id=test_org.id,
            tx_hash=f"0x{'0' * 63}{i}",
            target_contract="0x" + "11" * 20,
            function_selector="0x04e45aaf",
            value_usd=f"{100 * (i + 1)}.00",
            outcome="success" if i < 4 else "violation",
            violation_type="DAILY_CAP_EXCEEDED" if i == 4 else None,
            block_number=1000 + i,
            timestamp=datetime(2026, 3, 17, 10 + i, 0, 0),
        )
        test_db.add(event)
        events.append(event)
    await test_db.commit()
    return events


@pytest_asyncio.fixture
async def client(test_db: AsyncSession, test_org: Organization):
    """HTTP client with auth bypassed — org injected directly."""

    async def override_db():
        yield test_db

    async def override_org():
        return test_org

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_org] = override_org

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


# ── Health ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_health(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["version"] == "0.1.0"


# ── Agents ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_list_agents_empty(client: AsyncClient):
    resp = await client.get("/v1/agents")
    assert resp.status_code == 200
    data = resp.json()
    assert data["agents"] == []
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_list_agents_with_data(client: AsyncClient, test_agent: Agent):
    resp = await client.get("/v1/agents")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 1
    assert data["agents"][0]["did"] == test_agent.did


@pytest.mark.asyncio
async def test_get_agent(client: AsyncClient, test_agent: Agent):
    resp = await client.get(f"/v1/agents/{test_agent.did}")
    assert resp.status_code == 200
    data = resp.json()
    assert data["did"] == test_agent.did
    assert data["status"] == "active"
    assert data["model"] == "claude-sonnet-4-6"


@pytest.mark.asyncio
async def test_get_agent_not_found(client: AsyncClient):
    resp = await client.get("/v1/agents/did:ethr:base:0xNONEXISTENT")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_list_agents_filter_status(client: AsyncClient, test_agent: Agent):
    resp = await client.get("/v1/agents?status=revoked")
    assert resp.status_code == 200
    assert resp.json()["total"] == 0


# ── Audit Trail ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_audit_events(client: AsyncClient, test_agent: Agent, test_events):
    resp = await client.get(
        f"/v1/agents/{test_agent.did}/audit",
        params={"from": "2026-03-17T00:00:00", "to": "2026-03-18T00:00:00"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 5
    assert len(data["events"]) == 5


@pytest.mark.asyncio
async def test_audit_violations_only(client: AsyncClient, test_agent: Agent, test_events):
    resp = await client.get(
        f"/v1/agents/{test_agent.did}/audit",
        params={"from": "2026-03-17T00:00:00", "to": "2026-03-18T00:00:00", "outcome": "violation"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 1
    assert data["events"][0]["violation_type"] == "DAILY_CAP_EXCEEDED"


# ── Compliance ────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_compliance_report_mas(client: AsyncClient, test_agent: Agent, test_events):
    resp = await client.get(
        "/v1/compliance/report",
        params={
            "jurisdiction": "MAS",
            "from": "2026-03-17T00:00:00",
            "to": "2026-03-18T00:00:00",
            "format": "json",
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["report_type"] == "MAS_FAA_N16"
    assert data["summary"]["total_agents"] == 1
    assert data["summary"]["total_actions"] == 5
    assert data["summary"]["total_violations"] == 1
    assert len(data["action_log"]) == 5
    assert "disclaimer" in data


@pytest.mark.asyncio
async def test_compliance_report_mica(client: AsyncClient, test_agent: Agent, test_events):
    resp = await client.get(
        "/v1/compliance/report",
        params={
            "jurisdiction": "MiCA",
            "from": "2026-03-17T00:00:00",
            "to": "2026-03-18T00:00:00",
            "format": "json",
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["report_type"] == "MiCA_Article_38"
    assert data["summary"]["total_agents"] == 1
    assert len(data["compliance_violations"]) == 1


@pytest.mark.asyncio
async def test_compliance_report_csv(client: AsyncClient, test_agent: Agent, test_events):
    resp = await client.get(
        "/v1/compliance/report",
        params={
            "jurisdiction": "MAS",
            "from": "2026-03-17T00:00:00",
            "to": "2026-03-18T00:00:00",
            "format": "csv",
        },
    )
    assert resp.status_code == 200
    assert "text/csv" in resp.headers["content-type"]
    assert "timestamp" in resp.text  # CSV header


# ── Webhooks ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_webhook(client: AsyncClient):
    resp = await client.post(
        "/v1/webhooks",
        json={
            "url": "https://example.com/hook",
            "secret": "a-very-secure-secret-key",
            "events": ["agent.revoked", "permission.violation"],
        },
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["url"] == "https://example.com/hook"
    assert set(data["events"]) == {"agent.revoked", "permission.violation"}


@pytest.mark.asyncio
async def test_create_webhook_invalid_events(client: AsyncClient):
    resp = await client.post(
        "/v1/webhooks",
        json={
            "url": "https://example.com/hook",
            "secret": "a-very-secure-secret-key",
            "events": ["invalid.event"],
        },
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_list_webhooks_empty(client: AsyncClient):
    resp = await client.get("/v1/webhooks")
    assert resp.status_code == 200
    assert resp.json() == []


# ── Middleware ────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_request_id_generated(client: AsyncClient):
    """Verify X-Request-ID is in response headers."""
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert "x-request-id" in resp.headers
    # Should be a valid UUID
    uuid.UUID(resp.headers["x-request-id"])


@pytest.mark.asyncio
async def test_request_id_passthrough(client: AsyncClient):
    """If client sends X-Request-ID, server echoes it back."""
    custom_id = "custom-request-12345"
    resp = await client.get("/health", headers={"X-Request-ID": custom_id})
    assert resp.status_code == 200
    assert resp.headers["x-request-id"] == custom_id


# ── Webhook Dispatch ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_webhook_event_types():
    """Verify all expected event types are in the set."""
    from app.services.webhooks import EVENT_TYPES

    assert "agent.registered" in EVENT_TYPES
    assert "agent.revoked" in EVENT_TYPES
    assert "agent.reinstated" in EVENT_TYPES
    assert "permission.violation" in EVENT_TYPES
    assert "spend.cap_exceeded" in EVENT_TYPES


@pytest.mark.asyncio
async def test_webhook_dispatch_no_subscribers(test_db: AsyncSession, test_org: Organization):
    """dispatch_event returns empty list when no webhooks exist."""
    from app.services.webhooks import dispatch_event

    results = await dispatch_event(test_db, test_org.id, "agent.revoked", {"test": True})
    assert results == []


@pytest.mark.asyncio
async def test_webhook_dispatch_unknown_event(test_db: AsyncSession, test_org: Organization):
    """dispatch_event returns empty list for unknown event types."""
    from app.services.webhooks import dispatch_event

    results = await dispatch_event(test_db, test_org.id, "unknown.event", {})
    assert results == []

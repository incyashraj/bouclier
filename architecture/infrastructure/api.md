# REST API — Architecture & Endpoint Reference

> **Framework:** FastAPI 0.110+ (Python 3.12)  
> **Database:** PostgreSQL 16 (primary) + The Graph (real-time events)  
> **Cache:** Redis 7 (revocation state, rate limiting, session cache)  
> **Auth:** API key (header: `X-Bouclier-API-Key`) + JWT for dashboard sessions  
> **Base URL:** `https://api.bouclier.xyz/v1`

---

## Authentication

All API endpoints (except `/health`) require:

```http
X-Bouclier-API-Key: bsk_live_xxxxxxxxxxxxxxxx
```

API keys are issued per organisation from the compliance dashboard. Two types:
- `bsk_live_*` — production keys
- `bsk_test_*` — testnet keys (Base Sepolia only)

Rate limits: 100 req/min (Pro), 1000 req/min (Enterprise).

---

## Error Response Format

All errors return structured JSON:

```json
{
  "error": {
    "code": "AGENT_NOT_FOUND",
    "message": "No agent registered with ID 0x1234",
    "details": {},
    "request_id": "req_abc123"
  }
}
```

**Error codes:**

| Code | HTTP Status | Description |
|---|---|---|
| `AGENT_NOT_FOUND` | 404 | Agent DID or ID not registered |
| `AGENT_REVOKED` | 403 | Agent is currently revoked |
| `PERMISSION_DENIED` | 403 | You don't own this agent |
| `INVALID_SCOPE` | 400 | Permission scope failed validation |
| `INSUFFICIENT_FUNDS` | 400 | Insufficient ETH for transaction gas |
| `INVALID_API_KEY` | 401 | API key invalid or expired |
| `RATE_LIMITED` | 429 | Rate limit exceeded |
| `ORACLE_UNAVAILABLE` | 503 | Chainlink oracle unavailable |

---

## Endpoint Reference

### Agents

#### `POST /v1/agents` — Register Agent

```http
POST /v1/agents
Content-Type: application/json
X-Bouclier-API-Key: bsk_live_xxx

{
  "agent_address": "0x1234...abcd",
  "model": "claude-sonnet-4-6",
  "model_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "metadata": {
    "description": "DeFi trading agent for Uniswap v3",
    "version": "1.0.0",
    "tags": ["defi", "trading"]
  }
}
```

**Response `201 Created`:**
```json
{
  "agent_id": "0xabcdef...",
  "did": "did:ethr:base:0x1234...abcd",
  "permission_vault_address": "0xVAULT...",
  "tx_hash": "0xTX...",
  "created_at": "2026-03-17T14:30:00Z"
}
```

---

#### `GET /v1/agents/{did}` — Get Agent

```http
GET /v1/agents/did:ethr:base:0x1234...abcd
X-Bouclier-API-Key: bsk_live_xxx
```

**Response `200 OK`:**
```json
{
  "agent_id": "0xabcdef...",
  "did": "did:ethr:base:0x1234...abcd",
  "agent_address": "0x1234...abcd",
  "owner": "0xOWNER...",
  "model": "claude-sonnet-4-6",
  "status": "active",
  "permission_vault_address": "0xVAULT...",
  "created_at": "2026-03-17T14:30:00Z",
  "updated_at": "2026-03-17T14:30:00Z",
  "stats": {
    "total_actions": 47,
    "total_violations": 2,
    "total_spent_usd": "1247.50",
    "last_active_at": "2026-03-17T14:28:00Z"
  }
}
```

---

#### `GET /v1/agents` — List All Agents (paginated)

```http
GET /v1/agents?page=1&limit=20&status=active
X-Bouclier-API-Key: bsk_live_xxx
```

Query params: `status` (active/suspended/revoked), `page`, `limit` (max 100)

**Response `200 OK`:**
```json
{
  "agents": [...],
  "total": 47,
  "page": 1,
  "limit": 20,
  "has_more": true
}
```

---

### Permissions

#### `POST /v1/agents/{did}/permissions` — Grant Permission Scope

```http
POST /v1/agents/did:ethr:base:0x.../permissions
Content-Type: application/json
X-Bouclier-API-Key: bsk_live_xxx

{
  "allowed_protocols": [
    "0xUNISWAP_V3_ROUTER",
    "0xAAVE_V3_POOL"
  ],
  "allowed_selectors": ["0x04e45aaf", "0x617ba037"],
  "allowed_tokens": ["0xUSDC", "0xWETH", "0xWBTC"],
  "daily_spend_cap_usd": 2000,
  "per_tx_spend_cap_usd": 500,
  "valid_from": "2026-03-17T00:00:00Z",
  "valid_until": "2026-06-17T00:00:00Z",
  "time_window": {
    "start_hour": 8,
    "end_hour": 20,
    "days_of_week": ["mon", "tue", "wed", "thu", "fri"]
  }
}
```

**Response `201 Created`:**
```json
{
  "scope_id": "0xSCOPE...",
  "active": true,
  "tx_hash": "0xTX...",
  "superseded_scope_id": null,
  "created_at": "2026-03-17T14:30:00Z"
}
```

---

#### `GET /v1/agents/{did}/permissions` — Get Active Permission Scope

```http
GET /v1/agents/did:ethr:base:0x.../permissions
```

**Response `200 OK`:**
```json
{
  "scope_id": "0xSCOPE...",
  "active": true,
  "allowed_protocols": ["0xUNISWAP_V3_ROUTER", "0xAAVE_V3_POOL"],
  "allowed_tokens": ["0xUSDC", "0xWETH", "0xWBTC"],
  "daily_spend_cap_usd": "2000.00",
  "per_tx_spend_cap_usd": "500.00",
  "daily_used_usd": "847.50",
  "daily_cap_remaining_usd": "1152.50",
  "daily_cap_percent_used": 42.4,
  "valid_from": "2026-03-17T00:00:00Z",
  "valid_until": "2026-06-17T00:00:00Z",
  "created_at": "2026-03-17T14:30:00Z"
}
```

---

#### `GET /v1/agents/{did}/permissions/history` — Permission History

Returns all scopes ever granted to an agent (including revoked ones).

---

### Revocation

#### `POST /v1/agents/{did}/revoke` — Revoke Agent

```http
POST /v1/agents/did:ethr:base:0x.../revoke
Content-Type: application/json
X-Bouclier-API-Key: bsk_live_xxx

{
  "reason": "suspicious",
  "custom_reason": "Agent made 50 trades in 2 minutes — anomalous pattern detected"
}
```

**Response `200 OK`:**
```json
{
  "revoked": true,
  "revoked_at": "2026-03-17T14:30:00Z",
  "revoked_by": "0xOPERATOR",
  "tx_hash": "0xTX...",
  "redis_cache_updated": true
}
```

---

#### `POST /v1/agents/{did}/reinstate` — Reinstate Agent

Only available 24+ hours after revocation.

```http
POST /v1/agents/did:ethr:base:0x.../reinstate
Content-Type: application/json

{
  "reason": "Investigation complete — false positive, agent cleared"
}
```

---

### Audit Trail

#### `GET /v1/agents/{did}/audit` — Get Audit Events

```http
GET /v1/agents/did:ethr:base:0x.../audit?from=2026-03-10T00:00:00Z&limit=100&outcome=all
```

Query params:
- `from` / `to`: ISO 8601 timestamps
- `limit`: max 1000, default 100
- `outcome`: `success` | `violation` | `all`
- `format`: `json` | `csv` (for CSV download)

**Response `200 OK`:**
```json
{
  "events": [
    {
      "event_id": "0xEVENT...",
      "user_op_hash": "0xUSEROPHASH...",
      "tx_hash": "0xTX...",
      "target_contract": "0xUNISWAP...",
      "function_selector": "0x04e45aaf",
      "function_name": "exactInputSingle",
      "protocol": "uniswap_v3",
      "value_usd": "300.00",
      "outcome": "success",
      "violation_type": null,
      "block_number": 12345678,
      "timestamp": "2026-03-17T14:28:00Z",
      "permission_scope_id": "0xSCOPE...",
      "ipfs_cid": "ipfs://Qm..."
    }
  ],
  "total": 47,
  "has_more": false,
  "exported_at": "2026-03-17T14:30:00Z"
}
```

---

### Spend Analytics

#### `GET /v1/agents/{did}/spend` — Spend Summary

```http
GET /v1/agents/did:ethr:base:0x.../spend?granularity=daily&lookback_days=30
```

**Response `200 OK`:**
```json
{
  "rolling_24h_usd": "847.50",
  "daily_cap_usd": "2000.00",
  "percentage_used": 42.4,
  "period_breakdown": [
    {
      "period": "2026-03-17",
      "spent_usd": "847.50",
      "tx_count": 12,
      "violations": 0
    },
    {
      "period": "2026-03-16",
      "spent_usd": "1243.00",
      "tx_count": 18,
      "violations": 2
    }
  ]
}
```

---

### Compliance

#### `GET /v1/compliance/report` — Export Regulatory Report

```http
GET /v1/compliance/report?agent_id=did:ethr:base:0x...&jurisdiction=MAS&format=pdf&from=2026-01-01&to=2026-03-31
```

Query params:
- `agent_id`: Specific agent, or omit for all agents in organisation
- `jurisdiction`: `MAS` | `MiCA` | `generic`
- `format`: `pdf` | `json`
- `from` / `to`: Report period

**Response:** Binary PDF or JSON compliance report

---

### Pre-flight Check

#### `POST /v1/check` — Pre-flight Permission Check

```http
POST /v1/check
Content-Type: application/json
X-Bouclier-API-Key: bsk_live_xxx

{
  "agent_id": "0xAGENT...",
  "target": "0xUNISWAP_ROUTER",
  "selector": "0x04e45aaf",
  "estimated_value_usd": 300.0,
  "tokens": ["0xUSDC", "0xWETH"]
}
```

**Response `200 OK`:**
```json
{
  "allowed": true,
  "reject_reason": null,
  "remaining_daily_cap_usd": "1152.50",
  "remaining_daily_cap_percent": 57.6
}
```

**Response (if blocked):**
```json
{
  "allowed": false,
  "reject_reason": "DAILY_CAP_EXCEEDED",
  "current_rolling_total_usd": "1850.00",
  "daily_cap_usd": "2000.00",
  "shortfall_usd": "150.00"
}
```

---

### Webhooks

Enterprises can register webhook URLs to receive real-time event notifications.

#### `POST /v1/webhooks` — Register Webhook

```http
POST /v1/webhooks
Content-Type: application/json

{
  "url": "https://your-server.com/bouclier-events",
  "secret": "your_webhook_secret",    // Used to sign payloads (HMAC-SHA256)
  "events": [
    "agent.revoked",
    "permission.violation",
    "spend.cap_warning",              // Fires when > 80% of cap consumed
    "agent.registered"
  ]
}
```

#### Webhook Payload Examples

```json
// permission.violation
{
  "event": "permission.violation",
  "webhook_id": "wh_abc123",
  "request_id": "req_xyz789",
  "timestamp": "2026-03-17T14:30:00Z",
  "data": {
    "agent_id": "did:ethr:base:0x...",
    "agent_owner": "0xENTERPRISE",
    "violation_type": "DAILY_CAP_EXCEEDED",
    "attempted_usd": 600.00,
    "daily_cap_usd": 500.00,
    "current_rolling_total_usd": 450.00,
    "target_contract": "0xUNISWAP_ROUTER",
    "function_selector": "0x04e45aaf",
    "tx_blocked": true
  }
}

// agent.revoked
{
  "event": "agent.revoked",
  "data": {
    "agent_id": "did:ethr:base:0x...",
    "revoked_by": "0xOPERATOR",
    "reason": "suspicious",
    "custom_reason": "Anomalous trading pattern",
    "revoked_at": "2026-03-17T14:30:00Z",
    "tx_hash": "0xTX..."
  }
}

// spend.cap_warning (80% threshold)
{
  "event": "spend.cap_warning",
  "data": {
    "agent_id": "did:ethr:base:0x...",
    "rolling_24h_usd": 1620.00,
    "daily_cap_usd": 2000.00,
    "percentage_used": 81.0,
    "estimated_cap_reached_at": "2026-03-17T18:45:00Z"
  }
}
```

**Webhook security:** All payloads are signed with `HMAC-SHA256` using your webhook secret. Verify with:

```python
import hmac, hashlib

def verify_webhook(payload_bytes: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(), payload_bytes, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)
```

---

## Health Check

```http
GET /health

# Response 200 OK
{
  "status": "ok",
  "version": "1.0.0",
  "chains": {
    "base": "connected",
    "arbitrum": "connected",
    "ethereum": "connected"
  },
  "subgraph": "synced",
  "redis": "connected",
  "db": "connected"
}
```

---

*Last Updated: March 2026*

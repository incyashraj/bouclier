# Python SDK — Architecture & API Reference

> **Package:** `bouclier-sdk`  
> **Python:** 3.12+  
> **Async:** Native `asyncio` (all network calls are async)  
> **Install:** `pip install bouclier-sdk`

---

## Overview

The Python SDK provides the same capabilities as the TypeScript SDK, targeting the ML/AI engineering community. Python is the dominant language for LLM agent development (LangChain Python, AutoGPT, CrewAI), so a first-class Python SDK is essential for protocol adoption.

**All async.** Every function that makes a network call is `async`. Use `asyncio.run()` or any async framework (FastAPI, aiohttp, etc.).

---

## Package Structure

```
packages/python-sdk/
├── bouclier/
│   ├── __init__.py          ← Main export (AgentShield class)
│   ├── core.py              ← AgentShield class
│   ├── types.py             ← Pydantic models
│   ├── contracts.py         ← ABI + address registry
│   ├── agents/
│   │   ├── wrapper.py       ← wrap_agent() implementation
│   │   └── preflight.py     ← Pre-flight check
│   ├── integrations/
│   │   ├── langchain.py     ← LangChain Python integration
│   │   └── crewai.py        ← CrewAI integration
│   └── utils/
│       ├── did.py
│       └── errors.py
├── pyproject.toml
├── tests/
│   ├── unit/
│   └── integration/
└── examples/
    ├── langchain_agent.py
    └── crewai_agent.py
```

---

## Full API Reference

### Initialisation

```python
from bouclier import AgentShield

shield = AgentShield(
    # Required
    chain="base",                        # "base" | "base-sepolia" | "arbitrum" | "ethereum"
    rpc_url=os.environ["RPC_URL"],
    api_key=os.environ["BOUCLIER_API_KEY"],
    
    # Optional
    private_key=os.environ.get("AGENT_PRIVATE_KEY"),  # For signing transactions
    redis_url=os.environ.get("REDIS_URL"),             # Fast revocation cache
    log_level="info",                                   # "silent" | "info" | "debug"
)
```

---

### Pydantic Models (Types)

```python
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PermissionScope(BaseModel):
    allowed_protocols: list[str]           # Contract addresses
    allowed_selectors: list[str] = []      # Function selectors (4-byte hex strings)
    allowed_tokens: list[str]              # ERC-20 token addresses
    allow_any_token: bool = False
    daily_spend_cap_usd: float             # Max USD per rolling 24h
    per_tx_spend_cap_usd: float            # Max USD per single tx
    valid_from: Optional[datetime] = None  # Default: now
    valid_until: Optional[datetime] = None # Default: no expiry
    time_window: Optional["TimeWindow"] = None
    
class TimeWindow(BaseModel):
    start_hour: int   # UTC hour 0–23
    end_hour: int     # UTC hour 0–23
    days_of_week: list[str]  # ["mon", "tue", "wed", "thu", "fri"]

class AgentRecord(BaseModel):
    agent_id: str          # bytes32 hex
    agent_address: str     # wallet address
    owner: str             # enterprise wallet
    did: str               # "did:ethr:base:0x..."
    model: str
    status: str            # "active" | "suspended" | "revoked"
    created_at: datetime
    permission_vault: str  # contract address

class AuditEvent(BaseModel):
    event_id: str
    agent_id: str
    tx_hash: Optional[str]
    target_contract: str
    function_selector: str
    function_name: Optional[str]
    value_usd: float
    outcome: str             # "success" | "violation"
    violation_type: Optional[str]
    timestamp: datetime
    block_number: int
    permission_scope_id: str

class ValidationResult(BaseModel):
    allowed: bool
    reject_reason: Optional[str]
    remaining_daily_cap_usd: Optional[float]
    remaining_daily_cap_percent: Optional[float]

class SpendSummary(BaseModel):
    rolling_24h_usd: float
    daily_cap_usd: float
    percentage_used: float
    period_breakdown: list[dict]
```

---

### Agent Registration

```python
async def register_agent(
    self,
    agent_address: str,
    model: str,
    model_hash: Optional[str] = None,
    metadata: Optional[dict] = None,
) -> dict:
    """
    Registers a new AI agent with the Bouclier protocol.
    
    Returns:
        {
            "agent_id": "0x...",
            "did": "did:ethr:base:0x...",
            "tx_hash": "0x...",
            "permission_vault_address": "0x..."
        }
    """

# Example
import asyncio
from bouclier import AgentShield

shield = AgentShield(chain="base", rpc_url="...", api_key="...")

async def main():
    agent = await shield.register_agent(
        agent_address="0xAGENT_WALLET",
        model="claude-sonnet-4-6",
    )
    print(f"Agent DID: {agent['did']}")

asyncio.run(main())
```

---

### Permission Management

```python
async def grant_permission(
    self,
    agent_id: str,
    scope: PermissionScope,
) -> dict:
    """
    Grants a permission scope to a registered agent.
    
    Returns:
        {
            "scope_id": "0x...",
            "tx_hash": "0x...",
            "active": True
        }
    """

# Example
scope = PermissionScope(
    allowed_protocols=[
        shield.address_of("uniswap_v3", "router"),
        shield.address_of("aave_v3", "pool"),
    ],
    allowed_tokens=[
        shield.token_address_of("USDC"),
        shield.token_address_of("ETH"),
    ],
    daily_spend_cap_usd=2000.0,
    per_tx_spend_cap_usd=500.0,
    valid_until=datetime.now() + timedelta(days=90),
    time_window=TimeWindow(
        start_hour=8,
        end_hour=20,
        days_of_week=["mon", "tue", "wed", "thu", "fri"],
    ),
)

result = await shield.grant_permission(agent["agent_id"], scope)
```

---

### Agent Revocation

```python
async def revoke_agent(
    self,
    agent_id: str,
    reason: str,                  # "suspicious" | "compromised" | "policy" | "requested" | ...
    custom_reason: Optional[str] = None,
    immediate: bool = True,       # Set Redis flag before broadcasting
) -> dict:
    """
    Revokes an agent's permission to act.
    After this call returns, the agent cannot execute any further actions.
    
    Returns:
        {
            "revoked_at": datetime,
            "tx_hash": "0x..."
        }
    """

# Example
await shield.revoke_agent(
    agent["agent_id"],
    reason="suspicious",
    custom_reason="50 trades in 10 minutes, anomalous pattern detected",
)
```

---

### Agent Wrapping

```python
def wrap_agent(
    self,
    agent: Any,                    # Any agent object with a callable execution method
    agent_id: str,
    enforce_on_chain: bool = True,
    dry_run: bool = False,
    on_violation: Optional[Callable] = None,
) -> "WrappedAgent":
    """
    Wraps an existing agent to route all blockchain actions through Bouclier.
    Compatible with: LangChain agents, CrewAI agents, any class with a run()/arun() method.
    
    The wrapper intercepts at the tool call level — no changes to agent logic required.
    """

# Example with LangChain Python
from langchain.agents import initialize_agent

raw_agent = initialize_agent(tools=my_tools, llm=claude, ...)

protected_agent = shield.wrap_agent(
    raw_agent,
    agent_id=agent["agent_id"],
    enforce_on_chain=True,
    on_violation=lambda v: print(f"Blocked: {v.type}"),
)

# Run as normal — protection is transparent
result = await protected_agent.arun("Swap 300 USDC for ETH on Uniswap")
```

---

### Pre-flight Check

```python
async def check_permission(
    self,
    agent_id: str,
    target: str,             # Contract address
    selector: str,           # 4-byte function selector e.g. "0x04e45aaf"
    estimated_value_usd: float,
    tokens: Optional[list[str]] = None,
) -> ValidationResult:
    """
    Checks whether a specific action would be permitted, without executing it.
    Read-only — does not record spend or log action.
    """

# Example
result = await shield.check_permission(
    agent_id=agent["agent_id"],
    target=shield.address_of("uniswap_v3", "router"),
    selector="0x04e45aaf",
    estimated_value_usd=300.0,
    tokens=[shield.token_address_of("USDC"), shield.token_address_of("ETH")],
)

if not result.allowed:
    print(f"Would be blocked: {result.reject_reason}")
    # e.g. "DAILY_CAP_EXCEEDED"
```

---

### Audit Trail

```python
async def get_audit_trail(
    self,
    agent_id: str,
    from_time: Optional[datetime] = None,
    to_time: Optional[datetime] = None,
    limit: int = 100,
    outcome_filter: str = "all",         # "success" | "violation" | "all"
    include_ipfs_detail: bool = False,
) -> tuple[list[AuditEvent], int, bool]:
    """
    Returns: (events, total_count, has_more)
    """

# Example
from datetime import datetime, timedelta

events, total, has_more = await shield.get_audit_trail(
    agent_id=agent["agent_id"],
    from_time=datetime.now() - timedelta(days=7),
    limit=100,
)

for event in events:
    print(f"{event.timestamp}: {event.function_name} → {event.outcome}")
```

---

### Spend Summary

```python
async def get_spend_summary(
    self,
    agent_id: str,
    granularity: str = "daily",     # "hourly" | "daily" | "weekly"
    lookback_days: int = 30,
) -> SpendSummary:
    """Returns spending breakdown for an agent"""

summary = await shield.get_spend_summary(agent["agent_id"])
print(f"Used {summary.percentage_used:.1f}% of daily cap")
print(f"Remaining: ${summary.daily_cap_usd - summary.rolling_24h_usd:.2f}")
```

---

## LangChain Python Integration

```python
# bouclier/integrations/langchain.py (usage)

from bouclier.integrations.langchain import BouclierCallbackHandler
from langchain.agents import AgentExecutor

handler = BouclierCallbackHandler(
    shield=shield,
    agent_id=agent["agent_id"],
    on_violation=lambda v: send_alert(v),
)

agent_executor = AgentExecutor(
    agent=my_agent,
    tools=my_tools,
    callbacks=[handler],
    verbose=True,
)

# Every tool call now goes through Bouclier
result = await agent_executor.ainvoke({"input": "Swap 300 USDC for ETH"})
```

---

## Error Handling

```python
from bouclier.errors import BouclierError, BouclierErrorCode

try:
    await protected_agent.arun("Swap 2000000 USDC for ETH")
except BouclierError as e:
    match e.code:
        case BouclierErrorCode.SPEND_CAP_EXCEEDED:
            print("Daily spend cap exhausted")
        case BouclierErrorCode.AGENT_REVOKED:
            print("Agent has been revoked")
        case BouclierErrorCode.PROTOCOL_NOT_ALLOWED:
            print("Attempted to access disallowed protocol")
        case _:
            raise
```

---

## Testing

```python
# Use TestShield for unit testing — no RPC calls needed
from bouclier.testing import TestShield, MockScope

shield = TestShield(
    default_scope=MockScope(
        allow_all=True,  # All actions permitted (for testing agent logic)
    )
)

# Or test specific violation scenarios
shield = TestShield(
    default_scope=MockScope(
        allowed_protocols=["0xUNISWAP"],
        daily_spend_cap_usd=100.0,  # Low cap to test cap exceeded errors
    )
)
```

---

*Last Updated: March 2026*

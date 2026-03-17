import secrets
from datetime import datetime, timezone

import bcrypt
from fastapi import Depends, HTTPException, Security
from fastapi.security import APIKeyHeader
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.models.database import ApiKey, Organization

api_key_header = APIKeyHeader(name="X-Bouclier-API-Key", auto_error=False)


def _hash_key(key: str) -> str:
    return bcrypt.hashpw(key.encode()[:72], bcrypt.gensalt()).decode()


def _verify_key(key: str, hashed: str) -> bool:
    return bcrypt.checkpw(key.encode()[:72], hashed.encode())


async def get_current_org(
    api_key: str | None = Security(api_key_header),
    db: AsyncSession = Depends(get_db),
) -> Organization:
    """Validate API key and return the owning organization."""
    if not api_key:
        raise HTTPException(status_code=401, detail={"code": "INVALID_API_KEY", "message": "Missing API key"})

    # Extract prefix (first 12 chars) for DB lookup
    prefix = api_key[:12] if len(api_key) >= 12 else api_key
    result = await db.execute(
        select(ApiKey).where(ApiKey.key_prefix == prefix, ApiKey.is_active.is_(True))
    )
    db_key = result.scalar_one_or_none()

    if not db_key or not _verify_key(api_key, db_key.key_hash):
        raise HTTPException(status_code=401, detail={"code": "INVALID_API_KEY", "message": "Invalid API key"})

    # Update last_used_at
    db_key.last_used_at = datetime.now(timezone.utc)
    await db.commit()

    result = await db.execute(select(Organization).where(Organization.id == db_key.organization_id))
    org = result.scalar_one_or_none()
    if not org:
        raise HTTPException(status_code=401, detail={"code": "INVALID_API_KEY", "message": "Organization not found"})

    return org


def generate_api_key(environment: str = "test") -> tuple[str, str, str]:
    """Generate a new API key. Returns (full_key, prefix, bcrypt_hash)."""
    prefix_type = "bsk_live_" if environment == "live" else "bsk_test_"
    random_part = secrets.token_urlsafe(24)
    full_key = f"{prefix_type}{random_part}"
    key_prefix = full_key[:12]
    key_hash = _hash_key(full_key)
    return full_key, key_prefix, key_hash

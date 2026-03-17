"""Sign-In with Ethereum (EIP-4361) authentication for wallet-connected users."""

import logging
import secrets
from datetime import datetime, timezone, timedelta

from fastapi import Depends, HTTPException, Request
from jose import jwt, JWTError
from siwe import SiweMessage, generate_nonce

from app.config import get_settings

logger = logging.getLogger("bouclier.siwe")

settings = get_settings()

# In-memory nonce store — replace with Redis in production
_nonce_store: dict[str, datetime] = {}
NONCE_TTL = timedelta(minutes=5)


def issue_nonce() -> str:
    """Generate a fresh nonce for the SIWE flow."""
    nonce = generate_nonce()
    _nonce_store[nonce] = datetime.now(timezone.utc)
    # Evict expired nonces
    cutoff = datetime.now(timezone.utc) - NONCE_TTL
    expired = [k for k, v in _nonce_store.items() if v < cutoff]
    for k in expired:
        _nonce_store.pop(k, None)
    return nonce


def verify_siwe_message(message: str, signature: str) -> dict:
    """Verify a SIWE message + signature. Returns claims dict on success.

    Raises HTTPException on invalid/expired messages.
    """
    try:
        siwe_msg = SiweMessage.from_message(message=message)
        siwe_msg.verify(signature=signature)
    except Exception as exc:
        raise HTTPException(status_code=401, detail={"code": "SIWE_INVALID", "message": str(exc)})

    # Check nonce was issued by us
    if siwe_msg.nonce not in _nonce_store:
        raise HTTPException(status_code=401, detail={"code": "SIWE_NONCE_INVALID", "message": "Unknown or expired nonce"})

    # Consume nonce (one-time use)
    _nonce_store.pop(siwe_msg.nonce, None)

    return {
        "address": siwe_msg.address,
        "chain_id": siwe_msg.chain_id,
        "domain": siwe_msg.domain,
        "issued_at": siwe_msg.issued_at,
    }


def create_session_token(address: str, chain_id: int) -> str:
    """Create a JWT session token after successful SIWE verification."""
    payload = {
        "sub": address.lower(),
        "chain_id": chain_id,
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes),
        "type": "siwe",
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def get_wallet_address(request: Request) -> str:
    """FastAPI dependency — extract and verify wallet address from Bearer JWT."""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail={"code": "MISSING_TOKEN", "message": "Bearer token required"})

    token = auth_header[7:]
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError:
        raise HTTPException(status_code=401, detail={"code": "INVALID_TOKEN", "message": "Invalid or expired token"})

    if payload.get("type") != "siwe":
        raise HTTPException(status_code=401, detail={"code": "INVALID_TOKEN", "message": "Not a SIWE token"})

    return payload["sub"]

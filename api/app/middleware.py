"""Middleware: rate limiting (Redis), request ID tracking, structured logging."""

import logging
import time
import uuid

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

logger = logging.getLogger("bouclier.api")

# Tier → requests per minute
TIER_LIMITS = {
    "starter": 100,
    "growth": 1000,
    "enterprise": 10000,
}


class RequestIdMiddleware(BaseHTTPMiddleware):
    """Attach a unique X-Request-ID to every request/response."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id

        start = time.perf_counter()
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000

        response.headers["X-Request-ID"] = request_id
        logger.info(
            "%s %s %d %.1fms [%s]",
            request.method,
            request.url.path,
            response.status_code,
            elapsed_ms,
            request_id,
        )
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Sliding-window rate limiter backed by Redis.

    Falls back to no-limit (pass-through) if Redis is unavailable.
    Uses the org tier attached by the auth dependency (via request.state).
    Unauthenticated routes (e.g. /health) are never rate-limited.
    """

    def __init__(self, app, redis_url: str = "redis://localhost:6379/0"):
        super().__init__(app)
        self._redis_url = redis_url
        self._redis = None

    async def _get_redis(self):
        if self._redis is not None:
            return self._redis
        try:
            from redis.asyncio import from_url

            self._redis = from_url(self._redis_url, decode_responses=True)
            await self._redis.ping()
            return self._redis
        except Exception:
            logger.warning("Redis unavailable — rate limiting disabled")
            self._redis = None
            return None

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        # Let the request pass through first (auth sets request.state.org)
        response = await call_next(request)

        # Only apply rate limiting for authenticated routes
        org = getattr(request.state, "org", None)
        if org is None:
            return response

        redis = await self._get_redis()
        if redis is None:
            return response

        tier = getattr(org, "tier", "starter")
        limit = TIER_LIMITS.get(tier, 100)
        key = f"ratelimit:{org.id}:{int(time.time()) // 60}"

        try:
            current = await redis.incr(key)
            if current == 1:
                await redis.expire(key, 120)  # 2 min TTL (covers the window + buffer)

            response.headers["X-RateLimit-Limit"] = str(limit)
            response.headers["X-RateLimit-Remaining"] = str(max(0, limit - current))

            if current > limit:
                return Response(
                    content='{"error":{"code":"RATE_LIMITED","message":"Rate limit exceeded. Upgrade your plan for higher limits."}}',
                    status_code=429,
                    media_type="application/json",
                    headers={
                        "X-RateLimit-Limit": str(limit),
                        "X-RateLimit-Remaining": "0",
                        "Retry-After": "60",
                    },
                )
        except Exception:
            logger.warning("Rate limit check failed — allowing request")

        return response

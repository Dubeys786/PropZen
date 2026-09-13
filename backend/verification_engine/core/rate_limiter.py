"""
In-memory sliding window rate limiter placeholder for PropZen GlobalVerificationEngine
"""
import time
from collections import defaultdict
from typing import Dict, List
from fastapi import HTTPException, status
from .config import settings


class InMemoryRateLimiter:
    def __init__(self, requests_per_minute: int = 60):
        self.requests_per_minute = requests_per_minute
        self.requests: Dict[str, List[float]] = defaultdict(list)

    def check_rate_limit(self, client_identifier: str) -> None:
        """Sliding window rate limit check."""
        now = time.time()
        window_start = now - 60.0

        # Purge timestamps older than 60 seconds
        self.requests[client_identifier] = [
            ts for ts in self.requests[client_identifier] if ts > window_start
        ]

        if len(self.requests[client_identifier]) >= self.requests_per_minute:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded: maximum {self.requests_per_minute} requests per minute allowed."
            )

        self.requests[client_identifier].append(now)


rate_limiter = InMemoryRateLimiter(settings.RATE_LIMIT_REQUESTS_PER_MINUTE)

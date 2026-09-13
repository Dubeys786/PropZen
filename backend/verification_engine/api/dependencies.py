"""
FastAPI dependencies for PropZen GlobalVerificationEngine
"""
from fastapi import Request
from ..core.security import verify_api_key_dependency
from ..core.rate_limiter import rate_limiter


async def rate_limit_dependency(request: Request) -> None:
    client_ip = request.client.host if request.client else "unknown"
    rate_limiter.check_rate_limit(client_ip)

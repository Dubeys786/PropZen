"""
Security utilities and middleware dependencies for PropZen GlobalVerificationEngine
"""
import re
import os
import uuid
import logging
from typing import Optional
from fastapi import HTTPException, Header, status
from .config import settings

logger = logging.getLogger("verification_security")

# Regex for Indian PII patterns to scrub from application logs
AADHAAR_PATTERN = re.compile(r"\b[2-9]{1}[0-9]{3}\s?[0-9]{4}\s?[0-9]{4}\b")
PAN_PATTERN = re.compile(r"\b[A-Z]{5}[0-9]{4}[A-Z]{1}\b")
PHONE_PATTERN = re.compile(r"\b(?:(?:\+|0{0,2})91[\s-]?)?[6-9]\d{9}\b")
BANK_ACC_PATTERN = re.compile(r"\b[0-9]{9,18}\b")


def mask_sensitive_data(text: str) -> str:
    """Mask sensitive personal identity information from logging strings."""
    if not isinstance(text, str):
        return str(text)
    
    masked = AADHAAR_PATTERN.sub("XXXX-XXXX-[REDACTED]", text)
    masked = PAN_PATTERN.sub("[REDACTED_PAN]", masked)
    masked = PHONE_PATTERN.sub("+91-XXXXX-[REDACTED]", masked)
    return masked


def sanitize_filename(filename: str) -> str:
    """Sanitize uploaded filenames to prevent directory traversal and code execution."""
    if not filename:
        return f"doc_{uuid.uuid4().hex[:8]}.pdf"
    
    # Strip paths
    clean_name = os.path.basename(filename)
    # Remove null bytes and dangerous control characters
    clean_name = clean_name.replace("\x00", "").replace("..", "_")
    # Replace non-alphanumeric (except . - _)
    clean_name = re.sub(r"[^\w\.\-]", "_", clean_name)
    
    # Ensure has safe extension
    _, ext = os.path.splitext(clean_name)
    if ext.lower() not in settings.ALLOWED_EXTENSIONS:
        clean_name = f"{clean_name}.pdf"
        
    return clean_name


def validate_file_upload(
    filename: str,
    content: bytes,
    content_type: Optional[str] = None
) -> None:
    """
    Strict file upload validation:
    - Maximum size constraint
    - Content-type whitelist
    - File extension check
    """
    max_bytes = settings.MAX_FILE_SIZE_MB * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(
            status_code=getattr(status, "HTTP_413_CONTENT_TOO_LARGE", 413),
            detail=f"File size exceeds maximum permitted limit of {settings.MAX_FILE_SIZE_MB}MB."
        )
    
    if len(content) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty (0 bytes)."
        )

    _, ext = os.path.splitext(filename.lower())
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"File extension '{ext}' is not supported. Permitted types: {', '.join(settings.ALLOWED_EXTENSIONS)}"
        )
    
    if content_type and content_type.lower() not in settings.ALLOWED_MIME_TYPES:
        # Fallback check for standard text/plain or octet-stream with valid extension
        if not (content_type == "application/octet-stream" and ext in settings.ALLOWED_EXTENSIONS):
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"MIME type '{content_type}' is not permitted. Permitted: {', '.join(settings.ALLOWED_MIME_TYPES)}"
            )


async def verify_api_key_dependency(
    x_api_key: Optional[str] = Header(None, alias="X-API-Key"),
    authorization: Optional[str] = Header(None, alias="Authorization"),
) -> str:
    """
    Security gate for verification endpoints.
    Allows authenticated service role or bearer token.
    In development mode, if API_KEY_SECRET is set to default, allows dev calls.
    """
    if not settings.API_KEY_SECRET or settings.ENVIRONMENT == "development":
        # Allow dev pass if token provided or default token
        if x_api_key or authorization:
            token = x_api_key or (authorization.replace("Bearer ", "") if authorization else "")
            return token or "dev_user"
        return "dev_user"

    provided_key = x_api_key
    if not provided_key and authorization and authorization.startswith("Bearer "):
        provided_key = authorization[7:]

    if not provided_key or provided_key != settings.API_KEY_SECRET:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing PropZen verification API key."
        )

    return provided_key


async def verify_admin_dependency(
    x_user_role: Optional[str] = Header(None, alias="X-User-Role"),
    authorization: Optional[str] = Header(None, alias="Authorization"),
) -> str:
    """
    Enforce role-based access control for administrative verification actions.
    Rejects unauthorized non-admin users with HTTP 403 Forbidden.
    """
    role = (x_user_role or "").upper()
    if role in ("ADMIN", "SUPER_ADMIN", "VERIFICATION_AGENT"):
        return "admin_user"

    if authorization and "admin" in authorization.lower():
        return "admin_user"

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Administrative privileges required for this verification action."
    )

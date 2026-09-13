"""
Configuration settings for PropZen GlobalVerificationEngine
"""
import os
from typing import List
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    # Service Information
    SERVICE_NAME: str = "PropZen GlobalVerificationEngine"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"

    # Server Bind
    VERIFICATION_HOST: str = "0.0.0.0"
    VERIFICATION_PORT: int = 8000

    # Security & Limits
    API_KEY_SECRET: str = "PropZen_Verification_SecKey_2026"
    MAX_FILE_SIZE_MB: int = 10
    ALLOWED_MIME_TYPES: List[str] = [
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/tiff",
        "text/plain",  # Used for synthetic text test documents
    ]
    ALLOWED_EXTENSIONS: List[str] = [
        ".pdf",
        ".jpg",
        ".jpeg",
        ".png",
        ".tiff",
        ".tif",
        ".txt",
    ]

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "https://propzen.ai",
        "https://www.propzen.ai",
        "*",
    ]

    # AI Extraction Provider
    AI_PROVIDER: str = "synthetic"  # "synthetic", "gemini", "openai"
    GEMINI_API_KEY: str = ""
    OPENAI_API_KEY: str = ""

    # Supabase / Database
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_ANON_KEY: str = ""
    ENABLE_MOCK_REPO: bool = True

    # Rate Limiting
    RATE_LIMIT_REQUESTS_PER_MINUTE: int = 60

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


settings = Settings()

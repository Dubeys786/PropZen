"""
Pytest configuration and shared fixtures for PropZen GlobalVerificationEngine
"""
import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure root and verification engine paths are available
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
VERIF_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
for p in [BASE_DIR, VERIF_DIR]:
    if p not in sys.path:
        sys.path.insert(0, p)

try:
    from backend.verification_engine.main import app
    from backend.verification_engine.core.config import settings
    from backend.verification_engine.services.repository import repository
except ImportError:
    from main import app
    from core.config import settings
    from services.repository import repository

TEST_DATA_DIR = os.path.join(os.path.dirname(__file__), "test_data")


@pytest.fixture
def client():
    """FastAPI test client instance."""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(autouse=True)
def reset_in_memory_repository():
    """Ensure clean repository state before every test."""
    repository._cases.clear()
    repository._documents.clear()
    repository._extracted_fields.clear()
    repository._findings.clear()
    repository._audit_logs.clear()


@pytest.fixture
def load_test_file():
    """Helper fixture to read sample document files."""
    def _loader(filename: str) -> bytes:
        path = os.path.join(TEST_DATA_DIR, filename)
        with open(path, "rb") as f:
            return f.read()
    return _loader

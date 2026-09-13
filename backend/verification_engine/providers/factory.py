"""
Factory for instantiating DocumentAIProvider instances
"""
from typing import Optional
from .base import DocumentAIProvider
from .synthetic_provider import SyntheticDocumentAIProvider
from .gemini_provider import GeminiDocumentAIProvider
from .openai_provider import OpenAIDocumentAIProvider
from ..core.config import settings


def get_document_ai_provider(provider_type: Optional[str] = None) -> DocumentAIProvider:
    """
    Instantiate DocumentAIProvider based on configuration or explicit override.
    Defaults to SyntheticDocumentAIProvider.
    """
    prov = (provider_type or settings.AI_PROVIDER or "synthetic").lower().strip()

    if prov == "gemini":
        return GeminiDocumentAIProvider()
    elif prov in ("openai", "gpt4"):
        return OpenAIDocumentAIProvider()
    else:
        return SyntheticDocumentAIProvider()

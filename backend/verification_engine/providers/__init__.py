"""
AI and OCR Document Extraction Providers for PropZen GlobalVerificationEngine
"""
from .base import DocumentAIProvider
from .synthetic_provider import SyntheticDocumentAIProvider
from .gemini_provider import GeminiDocumentAIProvider
from .openai_provider import OpenAIDocumentAIProvider
from .factory import get_document_ai_provider

__all__ = [
    "DocumentAIProvider",
    "SyntheticDocumentAIProvider",
    "GeminiDocumentAIProvider",
    "OpenAIDocumentAIProvider",
    "get_document_ai_provider",
]

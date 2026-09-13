"""
OpenAI Document AI Provider for PropZen GlobalVerificationEngine
Leverages OpenAI GPT-4o vision & structured outputs for property documents.
"""
import io
import json
import logging
from typing import Optional, Tuple
import httpx
from ..models.enums import DocumentType
from ..models.schemas import ExtractedData
from ..core.config import settings
from .base import DocumentAIProvider

logger = logging.getLogger("openai_provider")


class OpenAIDocumentAIProvider(DocumentAIProvider):
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or settings.OPENAI_API_KEY
        self.model = "gpt-4o-mini"

    @property
    def provider_name(self) -> str:
        return "openai"

    async def extract_text(
        self,
        file_bytes: bytes,
        mime_type: str,
        file_name: str
    ) -> Tuple[str, int]:
        try:
            import pypdf
            reader = pypdf.PdfReader(io.BytesIO(file_bytes))
            texts = [p.extract_text() for p in reader.pages if p.extract_text()]
            if texts:
                return "\n".join(texts), len(reader.pages)
        except Exception:
            pass

        try:
            return file_bytes.decode("utf-8"), 1
        except Exception:
            return f"Binary Document {file_name}", 1

    async def classify_document(
        self,
        text: str,
        file_name: str
    ) -> DocumentType:
        upper = f"{file_name} {text}".upper()
        if "SALE DEED" in upper:
            return DocumentType.SALE_DEED
        if "KHATAUNI" in upper or "KHASRA" in upper:
            return DocumentType.KHATAUNI_LAND_RECORD
        if "TAX" in upper:
            return DocumentType.PROPERTY_TAX_DOCUMENT
        if "ENCUMBRANCE" in upper:
            return DocumentType.ENCUMBRANCE_CERTIFICATE
        return DocumentType.GENERIC_PROPERTY_DOCUMENT

    async def extract_fields(
        self,
        text: str,
        document_type: Optional[DocumentType] = None
    ) -> ExtractedData:
        if not self.api_key or self.api_key.startswith("sk_placeholder"):
            logger.warning("OPENAI_API_KEY not configured; falling back to synthetic provider.")
            from .synthetic_provider import SyntheticDocumentAIProvider
            return await SyntheticDocumentAIProvider().extract_fields(text, document_type)

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "response_format": {"type": "json_object"},
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are an Indian land and property deed extraction engine. "
                        "Return strict JSON matching the ExtractedData schema. Do not invent missing values."
                    )
                },
                {"role": "user", "content": f"Document text:\n{text[:4000]}"}
            ]
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
                resp.raise_for_status()
                data = resp.json()
                raw_content = data["choices"][0]["message"]["content"]
                parsed = json.loads(raw_content)
                return ExtractedData.model_validate(parsed)
        except Exception as e:
            logger.error(f"OpenAI extraction failed: {e}; falling back to synthetic.")
            from .synthetic_provider import SyntheticDocumentAIProvider
            return await SyntheticDocumentAIProvider().extract_fields(text, document_type)

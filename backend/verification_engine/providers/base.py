"""
Abstract Base Provider Interface for PropZen Document AI
"""
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, Tuple
from ..models.enums import DocumentType
from ..models.schemas import ExtractedData


class DocumentAIProvider(ABC):
    """
    Pluggable document AI interface for PropZen.
    Enables zero-friction switching between Synthetic, Gemini, OpenAI, and OCR engines.
    """

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Return the unique identifier of the provider."""
        pass

    @abstractmethod
    async def extract_text(
        self,
        file_bytes: bytes,
        mime_type: str,
        file_name: str
    ) -> Tuple[str, int]:
        """
        Extract raw text and page count from the document bytes.
        Returns: (raw_text, page_count)
        """
        pass

    @abstractmethod
    async def extract_fields(
        self,
        text: str,
        document_type: Optional[DocumentType] = None
    ) -> ExtractedData:
        """
        Extract structured property, ownership, transaction, and metadata fields from text.
        Missing fields must be assigned null and included in missing_fields list.
        """
        pass

    @abstractmethod
    async def classify_document(
        self,
        text: str,
        file_name: str
    ) -> DocumentType:
        """
        Determine the document type (e.g., SALE_DEED, KHATAUNI_LAND_RECORD) from content.
        """
        pass

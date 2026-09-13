"""
DocumentParserProvider Abstract Interface
Defines the required operations for replaceable document text, table, and layout extraction.
"""
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Tuple, Optional


class ParsedPage:
    def __init__(self, page_number: int, text: str, tables: Optional[List[Dict[str, Any]]] = None):
        self.page_number = page_number
        self.text = text
        self.tables = tables or []


class DocumentParserProvider(ABC):
    """
    Replaceable document parser and OCR provider abstraction.
    Supports future integrations with Tesseract, PaddleOCR, AWS Textract, or multimodal VLMs.
    """

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Name of the parsing provider (e.g. 'synthetic', 'tesseract', 'vlm')."""
        pass

    @abstractmethod
    async def extract_text(
        self,
        file_bytes: bytes,
        mime_type: str,
        file_name: str
    ) -> Tuple[str, int, Dict[int, str]]:
        """
        Extract text from document.
        Returns:
            Tuple of (full_text, total_page_count, per_page_text_map)
        """
        pass

    @abstractmethod
    async def extract_tables(
        self,
        file_bytes: bytes,
        mime_type: str
    ) -> List[Dict[str, Any]]:
        """
        Extract structured table data (e.g., Schedules of Property, Khatedar shares).
        """
        pass

    @abstractmethod
    async def detect_language(self, text: str) -> str:
        """
        Detect primary document language(s). Returns 'Hindi', 'English', or 'Bilingual (Hindi/English)'.
        """
        pass

    @abstractmethod
    async def get_page_count(
        self,
        file_bytes: bytes,
        mime_type: str
    ) -> int:
        """
        Compute total page count of document.
        """
        pass

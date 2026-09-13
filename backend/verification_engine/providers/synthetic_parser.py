"""
Synthetic & Local Document Parser Implementation
Provides deterministic local OCR and document parsing with Hindi/English support.
"""
import io
import re
import hashlib
from typing import Dict, Any, List, Tuple
from .parser_base import DocumentParserProvider


class SyntheticDocumentParser(DocumentParserProvider):
    @property
    def provider_name(self) -> str:
        return "synthetic_local_parser"

    def compute_sha256(self, file_bytes: bytes) -> str:
        """Compute SHA-256 checksum for duplicate document identification."""
        return hashlib.sha256(file_bytes).hexdigest()

    def validate_file_signature(self, file_bytes: bytes, file_name: str) -> str:
        """
        Verify magic bytes / file signature to prevent extension-spoofing attacks.
        """
        if not file_bytes:
            raise ValueError("File payload is empty (0 bytes).")

        # PDF Signature
        if file_bytes.startswith(b"%PDF-"):
            return "application/pdf"

        # PNG Signature
        if file_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
            return "image/png"

        # JPEG Signature
        if file_bytes.startswith(b"\xff\xd8\xff"):
            return "image/jpeg"

        # TIFF Signature
        if file_bytes.startswith(b"II*\x00") or file_bytes.startswith(b"MM\x00*"):
            return "image/tiff"

        # Text files (.txt or valid UTF-8/ASCII plain text)
        if file_name.lower().endswith(".txt"):
            try:
                file_bytes.decode("utf-8")
                return "text/plain"
            except UnicodeDecodeError:
                pass

        # Check if printable ASCII/UTF-8
        try:
            sample = file_bytes[:1024].decode("utf-8")
            if any(c.isalnum() for c in sample):
                return "text/plain"
        except UnicodeDecodeError:
            pass

        raise ValueError(f"Corrupted or invalid file signature for '{file_name}'. Not a valid PDF, image, or text.")

    async def get_page_count(self, file_bytes: bytes, mime_type: str) -> int:
        if mime_type == "application/pdf" or file_bytes.startswith(b"%PDF-"):
            try:
                import pypdf
                reader = pypdf.PdfReader(io.BytesIO(file_bytes))
                return max(1, len(reader.pages))
            except Exception:
                return 1
        return 1

    async def detect_language(self, text: str) -> str:
        """
        Detect whether document is in Hindi (Devanagari \u0900-\u097F), English, or Bilingual.
        """
        has_devanagari = bool(re.search(r"[\u0900-\u097F]", text))
        has_latin = bool(re.search(r"[a-zA-Z]", text))

        if has_devanagari and has_latin:
            return "Bilingual (Hindi/English)"
        elif has_devanagari:
            return "Hindi"
        elif has_latin:
            return "English"
        return "Unknown"

    async def extract_text(
        self,
        file_bytes: bytes,
        mime_type: str,
        file_name: str
    ) -> Tuple[str, int, Dict[int, str]]:
        """
        Extract text while preserving page numbers.
        Returns (full_text, total_pages, {page_num: page_text})
        """
        pages_map: Dict[int, str] = {}

        # 1. Try PDF extraction
        if file_bytes.startswith(b"%PDF-") or mime_type == "application/pdf":
            try:
                import pypdf
                reader = pypdf.PdfReader(io.BytesIO(file_bytes))
                for idx, page in enumerate(reader.pages, start=1):
                    txt = page.extract_text() or ""
                    pages_map[idx] = txt.strip()
                if pages_map:
                    full_text = "\n\n".join(pages_map.values())
                    return full_text, len(reader.pages), pages_map
            except Exception:
                pass

        # 2. Try text/plain decoding
        try:
            decoded = file_bytes.decode("utf-8")
            pages_map[1] = decoded.strip()
            return decoded.strip(), 1, pages_map
        except UnicodeDecodeError:
            pass

        # 3. Fallback check for printable characters
        printable = "".join(chr(b) for b in file_bytes if 32 <= b <= 126 or b in (10, 13))
        if len(printable.strip()) >= 15:
            pages_map[1] = printable.strip()
            return printable.strip(), 1, pages_map

        # If unreadable/corrupted
        pages_map[1] = ""
        return "", 0, pages_map

    async def extract_tables(
        self,
        file_bytes: bytes,
        mime_type: str
    ) -> List[Dict[str, Any]]:
        """
        Extract tabular sections like Schedules of Property or Khatedar Share records.
        """
        tables: List[Dict[str, Any]] = []
        try:
            text = file_bytes.decode("utf-8", errors="ignore")
            # Identify Schedule of Property or tabular rows
            schedule_match = re.search(
                r"(?:SCHEDULE OF PROPERTY|RECORD OF RIGHTS|KHATEDAR DETAILS)[\s:]*([^\n\r]+(?:\n[^\n\r]+){1,10})",
                text,
                re.IGNORECASE
            )
            if schedule_match:
                lines = schedule_match.group(1).strip().split("\n")
                rows = []
                for line in lines:
                    if ":" in line:
                        k, v = line.split(":", 1)
                        rows.append({"key": k.strip(), "value": v.strip()})
                if rows:
                    tables.append({
                        "table_name": "Schedule of Property",
                        "rows": rows,
                        "page": 1,
                    })
        except Exception:
            pass
        return tables


synthetic_parser = SyntheticDocumentParser()

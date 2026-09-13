"""
Document Classification Service for PropZen GlobalVerificationEngine
Classifies property instruments with explicit confidence scores and fallback to UNKNOWN.
"""
import re
from typing import Dict, Any, Tuple
from ..models.enums import DocumentType


class DocumentClassificationService:
    """
    Categorizes property-related documents into standard legal types.
    Strictly assigns UNKNOWN if confidence falls below threshold. Never guesses.
    """

    CLASSIFICATION_PATTERNS = {
        DocumentType.SALE_DEED: [
            (r"\b(?:SALE\s*DEED|DEED\s*OF\s*SALE|बैनामा|विक्रय\s*पत्र)\b", 0.96),
            (r"\b(?:CONVEYANCE\s*DEED|VENDOR|PURCHASER|FIRST\s*PARTY|SECOND\s*PARTY)\b", 0.85),
        ],
        DocumentType.REGISTRY: [
            (r"\b(?:OFFICE\s*OF\s*(?:THE\s*)?SUB-REGISTRAR|REGISTRATION\s*PARTICULARS|निबंधन\s*कार्यालय|उप\s*निबंधक)\b", 0.94),
            (r"\b(?:BAHI\s*NO|JILD\s*NO|BOOK\s*NO|REGISTRATION\s*FEE)\b", 0.88),
        ],
        DocumentType.KHATAUNI: [
            (r"\b(?:KHATAUNI|RECORD\s*OF\s*RIGHTS|खतौनी|भूलेख|ROR|उद्धरण\s*खतौनी)\b", 0.95),
            (r"\b(?:KHASRA\s*NO|KHATA\s*NO|KHATEDAR|FASLI\s*YEAR|खातेदार)\b", 0.90),
        ],
        DocumentType.PROPERTY_TAX: [
            (r"\b(?:PROPERTY\s*TAX|MUNICIPAL\s*TAX|HOUSE\s*TAX|गृह\s*कर|MUNICIPAL\s*CORPORATION\s*TAX|TAX\s*RECEIPT)\b", 0.95),
            (r"\b(?:TAX\s*ASSESSMENT|ANNUAL\s*RATEABLE\s*VALUE|ARV|HOLDING\s*TAX)\b", 0.86),
        ],
        DocumentType.ENCUMBRANCE: [
            (r"\b(?:ENCUMBRANCE\s*CERTIFICATE|NON-ENCUMBRANCE|NIL\s*ENCUMBRANCE|FORM\s*NO\.?\s*15|FORM\s*NO\.?\s*16|भारमुक्त)\b", 0.95),
            (r"\b(?:LIEN|CHARGE|SEARCH\s*PERIOD|NO\s*ACTS\s*ENCUMBERING)\b", 0.85),
        ],
        DocumentType.ALLOTMENT: [
            (r"\b(?:ALLOTMENT\s*LETTER|LETTER\s*OF\s*ALLOTMENT|आवंटन\s*पत्र|ALLOTTEE)\b", 0.95),
            (r"\b(?:ALLOTMENT\s*PRICE|NOIDA\s*AUTHORITY\s*ALLOTMENT|YEIDA\s*ALLOTMENT|DDA\s*ALLOTMENT)\b", 0.90),
        ],
        DocumentType.POSSESSION: [
            (r"\b(?:POSSESSION\s*LETTER|POSSESSION\s*CERTIFICATE|कब्जा\s*प्रमाण\s*पत्र|HANDING\s*OVER\s*POSSESSION)\b", 0.95),
            (r"\b(?:KEY\s*HANDOVER|POSSESSION\s*OFFER)\b", 0.85),
        ],
        DocumentType.COURT_DOCUMENT: [
            (r"\b(?:HON'BLE|DISTRICT\s*COURT|HIGH\s*COURT|CIVIL\s*SUIT|ORIGINAL\s*SUIT|INJUNCTION|STAY\s*ORDER| न्यायालय)\b", 0.95),
            (r"\b(?:PETITIONER|RESPONDENT|PLAINTIFF|DEFENDANT|CASE\s*NO)\b", 0.88),
        ],
    }

    def classify_document(self, text: str, file_name: str = "") -> Dict[str, Any]:
        """
        Input: Document raw text and file name.
        Output: {'document_type': 'SALE_DEED', 'confidence': 0.94}
        """
        combined = f"{file_name} {text}".upper()
        if not text or len(text.strip()) < 15:
            return {
                "document_type": DocumentType.UNKNOWN.value,
                "confidence": 0.0,
            }

        best_type = DocumentType.UNKNOWN
        best_confidence = 0.0

        for doc_type, patterns in self.CLASSIFICATION_PATTERNS.items():
            for regex, score in patterns:
                if re.search(regex, combined, re.IGNORECASE):
                    if score > best_confidence:
                        best_confidence = score
                        best_type = doc_type

        # Low confidence guard: if below 0.50, return UNKNOWN
        if best_confidence < 0.50:
            return {
                "document_type": DocumentType.UNKNOWN.value,
                "confidence": round(best_confidence, 2),
            }

        return {
            "document_type": best_type.value,
            "confidence": round(best_confidence, 2),
        }


classification_service = DocumentClassificationService()

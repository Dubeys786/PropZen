"""
Synthetic Document AI Provider for PropZen GlobalVerificationEngine
Performs deterministic, rule-based extraction from synthetic Indian real estate documents,
enabling fast, zero-cost, reproducible offline testing and development.
"""
import io
import re
from typing import Optional, Dict, Any, Tuple, List
from ..models.enums import DocumentType
from ..models.schemas import (
    ExtractedData,
    PropertyFields,
    OwnershipFields,
    TransactionFields,
    MetadataFields,
    FieldExtractionResult,
)
from .base import DocumentAIProvider
from .synthetic_parser import synthetic_parser
from ..services.classification_service import classification_service


class SyntheticDocumentAIProvider(DocumentAIProvider):
    @property
    def provider_name(self) -> str:
        return "synthetic"

    async def extract_text(
        self,
        file_bytes: bytes,
        mime_type: str,
        file_name: str
    ) -> Tuple[str, int]:
        """Extract text from PDF, text, or simulate OCR extraction for image payloads."""
        full_text, pages, _ = await synthetic_parser.extract_text(file_bytes, mime_type, file_name)
        return full_text, pages

    async def classify_document(
        self,
        text: str,
        file_name: str
    ) -> DocumentType:
        """Classify document using DocumentClassificationService."""
        res = classification_service.classify_document(text, file_name)
        raw_type = res["document_type"]
        try:
            return DocumentType(raw_type)
        except ValueError:
            return DocumentType.UNKNOWN

    async def extract_fields(
        self,
        text: str,
        document_type: Optional[DocumentType] = None
    ) -> ExtractedData:
        """
        Deterministic regex extraction adhering to standard Indian property documentation formats.
        Missing values remain None and are appended to missing_fields.
        Populates granular field_metadata with confidence and extraction method.
        """
        detected: List[str] = []
        field_meta: Dict[str, FieldExtractionResult] = {}
        expected_fields = [
            "owner_name",
            "property_address",
            "plot_number",
            "khasra_number",
            "property_area",
            "registration_number",
            "registration_date",
            "execution_date",
        ]

        def search_pattern(patterns: List[str], field_name: str) -> Optional[str]:
            for pat in patterns:
                m = re.search(pat, text, re.IGNORECASE)
                if m:
                    res = m.group(1).strip()
                    if res:
                        detected.append(field_name)
                        field_meta[field_name] = FieldExtractionResult(
                            value=res,
                            confidence=0.94,
                            source_page=1,
                            extraction_method="OCR+RULE"
                        )
                        return res
            return None

        # 1. PROPERTY FIELDS
        prop_address = search_pattern([
            r"(?:property address|situated at|address|location|संपत्ति का पता)[\s:]+([^\n\r,]+(?:,[^\n\r,]+){1,3})",
            r"(?:at plot|located at)[\s:]+([^\n\r]+)",
        ], "property_address")

        village = search_pattern([
            r"(?:village|mouza|ग्राम|मौजा)[\s:]+([A-Za-z0-9\s\-]+?)(?:,|$|\n|tehsil|district)",
        ], "village")

        district = search_pattern([
            r"(?:district|dist\.?|जिला)[\s:]+([A-Za-z0-9\s\-]+?)(?:,|$|\n|state|pin)",
        ], "district")

        state = search_pattern([
            r"(?:state|राज्य)[\s:]+([A-Za-z0-9\s\-]+?)(?:,|$|\n|pin)",
        ], "state")

        tehsil = search_pattern([
            r"(?:tehsil|taluka|तहसील)[\s:]+([A-Za-z0-9\s\-]+?)(?:,|$|\n|district)",
        ], "tehsil")

        plot_no = search_pattern([
            r"(?:plot\s*no\.?|plot\s*number|भूखंड\s*संख्या)[\s:]+([A-Za-z0-9\/\-]+)",
        ], "plot_number")

        khasra_no = search_pattern([
            r"(?:khasra\s*no\.?|khasra\s*number|खसरा\s*नं\.?)[\s:]+([A-Za-z0-9\/\-]+)",
        ], "khasra_number")

        khata_no = search_pattern([
            r"(?:khata\s*no\.?|khata\s*number|खाता\s*नं\.?)[\s:]+([A-Za-z0-9\/\-]+)",
        ], "khata_number")

        survey_no = search_pattern([
            r"(?:survey\s*no\.?|survey\s*number|सर्वे\s*नं\.?)[\s:]+([A-Za-z0-9\/\-]+)",
        ], "survey_number")

        # Property Area & Unit
        prop_area_val: Optional[float] = None
        area_unit_val: Optional[str] = None
        area_match = re.search(
            r"(?:property area|area|measuring|क्षेत्रफल)[\s:]+([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z\s\.\u0900-\u097F]+?)(?:,|$|\n|\.|\s*residential|\s*commercial)",
            text,
            re.IGNORECASE
        )
        if area_match:
            try:
                prop_area_val = float(area_match.group(1))
                area_unit_val = area_match.group(2).strip()
                detected.append("property_area")
                detected.append("area_unit")
                field_meta["property_area"] = FieldExtractionResult(
                    value=prop_area_val,
                    confidence=0.95,
                    source_page=1,
                    extraction_method="OCR+RULE"
                )
                field_meta["area_unit"] = FieldExtractionResult(
                    value=area_unit_val,
                    confidence=0.92,
                    source_page=1,
                    extraction_method="OCR+RULE"
                )
            except ValueError:
                pass

        prop_type = search_pattern([
            r"(?:property type|type of property)[\s:]+([A-Za-z\s]+)",
        ], "property_type")

        # 2. OWNERSHIP FIELDS
        owner_name = search_pattern([
            r"(?:owner name|owner|khatedar|purchaser|name of owner|मालिक का नाम)[\s:]+([A-Za-z\s\.]+?)(?:,|\n|s\/o|w\/o|d\/o|resident)",
            r"(?:in the name of)[\s:]+([A-Za-z\s\.]+?)(?:,|\n)",
        ], "owner_name")

        co_owners_str = search_pattern([
            r"(?:co-owners?|joint owners?)[\s:]+([^\n\r]+)",
        ], "co_owner_names")
        co_owners: List[str] = []
        if co_owners_str:
            co_owners = [c.strip() for c in co_owners_str.split(",") if c.strip()]

        seller_name = search_pattern([
            r"(?:seller name|vendor|first party|seller|विक्रेता)[\s:]+([A-Za-z\s\.]+?)(?:,|\n|s\/o|w\/o|resident)",
        ], "seller_name")

        buyer_name = search_pattern([
            r"(?:buyer name|purchaser|second party|buyer|क्रेता)[\s:]+([A-Za-z\s\.]+?)(?:,|\n|s\/o|w\/o|resident)",
        ], "buyer_name")

        previous_owner_name = search_pattern([
            r"(?:previous owner|prior owner|पूर्व स्वामी)[\s:]+([A-Za-z\s\.]+?)(?:,|\n)",
        ], "previous_owner_name")

        # 3. TRANSACTION FIELDS
        doc_no = search_pattern([
            r"(?:document\s*no\.?|document\s*number|दस्तावेज़\s*संख्या)[\s:]+([A-Za-z0-9\/\-_]+)",
        ], "document_number")

        reg_no = search_pattern([
            r"(?:registration\s*no\.?|registration\s*number|bahi\s*no\.?|पंजीकरण\s*संख्या)[\s:]+([A-Za-z0-9\/\-_]+)",
        ], "registration_number")

        # Dates
        def parse_date(raw_date: Optional[str]) -> Optional[str]:
            if not raw_date:
                return None
            clean = raw_date.strip()
            dmy = re.match(r"^(\d{2})[-/.](\d{2})[-/.](\d{4})$", clean)
            if dmy:
                return f"{dmy.group(3)}-{dmy.group(2)}-{dmy.group(1)}"
            ymd = re.match(r"^(\d{4})[-/.](\d{2})[-/.](\d{2})$", clean)
            if ymd:
                return f"{ymd.group(1)}-{ymd.group(2)}-{ymd.group(3)}"
            return clean

        raw_reg_date = search_pattern([
            r"(?:registration date|registered on|date of registration|पंजीकरण तिथि)[\s:]+([0-9]{2,4}[-/.][0-9]{2}[-/.][0-9]{2,4})",
        ], "registration_date")
        reg_date = parse_date(raw_reg_date)
        if reg_date and "registration_date" in field_meta:
            field_meta["registration_date"].value = reg_date

        raw_exec_date = search_pattern([
            r"(?:execution date|executed on|date of execution|निष्पादन तिथि)[\s:]+([0-9]{2,4}[-/.][0-9]{2}[-/.][0-9]{2,4})",
        ], "execution_date")
        exec_date = parse_date(raw_exec_date)
        if exec_date and "execution_date" in field_meta:
            field_meta["execution_date"].value = exec_date

        consideration_amount: Optional[float] = None
        raw_amt = search_pattern([
            r"(?:consideration amount|sale consideration|amount|प्रतिफल राशि)[\s:Rs\.\u20B9]+([0-9,]+(?:\.[0-9]+)?)",
        ], "consideration_amount")
        if raw_amt:
            try:
                consideration_amount = float(raw_amt.replace(",", ""))
                if "consideration_amount" in field_meta:
                    field_meta["consideration_amount"].value = consideration_amount
            except ValueError:
                pass

        stamp_duty: Optional[float] = None
        raw_duty = search_pattern([
            r"(?:stamp duty|duty paid|स्टाम्प शुल्क)[\s:Rs\.\u20B9]+([0-9,]+(?:\.[0-9]+)?)",
        ], "stamp_duty")
        if raw_duty:
            try:
                stamp_duty = float(raw_duty.replace(",", ""))
                if "stamp_duty" in field_meta:
                    field_meta["stamp_duty"].value = stamp_duty
            except ValueError:
                pass

        reg_office = search_pattern([
            r"(?:sub-registrar office|registration office|sro|उप निबंधक कार्यालय)[\s:]+([^\n\r]+)",
        ], "registration_office")

        # 4. DOCUMENT & METADATA
        doc_date = parse_date(search_pattern([
            r"(?:document date|date of deed)[\s:]+([0-9]{2,4}[-/.][0-9]{2}[-/.][0-9]{2,4})",
        ], "document_date"))

        ref_no = search_pattern([
            r"(?:reference\s*no\.?|ref\s*no\.?|file\s*number)[\s:]+([A-Za-z0-9\/\-_]+)",
        ], "reference_number")

        lang = await synthetic_parser.detect_language(text)

        missing = [field for field in expected_fields if field not in detected]
        confidence = round(max(0.15, min(0.98, len(detected) / max(len(expected_fields), 1))), 2)

        return ExtractedData(
            property=PropertyFields(
                property_address=prop_address,
                village=village,
                district=district,
                state=state,
                tehsil=tehsil,
                plot_number=plot_no,
                khasra_number=khasra_no,
                khata_number=khata_no,
                survey_number=survey_no,
                property_area=prop_area_val,
                area_unit=area_unit_val,
                property_type=prop_type,
            ),
            ownership=OwnershipFields(
                owner_name=owner_name,
                co_owner_names=co_owners,
                seller_name=seller_name,
                buyer_name=buyer_name,
                previous_owner_name=previous_owner_name,
            ),
            transaction=TransactionFields(
                document_number=doc_no,
                registration_number=reg_no,
                registration_date=reg_date,
                execution_date=exec_date,
                consideration_amount=consideration_amount,
                stamp_duty=stamp_duty,
                registration_office=reg_office,
            ),
            metadata=MetadataFields(
                document_language=lang,
                issuing_authority=reg_office or "Revenue Department / SRO",
                page_count=1,
                document_date=doc_date,
                reference_number=ref_no,
                detected_fields=detected,
                missing_fields=missing,
                extraction_confidence=confidence,
            ),
            field_metadata=field_meta,
        )

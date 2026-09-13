"""
Deterministic Validation Engine for PropZen GlobalVerificationEngine
Implements deterministic rules 1 through 10 with legal-safe phrasing and status classification:
PASS, WARNING, REVIEW_REQUIRED, HIGH_RISK, INSUFFICIENT_DATA.
"""
import re
from datetime import datetime
from typing import List, Dict, Any, Optional, Set
from ..models.enums import (
    DocumentType,
    VerificationStatus,
    FindingSeverity,
    FindingType,
)
from ..models.schemas import (
    ExtractedData,
    Finding,
)


class ValidationEngine:
    """
    Implements 10 deterministic rules for internal and cross-document verification.
    """

    RECOGNIZED_AREA_UNITS: Set[str] = {
        "sq ft", "sq. ft.", "sq.ft", "sqft", "sq feet", "square feet",
        "sq yard", "sq yards", "sq. yards", "sq. yd", "sqyd", "square yards",
        "sq meter", "sq meters", "sq. meter", "sq. mtr", "sqm", "square meters",
        "acre", "acres",
        "hectare", "hectares",
        "bigha", "biswa",
        "kanal", "marla",
        "guntha", "cent", "ground", "katha",
        "वर्ग गज", "वर्ग मीटर", "वर्ग फुट", "एकड़", "बीघा", "बिस्वा",
    }

    def validate_document(
        self,
        extracted: ExtractedData,
        document_type: DocumentType,
        raw_text: str = "",
        file_name: str = "document"
    ) -> List[Finding]:
        """
        Execute single-document internal consistency rules (Rules 1, 2, 3, 5-single, 9).
        """
        findings: List[Finding] = []

        # 0. Check for unreadable / degraded document
        if not raw_text or len(raw_text.strip()) < 15:
            findings.append(
                Finding(
                    finding="INSUFFICIENT_DOCUMENT_DATA",
                    severity=FindingSeverity.HIGH,
                    type=FindingType.OCR_UNCERTAINTY,
                    field="raw_text",
                    description="Insufficient legible text detected. Document scan may be corrupted, blurred, or empty.",
                    evidence=[{"document": file_name, "page": 1, "confidence": extracted.metadata.extraction_confidence}],
                    recommended_action="Upload a clean, high-resolution original document scan.",
                )
            )
            return findings

        # RULE 1: Registration date should not precede execution date
        reg_date_str = extracted.transaction.registration_date
        exec_date_str = extracted.transaction.execution_date
        if reg_date_str and exec_date_str:
            try:
                reg_date = datetime.strptime(reg_date_str, "%Y-%m-%d").date()
                exec_date = datetime.strptime(exec_date_str, "%Y-%m-%d").date()

                if reg_date < exec_date:
                    findings.append(
                        Finding(
                            finding="REGISTRATION_PRECEDES_EXECUTION",
                            severity=FindingSeverity.HIGH,
                            type=FindingType.INVALID_DATE_RELATIONSHIP,
                            field="registration_date",
                            description=(
                                f"Registration date ({reg_date_str}) is earlier than document "
                                f"execution date ({exec_date_str}). Chronologically contradictory."
                            ),
                            evidence=[
                                {"document": file_name, "page": 1, "registration_date": reg_date_str, "execution_date": exec_date_str}
                            ],
                            recommended_action="Potential inconsistency detected — manual/legal verification recommended.",
                        )
                    )
            except ValueError:
                pass

        # RULE 2: Property area must be positive
        area = extracted.property.property_area
        if area is not None:
            if area <= 0:
                findings.append(
                    Finding(
                        finding="INVALID_PROPERTY_AREA",
                        severity=FindingSeverity.HIGH,
                        type=FindingType.INVALID_NUMERIC_VALUE,
                        field="property_area",
                        description=f"Property area must be a positive number (> 0), extracted: {area}.",
                        evidence=[{"document": file_name, "page": 1, "extracted_area": area}],
                        recommended_action="Potential inconsistency detected — manual/legal verification recommended.",
                    )
                )
        else:
            # Missing area in title conveyance
            if document_type in (DocumentType.SALE_DEED, DocumentType.KHATAUNI, DocumentType.REGISTRY):
                findings.append(
                    Finding(
                        finding="MISSING_PROPERTY_AREA",
                        severity=FindingSeverity.MEDIUM,
                        type=FindingType.MISSING_CRITICAL_FIELD,
                        field="property_area",
                        description="Property area is missing or could not be reliably extracted from the deed.",
                        evidence=[{"document": file_name, "page": 1}],
                        recommended_action="Verify Schedule of Property in deed for physical boundary measurements.",
                    )
                )

        # RULE 3: Area unit must be recognized
        unit = extracted.property.area_unit
        if unit:
            clean_unit = unit.strip().lower()
            if clean_unit not in self.RECOGNIZED_AREA_UNITS:
                findings.append(
                    Finding(
                        finding="UNRECOGNIZED_AREA_UNIT",
                        severity=FindingSeverity.MEDIUM,
                        type=FindingType.UNRECOGNIZED_AREA_UNIT,
                        field="area_unit",
                        description=f"Area unit '{unit}' is not in the recognized land measurement taxonomy.",
                        evidence=[{"document": file_name, "page": 1, "area_unit": unit}],
                        recommended_action="Confirm local customary land measurement standards (e.g., standard Bigha vs Kacha Bigha).",
                    )
                )

        # RULE 5 (Single Doc): Owner / Party Name checks
        owner = extracted.ownership.owner_name or extracted.ownership.buyer_name
        if not owner and document_type in (DocumentType.SALE_DEED, DocumentType.KHATAUNI, DocumentType.REGISTRY):
            findings.append(
                Finding(
                    finding="MISSING_PRIMARY_OWNER",
                    severity=FindingSeverity.HIGH,
                    type=FindingType.MISSING_CRITICAL_FIELD,
                    field="owner_name",
                    description="Primary owner or purchaser name could not be identified.",
                    evidence=[{"document": file_name, "page": 1}],
                    recommended_action="Title clearance check recommended to establish legal ownership chain.",
                )
            )
        elif owner and re.search(r"\d", owner):
            findings.append(
                Finding(
                    finding="SUSPICIOUS_PARTY_NAME",
                    severity=FindingSeverity.MEDIUM,
                    type=FindingType.SUSPICIOUS_NAME_VARIATION,
                    field="owner_name",
                    description=f"Extracted party name contains numeric characters: '{owner}'.",
                    evidence=[{"document": file_name, "page": 1, "raw_name": owner}],
                    recommended_action="Manual verification of physical seal and stamp endorsement required.",
                )
            )

        # Check self-transaction
        seller = extracted.ownership.seller_name
        buyer = extracted.ownership.buyer_name
        if seller and buyer and self._normalize_name(seller) == self._normalize_name(buyer):
            findings.append(
                Finding(
                    finding="IDENTICAL_BUYER_SELLER",
                    severity=FindingSeverity.HIGH,
                    type=FindingType.SUSPICIOUS_NAME_VARIATION,
                    field="buyer_seller",
                    description="First party (seller) and second party (buyer) are identical.",
                    evidence=[{"document": file_name, "page": 1, "seller": seller, "buyer": buyer}],
                    recommended_action="Potential inconsistency detected — manual/legal verification recommended.",
                )
            )

        # RULE 9: Document / Registration number format
        doc_num = extracted.transaction.document_number or extracted.transaction.registration_number
        if doc_num:
            cleaned_doc = re.sub(r"[\s\-_/]", "", doc_num)
            if len(cleaned_doc) < 2 or cleaned_doc == "0" * len(cleaned_doc):
                findings.append(
                    Finding(
                        finding="INVALID_DOCUMENT_NUMBER_FORMAT",
                        severity=FindingSeverity.MEDIUM,
                        type=FindingType.UNSUPPORTED_FORMAT,
                        field="document_number",
                        description=f"Document identifier '{doc_num}' has an irregular or placeholder format.",
                        evidence=[{"document": file_name, "page": 1, "document_number": doc_num}],
                        recommended_action="Verify registration seal with local Sub-Registrar Office index book.",
                    )
                )

        # Check unknown document type
        if document_type == DocumentType.UNKNOWN:
            findings.append(
                Finding(
                    finding="UNKNOWN_DOCUMENT_TYPE",
                    severity=FindingSeverity.MEDIUM,
                    type=FindingType.UNKNOWN_DOCUMENT_TYPE,
                    field="document_type",
                    description="Document type could not be confidently identified from content.",
                    evidence=[{"document": file_name, "page": 1}],
                    recommended_action="Ensure the uploaded file is a recognized property document.",
                )
            )

        # Low OCR confidence
        if extracted.metadata.extraction_confidence < 0.60:
            findings.append(
                Finding(
                    finding="LOW_OCR_CONFIDENCE",
                    severity=FindingSeverity.LOW,
                    type=FindingType.OCR_UNCERTAINTY,
                    field="extraction_confidence",
                    description=f"Extraction confidence is low ({int(extracted.metadata.extraction_confidence * 100)}%).",
                    evidence=[{"document": file_name, "confidence": extracted.metadata.extraction_confidence}],
                    recommended_action="Review high-resolution original certified copy.",
                )
            )

        return findings

    def validate_cross_document(
        self,
        documents_data: List[Dict[str, Any]]
    ) -> List[Finding]:
        """
        Execute multi-document cross-verification (Rules 4, 5, 6, 7, 8, 10).
        """
        findings: List[Finding] = []
        if len(documents_data) < 2:
            return findings

        # RULE 10: Duplicate Document Detection (by SHA-256 or identical numbers)
        seen_hashes: Dict[str, str] = {}
        for doc in documents_data:
            sha = doc.get("sha256_hash")
            name = doc.get("file_name", "Document")
            if sha:
                if sha in seen_hashes:
                    findings.append(
                        Finding(
                            finding="DUPLICATE_DOCUMENT_UPLOADED",
                            severity=FindingSeverity.LOW,
                            type=FindingType.DUPLICATE_RECORD,
                            field="sha256_hash",
                            description=f"Duplicate document detected: '{name}' is byte-identical to '{seen_hashes[sha]}'.",
                            evidence=[{"document_1": seen_hashes[sha], "document_2": name}],
                            recommended_action="Review case attachments to avoid redundant verification runs.",
                        )
                    )
                else:
                    seen_hashes[sha] = name

        # Pairwise comparison between first two primary documents
        doc_a = documents_data[0]
        doc_b = documents_data[1]
        data_a: ExtractedData = doc_a["extracted_data"]
        data_b: ExtractedData = doc_b["extracted_data"]
        name_a: str = doc_a.get("file_name", "Document 1")
        name_b: str = doc_b.get("file_name", "Document 2")

        # RULE 5: Compare Owner Names (Normalized while keeping original available)
        owner_a = data_a.ownership.owner_name or data_a.ownership.buyer_name
        owner_b = data_b.ownership.owner_name or data_b.ownership.buyer_name
        if owner_a and owner_b:
            norm_a = self._normalize_name(owner_a)
            norm_b = self._normalize_name(owner_b)
            if norm_a != norm_b and not self._is_fuzzy_name_match(norm_a, norm_b):
                findings.append(
                    Finding(
                        finding="OWNER_NAME_MISMATCH",
                        severity=FindingSeverity.HIGH,
                        type=FindingType.FIELD_MISMATCH,
                        field="owner_name",
                        description=f"Owner name mismatch between uploaded documents: '{owner_a}' ({name_a}) vs '{owner_b}' ({name_b}).",
                        evidence=[
                            {"document": name_a, "page": 1, "owner_name": owner_a, "normalized": norm_a},
                            {"document": name_b, "page": 1, "owner_name": owner_b, "normalized": norm_b}
                        ],
                        recommended_action="Obtain and manually verify the latest ownership record.",
                    )
                )

        # RULE 4 & RULE 6: Compare Property Identifiers (Plot, Khasra, Khata, Survey)
        plot_a = data_a.property.plot_number or data_a.property.khasra_number or data_a.property.khata_number
        plot_b = data_b.property.plot_number or data_b.property.khasra_number or data_b.property.khata_number
        if plot_a and plot_b:
            clean_a = re.sub(r"[\s\-_/]", "", str(plot_a)).upper()
            clean_b = re.sub(r"[\s\-_/]", "", str(plot_b)).upper()
            if clean_a != clean_b:
                findings.append(
                    Finding(
                        finding="PROPERTY_IDENTIFIER_MISMATCH",
                        severity=FindingSeverity.HIGH,
                        type=FindingType.FIELD_MISMATCH,
                        field="plot_number",
                        description=f"Property identifier differs: '{plot_a}' ({name_a}) vs '{plot_b}' ({name_b}).",
                        evidence=[
                            {"document": name_a, "page": 1, "identifier": plot_a},
                            {"document": name_b, "page": 1, "identifier": plot_b}
                        ],
                        recommended_action="Potential inconsistency detected — manual/legal verification recommended.",
                    )
                )

        # Compare Property Area
        area_a = data_a.property.property_area
        area_b = data_b.property.property_area
        if area_a is not None and area_b is not None:
            diff = abs(area_a - area_b)
            avg = (area_a + area_b) / 2.0
            if avg > 0 and (diff / avg) > 0.02:  # > 2% difference
                findings.append(
                    Finding(
                        finding="PROPERTY_AREA_MISMATCH",
                        severity=FindingSeverity.HIGH,
                        type=FindingType.FIELD_MISMATCH,
                        field="property_area",
                        description=(
                            f"Property area differs between supplied documents: {area_a} {data_a.property.area_unit or ''} "
                            f"({name_a}) vs {area_b} {data_b.property.area_unit or ''} ({name_b})."
                        ),
                        evidence=[
                            {"document": name_a, "page": 1, "property_area": area_a, "unit": data_a.property.area_unit},
                            {"document": name_b, "page": 1, "property_area": area_b, "unit": data_b.property.area_unit}
                        ],
                        recommended_action="Manual verification required.",
                    )
                )

        # RULE 7: Address Component Comparison (Village, District, State)
        dist_a = data_a.property.district or data_a.property.village
        dist_b = data_b.property.district or data_b.property.village
        if dist_a and dist_b:
            norm_da = dist_a.strip().upper()
            norm_db = dist_b.strip().upper()
            if norm_da != norm_db and norm_da not in norm_db and norm_db not in norm_da:
                findings.append(
                    Finding(
                        finding="ADDRESS_LOCALITY_MISMATCH",
                        severity=FindingSeverity.HIGH,
                        type=FindingType.FIELD_MISMATCH,
                        field="district",
                        description=f"Address component mismatch: '{dist_a}' ({name_a}) vs '{dist_b}' ({name_b}).",
                        evidence=[
                            {"document": name_a, "locality": dist_a},
                            {"document": name_b, "locality": dist_b}
                        ],
                        recommended_action="Potential inconsistency detected — manual/legal verification recommended.",
                    )
                )

        # RULE 8 & 9: Registration / Document Numbers Conflicts
        reg_a = data_a.transaction.registration_number
        reg_b = data_b.transaction.registration_number
        if reg_a and reg_b and doc_a.get("document_type") == doc_b.get("document_type"):
            clean_ra = re.sub(r"[\s\-_/]", "", reg_a).upper()
            clean_rb = re.sub(r"[\s\-_/]", "", reg_b).upper()
            if clean_ra != clean_rb:
                findings.append(
                    Finding(
                        finding="REGISTRATION_NUMBER_CONFLICT",
                        severity=FindingSeverity.HIGH,
                        type=FindingType.FIELD_MISMATCH,
                        field="registration_number",
                        description=f"Registration numbers conflict across identical document categories: '{reg_a}' vs '{reg_b}'.",
                        evidence=[
                            {"document": name_a, "registration_number": reg_a},
                            {"document": name_b, "registration_number": reg_b}
                        ],
                        recommended_action="Verify index registration entry at the Sub-Registrar Office.",
                    )
                )

        return findings

    def determine_status(
        self,
        findings: List[Finding],
        extracted_data: ExtractedData,
        raw_text: str = ""
    ) -> VerificationStatus:
        """
        Classifies status into: PASS, WARNING, REVIEW_REQUIRED, HIGH_RISK, INSUFFICIENT_DATA.
        """
        if not raw_text or len(raw_text.strip()) < 15:
            return VerificationStatus.INSUFFICIENT_DATA

        has_high_or_crit = any(
            f.severity in (FindingSeverity.HIGH, FindingSeverity.CRITICAL)
            for f in findings
        )
        if has_high_or_crit:
            return VerificationStatus.HIGH_RISK

        has_medium = any(
            f.severity == FindingSeverity.MEDIUM
            for f in findings
        )
        if has_medium or len(extracted_data.metadata.missing_fields) >= 4:
            return VerificationStatus.REVIEW_REQUIRED

        has_low = any(
            f.severity == FindingSeverity.LOW
            for f in findings
        )
        if has_low:
            return VerificationStatus.WARNING

        return VerificationStatus.PASS

    def _normalize_name(self, name: str) -> str:
        clean = name.upper()
        clean = re.sub(r"\b(SHRI|SHREE|SMT|SHRIMATI|MR|MRS|MS|DR|LATE)\b\.?", "", clean)
        clean = re.sub(r"\s+", " ", clean).strip()
        return clean

    def _is_fuzzy_name_match(self, name1: str, name2: str) -> bool:
        tokens1 = set(name1.split())
        tokens2 = set(name2.split())
        if not tokens1 or not tokens2:
            return False
        intersection = tokens1.intersection(tokens2)
        return len(intersection) >= min(len(tokens1), len(tokens2))


validation_engine = ValidationEngine()

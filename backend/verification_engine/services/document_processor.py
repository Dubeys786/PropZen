"""
Document Processor Orchestrator for PropZen GlobalVerificationEngine
Coordinates the complete Phase 1 pipeline:
File Signature Validation -> OCR/Parser -> Classification -> Field Extraction -> Validation -> Cross-Matching -> Risk Analysis -> Report.
"""
import os
import logging
from typing import Dict, Any, List, Optional
from ..models.enums import DocumentType, VerificationStatus, RiskLevel
from ..models.schemas import (
    ExtractedData,
    Finding,
    VerificationAnalyzeResponse,
    AuditLogEntry,
)
from ..providers.factory import get_document_ai_provider
from ..providers.synthetic_parser import synthetic_parser
from ..services.classification_service import classification_service
from .validation_engine import validation_engine
from .risk_engine import risk_engine
from .repository import repository
from ..core.audit import audit_logger

logger = logging.getLogger("document_processor")


class DocumentProcessor:
    def __init__(self):
        self._doc_content_cache: Dict[str, bytes] = {}

    def cache_document_content(self, doc_id: str, content: bytes) -> None:
        self._doc_content_cache[doc_id] = content

    def get_document_content(self, doc_id: str) -> Optional[bytes]:
        return self._doc_content_cache.get(doc_id)

    async def analyze_case(self, case_id: str) -> VerificationAnalyzeResponse:
        """
        Execute full Phase 1 verification pipeline for the given case.
        """
        case = await repository.get_case(case_id)
        if not case:
            raise ValueError(f"Verification case '{case_id}' not found.")

        documents = await repository.get_documents(case_id)
        if not documents:
            raise ValueError(f"No documents uploaded for verification case '{case_id}'.")

        ai_provider = get_document_ai_provider()
        audit_logger.log_event(case_id, "ANALYSIS_STARTED", details={"doc_count": len(documents), "provider": ai_provider.provider_name})

        per_doc_results: List[Dict[str, Any]] = []
        all_findings: List[Finding] = []
        documents_summary: List[Dict[str, Any]] = []
        aggregated_extracted = ExtractedData()
        primary_doc_type = case.document_type

        # Process each uploaded document
        for doc in documents:
            doc_id = doc["id"]
            file_name = doc["file_name"]
            content = self.get_document_content(doc_id)
            if not content:
                if os.path.exists(doc.get("storage_path", "")):
                    with open(doc["storage_path"], "rb") as f:
                        content = f.read()
                else:
                    content = b""

            mime_type = doc.get("mime_type", "application/pdf")

            # 1. Validate File Signature & Compute SHA-256 for duplicate detection
            sha256_hash = synthetic_parser.compute_sha256(content) if content else None

            # 2. Text, Table, & Language Extraction via DocumentParserProvider
            raw_text, page_count, _ = await synthetic_parser.extract_text(content, mime_type, file_name)

            # 3. Document Classification Service
            classification_result = classification_service.classify_document(raw_text, file_name)
            detected_doc_type_str = classification_result["document_type"]
            try:
                classified_type = DocumentType(detected_doc_type_str)
            except ValueError:
                classified_type = DocumentType.UNKNOWN

            if primary_doc_type in (DocumentType.GENERIC_PROPERTY_DOCUMENT, DocumentType.UNKNOWN):
                primary_doc_type = classified_type

            # 4. Structured Field Extraction with Confidence
            extracted = await ai_provider.extract_fields(raw_text, classified_type)

            # 5. Deterministic Validation for this document
            doc_findings = validation_engine.validate_document(extracted, classified_type, raw_text, file_name)
            all_findings.extend(doc_findings)

            # Persist extracted fields
            await repository.save_extracted_fields(case_id, doc_id, extracted)

            per_doc_results.append({
                "doc_id": doc_id,
                "file_name": file_name,
                "document_type": classified_type,
                "sha256_hash": sha256_hash,
                "raw_text": raw_text,
                "extracted_data": extracted,
                "page_count": page_count,
            })

            documents_summary.append({
                "document_id": doc_id,
                "file_name": file_name,
                "document_type": classified_type.value,
                "page_count": page_count,
                "sha256_hash": sha256_hash,
            })

            if len(extracted.metadata.detected_fields) >= len(aggregated_extracted.metadata.detected_fields):
                aggregated_extracted = extracted

        # 6. Multi-Document Cross Verification (if 2+ documents in case)
        if len(per_doc_results) >= 2:
            cross_findings = validation_engine.validate_cross_document(per_doc_results)
            all_findings.extend(cross_findings)

        # 7. Classify Overall Verification Status
        primary_raw_text = per_doc_results[0]["raw_text"] if per_doc_results else ""
        status = validation_engine.determine_status(all_findings, aggregated_extracted, primary_raw_text)

        # 8. Explainable Risk Engine
        risk_analysis = risk_engine.evaluate_risk(
            findings=all_findings,
            status=status,
            missing_fields=aggregated_extracted.metadata.missing_fields
        )

        # Collect recommended actions
        recommended_actions_list = [risk_analysis.recommended_action]
        for f in all_findings:
            if f.recommended_action and f.recommended_action not in recommended_actions_list:
                recommended_actions_list.append(f.recommended_action)

        # Persist findings & update case
        await repository.save_findings(case_id, all_findings)
        await repository.update_case_result(
            case_id=case_id,
            status=status,
            risk_score=risk_analysis.risk_score,
            risk_level=risk_analysis.risk_level,
            document_type=primary_doc_type,
            recommended_action=risk_analysis.recommended_action
        )

        # Audit event
        audit_entry = AuditLogEntry(
            case_id=case_id,
            action="PHASE_1_ANALYSIS_COMPLETED",
            actor="system",
            details={
                "status": status.value,
                "risk_score": risk_analysis.risk_score,
                "risk_level": risk_analysis.risk_level.value,
                "findings_count": len(all_findings),
            }
        )
        await repository.log_audit(audit_entry)
        audit_logger.log_event(case_id, "PHASE_1_ANALYSIS_COMPLETED", details=audit_entry.details)

        return VerificationAnalyzeResponse(
            case_id=case_id,
            status=status,
            risk_score=risk_analysis.risk_score,
            risk_level=risk_analysis.risk_level,
            document_type=primary_doc_type,
            documents=documents_summary,
            extracted_data=aggregated_extracted.to_flat_dict(),
            field_details=aggregated_extracted.to_granular_dict(),
            findings=all_findings,
            missing_fields=aggregated_extracted.metadata.missing_fields,
            recommended_actions=recommended_actions_list,
            recommended_action=risk_analysis.recommended_action,
            disclaimer="AI-assisted preliminary verification. This result does not constitute legal title certification."
        )


document_processor = DocumentProcessor()

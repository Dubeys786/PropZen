"""
Supabase & In-Memory Repository for PropZen GlobalVerificationEngine
Persists cases, documents, extracted fields, findings, and audit trails.
"""
import uuid
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from ..models.enums import DocumentType, VerificationStatus, RiskLevel
from ..models.schemas import (
    VerificationCaseCreate,
    VerificationCaseResponse,
    DocumentUploadResponse,
    Finding,
    ExtractedData,
    AuditLogEntry,
)
from ..core.config import settings

logger = logging.getLogger("verification_repo")


class SupabaseVerificationRepository:
    def __init__(self):
        self._supabase_client = None
        self._mock_mode = settings.ENABLE_MOCK_REPO or not settings.SUPABASE_URL

        # In-memory mock store
        self._cases: Dict[str, Dict[str, Any]] = {}
        self._documents: Dict[str, List[Dict[str, Any]]] = {}
        self._extracted_fields: Dict[str, List[Dict[str, Any]]] = {}
        self._findings: Dict[str, List[Dict[str, Any]]] = {}
        self._audit_logs: Dict[str, List[Dict[str, Any]]] = {}

        if not self._mock_mode:
            try:
                from supabase import create_client
                key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_ANON_KEY
                self._supabase_client = create_client(settings.SUPABASE_URL, key)
                logger.info("Supabase client initialized successfully.")
            except Exception as e:
                logger.warning(f"Failed to connect to Supabase: {e}. Falling back to in-memory store.")
                self._mock_mode = True

    @property
    def is_mock(self) -> bool:
        return self._mock_mode

    async def create_case(self, data: VerificationCaseCreate) -> VerificationCaseResponse:
        case_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        record = {
            "id": case_id,
            "user_id": data.user_id or "anonymous_user",
            "property_id": data.property_id,
            "document_type": data.document_type.value if data.document_type else DocumentType.GENERIC_PROPERTY_DOCUMENT.value,
            "status": VerificationStatus.PENDING.value,
            "risk_score": 0,
            "risk_level": RiskLevel.LOW.value,
            "notes": data.notes,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
        }

        if not self._mock_mode and self._supabase_client:
            try:
                self._supabase_client.table("verification_cases").insert(record).execute()
            except Exception as e:
                logger.error(f"Supabase insert failed: {e}. Falling back to local store.")
                self._cases[case_id] = record
        else:
            self._cases[case_id] = record

        return VerificationCaseResponse(
            case_id=case_id,
            user_id=record["user_id"],
            property_id=record["property_id"],
            document_type=DocumentType(record["document_type"]),
            status=VerificationStatus(record["status"]),
            risk_score=record["risk_score"],
            risk_level=RiskLevel(record["risk_level"]),
            created_at=now,
            updated_at=now,
        )

    async def get_case(self, case_id: str) -> Optional[VerificationCaseResponse]:
        if not self._mock_mode and self._supabase_client:
            try:
                resp = self._supabase_client.table("verification_cases").select("*").eq("id", case_id).execute()
                if resp.data:
                    row = resp.data[0]
                    return VerificationCaseResponse(
                        case_id=row["id"],
                        user_id=row["user_id"],
                        property_id=row.get("property_id"),
                        document_type=DocumentType(row["document_type"]),
                        status=VerificationStatus(row["status"]),
                        risk_score=row["risk_score"],
                        risk_level=RiskLevel(row["risk_level"]),
                        created_at=datetime.fromisoformat(row["created_at"]),
                        updated_at=datetime.fromisoformat(row["updated_at"]),
                    )
            except Exception as e:
                logger.error(f"Supabase get_case failed: {e}")

        if case_id in self._cases:
            row = self._cases[case_id]
            return VerificationCaseResponse(
                case_id=row["id"],
                user_id=row["user_id"],
                property_id=row.get("property_id"),
                document_type=DocumentType(row["document_type"]),
                status=VerificationStatus(row["status"]),
                risk_score=row["risk_score"],
                risk_level=RiskLevel(row["risk_level"]),
                created_at=datetime.fromisoformat(row["created_at"]) if isinstance(row["created_at"], str) else row["created_at"],
                updated_at=datetime.fromisoformat(row["updated_at"]) if isinstance(row["updated_at"], str) else row["updated_at"],
            )
        return None

    async def add_document(
        self,
        case_id: str,
        file_name: str,
        document_type: DocumentType,
        storage_path: str,
        page_count: int = 1,
        mime_type: str = "application/pdf",
        file_size_bytes: int = 0,
    ) -> DocumentUploadResponse:
        doc_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        record = {
            "id": doc_id,
            "case_id": case_id,
            "file_name": file_name,
            "document_type": document_type.value,
            "storage_path": storage_path,
            "mime_type": mime_type,
            "file_size_bytes": file_size_bytes,
            "page_count": page_count,
            "created_at": now.isoformat(),
        }

        if not self._mock_mode and self._supabase_client:
            try:
                self._supabase_client.table("verification_documents").insert(record).execute()
            except Exception as e:
                logger.error(f"Supabase add_document failed: {e}")
                self._documents.setdefault(case_id, []).append(record)
        else:
            self._documents.setdefault(case_id, []).append(record)

        return DocumentUploadResponse(
            document_id=doc_id,
            case_id=case_id,
            file_name=file_name,
            document_type=document_type,
            page_count=page_count,
            storage_path=storage_path,
            created_at=now,
        )

    async def get_documents(self, case_id: str) -> List[Dict[str, Any]]:
        if not self._mock_mode and self._supabase_client:
            try:
                resp = self._supabase_client.table("verification_documents").select("*").eq("case_id", case_id).execute()
                return resp.data or []
            except Exception as e:
                logger.error(f"Supabase get_documents failed: {e}")
        return self._documents.get(case_id, [])

    async def save_extracted_fields(
        self,
        case_id: str,
        document_id: str,
        extracted_data: ExtractedData
    ) -> None:
        flat = extracted_data.to_flat_dict()
        now = datetime.now(timezone.utc).isoformat()
        records = [
            {
                "id": str(uuid.uuid4()),
                "case_id": case_id,
                "document_id": document_id,
                "field_name": k,
                "field_value": str(v),
                "confidence": extracted_data.metadata.extraction_confidence,
                "source_page": 1,
                "created_at": now,
            }
            for k, v in flat.items()
        ]

        if not self._mock_mode and self._supabase_client and records:
            try:
                self._supabase_client.table("extracted_fields").insert(records).execute()
            except Exception as e:
                logger.error(f"Supabase save_extracted_fields failed: {e}")
                self._extracted_fields.setdefault(case_id, []).extend(records)
        else:
            self._extracted_fields.setdefault(case_id, []).extend(records)

    async def save_findings(self, case_id: str, findings: List[Finding]) -> None:
        now = datetime.now(timezone.utc).isoformat()
        records = [
            {
                "id": str(uuid.uuid4()),
                "case_id": case_id,
                "finding_type": f.type.value,
                "severity": f.severity.value,
                "field": f.field,
                "description": f.description,
                "evidence": f.evidence if isinstance(f.evidence, dict) else {"details": f.evidence},
                "recommended_action": f.recommended_action,
                "created_at": now,
            }
            for f in findings
        ]

        if not self._mock_mode and self._supabase_client and records:
            try:
                self._supabase_client.table("verification_findings").insert(records).execute()
            except Exception as e:
                logger.error(f"Supabase save_findings failed: {e}")
                self._findings.setdefault(case_id, []).extend(records)
        else:
            self._findings.setdefault(case_id, []).extend(records)

    async def get_findings(self, case_id: str) -> List[Finding]:
        if not self._mock_mode and self._supabase_client:
            try:
                resp = self._supabase_client.table("verification_findings").select("*").eq("case_id", case_id).execute()
                if resp.data:
                    return [
                        Finding(
                            id=row["id"],
                            severity=row["severity"],
                            type=row["finding_type"],
                            field=row.get("field"),
                            description=row["description"],
                            evidence=row.get("evidence"),
                            recommended_action=row.get("recommended_action", "Manual verification required."),
                        )
                        for row in resp.data
                    ]
            except Exception as e:
                logger.error(f"Supabase get_findings failed: {e}")

        raw_list = self._findings.get(case_id, [])
        return [
            Finding(
                id=r.get("id"),
                severity=r["severity"],
                type=r["finding_type"],
                field=r.get("field"),
                description=r["description"],
                evidence=r.get("evidence"),
                recommended_action=r.get("recommended_action", "Manual verification required."),
            )
            for r in raw_list
        ]

    async def update_case_result(
        self,
        case_id: str,
        status: VerificationStatus,
        risk_score: int,
        risk_level: RiskLevel,
        document_type: DocumentType,
        recommended_action: str
    ) -> None:
        now = datetime.now(timezone.utc).isoformat()
        update_data = {
            "status": status.value,
            "risk_score": risk_score,
            "risk_level": risk_level.value,
            "document_type": document_type.value,
            "recommended_action": recommended_action,
            "updated_at": now,
        }

        if not self._mock_mode and self._supabase_client:
            try:
                self._supabase_client.table("verification_cases").update(update_data).eq("id", case_id).execute()
            except Exception as e:
                logger.error(f"Supabase update_case_result failed: {e}")
                if case_id in self._cases:
                    self._cases[case_id].update(update_data)
        else:
            if case_id in self._cases:
                self._cases[case_id].update(update_data)

    async def log_audit(self, entry: AuditLogEntry) -> None:
        now = datetime.now(timezone.utc).isoformat()
        record = {
            "id": entry.id or str(uuid.uuid4()),
            "case_id": entry.case_id,
            "action": entry.action,
            "actor": entry.actor,
            "details": entry.details,
            "created_at": now,
        }

        if not self._mock_mode and self._supabase_client:
            try:
                self._supabase_client.table("verification_audit_logs").insert(record).execute()
            except Exception as e:
                logger.error(f"Supabase log_audit failed: {e}")
                self._audit_logs.setdefault(entry.case_id, []).append(record)
        else:
            self._audit_logs.setdefault(entry.case_id, []).append(record)


repository = SupabaseVerificationRepository()

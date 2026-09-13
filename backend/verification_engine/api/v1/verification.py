"""
FastAPI Verification Router for PropZen GlobalVerificationEngine
"""
import os
import uuid
import tempfile
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from ...models.enums import DocumentType, VerificationStatus, RiskLevel
from ...models.schemas import (
    VerificationCaseCreate,
    VerificationCaseResponse,
    DocumentUploadResponse,
    VerificationAnalyzeResponse,
    Finding,
    HealthResponse,
    AuditLogEntry,
)
from ...core.config import settings
from ...core.security import (
    sanitize_filename,
    validate_file_upload,
    verify_api_key_dependency,
    verify_admin_dependency,
)
from ...core.audit import audit_logger
from ..dependencies import rate_limit_dependency
from ...services.repository import repository
from ...services.document_processor import document_processor

router = APIRouter(
    prefix="/api/v1/verification",
    tags=["Verification Engine"],
    dependencies=[Depends(rate_limit_dependency)],
)


@router.get("/health", response_model=HealthResponse, tags=["System"])
async def verification_health():
    """Service health and diagnostic status."""
    return HealthResponse(
        status="HEALTHY",
        service=settings.SERVICE_NAME,
        version=settings.VERSION,
        ai_provider=settings.AI_PROVIDER,
        storage_mode="MOCK_IN_MEMORY" if repository.is_mock else "SUPABASE_POSTGRESQL",
        timestamp=datetime.now(timezone.utc),
    )


@router.post(
    "/cases",
    response_model=VerificationCaseResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Verification Case",
)
async def create_verification_case(
    payload: VerificationCaseCreate,
    auth_user: str = Depends(verify_api_key_dependency),
):
    """
    Initialize a new property verification case container.
    """
    case = await repository.create_case(payload)
    audit_logger.log_event(
        case.case_id,
        "CASE_CREATED",
        actor=auth_user,
        details={"document_type": case.document_type.value, "property_id": case.property_id}
    )
    return case


@router.post(
    "/cases/{case_id}/documents",
    response_model=DocumentUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload Document to Verification Case",
)
async def upload_document(
    case_id: str,
    file: UploadFile = File(...),
    document_type: Optional[DocumentType] = Form(None),
    auth_user: str = Depends(verify_api_key_dependency),
):
    """
    Securely upload a property document (PDF, PNG, JPEG, TIFF) for a verification case.
    Validates file size, file signature/MIME, and sanitizes filenames.
    """
    case = await repository.get_case(case_id)
    if not case:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Verification case '{case_id}' not found."
        )

    # Read content
    content = await file.read()

    # Validate file
    validate_file_upload(
        filename=file.filename or "upload.pdf",
        content=content,
        content_type=file.content_type
    )

    clean_filename = sanitize_filename(file.filename or "document.pdf")
    doc_type = document_type or case.document_type or DocumentType.GENERIC_PROPERTY_DOCUMENT

    # Persist file to temp directory for safe processing
    temp_dir = os.path.join(tempfile.gettempdir(), "propzen_verification")
    os.makedirs(temp_dir, exist_ok=True)
    temp_path = os.path.join(temp_dir, f"{case_id}_{uuid.uuid4().hex[:6]}_{clean_filename}")

    try:
        with open(temp_path, "wb") as f:
            f.write(content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to store uploaded document: {str(e)}"
        )

    doc_response = await repository.add_document(
        case_id=case_id,
        file_name=clean_filename,
        document_type=doc_type,
        storage_path=temp_path,
        page_count=1,
        mime_type=file.content_type or "application/pdf",
        file_size_bytes=len(content),
    )

    # Cache content in memory for fast analysis
    document_processor.cache_document_content(doc_response.document_id, content)

    audit_logger.log_event(
        case_id,
        "DOCUMENT_UPLOADED",
        actor=auth_user,
        details={
            "document_id": doc_response.document_id,
            "file_name": clean_filename,
            "size_bytes": len(content),
            "document_type": doc_type.value,
        }
    )

    return doc_response


@router.post(
    "/cases/{case_id}/analyze",
    response_model=VerificationAnalyzeResponse,
    summary="Execute AI & Rule Verification Pipeline",
)
async def analyze_verification_case(
    case_id: str,
    auth_user: str = Depends(verify_api_key_dependency),
):
    """
    Execute AI document parsing, deterministic validation, cross-document correlation,
    and transparent risk scoring on all documents uploaded to this case.
    """
    try:
        result = await document_processor.analyze_case(case_id)
        return result
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(ve))
    except Exception as ex:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis pipeline error: {str(ex)}"
        )


@router.get(
    "/cases/{case_id}",
    response_model=VerificationCaseResponse,
    summary="Get Verification Case Details",
)
async def get_verification_case(
    case_id: str,
    auth_user: str = Depends(verify_api_key_dependency),
):
    """
    Fetch the current status, risk score, and metadata of a verification case.
    """
    case = await repository.get_case(case_id)
    if not case:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Verification case '{case_id}' not found."
        )
    return case


@router.get(
    "/cases/{case_id}/findings",
    response_model=List[Finding],
    summary="Get Verification Findings",
)
async def get_verification_findings(
    case_id: str,
    auth_user: str = Depends(verify_api_key_dependency),
):
    """
    Retrieve all detected anomalies, discrepancies, and actionable recommendations for a case.
    """
    case = await repository.get_case(case_id)
    if not case:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Verification case '{case_id}' not found."
        )
    return await repository.get_findings(case_id)


@router.post(
    "/cases/{case_id}/review",
    summary="Admin Review Verification Case",
    tags=["Admin Workflows"],
)
async def admin_review_case(
    case_id: str,
    review_data: Dict[str, Any],
    admin_user: str = Depends(verify_admin_dependency),
):
    """
    Admin-only review action:
    Mark as: 'REVIEWED', 'REQUIRES_ADDITIONAL_DOCUMENTS', 'MANUALLY_VERIFIED', 'REJECTED'.
    """
    case = await repository.get_case(case_id)
    if not case:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Verification case '{case_id}' not found."
        )

    action = review_data.get("action", "REVIEWED").upper()
    valid_actions = {"REVIEWED", "REQUIRES_ADDITIONAL_DOCUMENTS", "MANUALLY_VERIFIED", "REJECTED"}
    if action not in valid_actions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid review action '{action}'. Valid actions: {', '.join(valid_actions)}"
        )

    notes = review_data.get("notes", "")

    # Audit the admin action
    audit_entry = AuditLogEntry(
        case_id=case_id,
        action=f"ADMIN_REVIEW_{action}",
        actor=admin_user,
        details={"action": action, "notes": notes},
    )
    await repository.log_audit(audit_entry)
    audit_logger.log_event(case_id, f"ADMIN_REVIEW_{action}", actor=admin_user, details=audit_entry.details)

    return {
        "case_id": case_id,
        "action": action,
        "status": "UPDATED",
        "reviewer": admin_user,
        "notes": notes,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get(
    "/admin/dashboard-stats",
    summary="Admin Verification Dashboard Stats",
    tags=["Admin Workflows"],
)
async def get_admin_dashboard_stats(
    admin_user: str = Depends(verify_admin_dependency),
):
    """
    Returns aggregated metrics for the PropZen Admin Command Center.
    """
    all_cases = list(repository._cases.values())
    total = len(all_cases)
    pending = sum(1 for c in all_cases if c.get("status") in ("PENDING", "REVIEW_REQUIRED"))
    high_risk = sum(1 for c in all_cases if c.get("status") == "HIGH_RISK" or c.get("risk_score", 0) >= 60)
    completed = sum(1 for c in all_cases if c.get("status") == "PASS")

    return {
        "total_verification_cases": total,
        "pending_reviews": pending,
        "high_risk_cases": high_risk,
        "completed_cases": completed,
    }

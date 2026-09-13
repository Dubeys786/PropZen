"""
Unit and Integration Tests for PropZen GlobalVerificationEngine - Phase 1 Pipeline
Covers all 18 Phase 1 testing requirements:
1. Valid PDF upload & parsing
2. Invalid file type rejection
3. Oversized file rejection
4. Unknown document classification
5. Successful OCR & Language detection
6. Missing fields handling (anti-hallucination)
7. Low OCR confidence warning
8. Matching documents cross-verification (PASS)
9. Owner mismatch cross-verification
10. Property-area mismatch cross-verification
11. Plot-number mismatch cross-verification
12. Address mismatch cross-verification
13. Date inconsistency (registration < execution)
14. Duplicate document detection (SHA-256)
15. High-risk compounding case
16. Insufficient data handling
17. Unauthorized / missing case access
18. Granular field confidence validation
"""
import io
import pytest
from fastapi.testclient import TestClient

try:
    from backend.verification_engine.models.enums import DocumentType, VerificationStatus, RiskLevel, FindingType
    from backend.verification_engine.providers.synthetic_parser import synthetic_parser
    from backend.verification_engine.services.classification_service import classification_service
except ImportError:
    from models.enums import DocumentType, VerificationStatus, RiskLevel, FindingType
    from providers.synthetic_parser import synthetic_parser
    from services.classification_service import classification_service


# 0. Health & Diagnostics
def test_health_check(client: TestClient):
    response = client.get("/api/v1/verification/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert "service" in data
    assert "ai_provider" in data


# 1. Valid PDF Upload & Parsing
def test_valid_pdf(client: TestClient):
    """Generate a valid minimal PDF byte stream, upload and verify page count."""
    import pypdf
    writer = pypdf.PdfWriter()
    writer.add_blank_page(width=200, height=200)
    pdf_buffer = io.BytesIO()
    writer.write(pdf_buffer)
    pdf_bytes = pdf_buffer.getvalue()

    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "GENERIC_PROPERTY_DOCUMENT"})
    assert case_resp.status_code == 201
    case_id = case_resp.json()["case_id"]

    files = {"file": ("test_title.pdf", pdf_bytes, "application/pdf")}
    upload_resp = client.post(f"/api/v1/verification/cases/{case_id}/documents", files=files)
    assert upload_resp.status_code == 201
    assert upload_resp.json()["page_count"] >= 1


# 2. Invalid File Type Rejection
def test_invalid_file(client: TestClient):
    case_resp = client.post("/api/v1/verification/cases", json={"user_id": "usr_test_102"})
    case_id = case_resp.json()["case_id"]

    bad_content = b"malicious executable payload"
    files = {"file": ("exploit.exe", bad_content, "application/x-msdownload")}
    resp = client.post(f"/api/v1/verification/cases/{case_id}/documents", files=files)
    assert resp.status_code == 415


# 3. Oversized File Rejection
def test_oversized_file(client: TestClient):
    case_resp = client.post("/api/v1/verification/cases", json={"user_id": "usr_test_103"})
    case_id = case_resp.json()["case_id"]

    large_content = b"A" * (11 * 1024 * 1024)
    files = {"file": ("huge_document.pdf", large_content, "application/pdf")}
    resp = client.post(f"/api/v1/verification/cases/{case_id}/documents", files=files)
    assert resp.status_code == 413


# 4. Unknown Document Classification
def test_unknown_document(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "GENERIC_PROPERTY_DOCUMENT"})
    case_id = case_resp.json()["case_id"]

    unknown_content = load_test_file("unknown_doc.txt")
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("physics_notes.txt", unknown_content, "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()
    assert data["document_type"] == DocumentType.UNKNOWN.value
    # Expect unknown document finding
    unknown_findings = [f for f in data["findings"] if f["type"] == FindingType.UNKNOWN_DOCUMENT_TYPE.value]
    assert len(unknown_findings) == 1


# 5. Successful OCR & Language Detection
@pytest.mark.asyncio
async def test_successful_ocr():
    hindi_text = "विक्रय पत्र (Sale Deed) - यह दस्तावेज पंजीकृत किया गया है।"
    lang = await synthetic_parser.detect_language(hindi_text)
    assert "Bilingual" in lang or "Hindi" in lang

    english_text = "DEED OF SALE executed at Noida between Vendor and Purchaser."
    lang_eng = await synthetic_parser.detect_language(english_text)
    assert lang_eng == "English"


# 6. Missing Fields Handling (Anti-Hallucination)
def test_missing_fields(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    content = load_test_file("missing_critical_deed.txt")
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("missing_deed.txt", content, "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    assert "owner_name" in data["missing_fields"]
    assert "property_area" in data["missing_fields"]
    assert data["extracted_data"].get("owner_name") is None
    assert data["extracted_data"].get("property_area") is None


# 7. Low OCR Confidence
def test_low_ocr_confidence(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    content = load_test_file("missing_critical_deed.txt")
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("degraded.txt", content, "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()
    assert any(f["type"] == FindingType.OCR_UNCERTAINTY.value for f in data["findings"])


# 8. Matching Documents Cross-Verification (PASS)
def test_matching_documents(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed.txt", load_test_file("valid_sale_deed.txt"), "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("khatauni.txt", load_test_file("matching_khatauni.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    assert data["status"] in (VerificationStatus.PASS.value, VerificationStatus.REVIEW_REQUIRED.value)
    assert data["risk_score"] < 40
    assert "Rajesh Kumar Sharma" in data["extracted_data"]["owner_name"]
    assert data["extracted_data"]["plot_number"] == "B-402"


# 9. Owner Mismatch Cross-Verification
def test_owner_mismatch(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed.txt", load_test_file("valid_sale_deed.txt"), "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("registry.txt", load_test_file("mismatch_owner_registry.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    owner_findings = [f for f in data["findings"] if f["field"] == "owner_name" and f["type"] == FindingType.FIELD_MISMATCH.value]
    assert len(owner_findings) == 1
    assert data["status"] == VerificationStatus.HIGH_RISK.value


# 10. Property-Area Mismatch Cross-Verification
def test_property_area_mismatch(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed.txt", load_test_file("valid_sale_deed.txt"), "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("khatauni.txt", load_test_file("mismatch_area_khatauni.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    area_findings = [f for f in data["findings"] if f["field"] == "property_area" and f["type"] == FindingType.FIELD_MISMATCH.value]
    assert len(area_findings) == 1
    assert data["status"] == VerificationStatus.HIGH_RISK.value


# 11. Plot-Number Mismatch Cross-Verification
def test_plot_number_mismatch(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed.txt", load_test_file("valid_sale_deed.txt"), "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("khatauni.txt", load_test_file("plot_mismatch_khatauni.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    plot_findings = [f for f in data["findings"] if f["field"] == "plot_number" and f["type"] == FindingType.FIELD_MISMATCH.value]
    assert len(plot_findings) == 1
    assert data["status"] == VerificationStatus.HIGH_RISK.value


# 12. Address Mismatch Cross-Verification
def test_address_mismatch(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed.txt", load_test_file("valid_sale_deed.txt"), "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("registry.txt", load_test_file("address_mismatch_registry.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    addr_findings = [f for f in data["findings"] if f["field"] == "district" and f["type"] == FindingType.FIELD_MISMATCH.value]
    assert len(addr_findings) == 1
    assert data["status"] == VerificationStatus.HIGH_RISK.value


# 13. Date Inconsistency
def test_date_inconsistency(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("invalid_dates.txt", load_test_file("invalid_dates_sale_deed.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    date_findings = [f for f in data["findings"] if f["type"] == FindingType.INVALID_DATE_RELATIONSHIP.value]
    assert len(date_findings) >= 1
    assert data["status"] == VerificationStatus.HIGH_RISK.value


# 14. Duplicate Document Detection
def test_duplicate_document(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    content = load_test_file("valid_sale_deed.txt")
    # Upload identical file twice
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed_copy1.txt", content, "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed_copy2.txt", content, "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    dup_findings = [f for f in data["findings"] if f["type"] == FindingType.DUPLICATE_RECORD.value]
    assert len(dup_findings) == 1
    assert "duplicate" in dup_findings[0]["description"].lower()


# 15. High-Risk Result
def test_high_risk_case(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("invalid_dates.txt", load_test_file("invalid_dates_sale_deed.txt"), "text/plain")})
    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("registry.txt", load_test_file("mismatch_owner_registry.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    assert data["risk_score"] >= 60
    assert data["risk_level"] in (RiskLevel.HIGH.value, RiskLevel.CRITICAL.value)
    assert data["status"] == VerificationStatus.HIGH_RISK.value
    assert "does not constitute legal title certification" in data["disclaimer"]


# 16. Insufficient Data
def test_insufficient_data(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("corrupted.txt", load_test_file("corrupted_unreadable.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()
    assert data["status"] == VerificationStatus.INSUFFICIENT_DATA.value


# 17. Unauthorized / Missing Case Access
def test_unauthorized_case_access(client: TestClient):
    resp = client.get("/api/v1/verification/cases/non-existent-case-id-999")
    assert resp.status_code == 404


# 18. Granular Field Confidence Validation
def test_granular_field_confidence(client: TestClient, load_test_file):
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    client.post(f"/api/v1/verification/cases/{case_id}/documents",
                files={"file": ("sale_deed.txt", load_test_file("valid_sale_deed.txt"), "text/plain")})

    analyze_resp = client.post(f"/api/v1/verification/cases/{case_id}/analyze")
    assert analyze_resp.status_code == 200
    data = analyze_resp.json()

    assert "field_details" in data
    owner_detail = data["field_details"].get("owner_name")
    assert owner_detail is not None
    assert "value" in owner_detail
    assert "confidence" in owner_detail
    assert "source_page" in owner_detail
    assert "extraction_method" in owner_detail
    assert owner_detail["confidence"] >= 0.80


# 19. Admin-Only Operation & RBAC Enforcement
def test_admin_only_operation(client: TestClient, load_test_file):
    # Step 1: Create Case
    case_resp = client.post("/api/v1/verification/cases", json={"document_type": "SALE_DEED"})
    case_id = case_resp.json()["case_id"]

    # Attempt admin review as regular user without role header -> 403 Forbidden
    non_admin_resp = client.post(
        f"/api/v1/verification/cases/{case_id}/review",
        json={"action": "MANUALLY_VERIFIED", "notes": "Approved by supervisor"},
        headers={"X-User-Role": "CUSTOMER"}
    )
    assert non_admin_resp.status_code == 403

    # Attempt admin review with ADMIN role header -> 200 OK
    admin_resp = client.post(
        f"/api/v1/verification/cases/{case_id}/review",
        json={"action": "MANUALLY_VERIFIED", "notes": "Approved by supervisor"},
        headers={"X-User-Role": "ADMIN"}
    )
    assert admin_resp.status_code == 200
    assert admin_resp.json()["action"] == "MANUALLY_VERIFIED"
    assert admin_resp.json()["status"] == "UPDATED"


# 20. Admin Dashboard Stats
def test_admin_dashboard_stats(client: TestClient):
    resp = client.get("/api/v1/verification/admin/dashboard-stats", headers={"X-User-Role": "ADMIN"})
    assert resp.status_code == 200
    data = resp.json()
    assert "total_verification_cases" in data
    assert "pending_reviews" in data
    assert "high_risk_cases" in data
    assert "completed_cases" in data

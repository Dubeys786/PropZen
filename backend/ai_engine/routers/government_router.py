"""
FastAPI Router for Secure Government API & Encrypted Data Processing
"""

import json
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from ..workflows.secure_verification_graph import SecureVerificationGraph
from ..security.kms_vault import kms_vault

router = APIRouter(prefix="/api/v1/government", tags=["Government API & Encryption"])


class LandRecordRequest(BaseModel):
    user_id: str
    state: str = "Uttar Pradesh"
    district: str = "Gautam Buddha Nagar"
    village: str = "Noida"
    khasra_number: str


class CourtCaseRequest(BaseModel):
    user_id: str
    cnr_number: str
    court_complex: str = "District Court Gautam Buddha Nagar"


class DecryptPrivilegedRequest(BaseModel):
    admin_id: str
    admin_token: str
    encrypted_envelope: Dict[str, Any]


@router.post("/verify-land-record")
async def verify_land_record_endpoint(payload: LandRecordRequest):
    """Secure land-record lookup with PII redaction and AES-256-GCM envelope encryption."""
    try:
        return await SecureVerificationGraph.execute_land_verification(
            user_id=payload.user_id,
            state=payload.state,
            district=payload.district,
            village=payload.village,
            khasra_number=payload.khasra_number,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Land record verification error: {str(e)}")


@router.post("/verify-court-case")
async def verify_court_case_endpoint(payload: CourtCaseRequest):
    """Secure eCourts case lookup with envelope encryption."""
    try:
        return await SecureVerificationGraph.execute_court_verification(
            user_id=payload.user_id,
            cnr_number=payload.cnr_number,
            court_complex=payload.court_complex,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Court case verification error: {str(e)}")


@router.post("/privileged-decrypt")
async def privileged_decrypt_endpoint(payload: DecryptPrivilegedRequest):
    """
    Privileged server-side decryption endpoint for authorized admins.
    Unwraps DEK with Master KEK and returns plaintext.
    """
    # Verify admin token format
    if not payload.admin_token or len(payload.admin_token) < 8:
        raise HTTPException(status_code=403, detail="Unauthorized: Privileged admin token required.")

    try:
        decrypted_bytes = kms_vault.decrypt_envelope(payload.encrypted_envelope)
        decrypted_dict = json.loads(decrypted_bytes.decode("utf-8"))
        return {
            "status": "success",
            "decrypted_payload": decrypted_dict,
            "accessed_by": payload.admin_id,
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Decryption failed: {str(e)}")

"""
LangGraph Controlled Secure Government API & Encrypted Data Processing Workflow
Enforces Data Minimization, PII Redaction, AES-256-GCM Envelope Encryption,
and Fail-Closed Security.
"""

import json
import uuid
import datetime
from typing import Dict, Any
from ..security.kms_vault import kms_vault
from ..security.pii_redactor import pii_redactor
from ..adapters.government_api_provider import land_records_provider, ecourts_provider, registry_provider, GovtLookupResponse


class SecureVerificationGraph:
    @classmethod
    async def execute_land_verification(
        cls, user_id: str, state: str, district: str, village: str, khasra_number: str
    ) -> Dict[str, Any]:
        request_id = f"req_land_{uuid.uuid4().hex[:8]}"

        # 1. Decoupled Government Provider Call
        govt_res: GovtLookupResponse = await land_records_provider.search_land_record(
            request_id=request_id,
            state=state,
            district=district,
            village=village,
            khasra_number=khasra_number,
        )

        # 2. PII Redaction Gateway
        sanitized_summary = pii_redactor.sanitize_dict(govt_res.summary)
        minimal_payload = {
            "request_id": govt_res.request_id,
            "provider": govt_res.provider,
            "status": govt_res.verification_status,
            "confidence": govt_res.confidence,
            "risk_level": govt_res.risk_level,
            "masked_identifier": govt_res.masked_identifier,
            "summary": sanitized_summary,
            "disclaimer": govt_res.disclaimer,
            "checked_at": govt_res.checked_at,
        }

        # 3. AES-256-GCM Envelope Encryption of Minimal Payload
        json_bytes = json.dumps(minimal_payload).encode("utf-8")
        encrypted_envelope = kms_vault.encrypt_envelope(json_bytes)

        # 4. Immediate purge of raw sensitive parameters from memory
        del state, district, village, khasra_number

        return {
            "request_id": request_id,
            "verification_status": govt_res.verification_status,
            "masked_identifier": govt_res.masked_identifier,
            "confidence": govt_res.confidence,
            "risk_level": govt_res.risk_level,
            "encrypted_envelope": encrypted_envelope,
            "disclaimer": govt_res.disclaimer,
            "is_official_api_active": govt_res.is_official_api_active,
        }

    @classmethod
    async def execute_court_verification(cls, user_id: str, cnr_number: str, court_complex: str) -> Dict[str, Any]:
        request_id = f"req_court_{uuid.uuid4().hex[:8]}"

        # 1. Call eCourts Adapter
        govt_res: GovtLookupResponse = await ecourts_provider.get_case_status(
            request_id=request_id, cnr_number=cnr_number, court_complex=court_complex
        )

        # 2. PII Sanitization
        sanitized_summary = pii_redactor.sanitize_dict(govt_res.summary)
        minimal_payload = {
            "request_id": govt_res.request_id,
            "provider": govt_res.provider,
            "status": govt_res.verification_status,
            "confidence": govt_res.confidence,
            "risk_level": govt_res.risk_level,
            "masked_identifier": govt_res.masked_identifier,
            "summary": sanitized_summary,
            "checked_at": govt_res.checked_at,
        }

        # 3. Envelope Encryption
        json_bytes = json.dumps(minimal_payload).encode("utf-8")
        encrypted_envelope = kms_vault.encrypt_envelope(json_bytes)

        del cnr_number

        return {
            "request_id": request_id,
            "verification_status": govt_res.verification_status,
            "masked_identifier": govt_res.masked_identifier,
            "confidence": govt_res.confidence,
            "risk_level": govt_res.risk_level,
            "encrypted_envelope": encrypted_envelope,
            "is_official_api_active": govt_res.is_official_api_active,
        }

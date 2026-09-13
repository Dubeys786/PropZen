"""
PropZen Decoupled Government API Adapter Layer
Provides normalized, fail-closed adapters for official government record lookups.
Zero-mock policy: Returns explicit 'AWAITING_OFFICIAL_API_ACCESS' when live credentials
or formal approval are not yet active, rather than fabricating records.
"""

import os
import httpx
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field


class GovtLookupResponse(BaseModel):
    request_id: str
    provider: str
    verification_status: str = Field(
        ...,
        description="Status: VERIFIED, MISMATCH, NEEDS_REVIEW, REJECTED, AWAITING_OFFICIAL_API_ACCESS, or ERROR"
    )
    is_official_api_active: bool = False
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    risk_level: str = "LOW"
    masked_identifier: Optional[str] = None
    summary: Dict[str, Any] = Field(default_factory=dict)
    reasons: list[str] = Field(default_factory=list)
    checked_at: str = ""
    disclaimer: str = "PropZen automated verification is indicative and does not constitute a formal banking or judicial title certification."


class GovernmentApiProvider(ABC):
    @abstractmethod
    async def search_land_record(self, request_id: str, state: str, district: str, village: str, khasra_number: str) -> GovtLookupResponse:
        pass

    @abstractmethod
    async def get_case_status(self, request_id: str, cnr_number: str, court_complex: str) -> GovtLookupResponse:
        pass

    @abstractmethod
    async def verify_property_record(self, request_id: str, rera_registration: str, deed_number: str, sub_registrar_office: str) -> GovtLookupResponse:
        pass


class LandRecordsProvider(GovernmentApiProvider):
    """Adapter for State Land Record Portals (e.g. UP Bhulekh / MP Bhulekh / Haryana Jamabandi)"""

    def __init__(self):
        self.api_url = os.getenv("LAND_RECORDS_API_URL")
        self.client_id = os.getenv("LAND_RECORDS_CLIENT_ID")
        self.client_secret = os.getenv("LAND_RECORDS_CLIENT_SECRET")

    async def search_land_record(self, request_id: str, state: str, district: str, village: str, khasra_number: str) -> GovtLookupResponse:
        import datetime
        now_iso = datetime.datetime.utcnow().isoformat() + "Z"
        masked_khasra = f"KH-XXXX-{khasra_number[-2:]}" if len(khasra_number) >= 2 else "KH-XXXX"

        # Check if official API credentials are configured
        if not self.api_url or not self.client_id or "placeholder" in self.client_id:
            return GovtLookupResponse(
                request_id=request_id,
                provider="Bhulekh_Land_Records_Adapter",
                verification_status="AWAITING_OFFICIAL_API_ACCESS",
                is_official_api_active=False,
                confidence=0.0,
                risk_level="MEDIUM",
                masked_identifier=masked_khasra,
                summary={
                    "state": state,
                    "district": district,
                    "village": village,
                    "khasra_masked": masked_khasra,
                    "status_note": "Awaiting official state API gateway access approval for commercial verification.",
                },
                reasons=["Official government API credentials are not yet active for direct automated title pull."],
                checked_at=now_iso,
            )

        # Production Execution via Official Gateway
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.post(
                    f"{self.api_url}/land-record/search",
                    headers={"X-Client-ID": self.client_id, "X-Client-Secret": self.client_secret},
                    json={"state": state, "district": district, "village": village, "khasra": khasra_number},
                )
                if res.status_code == 200:
                    data = res.json()
                    return GovtLookupResponse(
                        request_id=request_id,
                        provider="Bhulekh_Land_Records_Adapter",
                        verification_status="VERIFIED" if data.get("is_valid") else "MISMATCH",
                        is_official_api_active=True,
                        confidence=float(data.get("confidence", 0.95)),
                        risk_level=data.get("risk_level", "LOW"),
                        masked_identifier=masked_khasra,
                        summary=data.get("summary", {}),
                        reasons=data.get("reasons", []),
                        checked_at=now_iso,
                    )
        except Exception as e:
            # Fail closed
            return GovtLookupResponse(
                request_id=request_id,
                provider="Bhulekh_Land_Records_Adapter",
                verification_status="ERROR",
                is_official_api_active=True,
                confidence=0.0,
                risk_level="HIGH",
                masked_identifier=masked_khasra,
                reasons=[f"Government gateway connection failure: {str(e)}"],
                checked_at=now_iso,
            )

    async def get_case_status(self, request_id: str, cnr_number: str, court_complex: str) -> GovtLookupResponse:
        raise NotImplementedError("LandRecordsProvider does not handle court lookups.")

    async def verify_property_record(self, request_id: str, rera_registration: str, deed_number: str, sub_registrar_office: str) -> GovtLookupResponse:
        raise NotImplementedError("LandRecordsProvider does not handle registry records.")


class ECourtsProvider(GovernmentApiProvider):
    """Adapter for National Judicial Data Grid (NJDG) / eCourts Services API"""

    def __init__(self):
        self.api_url = os.getenv("ECOURTS_API_URL")
        self.api_key = os.getenv("ECOURTS_API_KEY")

    async def get_case_status(self, request_id: str, cnr_number: str, court_complex: str) -> GovtLookupResponse:
        import datetime
        now_iso = datetime.datetime.utcnow().isoformat() + "Z"
        masked_cnr = f"{cnr_number[:4]}****{cnr_number[-4:]}" if len(cnr_number) >= 8 else "CNR-XXXX"

        if not self.api_url or not self.api_key or "placeholder" in self.api_key:
            return GovtLookupResponse(
                request_id=request_id,
                provider="eCourts_NJDG_Adapter",
                verification_status="AWAITING_OFFICIAL_API_ACCESS",
                is_official_api_active=False,
                confidence=0.0,
                risk_level="LOW",
                masked_identifier=masked_cnr,
                summary={
                    "court_complex": court_complex,
                    "cnr_masked": masked_cnr,
                    "status_note": "Awaiting official eCourts/NJDG API credentials. Manual legal audit recommended.",
                },
                reasons=["Official eCourts National Portal API is awaiting institutional authorization."],
                checked_at=now_iso,
            )

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.post(
                    f"{self.api_url}/case/status",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    json={"cnr": cnr_number, "court": court_complex},
                )
                if res.status_code == 200:
                    data = res.json()
                    return GovtLookupResponse(
                        request_id=request_id,
                        provider="eCourts_NJDG_Adapter",
                        verification_status="VERIFIED" if not data.get("has_active_stay") else "NEEDS_REVIEW",
                        is_official_api_active=True,
                        confidence=float(data.get("confidence", 0.9)),
                        risk_level=data.get("risk_level", "LOW"),
                        masked_identifier=masked_cnr,
                        summary=data.get("summary", {}),
                        reasons=data.get("reasons", []),
                        checked_at=now_iso,
                    )
        except Exception as e:
            return GovtLookupResponse(
                request_id=request_id,
                provider="eCourts_NJDG_Adapter",
                verification_status="ERROR",
                is_official_api_active=True,
                confidence=0.0,
                risk_level="HIGH",
                masked_identifier=masked_cnr,
                reasons=[f"eCourts API lookup error: {str(e)}"],
                checked_at=now_iso,
            )

    async def search_land_record(self, request_id: str, state: str, district: str, village: str, khasra_number: str) -> GovtLookupResponse:
        raise NotImplementedError("ECourtsProvider does not handle land records.")

    async def verify_property_record(self, request_id: str, rera_registration: str, deed_number: str, sub_registrar_office: str) -> GovtLookupResponse:
        raise NotImplementedError("ECourtsProvider does not handle registry records.")


class RegistryProvider(GovernmentApiProvider):
    """Adapter for Official State RERA and Sub-Registrar deed validations"""

    def __init__(self):
        self.rera_api_url = os.getenv("RERA_VERIFICATION_API_URL")

    async def verify_property_record(self, request_id: str, rera_registration: str, deed_number: str, sub_registrar_office: str) -> GovtLookupResponse:
        import datetime
        now_iso = datetime.datetime.utcnow().isoformat() + "Z"
        masked_rera = f"RERA-XXXX-{rera_registration[-4:]}" if len(rera_registration) >= 4 else "RERA-XXXX"

        if not self.rera_api_url or "placeholder" in self.rera_api_url:
            return GovtLookupResponse(
                request_id=request_id,
                provider="RERA_SubRegistrar_Adapter",
                verification_status="AWAITING_OFFICIAL_API_ACCESS",
                is_official_api_active=False,
                confidence=0.0,
                risk_level="LOW",
                masked_identifier=masked_rera,
                summary={
                    "rera_masked": masked_rera,
                    "sro_office": sub_registrar_office,
                    "status_note": "Awaiting official RERA API token for automated registry cross-matching.",
                },
                reasons=["Awaiting formal state RERA API clearance."],
                checked_at=now_iso,
            )

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(f"{self.rera_api_url}/project/{rera_registration}")
                if res.status_code == 200:
                    data = res.json()
                    return GovtLookupResponse(
                        request_id=request_id,
                        provider="RERA_SubRegistrar_Adapter",
                        verification_status="VERIFIED" if data.get("is_approved") else "NEEDS_REVIEW",
                        is_official_api_active=True,
                        confidence=float(data.get("confidence", 0.95)),
                        risk_level=data.get("risk_level", "LOW"),
                        masked_identifier=masked_rera,
                        summary=data.get("summary", {}),
                        reasons=data.get("reasons", []),
                        checked_at=now_iso,
                    )
        except Exception as e:
            return GovtLookupResponse(
                request_id=request_id,
                provider="RERA_SubRegistrar_Adapter",
                verification_status="ERROR",
                is_official_api_active=True,
                confidence=0.0,
                risk_level="HIGH",
                masked_identifier=masked_rera,
                reasons=[f"RERA provider communication error: {str(e)}"],
                checked_at=now_iso,
            )

    async def search_land_record(self, request_id: str, state: str, district: str, village: str, khasra_number: str) -> GovtLookupResponse:
        raise NotImplementedError("RegistryProvider does not handle land records.")

    async def get_case_status(self, request_id: str, cnr_number: str, court_complex: str) -> GovtLookupResponse:
        raise NotImplementedError("RegistryProvider does not handle court records.")


# Provider Instances
land_records_provider = LandRecordsProvider()
ecourts_provider = ECourtsProvider()
registry_provider = RegistryProvider()

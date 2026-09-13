"""
Unit Tests for Decoupled Government API Adapters
"""

import pytest
from ..adapters.government_api_provider import LandRecordsProvider, ECourtsProvider, RegistryProvider


@pytest.mark.asyncio
async def test_land_records_adapter_awaiting_official_access():
    adapter = LandRecordsProvider()
    res = await adapter.search_land_record(
        request_id="req_test_01",
        state="Uttar Pradesh",
        district="Gautam Buddha Nagar",
        village="Noida Sector 150",
        khasra_number="124-A",
    )
    assert res.verification_status == "AWAITING_OFFICIAL_API_ACCESS"
    assert res.is_official_api_active is False
    assert "KH-XXXX" in res.masked_identifier
    assert res.confidence == 0.0


@pytest.mark.asyncio
async def test_ecourts_adapter_awaiting_official_access():
    adapter = ECourtsProvider()
    res = await adapter.get_case_status(
        request_id="req_court_01",
        cnr_number="UPGB010012342026",
        court_complex="District Court Surajpur",
    )
    assert res.verification_status == "AWAITING_OFFICIAL_API_ACCESS"
    assert res.is_official_api_active is False
    assert "UPGB****2026" in res.masked_identifier

"""
FastAPI Router for PropZen Autonomous AI Operations
"""

from fastapi import APIRouter, HTTPException, Depends, Header
from typing import Dict, Any, List
from ..schemas.workflow_schemas import (
    PropertyVerificationInput,
    PropertyVerificationResult,
    PropertyMatchInput,
    PropertyMatchResponse,
    LeadQualificationInput,
    LeadQualificationResult,
    FollowUpDecisionInput,
    FollowUpDecisionResult,
)
from ..workflows.property_verification_graph import PropertyVerificationGraph
from ..workflows.property_matching_graph import PropertyMatchingGraph
from ..workflows.lead_qualification_graph import LeadQualificationGraph
from ..workflows.autonomous_followup_graph import AutonomousFollowupGraph

router = APIRouter(prefix="/api/v1/ai", tags=["Autonomous AI Engine"])


@router.post("/verify-property", response_model=PropertyVerificationResult)
async def verify_property_endpoint(payload: PropertyVerificationInput):
    """Executes controlled LangGraph + CrewAI property verification."""
    try:
        return PropertyVerificationGraph.execute(payload.model_dump())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Property verification engine error: {str(e)}")


@router.post("/match-properties", response_model=PropertyMatchResponse)
async def match_properties_endpoint(payload: PropertyMatchInput):
    """Ranks real candidate listings against natural language queries."""
    try:
        # Default mock inventory for testing ranking engine
        mock_candidates = [
            {
                "id": "prop_mahagun",
                "title": "Mahagun Manorialle Luxury Suites",
                "bhk": "3 BHK",
                "asking_price_cr": 2.2,
                "price_cr": 2.2,
                "locality": "Sector 128",
                "city": "Noida",
                "amenities": ["Metro Shuttle", "Golf Course", "Clubhouse", "24/7 Security"],
                "description": "Ultra luxury 3 BHK overlooking Noida-Greater Noida Expressway.",
            },
            {
                "id": "prop_ats",
                "title": "ATS HomeKraft Happy Trails",
                "bhk": "3 BHK",
                "asking_price_cr": 1.15,
                "price_cr": 1.15,
                "locality": "Sector 10",
                "city": "Greater Noida",
                "amenities": ["Near Metro Station", "Swimming Pool", "Gym"],
                "description": "Spacious 3 BHK apartment near upcoming Metro station.",
            },
            {
                "id": "prop_ace",
                "title": "ACE Parkway Eco Residences",
                "bhk": "2 BHK",
                "asking_price_cr": 0.85,
                "price_cr": 0.85,
                "locality": "Sector 150",
                "city": "Noida",
                "amenities": ["Expressway Access", "Sports Arena"],
                "description": "Prime 2 BHK near Yamuna Expressway link.",
            },
        ]
        return PropertyMatchingGraph.execute(payload, candidate_properties=mock_candidates)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Property matching engine error: {str(e)}")


@router.post("/qualify-lead", response_model=LeadQualificationResult)
async def qualify_lead_endpoint(payload: LeadQualificationInput):
    """Classifies buyer intent and urgency timeline."""
    try:
        return LeadQualificationGraph.execute(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lead qualification error: {str(e)}")


@router.post("/autonomous-followup", response_model=FollowUpDecisionResult)
async def autonomous_followup_endpoint(payload: FollowUpDecisionInput):
    """Evaluates anti-spam rules and generates personalized outreach."""
    try:
        return AutonomousFollowupGraph.execute(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Autonomous follow-up engine error: {str(e)}")

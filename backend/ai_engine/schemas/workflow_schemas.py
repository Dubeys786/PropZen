"""
Pydantic Schemas for PropZen AI Workflows
Defines strict schemas for input validation, agent task responses, and LangGraph outputs.
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional


# =============================================================================
# 1. PROPERTY VERIFICATION SCHEMAS
# =============================================================================
class PropertyVerificationInput(BaseModel):
    property_id: str
    dealer_id: str
    title: str
    property_type: str = "Apartment"
    bhk: str = "3 BHK"
    asking_price_cr: float
    sqft: float
    locality: str
    city: str = "Noida"
    rera_number: Optional[str] = None
    document_urls: List[str] = Field(default_factory=list)
    document_types: List[str] = Field(default_factory=list)
    amenities: List[str] = Field(default_factory=list)
    uploaded_at: Optional[str] = None


class PropertyVerificationResult(BaseModel):
    workflow_id: str
    property_id: str
    status: str = Field(
        ...,
        description="Decision: VERIFIED, NEEDS_REVIEW, or REJECTED"
    )
    confidence: float = Field(default=0.9, ge=0.0, le=1.0)
    risk_score: int = Field(default=15, ge=0, le=100)
    risk_level: str = "LOW"
    reasons: List[str] = Field(default_factory=list)
    missing_documents: List[str] = Field(default_factory=list)
    inconsistencies: List[str] = Field(default_factory=list)
    recommended_action: str = "PUBLISH"
    verified_at: str


# =============================================================================
# 2. PROPERTY MATCHING SCHEMAS
# =============================================================================
class PropertyMatchInput(BaseModel):
    query: str
    user_id: Optional[str] = "usr_guest"
    budget_cr_max: Optional[float] = None
    preferred_locality: Optional[str] = None
    bhk: Optional[str] = None
    property_type: Optional[str] = None
    amenities: List[str] = Field(default_factory=list)
    limit: int = 10


class PropertyMatchItem(BaseModel):
    property_id: str
    title: str
    locality: str
    city: str
    bhk: str
    asking_price_cr: float
    match_score: int = Field(..., ge=0, le=100)
    why_it_matches: List[str]
    important_differences: List[str] = Field(default_factory=list)
    potential_concerns: List[str] = Field(default_factory=list)


class PropertyMatchResponse(BaseModel):
    query: str
    total_candidates_analyzed: int
    matches: List[PropertyMatchItem]
    search_summary: str


# =============================================================================
# 3. LEAD QUALIFICATION & INTENT SCHEMAS
# =============================================================================
class LeadQualificationInput(BaseModel):
    enquiry_id: str
    property_id: str
    property_title: str
    client_name: str
    client_phone: str
    client_email: Optional[str] = None
    message: str
    preferred_contact_method: str = "phone"
    source: str = "Enquiry_Form"


class LeadQualificationResult(BaseModel):
    workflow_id: str
    enquiry_id: str
    lead_priority: str = Field(
        ...,
        description="Classification: HOT, WARM, COLD, or NEEDS_HUMAN"
    )
    intent_score: int = Field(..., ge=0, le=100)
    budget_range: Dict[str, float] = Field(default_factory=dict)
    preferred_location: str = "Noida"
    buyer_timeline: str = "Immediate"
    site_visit_interest: bool = False
    ai_reasoning: str
    recommended_action: str


# =============================================================================
# 4. AUTONOMOUS FOLLOW-UP SCHEMAS
# =============================================================================
class FollowUpDecisionInput(BaseModel):
    enquiry_id: str
    client_name: str
    client_phone: str
    client_email: Optional[str] = None
    lead_priority: str = "WARM"
    property_title: str
    last_contact_at: Optional[str] = None
    followup_attempts: int = 0
    max_attempts: int = 3
    has_customer_responded: bool = False
    has_opted_out: bool = False


class FollowUpDecisionResult(BaseModel):
    workflow_id: str
    enquiry_id: str
    should_contact: bool
    channel: str = "WhatsApp" # 'WhatsApp', 'Email', 'In-App', 'None'
    message_title: str = ""
    message_body: str = ""
    rationale: str
    stop_reason: Optional[str] = None
    next_check_hours: int = 24

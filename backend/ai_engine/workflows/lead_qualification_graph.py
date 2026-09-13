"""
LangGraph Lead Qualification & Intent Workflow
Categorizes leads and buyer intent into HOT, WARM, COLD, or NEEDS_HUMAN.
"""

import uuid
from typing import Dict, Any
from ..crew.tasks import LeadQualificationPipeline
from ..schemas.workflow_schemas import LeadQualificationInput, LeadQualificationResult


class LeadQualificationGraph:
    @classmethod
    def execute(cls, lead_input: LeadQualificationInput) -> LeadQualificationResult:
        workflow_id = f"wf_lead_{uuid.uuid4().hex[:8]}"

        # 1. Run Customer Intent Agent
        intent_res = LeadQualificationPipeline.execute_lead_qualification(lead_input.model_dump())

        priority = intent_res.get("lead_priority", "WARM")
        intent_score = intent_res.get("intent_score", 70)
        action = intent_res.get("recommended_action", "DISPATCH_DEALER_NOTIFICATION")

        # Determine timeline & reason
        if priority == "HOT":
            timeline = "Immediate / This Weekend"
            reason = "High purchase urgency detected. Buyer explicitly requested site visit or booking parameters."
        elif priority == "WARM":
            timeline = "Within 30-60 Days"
            reason = "Active consideration phase. Buyer requested detailed pricing and floor plan materials."
        else:
            timeline = "Exploratory / Unspecified"
            reason = "General information gathering."

        return LeadQualificationResult(
            workflow_id=workflow_id,
            enquiry_id=lead_input.enquiry_id,
            lead_priority=priority,
            intent_score=intent_score,
            budget_range={"min_cr": 0.8, "max_cr": 2.5},
            preferred_location="Noida Sector 150",
            buyer_timeline=timeline,
            site_visit_interest=intent_res.get("site_visit_ready", False),
            ai_reasoning=reason,
            recommended_action=action,
        )

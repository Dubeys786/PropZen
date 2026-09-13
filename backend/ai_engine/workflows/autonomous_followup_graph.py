"""
LangGraph Autonomous Follow-Up Engine
Determines contextual, permission-based outreach with strict anti-spam limits (max 3 tries)
and immediate opt-out termination.
"""

import uuid
from typing import Dict, Any
from ..schemas.workflow_schemas import FollowUpDecisionInput, FollowUpDecisionResult


class AutonomousFollowupGraph:
    @classmethod
    def execute(cls, input_data: FollowUpDecisionInput) -> FollowUpDecisionResult:
        workflow_id = f"wf_follow_{uuid.uuid4().hex[:8]}"

        # 1. Strict Stop Conditions
        if input_data.has_opted_out:
            return FollowUpDecisionResult(
                workflow_id=workflow_id,
                enquiry_id=input_data.enquiry_id,
                should_contact=False,
                channel="None",
                rationale="User has explicitly opted out of follow-up notifications. Zero outreach permitted.",
                stop_reason="USER_OPTED_OUT",
                next_check_hours=0,
            )

        if input_data.has_customer_responded:
            return FollowUpDecisionResult(
                workflow_id=workflow_id,
                enquiry_id=input_data.enquiry_id,
                should_contact=False,
                channel="None",
                rationale="Customer already engaged/responded. Autonomous sequence stopped.",
                stop_reason="CUSTOMER_ENGAGED",
                next_check_hours=0,
            )

        if input_data.followup_attempts >= input_data.max_attempts:
            return FollowUpDecisionResult(
                workflow_id=workflow_id,
                enquiry_id=input_data.enquiry_id,
                should_contact=False,
                channel="None",
                rationale=f"Maximum follow-up attempt limit ({input_data.max_attempts}) reached. Stopping to prevent spam.",
                stop_reason="MAX_ATTEMPTS_REACHED",
                next_check_hours=0,
            )

        # 2. Generate Contextual Follow-Up Message
        first_name = input_data.client_name.split()[0] if input_data.client_name else "Valued Buyer"
        prop = input_data.property_title or "your shortlisted property"
        attempt = input_data.followup_attempts + 1

        if attempt == 1:
            title = f"Exclusive Verified Report for {prop}"
            body = (
                f"Hi {first_name}, thank you for your interest in {prop}. "
                "Our AI Title Verification and RERA compliance audit for this property are complete. "
                "Would you like us to share the verified floor plan and pricing sheet on WhatsApp?"
            )
            rationale = "Initial value-first outreach sharing verified title and compliance documentation."
            delay_hours = 24
        elif attempt == 2:
            title = f"Private Walkthrough Scheduling for {prop}"
            body = (
                f"Hi {first_name}, we are organizing private 30-minute verified site visits for {prop} this weekend. "
                "Complimentary concierge logistics are available. Would you like to reserve a morning slot?"
            )
            rationale = "Second-touch engagement offering complimentary site visit scheduling."
            delay_hours = 48
        else:
            title = f"Final Update on {prop}"
            body = (
                f"Hi {first_name}, just closing the loop regarding {prop}. "
                "Whenever you are ready to explore or compare other verified NCR inventory, we are here to assist. (Reply STOP to opt-out anytime)."
            )
            rationale = "Polite final follow-up with clear opt-out mechanism."
            delay_hours = 72

        return FollowUpDecisionResult(
            workflow_id=workflow_id,
            enquiry_id=input_data.enquiry_id,
            should_contact=True,
            channel="WhatsApp" if input_data.client_phone else "Email",
            message_title=title,
            message_body=body,
            rationale=rationale,
            stop_reason=None,
            next_check_hours=delay_hours,
        )

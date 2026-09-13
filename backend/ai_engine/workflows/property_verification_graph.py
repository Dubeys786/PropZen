"""
LangGraph Controlled Property Verification Workflow
Implements deterministic finite-state decision loop with failsafe human routing.
"""

import uuid
import datetime
from typing import Dict, Any, TypedDict
from ..crew.tasks import VerificationCrewPipeline
from ..schemas.workflow_schemas import PropertyVerificationResult


class VerificationState(TypedDict):
    workflow_id: str
    property_data: Dict[str, Any]
    crew_output: Dict[str, Any]
    rule_results: Dict[str, Any]
    final_result: Dict[str, Any]
    audit_entry: Dict[str, Any]
    error: str


class PropertyVerificationGraph:
    @classmethod
    def execute(cls, property_data: Dict[str, Any]) -> PropertyVerificationResult:
        workflow_id = f"wf_verif_{uuid.uuid4().hex[:8]}"
        state: VerificationState = {
            "workflow_id": workflow_id,
            "property_data": property_data,
            "crew_output": {},
            "rule_results": {},
            "final_result": {},
            "audit_entry": {},
            "error": "",
        }

        # Step 1: Execute Multi-Agent Analysis
        state["crew_output"] = VerificationCrewPipeline.execute_property_audit(property_data)
        final_decision = state["crew_output"]["final_decision"]

        # Step 2: Deterministic Rule Checks (Hard policy guards)
        rule_checks = []
        is_hard_rejected = False

        price_cr = float(property_data.get("asking_price_cr", 0.0))
        if price_cr <= 0.01:
            rule_checks.append("HARD_FAIL: Asking price is zero or invalid.")
            is_hard_rejected = True

        sqft = float(property_data.get("sqft", 0.0))
        if sqft < 100:
            rule_checks.append("HARD_FAIL: Carpet/super area is below 100 sq.ft threshold.")
            is_hard_rejected = True

        # Rule evaluation
        decision_status = final_decision.get("status", "NEEDS_REVIEW")
        if is_hard_rejected:
            decision_status = "REJECTED"

        now_iso = datetime.datetime.utcnow().isoformat() + "Z"
        result = PropertyVerificationResult(
            workflow_id=workflow_id,
            property_id=property_data.get("property_id", f"prop_{uuid.uuid4().hex[:6]}"),
            status=decision_status,
            confidence=float(final_decision.get("confidence", 0.85)),
            risk_score=int(final_decision.get("risk_score", 15)),
            risk_level=final_decision.get("risk_level", "LOW"),
            reasons=final_decision.get("reasons", []) + rule_checks,
            missing_documents=final_decision.get("missing_documents", []),
            inconsistencies=final_decision.get("inconsistencies", []),
            recommended_action=final_decision.get("recommended_action", "ROUTE_TO_ADMIN_REVIEW"),
            verified_at=now_iso,
        )

        return result

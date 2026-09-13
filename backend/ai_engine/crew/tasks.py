"""
CrewAI Task definitions for PropZen verification, matching, and lead pipelines.
"""

from typing import Dict, Any
from .agents import (
    property_research_agent,
    document_analysis_agent,
    legal_compliance_agent,
    fraud_risk_agent,
    customer_intent_agent,
    final_review_agent,
)


class VerificationCrewPipeline:
    @classmethod
    def execute_property_audit(cls, property_data: Dict[str, Any]) -> Dict[str, Any]:
        """Executes multi-agent audit across the 5 specialized verification agents."""
        # 1. Market Research
        research_res = property_research_agent.analyze(property_data)

        # 2. Document Examiner
        doc_res = document_analysis_agent.audit_documents(property_data)

        # 3. Legal Compliance
        legal_res = legal_compliance_agent.audit_compliance(property_data, doc_res)

        # 4. Fraud & Risk Calculation
        risk_res = fraud_risk_agent.calculate_risk(property_data, research_res, doc_res)

        # 5. Final Synthesis
        final_decision = final_review_agent.synthesize(
            property_data, research_res, doc_res, legal_res, risk_res
        )

        return {
            "research": research_res,
            "document_audit": doc_res,
            "legal_compliance": legal_res,
            "risk_assessment": risk_res,
            "final_decision": final_decision,
        }


class LeadQualificationPipeline:
    @classmethod
    def execute_lead_qualification(cls, enquiry_data: Dict[str, Any]) -> Dict[str, Any]:
        return customer_intent_agent.qualify_intent(enquiry_data)

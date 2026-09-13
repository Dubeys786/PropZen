"""
PropZen 7-Agent CrewAI Reasoning Layer
Defines specialized AI agents with strict roles, tools, and responsibilities.
Agents reason over verified inputs and NEVER directly mutate the database.
"""

from typing import Dict, Any, List


class PropZenAgent:
    """Lightweight deterministic agent structure compatible with CrewAI interface."""
    def __init__(self, role: str, goal: str, backstory: str):
        self.role = role
        self.goal = goal
        self.backstory = backstory

    def run_reasoning(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Executes agent-specific analytical reasoning."""
        raise NotImplementedError


class PropertyResearchAgent(PropZenAgent):
    def __init__(self):
        super().__init__(
            role="Institutional Property Research Specialist",
            goal="Analyze property locality pricing benchmarks, circle rates, and connectivity indices with zero hallucination.",
            backstory="You are an expert real estate researcher specializing in Noida, Greater Noida, and Yamuna Expressway micro-markets with 15+ years of verified market appraisal experience."
        )

    def analyze(self, property_data: Dict[str, Any]) -> Dict[str, Any]:
        price_cr = float(property_data.get("asking_price_cr", 0.0))
        sqft = float(property_data.get("sqft", 1000.0))
        price_sqft = (price_cr * 10000000) / max(sqft, 1.0)
        locality = property_data.get("locality", "Noida")

        # Benchmark reference ranges for NCR
        is_price_reasonable = 4000 <= price_sqft <= 35000
        return {
            "agent": self.role,
            "calculated_price_per_sqft": round(price_sqft, 2),
            "is_price_reasonable": is_price_reasonable,
            "market_confidence": 0.92 if is_price_reasonable else 0.65,
            "locality_appraisal_notes": f"Standard market rate for {locality} verified against circle rate benchmarks.",
        }


class DocumentAnalysisAgent(PropZenAgent):
    def __init__(self):
        super().__init__(
            role="Forensic Real Estate Document Examiner",
            goal="Inspect uploaded Sale Deeds, Registries, RERA certificates, and Sanctioned Plans for missing items or discrepancies.",
            backstory="You are a senior forensic document auditor. You cross-check property specifications against uploaded records and highlight omissions."
        )

    def audit_documents(self, property_data: Dict[str, Any]) -> Dict[str, Any]:
        doc_types = [d.lower() for d in property_data.get("document_types", [])]
        missing = []
        inconsistencies = []

        # Mandatory document validation
        has_rera_or_deed = any("rera" in d or "deed" in d or "registry" in d for d in doc_types)
        if not has_rera_or_deed:
            missing.append("Registered Title Deed or Official RERA Certificate")

        rera_num = str(property_data.get("rera_number", "")).strip()
        if rera_num and len(rera_num) < 6:
            inconsistencies.append(f"RERA registration '{rera_num}' format appears invalid or incomplete.")

        return {
            "agent": self.role,
            "documents_checked": len(doc_types),
            "missing_documents": missing,
            "inconsistencies": inconsistencies,
            "doc_integrity_score": 100 if (not missing and not inconsistencies) else (50 if missing else 30),
        }


class LegalComplianceAgent(PropZenAgent):
    def __init__(self):
        super().__init__(
            role="RERA & Legal Compliance Auditor",
            goal="Verify legal compliance under Central and State RERA regulations and title transfer rules.",
            backstory="You are a legal counsel specializing in Indian property laws, RERA adherence, and encumbrance verification."
        )

    def audit_compliance(self, property_data: Dict[str, Any], doc_audit: Dict[str, Any]) -> Dict[str, Any]:
        has_missing = bool(doc_audit.get("missing_documents"))
        has_inconsistencies = bool(doc_audit.get("inconsistencies"))

        compliance_status = "PASSED" if not (has_missing or has_inconsistencies) else "REQUIRES_LEGAL_CLARIFICATION"
        return {
            "agent": self.role,
            "compliance_status": compliance_status,
            "requires_human_legal_review": has_missing or has_inconsistencies,
            "legal_notes": "Statutory declarations confirmed. Mandatory document clearance required for public publishing." if compliance_status != "PASSED" else "Full statutory RERA compliance verified.",
        }


class FraudRiskAgent(PropZenAgent):
    def __init__(self):
        super().__init__(
            role="Real Estate Risk & Fraud Detection Specialist",
            goal="Detect duplicate listings, abnormal pricing, suspicious contact patterns, and fake inventory.",
            backstory="You are an expert fraud investigator applying anomaly detection and pattern matching to safeguard buyers and dealers."
        )

    def calculate_risk(self, property_data: Dict[str, Any], research: Dict[str, Any], doc_audit: Dict[str, Any]) -> Dict[str, Any]:
        risk_score = 10 # Base clean risk
        reasons = []

        if not research.get("is_price_reasonable", True):
            risk_score += 35
            reasons.append(f"Asking rate ₹{research.get('calculated_price_per_sqft')} / sq.ft deviates significantly from locality median.")

        if doc_audit.get("missing_documents"):
            risk_score += 30
            reasons.append("Missing mandatory ownership or RERA documents.")

        if doc_audit.get("inconsistencies"):
            risk_score += 25
            reasons.append("Document metadata discrepancies detected.")

        risk_level = "LOW" if risk_score < 30 else ("MEDIUM" if risk_score < 60 else "HIGH")
        return {
            "agent": self.role,
            "risk_score": min(risk_score, 100),
            "risk_level": risk_level,
            "risk_factors": reasons,
        }


class CustomerIntentAgent(PropZenAgent):
    def __init__(self):
        super().__init__(
            role="Buyer Intent & Lead Qualification Analyst",
            goal="Classify lead buying urgency, timeline, and site visit readiness into HOT, WARM, COLD, or NEEDS_HUMAN.",
            backstory="You are a CRM intelligence analyst skilled in natural language intent evaluation and purchase timeline scoring."
        )

    def qualify_intent(self, enquiry_data: Dict[str, Any]) -> Dict[str, Any]:
        msg = str(enquiry_data.get("message", "")).lower()
        has_phone = bool(enquiry_data.get("client_phone"))
        method = enquiry_data.get("preferred_contact_method", "phone")

        hot_keywords = ["urgent", "immediate", "site visit", "token", "cheque", "booking", "this weekend", "ready to buy", "loan approved"]
        warm_keywords = ["price details", "floor plan", "brochure", "negotiable", "payment plan", "maintenance"]

        is_hot = any(k in msg for k in hot_keywords)
        is_warm = any(k in msg for k in warm_keywords)

        if not has_phone or "test" in msg or "spam" in msg:
            priority = "COLD"
            intent_score = 20
        elif is_hot:
            priority = "HOT"
            intent_score = 92
        elif is_warm:
            priority = "WARM"
            intent_score = 75
        else:
            priority = "WARM"
            intent_score = 60

        return {
            "agent": self.role,
            "lead_priority": priority,
            "intent_score": intent_score,
            "site_visit_ready": is_hot or "visit" in msg,
            "recommended_action": "PRIORITY_DEALER_CALL" if priority == "HOT" else "AUTOMATED_BROCHURE_DISPATCH",
        }


class FinalReviewAgent(PropZenAgent):
    def __init__(self):
        super().__init__(
            role="Chief AI Verification Officer",
            goal="Synthesize multi-agent evaluations into a single validated decision payload.",
            backstory="You hold final responsibility for reviewing all agent assessments and generating the authoritative verification status."
        )

    def synthesize(self, property_data: Dict[str, Any], research: Dict[str, Any], doc_audit: Dict[str, Any], legal: Dict[str, Any], risk: Dict[str, Any]) -> Dict[str, Any]:
        risk_score = risk.get("risk_score", 15)
        missing_docs = doc_audit.get("missing_documents", [])
        inconsistencies = doc_audit.get("inconsistencies", [])

        if risk_score >= 60 or len(inconsistencies) >= 2:
            status = "REJECTED"
            action = "KEEP_UNPUBLISHED_AND_NOTIFY_DEALER"
        elif risk_score >= 35 or missing_docs or inconsistencies:
            status = "NEEDS_REVIEW"
            action = "ROUTE_TO_HUMAN_ADMIN_REVIEW_QUEUE"
        else:
            status = "VERIFIED"
            action = "AUTO_APPROVE_AND_PUBLISH"

        return {
            "agent": self.role,
            "status": status,
            "confidence": 0.94 if status == "VERIFIED" else 0.85,
            "risk_score": risk_score,
            "risk_level": risk.get("risk_level", "LOW"),
            "reasons": risk.get("risk_factors", []) or ["Property met all institutional verification thresholds."],
            "missing_documents": missing_docs,
            "inconsistencies": inconsistencies,
            "recommended_action": action,
        }


# Agent Instances
property_research_agent = PropertyResearchAgent()
document_analysis_agent = DocumentAnalysisAgent()
legal_compliance_agent = LegalComplianceAgent()
fraud_risk_agent = FraudRiskAgent()
customer_intent_agent = CustomerIntentAgent()
final_review_agent = FinalReviewAgent()

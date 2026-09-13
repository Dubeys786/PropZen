"""
Explainable Risk Engine for PropZen GlobalVerificationEngine
Calculates a 0 to 100 composite risk score with factor breakdown and compliant recommendations.
"""
from typing import List
from ..models.enums import RiskLevel, FindingSeverity, FindingType, VerificationStatus
from ..models.schemas import Finding, RiskFactor, RiskAnalysis


class RiskEngine:
    """
    Computes an explainable 0 to 100 risk score based on rule violations and evidence.
    """

    SEVERITY_WEIGHTS = {
        FindingType.INVALID_DATE_RELATIONSHIP: 40,
        FindingType.FIELD_MISMATCH: 35,
        FindingType.SUSPICIOUS_NAME_VARIATION: 30,
        FindingType.INVALID_NUMERIC_VALUE: 25,
        FindingType.UNKNOWN_DOCUMENT_TYPE: 25,
        FindingType.MISSING_CRITICAL_FIELD: 20,
        FindingType.UNRECOGNIZED_AREA_UNIT: 15,
        FindingType.OCR_UNCERTAINTY: 15,
        FindingType.UNSUPPORTED_FORMAT: 15,
        FindingType.DUPLICATE_RECORD: 10,
    }

    def evaluate_risk(
        self,
        findings: List[Finding],
        status: VerificationStatus,
        missing_fields: List[str]
    ) -> RiskAnalysis:
        factors: List[RiskFactor] = []
        raw_score = 0

        # Insufficient data scenario
        if status == VerificationStatus.INSUFFICIENT_DATA:
            factors.append(
                RiskFactor(
                    category="Insufficient Legible Content",
                    impact_score=65,
                    severity=FindingSeverity.HIGH,
                    description="The document scan is unreadable, empty, or corrupted.",
                )
            )
            return RiskAnalysis(
                risk_score=65,
                risk_level=RiskLevel.HIGH,
                risk_factors=factors,
                recommended_action="Insufficient data for verification. Please upload a clear original document scan.",
            )

        # Process detected rule findings
        for finding in findings:
            weight = self.SEVERITY_WEIGHTS.get(finding.type, 15)
            if finding.severity == FindingSeverity.CRITICAL:
                weight = max(weight, 50)
            elif finding.severity == FindingSeverity.HIGH:
                weight = max(weight, 35)
            elif finding.severity == FindingSeverity.LOW:
                weight = min(weight, 10)

            raw_score += weight
            category_label = (finding.finding or finding.type.value).replace("_", " ").title()
            factors.append(
                RiskFactor(
                    category=category_label,
                    impact_score=weight,
                    severity=finding.severity,
                    description=finding.description,
                )
            )

        # Additional minor penalty for non-critical missing fields
        if missing_fields and len(missing_fields) > 2:
            missing_impact = min(15, len(missing_fields) * 3)
            raw_score += missing_impact
            factors.append(
                RiskFactor(
                    category="Missing Fields",
                    impact_score=missing_impact,
                    severity=FindingSeverity.LOW if missing_impact < 10 else FindingSeverity.MEDIUM,
                    description=f"{len(missing_fields)} standard deed clauses could not be indexed: {', '.join(missing_fields[:3])}.",
                )
            )

        # Score bounded [0, 100]
        risk_score = min(100, max(0, raw_score))

        # Categorize Risk Level
        if risk_score >= 80:
            level = RiskLevel.CRITICAL
            action = "Potential inconsistency detected — manual/legal verification recommended."
        elif risk_score >= 60:
            level = RiskLevel.HIGH
            action = "Potential inconsistency detected — manual/legal verification recommended."
        elif risk_score >= 30:
            level = RiskLevel.MEDIUM
            action = "Potential inconsistency detected — manual/legal verification recommended."
        else:
            level = RiskLevel.LOW
            action = "Document meets standard consistency criteria. Regular legal conveyance review applies."

        return RiskAnalysis(
            risk_score=risk_score,
            risk_level=level,
            risk_factors=factors,
            recommended_action=action,
        )


risk_engine = RiskEngine()

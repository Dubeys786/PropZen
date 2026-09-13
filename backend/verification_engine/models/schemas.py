"""
Pydantic Schemas for PropZen GlobalVerificationEngine
"""
from datetime import datetime
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, ConfigDict
from .enums import (
    DocumentType,
    VerificationStatus,
    RiskLevel,
    FindingSeverity,
    FindingType,
)


class FieldExtractionResult(BaseModel):
    """Granular extracted field result with confidence and provenance."""
    value: Optional[Any] = None
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)
    source_page: int = 1
    extraction_method: str = "OCR+RULE"


class PropertyFields(BaseModel):
    property_address: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    tehsil: Optional[str] = None
    plot_number: Optional[str] = None
    khasra_number: Optional[str] = None
    khata_number: Optional[str] = None
    survey_number: Optional[str] = None
    property_area: Optional[float] = None
    area_unit: Optional[str] = None
    property_type: Optional[str] = None


class OwnershipFields(BaseModel):
    owner_name: Optional[str] = None
    co_owner_names: List[str] = Field(default_factory=list)
    seller_name: Optional[str] = None
    buyer_name: Optional[str] = None
    previous_owner_name: Optional[str] = None


class TransactionFields(BaseModel):
    document_number: Optional[str] = None
    registration_number: Optional[str] = None
    registration_date: Optional[str] = None
    execution_date: Optional[str] = None
    consideration_amount: Optional[float] = None
    stamp_duty: Optional[float] = None
    registration_office: Optional[str] = None


class MetadataFields(BaseModel):
    document_language: Optional[str] = "English / Hindi"
    issuing_authority: Optional[str] = None
    page_count: int = 1
    document_date: Optional[str] = None
    reference_number: Optional[str] = None
    detected_fields: List[str] = Field(default_factory=list)
    missing_fields: List[str] = Field(default_factory=list)
    extraction_confidence: float = Field(default=0.90, ge=0.0, le=1.0)


class ExtractedData(BaseModel):
    property: PropertyFields = Field(default_factory=PropertyFields)
    ownership: OwnershipFields = Field(default_factory=OwnershipFields)
    transaction: TransactionFields = Field(default_factory=TransactionFields)
    metadata: MetadataFields = Field(default_factory=MetadataFields)
    field_metadata: Dict[str, FieldExtractionResult] = Field(default_factory=dict)

    def to_flat_dict(self) -> Dict[str, Any]:
        """Flatten field values for API consumers."""
        flat: Dict[str, Any] = {}
        for k, v in self.property.model_dump().items():
            if v is not None:
                flat[k] = v
        for k, v in self.ownership.model_dump().items():
            if v is not None:
                flat[k] = v
        for k, v in self.transaction.model_dump().items():
            if v is not None:
                flat[k] = v
        return flat

    def to_granular_dict(self) -> Dict[str, Dict[str, Any]]:
        """Return full field objects with value, confidence, page, and method."""
        res: Dict[str, Dict[str, Any]] = {}
        flat = self.to_flat_dict()
        for k, v in flat.items():
            if k in self.field_metadata:
                res[k] = self.field_metadata[k].model_dump()
            else:
                res[k] = {
                    "value": v,
                    "confidence": self.metadata.extraction_confidence,
                    "source_page": 1,
                    "extraction_method": "OCR+RULE",
                }
        return res


class EvidenceItem(BaseModel):
    document: str
    page: int = 1
    snippet: Optional[str] = None
    confidence: Optional[float] = None


class Finding(BaseModel):
    id: Optional[str] = None
    finding: Optional[str] = None
    severity: FindingSeverity
    type: FindingType
    field: Optional[str] = None
    description: str
    evidence: Optional[Union[List[Dict[str, Any]], Dict[str, Any], str]] = None
    recommended_action: str = "Potential inconsistency detected — manual/legal verification recommended."


class RiskFactor(BaseModel):
    category: str
    impact_score: int
    severity: FindingSeverity
    description: str


class RiskAnalysis(BaseModel):
    risk_score: int = Field(ge=0, le=100)
    risk_level: RiskLevel
    risk_factors: List[RiskFactor] = Field(default_factory=list)
    recommended_action: str = "Manual verification required."


class VerificationCaseCreate(BaseModel):
    user_id: Optional[str] = "anonymous_user"
    property_id: Optional[str] = None
    document_type: Optional[DocumentType] = DocumentType.GENERIC_PROPERTY_DOCUMENT
    notes: Optional[str] = None


class VerificationCaseResponse(BaseModel):
    case_id: str
    user_id: str
    property_id: Optional[str] = None
    document_type: DocumentType
    status: VerificationStatus
    risk_score: int
    risk_level: RiskLevel
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DocumentUploadResponse(BaseModel):
    document_id: str
    case_id: str
    file_name: str
    document_type: DocumentType
    page_count: int
    storage_path: str
    created_at: datetime


class DocumentSummary(BaseModel):
    document_id: str
    file_name: str
    document_type: DocumentType
    page_count: int
    sha256_hash: Optional[str] = None


class VerificationAnalyzeResponse(BaseModel):
    case_id: str
    status: VerificationStatus
    risk_score: int
    risk_level: RiskLevel
    document_type: DocumentType
    documents: List[Dict[str, Any]] = Field(default_factory=list)
    extracted_data: Dict[str, Any] = Field(default_factory=dict)
    field_details: Dict[str, Dict[str, Any]] = Field(default_factory=dict)
    findings: List[Finding] = Field(default_factory=list)
    missing_fields: List[str] = Field(default_factory=list)
    recommended_actions: List[str] = Field(default_factory=list)
    recommended_action: str = "Potential inconsistency detected — manual/legal verification recommended."
    disclaimer: str = "AI-assisted preliminary verification. This result does not constitute legal title certification."


class AuditLogEntry(BaseModel):
    id: Optional[str] = None
    case_id: str
    action: str
    actor: str = "system"
    details: Dict[str, Any] = Field(default_factory=dict)
    created_at: Optional[datetime] = None


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    ai_provider: str
    storage_mode: str
    timestamp: datetime

"""
Pydantic Schemas for PropZen Programmatic SEO & AI Content Automation
Strictly validates market data inputs, generated articles, fact checks, and sitemaps.
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional


class SeoDataIngestionInput(BaseModel):
    source_name: str
    source_url: Optional[str] = None
    collection_date: str
    location: str
    property_type: str = "All"
    raw_data: Dict[str, Any]
    confidence_score: float = 1.0


class SeoFaqItem(BaseModel):
    question: str
    answer: str


class SeoInternalLink(BaseModel):
    anchor_text: str
    target_url: str
    context: str


class GeneratedContentPayload(BaseModel):
    title: str
    slug: str
    meta_title: str
    meta_description: str
    primary_keyword: str
    secondary_keywords: List[str] = Field(default_factory=list)
    content: str
    faq: List[SeoFaqItem] = Field(default_factory=list)
    internal_links: List[SeoInternalLink] = Field(default_factory=list)
    source_references: List[str] = Field(default_factory=list)
    content_type: str = "Market_Report"
    location: str
    property_type: str = "All"
    freshness_date: str
    quality_score: int = Field(default=95, ge=0, le=100)
    decision: str = Field(
        default="HUMAN_REVIEW",
        description="Decision: PUBLISH, UPDATE_EXISTING_ARTICLE, HUMAN_REVIEW, REJECT, or WAIT_FOR_MORE_DATA"
    )
    fact_check_warnings: List[str] = Field(default_factory=list)
    duplicate_similarity_score: float = 0.0


class ProgrammaticPageData(BaseModel):
    slug: str
    page_type: str = "property-rates"
    city: str
    sector: Optional[str] = None
    property_type: str = "Apartment"
    bhk: Optional[str] = None
    avg_price_sqft: float
    price_range_min: float
    price_range_max: float
    trend_percentage: float
    trend_summary: str
    available_properties_count: int
    sample_property_ids: List[str] = Field(default_factory=list)
    faqs: List[SeoFaqItem] = Field(default_factory=list)
    meta_title: str
    meta_description: str

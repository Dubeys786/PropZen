"""
LangGraph Controlled Programmatic SEO & Content Decision Workflow
Strictly validates source data freshness, detects duplicate slugs, verifies facts,
and enforces the quality gate before publication.
"""

from typing import Dict, Any, List
from ..crew.seo_tasks import SeoContentPipeline
from ..schemas.seo_schemas import GeneratedContentPayload


class SeoContentDecisionGraph:
    @classmethod
    def execute(
        cls,
        raw_data: Dict[str, Any],
        location: str,
        property_type: str = "All",
        existing_slugs: List[str] = None,
    ) -> GeneratedContentPayload:
        existing_slugs = existing_slugs or []

        # 1. Validate Input Data
        if not raw_data or not raw_data.get("avg_price_sqft"):
            return GeneratedContentPayload(
                title=f"Insufficient Market Data for {location}",
                slug=f"/insights/insufficient-data-{location.lower().replace(' ', '-')}",
                meta_title="Insufficient Market Data",
                meta_description="Data collection in progress.",
                primary_keyword=location,
                content="Market data currently insufficient for high-quality automated publication.",
                location=location,
                property_type=property_type,
                freshness_date="N/A",
                quality_score=0,
                decision="WAIT_FOR_MORE_DATA",
                fact_check_warnings=["No valid average price per sq.ft found in raw source feed."],
            )

        # 2. Execute Multi-Agent Content Pipeline
        result_dict = SeoContentPipeline.generate_verified_article(
            raw_data=raw_data,
            location=location,
            property_type=property_type,
            existing_slugs=existing_slugs,
        )

        return GeneratedContentPayload(**result_dict)

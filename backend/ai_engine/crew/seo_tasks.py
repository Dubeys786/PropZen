"""
CrewAI Content Task Pipeline for PropZen Programmatic SEO
"""

from typing import Dict, Any, List
from .seo_agents import (
    seo_research_agent,
    seo_writer_agent,
    seo_fact_agent,
    seo_opt_agent,
    seo_quality_agent,
    seo_decision_agent,
)


class SeoContentPipeline:
    @classmethod
    def generate_verified_article(
        cls, raw_data: Dict[str, Any], location: str, property_type: str = "All", existing_slugs: List[str] = None
    ) -> Dict[str, Any]:
        existing_slugs = existing_slugs or []

        # 1. Market Research Analysis
        research = seo_research_agent.analyze_source_data(raw_data, location)

        # 2. Article Drafting
        draft = seo_writer_agent.write_article(research, location, property_type)

        # 3. Fact Checking against raw data
        fact_check = seo_fact_agent.verify_claims(draft, raw_data)

        # 4. SEO Optimization & Linking
        seo_opt = seo_opt_agent.optimize(draft, location)

        # 5. Quality & Duplicate Evaluation
        quality = seo_quality_agent.review_quality(draft, existing_slugs)

        # 6. Final Decision Router
        decision = seo_decision_agent.decide(quality, fact_check)

        return {
            "title": draft["title"],
            "slug": draft["slug"],
            "meta_title": draft["meta_title"],
            "meta_description": draft["meta_description"],
            "primary_keyword": draft["primary_keyword"],
            "secondary_keywords": draft["secondary_keywords"],
            "content": draft["content"],
            "faq": draft["faq"],
            "internal_links": seo_opt["internal_links"],
            "source_references": [raw_data.get("source_name", "Official PropZen Registry Feed")],
            "content_type": "Market_Report",
            "location": location,
            "property_type": property_type,
            "freshness_date": raw_data.get("collection_date", ""),
            "quality_score": quality["quality_score"],
            "duplicate_similarity_score": 0.0 if not quality["is_duplicate"] else 1.0,
            "fact_check_warnings": fact_check["warnings"],
            "decision": decision,
        }

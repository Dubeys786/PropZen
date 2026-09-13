"""
Unit Tests for Programmatic SEO Content Graph
"""

from ..workflows.seo_content_decision_graph import SeoContentDecisionGraph


def test_seo_content_decision_graph_valid_article():
    raw_data = {
        "source_name": "UP_Gov_Circle_Rates",
        "collection_date": "2026-08-15",
        "avg_price_sqft": 9200,
        "prev_price_sqft": 8600,
        "infrastructure_drivers": ["Aqua Line Metro Extension", "Jewar Airport Corridor"],
    }

    result = SeoContentDecisionGraph.execute(
        raw_data=raw_data,
        location="Sector 150 Noida",
        property_type="Apartment",
        existing_slugs=[],
    )

    assert result.decision == "PUBLISH"
    assert result.quality_score >= 90
    assert "/insights/sector-150-noida" in result.slug
    assert len(result.faq) >= 2
    assert len(result.internal_links) >= 1
    assert not result.fact_check_warnings


def test_seo_content_decision_graph_rejects_duplicate():
    raw_data = {
        "source_name": "UP_Gov_Circle_Rates",
        "avg_price_sqft": 9200,
        "prev_price_sqft": 8600,
    }
    existing = ["/insights/sector-150-noida-property-rates-trends"]

    result = SeoContentDecisionGraph.execute(
        raw_data=raw_data,
        location="Sector 150 Noida",
        property_type="Apartment",
        existing_slugs=existing,
    )

    assert result.decision == "REJECT"
    assert result.duplicate_similarity_score == 1.0


def test_seo_content_decision_graph_insufficient_data():
    raw_data = {} # Empty data
    result = SeoContentDecisionGraph.execute(
        raw_data=raw_data,
        location="Unknown Sector",
    )

    assert result.decision == "WAIT_FOR_MORE_DATA"
    assert result.quality_score == 0

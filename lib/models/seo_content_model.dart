import 'dart:convert';

class SeoFaqModel {
  final String question;
  final String answer;

  const SeoFaqModel({required this.question, required this.answer});

  factory SeoFaqModel.fromMap(Map<String, dynamic> map) {
    return SeoFaqModel(
      question: map['question']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'question': question, 'answer': answer};
}

class SeoInternalLinkModel {
  final String anchorText;
  final String targetUrl;
  final String context;

  const SeoInternalLinkModel({
    required this.anchorText,
    required this.targetUrl,
    required this.context,
  });

  factory SeoInternalLinkModel.fromMap(Map<String, dynamic> map) {
    return SeoInternalLinkModel(
      anchorText: map['anchor_text']?.toString() ?? map['anchorText']?.toString() ?? '',
      targetUrl: map['target_url']?.toString() ?? map['targetUrl']?.toString() ?? '',
      context: map['context']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'anchor_text': anchorText,
        'target_url': targetUrl,
        'context': context,
      };
}

class SeoArticleModel {
  final String id;
  final String title;
  final String slug;
  final String metaTitle;
  final String metaDescription;
  final String primaryKeyword;
  final List<String> secondaryKeywords;
  final String content;
  final List<SeoFaqModel> faq;
  final List<SeoInternalLinkModel> internalLinks;
  final List<String> sourceReferences;
  final String contentType;
  final String location;
  final String propertyType;
  final String freshnessDate;
  final int qualityScore;
  final String status; // 'DRAFT', 'HUMAN_REVIEW', 'PUBLISHED', 'REJECTED'
  final List<String> factCheckWarnings;
  final DateTime createdAt;

  const SeoArticleModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.metaTitle,
    required this.metaDescription,
    required this.primaryKeyword,
    required this.secondaryKeywords,
    required this.content,
    required this.faq,
    required this.internalLinks,
    required this.sourceReferences,
    required this.contentType,
    required this.location,
    required this.propertyType,
    required this.freshnessDate,
    required this.qualityScore,
    required this.status,
    required this.factCheckWarnings,
    required this.createdAt,
  });

  factory SeoArticleModel.fromMap(Map<String, dynamic> map) {
    List<SeoFaqModel> faqs = [];
    if (map['faq'] is List) {
      faqs = (map['faq'] as List)
          .map((f) => SeoFaqModel.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList();
    }

    List<SeoInternalLinkModel> links = [];
    if (map['internal_links'] is List) {
      links = (map['internal_links'] as List)
          .map((l) => SeoInternalLinkModel.fromMap(Map<String, dynamic>.from(l as Map)))
          .toList();
    }

    return SeoArticleModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      metaTitle: map['meta_title']?.toString() ?? map['title']?.toString() ?? '',
      metaDescription: map['meta_description']?.toString() ?? '',
      primaryKeyword: map['primary_keyword']?.toString() ?? '',
      secondaryKeywords: (map['secondary_keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
      content: map['content']?.toString() ?? '',
      faq: faqs,
      internalLinks: links,
      sourceReferences: (map['source_references'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contentType: map['content_type']?.toString() ?? 'Market_Report',
      location: map['location']?.toString() ?? 'Noida',
      propertyType: map['property_type']?.toString() ?? 'All',
      freshnessDate: map['freshness_date']?.toString() ?? '',
      qualityScore: int.tryParse(map['quality_score']?.toString() ?? '95') ?? 95,
      status: map['status']?.toString() ?? 'PUBLISHED',
      factCheckWarnings: (map['fact_check_warnings'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ProgrammaticPageModel {
  final String id;
  final String slug;
  final String pageType; // 'property-rates', 'buy-category', 'rent-category'
  final String city;
  final String sector;
  final String propertyType;
  final String bhk;
  final double avgPriceSqft;
  final double priceRangeMin;
  final double priceRangeMax;
  final double trendPercentage;
  final String trendSummary;
  final int availablePropertiesCount;
  final List<String> samplePropertyIds;
  final List<SeoFaqModel> faqs;
  final String metaTitle;
  final String metaDescription;
  final bool isActive;
  final DateTime lastUpdatedAt;

  const ProgrammaticPageModel({
    required this.id,
    required this.slug,
    required this.pageType,
    required this.city,
    required this.sector,
    required this.propertyType,
    required this.bhk,
    required this.avgPriceSqft,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.trendPercentage,
    required this.trendSummary,
    required this.availablePropertiesCount,
    required this.samplePropertyIds,
    required this.faqs,
    required this.metaTitle,
    required this.metaDescription,
    required this.isActive,
    required this.lastUpdatedAt,
  });

  factory ProgrammaticPageModel.fromMap(Map<String, dynamic> map) {
    List<SeoFaqModel> faqs = [];
    if (map['faqs'] is List) {
      faqs = (map['faqs'] as List)
          .map((f) => SeoFaqModel.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList();
    }

    return ProgrammaticPageModel(
      id: map['id']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      pageType: map['page_type']?.toString() ?? 'property-rates',
      city: map['city']?.toString() ?? 'Noida',
      sector: map['sector']?.toString() ?? '',
      propertyType: map['property_type']?.toString() ?? 'Apartment',
      bhk: map['bhk']?.toString() ?? '3 BHK',
      avgPriceSqft: double.tryParse(map['avg_price_sqft']?.toString() ?? '8500') ?? 8500.0,
      priceRangeMin: double.tryParse(map['price_range_min']?.toString() ?? '7000') ?? 7000.0,
      priceRangeMax: double.tryParse(map['price_range_max']?.toString() ?? '11000') ?? 11000.0,
      trendPercentage: double.tryParse(map['trend_percentage']?.toString() ?? '5.4') ?? 5.4,
      trendSummary: map['trend_summary']?.toString() ?? 'Market rates have grown steadily across this micro-market.',
      availablePropertiesCount: int.tryParse(map['available_properties_count']?.toString() ?? '12') ?? 12,
      samplePropertyIds: (map['sample_property_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      faqs: faqs,
      metaTitle: map['meta_title']?.toString() ?? 'Property Rates & Trends | PropZen',
      metaDescription: map['meta_description']?.toString() ?? '',
      isActive: map['is_active'] != false,
      lastUpdatedAt: DateTime.tryParse(map['last_updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

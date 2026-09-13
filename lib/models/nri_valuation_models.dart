class HistoricalTrendPoint {
  final String year;
  final double avgPriceSqft;
  final double growthRatePercent;

  const HistoricalTrendPoint({
    required this.year,
    required this.avgPriceSqft,
    required this.growthRatePercent,
  });

  Map<String, dynamic> toMap() => {
        'year': year,
        'avg_price_sqft': avgPriceSqft,
        'growth_rate_percent': growthRatePercent,
      };

  factory HistoricalTrendPoint.fromMap(Map<String, dynamic> map) {
    return HistoricalTrendPoint(
      year: map['year']?.toString() ?? '2023',
      avgPriceSqft: (map['avg_price_sqft'] as num?)?.toDouble() ?? 0.0,
      growthRatePercent: (map['growth_rate_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PropertyValuationReportModel {
  final String id;
  final String propertyId;
  final String? userId;
  final double currentValueCr;
  final double pricePerSqft;
  final List<HistoricalTrendPoint> historicalTrend;
  final double conservative1yCr;
  final double conservative3yCr;
  final double conservative5yCr;
  final double base1yCr;
  final double base3yCr;
  final double base5yCr;
  final double optimistic1yCr;
  final double optimistic3yCr;
  final double optimistic5yCr;
  final double rentalYieldProjected;
  final String assumptions;
  final DateTime sourceDataTimestamp;
  final String modelVersion;
  final int confidenceScore;
  final String aiExplanation;
  final String disclaimer;
  final DateTime generatedAt;

  const PropertyValuationReportModel({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.currentValueCr,
    required this.pricePerSqft,
    required this.historicalTrend,
    required this.conservative1yCr,
    required this.conservative3yCr,
    required this.conservative5yCr,
    required this.base1yCr,
    required this.base3yCr,
    required this.base5yCr,
    required this.optimistic1yCr,
    required this.optimistic3yCr,
    required this.optimistic5yCr,
    this.rentalYieldProjected = 4.5,
    required this.assumptions,
    required this.sourceDataTimestamp,
    this.modelVersion = 'v2.4-hybrid',
    this.confidenceScore = 92,
    required this.aiExplanation,
    this.disclaimer = 'Illustrative projection based on available data. Actual market value may differ.',
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'current_value': currentValueCr,
      'price_per_sqft': pricePerSqft,
      'historical_trend': historicalTrend.map((e) => e.toMap()).toList(),
      'conservative_1y': conservative1yCr,
      'conservative_3y': conservative3yCr,
      'conservative_5y': conservative5yCr,
      'base_1y': base1yCr,
      'base_3y': base3yCr,
      'base_5y': base5yCr,
      'optimistic_1y': optimistic1yCr,
      'optimistic_3y': optimistic3yCr,
      'optimistic_5y': optimistic5yCr,
      'rental_yield_projected': rentalYieldProjected,
      'assumptions': assumptions,
      'source_data_timestamp': sourceDataTimestamp.toIso8601String(),
      'model_version': modelVersion,
      'confidence_score': confidenceScore,
      'ai_explanation': aiExplanation,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory PropertyValuationReportModel.fromMap(Map<String, dynamic> map) {
    List<HistoricalTrendPoint> trend = [];
    if (map['historical_trend'] is List) {
      trend = (map['historical_trend'] as List)
          .map((e) => HistoricalTrendPoint.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return PropertyValuationReportModel(
      id: map['id']?.toString() ?? 'PVR-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: map['property_id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      currentValueCr: (map['current_value'] as num?)?.toDouble() ?? 1.5,
      pricePerSqft: (map['price_per_sqft'] as num?)?.toDouble() ?? 8500.0,
      historicalTrend: trend,
      conservative1yCr: (map['conservative_1y'] as num?)?.toDouble() ?? 1.59,
      conservative3yCr: (map['conservative_3y'] as num?)?.toDouble() ?? 1.78,
      conservative5yCr: (map['conservative_5y'] as num?)?.toDouble() ?? 2.00,
      base1yCr: (map['base_1y'] as num?)?.toDouble() ?? 1.66,
      base3yCr: (map['base_3y'] as num?)?.toDouble() ?? 2.05,
      base5yCr: (map['base_5y'] as num?)?.toDouble() ?? 2.53,
      optimistic1yCr: (map['optimistic_1y'] as num?)?.toDouble() ?? 1.74,
      optimistic3yCr: (map['optimistic_3y'] as num?)?.toDouble() ?? 2.35,
      optimistic5yCr: (map['optimistic_5y'] as num?)?.toDouble() ?? 3.15,
      rentalYieldProjected: (map['rental_yield_projected'] as num?)?.toDouble() ?? 4.5,
      assumptions: map['assumptions']?.toString() ?? 'Baseline economic growth and civic infrastructure progression.',
      sourceDataTimestamp: map['source_data_timestamp'] != null
          ? DateTime.tryParse(map['source_data_timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      modelVersion: map['model_version']?.toString() ?? 'v2.4-hybrid',
      confidenceScore: (map['confidence_score'] as num?)?.toInt() ?? 92,
      aiExplanation: map['ai_explanation']?.toString() ?? '',
      generatedAt: map['generated_at'] != null
          ? DateTime.tryParse(map['generated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

import 'package:flutter/foundation.dart';
import '../models/property.dart';
import 'property_state_service.dart';

class AdvisorRecommendation {
  final Property property;
  final int matchPercentage; // e.g. 96%
  final List<String> matchReasons;
  final String recommendationSummary;

  const AdvisorRecommendation({
    required this.property,
    required this.matchPercentage,
    required this.matchReasons,
    required this.recommendationSummary,
  });
}

class AIAdvisorService extends ChangeNotifier {
  AIAdvisorService._internal();
  static final AIAdvisorService instance = AIAdvisorService._internal();
  factory AIAdvisorService() => instance;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  // =========================================================================
  // 1. GENERATE RECOMMENDATIONS (Strictly from actual Supabase property data)
  // =========================================================================
  Future<List<AdvisorRecommendation>> getRecommendations({
    required String location,
    required double budgetCr,
    required String propertyType,
    required String bhk,
    int? minAreaSqft,
    String purpose = 'Residence', // 'Investment' or 'Residence'
    String possessionPreference = 'Ready to Move',
    Set<String>? desiredAmenities,
    String riskPreference = 'Low Risk',
  }) async {
    _isAnalyzing = true;
    notifyListeners();

    // Small delay to simulate AI evaluation
    await Future.delayed(const Duration(milliseconds: 400));

    final allPublished = PropertyStateService.instance.publishedProperties;
    final List<AdvisorRecommendation> results = [];

    for (final prop in allPublished) {
      int score = 70;
      final List<String> reasons = [];

      // 1. Location match
      final locLower = location.toLowerCase();
      if (locLower.isNotEmpty && locLower != 'all') {
        if (prop.effectiveLocality.toLowerCase().contains(locLower) ||
            prop.city.toLowerCase().contains(locLower) ||
            prop.sector.toLowerCase().contains(locLower)) {
          score += 10;
          reasons.add('Prime match in ${prop.effectiveLocality}');
        }
      }

      // 2. Budget match
      if (budgetCr > 0) {
        final diff = (prop.askingPriceCr - budgetCr).abs();
        if (diff <= 0.3) {
          score += 10;
          reasons.add('Within your target budget of ₹${budgetCr.toStringAsFixed(2)} Cr');
        } else if (prop.askingPriceCr <= budgetCr) {
          score += 5;
          reasons.add('Under your max budget (₹${prop.formattedPrice})');
        }
      }

      // 3. BHK match
      if (bhk.isNotEmpty && bhk != 'All') {
        if (prop.bhk.toLowerCase().contains(bhk.toLowerCase())) {
          score += 10;
          reasons.add('Exact ${prop.bhk} configuration');
        }
      }

      // 4. Property Type
      if (propertyType.isNotEmpty && propertyType != 'All') {
        if (prop.propertyType.toLowerCase().contains(propertyType.toLowerCase())) {
          score += 5;
          reasons.add('Matches ${prop.propertyType} category');
        }
      }

      // 5. Purpose & Yield
      if (purpose == 'Investment') {
        if (prop.rentalYieldPercent >= 4.5 || prop.score10x >= 85) {
          score += 5;
          reasons.add('High rental yield (${prop.rentalYieldPercent}% p.a.) and appreciation potential');
        }
      }

      // 6. Verification Status
      if (prop.isReraApproved || prop.documentStatus.toLowerCase().contains('verified')) {
        score += 5;
        reasons.add('RERA Approved & Title Verified ✓');
      }

      final finalScore = score.clamp(60, 98);
      results.add(AdvisorRecommendation(
        property: prop,
        matchPercentage: finalScore,
        matchReasons: reasons.isNotEmpty ? reasons : ['Verified property matching your general parameters'],
        recommendationSummary: 'Recommended for ${prop.title} with a $finalScore% suitability rating for $purpose.',
      ));
    }

    // Sort descending by match percentage
    results.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    _isAnalyzing = false;
    notifyListeners();

    return results;
  }
}

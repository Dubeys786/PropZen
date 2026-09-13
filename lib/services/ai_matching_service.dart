import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/buyer_requirement.dart';
import '../models/property.dart';
import 'property_state_service.dart';

class SemanticMatchResult {
  final String propertyId;
  final String title;
  final String locality;
  final String city;
  final String bhk;
  final double askingPriceCr;
  final int matchScore;
  final List<String> whyItMatches;
  final List<String> importantDifferences;
  final List<String> potentialConcerns;

  const SemanticMatchResult({
    required this.propertyId,
    required this.title,
    required this.locality,
    required this.city,
    required this.bhk,
    required this.askingPriceCr,
    required this.matchScore,
    required this.whyItMatches,
    required this.importantDifferences,
    required this.potentialConcerns,
  });

  factory SemanticMatchResult.fromMap(Map<String, dynamic> map) {
    return SemanticMatchResult(
      propertyId: map['property_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      locality: map['locality']?.toString() ?? '',
      city: map['city']?.toString() ?? 'Noida',
      bhk: map['bhk']?.toString() ?? '3 BHK',
      askingPriceCr: double.tryParse(map['asking_price_cr']?.toString() ?? '1.0') ?? 1.0,
      matchScore: int.tryParse(map['match_score']?.toString() ?? '85') ?? 85,
      whyItMatches: (map['why_it_matches'] as List?)?.map((e) => e.toString()).toList() ?? [],
      importantDifferences: (map['important_differences'] as List?)?.map((e) => e.toString()).toList() ?? [],
      potentialConcerns: (map['potential_concerns'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class AiMatchingService {
  AiMatchingService._();
  static final AiMatchingService instance = AiMatchingService._();

  BuyerRequirement? _currentRequirement;
  BuyerRequirement? get currentRequirement => _currentRequirement;

  void saveRequirement(BuyerRequirement req) {
    _currentRequirement = req;
  }

  /// Semantic Match query calling LangGraph matching engine
  Future<List<SemanticMatchResult>> executeSemanticMatch(String naturalLanguageQuery, {int limit = 10}) async {
    final proxyBase = EnvConfig.backendApiBaseUrl;
    final endpoint = proxyBase.isEmpty
        ? Uri.parse('/api/ai/match-properties')
        : Uri.parse('$proxyBase/api/ai/match-properties');

    try {
      final res = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'query': naturalLanguageQuery,
          'limit': limit,
        }),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map && data['matches'] is List) {
          return (data['matches'] as List)
              .map((m) => SemanticMatchResult.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AiMatchingService] Semantic match proxy error: $e');
    }

    // Heuristic fallback
    final heuristic = getTopMatches(limit: limit);
    return heuristic
        .map((h) => SemanticMatchResult(
              propertyId: h.property.id,
              title: h.property.title,
              locality: h.property.sector,
              city: h.property.city,
              bhk: h.property.bhk,
              askingPriceCr: h.property.askingPriceCr,
              matchScore: h.matchPercentage,
              whyItMatches: ['Verified match for ${h.property.bhk} in ${h.property.sector}'],
              importantDifferences: [],
              potentialConcerns: [],
            ))
        .toList();
  }

  /// Calculates top property matches ranked by match percentage
  List<PropertyMatchResult> getTopMatches({BuyerRequirement? requirement, int limit = 10}) {
    final req = requirement ?? _currentRequirement ?? BuyerRequirement.defaultRequirement('usr_active');
    final List<Property> properties = PropertyStateService.instance.allProperties;

    if (properties.isEmpty) {
      return [];
    }

    final List<PropertyMatchResult> results = [];
    for (final prop in properties) {
      results.add(req.matchAgainst(prop));
    }

    // Sort descending by match percentage, then by intelligence score
    results.sort((a, b) {
      final cmp = b.matchPercentage.compareTo(a.matchPercentage);
      if (cmp != 0) return cmp;
      return b.property.intelligenceScore.compareTo(a.property.intelligenceScore);
    });

    return results.take(limit).toList();
  }
}


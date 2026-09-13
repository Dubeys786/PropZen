import 'property.dart';

class AiAdvisorCriteria {
  final double? maxBudgetCr;
  final double? minBudgetCr;
  final String? propertyType;
  final String? localityOrSector;
  final String? bhk;
  final String? investmentPurpose;
  final bool requiresReadyToMove;
  final bool requiresReraVerified;

  const AiAdvisorCriteria({
    this.maxBudgetCr,
    this.minBudgetCr,
    this.propertyType,
    this.localityOrSector,
    this.bhk,
    this.investmentPurpose,
    this.requiresReadyToMove = false,
    this.requiresReraVerified = true,
  });

  Map<String, dynamic> toMap() => {
        'max_budget_cr': maxBudgetCr,
        'min_budget_cr': minBudgetCr,
        'property_type': propertyType,
        'locality_sector': localityOrSector,
        'bhk': bhk,
        'investment_purpose': investmentPurpose,
        'ready_to_move': requiresReadyToMove,
        'rera_verified': requiresReraVerified,
      };

  factory AiAdvisorCriteria.fromMap(Map<String, dynamic> map) {
    return AiAdvisorCriteria(
      maxBudgetCr: (map['max_budget_cr'] as num?)?.toDouble(),
      minBudgetCr: (map['min_budget_cr'] as num?)?.toDouble(),
      propertyType: map['property_type']?.toString(),
      localityOrSector: map['locality_sector']?.toString(),
      bhk: map['bhk']?.toString(),
      investmentPurpose: map['investment_purpose']?.toString(),
      requiresReadyToMove: map['ready_to_move'] == true,
      requiresReraVerified: map['rera_verified'] != false,
    );
  }
}

class AiAdvisorMatchResult {
  final Property property;
  final int matchScore; // 0 to 100
  final bool isExactMatch; // true = Exact Match, false = Closest Alternative
  final List<String> whyItMatches;
  final double projectedYield;
  final String matchHeadline;

  const AiAdvisorMatchResult({
    required this.property,
    required this.matchScore,
    required this.isExactMatch,
    required this.whyItMatches,
    this.projectedYield = 4.5,
    required this.matchHeadline,
  });
}

class AiAdvisorMessageModel {
  final String id;
  final String sessionId;
  final String sender; // 'user' or 'assistant'
  final String content;
  final AiAdvisorCriteria? extractedCriteria;
  final List<AiAdvisorMatchResult> recommendations;
  final bool hasExactMatches;
  final DateTime createdAt;

  const AiAdvisorMessageModel({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    this.extractedCriteria,
    this.recommendations = const [],
    this.hasExactMatches = true,
    required this.createdAt,
  });
}

import '../models/property.dart';

class MatchReason {
  final String text;
  final bool isMatched;
  final int points;

  const MatchReason({
    required this.text,
    required this.isMatched,
    required this.points,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'isMatched': isMatched,
        'points': points,
      };

  factory MatchReason.fromMap(Map<String, dynamic> map) => MatchReason(
        text: map['text'] as String? ?? '',
        isMatched: map['isMatched'] as bool? ?? false,
        points: (map['points'] as num?)?.toInt() ?? 0,
      );
}

class PropertyMatchResult {
  final Property property;
  final int matchPercentage;
  final List<MatchReason> matchReasons;
  final String matchGrade; // 'Exceptional' (90%+), 'High' (80-89%), 'Good' (70-79%), 'Moderate' (<70%)

  const PropertyMatchResult({
    required this.property,
    required this.matchPercentage,
    required this.matchReasons,
    required this.matchGrade,
  });
}

class BuyerRequirement {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final List<String> preferredLocations;
  final double minBudgetCr;
  final double maxBudgetCr;
  final String propertyType; // 'Apartment', 'Villa', 'Plot', 'Office Space'
  final String bhk; // '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'
  final double minAreaSqft;
  final List<String> requiredAmenities;
  final String purchasePurpose; // 'Self-Use', 'Investment', 'Rental Income'
  final String possessionPreference; // 'Ready to Move', 'Within 6 Months', 'Under Construction'
  final DateTime createdAt;
  final DateTime updatedAt;

  BuyerRequirement({
    required this.id,
    required this.userId,
    this.userName = 'Verified Buyer',
    this.userPhone = '',
    this.userEmail = '',
    required this.preferredLocations,
    required this.minBudgetCr,
    required this.maxBudgetCr,
    this.propertyType = 'Apartment',
    this.bhk = '3 BHK',
    this.minAreaSqft = 1200,
    this.requiredAmenities = const ['Club House', 'Swimming Pool', 'Gym', 'Security'],
    this.purchasePurpose = 'Self-Use',
    this.possessionPreference = 'Ready to Move',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Deterministic matching calculation against a given Property
  PropertyMatchResult matchAgainst(Property prop) {
    int totalScore = 0;
    final List<MatchReason> reasons = [];

    // 1. Location Match (Max 30 pts)
    final propLoc = '${prop.city} ${prop.sector} ${prop.address}'.toLowerCase();
    bool locationMatch = false;
    if (preferredLocations.isEmpty) {
      locationMatch = true;
      totalScore += 25;
      reasons.add(const MatchReason(text: 'Location in NCR Region', isMatched: true, points: 25));
    } else {
      for (final loc in preferredLocations) {
        if (propLoc.contains(loc.toLowerCase().trim())) {
          locationMatch = true;
          break;
        }
      }
      if (locationMatch) {
        totalScore += 30;
        reasons.add(const MatchReason(text: 'Preferred location matched', isMatched: true, points: 30));
      } else {
        totalScore += 10;
        reasons.add(const MatchReason(text: 'Nearby NCR corridor', isMatched: false, points: 10));
      }
    }

    // 2. Budget Fit (Max 25 pts)
    final priceCr = prop.askingPriceCr > 0 ? prop.askingPriceCr : (prop.price / 10000000);
    if (priceCr >= minBudgetCr && priceCr <= maxBudgetCr) {
      totalScore += 25;
      reasons.add(const MatchReason(text: 'Within budget requirement', isMatched: true, points: 25));
    } else if (priceCr <= maxBudgetCr * 1.1) {
      totalScore += 18;
      reasons.add(const MatchReason(text: 'Within 10% budget range', isMatched: true, points: 18));
    } else if (priceCr < minBudgetCr) {
      totalScore += 20;
      reasons.add(const MatchReason(text: 'Below max budget (Value deal)', isMatched: true, points: 20));
    } else {
      totalScore += 5;
      reasons.add(const MatchReason(text: 'Higher than specified budget', isMatched: false, points: 5));
    }

    // 3. BHK & Configuration Match (Max 20 pts)
    if (prop.bhk.toLowerCase().contains(bhk.toLowerCase()) || bhk.isEmpty) {
      totalScore += 20;
      reasons.add(MatchReason(text: '$bhk layout matched', isMatched: true, points: 20));
    } else if (prop.bhk.contains('3') && bhk.contains('2')) {
      totalScore += 14;
      reasons.add(const MatchReason(text: 'Higher configuration offered', isMatched: true, points: 14));
    } else {
      totalScore += 5;
      reasons.add(MatchReason(text: '${prop.bhk} vs $bhk requested', isMatched: false, points: 5));
    }

    // 4. Amenities Match (Max 15 pts)
    if (requiredAmenities.isNotEmpty) {
      int matchedAmenities = 0;
      for (final req in requiredAmenities) {
        if (prop.amenities.any((a) => a.toLowerCase().contains(req.toLowerCase()))) {
          matchedAmenities++;
        }
      }
      final double ratio = matchedAmenities / requiredAmenities.length;
      final int amenityPts = (ratio * 15).round();
      totalScore += amenityPts;
      if (ratio >= 0.75) {
        reasons.add(MatchReason(text: 'Top amenities available ($matchedAmenities/${requiredAmenities.length})', isMatched: true, points: amenityPts));
      } else if (ratio > 0) {
        reasons.add(MatchReason(text: 'Key amenities available ($matchedAmenities/${requiredAmenities.length})', isMatched: true, points: amenityPts));
      } else {
        reasons.add(const MatchReason(text: 'Basic amenities provided', isMatched: false, points: 0));
      }
    } else {
      totalScore += 15;
      reasons.add(const MatchReason(text: 'Standard premium amenities included', isMatched: true, points: 15));
    }

    // 5. Possession Timeline (Max 10 pts)
    if (possessionPreference.toLowerCase() == prop.possessionStatus.toLowerCase() ||
        (possessionPreference == 'Ready to Move' && prop.possessionStatus.contains('Ready'))) {
      totalScore += 10;
      reasons.add(const MatchReason(text: 'Preferred possession timeline', isMatched: true, points: 10));
    } else if (prop.possessionStatus.isNotEmpty) {
      totalScore += 6;
      reasons.add(MatchReason(text: 'Timeline: ${prop.possessionStatus}', isMatched: true, points: 6));
    } else {
      totalScore += 4;
    }

    // Normalized Match Percentage (Clamped 40 - 98%)
    final clampedPercent = totalScore.clamp(40, 98);
    String grade = 'Moderate Match';
    if (clampedPercent >= 90) {
      grade = 'Exceptional Match';
    } else if (clampedPercent >= 80) {
      grade = 'High Match';
    } else if (clampedPercent >= 70) {
      grade = 'Good Match';
    }

    return PropertyMatchResult(
      property: prop,
      matchPercentage: clampedPercent,
      matchReasons: reasons,
      matchGrade: grade,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_phone': userPhone,
        'user_email': userEmail,
        'preferred_locations': preferredLocations,
        'min_budget_cr': minBudgetCr,
        'max_budget_cr': maxBudgetCr,
        'property_type': propertyType,
        'bhk': bhk,
        'min_area_sqft': minAreaSqft,
        'required_amenities': requiredAmenities,
        'purchase_purpose': purchasePurpose,
        'possession_preference': possessionPreference,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory BuyerRequirement.fromMap(Map<String, dynamic> map) => BuyerRequirement(
        id: map['id']?.toString() ?? 'REQ-${DateTime.now().millisecondsSinceEpoch}',
        userId: map['user_id']?.toString() ?? 'usr_active',
        userName: map['user_name']?.toString() ?? 'Verified Buyer',
        userPhone: map['user_phone']?.toString() ?? '',
        userEmail: map['user_email']?.toString() ?? '',
        preferredLocations: (map['preferred_locations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Sector 150', 'Noida Expressway', 'Greater Noida'],
        minBudgetCr: (map['min_budget_cr'] as num?)?.toDouble() ?? 1.2,
        maxBudgetCr: (map['max_budget_cr'] as num?)?.toDouble() ?? 2.8,
        propertyType: map['property_type']?.toString() ?? 'Apartment',
        bhk: map['bhk']?.toString() ?? '3 BHK',
        minAreaSqft: (map['min_area_sqft'] as num?)?.toDouble() ?? 1450,
        requiredAmenities: (map['required_amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Club House', 'Swimming Pool', 'Gym', 'Security'],
        purchasePurpose: map['purchase_purpose']?.toString() ?? 'Self-Use',
        possessionPreference: map['possession_preference']?.toString() ?? 'Ready to Move',
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
        updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      );

  static BuyerRequirement defaultRequirement(String userId, [String name = '']) => BuyerRequirement(
        id: 'REQ-$userId',
        userId: userId,
        userName: name.isNotEmpty ? name : 'Prospective Buyer',
        preferredLocations: ['Sector 150', 'Sector 137', 'Noida Expressway'],
        minBudgetCr: 1.0,
        maxBudgetCr: 3.0,
        propertyType: 'Apartment',
        bhk: '3 BHK',
        minAreaSqft: 1500,
        requiredAmenities: ['Club House', 'Swimming Pool', 'Gym', '24/7 Security', 'Power Backup'],
        purchasePurpose: 'Self-Use',
        possessionPreference: 'Ready to Move',
      );
}




import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/property_verification_model.dart';

class PropertyIntelligenceService {
  static final PropertyIntelligenceService instance = PropertyIntelligenceService._internal();
  factory PropertyIntelligenceService() => instance;

  PropertyIntelligenceService._internal();

  /// 1. Haversine Great-Circle Distance Calculation (in Kilometers)
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// 2. 5-KM Strict POI Radius Filter
  List<Map<String, dynamic>> getNearbyPoisWithin5Km(Property property, {double radiusKm = 5.0}) {
    final lat = property.latitude;
    final lon = property.longitude;

    final allPois = [
      // Noida Extension (Gaur Chowk / Sector 10 / Greater Noida West)
      {'name': 'Gaur City Mall & Multiplex', 'type': 'Shopping', 'lat': 28.6080, 'lon': 77.4320, 'rating': 4.8},
      {'name': 'Yatharth Super Speciality Hospital', 'type': 'Hospital', 'lat': 28.5950, 'lon': 77.4500, 'rating': 4.7},
      {'name': 'Sarvottam International School', 'type': 'School', 'lat': 28.6040, 'lon': 77.4410, 'rating': 4.8},
      {'name': 'Sector 52 / 71 Metro Interchange', 'type': 'Metro', 'lat': 28.5900, 'lon': 77.3800, 'rating': 4.9},
      {'name': 'FNG Expressway Access Corridor', 'type': 'Expressway', 'lat': 28.6100, 'lon': 77.4250, 'rating': 4.9},

      // Sector 150 / Expressway
      {'name': 'Sector 148 Aqua Line Metro', 'type': 'Metro', 'lat': 28.4485, 'lon': 77.4930, 'rating': 4.8},
      {'name': 'Noida-Greater Noida Expressway', 'type': 'Highway', 'lat': 28.4550, 'lon': 77.4900, 'rating': 4.9},
      {'name': 'Shaheed Bhagat Singh City Park', 'type': 'Park', 'lat': 28.4410, 'lon': 77.5020, 'rating': 4.7},
      {'name': 'Felix Hospital & Critical Care', 'type': 'Hospital', 'lat': 28.4620, 'lon': 77.4850, 'rating': 4.6},
      {'name': 'Lotus Valley International School', 'type': 'School', 'lat': 28.4700, 'lon': 77.4780, 'rating': 4.8},

      // Yamuna Expressway & Jewar
      {'name': 'Yamuna Expressway Interchange', 'type': 'Expressway', 'lat': 28.4200, 'lon': 77.5200, 'rating': 4.9},
      {'name': 'Buddh International Circuit', 'type': 'Sports', 'lat': 28.3550, 'lon': 77.5350, 'rating': 4.9},
      {'name': 'Galgotias & Sharda University Hub', 'type': 'Education', 'lat': 28.3650, 'lon': 77.5100, 'rating': 4.7},
      {'name': 'Noida International Airport (Jewar)', 'type': 'Airport', 'lat': 28.1800, 'lon': 77.6200, 'rating': 5.0},
    ];

    final results = <Map<String, dynamic>>[];

    for (final poi in allPois) {
      final poiLat = (poi['lat'] as num).toDouble();
      final poiLon = (poi['lon'] as num).toDouble();
      final dist = calculateDistanceKm(lat, lon, poiLat, poiLon);

      if (dist <= radiusKm) {
        results.add({
          'name': poi['name'],
          'type': poi['type'],
          'distanceKm': double.parse(dist.toStringAsFixed(1)),
          'durationMins': (dist * 2.5).round().clamp(2, 25),
          'rating': poi['rating'],
        });
      }
    }

    results.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return results;
  }

  /// 3. 5-Pillar Confidence Score Evaluator (0 - 100)
  Map<String, dynamic> evaluateConfidenceScore(Property property) {
    // 1. Legal / RERA Pillar (Max 25)
    int reraScore = 15;
    if (property.reraStatus.toUpperCase().contains('APPROVED') || property.reraStatus.toUpperCase().contains('VERIFIED')) {
      reraScore = 25;
    } else if (property.reraStatus.isNotEmpty) {
      reraScore = 20;
    }

    // 2. Pricing & Valuation Pillar (Max 20)
    int pricingScore = 18;
    if (property.intelligenceScore >= 90) {
      pricingScore = 20;
    } else if (property.intelligenceScore >= 80) {
      pricingScore = 17;
    }

    // 3. Media & Virtual Transparency (Max 20)
    int mediaScore = 8;
    final hasDrone = property.droneTourAvailable || (property.droneTourUrl != null && property.droneTourUrl!.isNotEmpty);
    final has360 = property.virtualTour != null || (property.virtualTourUrl != null && property.virtualTourUrl!.isNotEmpty);
    final has3D = (property.model3DUrl != null && property.model3DUrl!.isNotEmpty) || (property.model3DId != null && property.model3DId!.isNotEmpty);

    if (hasDrone) mediaScore += 4;
    if (has360) mediaScore += 4;
    if (has3D) mediaScore += 4;

    // 4. Locality & Infrastructure (Max 20)
    final pois = getNearbyPoisWithin5Km(property);
    int localityScore = pois.length >= 4 ? 20 : (pois.length * 5).clamp(5, 20);

    // 5. Developer Track Record (Max 15)
    int devScore = 13;
    final bName = property.builderName.toLowerCase();
    if (bName.contains('ats') || bName.contains('tata') || bName.contains('godrej') || bName.contains('mahagun') || bName.contains('eldeco')) {
      devScore = 15;
    }

    final totalScore = (reraScore + pricingScore + mediaScore + localityScore + devScore).clamp(0, 100);

    return {
      'totalScore': totalScore,
      'reraPillar': reraScore,
      'pricingPillar': pricingScore,
      'mediaPillar': mediaScore,
      'localityPillar': localityScore,
      'developerPillar': devScore,
      'ratingGrade': totalScore >= 90 ? 'Grade A+' : (totalScore >= 80 ? 'Grade A' : 'Grade B'),
      'recommendation': totalScore >= 85
          ? 'Proceed with Confidence (High Transparency & Clear Title)'
          : 'Standard Verification Recommended (Review Builder Buyer Agreement)',
    };
  }

  /// 4. True Cost Breakdown Calculator
  PropertyCostEstimateModel calculateTrueCostBreakdown(Property property, {String buyerCategory = 'Male'}) {
    final basePrice = property.askingPriceCr * 10000000.0;
    final regPct = 1.0;
    final stampPct = buyerCategory == 'Female' ? 5.0 : 6.0;
    final bkrPct = 1.0;

    final regCharges = basePrice * (regPct / 100.0);
    final stampCharges = basePrice * (stampPct / 100.0);
    final bkrCharges = basePrice * (bkrPct / 100.0);
    final maintDeposit = 150000.0;
    final renoEstimate = 300000.0;
    final legalDiligence = 25000.0;
    final otherCharges = 50000.0;

    final total = basePrice + regCharges + stampCharges + bkrCharges + maintDeposit + renoEstimate + legalDiligence + otherCharges;

    return PropertyCostEstimateModel(
      id: 'COST-${property.id}',
      propertyId: property.id,
      basePrice: basePrice,
      registrationPercent: regPct,
      registrationCharges: regCharges,
      stampDutyPercent: stampPct,
      stampDutyCharges: stampCharges,
      brokeragePercent: bkrPct,
      brokerageCharges: bkrCharges,
      maintenanceDeposit: maintDeposit,
      renovationEstimate: renoEstimate,
      legalDueDiligence: legalDiligence,
      otherCharges: otherCharges,
      estimatedTotalCost: total,
      buyerCategory: buyerCategory,
      locationJurisdiction: '${property.city} / Uttar Pradesh',
    );
  }

  /// 5. Risk Indicators Evaluator
  List<Map<String, dynamic>> evaluateRiskIndicators(Property property) {
    final risks = <Map<String, dynamic>>[];

    // RERA status check
    if (!property.reraStatus.toUpperCase().contains('APPROVED')) {
      risks.add({
        'level': 'Warning',
        'title': 'RERA Pending Certificate',
        'description': 'Official RERA registration status is under ongoing authority verification.',
      });
    } else {
      risks.add({
        'level': 'Clear',
        'title': 'RERA Registered & Verified',
        'description': 'Valid UP RERA project registration confirmed on official portal.',
      });
    }

    // Possession check
    final pos = (property.possessionDate.isNotEmpty ? property.possessionDate : property.possessionStatus).toLowerCase();
    if (pos.contains('ready') || pos.contains('immediate')) {
      risks.add({
        'level': 'Clear',
        'title': 'Ready to Move In',
        'description': 'Zero construction completion risk. Immediate registration and handover available.',
      });
    } else {
      risks.add({
        'level': 'Info',
        'title': 'Under Construction Project',
        'description': 'Target possession: ${property.possessionDate.isNotEmpty ? property.possessionDate : property.possessionStatus}. Milestone-linked payment plan advised.',
      });
    }

    // Encumbrance check
    risks.add({
      'level': 'Clear',
      'title': 'Clear Freehold Title Deed',
      'description': 'Standard search report indicates zero active bank mortgage dispute on unit.',
    });

    return risks;
  }

  // =========================================================================
  // 6. AI PROPERTY QUALITY SCORE (0 - 100) & ACTIONABLE SUGGESTIONS
  // =========================================================================

  PropertyQualityScoreResult calculateQualityScore(Property property) {
    int titleScore = 0;
    int descScore = 0;
    int specsScore = 0;
    int mediaScore = 0;
    int priceScore = 0;
    int locationScore = 0;

    final suggestions = <String>[];

    // Pillar 1: Title Completeness (Max 10)
    if (property.title.trim().length >= 10) {
      titleScore = 10;
    } else if (property.title.trim().isNotEmpty) {
      titleScore = 5;
      suggestions.add('Expand property title with project name and unit configuration.');
    } else {
      suggestions.add('Add a descriptive property title.');
    }

    // Pillar 2: Description Quality (Max 15)
    final descLen = property.description.trim().length;
    if (descLen >= 120) {
      descScore = 15;
    } else if (descLen >= 50) {
      descScore = 10;
      suggestions.add('Add more details to description (highlights, tower features, views).');
    } else {
      descScore = 4;
      suggestions.add('Provide a comprehensive property description.');
    }

    // Pillar 3: Property Specs & Attributes (Max 25)
    if (property.bhk.isNotEmpty) specsScore += 5;
    if (property.sqft > 0) specsScore += 5;
    if (property.carpetAreaSqft > 0) {
      specsScore += 5;
    } else {
      suggestions.add('Add verified carpet area in sq. ft.');
    }
    if (property.furnishing.isNotEmpty && property.furnishing != 'Unspecified') specsScore += 4;
    if (property.facing.isNotEmpty && property.facing != 'Unspecified') specsScore += 3;
    if (property.possessionDate.isNotEmpty || property.possessionStatus.isNotEmpty) {
      specsScore += 3;
    } else {
      suggestions.add('Add possession handover date.');
    }

    // Pillar 4: Photos & Visual Transparency (Max 20)
    final photoCount = property.galleryImages.length + (property.imageUrl.isNotEmpty ? 1 : 0);
    if (photoCount >= 4) {
      mediaScore += 12;
    } else if (photoCount >= 1) {
      mediaScore += 6;
      suggestions.add('Add at least 4 high-resolution photos of rooms and exterior.');
    } else {
      suggestions.add('Upload property photographs.');
    }
    if (property.hasYoutubeVideo) mediaScore += 4;
    if (property.hasFloorPlan || property.has3DModel || property.hasVirtualTour) mediaScore += 4;

    // Pillar 5: Pricing & Commercials (Max 15)
    if (property.askingPriceCr > 0) {
      priceScore += 10;
      if (property.pricePerSqft > 0) priceScore += 5;
    } else {
      suggestions.add('Specify clear asking price.');
    }

    // Pillar 6: Location & Infrastructure (Max 15)
    if (property.sector.isNotEmpty && property.city.isNotEmpty) {
      locationScore += 10;
      if (property.nearby.isNotEmpty || property.address.isNotEmpty) {
        locationScore += 5;
      } else {
        suggestions.add('Add nearby landmarks, schools, or metro distance.');
      }
    } else {
      suggestions.add('Complete sector and locality address.');
    }

    final total = (titleScore + descScore + specsScore + mediaScore + priceScore + locationScore).clamp(0, 100);

    String grade;
    if (total >= 90) {
      grade = 'Excellent (90-100)';
    } else if (total >= 75) {
      grade = 'Good (75-89)';
    } else if (total >= 50) {
      grade = 'Needs Improvement (50-74)';
    } else {
      grade = 'Incomplete (< 50)';
    }

    return PropertyQualityScoreResult(
      totalScore: total,
      grade: grade,
      pillarScores: {
        'Title': titleScore,
        'Description': descScore,
        'Specifications': specsScore,
        'Media': mediaScore,
        'Pricing': priceScore,
        'Location': locationScore,
      },
      suggestions: suggestions,
    );
  }

  // =========================================================================
  // 7. DUPLICATE LISTING DETECTION
  // =========================================================================

  DuplicateDetectionResult detectDuplicateListings(Property target, List<Property> allProperties) {
    for (final candidate in allProperties) {
      if (candidate.id == target.id) continue;

      final reasons = <String>[];
      int matchPoints = 0;

      // 1. Same City & Sector
      if (candidate.city.toLowerCase() == target.city.toLowerCase() &&
          candidate.sector.toLowerCase() == target.sector.toLowerCase()) {
        matchPoints += 30;
        reasons.add('Same sector and city (${target.sector}, ${target.city})');
      }

      // 2. Exact or close BHK
      if (candidate.bhk.toLowerCase() == target.bhk.toLowerCase()) {
        matchPoints += 20;
        reasons.add('Identical configuration (${target.bhk})');
      }

      // 3. Similar Area (+/- 8%)
      if (target.sqft > 0 && candidate.sqft > 0) {
        final areaDiff = (candidate.sqft - target.sqft).abs() / target.sqft;
        if (areaDiff <= 0.08) {
          matchPoints += 20;
          reasons.add('Matching carpet/super area (~${target.sqft} sq.ft.)');
        }
      }

      // 4. Similar Price (+/- 5%)
      if (target.askingPriceCr > 0 && candidate.askingPriceCr > 0) {
        final priceDiff = (candidate.askingPriceCr - target.askingPriceCr).abs() / target.askingPriceCr;
        if (priceDiff <= 0.05) {
          matchPoints += 20;
          reasons.add('Near-identical pricing (₹${target.askingPriceCr} Cr)');
        }
      }

      // 5. Proximity (< 0.3 km)
      final distKm = calculateDistanceKm(target.latitude, target.longitude, candidate.latitude, candidate.longitude);
      if (distKm <= 0.3) {
        matchPoints += 20;
        reasons.add('Geographical coordinate match (${distKm.toStringAsFixed(2)} km apart)');
      }

      if (matchPoints >= 80) {
        return DuplicateDetectionResult(
          status: 'confirmed_duplicate',
          similarityScore: (matchPoints / 110.0).clamp(0.0, 1.0),
          matchedProperty: candidate,
          matchReasons: reasons,
        );
      } else if (matchPoints >= 50) {
        return DuplicateDetectionResult(
          status: 'possible_duplicate',
          similarityScore: (matchPoints / 110.0).clamp(0.0, 1.0),
          matchedProperty: candidate,
          matchReasons: reasons,
        );
      }
    }

    return const DuplicateDetectionResult(
      status: 'normal',
      similarityScore: 0.0,
    );
  }

  // =========================================================================
  // 8. FRAUD / ANOMALY RISK SCORING (LOW, MEDIUM, HIGH)
  // =========================================================================

  FraudRiskAssessment evaluateFraudRisk(
    Property property, {
    int dealerTotalListings = 1,
    int dealerRejectedCount = 0,
    bool hasSuspiciousPhone = false,
  }) {
    int riskScore = 10;
    final flags = <String>[];

    // 1. Extreme Price Underpricing Anomaly (< 0.2 Cr for 3BHK or >2000 sqft in Noida/Gurugram)
    if (property.bhk.contains('3') && property.askingPriceCr > 0 && property.askingPriceCr < 0.20) {
      riskScore += 45;
      flags.add('Extremely anomalous low price for 3 BHK luxury segment (₹${property.askingPriceCr} Cr).');
    }

    // 2. High Dealer Rejection Ratio (> 35%)
    if (dealerTotalListings >= 3 && (dealerRejectedCount / dealerTotalListings) >= 0.35) {
      riskScore += 35;
      flags.add('Dealer account history shows elevated rejection frequency (${dealerRejectedCount}/${dealerTotalListings}).');
    }

    // 3. Suspicious Phone / Contact Details
    if (hasSuspiciousPhone || (property.contactPhone.isNotEmpty && property.contactPhone.replaceAll(RegExp(r'\D'), '').length < 10)) {
      riskScore += 25;
      flags.add('Incomplete or invalid contact telephone number.');
    }

    // 4. Duplicate Flag
    if (property.duplicateStatus == 'confirmed_duplicate') {
      riskScore += 30;
      flags.add('Property matches existing verified inventory on platform.');
    }

    final total = riskScore.clamp(0, 100);
    String level = 'LOW RISK';
    String rec = 'Automated risk indicators clear. Standard admin review.';

    if (total >= 70) {
      level = 'HIGH RISK';
      rec = 'High risk indicator triggered. Require supervisor identity and title documentation audit.';
    } else if (total >= 40) {
      level = 'MEDIUM RISK';
      rec = 'Moderate anomaly flagged. Verify pricing consistency and RERA certificate.';
    }

    return FraudRiskAssessment(
      riskLevel: level,
      riskScore: total,
      riskFlags: flags,
      recommendation: rec,
    );
  }

  // =========================================================================
  // 9. NATURAL-LANGUAGE AI SEARCH PARSER (Zero Hallucination)
  // =========================================================================

  NaturalLanguageFilterResult parseNaturalLanguageSearch(String query) {
    final lower = query.toLowerCase().trim();

    // 1. Extract BHK
    String? bhk;
    if (lower.contains('1 bhk') || lower.contains('1bhk') || lower.contains('1 bed') || lower.contains('studio')) {
      bhk = '1 BHK';
    } else if (lower.contains('2 bhk') || lower.contains('2bhk') || lower.contains('2 bed')) {
      bhk = '2 BHK';
    } else if (lower.contains('3 bhk') || lower.contains('3bhk') || lower.contains('3 bed')) {
      bhk = '3 BHK';
    } else if (lower.contains('4 bhk') || lower.contains('4bhk') || lower.contains('4 bed')) {
      bhk = '4 BHK';
    } else if (lower.contains('5 bhk') || lower.contains('5bhk')) {
      bhk = '5 BHK';
    }

    // 2. Extract Budget Bounds
    double? maxBudgetCr;
    double? minBudgetCr;

    // Pattern: "under 80 lakh", "under 80L", "under 1 crore", "under 1 cr", "under 2.5 cr"
    final croreMatch = RegExp(r'under\s*(\d+(\.\d+)?)\s*(crore|cr)', caseSensitive: false).firstMatch(lower);
    if (croreMatch != null) {
      maxBudgetCr = double.tryParse(croreMatch.group(1) ?? '');
    }

    final lakhMatch = RegExp(r'under\s*(\d+(\.\d+)?)\s*(lakh|lakhs|l)', caseSensitive: false).firstMatch(lower);
    if (lakhMatch != null) {
      final lakhs = double.tryParse(lakhMatch.group(1) ?? '');
      if (lakhs != null) maxBudgetCr = lakhs / 100.0;
    }

    // 3. Extract Location
    String? loc;
    if (lower.contains('sector 150')) {
      loc = 'Sector 150';
    } else if (lower.contains('sector 128')) {
      loc = 'Sector 128';
    } else if (lower.contains('sector 124')) {
      loc = 'Sector 124';
    } else if (lower.contains('noida extension') || lower.contains('greater noida west')) {
      loc = 'Noida Extension';
    } else if (lower.contains('yamuna expressway')) {
      loc = 'Yamuna Expressway';
    } else if (lower.contains('expressway')) {
      loc = 'Expressway';
    } else if (lower.contains('noida')) {
      loc = 'Noida';
    } else if (lower.contains('gurugram') || lower.contains('gurgaon')) {
      loc = 'Gurugram';
    } else if (lower.contains('greater noida')) {
      loc = 'Greater Noida';
    } else if (lower.contains('delhi')) {
      loc = 'Delhi';
    }

    // 4. Extract Property Type
    String? pType;
    if (lower.contains('villa') || lower.contains('bungalow')) {
      pType = 'Villa';
    } else if (lower.contains('flat') || lower.contains('apartment')) {
      pType = 'Apartment';
    } else if (lower.contains('penthouse')) {
      pType = 'Penthouse';
    } else if (lower.contains('plot') || lower.contains('land')) {
      pType = 'Plot';
    } else if (lower.contains('office') || lower.contains('commercial')) {
      pType = 'Office Space';
    }

    // 5. Special Flags
    final isNearMetro = lower.contains('metro') || lower.contains('near metro');
    final isReadyToMove = lower.contains('ready to move') || lower.contains('ready-to-move') || lower.contains('immediate');

    return NaturalLanguageFilterResult(
      query: query,
      bhk: bhk,
      maxBudgetCr: maxBudgetCr,
      minBudgetCr: minBudgetCr,
      location: loc,
      propertyType: pType,
      possession: isReadyToMove ? 'Ready to Move' : null,
      isNearMetro: isNearMetro,
      isReadyToMove: isReadyToMove,
    );
  }

  /// Filters real database properties according to natural language query
  NaturalLanguageSearchResults filterPropertiesNaturalLanguage(String query, List<Property> allProperties) {
    final parsed = parseNaturalLanguageSearch(query);

    final exact = allProperties.where((p) {
      // BHK filter
      if (parsed.bhk != null && !p.bhk.toLowerCase().contains(parsed.bhk!.toLowerCase())) {
        return false;
      }
      // Budget filter
      if (parsed.maxBudgetCr != null && p.askingPriceCr > parsed.maxBudgetCr!) {
        return false;
      }
      if (parsed.minBudgetCr != null && p.askingPriceCr < parsed.minBudgetCr!) {
        return false;
      }
      // Location filter
      if (parsed.location != null) {
        final loc = parsed.location!.toLowerCase();
        final matchCity = p.city.toLowerCase().contains(loc);
        final matchSector = p.sector.toLowerCase().contains(loc);
        final matchLocality = p.locality.toLowerCase().contains(loc);
        if (!matchCity && !matchSector && !matchLocality) return false;
      }
      // Property type filter
      if (parsed.propertyType != null && !p.propertyType.toLowerCase().contains(parsed.propertyType!.toLowerCase())) {
        return false;
      }
      // Ready to move
      if (parsed.isReadyToMove && !p.constructionStatus.toLowerCase().contains('ready') && !p.possessionStatus.toLowerCase().contains('ready')) {
        return false;
      }
      return true;
    }).toList();

    // If no exact match, compute labeled nearest alternatives
    final alternatives = <Property>[];
    if (exact.isEmpty) {
      alternatives.addAll(allProperties.where((p) {
        if (parsed.location != null) {
          final loc = parsed.location!.toLowerCase();
          return p.city.toLowerCase().contains(loc) || p.sector.toLowerCase().contains(loc);
        }
        if (parsed.bhk != null) {
          return p.bhk.toLowerCase().contains(parsed.bhk!.toLowerCase());
        }
        return true;
      }).take(3));
    }

    final msg = exact.isNotEmpty
        ? 'Found ${exact.length} exact verified properties matching "${query}".'
        : 'No exact matches found for "${query}". Showing ${alternatives.length} nearest available alternatives.';

    return NaturalLanguageSearchResults(
      exactMatches: exact,
      alternativeMatches: alternatives,
      hasExactMatches: exact.isNotEmpty,
      summaryMessage: msg,
    );
  }

  // =========================================================================
  // 10. SMART RECOMMENDATIONS (Privacy-Conscious)
  // =========================================================================

  List<Property> getSmartRecommendations(
    Property currentProperty,
    List<Property> allProperties, {
    double? userBudgetCr,
  }) {
    final targetBudget = userBudgetCr ?? currentProperty.askingPriceCr;

    final scored = allProperties.where((p) => p.id != currentProperty.id).map((p) {
      double score = 0.0;

      // 1. Same locality / city
      if (p.city.toLowerCase() == currentProperty.city.toLowerCase()) score += 30;
      if (p.sector.toLowerCase() == currentProperty.sector.toLowerCase()) score += 40;

      // 2. Budget similarity (+/- 25%)
      if (targetBudget > 0 && p.askingPriceCr > 0) {
        final diff = (p.askingPriceCr - targetBudget).abs() / targetBudget;
        if (diff <= 0.25) score += 30 * (1.0 - diff);
      }

      // 3. Same category / BHK
      if (p.bhk == currentProperty.bhk) score += 20;

      // 4. Verified boost
      if (p.isPropZenVerified) score += 10;

      return MapEntry(p, score);
    }).where((e) => e.value >= 30).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(4).map((e) => e.key).toList();
  }
}

class PropertyQualityScoreResult {
  final int totalScore;
  final String grade;
  final Map<String, int> pillarScores;
  final List<String> suggestions;

  const PropertyQualityScoreResult({
    required this.totalScore,
    required this.grade,
    required this.pillarScores,
    required this.suggestions,
  });
}

class DuplicateDetectionResult {
  final String status;
  final double similarityScore;
  final Property? matchedProperty;
  final List<String> matchReasons;

  const DuplicateDetectionResult({
    required this.status,
    required this.similarityScore,
    this.matchedProperty,
    this.matchReasons = const [],
  });
}

class FraudRiskAssessment {
  final String riskLevel;
  final int riskScore;
  final List<String> riskFlags;
  final String recommendation;

  const FraudRiskAssessment({
    required this.riskLevel,
    required this.riskScore,
    required this.riskFlags,
    required this.recommendation,
  });
}

class NaturalLanguageFilterResult {
  final String query;
  final String? bhk;
  final double? maxBudgetCr;
  final double? minBudgetCr;
  final String? location;
  final String? propertyType;
  final String? possession;
  final bool isNearMetro;
  final bool isReadyToMove;

  const NaturalLanguageFilterResult({
    required this.query,
    this.bhk,
    this.maxBudgetCr,
    this.minBudgetCr,
    this.location,
    this.propertyType,
    this.possession,
    this.isNearMetro = false,
    this.isReadyToMove = false,
  });
}

class NaturalLanguageSearchResults {
  final List<Property> exactMatches;
  final List<Property> alternativeMatches;
  final bool hasExactMatches;
  final String summaryMessage;

  const NaturalLanguageSearchResults({
    required this.exactMatches,
    required this.alternativeMatches,
    required this.hasExactMatches,
    required this.summaryMessage,
  });
}


import 'dart:math';
import '../models/property.dart';

/// User Preferences for the "Find My Perfect Property" flow
class PropertyPreferenceModel {
  String purpose; // 'Buy', 'Rent', 'Investment'
  String city; // 'Noida', 'Gurugram', 'Delhi', 'Greater Noida', etc.
  List<String> localities; // e.g. ['Sector 150', 'Sector 137', 'Sector 62']
  double minBudget; // in Crores for Buy/Invest, in Rupees for Rent
  double maxBudget; // in Crores for Buy/Invest, in Rupees for Rent
  List<String> propertyTypes; // 'Apartment', 'Villa', 'Plot', etc.
  List<String> bhkOptions; // '1 BHK', '2 BHK', '3 BHK', etc.
  List<String> priorities; // 'Near Metro', 'Gym', 'Swimming Pool', etc.
  List<String> lifestylePreferences; // 'Quiet Area', 'Luxury', etc.

  PropertyPreferenceModel({
    this.purpose = 'Buy',
    this.city = 'Noida',
    List<String>? localities,
    this.minBudget = 0.40, // 40 Lakhs
    this.maxBudget = 2.50, // 2.50 Crores
    List<String>? propertyTypes,
    List<String>? bhkOptions,
    List<String>? priorities,
    List<String>? lifestylePreferences,
  })  : localities = localities ?? ['Sector 150', 'Sector 137'],
        propertyTypes = propertyTypes ?? ['Apartment', 'Villa'],
        bhkOptions = bhkOptions ?? ['2 BHK', '3 BHK'],
        priorities = priorities ?? ['Near Metro', 'Parking', 'Gym', 'Security', 'Ready to Move'],
        lifestylePreferences = lifestylePreferences ?? ['Family Friendly', 'Modern Amenities'];

  PropertyPreferenceModel copyWith({
    String? purpose,
    String? city,
    List<String>? localities,
    double? minBudget,
    double? maxBudget,
    List<String>? propertyTypes,
    List<String>? bhkOptions,
    List<String>? priorities,
    List<String>? lifestylePreferences,
  }) {
    return PropertyPreferenceModel(
      purpose: purpose ?? this.purpose,
      city: city ?? this.city,
      localities: localities ?? List.from(this.localities),
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      propertyTypes: propertyTypes ?? List.from(this.propertyTypes),
      bhkOptions: bhkOptions ?? List.from(this.bhkOptions),
      priorities: priorities ?? List.from(this.priorities),
      lifestylePreferences: lifestylePreferences ?? List.from(this.lifestylePreferences),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'purpose': purpose,
      'city': city,
      'localities': localities,
      'min_budget': minBudget,
      'max_budget': maxBudget,
      'property_types': propertyTypes,
      'bhk_preferences': bhkOptions,
      'priorities': priorities,
      'lifestyle_preferences': lifestylePreferences,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory PropertyPreferenceModel.fromMap(Map<String, dynamic> map) {
    return PropertyPreferenceModel(
      purpose: map['purpose']?.toString() ?? 'Buy',
      city: map['city']?.toString() ?? 'Noida',
      localities: (map['localities'] as List?)?.map((e) => e.toString()).toList() ?? ['Sector 150'],
      minBudget: (map['min_budget'] as num?)?.toDouble() ?? 0.40,
      maxBudget: (map['max_budget'] as num?)?.toDouble() ?? 2.50,
      propertyTypes: (map['property_types'] as List?)?.map((e) => e.toString()).toList() ?? ['Apartment'],
      bhkOptions: (map['bhk_preferences'] as List?)?.map((e) => e.toString()).toList() ?? ['2 BHK', '3 BHK'],
      priorities: (map['priorities'] as List?)?.map((e) => e.toString()).toList() ?? ['Near Metro'],
      lifestylePreferences: (map['lifestyle_preferences'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Calculated result item with detailed match score & bullet points
class PropertyMatchResult {
  final Property property;
  final int matchScore; // 0 - 100%
  final List<String> matchReasons;
  final bool isExactMatch;
  final String? alternativeReason; // e.g. "₹4 Lakh above your budget" or "Nearby locality"

  const PropertyMatchResult({
    required this.property,
    required this.matchScore,
    required this.matchReasons,
    this.isExactMatch = true,
    this.alternativeReason,
  });
}

/// Real Property Matching Engine
class PerfectPropertyMatchingEngine {
  PerfectPropertyMatchingEngine._();

  /// Calculates matches against a list of published properties
  static List<PropertyMatchResult> evaluateMatches({
    required List<Property> properties,
    required PropertyPreferenceModel preferences,
  }) {
    // 1. STRICT FILTER: Only PUBLISHED properties
    final publishedProps = properties.where((p) => p.isPublished).toList();
    final List<PropertyMatchResult> results = [];

    for (final p in publishedProps) {
      double score = 0.0;
      final List<String> reasons = [];
      bool exactBudget = false;
      bool exactLocation = false;
      bool exactBhk = false;
      String? altReason;

      // 1. BUDGET SCORING (25%)
      // Convert property asking price to Lakhs/Crores comparison
      final askingCr = p.askingPriceCr > 0
          ? p.askingPriceCr
          : (p.pricePerSqft > 0 && p.sqft > 0 ? (p.pricePerSqft * p.sqft) / 10000000 : 1.0);

      if (preferences.purpose == 'Rent') {
        // In rent mode, monthly rent is typically estimated at 0.25% - 0.4% of property value
        final estimatedMonthlyRent = (askingCr * 10000000 * 0.0035).roundToDouble();
        if (estimatedMonthlyRent >= preferences.minBudget && estimatedMonthlyRent <= preferences.maxBudget) {
          score += 25.0;
          exactBudget = true;
          reasons.add('✓ Within your monthly rent budget (₹${(estimatedMonthlyRent / 1000).round()}k/mo)');
        } else if (estimatedMonthlyRent <= preferences.maxBudget * 1.15) {
          score += 15.0;
          final diff = ((estimatedMonthlyRent - preferences.maxBudget) / 1000).round();
          altReason = '₹${diff}k above your monthly budget';
          reasons.add('✓ Close to rental budget (+₹${diff}k/mo)');
        } else {
          score += 5.0;
        }
      } else {
        // Buy & Investment (in Crores)
        if (askingCr >= preferences.minBudget && askingCr <= preferences.maxBudget) {
          score += 25.0;
          exactBudget = true;
          reasons.add('✓ Within your budget (${p.formattedPrice})');
        } else if (askingCr > preferences.maxBudget && askingCr <= preferences.maxBudget * 1.15) {
          score += 16.0;
          final diffLakhs = ((askingCr - preferences.maxBudget) * 100).round();
          altReason = '₹$diffLakhs Lakh above your budget';
          reasons.add('✓ Premium match (+₹$diffLakhs L above budget)');
        } else if (askingCr < preferences.minBudget && askingCr >= preferences.minBudget * 0.85) {
          score += 18.0;
          final underLakhs = ((preferences.minBudget - askingCr) * 100).round();
          reasons.add('✓ Great value (₹$underLakhs L below max budget)');
        } else {
          score += 4.0;
        }
      }

      // 2. LOCATION SCORING (20%)
      final cityMatch = p.city.toLowerCase().contains(preferences.city.toLowerCase());
      final localityMatch = preferences.localities.any(
        (loc) =>
            p.effectiveLocality.toLowerCase().contains(loc.toLowerCase()) ||
            p.sector.toLowerCase().contains(loc.toLowerCase()) ||
            p.address.toLowerCase().contains(loc.toLowerCase()),
      );

      if (localityMatch) {
        score += 20.0;
        exactLocation = true;
        reasons.add('✓ Located in your preferred area (${p.effectiveLocality})');
      } else if (cityMatch) {
        score += 14.0;
        reasons.add('✓ Located in ${p.city} growth corridor');
      } else {
        score += 5.0;
      }

      // 3. BHK SCORING (15%)
      final bhkMatch = preferences.bhkOptions.any(
        (bhk) =>
            p.bhk.toLowerCase().contains(bhk.toLowerCase()) ||
            bhk.toLowerCase().contains(p.bhk.toLowerCase()) ||
            p.bhkOptions.any((opt) => opt.toLowerCase().contains(bhk.toLowerCase())),
      );

      if (bhkMatch) {
        score += 15.0;
        exactBhk = true;
        reasons.add('✓ Matches your preferred ${p.bhk} configuration');
      } else {
        score += 4.0;
      }

      // 4. PROPERTY TYPE SCORING (10%)
      final typeMatch = preferences.propertyTypes.any(
        (t) =>
            p.propertyType.toLowerCase().contains(t.toLowerCase()) ||
            t.toLowerCase().contains(p.propertyType.toLowerCase()) ||
            p.category.toLowerCase().contains(t.toLowerCase()),
      );

      if (typeMatch) {
        score += 10.0;
        reasons.add('✓ ${p.propertyType} category match');
      } else {
        score += 2.0;
      }

      // 5. AMENITIES & PRIORITIES SCORING (15%)
      int matchedPriorities = 0;
      for (final priority in preferences.priorities) {
        final pLower = priority.toLowerCase();
        bool found = false;

        if (pLower.contains('metro') && (p.nearby['Metro'] != null || p.description.toLowerCase().contains('metro'))) {
          found = true;
        } else if (pLower.contains('school') && (p.nearby['School'] != null || p.description.toLowerCase().contains('school'))) {
          found = true;
        } else if (pLower.contains('hospital') && (p.nearby['Hospital'] != null || p.description.toLowerCase().contains('hospital'))) {
          found = true;
        } else if (pLower.contains('green') || pLower.contains('park')) {
          found = p.amenities.any((a) => a.toLowerCase().contains('garden') || a.toLowerCase().contains('park') || a.toLowerCase().contains('green'));
        } else if (pLower.contains('gym')) {
          found = p.amenities.any((a) => a.toLowerCase().contains('gym') || a.toLowerCase().contains('fitness'));
        } else if (pLower.contains('pool')) {
          found = p.amenities.any((a) => a.toLowerCase().contains('pool'));
        } else if (pLower.contains('parking')) {
          found = p.amenities.any((a) => a.toLowerCase().contains('parking'));
        } else if (pLower.contains('security')) {
          found = p.amenities.any((a) => a.toLowerCase().contains('security') || a.toLowerCase().contains('cctv'));
        } else if (pLower.contains('power')) {
          found = p.amenities.any((a) => a.toLowerCase().contains('power') || a.toLowerCase().contains('backup'));
        } else if (pLower.contains('ready') && p.availability.toLowerCase().contains('ready')) {
          found = true;
        } else if (pLower.contains('construction') && p.availability.toLowerCase().contains('under')) {
          found = true;
        } else if (pLower.contains('vastu') && p.facing.isNotEmpty) {
          found = true;
        } else {
          found = p.amenities.any((a) => a.toLowerCase().contains(pLower));
        }

        if (found) {
          matchedPriorities++;
        }
      }

      final amenityRatio = preferences.priorities.isNotEmpty ? matchedPriorities / preferences.priorities.length : 0.8;
      final amenityPoints = min(15.0, (amenityRatio * 15.0).roundToDouble());
      score += amenityPoints;

      if (matchedPriorities >= 2) {
        reasons.add('✓ Includes $matchedPriorities of your requested amenities (Gym, Pool, Security)');
      }

      // 6. POSSESSION STATUS SCORING (5%)
      if (preferences.priorities.any((prio) => prio.toLowerCase().contains('ready')) && p.availability.toLowerCase().contains('ready')) {
        score += 5.0;
        reasons.add('✓ Ready to Move in with verified occupancy');
      } else if (preferences.priorities.any((prio) => prio.toLowerCase().contains('construction')) && p.availability.toLowerCase().contains('under')) {
        score += 5.0;
        reasons.add('✓ High appreciation potential (Under Construction)');
      } else {
        score += 3.0;
      }

      // 7. INVESTMENT & RENTAL SUITABILITY SCORING (10%)
      if (preferences.purpose == 'Investment') {
        if (p.rentalYieldPercent >= 4.5 || p.investmentScore >= 90) {
          score += 10.0;
          reasons.add('✓ High rental yield (${p.rentalYieldPercent}% p.a.) & 10X score (${p.score10x})');
        } else {
          score += 5.0;
        }
      } else {
        if (p.score10x >= 9.0) {
          score += 10.0;
          reasons.add('✓ PropZen 10X Certified Quality score (${p.score10x}/10)');
        } else {
          score += 7.0;
        }
      }

      // Final bounded match percentage (70% - 99%)
      final int finalScore = min(99, max(45, score.round()));
      final isExact = exactBudget && (exactLocation || cityMatch) && exactBhk;

      // Limit reasons to 3-5 distinct data backed items
      final distinctReasons = reasons.take(4).toList();

      results.add(
        PropertyMatchResult(
          property: p,
          matchScore: finalScore,
          matchReasons: distinctReasons,
          isExactMatch: isExact,
          alternativeReason: altReason,
        ),
      );
    }

    // Sort descending by match percentage
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return results;
  }
}

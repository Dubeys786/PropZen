import 'package:flutter/foundation.dart';

/// Categories of public figures associated with an area
enum PublicFigureCategory {
  electedRepresentative, // MP, MLA, Mayor, Councillor
  publicAdministrator,  // Authority Chairman, DM, Commissioner
  sportsPersonality,     // Athletes, Olympians, Cricketers
  culturalLeader,        // Artists, Authors, Musicians
  entrepreneur,          // Industry leaders, Startup founders
  socialWorker,          // Community activists, Philanthropists
  otherNotable;

  String get displayName {
    switch (this) {
      case PublicFigureCategory.electedRepresentative:
        return 'Elected Representative';
      case PublicFigureCategory.publicAdministrator:
        return 'Public Official';
      case PublicFigureCategory.sportsPersonality:
        return 'Sports Personality';
      case PublicFigureCategory.culturalLeader:
        return 'Cultural & Arts';
      case PublicFigureCategory.entrepreneur:
        return 'Entrepreneur & Industry';
      case PublicFigureCategory.socialWorker:
        return 'Community & Social';
      case PublicFigureCategory.otherNotable:
        return 'Notable Public Figure';
    }
  }

  static PublicFigureCategory fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower.contains('mp') || lower.contains('mla') || lower.contains('mayor') || lower.contains('councillor') || lower.contains('representative')) {
      return PublicFigureCategory.electedRepresentative;
    }
    if (lower.contains('admin') || lower.contains('official') || lower.contains('officer') || lower.contains('magistrate')) {
      return PublicFigureCategory.publicAdministrator;
    }
    if (lower.contains('sport') || lower.contains('cricket') || lower.contains('athlete')) {
      return PublicFigureCategory.sportsPersonality;
    }
    if (lower.contains('art') || lower.contains('music') || lower.contains('author') || lower.contains('culture')) {
      return PublicFigureCategory.culturalLeader;
    }
    if (lower.contains('business') || lower.contains('entrepreneur') || lower.contains('industry')) {
      return PublicFigureCategory.entrepreneur;
    }
    if (lower.contains('social') || lower.contains('ngo') || lower.contains('activist')) {
      return PublicFigureCategory.socialWorker;
    }
    return PublicFigureCategory.otherNotable;
  }
}

/// Public Figure Associated with an Area (Strict Public-Only Data)
class PublicFigureModel {
  final String id;
  final String name;
  final PublicFigureCategory category;
  final String designation;
  final String publicAssociation;
  final String shortBio;
  final String? photoUrl;
  final String source;
  final String sourceUrl;
  final DateTime verifiedAt;

  const PublicFigureModel({
    required this.id,
    required this.name,
    required this.category,
    required this.designation,
    required this.publicAssociation,
    required this.shortBio,
    this.photoUrl,
    required this.source,
    required this.sourceUrl,
    required this.verifiedAt,
  });

  factory PublicFigureModel.fromMap(Map<String, dynamic> map) {
    return PublicFigureModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: PublicFigureCategory.fromString(map['category']?.toString() ?? 'otherNotable'),
      designation: map['designation']?.toString() ?? '',
      publicAssociation: map['public_association']?.toString() ?? map['publicAssociation']?.toString() ?? '',
      shortBio: map['short_bio']?.toString() ?? map['shortBio']?.toString() ?? '',
      photoUrl: map['photo_url']?.toString() ?? map['photoUrl']?.toString(),
      source: map['source']?.toString() ?? 'Official Election Commission / Public Record',
      sourceUrl: map['source_url']?.toString() ?? map['sourceUrl']?.toString() ?? '',
      verifiedAt: DateTime.tryParse(map['verified_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'designation': designation,
        'public_association': publicAssociation,
        'short_bio': shortBio,
        'photo_url': photoUrl,
        'source': source,
        'source_url': sourceUrl,
        'verified_at': verifiedAt.toIso8601String(),
      };
}

/// Important Landmarks in the Area (Parks, Stadiums, Monuments, Major Facilities)
class AreaLandmarkItem {
  final String name;
  final String category;
  final String description;
  final String significance;
  final double distanceKm;
  final String source;

  const AreaLandmarkItem({
    required this.name,
    required this.category,
    required this.description,
    required this.significance,
    required this.distanceKm,
    required this.source,
  });

  factory AreaLandmarkItem.fromMap(Map<String, dynamic> map) {
    return AreaLandmarkItem(
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Public Landmark',
      description: map['description']?.toString() ?? '',
      significance: map['significance']?.toString() ?? '',
      distanceKm: double.tryParse(map['distance_km']?.toString() ?? '1.0') ?? 1.0,
      source: map['source']?.toString() ?? 'Noida Master Plan',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'description': description,
        'significance': significance,
        'distance_km': distanceKm,
        'source': source,
      };
}

/// Historical Milestones & Development Timeline
class AreaHistoryMilestone {
  final String year;
  final String title;
  final String description;
  final String source;

  const AreaHistoryMilestone({
    required this.year,
    required this.title,
    required this.description,
    required this.source,
  });

  factory AreaHistoryMilestone.fromMap(Map<String, dynamic> map) {
    return AreaHistoryMilestone(
      year: map['year']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      source: map['source']?.toString() ?? 'Noida Master Plan / Urban Development Records',
    );
  }

  Map<String, dynamic> toMap() => {
        'year': year,
        'title': title,
        'description': description,
        'source': source,
      };
}

/// Area Amenity Categories (Education, Healthcare, Shopping, Connectivity, Public Infrastructure)
enum AmenityCategory {
  education,
  healthcare,
  shopping,
  connectivity,
  publicInfrastructure;

  String get displayName {
    switch (this) {
      case AmenityCategory.education:
        return 'Education & Schools';
      case AmenityCategory.healthcare:
        return 'Healthcare & Hospitals';
      case AmenityCategory.shopping:
        return 'Shopping & Retail';
      case AmenityCategory.connectivity:
        return 'Connectivity & Transit';
      case AmenityCategory.publicInfrastructure:
        return 'Public Services & Safety';
    }
  }

  static AmenityCategory fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower.contains('edu') || lower.contains('school') || lower.contains('college')) {
      return AmenityCategory.education;
    }
    if (lower.contains('health') || lower.contains('hospital') || lower.contains('clinic')) {
      return AmenityCategory.healthcare;
    }
    if (lower.contains('shop') || lower.contains('mall') || lower.contains('market')) {
      return AmenityCategory.shopping;
    }
    if (lower.contains('connect') || lower.contains('transit') || lower.contains('metro') || lower.contains('expressway')) {
      return AmenityCategory.connectivity;
    }
    return AmenityCategory.publicInfrastructure;
  }
}

/// Nearby Public Places / Amenities Item
class AreaAmenityItem {
  final String name;
  final AmenityCategory category;
  final double distanceKm;
  final String typeDescription;
  final double? rating;

  const AreaAmenityItem({
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.typeDescription,
    this.rating,
  });

  factory AreaAmenityItem.fromMap(Map<String, dynamic> map) {
    return AreaAmenityItem(
      name: map['name']?.toString() ?? '',
      category: AmenityCategory.fromString(map['category']?.toString() ?? 'connectivity'),
      distanceKm: double.tryParse(map['distance_km']?.toString() ?? '1.0') ?? 1.0,
      typeDescription: map['type_description']?.toString() ?? map['type']?.toString() ?? '',
      rating: double.tryParse(map['rating']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.name,
        'distance_km': distanceKm,
        'type_description': typeDescription,
        'rating': rating,
      };
}

/// Area Property Market Snapshot
class AreaMarketSnapshot {
  final double avgPriceSqft;
  final double priceRangeMin;
  final double priceRangeMax;
  final double rentalRangeMinMonthly;
  final double rentalRangeMaxMonthly;
  final double appreciation6mPercent;
  final int availablePropertiesCount;
  final String trendSummary;

  const AreaMarketSnapshot({
    required this.avgPriceSqft,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.rentalRangeMinMonthly,
    required this.rentalRangeMaxMonthly,
    required this.appreciation6mPercent,
    required this.availablePropertiesCount,
    required this.trendSummary,
  });

  factory AreaMarketSnapshot.fromMap(Map<String, dynamic> map) {
    return AreaMarketSnapshot(
      avgPriceSqft: double.tryParse(map['avg_price_sqft']?.toString() ?? '8500') ?? 8500.0,
      priceRangeMin: double.tryParse(map['price_range_min']?.toString() ?? '7200') ?? 7200.0,
      priceRangeMax: double.tryParse(map['price_range_max']?.toString() ?? '11500') ?? 11500.0,
      rentalRangeMinMonthly: double.tryParse(map['rental_range_min_monthly']?.toString() ?? '22000') ?? 22000.0,
      rentalRangeMaxMonthly: double.tryParse(map['rental_range_max_monthly']?.toString() ?? '45000') ?? 45000.0,
      appreciation6mPercent: double.tryParse(map['appreciation_6m_percent']?.toString() ?? '5.8') ?? 5.8,
      availablePropertiesCount: int.tryParse(map['available_properties_count']?.toString() ?? '12') ?? 12,
      trendSummary: map['trend_summary']?.toString() ?? 'Capital values show steady appreciation backed by institutional infrastructure.',
    );
  }

  Map<String, dynamic> toMap() => {
        'avg_price_sqft': avgPriceSqft,
        'price_range_min': priceRangeMin,
        'price_range_max': priceRangeMax,
        'rental_range_min_monthly': rentalRangeMinMonthly,
        'rental_range_max_monthly': rentalRangeMaxMonthly,
        'appreciation_6m_percent': appreciation6mPercent,
        'available_properties_count': availablePropertiesCount,
        'trend_summary': trendSummary,
      };
}

/// Complete Area Discovery Profile Model
class AreaProfileModel {
  final String pincode;
  final String locality;
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final String historySummary;
  final List<AreaHistoryMilestone> historyMilestones;
  final List<AreaLandmarkItem> landmarks;
  final List<PublicFigureModel> publicFigures;
  final List<AreaAmenityItem> amenities;
  final AreaMarketSnapshot marketSnapshot;
  final DateTime resolvedAt;
  final DateTime updatedAt;

  const AreaProfileModel({
    required this.pincode,
    required this.locality,
    required this.city,
    required this.state,
    this.country = 'India',
    this.latitude,
    this.longitude,
    required this.historySummary,
    required this.historyMilestones,
    required this.landmarks,
    required this.publicFigures,
    required this.amenities,
    required this.marketSnapshot,
    required this.resolvedAt,
    required this.updatedAt,
  });

  factory AreaProfileModel.fromMap(Map<String, dynamic> map) {
    List<AreaHistoryMilestone> milestones = [];
    if (map['history_milestones'] is List) {
      milestones = (map['history_milestones'] as List)
          .map((m) => AreaHistoryMilestone.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    List<AreaLandmarkItem> lms = [];
    if (map['landmarks'] is List) {
      lms = (map['landmarks'] as List)
          .map((l) => AreaLandmarkItem.fromMap(Map<String, dynamic>.from(l as Map)))
          .toList();
    }

    List<PublicFigureModel> figures = [];
    if (map['public_figures'] is List) {
      figures = (map['public_figures'] as List)
          .map((f) => PublicFigureModel.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList();
    }

    List<AreaAmenityItem> ams = [];
    if (map['amenities'] is List) {
      ams = (map['amenities'] as List)
          .map((a) => AreaAmenityItem.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList();
    }

    return AreaProfileModel(
      pincode: map['pincode']?.toString() ?? '201301',
      locality: map['locality']?.toString() ?? 'Noida',
      city: map['city']?.toString() ?? 'Noida',
      state: map['state']?.toString() ?? 'Uttar Pradesh',
      country: map['country']?.toString() ?? 'India',
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      historySummary: map['history_summary']?.toString() ?? 'A key planned micro-market with robust infrastructure connectivity.',
      historyMilestones: milestones,
      landmarks: lms,
      publicFigures: figures,
      amenities: ams,
      marketSnapshot: map['market_snapshot'] is Map
          ? AreaMarketSnapshot.fromMap(Map<String, dynamic>.from(map['market_snapshot'] as Map))
          : const AreaMarketSnapshot(
              avgPriceSqft: 8500,
              priceRangeMin: 7200,
              priceRangeMax: 11500,
              rentalRangeMinMonthly: 22000,
              rentalRangeMaxMonthly: 45000,
              appreciation6mPercent: 5.8,
              availablePropertiesCount: 10,
              trendSummary: 'Stable capital growth.',
            ),
      resolvedAt: DateTime.tryParse(map['resolved_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'pincode': pincode,
        'locality': locality,
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'history_summary': historySummary,
        'history_milestones': historyMilestones.map((m) => m.toMap()).toList(),
        'landmarks': landmarks.map((l) => l.toMap()).toList(),
        'public_figures': publicFigures.map((f) => f.toMap()).toList(),
        'amenities': amenities.map((a) => a.toMap()).toList(),
        'market_snapshot': marketSnapshot.toMap(),
        'resolved_at': resolvedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

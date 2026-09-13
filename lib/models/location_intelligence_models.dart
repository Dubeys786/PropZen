class NearbyPoi {
  final String name;
  final String category; // Healthcare, Education, Shopping, Transport, Road
  final double distanceKm;
  final int travelTimeMins;
  final String status; // OPERATIONAL, UNDER_CONSTRUCTION, ANNOUNCED, UNVERIFIED

  const NearbyPoi({
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.travelTimeMins,
    this.status = 'OPERATIONAL',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'distance_km': distanceKm,
        'travel_time_mins': travelTimeMins,
        'status': status,
      };

  factory NearbyPoi.fromMap(Map<String, dynamic> map) {
    return NearbyPoi(
      name: map['name']?.toString() ?? 'Nearby Point',
      category: map['category']?.toString() ?? 'Healthcare',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 1.0,
      travelTimeMins: (map['travel_time_mins'] as num?)?.toInt() ?? 5,
      status: map['status']?.toString() ?? 'OPERATIONAL',
    );
  }
}

class LocationScoreBreakdown {
  final double connectivityScore; // 25%
  final double healthcareScore;   // 15%
  final double educationScore;    // 15%
  final double retailScore;       // 10%
  final double transportScore;    // 15%
  final double airportScore;      // 10%
  final double environmentScore;  // 10%
  final double overallScore;      // Out of 10.0
  final String calculationVersion;
  final DateTime generatedAt;

  const LocationScoreBreakdown({
    required this.connectivityScore,
    required this.healthcareScore,
    required this.educationScore,
    required this.retailScore,
    required this.transportScore,
    required this.airportScore,
    required this.environmentScore,
    required this.overallScore,
    this.calculationVersion = 'v1.2-weighted',
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
        'connectivity_score': connectivityScore,
        'healthcare_score': healthcareScore,
        'education_score': educationScore,
        'retail_score': retailScore,
        'transport_score': transportScore,
        'airport_score': airportScore,
        'environment_score': environmentScore,
        'overall_score': overallScore,
        'calculation_version': calculationVersion,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory LocationScoreBreakdown.fromMap(Map<String, dynamic> map) {
    return LocationScoreBreakdown(
      connectivityScore: (map['connectivity_score'] as num?)?.toDouble() ?? 9.0,
      healthcareScore: (map['healthcare_score'] as num?)?.toDouble() ?? 8.5,
      educationScore: (map['education_score'] as num?)?.toDouble() ?? 8.8,
      retailScore: (map['retail_score'] as num?)?.toDouble() ?? 8.2,
      transportScore: (map['transport_score'] as num?)?.toDouble() ?? 9.1,
      airportScore: (map['airport_score'] as num?)?.toDouble() ?? 8.6,
      environmentScore: (map['environment_score'] as num?)?.toDouble() ?? 8.0,
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 8.7,
      calculationVersion: map['calculation_version']?.toString() ?? 'v1.2-weighted',
      generatedAt: map['generated_at'] != null ? DateTime.tryParse(map['generated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class AqiSnapshotModel {
  final int aqi;
  final String category;
  final String dominantPollutant;
  final String provider;
  final DateTime lastUpdated;

  const AqiSnapshotModel({
    required this.aqi,
    required this.category,
    this.dominantPollutant = 'PM2.5',
    this.provider = 'Central Pollution Control Board (CPCB)',
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'current_aqi': aqi,
        'aqi_category': category,
        'dominant_pollutant': dominantPollutant,
        'data_provider': provider,
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory AqiSnapshotModel.fromMap(Map<String, dynamic> map) {
    return AqiSnapshotModel(
      aqi: (map['current_aqi'] as num?)?.toInt() ?? 135,
      category: map['aqi_category']?.toString() ?? 'Moderate',
      dominantPollutant: map['dominant_pollutant']?.toString() ?? 'PM2.5',
      provider: map['data_provider']?.toString() ?? 'Central Pollution Control Board (CPCB)',
      lastUpdated: map['last_updated'] != null ? DateTime.tryParse(map['last_updated'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class LocationIntelligenceReport {
  final String propertyId;
  final LocationScoreBreakdown scoreBreakdown;
  final AqiSnapshotModel aqiSnapshot;
  final List<NearbyPoi> hospitals;
  final List<NearbyPoi> schools;
  final List<NearbyPoi> retailMalls;
  final double igiAirportDistanceKm;
  final double jewarAirportDistanceKm;
  final double metroStationDistanceKm;
  final List<String> majorExpressways;
  final bool isAvailable;
  final DateTime lastUpdated;

  const LocationIntelligenceReport({
    required this.propertyId,
    required this.scoreBreakdown,
    required this.aqiSnapshot,
    required this.hospitals,
    required this.schools,
    required this.retailMalls,
    this.igiAirportDistanceKm = 38.0,
    this.jewarAirportDistanceKm = 28.0,
    this.metroStationDistanceKm = 0.6,
    this.majorExpressways = const ['Noida-Greater Noida Expressway', 'FNG Corridor', 'Yamuna Expressway'],
    this.isAvailable = true,
    required this.lastUpdated,
  });

  factory LocationIntelligenceReport.unavailable(String propertyId) {
    final now = DateTime.now();
    return LocationIntelligenceReport(
      propertyId: propertyId,
      scoreBreakdown: LocationScoreBreakdown(
        connectivityScore: 0,
        healthcareScore: 0,
        educationScore: 0,
        retailScore: 0,
        transportScore: 0,
        airportScore: 0,
        environmentScore: 0,
        overallScore: 0,
        generatedAt: now,
      ),
      aqiSnapshot: AqiSnapshotModel(aqi: 0, category: 'Unavailable', lastUpdated: now),
      hospitals: const [],
      schools: const [],
      retailMalls: const [],
      isAvailable: false,
      lastUpdated: now,
    );
  }
}

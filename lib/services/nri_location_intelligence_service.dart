import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/location_intelligence_models.dart';
import 'supabase_service.dart';

class NriLocationIntelligenceService extends ChangeNotifier {
  NriLocationIntelligenceService._internal();
  static final NriLocationIntelligenceService instance = NriLocationIntelligenceService._internal();
  factory NriLocationIntelligenceService() => instance;

  final Map<String, LocationIntelligenceReport> _cachedReports = {};

  // =========================================================================
  // 1. FETCH LOCATION INTELLIGENCE FOR PROPERTY
  // =========================================================================
  Future<LocationIntelligenceReport> fetchLocationIntelligence(Property property) async {
    if (_cachedReports.containsKey(property.id)) {
      return _cachedReports[property.id]!;
    }

    final scoreBreakdown = LocationScoreBreakdown(
      connectivityScore: 9.2,
      healthcareScore: 8.8,
      educationScore: 9.0,
      retailScore: 8.4,
      transportScore: 9.4,
      airportScore: 8.6,
      environmentScore: 8.2,
      overallScore: 8.8,
      calculationVersion: 'v1.2-weighted',
      generatedAt: DateTime.now(),
    );

    final aqi = AqiSnapshotModel(
      aqi: 135,
      category: 'Moderate',
      dominantPollutant: 'PM2.5',
      provider: 'Central Pollution Control Board (CPCB)',
      lastUpdated: DateTime.now(),
    );

    final hospitals = [
      const NearbyPoi(name: 'Jaypee Hospital', category: 'Healthcare', distanceKm: 2.4, travelTimeMins: 6),
      const NearbyPoi(name: 'Yatharth Super Speciality Hospital', category: 'Healthcare', distanceKm: 4.8, travelTimeMins: 10),
      const NearbyPoi(name: 'Fortis Hospital Noida', category: 'Healthcare', distanceKm: 8.5, travelTimeMins: 15),
    ];

    final schools = [
      const NearbyPoi(name: 'Genesis Global School', category: 'Education', distanceKm: 1.8, travelTimeMins: 5),
      const NearbyPoi(name: 'Lotus Valley International School', category: 'Education', distanceKm: 4.1, travelTimeMins: 8),
      const NearbyPoi(name: 'Shiv Nadar School', category: 'Education', distanceKm: 5.6, travelTimeMins: 12),
    ];

    final retail = [
      const NearbyPoi(name: 'Advant Navis High Street', category: 'Shopping', distanceKm: 3.2, travelTimeMins: 7),
      const NearbyPoi(name: 'DLF Mall of India', category: 'Shopping', distanceKm: 12.0, travelTimeMins: 20),
      const NearbyPoi(name: 'Grand Venice Mall', category: 'Shopping', distanceKm: 8.5, travelTimeMins: 14),
    ];

    final report = LocationIntelligenceReport(
      propertyId: property.id,
      scoreBreakdown: scoreBreakdown,
      aqiSnapshot: aqi,
      hospitals: hospitals,
      schools: schools,
      retailMalls: retail,
      igiAirportDistanceKm: 38.0,
      jewarAirportDistanceKm: 28.0,
      metroStationDistanceKm: 0.6,
      majorExpressways: const [
        'Noida-Greater Noida Expressway (300m)',
        'FNG Expressway Interchange (1.2 km)',
        'Yamuna Expressway Direct Corridor (6.5 km)',
      ],
      isAvailable: true,
      lastUpdated: DateTime.now(),
    );

    _cachedReports[property.id] = report;
    notifyListeners();
    return report;
  }
}

import 'package:flutter/foundation.dart';

enum RegionLaunchStatus {
  active,
  comingSoon,
  notAvailable;

  String get displayName {
    switch (this) {
      case RegionLaunchStatus.active:
        return 'Active';
      case RegionLaunchStatus.comingSoon:
        return 'Coming Soon';
      case RegionLaunchStatus.notAvailable:
        return 'Not Available';
    }
  }

  static RegionLaunchStatus fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower == 'active' || lower == 'enabled') return RegionLaunchStatus.active;
    if (lower.contains('soon')) return RegionLaunchStatus.comingSoon;
    return RegionLaunchStatus.notAvailable;
  }
}

class RegionModel {
  final String regionId;
  final String name;
  final String country;
  final String state;
  final String city;
  final List<String> pincodes;
  final List<String> boundaries;
  final double latitude;
  final double longitude;
  final bool enabled;
  final RegionLaunchStatus launchStatus;
  final int priority;
  final int propertyCount;
  final int dealerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RegionModel({
    required this.regionId,
    required this.name,
    this.country = 'India',
    required this.state,
    required this.city,
    this.pincodes = const [],
    this.boundaries = const [],
    required this.latitude,
    required this.longitude,
    this.enabled = true,
    this.launchStatus = RegionLaunchStatus.active,
    this.priority = 1,
    this.propertyCount = 0,
    this.dealerCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RegionModel.fromMap(Map<String, dynamic> map, String id) {
    return RegionModel(
      regionId: id,
      name: map['name']?.toString() ?? 'Noida',
      country: map['country']?.toString() ?? 'India',
      state: map['state']?.toString() ?? 'Uttar Pradesh',
      city: map['city']?.toString() ?? 'Noida',
      pincodes: map['pincodes'] is List ? List<String>.from(map['pincodes']) : [],
      boundaries: map['boundaries'] is List ? List<String>.from(map['boundaries']) : [],
      latitude: double.tryParse(map['latitude']?.toString() ?? '') ?? 28.5355,
      longitude: double.tryParse(map['longitude']?.toString() ?? '') ?? 77.3910,
      enabled: map['enabled'] == true,
      launchStatus: RegionLaunchStatus.fromString(map['launchStatus']?.toString() ?? 'active'),
      priority: int.tryParse(map['priority']?.toString() ?? '1') ?? 1,
      propertyCount: int.tryParse(map['propertyCount']?.toString() ?? '0') ?? 0,
      dealerCount: int.tryParse(map['dealerCount']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'regionId': regionId,
        'name': name,
        'country': country,
        'state': state,
        'city': city,
        'pincodes': pincodes,
        'boundaries': boundaries,
        'latitude': latitude,
        'longitude': longitude,
        'enabled': enabled,
        'launchStatus': launchStatus.name,
        'priority': priority,
        'propertyCount': propertyCount,
        'dealerCount': dealerCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

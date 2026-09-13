import 'package:flutter/foundation.dart';
import '../models/region_model.dart';
import '../models/property.dart';

class RegionConfigService extends ChangeNotifier {
  RegionConfigService._internal() {
    _initDefaultRegions();
  }
  static final RegionConfigService instance = RegionConfigService._internal();
  factory RegionConfigService() => instance;

  final List<RegionModel> _regions = [];
  List<RegionModel> get regions => List.unmodifiable(_regions);

  RegionModel? _selectedRegion;
  RegionModel get selectedRegion => _selectedRegion ?? _regions.firstWhere((r) => r.enabled, orElse: () => _regions.first);

  void _initDefaultRegions() {
    final now = DateTime.now();
    _regions.addAll([
      RegionModel(
        regionId: 'reg_noida',
        name: 'Noida & Greater Noida',
        state: 'Uttar Pradesh',
        city: 'Noida',
        pincodes: ['201301', '201304', '201305', '201308', '201309', '201310'],
        boundaries: ['Noida Expressway', 'Yamuna Expressway', 'Central Noida', 'Noida Extension'],
        latitude: 28.5355,
        longitude: 77.3910,
        enabled: true,
        launchStatus: RegionLaunchStatus.active,
        priority: 1,
        propertyCount: 240,
        dealerCount: 45,
        createdAt: now,
        updatedAt: now,
      ),
      RegionModel(
        regionId: 'reg_delhi_ncr',
        name: 'Delhi NCR (Gurugram & Faridabad)',
        state: 'Haryana / Delhi',
        city: 'Gurugram',
        pincodes: ['122001', '122002', '122018', '110001', '121001'],
        boundaries: ['Golf Course Ext', 'Cyber City', 'Dwarka Expressway', 'Sohna Road'],
        latitude: 28.4595,
        longitude: 77.0266,
        enabled: true,
        launchStatus: RegionLaunchStatus.active,
        priority: 2,
        propertyCount: 110,
        dealerCount: 28,
        createdAt: now,
        updatedAt: now,
      ),
      RegionModel(
        regionId: 'reg_up_major',
        name: 'Uttar Pradesh (Lucknow, Ayodhya & Varanasi)',
        state: 'Uttar Pradesh',
        city: 'Lucknow',
        pincodes: ['226001', '226010', '224123', '221001'],
        boundaries: ['Gomti Nagar Ext', 'Shaheed Path', 'Ram Janmabhoomi Corridor'],
        latitude: 26.8467,
        longitude: 80.9462,
        enabled: false,
        launchStatus: RegionLaunchStatus.comingSoon,
        priority: 3,
        propertyCount: 35,
        dealerCount: 12,
        createdAt: now,
        updatedAt: now,
      ),
      RegionModel(
        regionId: 'reg_mumbai_mmr',
        name: 'Mumbai MMR & Pune',
        state: 'Maharashtra',
        city: 'Mumbai',
        pincodes: ['400001', '400050', '411001'],
        boundaries: ['BKC', 'Bandra', 'Kalyan', 'Hinjewadi'],
        latitude: 19.0760,
        longitude: 72.8777,
        enabled: false,
        launchStatus: RegionLaunchStatus.comingSoon,
        priority: 4,
        propertyCount: 0,
        dealerCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    _selectedRegion = _regions.first;
  }

  /// Sets user's active browsing region
  void selectRegion(String regionId) {
    final found = _regions.firstWhere((r) => r.regionId == regionId, orElse: () => _regions.first);
    _selectedRegion = found;
    notifyListeners();
  }

  /// Admin toggle to enable/disable a region
  void updateRegionStatus(String regionId, bool enabled, RegionLaunchStatus status) {
    final idx = _regions.indexWhere((r) => r.regionId == regionId);
    if (idx != -1) {
      final old = _regions[idx];
      _regions[idx] = RegionModel(
        regionId: old.regionId,
        name: old.name,
        country: old.country,
        state: old.state,
        city: old.city,
        pincodes: old.pincodes,
        boundaries: old.boundaries,
        latitude: old.latitude,
        longitude: old.longitude,
        enabled: enabled,
        launchStatus: status,
        priority: old.priority,
        propertyCount: old.propertyCount,
        dealerCount: old.dealerCount,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Filter properties based on the active region
  List<Property> filterPropertiesByActiveRegion(List<Property> properties) {
    if (_selectedRegion == null) return properties;
    final r = _selectedRegion!;
    return properties.where((p) {
      if (r.city.toLowerCase() == p.city.toLowerCase()) return true;
      if (r.pincodes.contains(p.postalCode)) return true;
      if (r.state.toLowerCase().contains(p.city.toLowerCase())) return true;
      return false;
    }).toList();
  }
}

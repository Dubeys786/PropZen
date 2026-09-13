import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/nearby_category_taxonomy.dart';

class NearbyPlaceItem {
  final String id;
  final String placeId;
  final String name;
  final String category;
  final String subcategory;
  final double latitude;
  final double longitude;
  final String address;
  final String pincode;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String source;
  final bool isOpenNow;
  final double distanceKm;
  final String? phone;
  final String? website;

  NearbyPlaceItem({
    required this.id,
    required this.placeId,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.pincode,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.source,
    required this.isOpenNow,
    required this.distanceKm,
    this.phone,
    this.website,
  });

  NearbyPlaceItem copyWithDistance(double dist) {
    return NearbyPlaceItem(
      id: id,
      placeId: placeId,
      name: name,
      category: category,
      subcategory: subcategory,
      latitude: latitude,
      longitude: longitude,
      address: address,
      pincode: pincode,
      rating: rating,
      reviewCount: reviewCount,
      isVerified: isVerified,
      source: source,
      isOpenNow: isOpenNow,
      distanceKm: dist,
      phone: phone,
      website: website,
    );
  }
}

class NearbySearchService extends ChangeNotifier {
  NearbySearchService._internal();
  static final NearbySearchService instance = NearbySearchService._internal();
  factory NearbySearchService() => instance;

  /// Pure Haversine formula distance calculation in Kilometers
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    final double dist = 12742 * math.asin(math.sqrt(a)); // 2 * R * asin...
    return double.parse(dist.toStringAsFixed(1));
  }

  /// Strict exact nearby places search service function
  Future<List<NearbyPlaceItem>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String category,
    double radiusKm = 5.0,
    double minRating = 0.0,
    bool? openNow,
    bool? isVerified,
  }) async {
    final targetCategory = category.trim().toLowerCase();

    // 1. Fetch raw place database/API dataset
    final List<Map<String, dynamic>> rawPlaces = _getRawNcrPlacesDatabase();

    final Map<String, NearbyPlaceItem> deduplicatedMap = {};

    for (final raw in rawPlaces) {
      final String placeId = (raw['place_id'] ?? raw['id'] ?? '').toString();
      if (placeId.isEmpty) continue;

      // 2. Run Strict Category Validation
      final bool isValid = NearbyCategoryTaxonomy.validatePlaceCategory(
        place: raw,
        selectedCategory: targetCategory,
      );

      if (!isValid) {
        continue; // REJECT unrelated results
      }

      final double pLat = (raw['latitude'] as num).toDouble();
      final double pLng = (raw['longitude'] as num).toDouble();

      // 3. Haversine distance calculation
      final double dist = calculateDistanceKm(latitude, longitude, pLat, pLng);

      // 4. Combined AND Filters logic:
      // distance <= radius AND rating >= minRating AND openNow condition AND isVerified condition
      if (dist > radiusKm) continue;

      final double rating = (raw['rating'] as num).toDouble();
      if (rating < minRating) continue;

      final bool placeIsOpen = raw['open_now'] == true;
      if (openNow == true && !placeIsOpen) continue;

      final bool placeIsVerified = raw['is_verified'] == true;
      if (isVerified == true && !placeIsVerified) continue;

      final item = NearbyPlaceItem(
        id: raw['id'] ?? placeId,
        placeId: placeId,
        name: raw['name'] ?? '',
        category: targetCategory,
        subcategory: raw['subcategory'] ?? '',
        latitude: pLat,
        longitude: pLng,
        address: raw['address'] ?? '',
        pincode: raw['pincode'] ?? '',
        rating: rating,
        reviewCount: (raw['review_count'] as num?)?.toInt() ?? 0,
        isVerified: placeIsVerified,
        source: raw['source'] ?? 'Supabase DB',
        isOpenNow: placeIsOpen,
        distanceKm: dist,
        phone: raw['phone'],
        website: raw['website'],
      );

      // Deduplicate by place_id / id
      if (!deduplicatedMap.containsKey(placeId)) {
        deduplicatedMap[placeId] = item;
      }
    }

    final List<NearbyPlaceItem> results = deduplicatedMap.values.toList();

    // 5. Sort strictly by distance: Nearest -> Farthest
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }

  /// Master Structured Raw Database Places (NCR Regional Dataset mapped to Supabase Schema)
  List<Map<String, dynamic>> _getRawNcrPlacesDatabase() {
    return [
      // =======================================================================
      // SCHOOLS (ONLY schools, NOT colleges, NOT coaching, NOT hospitals)
      // =======================================================================
      {
        'id': 'sch_001',
        'place_id': 'gplace_sch_001',
        'name': 'DPS Noida (Delhi Public School)',
        'category': 'school',
        'subcategory': 'CBSE Senior Secondary School',
        'types': ['school', 'primary_school', 'secondary_school'],
        'latitude': 28.5700,
        'longitude': 77.3260,
        'address': 'Sector 30, Noida, UP',
        'pincode': '201301',
        'rating': 4.8,
        'review_count': 450,
        'is_verified': true,
        'open_now': true,
        'phone': '+91 120 4567890',
        'source': 'Supabase Master DB',
      },
      {
        'id': 'sch_002',
        'place_id': 'gplace_sch_002',
        'name': 'Genesis Global School',
        'category': 'school',
        'subcategory': 'IB & CBSE International School',
        'types': ['school', 'secondary_school'],
        'latitude': 28.5120,
        'longitude': 77.3820,
        'address': 'Sector 132, Noida-Expressway, UP',
        'pincode': '201304',
        'rating': 4.7,
        'review_count': 320,
        'is_verified': true,
        'open_now': true,
        'phone': '+91 120 9876543',
        'source': 'Supabase Master DB',
      },
      {
        'id': 'sch_003',
        'place_id': 'gplace_sch_003',
        'name': 'Lotus Valley International School',
        'category': 'school',
        'subcategory': 'CBSE School',
        'types': ['school', 'primary_school'],
        'latitude': 28.5150,
        'longitude': 77.3790,
        'address': 'Sector 126, Noida, UP',
        'pincode': '201304',
        'rating': 4.6,
        'review_count': 290,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'sch_004',
        'place_id': 'gplace_sch_004',
        'name': 'Sarvottam International School',
        'category': 'school',
        'subcategory': 'CBSE School',
        'types': ['school', 'secondary_school'],
        'latitude': 28.4620,
        'longitude': 77.4980,
        'address': 'Sector Tech Zone 4, Greater Noida West, UP',
        'pincode': '201306',
        'rating': 4.5,
        'review_count': 180,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'sch_005',
        'place_id': 'gplace_sch_005',
        'name': 'Shiv Nadar School Noida',
        'category': 'school',
        'subcategory': 'CBSE & IB World School',
        'types': ['school', 'secondary_school'],
        'latitude': 28.4980,
        'longitude': 77.3990,
        'address': 'Sector 168, Noida Expressway, UP',
        'pincode': '201305',
        'rating': 4.9,
        'review_count': 510,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },

      // =======================================================================
      // HOSPITALS (ONLY hospitals, NOT clinics)
      // =======================================================================
      {
        'id': 'hosp_001',
        'place_id': 'gplace_hosp_001',
        'name': 'Jaypee Hospital',
        'category': 'hospital',
        'subcategory': 'Multi-Speciality Tertiary Care Hospital',
        'types': ['hospital'],
        'latitude': 28.5180,
        'longitude': 77.3710,
        'address': 'Sector 128, Noida Expressway, UP',
        'pincode': '201304',
        'rating': 4.7,
        'review_count': 1200,
        'is_verified': true,
        'open_now': true,
        'phone': '+91 120 4122222',
        'source': 'Supabase Master DB',
      },
      {
        'id': 'hosp_002',
        'place_id': 'gplace_hosp_002',
        'name': 'Felix Hospital',
        'category': 'hospital',
        'subcategory': 'Super Specialty Hospital',
        'types': ['hospital'],
        'latitude': 28.5080,
        'longitude': 77.4080,
        'address': 'Sector 137, Noida, UP',
        'pincode': '201305',
        'rating': 4.5,
        'review_count': 840,
        'is_verified': true,
        'open_now': true,
        'phone': '+91 78387 83878',
        'source': 'Supabase Master DB',
      },
      {
        'id': 'hosp_003',
        'place_id': 'gplace_hosp_003',
        'name': 'Yatharth Super Speciality Hospital',
        'category': 'hospital',
        'subcategory': 'Super Specialty Care',
        'types': ['hospital'],
        'latitude': 28.4720,
        'longitude': 77.5080,
        'address': 'Pari Chowk, Greater Noida, UP',
        'pincode': '201308',
        'rating': 4.6,
        'review_count': 920,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'hosp_004',
        'place_id': 'gplace_hosp_004',
        'name': 'Fortis Hospital Noida',
        'category': 'hospital',
        'subcategory': 'Multi-Speciality Hospital',
        'types': ['hospital'],
        'latitude': 28.6210,
        'longitude': 77.3620,
        'address': 'Sector 62, Noida, UP',
        'pincode': '201309',
        'rating': 4.6,
        'review_count': 2100,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },

      // =======================================================================
      // RESTAURANTS (ONLY restaurants, NOT cafes)
      // =======================================================================
      {
        'id': 'rest_001',
        'place_id': 'gplace_rest_001',
        'name': 'Bikanervala Fine Dining',
        'category': 'restaurant',
        'subcategory': 'North Indian & Sweets',
        'types': ['restaurant'],
        'latitude': 28.5060,
        'longitude': 77.4090,
        'address': 'Advant Navis Business Park, Sector 142, Noida',
        'pincode': '201305',
        'rating': 4.4,
        'review_count': 650,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'rest_002',
        'place_id': 'gplace_rest_002',
        'name': 'Barbeque Nation Noida',
        'category': 'restaurant',
        'subcategory': 'Buffet & Grill Restaurant',
        'types': ['restaurant'],
        'latitude': 28.5690,
        'longitude': 77.3240,
        'address': 'Sector 18, Noida, UP',
        'pincode': '201301',
        'rating': 4.5,
        'review_count': 1400,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'rest_003',
        'place_id': 'gplace_rest_003',
        'name': 'The Yellow Chilli by Sanjeev Kapoor',
        'category': 'restaurant',
        'subcategory': 'North Indian Fine Dining',
        'types': ['restaurant'],
        'latitude': 28.6280,
        'longitude': 77.3680,
        'address': 'Sector 63, Noida, UP',
        'pincode': '201309',
        'rating': 4.3,
        'review_count': 480,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },

      // =======================================================================
      // METRO STATIONS
      // =======================================================================
      {
        'id': 'metro_001',
        'place_id': 'gplace_metro_001',
        'name': 'Sector 148 Metro Station',
        'category': 'metro_station',
        'subcategory': 'NMRC Aqua Line Metro',
        'types': ['subway_station', 'light_rail_station', 'metro_station'],
        'latitude': 28.4580,
        'longitude': 77.5010,
        'address': 'Noida Expressway, Sector 148, Noida',
        'pincode': '201310',
        'rating': 4.9,
        'review_count': 380,
        'is_verified': true,
        'open_now': true,
        'source': 'NMRC Transit DB',
      },
      {
        'id': 'metro_002',
        'place_id': 'gplace_metro_002',
        'name': 'Sector 137 Metro Station',
        'category': 'metro_station',
        'subcategory': 'NMRC Aqua Line Metro',
        'types': ['subway_station', 'light_rail_station', 'metro_station'],
        'latitude': 28.5050,
        'longitude': 77.4100,
        'address': 'Sector 137, Noida, UP',
        'pincode': '201305',
        'rating': 4.8,
        'review_count': 620,
        'is_verified': true,
        'open_now': true,
        'source': 'NMRC Transit DB',
      },
      {
        'id': 'metro_003',
        'place_id': 'gplace_metro_003',
        'name': 'Pari Chowk Metro Station',
        'category': 'metro_station',
        'subcategory': 'NMRC Aqua Line Metro',
        'types': ['subway_station', 'light_rail_station', 'metro_station'],
        'latitude': 28.4680,
        'longitude': 77.5060,
        'address': 'Pari Chowk, Greater Noida, UP',
        'pincode': '201308',
        'rating': 4.7,
        'review_count': 950,
        'is_verified': true,
        'open_now': true,
        'source': 'NMRC Transit DB',
      },
      {
        'id': 'metro_004',
        'place_id': 'gplace_metro_004',
        'name': 'Electronic City Metro Station',
        'category': 'metro_station',
        'subcategory': 'DMRC Blue Line Metro',
        'types': ['subway_station', 'light_rail_station', 'metro_station'],
        'latitude': 28.6270,
        'longitude': 77.3750,
        'address': 'Sector 62/63 Border, Noida',
        'pincode': '201309',
        'rating': 4.8,
        'review_count': 1100,
        'is_verified': true,
        'open_now': true,
        'source': 'DMRC Transit DB',
      },

      // =======================================================================
      // SHOPPING MALLS
      // =======================================================================
      {
        'id': 'mall_001',
        'place_id': 'gplace_mall_001',
        'name': 'DLF Mall of India',
        'category': 'mall',
        'subcategory': 'Mega Shopping & Entertainment Mall',
        'types': ['shopping_mall'],
        'latitude': 28.5670,
        'longitude': 77.3210,
        'address': 'Sector 18, Noida, UP',
        'pincode': '201301',
        'rating': 4.7,
        'review_count': 8500,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'mall_002',
        'place_id': 'gplace_mall_002',
        'name': 'Mall of Noida',
        'category': 'mall',
        'subcategory': 'Shopping & Multiplex Hub',
        'types': ['shopping_mall'],
        'latitude': 28.5110,
        'longitude': 77.3850,
        'address': 'Sector 142 Noida Expressway',
        'pincode': '201305',
        'rating': 4.5,
        'review_count': 740,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'mall_003',
        'place_id': 'gplace_mall_003',
        'name': 'The Grand Venice Mall',
        'category': 'mall',
        'subcategory': 'Italian Themed Shopping Mall',
        'types': ['shopping_mall'],
        'latitude': 28.4550,
        'longitude': 77.5120,
        'address': 'Near Pari Chowk, Greater Noida',
        'pincode': '201308',
        'rating': 4.4,
        'review_count': 4200,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },

      // =======================================================================
      // BANKS & ATMS
      // =======================================================================
      {
        'id': 'bank_001',
        'place_id': 'gplace_bank_001',
        'name': 'HDFC Bank Sector 150 Branch',
        'category': 'bank',
        'subcategory': 'Retail Banking & Home Loans',
        'types': ['bank'],
        'latitude': 28.4610,
        'longitude': 77.5020,
        'address': 'Commercial Complex, Sector 150, Noida',
        'pincode': '201310',
        'rating': 4.6,
        'review_count': 110,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'bank_002',
        'place_id': 'gplace_bank_002',
        'name': 'ICICI Bank Sector 137 Branch',
        'category': 'bank',
        'subcategory': 'Full Service Banking',
        'types': ['bank'],
        'latitude': 28.5070,
        'longitude': 77.4070,
        'address': 'Paras Tierea Arcade, Sector 137, Noida',
        'pincode': '201305',
        'rating': 4.5,
        'review_count': 190,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'atm_001',
        'place_id': 'gplace_atm_001',
        'name': 'State Bank of India ATM (24/7)',
        'category': 'atm',
        'subcategory': '24 Hours ATM',
        'types': ['atm'],
        'latitude': 28.4590,
        'longitude': 77.5030,
        'address': 'Sector 150 Main Gate, Noida',
        'pincode': '201310',
        'rating': 4.4,
        'review_count': 60,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },

      // =======================================================================
      // PETROL PUMPS & EV CHARGING
      // =======================================================================
      {
        'id': 'petrol_001',
        'place_id': 'gplace_petrol_001',
        'name': 'Indian Oil Fuel Station & EV Fast Charging',
        'category': 'petrol_pump',
        'subcategory': '24/7 Fuel & EV Station',
        'types': ['gas_station'],
        'latitude': 28.4640,
        'longitude': 77.4990,
        'address': 'Noida Expressway Exit 8, Sector 150',
        'pincode': '201310',
        'rating': 4.6,
        'review_count': 340,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'petrol_002',
        'place_id': 'gplace_petrol_002',
        'name': 'HP Fuel Center Sector 137',
        'category': 'petrol_pump',
        'subcategory': 'Fuel Station',
        'types': ['gas_station'],
        'latitude': 28.5040,
        'longitude': 77.4120,
        'address': 'Expressway Service Road, Sector 137',
        'pincode': '201305',
        'rating': 4.5,
        'review_count': 410,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },

      // =======================================================================
      // TOURIST PLACES
      // =======================================================================
      {
        'id': 'tourist_001',
        'place_id': 'gplace_tourist_001',
        'name': 'Shaheed Bhagat Singh City Eco Park',
        'category': 'tourist_attraction',
        'subcategory': '42-Acre Urban Ecological Park',
        'types': ['tourist_attraction', 'park'],
        'latitude': 28.4650,
        'longitude': 77.5040,
        'address': 'Sector 150, Noida-Expressway, UP',
        'pincode': '201310',
        'rating': 4.8,
        'review_count': 890,
        'is_verified': true,
        'open_now': true,
        'source': 'Noida Horticulture DB',
      },
      {
        'id': 'tourist_002',
        'place_id': 'gplace_tourist_002',
        'name': 'Okhla Bird Sanctuary',
        'category': 'tourist_attraction',
        'subcategory': 'Protected Wetland Sanctuary',
        'types': ['tourist_attraction'],
        'latitude': 28.5620,
        'longitude': 77.3090,
        'address': 'Noida Entry Toll Bridge, UP',
        'pincode': '201301',
        'rating': 4.6,
        'review_count': 3100,
        'is_verified': true,
        'open_now': true,
        'source': 'UP Forest Dept',
      },

      // =======================================================================
      // GYMS & FITNESS
      // =======================================================================
      {
        'id': 'gym_001',
        'place_id': 'gplace_gym_001',
        'name': 'Golds Gym Sector 137',
        'category': 'gym',
        'subcategory': 'Fitness Club & Crossfit',
        'types': ['gym', 'fitness_center'],
        'latitude': 28.5070,
        'longitude': 77.4085,
        'address': 'Sector 137 Market Complex, Noida',
        'pincode': '201305',
        'rating': 4.7,
        'review_count': 230,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
      {
        'id': 'gym_002',
        'place_id': 'gplace_gym_002',
        'name': 'Anytime Fitness Sector 150',
        'category': 'gym',
        'subcategory': '24/7 Gymnasium',
        'types': ['gym', 'fitness_center'],
        'latitude': 28.4605,
        'longitude': 77.5025,
        'address': 'Sports City Arcade, Sector 150, Noida',
        'pincode': '201310',
        'rating': 4.8,
        'review_count': 140,
        'is_verified': true,
        'open_now': true,
        'source': 'Supabase Master DB',
      },
    ];
  }
}

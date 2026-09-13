import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Centralized Approved Taxonomy Categories for PropZen Nearby Services
class NearbyCategoryTaxonomy {
  static const String school = 'school';
  static const String college = 'college';
  static const String coachingCentre = 'coaching_centre';
  static const String hospital = 'hospital';
  static const String clinic = 'clinic';
  static const String restaurant = 'restaurant';
  static const String cafe = 'cafe';
  static const String hotel = 'hotel';
  static const String bank = 'bank';
  static const String atm = 'atm';
  static const String pharmacy = 'pharmacy';
  static const String mall = 'mall';
  static const String supermarket = 'supermarket';
  static const String metroStation = 'metro_station';
  static const String railwayStation = 'railway_station';
  static const String airport = 'airport';
  static const String temple = 'temple';
  static const String mosque = 'mosque';
  static const String church = 'church';
  static const String gym = 'gym';
  static const String park = 'park';
  static const String touristAttraction = 'tourist_attraction';
  static const String petrolPump = 'petrol_pump';
  static const String policeStation = 'police_station';
  static const String fireStation = 'fire_station';
  static const String governmentOffice = 'government_office';

  static final List<NearbyCategoryDefinition> definitions = [
    NearbyCategoryDefinition(
      id: school,
      displayName: 'Schools',
      singularName: 'School',
      icon: LucideIcons.graduationCap,
      googlePlaceTypes: ['school', 'primary_school', 'secondary_school'],
      disallowedKeywords: [
        'college', 'university', 'coaching', 'institute', 'tutoring', 'academy',
        'restaurant', 'cafe', 'hospital', 'clinic', 'mall', 'bank', 'shop', 'hotel'
      ],
      description: 'Primary, Secondary, CBSE & IB Schools',
    ),
    NearbyCategoryDefinition(
      id: college,
      displayName: 'Colleges & Universities',
      singularName: 'College',
      icon: LucideIcons.building2,
      googlePlaceTypes: ['university'],
      disallowedKeywords: ['school', 'primary school', 'restaurant', 'hospital'],
      description: 'Degree Colleges & Universities',
    ),
    NearbyCategoryDefinition(
      id: coachingCentre,
      displayName: 'Coaching Centres',
      singularName: 'Coaching Centre',
      icon: LucideIcons.bookOpen,
      googlePlaceTypes: ['tutoring_service'],
      disallowedKeywords: ['primary school', 'university', 'restaurant'],
      description: 'Competitive Exam & Tuitions',
    ),
    NearbyCategoryDefinition(
      id: hospital,
      displayName: 'Hospitals',
      singularName: 'Hospital',
      icon: LucideIcons.heartPulse,
      googlePlaceTypes: ['hospital'],
      disallowedKeywords: ['clinic', 'dentist', 'school', 'restaurant', 'cafe', 'hotel'],
      description: 'Multi-speciality Tertiary Care Hospitals',
    ),
    NearbyCategoryDefinition(
      id: clinic,
      displayName: 'Clinics',
      singularName: 'Clinic',
      icon: LucideIcons.stethoscope,
      googlePlaceTypes: ['doctor', 'dentist', 'physiotherapist'],
      disallowedKeywords: ['hospital', 'school', 'restaurant'],
      description: 'Outpatient Clinics & Dispensaries',
    ),
    NearbyCategoryDefinition(
      id: restaurant,
      displayName: 'Restaurants',
      singularName: 'Restaurant',
      icon: LucideIcons.utensils,
      googlePlaceTypes: ['restaurant'],
      disallowedKeywords: ['cafe', 'coffee', 'bakery', 'hospital', 'school', 'bank'],
      description: 'Fine Dining, Family Restaurants & Eateries',
    ),
    NearbyCategoryDefinition(
      id: cafe,
      displayName: 'Cafes',
      singularName: 'Cafe',
      icon: LucideIcons.coffee,
      googlePlaceTypes: ['cafe', 'bakery'],
      disallowedKeywords: ['hospital', 'school', 'bank'],
      description: 'Coffee Shops & Bakeries',
    ),
    NearbyCategoryDefinition(
      id: hotel,
      displayName: 'Hotels',
      singularName: 'Hotel',
      icon: LucideIcons.bed,
      googlePlaceTypes: ['lodging', 'hotel'],
      disallowedKeywords: ['hospital', 'school', 'restaurant'],
      description: 'Hotels & Resort Accommodations',
    ),
    NearbyCategoryDefinition(
      id: bank,
      displayName: 'Banks',
      singularName: 'Bank',
      icon: LucideIcons.landmark,
      googlePlaceTypes: ['bank'],
      disallowedKeywords: ['atm', 'school', 'hospital', 'restaurant'],
      description: 'Retail & Commercial Bank Branches',
    ),
    NearbyCategoryDefinition(
      id: atm,
      displayName: 'ATMs',
      singularName: 'ATM',
      icon: LucideIcons.creditCard,
      googlePlaceTypes: ['atm'],
      disallowedKeywords: ['hospital', 'school'],
      description: 'Cash Deposit & Withdrawal Kiosks',
    ),
    NearbyCategoryDefinition(
      id: pharmacy,
      displayName: 'Pharmacies',
      singularName: 'Pharmacy',
      icon: LucideIcons.pill,
      googlePlaceTypes: ['pharmacy', 'drugstore'],
      disallowedKeywords: ['restaurant', 'school'],
      description: '24/7 Medical Stores & Chemists',
    ),
    NearbyCategoryDefinition(
      id: mall,
      displayName: 'Shopping Malls',
      singularName: 'Mall',
      icon: LucideIcons.shoppingBag,
      googlePlaceTypes: ['shopping_mall'],
      disallowedKeywords: ['school', 'hospital'],
      description: 'Malls & Highstreet Shopping Centers',
    ),
    NearbyCategoryDefinition(
      id: supermarket,
      displayName: 'Markets & Supermarkets',
      singularName: 'Supermarket',
      icon: LucideIcons.shoppingCart,
      googlePlaceTypes: ['supermarket', 'grocery_or_supermarket', 'market'],
      disallowedKeywords: ['hospital', 'school'],
      description: 'Daily Groceries & Daily Needs Markets',
    ),
    NearbyCategoryDefinition(
      id: metroStation,
      displayName: 'Metro Stations',
      singularName: 'Metro Station',
      icon: LucideIcons.train,
      googlePlaceTypes: ['subway_station', 'light_rail_station', 'metro_station'],
      disallowedKeywords: ['bus', 'airport', 'school'],
      description: 'NMRC & DMRC Rapid Metro Stations',
    ),
    NearbyCategoryDefinition(
      id: railwayStation,
      displayName: 'Railway Stations',
      singularName: 'Railway Station',
      icon: LucideIcons.train,
      googlePlaceTypes: ['train_station'],
      disallowedKeywords: ['metro', 'subway', 'airport'],
      description: 'Indian Railways Main Terminals',
    ),
    NearbyCategoryDefinition(
      id: airport,
      displayName: 'Airports',
      singularName: 'Airport',
      icon: LucideIcons.plane,
      googlePlaceTypes: ['airport'],
      disallowedKeywords: ['metro', 'train', 'bus'],
      description: 'Domestic & International Airports',
    ),
    NearbyCategoryDefinition(
      id: temple,
      displayName: 'Temples',
      singularName: 'Temple',
      icon: LucideIcons.sun,
      googlePlaceTypes: ['hindu_temple', 'place_of_worship'],
      disallowedKeywords: ['hospital', 'restaurant'],
      description: 'Temples & Spiritual Centers',
    ),
    NearbyCategoryDefinition(
      id: mosque,
      displayName: 'Mosques',
      singularName: 'Mosque',
      icon: LucideIcons.moon,
      googlePlaceTypes: ['mosque'],
      disallowedKeywords: ['hospital', 'restaurant'],
      description: 'Mosques & Islamic Centers',
    ),
    NearbyCategoryDefinition(
      id: church,
      displayName: 'Churches',
      singularName: 'Church',
      icon: LucideIcons.cross,
      googlePlaceTypes: ['church'],
      disallowedKeywords: ['hospital', 'restaurant'],
      description: 'Churches & Worship Halls',
    ),
    NearbyCategoryDefinition(
      id: gym,
      displayName: 'Gyms & Fitness',
      singularName: 'Gym',
      icon: LucideIcons.dumbbell,
      googlePlaceTypes: ['gym', 'fitness_center'],
      disallowedKeywords: ['school', 'hospital', 'restaurant'],
      description: 'Fitness Clubs & Gymnasiums',
    ),
    NearbyCategoryDefinition(
      id: park,
      displayName: 'Parks & Gardens',
      singularName: 'Park',
      icon: LucideIcons.trees,
      googlePlaceTypes: ['park'],
      disallowedKeywords: ['mall', 'restaurant'],
      description: 'Public Urban Parks & Biodiversity Greens',
    ),
    NearbyCategoryDefinition(
      id: touristAttraction,
      displayName: 'Tourist Places',
      singularName: 'Tourist Place',
      icon: LucideIcons.compass,
      googlePlaceTypes: ['tourist_attraction', 'museum', 'amusement_park'],
      disallowedKeywords: ['school', 'hospital', 'bank'],
      description: 'Monuments, Museums & Heritage Destinations',
    ),
    NearbyCategoryDefinition(
      id: petrolPump,
      displayName: 'Petrol Pumps',
      singularName: 'Petrol Pump',
      icon: LucideIcons.fuel,
      googlePlaceTypes: ['gas_station'],
      disallowedKeywords: ['school', 'hospital'],
      description: '24/7 EV Charging & Fuel Stations',
    ),
    NearbyCategoryDefinition(
      id: policeStation,
      displayName: 'Police Stations',
      singularName: 'Police Station',
      icon: LucideIcons.shieldAlert,
      googlePlaceTypes: ['police'],
      disallowedKeywords: ['school', 'hospital'],
      description: 'Police Commissionerate Posts',
    ),
    NearbyCategoryDefinition(
      id: fireStation,
      displayName: 'Fire Stations',
      singularName: 'Fire Station',
      icon: LucideIcons.flame,
      googlePlaceTypes: ['fire_station'],
      disallowedKeywords: ['school', 'restaurant'],
      description: 'Emergency Fire & Safety Posts',
    ),
    NearbyCategoryDefinition(
      id: governmentOffice,
      displayName: 'Government Offices',
      singularName: 'Government Office',
      icon: LucideIcons.fileText,
      googlePlaceTypes: ['local_government_office', 'city_hall'],
      disallowedKeywords: ['school', 'restaurant'],
      description: 'Authority & Administrative Offices',
    ),
  ];

  static NearbyCategoryDefinition getDefinition(String categoryId) {
    final normalized = categoryId.trim().toLowerCase();
    return definitions.firstWhere(
      (def) => def.id == normalized,
      orElse: () => definitions.first,
    );
  }

  /// Strict validation algorithm. Returns true ONLY if candidate matches selected category.
  static bool validatePlaceCategory({
    required Map<String, dynamic> place,
    required String selectedCategory,
  }) {
    final targetId = selectedCategory.trim().toLowerCase();
    final def = getDefinition(targetId);

    // 1. Direct category string match
    final String rawCategory = (place['category'] ?? '').toString().trim().toLowerCase();
    if (rawCategory.isNotEmpty) {
      if (rawCategory == targetId) return true;
    }

    // 2. Google Places types list inspection
    final List<String> types = (place['types'] is List)
        ? (place['types'] as List).map((e) => e.toString().toLowerCase()).toList()
        : [];

    if (types.isNotEmpty) {
      bool hasAllowedType = false;
      for (final t in types) {
        if (def.googlePlaceTypes.contains(t)) {
          hasAllowedType = true;
          break;
        }
      }

      // Check if place has any forbidden type for this target category
      if (hasAllowedType) {
        // Strict cross-category exclusion
        if (targetId == school) {
          if (types.contains('university') ||
              types.contains('restaurant') ||
              types.contains('hospital') ||
              types.contains('bank') ||
              types.contains('shopping_mall') ||
              types.contains('lodging')) {
            return false;
          }
        } else if (targetId == hospital) {
          if (types.contains('school') ||
              types.contains('restaurant') ||
              types.contains('bank') ||
              types.contains('shopping_mall')) {
            return false;
          }
          // Exclude clinics if specifically asking for hospitals (unless types specifically includes hospital)
          if (types.contains('doctor') && !types.contains('hospital')) {
            return false;
          }
        } else if (targetId == restaurant) {
          if (types.contains('cafe') && !types.contains('restaurant')) {
            return false;
          }
          if (types.contains('school') || types.contains('hospital')) {
            return false;
          }
        }
        return true;
      }
    }

    // 3. Name & Subcategory inspection with strict negative keyword checks
    final String name = (place['name'] ?? '').toString().toLowerCase();
    final String subcategory = (place['subcategory'] ?? '').toString().toLowerCase();

    // Check disallowed keywords first!
    for (final disallowed in def.disallowedKeywords) {
      if (name.contains(disallowed) || subcategory.contains(disallowed)) {
        return false;
      }
    }

    // Check allowed keyword signals in name/subcategory
    if (targetId == school) {
      return name.contains('school') || subcategory.contains('school');
    } else if (targetId == college) {
      return name.contains('college') || name.contains('university') || subcategory.contains('college');
    } else if (targetId == coachingCentre) {
      return name.contains('coaching') || name.contains('tuition') || name.contains('academy') || subcategory.contains('coaching');
    } else if (targetId == hospital) {
      return name.contains('hospital') || subcategory.contains('hospital');
    } else if (targetId == clinic) {
      return name.contains('clinic') || name.contains('dispensary') || subcategory.contains('clinic');
    } else if (targetId == restaurant) {
      return name.contains('restaurant') || name.contains('dhaba') || name.contains('bistro') || subcategory.contains('restaurant');
    } else if (targetId == cafe) {
      return name.contains('cafe') || name.contains('coffee') || name.contains('bakery') || subcategory.contains('cafe');
    } else if (targetId == hotel) {
      return name.contains('hotel') || name.contains('resort') || name.contains('inn') || subcategory.contains('hotel');
    } else if (targetId == bank) {
      return name.contains('bank') || subcategory.contains('bank');
    } else if (targetId == atm) {
      return name.contains('atm') || subcategory.contains('atm');
    } else if (targetId == pharmacy) {
      return name.contains('pharmacy') || name.contains('chemist') || name.contains('medical store') || subcategory.contains('pharmacy');
    } else if (targetId == mall) {
      return name.contains('mall') || name.contains('shopping center') || name.contains('shopping centre') || subcategory.contains('mall');
    } else if (targetId == supermarket) {
      return name.contains('supermarket') || name.contains('grocery') || name.contains('bazaar') || name.contains('market');
    } else if (targetId == metroStation) {
      return name.contains('metro station') || name.contains('metro line') || subcategory.contains('metro');
    } else if (targetId == railwayStation) {
      return name.contains('railway station') || name.contains('train station');
    } else if (targetId == airport) {
      return name.contains('airport') || name.contains('aerodrome');
    } else if (targetId == temple) {
      return name.contains('temple') || name.contains('mandir');
    } else if (targetId == mosque) {
      return name.contains('mosque') || name.contains('masjid');
    } else if (targetId == church) {
      return name.contains('church');
    } else if (targetId == gym) {
      return name.contains('gym') || name.contains('fitness');
    } else if (targetId == park) {
      return name.contains('park') || name.contains('garden');
    } else if (targetId == touristAttraction) {
      return name.contains('museum') || name.contains('monument') || name.contains('sanctuary') || name.contains('tourist');
    } else if (targetId == petrolPump) {
      return name.contains('petrol') || name.contains('fuel') || name.contains('gas station');
    } else if (targetId == policeStation) {
      return name.contains('police');
    } else if (targetId == fireStation) {
      return name.contains('fire station');
    } else if (targetId == governmentOffice) {
      return name.contains('authority') || name.contains('government') || name.contains('office');
    }

    return false;
  }
}

class NearbyCategoryDefinition {
  final String id;
  final String displayName;
  final String singularName;
  final IconData icon;
  final List<String> googlePlaceTypes;
  final List<String> disallowedKeywords;
  final String description;

  const NearbyCategoryDefinition({
    required this.id,
    required this.displayName,
    required this.singularName,
    required this.icon,
    required this.googlePlaceTypes,
    required this.disallowedKeywords,
    required this.description,
  });
}

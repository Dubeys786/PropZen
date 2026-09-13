import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/nearby_category_taxonomy.dart';
import 'package:dealghar_ncr_10x/services/nearby_search_service.dart';
import 'package:dealghar_ncr_10x/services/global_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PROPZEN STRICT EXACT SEARCH & FILTERING SYSTEM TESTS', () {
    final searchService = NearbySearchService.instance;
    final globalSearch = GlobalSearchService.instance;

    // Benchmark location: Noida Sector 150 (28.4600, 77.5020)
    const double testLat = 28.4600;
    const double testLng = 77.5020;

    test('TEST 1: Search Schools Nearby -> Expected ONLY schools (NO colleges, coaching, restaurants, hospitals)', () async {
      // Validate candidate places
      final schoolPlace = {'name': 'DPS Noida', 'category': 'school', 'types': ['school']};
      final collegePlace = {'name': 'Amity University', 'category': 'college', 'types': ['university']};
      final restaurantPlace = {'name': 'Bikanervala', 'category': 'restaurant', 'types': ['restaurant']};

      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: schoolPlace, selectedCategory: 'school'), isTrue);
      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: collegePlace, selectedCategory: 'school'), isFalse);
      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: restaurantPlace, selectedCategory: 'school'), isFalse);

      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'school',
        radiusKm: 20.0,
      );

      expect(results, isNotEmpty);
      for (final place in results) {
        expect(place.category, equals('school'));
        expect(place.name.toLowerCase().contains('college'), isFalse);
        expect(place.name.toLowerCase().contains('restaurant'), isFalse);
        expect(place.name.toLowerCase().contains('hospital'), isFalse);
      }
    });

    test('TEST 2: Search Hospitals Nearby -> Expected ONLY hospitals (NO clinics unless requested)', () async {
      final hospPlace = {'name': 'Jaypee Hospital', 'category': 'hospital', 'types': ['hospital']};
      final clinicPlace = {'name': 'Dental Clinic', 'category': 'clinic', 'types': ['doctor']};

      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: hospPlace, selectedCategory: 'hospital'), isTrue);
      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: clinicPlace, selectedCategory: 'hospital'), isFalse);

      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'hospital',
        radiusKm: 20.0,
      );

      expect(results, isNotEmpty);
      for (final place in results) {
        expect(place.category, equals('hospital'));
        expect(place.name.toLowerCase().contains('clinic'), isFalse);
      }
    });

    test('TEST 3: Search Restaurants Nearby -> Expected ONLY restaurants (NO cafes)', () async {
      final restPlace = {'name': 'Barbeque Nation', 'category': 'restaurant', 'types': ['restaurant']};
      final cafePlace = {'name': 'Starbucks Cafe', 'category': 'cafe', 'types': ['cafe']};

      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: restPlace, selectedCategory: 'restaurant'), isTrue);
      expect(NearbyCategoryTaxonomy.validatePlaceCategory(place: cafePlace, selectedCategory: 'restaurant'), isFalse);

      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'restaurant',
        radiusKm: 30.0,
      );

      expect(results, isNotEmpty);
      for (final place in results) {
        expect(place.category, equals('restaurant'));
      }
    });

    test('TEST 4: Search Metro Nearby -> Expected ONLY metro stations', () async {
      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'metro_station',
        radiusKm: 30.0,
      );

      expect(results, isNotEmpty);
      for (final place in results) {
        expect(place.category, equals('metro_station'));
        expect(place.name.toLowerCase().contains('metro'), isTrue);
      }
    });

    test('TEST 5: Search Home Loan -> Expected Home Loan tool intent', () {
      final items = globalSearch.search('Home Loan');
      expect(items, isNotEmpty);
      final topItem = items.first;
      expect(topItem.title, contains('Home Loan'));
    });

    test('TEST 6: Search Dashboard -> Expected Dashboard intent', () {
      final items = globalSearch.search('Dashboard');
      expect(items, isNotEmpty);
      final topItem = items.first;
      expect(topItem.title, equals('Dashboard'));
    });

    test('TEST 7: Search Loan Calculator -> Expected EMI / Loan Calculator intent', () {
      final items = globalSearch.search('Loan Calculator');
      expect(items, isNotEmpty);
      final topItem = items.first;
      expect(topItem.title, contains('Calculator'));
    });

    test('TEST 8: School search with zero results -> Expected empty list, NO unrelated places fallback', () async {
      // Search with impossible radius (e.g. 0.01 km)
      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'school',
        radiusKm: 0.01,
      );

      // Must be empty, with zero contamination
      expect(results, isEmpty);
    });

    test('TEST 9: School + 5 km -> Expected ONLY schools within 5 km', () async {
      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'school',
        radiusKm: 5.0,
      );

      for (final place in results) {
        expect(place.category, equals('school'));
        expect(place.distanceKm, lessThanOrEqualTo(5.0));
      }
    });

    test('TEST 10: School + 4+ rating -> Expected ONLY schools within radius having rating >= 4', () async {
      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'school',
        radiusKm: 20.0,
        minRating: 4.0,
      );

      for (final place in results) {
        expect(place.category, equals('school'));
        expect(place.rating, greaterThanOrEqualTo(4.0));
      }
    });

    test('TEST 11 & 12: Distance sorting -> Nearest to Farthest', () async {
      final results = await searchService.searchNearbyPlaces(
        latitude: testLat,
        longitude: testLng,
        category: 'school',
        radiusKm: 20.0,
      );

      if (results.length > 1) {
        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].distanceKm, lessThanOrEqualTo(results[i + 1].distanceKm));
        }
      }
    });
  });
}

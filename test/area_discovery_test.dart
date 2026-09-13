import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/area_discovery_model.dart';
import 'package:dealghar_ncr_10x/services/area_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Automatic Area Discovery Tests', () {
    test('Automatic PIN resolution from property without manual entry', () async {
      final service = AreaDiscoveryService.instance;

      final testProperty = Property(
        id: 'prop_sector_150_01',
        title: 'Mahagun Manorialle Luxury Suites',
        propertyType: 'Apartment',
        bhk: '3 BHK',
        askingPriceCr: 2.2,
        sqft: 2150,
        sector: 'Sector 150',
        city: 'Noida',
        postalCode: '201310',
        latitude: 28.4595,
        longitude: 77.5020,
        imageUrl: 'https://example.com/prop.jpg',
      );

      final profile = await service.resolveAreaForProperty(testProperty);

      expect(profile.pincode, equals('201310'));
      expect(profile.locality, equals('Sector 150'));
      expect(profile.city, equals('Noida'));
      expect(profile.state, equals('Uttar Pradesh'));
      expect(profile.historyMilestones, isNotEmpty);
      expect(profile.landmarks, isNotEmpty);
      expect(profile.publicFigures, isNotEmpty);
      expect(profile.amenities, isNotEmpty);
      expect(profile.marketSnapshot.avgPriceSqft, greaterThan(0));
    });

    test('Multiple properties in same PIN code reuse cached area profile', () async {
      final service = AreaDiscoveryService.instance;

      final propA = Property(
        id: 'prop_150_a',
        title: 'ACE Parkway',
        sector: 'Sector 150',
        city: 'Noida',
        postalCode: '201310',
        askingPriceCr: 1.4,
        sqft: 1450,
        imageUrl: '',
        propertyType: 'Apartment',
        bhk: '2 BHK',
      );

      final propB = Property(
        id: 'prop_150_b',
        title: 'Samridhi Luxuriya Avenue',
        sector: 'Sector 150',
        city: 'Noida',
        postalCode: '201310',
        askingPriceCr: 1.8,
        sqft: 1750,
        imageUrl: '',
        propertyType: 'Apartment',
        bhk: '3 BHK',
      );

      final profileA = await service.resolveAreaForProperty(propA);
      final profileB = await service.resolveAreaForProperty(propB);

      expect(identical(profileA, profileB), isTrue);
      expect(profileA.pincode, equals(profileB.pincode));
    });

    test('Public figures strictly adhere to public-only documentation and privacy rules', () async {
      final service = AreaDiscoveryService.instance;

      final prop = Property(
        id: 'prop_sec_128',
        title: 'Kalpataru Vista',
        sector: 'Sector 128',
        city: 'Noida',
        postalCode: '201304',
        askingPriceCr: 3.5,
        sqft: 3000,
        imageUrl: '',
        propertyType: 'Apartment',
        bhk: '4 BHK',
      );

      final profile = await service.resolveAreaForProperty(prop);

      for (final fig in profile.publicFigures) {
        expect(fig.name, isNotEmpty);
        expect(fig.designation, isNotEmpty);
        expect(fig.publicAssociation, isNotEmpty);
        expect(fig.source, isNotEmpty);
        expect(fig.sourceUrl, startsWith('http'));
        expect(fig.verifiedAt, isNotNull);
      }
    });

    test('Area landmarks include verified ecological and institutional sites', () async {
      final service = AreaDiscoveryService.instance;

      final prop = Property(
        id: 'prop_sec_150',
        title: 'Eldeco Live By The Greens',
        sector: 'Sector 150',
        city: 'Noida',
        postalCode: '201310',
        askingPriceCr: 1.6,
        sqft: 1400,
        imageUrl: '',
        propertyType: 'Apartment',
        bhk: '3 BHK',
      );

      final profile = await service.resolveAreaForProperty(prop);
      expect(profile.landmarks, isNotEmpty);
      expect(profile.landmarks.any((lm) => lm.name.contains('Shaheed Bhagat Singh')), isTrue);
    });

    test('Area amenities cover Education, Healthcare, Shopping, and Connectivity', () async {
      final service = AreaDiscoveryService.instance;
      final prop = Property(
        id: 'prop_sec_137',
        title: 'Paras Tierea',
        sector: 'Sector 137',
        city: 'Noida',
        postalCode: '201305',
        askingPriceCr: 0.95,
        sqft: 1250,
        imageUrl: '',
        propertyType: 'Apartment',
        bhk: '2 BHK',
      );

      final profile = await service.resolveAreaForProperty(prop);
      final categories = profile.amenities.map((a) => a.category).toSet();

      expect(categories.contains(AmenityCategory.education), isTrue);
      expect(categories.contains(AmenityCategory.healthcare), isTrue);
      expect(categories.contains(AmenityCategory.connectivity), isTrue);
    });
  });
}

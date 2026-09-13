import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/config/maps_config.dart';
import 'package:dealghar_ncr_10x/screens/location_picker_screen.dart';

void main() {
  group('Real Google Maps & Property Location Integration Tests', () {
    test('1. All sample properties have valid NCR coordinates & addresses', () {
      final properties = Property.sampleDeals;
      expect(properties.length, greaterThanOrEqualTo(12));

      for (final p in properties) {
        expect(p.latitude, isNot(0.0));
        expect(p.longitude, isNot(0.0));
        expect(p.latitude, inInclusiveRange(28.0, 29.0), reason: 'Latitude should be in NCR region');
        expect(p.longitude, inInclusiveRange(76.5, 77.8), reason: 'Longitude should be in NCR region');
        expect(p.fullAddress, isNotEmpty);
        expect(p.effectiveLocality, isNotEmpty);
        expect(p.postalCode, isNotEmpty);
      }
    });

    test('2. Key sample properties match required locality coordinates', () {
      final ats = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      expect(ats.city, equals('Noida Extension'));
      expect(ats.latitude, closeTo(28.6012, 0.01));
      expect(ats.longitude, closeTo(77.4421, 0.01));

      final gaurCity = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');
      expect(gaurCity.city, equals('Noida Extension'));
      expect(gaurCity.latitude, closeTo(28.6085, 0.01));
      expect(gaurCity.longitude, closeTo(77.4298, 0.01));

      final ace = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ace_divino');
      expect(ace.sector, equals('Sector 1, Noida Extension'));
      expect(ace.latitude, closeTo(28.6140, 0.01));
      expect(ace.longitude, closeTo(77.4520, 0.01));

      final tata = Property.sampleDeals.firstWhere((p) => p.id == 'prop_tata_eureka_150');
      expect(tata.sector, equals('Sector 150'));
      expect(tata.city, equals('Noida'));
      expect(tata.latitude, closeTo(28.4380, 0.01));
      expect(tata.longitude, closeTo(77.4850, 0.01));

      final advant = Property.sampleDeals.firstWhere((p) => p.id == 'prop_advant_navis');
      expect(advant.sector, equals('Sector 142'));
      expect(advant.city, equals('Noida'));
      expect(advant.latitude, closeTo(28.4980, 0.01));
      expect(advant.longitude, closeTo(77.4180, 0.01));
    });

    test('3. Property JSON / Map serialization preserves location fields for n8n/database backend', () {
      const original = Property(
        id: 'prop_custom_101',
        title: 'Cyber Greens Tower',
        sector: 'Sector 62',
        city: 'Noida',
        locality: 'Sector 62',
        address: 'Plot A-42, Institutional Area, Sector 62, Noida, UP',
        postalCode: '201309',
        placeId: 'ChIJ_cyber_greens_62',
        latitude: 28.6258,
        longitude: 77.3639,
        category: 'Commercial',
        propertyType: 'Office Space',
        askingPriceCr: 4.5,
        fairValueCr: 4.8,
        pricePerSqft: 9000,
        score10x: 9.3,
        rentalYieldPercent: 7.2,
        sqft: 5000,
        bhk: 'Commercial',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=600&q=80',
      );

      final map = original.toMap();
      expect(map['latitude'], equals(28.6258));
      expect(map['longitude'], equals(77.3639));
      expect(map['address'], equals('Plot A-42, Institutional Area, Sector 62, Noida, UP'));
      expect(map['postalCode'], equals('201309'));
      expect(map['placeId'], equals('ChIJ_cyber_greens_62'));
      expect(map['locality'], equals('Sector 62'));

      final reconstructed = Property.fromMap(map);
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.latitude, equals(original.latitude));
      expect(reconstructed.longitude, equals(original.longitude));
      expect(reconstructed.address, equals(original.address));
      expect(reconstructed.postalCode, equals(original.postalCode));
      expect(reconstructed.placeId, equals(original.placeId));
      expect(reconstructed.effectiveLocality, equals(original.effectiveLocality));
    });

    test('4. LocationResult encapsulates location picker confirmed payload', () {
      const result = LocationResult(
        latitude: 28.4354,
        longitude: 77.4878,
        address: 'Sector 150, Noida-Greater Noida Expressway, UP',
        city: 'Noida',
        locality: 'Sector 150',
        postalCode: '201310',
        placeId: 'loc_custom_123',
      );

      expect(result.latitude, equals(28.4354));
      expect(result.longitude, equals(77.4878));
      expect(result.city, equals('Noida'));
      expect(result.locality, equals('Sector 150'));
      expect(result.postalCode, equals('201310'));
    });

    test('5. MapsConfig contains default NCR center and locality registry', () {
      expect(MapsConfig.defaultLatitude, inInclusiveRange(28.0, 29.0));
      expect(MapsConfig.defaultLongitude, inInclusiveRange(76.5, 77.8));
      expect(MapsConfig.ncrLocalities.length, greaterThanOrEqualTo(10));
      expect(MapsConfig.lightMapStyle, contains('featureType'));
      expect(MapsConfig.darkMapStyle, contains('featureType'));
    });
  });
}

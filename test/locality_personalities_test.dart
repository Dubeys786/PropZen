import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/locality_personality.dart';
import 'package:dealghar_ncr_10x/models/property.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart 3-Level Locality Hierarchy & Data Isolation Tests', () {
    test('1. Haversine distance formula mathematical correctness', () {
      final dist = LocalityPersonalityRegistry.calculateDistanceKm(28.6315, 77.2167, 28.6129, 77.2295);
      expect(dist, greaterThan(2.0));
      expect(dist, lessThan(2.8));
    });

    test('2. Property A (ATS Happy Trails: Sector 10 GN West) matches Level 1 Personalities, Level 2 Society RWA, and Level 3 Governance', () {
      final prop = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      final result = LocalityPersonalityRegistry.getLocalInformationForProperty(prop);

      expect(result.hasAnyInformation, isTrue);

      // Level 1: Notable Personalities within 5 KM
      expect(result.notablePersonalities.any((p) => p.name.contains('Tejpal Singh Nagar')), isTrue);
      expect(result.notablePersonalities.any((p) => p.name.contains('Deepak Malik')), isTrue);

      // Level 2: Society-Specific RWA (Col. Sanjeev Tyagi, Pooja Sharma)
      expect(result.communityRwa.any((p) => p.name.contains('Sanjeev Tyagi') && p.societyOrArea.contains('ATS Happy Trails')), isTrue);
      expect(result.communityRwa.any((p) => p.name.contains('Pooja Sharma')), isTrue);

      // MUST NOT contain RWA of an unrelated society (e.g. Tata Eureka Park or Gaur City)
      expect(result.communityRwa.any((p) => p.societyOrArea.contains('Tata Eureka Park')), isFalse);
      expect(result.communityRwa.any((p) => p.societyOrArea.contains('Gaur City')), isFalse);

      // Level 3: Local Governance
      expect(result.localGovernance.any((p) => p.name.contains('Geeta Bhati')), isTrue);

      // Verify Available Tabs
      expect(result.availableTabLabels.contains('Nearby Personalities'), isTrue);
      expect(result.availableTabLabels.contains('Community & RWA'), isTrue);
      expect(result.availableTabLabels.contains('Local Governance'), isTrue);
    });

    test('3. Property B (Tata Eureka Park: Sector 150) matches Tata Eureka Park RWA and Noida Authority Ward 14', () {
      final prop = Property.sampleDeals.firstWhere((p) => p.id == 'prop_tata_eureka_150');
      final result = LocalityPersonalityRegistry.getLocalInformationForProperty(prop);

      // Level 1: Personalities (Gaurav Taneja, Dr. Mahesh Sharma, Pankaj Singh)
      expect(result.notablePersonalities.any((p) => p.name.contains('Gaurav Taneja')), isTrue);
      expect(result.notablePersonalities.any((p) => p.name.contains('Dr. Mahesh Sharma')), isTrue);

      // Level 2: Society RWA (Tata Eureka Park AoA President Cdr. Rajeshwar Rao)
      expect(result.communityRwa.any((p) => p.name.contains('Rajeshwar Rao') && p.societyOrArea.contains('Tata Eureka Park')), isTrue);

      // MUST NOT contain ATS Happy Trails RWA
      expect(result.communityRwa.any((p) => p.societyOrArea.contains('ATS Happy Trails')), isFalse);

      // Level 3: Local Governance (Noida Authority Ward 14)
      expect(result.localGovernance.any((p) => p.name.contains('Virendra Singh Dadwal')), isTrue);
    });

    test('4. Property C (DLF The Crest: Gurugram) matches Gurugram Personalities and MCG Ward Councillor', () {
      const prop = Property(
        id: 'prop_dlf_crest',
        title: 'DLF The Crest',
        sector: 'Sector 54, Golf Course Road',
        city: 'Gurugram',
        latitude: 28.4350,
        longitude: 77.1050,
        askingPriceCr: 7.5,
      );

      final result = LocalityPersonalityRegistry.getLocalInformationForProperty(prop);

      // Level 1: Deepinder Goyal, Rao Inderjit Singh, Gaurav Chaudhary
      expect(result.notablePersonalities.any((p) => p.name.contains('Deepinder Goyal')), isTrue);
      expect(result.notablePersonalities.any((p) => p.name.contains('Gaurav Chaudhary')), isTrue);

      // Level 3: MCG Ward 34 Councillor (Sunita Yadav)
      expect(result.localGovernance.any((p) => p.name.contains('Sunita Yadav') && p.applicableJurisdiction.contains('MCG')), isTrue);

      // MUST NOT contain Noida or Greater Noida RWA
      expect(result.communityRwa.any((p) => p.societyOrArea.contains('ATS Happy Trails')), isFalse);
    });

    test('5. Remote Outlying Property returns 0 records and hasAnyInformation is false', () {
      const remoteProp = Property(
        id: 'prop_remote_99',
        title: 'Remote Outlying Land',
        sector: 'Outlying Sector',
        city: 'Remote Region',
        latitude: 29.8000,
        longitude: 78.9000,
        askingPriceCr: 1.0,
      );

      final result = LocalityPersonalityRegistry.getLocalInformationForProperty(remoteProp);
      expect(result.hasAnyInformation, isFalse);
      expect(result.allCombined, isEmpty);
      expect(result.availableTabLabels, isEmpty);
    });
  });
}

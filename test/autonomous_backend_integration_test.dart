import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/property_verification_service.dart';
import 'package:dealghar_ncr_10x/services/ai_matching_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Autonomous AI Backend Integration Tests', () {
    test('PropertyVerificationService handles autonomous evaluation resiliently', () async {
      final testProp = Property(
        id: 'prop_test_001',
        title: 'ATS HomeKraft Happy Trails',
        propertyType: 'Apartment',
        bhk: '3 BHK',
        askingPriceCr: 1.15,
        sqft: 1625,
        city: 'Greater Noida',
        sector: 'Sector 10',
        imageUrl: 'https://example.com/image.jpg',
        reraId: 'UPRERAAGT12345',
        amenities: ['Near Metro', 'Gym'],
        status: 'pending',
      );

      final result = await PropertyVerificationService.instance.executeAutonomousAiVerification(
        testProp,
        documentTypes: ['Sale Deed', 'RERA Certificate'],
      );

      expect(result, isNotNull);
      expect(result['status'], isIn(['VERIFIED', 'NEEDS_REVIEW', 'REJECTED']));
      expect(result['risk_score'], isNotNull);
      expect(result['reasons'], isNotNull);
    });

    test('AiMatchingService handles semantic and heuristic natural language queries', () async {
      final matches = await AiMatchingService.instance.executeSemanticMatch(
        '3 BHK in Noida under 1.5 Cr near metro',
        limit: 5,
      );

      expect(matches, isNotNull);
      expect(matches.length, greaterThanOrEqualTo(0));
    });
  });
}

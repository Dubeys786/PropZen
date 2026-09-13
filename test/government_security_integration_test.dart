import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/government_verification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Secure Government API & Envelope Encryption Gateway Tests', () {
    test('Land record lookup fails closed with AWAITING_OFFICIAL_API_ACCESS when access is pending', () async {
      final res = await GovernmentVerificationService.instance.verifyLandRecord(
        userId: 'usr_test_999',
        state: 'Uttar Pradesh',
        district: 'Gautam Buddha Nagar',
        village: 'Noida',
        khasraNumber: '142-B',
      );

      expect(res.verificationStatus, equals('AWAITING_OFFICIAL_API_ACCESS'));
      expect(res.isOfficialApiActive, isFalse);
      expect(res.maskedIdentifier, contains('KH-XXXX'));
      expect(res.disclaimer, isNotEmpty);
    });

    test('eCourts lookup fails closed with AWAITING_OFFICIAL_API_ACCESS when API access is unapproved', () async {
      final res = await GovernmentVerificationService.instance.verifyCourtRecord(
        userId: 'usr_test_999',
        cnrNumber: 'UPGB010099992026',
        courtComplex: 'District Court Gautam Buddha Nagar',
      );

      expect(res.verificationStatus, equals('AWAITING_OFFICIAL_API_ACCESS'));
      expect(res.isOfficialApiActive, isFalse);
      expect(res.maskedIdentifier, contains('UPGB****2026'));
    });
  });
}

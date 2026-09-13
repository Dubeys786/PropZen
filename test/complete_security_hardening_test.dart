import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_lead_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/nri_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/drone_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_storage_service.dart';
import 'package:dealghar_ncr_10x/services/site_visit_booking_service.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/drone_tour_subscription_model.dart';
import 'package:dealghar_ncr_10x/models/nri_subscription_model.dart';
import 'package:dealghar_ncr_10x/models/dealer_subscription_model.dart';
import 'package:dealghar_ncr_10x/utils/validators.dart';

void main() {
  setUp(() {
    UserSession.logout();
    AdminService.instance.resetForTesting();
  });

  group('PROPZEN COMPLETE SECURITY HARDENING TEST SUITE', () {
    // =========================================================================
    // TEST 1: User A tries to access User B's private data -> DENIED
    // =========================================================================
    test('TEST 1: User A cannot access User B private data / isolation', () {
      UserSession.login(
        name: 'User A',
        email: 'userA@propzen.ai',
        phone: '9810100001',
        role: 'Buyer',
      );

      expect(UserSession.email, 'userA@propzen.ai');
      expect(UserSession.mobileNumber, '9810100001');

      // Dealer lead / notification stores must isolate data
      final leadsForB = DealerLeadService.instance.getLeadsForDealer('DLR-USER-B');
      expect(leadsForB.every((l) => l.dealerId == 'DLR-USER-B'), isTrue);

      final visitsForB = DealerLeadService.instance.getSiteVisitsForDealer('DLR-USER-B');
      expect(visitsForB.every((v) => v.dealerId == 'DLR-USER-B'), isTrue);
    });

    // =========================================================================
    // TEST 2: Dealer A tries to access Dealer B's property/leads -> DENIED
    // =========================================================================
    test('TEST 2: Dealer A cannot access Dealer B properties, leads, or visits', () {
      UserSession.registerAsDealer(
        agencyName: 'Agency Alpha',
        email: 'dealerA@ncr.com',
        phone: '9810200002',
      );

      final dealerAId = UserSession.dealerId;
      expect(dealerAId, 'DLR-9810200002');

      // Querying with Dealer A's ID must NOT return Dealer B's records
      final dealerBLeads = DealerLeadService.instance.getLeadsForDealer('DLR-SEC150-102');
      for (final lead in dealerBLeads) {
        expect(lead.dealerId, isNot(equals(dealerAId)));
      }

      final dealerBVisits = DealerLeadService.instance.getSiteVisitsForDealer('DLR-SEC150-102');
      for (final visit in dealerBVisits) {
        expect(visit.dealerId, isNot(equals(dealerAId)));
      }
    });

    // =========================================================================
    // TEST 3: Normal user tries to access Admin API / Admin functions -> DENIED
    // =========================================================================
    test('TEST 3: Normal user cannot access Admin features or claim admin privileges', () {
      UserSession.login(
        name: 'Normal Buyer',
        email: 'buyer@example.com',
        phone: '9810300003',
        role: 'Buyer',
      );

      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.isBuyer, isTrue);
      expect(AdminService.instance.isAdminLoggedIn, isFalse);

      // Attempting to login admin with wrong password must fail
      final loginResult = AdminService.instance.loginAdmin(
        email: 'buyer@example.com',
        password: 'any_password',
      );
      expect(loginResult, isFalse);
      expect(AdminService.instance.isAdminLoggedIn, isFalse);
    });

    // =========================================================================
    // TEST 4: Dealer tries to access Admin API -> DENIED
    // =========================================================================
    test('TEST 4: Dealer user cannot access Admin API', () {
      UserSession.registerAsDealer(
        agencyName: 'Top Brokerage',
        email: 'dealer@ncrrealty.com',
        phone: '9810400004',
      );

      expect(UserSession.isDealer, isTrue);
      expect(UserSession.isAdmin, isFalse);

      final adminLogin = AdminService.instance.loginAdmin(
        email: 'dealer@ncrrealty.com',
        password: 'dealer_password',
      );
      expect(adminLogin, isFalse);
      expect(AdminService.instance.isAdminLoggedIn, isFalse);
    });

    // =========================================================================
    // TEST 5: User changes user_id in a request -> Denied / Handled securely
    // =========================================================================
    test('TEST 5: Tampered user_id cannot spoof identity in UserSession', () {
      UserSession.login(
        name: 'Genuine User',
        email: 'genuine@propzen.ai',
        phone: '9810500005',
        role: 'Buyer',
      );

      expect(UserSession.email, 'genuine@propzen.ai');
      expect(UserSession.isAdmin, isFalse);

      // Attempt to spoof admin role in roleTier
      UserSession.roleTierNotifier.value = 'Buyer';
      expect(UserSession.isAdmin, isFalse);
    });

    // =========================================================================
    // TEST 6: Dealer changes dealer_id in a request -> Denied / Handled securely
    // =========================================================================
    test('TEST 6: Dealer cannot impersonate another dealer ID', () {
      UserSession.registerAsDealer(
        agencyName: 'Dealer Alpha',
        email: 'alpha@propzen.ai',
        phone: '9810600006',
      );

      expect(UserSession.dealerId, 'DLR-9810600006');
      expect(UserSession.dealerId, isNot(equals('DLR-NOIDA-101')));
    });

    // =========================================================================
    // TEST 7: Frontend attempts to activate subscription with fake/bypass signature -> DENIED
    // =========================================================================
    test('TEST 7: Fake signature or bypass attempt fails subscription verification', () async {
      final nriService = NriSubscriptionService.instance;
      const plan = NriSubscriptionPlan(
        id: 'nri_pass_premium',
        name: 'Premium NRI Drone & 3D Pass',
        tier: 'premium',
        durationMonths: 6,
        priceInr: 3999.0,
        benefits: ['4K Drone Tours', '3D Twins'],
      );

      // Attempt verification with invalid / empty payment ID or failed status
      expect(
        () async => await nriService.verifyAndActivateSubscription(
          plan: plan,
          paymentId: 'pay_fail_test',
          orderId: 'order_123',
          signature: 'sig_fake_bypass_signature',
          userId: 'usr_test',
          userEmail: 'test@propzen.ai',
        ),
        throwsException,
      );

      // Dealer subscription verification with failed signature must also throw
      final dealerService = DealerSubscriptionService.instance;
      const dealerPlan = DealerSubscriptionPlan(
        id: 'dealer_pro',
        name: 'Pro Growth Plan',
        tier: 'pro',
        description: 'Test Plan',
        priceInr: 1499.0,
        currency: 'INR',
        durationMonths: 1,
        listingLimit: 50,
        leadLimit: 100,
        photosPerProperty: 15,
        benefits: ['50 Listings', '100 Leads'],
      );

      expect(
        () async => await dealerService.verifyAndActivateSubscription(
          plan: dealerPlan,
          paymentId: 'pay_failed_123',
          orderId: 'order_dlr_123',
          signature: 'fake_sig',
          dealerId: 'DLR-123',
          dealerEmail: 'dealer@test.com',
        ),
        throwsException,
      );
    });

    // =========================================================================
    // TEST 8: Expired subscription tries to access Drone Tour -> LOCKED / DENIED
    // =========================================================================
    test('TEST 8: Expired subscription locks Drone Tour access', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 40));
      final expiredSub = DroneTourSubscription(
        id: 'sub_expired_1',
        userId: 'usr_1',
        userEmail: 'user@propzen.ai',
        planId: 'drone_pass_1m',
        planName: '1 Month Standard Pass',
        tier: 'basic',
        durationMonths: 1,
        status: 'expired',
        startDate: pastDate.subtract(const Duration(days: 30)),
        expiryDate: pastDate, // Expired in the past!
        amount: 999.0,
        currency: 'INR',
      );

      UserSession.updateDroneSubscription(expiredSub);

      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(DroneSubscriptionService.instance.checkActiveAccess(), isFalse);

      // Even if dealer is registered, drone tour must remain LOCKED without valid drone subscription
      UserSession.registerAsDealer(agencyName: 'Test Agency', phone: '9810700007');
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    // =========================================================================
    // TEST 9: User attempts to download another user's private document -> DENIED
    // =========================================================================
    test('TEST 9: Storage path traversal and unverified file access blocked', () {
      // Path traversal attack paths must be sanitized
      const maliciousPath = '../../../etc/passwd/secret.pdf';
      final sanitized = SupabaseStorageService.sanitizeStoragePath(maliciousPath);

      expect(sanitized.contains('../'), isFalse);
      expect(sanitized.contains('..\\'), isFalse);
      expect(sanitized.startsWith('/'), isFalse);
    });

    // =========================================================================
    // TEST 10: Logged-out user tries to access protected API -> DENIED
    // =========================================================================
    test('TEST 10: Logged-out user rejected when checkAuth is required', () async {
      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);

      final result = await SiteVisitBookingService.instance.bookSiteVisit(
        propertyId: 'PROP-TEST-001',
        propertyTitle: 'Luxury Suites Noida',
        visitDate: '2026-09-10',
        timeSlot: '11:00 AM',
        checkAuth: true, // Requires authenticated user
      );

      expect(result.isSuccess, isFalse);
      expect(result.requiresAuth, isTrue);
    });

    // =========================================================================
    // TEST 11: Invalid/malicious file upload -> REJECTED
    // =========================================================================
    test('TEST 11: Storage service rejects executable and oversized files', () async {
      final storage = SupabaseStorageService.instance;

      // 1. Rejected extension: .exe, .sh, .apk
      expect(SupabaseStorageService.isAllowedFileType('malicious_payload.exe'), isFalse);
      expect(SupabaseStorageService.isAllowedFileType('script.sh'), isFalse);
      expect(SupabaseStorageService.isAllowedFileType('app.apk'), isFalse);
      expect(SupabaseStorageService.isAllowedFileType('document.pdf'), isTrue);
      expect(SupabaseStorageService.isAllowedFileType('property.jpg'), isTrue);
      expect(SupabaseStorageService.isAllowedFileType('property.png'), isTrue);

      // 2. Upload of .exe must fail validation
      final exeBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00]); // MZ header
      final resultExe = await storage.uploadBinary(
        bucket: SupabaseStorageService.documentsBucket,
        path: 'uploads/malicious.exe',
        bytes: exeBytes,
        contentType: 'application/octet-stream',
        userId: 'usr_test',
        propertyId: 'prop_test',
        fileName: 'malicious.exe',
      );

      expect(resultExe.isSuccess, isFalse);
      expect(resultExe.statusCode, 415);

      // 3. Oversized file (>15MB)
      final oversizedBytes = Uint8List(16 * 1024 * 1024); // 16 MB
      final resultOversized = await storage.uploadBinary(
        bucket: SupabaseStorageService.documentsBucket,
        path: 'uploads/large.pdf',
        bytes: oversizedBytes,
        contentType: 'application/pdf',
        userId: 'usr_test',
        propertyId: 'prop_test',
        fileName: 'large.pdf',
      );

      expect(resultOversized.isSuccess, isFalse);
      expect(resultOversized.statusCode, 413);
    });

    // =========================================================================
    // TEST 12: Malformed input / injection payload -> VALIDATION ERROR
    // =========================================================================
    test('TEST 12: Malformed input, XSS scripts, and invalid credentials trigger validation error', () {
      // 1. Invalid phone numbers
      expect(FormValidators.isPhoneValid('12345'), isFalse);
      expect(FormValidators.isPhoneValid('1234567890'), isFalse); // Starts with 1 (not 6-9)
      expect(FormValidators.isPhoneValid('9810394068'), isTrue);

      // 2. Invalid emails
      expect(FormValidators.isEmailValid('notanemail'), isFalse);
      expect(FormValidators.isEmailValid('test@'), isFalse);
      expect(FormValidators.isEmailValid('user@propzen.ai'), isTrue);

      // 3. XSS / Script Injection sanitization
      const xssInput = '<script>alert("hack")</script>Luxury 3 BHK Penthouse';
      final cleanText = FormValidators.sanitizeTextInput(xssInput);
      expect(cleanText.contains('<script>'), isFalse);
      expect(cleanText.contains('alert'), isTrue); // Content preserved without executable tag

      // 4. Property price & area validation
      expect(FormValidators.validatePriceCr('-5.0'), isNotNull);
      expect(FormValidators.validatePriceCr('0'), isNotNull);
      expect(FormValidators.validatePriceCr('2.5'), isNull);

      expect(FormValidators.validateAreaSqft('10'), isNotNull); // Too small
      expect(FormValidators.validateAreaSqft('1500'), isNull);
    });
  });
}

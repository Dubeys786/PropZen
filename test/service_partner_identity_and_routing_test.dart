import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/models/service_partner_profile.dart';
import 'package:dealghar_ncr_10x/models/service_request_model.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/services/service_partner_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/service_partner_status_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partner_access_denied_screen.dart';
import 'package:dealghar_ncr_10x/widgets/service_partner_route_guard.dart';

final Uint8List _kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  bool followRedirects = true;
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool? preserveHeaderCase}) {}
  @override
  void set(String name, Object value, {bool? preserveHeaderCase}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UserSession.logout();
  });

  group('Service Partner Identity & Specialization Routing Tests', () {
    test('1. Specialization resolved strictly from profile, NOT email heuristics', () async {
      // Even if email contains 'loan' or 'partner', if the database profile says 'HOME_DESIGN',
      // it must resolve to HOME_DESIGN and route to homeDesignPartnerPortal!
      final profile = ServicePartnerProfile(
        id: 'SP-TEST-001',
        userId: 'usr_test_design',
        businessName: 'Creative Design Studio',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'john.loan.expert@domain.com', // Contains 'loan', but category is HOME_DESIGN!
      );

      UserSession.login(
        userId: profile.userId,
        name: profile.businessName,
        email: profile.email,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(profile);

      expect(UserSession.isServicePartner, isTrue);
      expect(profile.primaryCategory, equals(ServiceCategoryType.homeDesign));

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.homeDesignPartnerPortal));
      expect(destination, isNot(equals(AppRoutes.loanPartnerPortal)));
    });

    test('2. Designated Admin email immunity remains strictly ADMIN', () async {
      UserSession.login(
        userId: 'usr_admin',
        name: 'Sakshi Admin',
        email: UserSession.designatedAdminEmail, // dubeysakshi618@gmail.com
        role: 'ADMIN',
        isEmailVerified: true,
      );

      expect(UserSession.isAdmin, isTrue);
      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.admin));
    });

    test('3. Pending Service Partner application routes to status gate and has 0 requests', () async {
      final pendingProfile = ServicePartnerProfile(
        id: 'SP-PENDING-001',
        userId: 'usr_applicant_01',
        businessName: 'Aura Interiors',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'PENDING',
        status: 'PENDING',
        email: 'applicant@aurainteriors.com',
      );

      UserSession.login(
        userId: pendingProfile.userId,
        name: pendingProfile.businessName,
        email: pendingProfile.email,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(pendingProfile);

      expect(pendingProfile.isApproved, isFalse);
      expect(pendingProfile.isPending, isTrue);

      // Must route to status screen, NOT to any partner dashboard
      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.servicePartnerStatus));

      // Content Isolation: loadForProfile on unapproved partner must yield 0 requests
      await ServicePartnerService.instance.loadForProfile(pendingProfile);
      final requests = ServicePartnerService.instance.getRequestsForPartner(pendingProfile.id);
      expect(requests, isEmpty);

      final available = ServicePartnerService.instance.getAvailableRequestsForCategory(
        category: ServiceCategoryType.homeDesign,
        currentPartnerId: pendingProfile.id,
      );
      expect(available, isEmpty);
    });

    test('4. Suspended partner routes to status gate and has 0 live requests', () async {
      final suspendedProfile = ServicePartnerProfile(
        id: 'SP-SUSPENDED-001',
        userId: 'usr_suspended_01',
        businessName: 'Old Apex Builders',
        serviceCategory: 'CONSTRUCTION',
        serviceCategories: ['CONSTRUCTION'],
        verificationStatus: 'SUSPENDED',
        status: 'SUSPENDED',
        email: 'contact@oldapex.com',
      );

      UserSession.login(
        userId: suspendedProfile.userId,
        name: suspendedProfile.businessName,
        email: suspendedProfile.email,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(suspendedProfile);

      expect(suspendedProfile.isApproved, isFalse);
      expect(suspendedProfile.isSuspended, isTrue);

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.servicePartnerStatus));

      await ServicePartnerService.instance.loadForProfile(suspendedProfile);
      final requests = ServicePartnerService.instance.getRequestsForPartner(suspendedProfile.id);
      expect(requests, isEmpty);
    });

    test('5. Missing specialization routes to status gate and NEVER defaults to Loan Partner', () async {
      final unassignedProfile = ServicePartnerProfile(
        id: 'SP-NO-CAT-001',
        userId: 'usr_nocat_01',
        businessName: 'Unassigned Partner Ltd',
        serviceCategory: '', // Empty specialization
        serviceCategories: [],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'unassigned@partner.com',
      );

      UserSession.login(
        userId: unassignedProfile.userId,
        name: unassignedProfile.businessName,
        email: unassignedProfile.email,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(unassignedProfile);

      expect(unassignedProfile.hasSpecialization, isFalse);
      expect(unassignedProfile.approvedCategoryTypes, isEmpty);

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.servicePartnerStatus));
      expect(destination, isNot(equals(AppRoutes.loanPartnerPortal)));
    });

    test('6. Multi-service approved partner routes to Select Service Portal', () async {
      final multiProfile = ServicePartnerProfile(
        id: 'SP-MULTI-001',
        userId: 'usr_multi_01',
        businessName: 'Prime Design & Construction',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN', 'CONSTRUCTION'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'multi@primeconsortium.com',
      );

      UserSession.login(
        userId: multiProfile.userId,
        name: multiProfile.businessName,
        email: multiProfile.email,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(multiProfile);

      expect(multiProfile.isApproved, isTrue);
      expect(multiProfile.approvedCategoryTypes.length, equals(2));

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.selectServicePortal));
    });

    test('7. Customer Request Isolation: Home Design partner only sees Home Design requests', () async {
      // Save Home Design and Loan partner profiles
      final designPartner = ServicePartnerProfile(
        id: 'SP-DESIGN-ISO-01',
        userId: 'usr_iso_design',
        businessName: 'Studio Iso Design',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'iso.design@test.com',
      );

      final loanPartner = ServicePartnerProfile(
        id: 'SP-LOAN-ISO-01',
        userId: 'usr_iso_loan',
        businessName: 'Capital Fast Loans',
        serviceCategory: 'LOAN',
        serviceCategories: ['LOAN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'iso.loans@test.com',
      );

      // Verify canProvide isolation logic
      expect(designPartner.canProvide(ServiceCategoryType.homeDesign), isTrue);
      expect(designPartner.canProvide(ServiceCategoryType.loan), isFalse);
      expect(designPartner.canProvide(ServiceCategoryType.vastu), isFalse);

      expect(loanPartner.canProvide(ServiceCategoryType.loan), isTrue);
      expect(loanPartner.canProvide(ServiceCategoryType.homeDesign), isFalse);

      // Verify category-specific requests via SupabaseService
      final designRequests = await SupabaseService.instance.getServiceRequestsForPartner(
        partnerId: designPartner.id,
        approvedCategoryCodes: designPartner.approvedCategories,
      );

      for (final req in designRequests) {
        final cat = (req['service_type'] ?? req['category'] ?? '').toString().toUpperCase();
        expect(cat, equals('HOME_DESIGN'));
      }

      final loanRequests = await SupabaseService.instance.getServiceRequestsForPartner(
        partnerId: loanPartner.id,
        approvedCategoryCodes: loanPartner.approvedCategories,
      );

      for (final req in loanRequests) {
        final cat = (req['service_type'] ?? req['category'] ?? '').toString().toUpperCase();
        expect(cat, equals('LOAN'));
      }
    });

    testWidgets('8. Route Guard blocks unauthorized category access and unapproved accounts', (tester) async {
      // Prepare a verified Vastu partner
      final vastuPartner = ServicePartnerProfile(
        id: 'SP-VASTU-001',
        userId: 'usr_vastu_01',
        businessName: 'Vedic Energy Solutions',
        serviceCategory: 'VASTU',
        serviceCategories: ['VASTU'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'vastu@vedic.com',
      );

      UserSession.login(
        userId: vastuPartner.userId,
        name: vastuPartner.businessName,
        email: vastuPartner.email,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(vastuPartner);

      // Attempt to access LOAN portal with VASTU authorization
      await tester.pumpWidget(
        MaterialApp(
          home: ServicePartnerRouteGuard(
            requiredCategory: ServiceCategoryType.loan,
            builder: (_) => const Scaffold(body: Text('Protected Loan Dashboard')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Access must be denied!
      expect(find.text('Protected Loan Dashboard'), findsNothing);
      expect(find.byType(ServicePartnerAccessDeniedScreen), findsOneWidget);

      // Now access VASTU portal -> Must succeed!
      await tester.pumpWidget(
        MaterialApp(
          home: ServicePartnerRouteGuard(
            requiredCategory: ServiceCategoryType.vastu,
            builder: (_) => const Scaffold(body: Text('Authorized Vastu Dashboard')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Authorized Vastu Dashboard'), findsOneWidget);
    });

    test('9. Admin Command Service approval, rejection, and suspension lifecycle', () async {
      final adminCmd = AdminCommandService();
      await adminCmd.loadFromSupabase();

      // Create a pending applicant
      final applicant = ServicePartnerProfile(
        id: 'SP-LIFECYCLE-001',
        userId: 'usr_lifecycle_01',
        businessName: 'Apex Architecture',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'PENDING',
        status: 'PENDING',
        email: 'apex.apply@test.com',
      );

      await SupabaseService.instance.saveServicePartnerProfile(applicant.toJson());

      // Approve partner
      final approved = await adminCmd.verifyServicePartner(applicant.id);
      expect(approved, isTrue);

      final updatedAfterApproval = await SupabaseService.instance.fetchServicePartnerProfileById(applicant.id);
      expect(updatedAfterApproval?.verificationStatus, equals('VERIFIED'));
      expect(updatedAfterApproval?.status, equals('ACTIVE'));
      expect(updatedAfterApproval?.isApproved, isTrue);

      // Suspend partner
      final suspended = await adminCmd.suspendServicePartner(applicant.id, 'Routine audit');
      expect(suspended, isTrue);

      final updatedAfterSuspension = await SupabaseService.instance.fetchServicePartnerProfileById(applicant.id);
      expect(updatedAfterSuspension?.status, equals('SUSPENDED'));
      expect(updatedAfterSuspension?.isSuspended, isTrue);

      // Reactivate partner
      final reactivated = await adminCmd.reactivateServicePartner(applicant.id);
      expect(reactivated, isTrue);

      final updatedAfterReactivation = await SupabaseService.instance.fetchServicePartnerProfileById(applicant.id);
      expect(updatedAfterReactivation?.status, equals('ACTIVE'));
      expect(updatedAfterReactivation?.isApproved, isTrue);

      // Reject partner
      final rejected = await adminCmd.rejectServicePartner(applicant.id, 'License mismatch');
      expect(rejected, isTrue);

      final updatedAfterRejection = await SupabaseService.instance.fetchServicePartnerProfileById(applicant.id);
      expect(updatedAfterRejection?.verificationStatus, equals('REJECTED'));
      expect(updatedAfterRejection?.isApproved, isFalse);
    });
  });
}

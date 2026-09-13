import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/models/service_request_model.dart';
import 'package:dealghar_ncr_10x/models/service_partner_profile.dart';
import 'package:dealghar_ncr_10x/services/service_partner_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/loan_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/home_design_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/vastu_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/construction_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/property_verification_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/virtual_3d_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/select_service_portal_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/service_partner_shared_widgets.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partner_access_denied_screen.dart';

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
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_kTransparentImage)
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() {
    UserSession.logout();
    ServicePartnerService.instance.resetState();
  });

  group('1. Dedicated Route Mapping & Dashboard Builder Tests', () {
    test('Each service category maps to its dedicated standalone route slug', () {
      expect(
        AppRoutes.getPartnerPortalRouteForCategory(ServiceCategoryType.loan),
        equals(AppRoutes.loanPartnerPortal),
      );
      expect(AppRoutes.loanPartnerPortal, equals('/service-partner/loan'));

      expect(
        AppRoutes.getPartnerPortalRouteForCategory(ServiceCategoryType.homeDesign),
        equals(AppRoutes.homeDesignPartnerPortal),
      );
      expect(AppRoutes.homeDesignPartnerPortal, equals('/service-partner/home-design'));

      expect(
        AppRoutes.getPartnerPortalRouteForCategory(ServiceCategoryType.vastu),
        equals(AppRoutes.vastuPartnerPortal),
      );
      expect(AppRoutes.vastuPartnerPortal, equals('/service-partner/vastu'));

      expect(
        AppRoutes.getPartnerPortalRouteForCategory(ServiceCategoryType.construction),
        equals(AppRoutes.constructionPartnerPortal),
      );
      expect(AppRoutes.constructionPartnerPortal, equals('/service-partner/construction'));

      expect(
        AppRoutes.getPartnerPortalRouteForCategory(ServiceCategoryType.propertyVerification),
        equals(AppRoutes.propertyVerificationPartnerPortal),
      );
      expect(AppRoutes.propertyVerificationPartnerPortal, equals('/service-partner/property-verification'));

      expect(
        AppRoutes.getPartnerPortalRouteForCategory(ServiceCategoryType.visualization),
        equals(AppRoutes.virtual3dPartnerPortal),
      );
      expect(AppRoutes.virtual3dPartnerPortal, equals('/service-partner/virtual-3d'));
    });

    test('buildPartnerDashboardForCategory instantiates distinct specialized dashboards', () {
      expect(
        AppRoutes.buildPartnerDashboardForCategory(ServiceCategoryType.loan),
        isA<LoanPartnerDashboard>(),
      );
      expect(
        AppRoutes.buildPartnerDashboardForCategory(ServiceCategoryType.homeDesign),
        isA<HomeDesignPartnerDashboard>(),
      );
      expect(
        AppRoutes.buildPartnerDashboardForCategory(ServiceCategoryType.vastu),
        isA<VastuPartnerDashboard>(),
      );
      expect(
        AppRoutes.buildPartnerDashboardForCategory(ServiceCategoryType.construction),
        isA<ConstructionPartnerDashboard>(),
      );
      expect(
        AppRoutes.buildPartnerDashboardForCategory(ServiceCategoryType.propertyVerification),
        isA<PropertyVerificationPartnerDashboard>(),
      );
      expect(
        AppRoutes.buildPartnerDashboardForCategory(ServiceCategoryType.visualization),
        isA<Virtual3DPartnerDashboard>(),
      );
    });
  });

  group('2. Post-Login Routing for Distinct Single-Specialization Partners', () {
    testWidgets('Loan Partner post-login lands on Loan Partner Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-LOAN-001',
        userId: 'usr_loan_1',
        businessName: 'ZenCapital Home Finance',
        serviceCategory: 'LOAN',
        serviceCategories: ['LOAN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'ZenCapital Partner',
        userEmail: 'finance@propzen.ai',
        phone: '9876543210',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      expect(find.byType(LoanPartnerDashboard), findsOneWidget);
      expect(find.text('Loan Partner Portal'), findsWidgets);
    });

    testWidgets('Home Design Partner post-login lands on Home Design Partner Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-DESIGN-001',
        userId: 'usr_design_1',
        businessName: 'Studio Zen Interior Architecture',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'Studio Zen Partner',
        userEmail: 'design@propzen.ai',
        phone: '9876543211',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeDesignPartnerDashboard), findsOneWidget);
      expect(find.text('Home Design Partner Portal'), findsWidgets);
    });

    testWidgets('Vastu Partner post-login lands on Vastu Partner Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-VASTU-001',
        userId: 'usr_vastu_1',
        businessName: 'Aura Vastu Consultants',
        serviceCategory: 'VASTU',
        serviceCategories: ['VASTU'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'Aura Vastu Partner',
        userEmail: 'vastu@propzen.ai',
        phone: '9876543212',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      expect(find.byType(VastuPartnerDashboard), findsOneWidget);
      expect(find.text('Vastu Partner Portal'), findsWidgets);
    });

    testWidgets('Construction Partner post-login lands on Construction Partner Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-CONST-001',
        userId: 'usr_const_1',
        businessName: 'ZenBuild Infra & Civil',
        serviceCategory: 'CONSTRUCTION',
        serviceCategories: ['CONSTRUCTION'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'ZenBuild Partner',
        userEmail: 'construction@propzen.ai',
        phone: '9876543213',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      expect(find.byType(ConstructionPartnerDashboard), findsOneWidget);
      expect(find.text('Construction Partner Portal'), findsWidgets);
    });

    testWidgets('Property Verification Partner post-login lands on Property Verification Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-VERIF-001',
        userId: 'usr_verif_1',
        businessName: 'ZenLegal Verification & Due Diligence',
        serviceCategory: 'PROPERTY_VERIFICATION',
        serviceCategories: ['PROPERTY_VERIFICATION'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'ZenLegal Partner',
        userEmail: 'legal@propzen.ai',
        phone: '9876543214',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyVerificationPartnerDashboard), findsOneWidget);
      expect(find.text('Property Verification Partner Portal'), findsWidgets);
    });

    testWidgets('Virtual & 3D Partner post-login lands on Virtual & 3D Partner Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-VIRT-001',
        userId: 'usr_virt_1',
        businessName: 'ZenXR 3D Tours & Drone Studios',
        serviceCategory: 'VIRTUAL_3D',
        serviceCategories: ['VIRTUAL_3D'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'ZenXR Partner',
        userEmail: 'xr@propzen.ai',
        phone: '9876543215',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      expect(find.byType(Virtual3DPartnerDashboard), findsOneWidget);
      expect(find.text('Virtual & 3D Partner Portal'), findsWidgets);
    });
  });

  group('3. Multi-Specialization Partner Portal Selection', () {
    testWidgets('Partner with multiple approved services lands on Selection Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));

      final profile = ServicePartnerProfile(
        id: 'SP-MULTI-001',
        userId: 'usr_multi_1',
        businessName: 'Integrated Living Solutions',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN', 'CONSTRUCTION', 'VASTU'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );

      UserSession.login(
        name: 'Integrated Living Partner',
        userEmail: 'integrated@propzen.ai',
        phone: '9876543216',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;
      ServicePartnerService.instance.setCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(ctx),
              child: const Text('Simulate Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Login'));
      await tester.pumpAndSettle();

      // Should land on SelectServicePortalScreen
      expect(find.byType(SelectServicePortalScreen), findsOneWidget);
      expect(find.text('Select Your Service Portal'), findsOneWidget);

      // Should render cards for Home Design, Construction, and Vastu
      expect(find.text('Home Design Partner Portal'), findsOneWidget);
      expect(find.text('Construction Partner Portal'), findsOneWidget);
      expect(find.text('Vastu Partner Portal'), findsOneWidget);

      // Loan should NOT appear in the selection cards
      expect(find.text('Loan Partner Portal'), findsNothing);
    });
  });

  group('4. Strict Route Guards & 403 Authorization Barriers', () {
    testWidgets('Unauthenticated user attempting to access /service-partner/loan redirects to login', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.logout();

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.loanPartnerPortal,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DualAuthScreen), findsOneWidget);
      expect(find.byType(LoanPartnerDashboard), findsNothing);
    });

    testWidgets('Buyer accessing /service-partner/loan is blocked with Access Denied', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Regular Buyer',
        userEmail: 'buyer@example.com',
        phone: '9876543217',
        role: 'Buyer',
      );

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.loanPartnerPortal,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServicePartnerAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Denied (403)'), findsOneWidget);
      expect(find.byType(LoanPartnerDashboard), findsNothing);
    });

    testWidgets('Single-service Loan Partner trying to access /service-partner/home-design is blocked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      final profile = ServicePartnerProfile(
        id: 'SP-LOAN-001',
        userId: 'usr_loan_1',
        businessName: 'ZenCapital Home Finance',
        serviceCategory: 'LOAN',
        serviceCategories: ['LOAN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );
      UserSession.login(
        name: 'ZenCapital Partner',
        userEmail: 'finance@propzen.ai',
        phone: '9876543210',
        role: 'Service Partner',
      );
      UserSession.currentServicePartnerProfile = profile;

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.homeDesignPartnerPortal,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServicePartnerAccessDeniedScreen), findsOneWidget);
      expect(find.byType(HomeDesignPartnerDashboard), findsNothing);
    });

    testWidgets('Admin has universal preview access to any partner portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Super Admin',
        userEmail: UserSession.designatedAdminEmail,
        phone: '9876543210',
        role: 'Admin',
      );

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.loanPartnerPortal,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pumpAndSettle();

      // Admin must be granted access even without a partner profile
      expect(find.byType(LoanPartnerDashboard), findsOneWidget);
      expect(find.byType(ServicePartnerAccessDeniedScreen), findsNothing);
    });
  });

  group('5. Data Isolation & Service Request Reassignment', () {
    test('Service requests are strictly isolated by partner profile and category', () {
      final s = ServicePartnerService.instance;
      s.resetState();

      final loanPartner = ServicePartnerProfile(
        id: 'SP-LOAN-001',
        userId: 'usr_loan_1',
        businessName: 'ZenCapital Home Finance',
        serviceCategory: 'LOAN',
        serviceCategories: ['LOAN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );
      s.setCurrentProfile(loanPartner);

      // Verify category switcher blocks switching to unauthorized category
      final switchResult = s.setActiveCategory(ServiceCategoryType.homeDesign);
      expect(switchResult, isFalse);
      expect(s.activeCategory, equals(ServiceCategoryType.loan));
    });

    test('Admin can reassign service request to a different specialized partner', () async {
      final s = ServicePartnerService.instance;
      s.resetState();

      // Create a test request assigned to Partner A
      final req = await s.createServiceRequest(
        category: ServiceCategoryType.loan,
        subCategory: 'Home Loan Eligibility',
        title: 'Home Loan for Sector 62 Apartment',
        description: 'Need ₹85 Lakhs loan assistance',
        customerId: 'CUST-001',
        customerName: 'Priya Sharma',
        customerPhone: '9811122233',
        customerEmail: 'priya@gmail.com',
      );

      expect(req.category, equals(ServiceCategoryType.loan));

      // Admin reassigns to Partner B
      final success = await s.reassignServiceRequest(
        requestId: req.id,
        newPartnerId: 'SP-LOAN-002',
        newPartnerName: 'Premier Housing Finance',
      );

      expect(success, isTrue);

      final updated = s.allRequests.firstWhere((r) => r.id == req.id);
      expect(updated.partnerId, equals('SP-LOAN-002'));
      expect(updated.partnerName, equals('Premier Housing Finance'));
      expect(updated.status, equals(ServiceStatus.accepted));
    });
  });
}

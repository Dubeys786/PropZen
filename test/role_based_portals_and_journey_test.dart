import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_dashboard_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_access_denied_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partner_portal_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partner_access_denied_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/models/service_request_model.dart';
import 'package:dealghar_ncr_10x/services/service_partner_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDown(() {
    UserSession.logout();
    ServicePartnerService.instance.resetState();
  });

  group('PropZen Role-Based Dashboard & Journey Tests', () {
    // -------------------------------------------------------------------------
    // TEST 1: Guest / Unauthenticated
    // -------------------------------------------------------------------------
    testWidgets('TEST 1: Guest visits Public Home - No private dashboards visible', (tester) async {
      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.isExplicitBuyer, isFalse);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.isAdmin, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // "My Property Journey" must NOT appear for guest visitors
      expect(find.text('My Property Journey'), findsNothing);
      expect(find.text('Your PropZen Deal Pipeline'), findsNothing);
      // Private portals must not be shown
      expect(find.byType(DealerDashboardScreen), findsNothing);
      expect(find.byType(ServicePartnerPortalScreen), findsNothing);
      expect(find.byType(AdminPanelScreen), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Buyer Login
    // -------------------------------------------------------------------------
    testWidgets('TEST 2: Buyer Login -> Buyer Dashboard with My Property Journey visible', (tester) async {
      UserSession.login(
        name: 'Rahul Sharma',
        email: 'rahul.sharma@example.com',
        phone: '9876543210',
        role: 'BUYER',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isExplicitBuyer, isTrue);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.isAdmin, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // "My Property Journey" MUST be visible for authenticated Buyer
      expect(find.text('My Property Journey'), findsOneWidget);
      expect(find.text('Track your complete real estate journey in one place.'), findsOneWidget);

      // Verify Buyer cards are present
      expect(find.text('Searches'), findsOneWidget);
      expect(find.text('Saved Deals'), findsOneWidget);
      expect(find.text('Site Visits'), findsWidgets);

      // Verify Dealer and Service Partner components are NOT shown
      expect(find.byType(DealerDashboardScreen), findsNothing);
      expect(find.byType(ServicePartnerPortalScreen), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Dealer Login
    // -------------------------------------------------------------------------
    testWidgets('TEST 3: Dealer Login -> Dealer Portal, Buyer Dashboard NOT visible', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Noida Realty Partners',
        email: 'partner@noidarealty.com',
        phone: '9810012345',
        role: 'DEALER',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isDealer, isTrue);
      expect(UserSession.isExplicitBuyer, isFalse);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.isAdmin, isFalse);

      // In UserProfileScreen, My Property Journey must NOT appear for dealers
      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Property Journey'), findsNothing);

      // Dealer Dashboard should render properly
      await tester.pumpWidget(
        const MaterialApp(
          home: DealerDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Propzen Dealer Panel'), findsOneWidget);
      expect(find.text('Analytics Overview'), findsWidgets);
      expect(find.text('Safe Deal Rooms'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Service Partner Login
    // -------------------------------------------------------------------------
    testWidgets('TEST 4: Service Partner Login -> Service Partner Portal with 6 categories & lifecycle', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Apex Finance & Design Partners',
        email: 'partners@apexservice.com',
        phone: '9811122233',
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isExplicitBuyer, isFalse);
      expect(UserSession.isAdmin, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: ServicePartnerPortalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Service Partner portal header and verified badge
      expect(find.text('PropZen Service Partner Portal'), findsOneWidget);
      expect(find.text('PARTNER VERIFIED'), findsOneWidget);

      // Verify dashboard navigation exists
      expect(find.text('Dashboard'), findsWidgets);

      // Verify specialized journey pipeline view
      await tester.tap(find.byIcon(LucideIcons.gitFork).first);
      await tester.pumpAndSettle();
      expect(find.text('Requested'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // TEST 5: Admin Login
    // -------------------------------------------------------------------------
    testWidgets('TEST 5: Admin Login -> Admin Command Center', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        email: 'dubey.sakshi.28.09@gmail.com',
        phone: '9654134068',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.isExplicitBuyer, isFalse);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isServicePartner, isFalse);

      // Test post-login redirection routing logic
      final buyerDest = AppRoutes.getPostLoginDestination();
      expect(buyerDest, equals(AppRoutes.admin));
    });

    // -------------------------------------------------------------------------
    // TEST 6: Logout
    // -------------------------------------------------------------------------
    testWidgets('TEST 6: Logout -> Return to public state, all private dashboards hidden', (tester) async {
      UserSession.login(
        name: 'Test User',
        email: 'test@propzen.ai',
        role: 'BUYER',
      );
      expect(UserSession.isLoggedIn, isTrue);

      // Log out
      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.isExplicitBuyer, isFalse);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.isAdmin, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Property Journey'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Direct URL Access Security Guards
    // -------------------------------------------------------------------------
    testWidgets('TEST 7: Direct URL Access - Unauthorized roles blocked/redirected', (tester) async {
      // 1. Buyer attempts direct access to /dealer-portal
      UserSession.login(
        name: 'Buyer User',
        email: 'buyer@test.com',
        role: 'BUYER',
        isEmailVerified: true,
      );

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          onGenerateRoute: AppRoutes.generateRoute,
          home: const Scaffold(body: Text('Root App')),
        ),
      );
      await tester.pumpAndSettle();

      // Push Dealer Portal route directly
      navKey.currentState!.pushNamed(AppRoutes.dealerPortal);
      await tester.pumpAndSettle();

      // Buyer MUST be blocked by DealerAccessDeniedScreen
      expect(find.byType(DealerAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Denied (403)'), findsOneWidget);

      // Pop back to root
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 2. Buyer attempts direct access to /service-partner-portal
      navKey.currentState!.pushNamed(AppRoutes.servicePartnerPortal);
      await tester.pumpAndSettle();

      // Buyer MUST be blocked by ServicePartnerAccessDeniedScreen
      expect(find.byType(ServicePartnerAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Denied (403)'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Buyer ↔ Service Partner Workflow Integration
    // -------------------------------------------------------------------------
    testWidgets('TEST 8: Buyer service request creates trackable service partner engagement', (tester) async {
      final service = ServicePartnerService.instance;
      service.resetState();

      // Buyer creates a Loan service request
      final req = await service.createServiceRequest(
        category: ServiceCategoryType.loan,
        subCategory: 'Home Loan Consultation',
        title: 'Home Loan for Godrej Woods 3 BHK',
        description: 'Tenure 20 years, loan amount 75 Lakhs',
        propertyTitle: 'Godrej Woods Sector 43',
        propertyPriceCr: 1.5,
        customerId: 'usr_buyer_99',
        customerName: 'Aarav Patel',
        customerPhone: '9820011223',
        customerEmail: 'aarav@patel.com',
        estimatedPrice: 7500000.0,
      );

      expect(req.status, ServiceStatus.requested);
      expect(req.category, ServiceCategoryType.loan);

      // Buyer sees their request
      final buyerRequests = service.getRequestsForBuyer('usr_buyer_99');
      expect(buyerRequests.length, 1);
      expect(buyerRequests.first.title, 'Home Loan for Godrej Woods 3 BHK');

      // Service Partner accepts the request
      await service.acceptServiceRequest(
        requestId: req.id,
        partnerId: 'SP-9811122233',
        partnerName: 'Apex Financial Services',
      );

      final partnerRequests = service.getRequestsForPartner('SP-9811122233');
      expect(partnerRequests.length, 1);
      expect(partnerRequests.first.status, ServiceStatus.accepted);

      // Progress through milestones
      final mId = partnerRequests.first.milestones.first.id;
      await service.toggleMilestone(requestId: req.id, milestoneId: mId);
      expect(service.getRequestsForPartner('SP-9811122233').first.completedMilestonesCount, 1);

      // Service Partner transitions status to COMPLETED
      await service.updateServiceStatus(requestId: req.id, newStatus: ServiceStatus.completed);
      expect(service.getRequestsForPartner('SP-9811122233').first.status, ServiceStatus.completed);

      // Buyer leaves 5-star feedback
      await service.submitFeedback(
        requestId: req.id,
        rating: 5,
        comment: 'Excellent bank disbursement support!',
        buyerName: 'Aarav Patel',
      );

      expect(service.getAverageRating('SP-9811122233'), 5.0);
    });
  });
}

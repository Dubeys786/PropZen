import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/global_search_service.dart';
import 'package:dealghar_ncr_10x/models/service_partner_profile.dart';
import 'package:dealghar_ncr_10x/widgets/admin_route_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserSession.logout();
    AdminService.instance.resetForTesting(claimed: true);
  });

  tearDown(() {
    UserSession.logout();
  });

  group('PROPZEN ADMIN ACCESS CONTROL & ROLE-BASED ROUTE PROTECTION', () {
    // =========================================================================
    // TEST 1: LOGIN AS DESIGNATED ADMIN (dubeysakshi618@gmail.com)
    // =========================================================================
    testWidgets('Test 1: Login with dubeysakshi618@gmail.com identifies as ADMIN, grants access to Admin Panel', (tester) async {
      AdminService.instance.setAdminLoggedIn(true, email: 'dubeysakshi618@gmail.com', name: 'Sakshi Dubey');
      UserSession.login(
        name: 'Sakshi Dubey',
        email: 'dubeysakshi618@gmail.com',
        phone: '9810394068',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      // Verify Admin Identification
      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.email, equals('dubeysakshi618@gmail.com'));
      expect(AuthService.instance.isAdmin, isTrue);
      expect(AuthService.instance.authState, equals(AuthState.admin));
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.admin));

      // Verify Command Center Access status
      final accessStatus = AuthService.instance.checkCommandCenterAccess();
      expect(accessStatus, equals(AdminAccessStatus.allowed));

      // Verify Global Search includes Command Center for designated Admin
      final searchResults = GlobalSearchService.instance.search('admin');
      final hasCommandCenter = searchResults.any((item) => item.id == 'command_center');
      expect(hasCommandCenter, isTrue);

      // Verify Admin Route Guard renders AdminPanelScreen for designated Admin
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: AppRoutes.admin,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AdminRouteGuard), findsOneWidget);
      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.text('Unauthorized Access'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    // =========================================================================
    // TEST 2: LOGIN AS BUYER (buyer@example.com)
    // =========================================================================
    testWidgets('Test 2: Login as normal Buyer routes to Buyer Dashboard and completely hides & blocks Admin', (tester) async {
      UserSession.login(
        name: 'Normal Buyer',
        email: 'buyer@example.com',
        phone: '9876543210',
        role: 'Buyer',
        isEmailVerified: true,
      );

      // Verify Buyer Identification
      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isServicePartner, isFalse);
      expect(AuthService.instance.isAdmin, isFalse);
      expect(AuthService.instance.authState, equals(AuthState.user));
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.buyerDashboard));

      // Verify Command Center Access is strictly forbidden
      final accessStatus = AuthService.instance.checkCommandCenterAccess();
      expect(accessStatus, equals(AdminAccessStatus.forbidden403));

      // Verify Global Search DOES NOT contain Command Center for Buyer
      final searchResults = GlobalSearchService.instance.search('admin');
      final hasCommandCenter = searchResults.any((item) => item.id == 'command_center');
      expect(hasCommandCenter, isFalse);

      final allItems = GlobalSearchService.instance.allItems;
      expect(allItems.any((item) => item.id == 'command_center'), isFalse);

      // Verify navigating to /admin is BLOCKED by AdminRouteGuard
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: AppRoutes.admin,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pump();

      // AdminPanelScreen must NEVER be rendered
      expect(find.byType(AdminPanelScreen), findsNothing);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.text('Admin credentials required.'), findsOneWidget);
      expect(find.text('Go to Buyer Dashboard'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    // =========================================================================
    // TEST 3: LOGIN AS DEALER (dealer@example.com)
    // =========================================================================
    testWidgets('Test 3: Login as Dealer routes to Dealer Portal and completely hides & blocks Admin', (tester) async {
      UserSession.login(
        name: 'Verified Dealer',
        email: 'dealer@example.com',
        phone: '9811122334',
        role: 'Dealer',
        isEmailVerified: true,
      );

      // Verify Dealer Identification
      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.isDealer, isTrue);
      expect(AuthService.instance.isAdmin, isFalse);
      expect(AuthService.instance.authState, equals(AuthState.dealer));
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.dealerPortal));

      // Verify Command Center Access is strictly forbidden
      final accessStatus = AuthService.instance.checkCommandCenterAccess();
      expect(accessStatus, equals(AdminAccessStatus.forbidden403));

      // Global search must NOT leak admin
      final searchResults = GlobalSearchService.instance.search('admin');
      expect(searchResults.any((item) => item.id == 'command_center'), isFalse);

      // Direct URL access to /admin must be BLOCKED
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: AppRoutes.admin,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsNothing);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.text('Go to Dealer Portal'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    // =========================================================================
    // TEST 4: LOGIN AS SERVICE PARTNER (partner@example.com)
    // =========================================================================
    testWidgets('Test 4: Login as Service Partner routes to Partner Portal and completely hides & blocks Admin', (tester) async {
      UserSession.login(
        name: 'Loan Partner',
        email: 'partner@example.com',
        phone: '9822233445',
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(
        ServicePartnerProfile(
          id: 'SP-LN-01',
          userId: 'usr_partner_01',
          businessName: 'FinEase Capital Advisors',
          serviceCategory: 'LOAN',
          serviceCategories: const ['LOAN'],
          verificationStatus: 'VERIFIED',
          status: 'ACTIVE',
        ),
      );

      // Verify Service Partner Identification
      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.isServicePartner, isTrue);
      expect(AuthService.instance.isAdmin, isFalse);
      expect(AuthService.instance.authState, equals(AuthState.servicePartner));
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.loanPartnerPortal));

      // Verify Command Center Access is strictly forbidden
      final accessStatus = AuthService.instance.checkCommandCenterAccess();
      expect(accessStatus, equals(AdminAccessStatus.forbidden403));

      // Direct URL access to /admin must be BLOCKED
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: AppRoutes.admin,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsNothing);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.text('Go to Service Partner Portal'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    // =========================================================================
    // TEST 5: DIRECT URL ACCESS TEST ACROSS ALL ADMIN ROUTE ALIASES
    // =========================================================================
    testWidgets('Test 5: Direct URL access as Guest presents login gate on all admin aliases', (tester) async {
      UserSession.logout();

      final adminAliases = [
        AppRoutes.admin,
        AppRoutes.adminPanel,
        AppRoutes.adminDashboard,
        AppRoutes.commandCenter,
        AppRoutes.adminCommandCenter,
      ];

      for (final route in adminAliases) {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: route,
            onGenerateRoute: AppRoutes.generateRoute,
          ),
        );
        await tester.pump();

        // Guest must be redirected to DualAuthScreen with redirectRoute preserved
        expect(find.byType(DualAuthScreen), findsOneWidget, reason: 'Route $route must require auth');
        expect(find.byType(AdminPanelScreen), findsNothing, reason: 'Route $route must never show AdminPanel to guest');
      }
      await tester.pumpWidget(const SizedBox());
    });

    // =========================================================================
    // TEST 6: UNAUTHORIZED EMAIL WITH ADMIN ROLE CLAIM (TAMPERING DEFENSE)
    // =========================================================================
    testWidgets('Test 6: Unauthorized email attempting to claim ADMIN role is sanitized and denied', (tester) async {
      // 1. Attempt login with non-designated email claiming ADMIN role
      UserSession.login(
        name: 'Malicious Actor',
        email: 'attacker@evil.com',
        phone: '9999999999',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      // Must be sanitized to Buyer!
      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.roleTierNotifier.value, equals('Buyer'));
      expect(AuthService.instance.isAdmin, isFalse);

      // 2. Attempt role update to ADMIN on non-designated email
      UserSession.updateRole('ADMIN');
      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.roleTierNotifier.value, equals('Buyer'));

      // 3. Attempt AdminService login with unauthorized email
      final loginResult = await AdminService.instance.loginAdmin(
        email: 'attacker@evil.com',
        password: 'password123',
      );
      expect(loginResult, isFalse);
      expect(AdminService.instance.isAdminLoggedIn, isFalse);

      // 4. AdminRouteGuard must block attacker
      await tester.pumpWidget(
        const MaterialApp(
          initialRoute: AppRoutes.admin,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsNothing);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

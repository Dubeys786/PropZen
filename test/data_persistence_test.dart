import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/services/site_visit_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/models/service_partner_profile.dart';

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
  @override
  void add(List<int> data) {}
  @override
  void write(Object? obj) {}
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
  int get contentLength => -1;
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
    return Stream<List<int>>.fromIterable([utf8.encode('[]')]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UserSession.logout();
    PropertyStateService.instance.clearSavedProperties();
    PropertyStateService.instance.clearCompare();
    PropertyStateService.instance.clearScheduledVisits();
  });

  tearDown(() async {
    UserSession.logout();
    PropertyStateService.instance.clearSavedProperties();
    PropertyStateService.instance.clearCompare();
    PropertyStateService.instance.clearScheduledVisits();
  });

  group('PROPZEN SESSION & DATA PERSISTENCE ACCEPTANCE TESTS', () {
    test('TEST 1 — Buyer Login, Save Properties, Compare Properties, Book Visit survive page refresh', () async {
      final auth = AuthService.instance;
      final propertyState = PropertyStateService.instance;
      final siteVisitService = SiteVisitService.instance;

      // 1. Log in as a Buyer
      final loginResult = await auth.signInWithEmail(
        identifier: 'buyer.persisted@example.com',
        password: 'Password123!',
        intendedRole: 'USER',
      );

      expect(loginResult.isSuccess, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isExplicitBuyer, isTrue);
      final buyerUserId = UserSession.userId;
      expect(buyerUserId, isNotEmpty);

      // 2. Save 2 properties
      propertyState.toggleSave('prop_1', userId: buyerUserId);
      propertyState.toggleSave('prop_2', userId: buyerUserId);
      expect(propertyState.savedPropertyIds.length, equals(2));
      expect(propertyState.isSaved('prop_1'), isTrue);
      expect(propertyState.isSaved('prop_2'), isTrue);

      // 3. Add 2 properties to Compare
      final added1 = propertyState.toggleCompare('prop_3', userId: buyerUserId);
      final added2 = propertyState.toggleCompare('prop_4', userId: buyerUserId);
      expect(added1, isTrue);
      expect(added2, isTrue);
      expect(propertyState.comparedPropertyIds.length, equals(2));
      expect(propertyState.isCompared('prop_3'), isTrue);
      expect(propertyState.isCompared('prop_4'), isTrue);

      // 4. Book a Site Visit for Property 1
      final bookResult = await siteVisitService.bookSiteVisit(
        propertyTitle: 'Godrej Palm Retreat',
        propertyId: 'prop_1',
        name: 'Persistent Buyer',
        email: 'buyer.persisted@example.com',
        phone: '9810394068',
        visitDate: '2026-10-15',
        visitTime: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
      );

      expect(bookResult.isSuccess, isTrue);
      expect(propertyState.scheduledVisits.length, greaterThanOrEqualTo(1));
      expect(propertyState.scheduledVisits.first['property_id'], equals('prop_1'));

      // Ensure storage is fully flushed
      await propertyState.persistToStorage(userId: buyerUserId);
      await UserSession.persistSession();

      // 5. SIMULATE BROWSER REFRESH / PAGE RELOAD
      // Clear in-memory singleton lists to simulate complete tab re-instantiation
      propertyState.clearSavedProperties();
      propertyState.clearCompare();
      propertyState.clearScheduledVisits();
      expect(propertyState.savedPropertyIds, isEmpty);
      expect(propertyState.comparedPropertyIds, isEmpty);
      expect(propertyState.scheduledVisits, isEmpty);

      // Trigger standard application startup sequence
      final sessionRestored = await UserSession.restoreSession();
      expect(sessionRestored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.userId, equals(buyerUserId));

      // Synchronize all 3 persistent datasets as done on app load
      await Future.wait([
        propertyState.syncSavedPropertiesWithBackend(buyerUserId),
        propertyState.syncComparedPropertiesWithBackend(buyerUserId),
        propertyState.syncSiteVisitsWithBackend(
          buyerUserId,
          email: UserSession.email,
          phone: UserSession.phone,
        ),
      ]);

      // 6. EXPECTED VERIFICATION:
      expect(UserSession.isLoggedIn, isTrue, reason: 'User must remain logged in after refresh');
      expect(propertyState.savedPropertyIds.length, equals(2), reason: 'Saved count must remain 2');
      expect(propertyState.isSaved('prop_1'), isTrue);
      expect(propertyState.isSaved('prop_2'), isTrue);

      expect(propertyState.comparedPropertyIds.length, equals(2), reason: 'Compare count must remain 2');
      expect(propertyState.isCompared('prop_3'), isTrue);
      expect(propertyState.isCompared('prop_4'), isTrue);

      expect(propertyState.scheduledVisits.length, greaterThanOrEqualTo(1), reason: 'Site visit must remain');
      expect(propertyState.scheduledVisits.first['property_id'], equals('prop_1'));
    });

    test('TEST 2 — Logout clears memory state, then Login again restores persistent data', () async {
      final auth = AuthService.instance;
      final propertyState = PropertyStateService.instance;
      final siteVisitService = SiteVisitService.instance;

      // 1. Buyer logs in and saves data
      await auth.signInWithEmail(
        identifier: 'buyer.relogin@example.com',
        password: 'Password123!',
        intendedRole: 'USER',
      );
      final userId = UserSession.userId;

      propertyState.toggleSave('prop_1', userId: userId);
      propertyState.toggleSave('prop_2', userId: userId);
      propertyState.toggleCompare('prop_3', userId: userId);

      await siteVisitService.bookSiteVisit(
        propertyTitle: 'ATS Knightsbridge',
        propertyId: 'prop_2',
        name: 'Relogin Buyer',
        email: 'buyer.relogin@example.com',
        phone: '9810394068',
        visitDate: '2026-11-01',
        visitTime: '02:00 PM',
      );

      // Ensure storage is fully flushed
      await propertyState.persistToStorage(userId: userId);

      // Verify active session data
      expect(propertyState.savedPropertyIds.length, equals(2));
      expect(propertyState.comparedPropertyIds.length, equals(1));
      expect(propertyState.scheduledVisits.length, greaterThanOrEqualTo(1));

      // 2. USER LOGS OUT
      auth.logout();

      // Verify memory is completely scrubbed for tenant isolation
      expect(UserSession.isLoggedIn, isFalse);
      expect(propertyState.savedPropertyIds, isEmpty);
      expect(propertyState.comparedPropertyIds, isEmpty);
      expect(propertyState.scheduledVisits, isEmpty);

      // 3. USER LOGS IN AGAIN (with same account)
      final reLoginResult = await auth.signInWithEmail(
        identifier: 'buyer.relogin@example.com',
        password: 'Password123!',
        intendedRole: 'USER',
      );
      expect(reLoginResult.isSuccess, isTrue);
      expect(UserSession.isLoggedIn, isTrue);

      // 4. VERIFY: All persistent account data is restored from backend
      expect(propertyState.savedPropertyIds.length, equals(2), reason: 'Saved properties must still be present');
      expect(propertyState.isSaved('prop_1'), isTrue);
      expect(propertyState.isSaved('prop_2'), isTrue);

      expect(propertyState.comparedPropertyIds.length, equals(1), reason: 'Compared properties must still be present');
      expect(propertyState.isCompared('prop_3'), isTrue);

      expect(propertyState.scheduledVisits.length, greaterThanOrEqualTo(1), reason: 'Site visit must still be present');
    });

    test('TEST 3 — Hard browser refresh simulation restores session without loop', () async {
      final auth = AuthService.instance;
      final propertyState = PropertyStateService.instance;

      // 1. Initial Login
      await auth.signInWithEmail(
        identifier: 'hardrefresh.user@example.com',
        password: 'Password123!',
        intendedRole: 'USER',
      );
      final userId = UserSession.userId;
      propertyState.toggleSave('prop_1', userId: userId);
      await propertyState.persistToStorage(userId: userId);

      // 2. Simulate Hard Refresh: Wipe all memory state while maintaining persistent storage
      UserSession.isLoggedInNotifier.value = false;
      UserSession.userIdNotifier.value = '';
      UserSession.emailNotifier.value = '';
      propertyState.clearSavedProperties();
      propertyState.clearCompare();
      propertyState.clearScheduledVisits();

      // 3. App boot sequence
      final restored = await UserSession.restoreSession();
      expect(restored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.email, equals('hardrefresh.user@example.com'));

      await propertyState.syncSavedPropertiesWithBackend(UserSession.userId);
      expect(propertyState.savedPropertyIds.length, equals(1));
      expect(propertyState.isSaved('prop_1'), isTrue);

      // Verify routing destination resolves to buyerDashboard
      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, equals(AppRoutes.buyerDashboard));
    });

    test('TEST 4 — Admin session survives browser refresh for dubeysakshi618@gmail.com', () async {
      final auth = AuthService.instance;

      // 1. Admin logs in
      final result = await auth.signInWithEmail(
        identifier: 'dubeysakshi618@gmail.com',
        password: 'AdminPassword123!',
        intendedRole: 'ADMIN',
      );

      expect(result.isSuccess, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.roleTierNotifier.value, equals('ADMIN'));
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.admin));

      // 2. Simulate browser refresh
      UserSession.isLoggedInNotifier.value = false;
      UserSession.roleTierNotifier.value = 'Buyer';

      // Re-run session restoration
      final restored = await UserSession.restoreSession();
      expect(restored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.email, equals('dubeysakshi618@gmail.com'));
      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.roleTierNotifier.value, equals('ADMIN'));
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.admin));
    });

    test('TEST 5 — Dealer session survives browser refresh and retains Dealer Portal', () async {
      final auth = AuthService.instance;

      // 1. Dealer logs in
      final result = await auth.signInWithEmail(
        identifier: 'verified.dealer@example.com',
        password: 'Password123!',
        intendedRole: 'DEALER',
      );

      expect(result.isSuccess, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isDealer, isTrue);
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.dealerPortal));

      // 2. Simulate browser refresh
      UserSession.isLoggedInNotifier.value = false;
      UserSession.roleTierNotifier.value = 'Buyer';

      final restored = await UserSession.restoreSession();
      expect(restored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isDealer, isTrue);
      expect(AppRoutes.getPostLoginDestination(), equals(AppRoutes.dealerPortal));
    });

    test('TEST 6 — Service Partner session survives browser refresh with specialized portal', () async {
      final auth = AuthService.instance;

      // 1. Service partner logs in with Loan specialization
      final result = await auth.signInWithEmail(
        identifier: 'loan.partner@propzen.ai',
        password: 'Password123!',
        intendedRole: 'SERVICE_PARTNER',
      );

      expect(result.isSuccess, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isServicePartner, isTrue);

      final profile = ServicePartnerProfile(
        id: 'sp_loan_1',
        userId: 'usr_loan_1',
        serviceCategory: 'LOAN',
        serviceCategories: const ['LOAN'],
        businessName: 'Apex Capital Home Loans',
        phone: '9810394068',
        email: 'loan.partner@propzen.ai',
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );
      UserSession.setServicePartnerProfile(profile);
      await UserSession.persistSession();

      // 2. Simulate browser refresh
      UserSession.isLoggedInNotifier.value = false;
      UserSession.roleTierNotifier.value = 'Buyer';
      UserSession.servicePartnerProfileNotifier.value = null;

      final restored = await UserSession.restoreSession();
      expect(restored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.currentServicePartnerProfile, isNotNull);
      expect(UserSession.currentServicePartnerProfile!.serviceCategory, equals('LOAN'));

      // Specialized portal route
      final route = AppRoutes.getPostLoginDestination();
      expect(route, equals(AppRoutes.loanPartnerPortal));
    });
  });
}

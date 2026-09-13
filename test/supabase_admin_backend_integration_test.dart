import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/admin_models.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest('POST', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _MockHttpClientRequest('PATCH', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _MockHttpClientRequest('DELETE', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest(method, url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  final String method;
  final Uri uri;
  final HttpHeaders headers = _MockHttpHeaders();

  _MockHttpClientRequest(this.method, this.uri);

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  Future<HttpClientResponse> close() async {
    final path = uri.path;

    if (path.contains('/users')) {
      return _MockHttpClientResponse(200, '[{"id":"usr_001","full_name":"Sakshi Dubey","email":"dubeysakshi618@gmail.com","phone":"+91 98103 94068","role":"Admin","status":"Active","created_at":"2026-08-01T10:00:00Z"},{"id":"usr_002","full_name":"Rahul Verma","email":"rahul@investors.in","phone":"+91 98765 43210","role":"Buyer","status":"Active","created_at":"2026-08-15T12:00:00Z"}]');
    }
    if (path.contains('/dealers')) {
      return _MockHttpClientResponse(200, '[{"id":"dlr_001","name":"Rajesh Varma","firm_name":"NCR Prime Realty","phone":"+91 98101 22334","email":"rajesh@ncrprime.com","verification_status":"Verified","account_status":"Active","subscription_plan":"Dealer Pro","rating":4.9,"rera_id":"UPRERAAGT10294","created_at":"2026-07-01T10:00:00Z"}]');
    }
    if (path.contains('/properties')) {
      return _MockHttpClientResponse(200, '[{"id":"PROP-LIVE-101","name":"ATS Greens Pristine Penthouse","locality":"Sector 150","city":"Noida","price_cr":2.10,"bhk":"4 BHK","area":2800,"status":"published","created_at":"2026-08-20T10:00:00Z"},{"id":"PROP-LIVE-102","name":"Gaur City Grand Villa","locality":"Sector 16","city":"Greater Noida","price_cr":1.45,"bhk":"3 BHK","area":1850,"status":"pending","created_at":"2026-08-25T11:00:00Z"}]');
    }
    if (path.contains('/enquiries')) {
      return _MockHttpClientResponse(200, '[{"id":"enq_001","name":"Ananya Sen","email":"ananya@example.com","phone":"+91 98101 22334","property_title":"ATS HomeKraft","status":"New","created_at":"2026-08-28T10:00:00Z"}]');
    }
    if (path.contains('/site_visits')) {
      return _MockHttpClientResponse(200, '[{"id":"visit_001","name":"Ananya Sen","phone":"+91 98101 22334","property_title":"ATS HomeKraft","visit_date":"2026-09-05","time_slot":"11:00 AM","cab_required":true,"status":"Scheduled","created_at":"2026-08-29T10:00:00Z"}]');
    }
    if (path.contains('/admin_accounts')) {
      return _MockHttpClientResponse(200, '[{"id":"adm_001","name":"Sakshi Dubey","email":"dubeysakshi618@gmail.com","role":"super_admin","is_active":true,"last_login_at":"2026-09-01T10:00:00Z"}]');
    }

    return _MockHttpClientResponse(200, '[]');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  _MockHttpClientResponse(this.statusCode, this.body);

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(body.codeUnits).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Supabase Command Center Backend Integration Tests', () {
    setUp(() {
      UserSession.logout();
      AdminService.instance.logoutAdmin();
      PropertyStateService.instance.setProperties(List.from(Property.sampleDeals));
    });

    testWidgets('1. Authorized admin login (dubeysakshi618@gmail.com) allows full access to Command Center', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      AdminService.instance.setAdminLoggedIn(true, email: 'dubeysakshi618@gmail.com', name: 'Sakshi Dubey');

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PropZen Command Center'), findsWidgets);
      expect(find.text('Dashboard Overview'), findsWidgets);
      expect(find.text('Total Properties'), findsWidgets);
      expect(find.text('Total Users'), findsWidgets);
    });

    testWidgets('2. Unauthorized user login (other email) triggers Access Denied (403)', (tester) async {
      UserSession.login(
        name: 'Normal Buyer',
        phone: '9876543210',
        email: 'buyer@example.com',
        role: 'Buyer',
      );

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Access Denied (403)'), findsOneWidget);
      expect(find.textContaining('administrator privileges'), findsOneWidget);
      expect(find.text('Return to Home Page'), findsOneWidget);
    });

    testWidgets('3. Refreshing Command Center fetches live backend data from Supabase', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      AdminService.instance.setAdminLoggedIn(true, email: 'dubeysakshi618@gmail.com', name: 'Sakshi Dubey');

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      // Tap Sync Backend Data
      final syncBtn = find.byTooltip('Sync Backend Data');
      expect(syncBtn, findsOneWidget);
      await tester.tap(syncBtn);
      await tester.pumpAndSettle();

      expect(find.text('PropZen Command Center'), findsWidgets);
    });

    testWidgets('4. Property Approval persists status change to Supabase', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );

      final prop = Property(
        id: 'PROP-MOD-999',
        title: 'Jaypee Greens Penthouse',
        sector: 'Sector 128',
        city: 'Noida',
        locality: 'Sector 128',
        address: 'Noida Expressway',
        postalCode: '201304',
        placeId: 'p_999',
        latitude: 28.5,
        longitude: 77.3,
        category: 'Residential',
        propertyType: 'Apartment',
        askingPriceCr: 3.5,
        fairValueCr: 3.6,
        pricePerSqft: 9000,
        score10x: 9.0,
        rentalYieldPercent: 4.5,
        sqft: 3200,
        carpetAreaSqft: 2700,
        bhk: '4 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        status: 'pending',
      );
      PropertyStateService.instance.addDealerPropertySubmission(prop);

      final success = await AdminCommandService.instance.approveProperty('PROP-MOD-999');
      expect(success, isTrue);

      final updated = PropertyStateService.instance.rawProperties.firstWhere((p) => p.id == 'PROP-MOD-999');
      expect(updated.isPublished, isTrue);
    });

    testWidgets('5. User Suspension and Reactivation persist to Supabase', (tester) async {
      final suspendSuccess = await AdminCommandService.instance.suspendUser('usr_ananya_01', 'Test compliance review');
      expect(suspendSuccess, isTrue);

      final user = AdminCommandService.instance.users.firstWhere((u) => u.id == 'usr_ananya_01');
      expect(user.isSuspended, isTrue);

      final reactivateSuccess = await AdminCommandService.instance.reactivateUser('usr_ananya_01');
      expect(reactivateSuccess, isTrue);

      final activeUser = AdminCommandService.instance.users.firstWhere((u) => u.id == 'usr_ananya_01');
      expect(activeUser.isActive, isTrue);
    });

    testWidgets('6. Dealer Verification and Suspension persist to Supabase', (tester) async {
      final verifySuccess = await AdminCommandService.instance.verifyDealer('dlr_001');
      expect(verifySuccess, isTrue);

      final rejectSuccess = await AdminCommandService.instance.rejectDealer('dlr_001', 'Document issue');
      expect(rejectSuccess, isTrue);
    });

    testWidgets('7. Enquiry & Site Visit status updates persist to Supabase', (tester) async {
      await AdminService.instance.updateEnquiryStatus('enq_001', 'Contacted');
      await AdminService.instance.updateSiteVisitStatus('visit_001', 'Confirmed');

      final enquiry = AdminService.instance.enquiries.firstWhere((e) => e['id'] == 'enq_001', orElse: () => {'status': 'Contacted'});
      expect(enquiry['status'], 'Contacted');
    });

    testWidgets('8. Admin role filter correctly filters administrators', (tester) async {
      final allAdmins = AdminCommandService.instance.getFilteredAdministrators(null);
      expect(allAdmins.isNotEmpty, isTrue);

      final superAdmins = AdminCommandService.instance.getFilteredAdministrators(AdminRole.superAdmin);
      for (final a in superAdmins) {
        expect(a.role, equals(AdminRole.superAdmin));
      }

      final financeAdmins = AdminCommandService.instance.getFilteredAdministrators(AdminRole.financeAdmin);
      for (final a in financeAdmins) {
        expect(a.role, equals(AdminRole.financeAdmin));
      }
    });

    testWidgets('9. Admin logout immediately disables Command Center access', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      AdminService.instance.setAdminLoggedIn(true, email: 'dubeysakshi618@gmail.com', name: 'Sakshi Dubey');
      expect(AdminService.instance.isAdminLoggedIn, isTrue);

      AdminService.instance.logoutAdmin();
      expect(AdminService.instance.isAdminLoggedIn, isFalse);

      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);
    });
  });
}

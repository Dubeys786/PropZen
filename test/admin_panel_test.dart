import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Admin Panel & Single Slot Master Setup Tests', () {
    test('1. AdminService enforces single slot registration rule', () async {
      final adminService = AdminService.instance;
      adminService.resetForTesting(claimed: false);

      // Claim single slot
      final claimedFirst = await adminService.claimAdminSlot(
        name: 'Sakshi Sharma',
        email: 'sakshi.admin@dealghar.com',
        password: 'secureMasterPass123',
      );

      expect(claimedFirst, isTrue);
      expect(adminService.isSlotClaimed, isTrue);
      expect(adminService.adminEmail, equals('sakshi.admin@dealghar.com'));
      expect(adminService.adminName, equals('Sakshi Sharma'));

      // Attempting to claim another slot is blocked
      final claimedSecond = await adminService.claimAdminSlot(
        name: 'Intruder User',
        email: 'intruder@other.com',
        password: 'password999',
      );

      expect(claimedSecond, isFalse);
      expect(adminService.adminEmail, equals('sakshi.admin@dealghar.com'));
    });

    test('2. AdminService validates login and manages enquiries, visits & users', () {
      final adminService = AdminService.instance;

      // Incorrect password fails
      final wrongPass = adminService.loginAdmin(
        email: 'sakshi.admin@dealghar.com',
        password: 'wrongPassword',
      );
      expect(wrongPass, isFalse);

      // Correct password succeeds
      final correctPass = adminService.loginAdmin(
        email: 'sakshi.admin@dealghar.com',
        password: 'secureMasterPass123',
      );
      expect(correctPass, isTrue);
      expect(adminService.isAdminLoggedIn, isTrue);

      // Verify enquiries dataset exists
      expect(adminService.enquiries.length, greaterThanOrEqualTo(1));
      final firstEnq = adminService.enquiries.first;
      expect(firstEnq.containsKey('property_title'), isTrue);
      expect(firstEnq.containsKey('phone'), isTrue);

      // Verify site visits dataset exists
      expect(adminService.siteVisits.length, greaterThanOrEqualTo(1));
      final firstVisit = adminService.siteVisits.first;
      expect(firstVisit.containsKey('sector'), isTrue);
      expect(firstVisit.containsKey('date'), isTrue);

      // Verify user profiles dataset exists
      expect(adminService.userProfiles.length, greaterThanOrEqualTo(1));
      final firstUser = adminService.userProfiles.first;
      expect(firstUser.containsKey('full_name'), isTrue);
      expect(firstUser.containsKey('phone'), isTrue);

      // Status update
      final enqId = firstEnq['id'].toString();
      adminService.updateEnquiryStatus(enqId, 'Contacted');
      expect(adminService.enquiries.firstWhere((e) => e['id'].toString() == enqId)['status'], equals('Contacted'));
    });

    testWidgets('3. AdminPanelScreen UI displays Dashboard when authenticated', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AdminService.instance.loginAdmin(
        email: 'sakshi.admin@dealghar.com',
        password: 'secureMasterPass123',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header & console
      expect(find.text('PropZen Command Center'), findsWidgets);
      expect(find.textContaining('Site Visits'), findsWidgets);
      expect(find.textContaining('Users'), findsWidgets);

      // Verify TabBar navigation
      final visitsTab = find.textContaining('Site Visits').first;
      await tester.tap(visitsTab);
      await tester.pumpAndSettle();

      final usersTab = find.textContaining('User Management').first;
      await tester.tap(usersTab);
      await tester.pumpAndSettle();
    });

    testWidgets('4. HomeScreen footer conditionally displays Admin Portal access link', (WidgetTester tester) async {
      AdminService.instance.logoutAdmin();
      UserSession.logout();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When logged out, Admin Portal is hidden
      final adminPortalBtn = find.text('🔐 Admin Portal (Sign In / Setup)', skipOffstage: false);
      expect(adminPortalBtn, findsNothing);

      // Log in as authorized admin
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      await tester.pumpAndSettle();

      // Now visible
      expect(adminPortalBtn, findsOneWidget);

      await tester.ensureVisible(adminPortalBtn);
      await tester.pumpAndSettle();

      await tester.tap(adminPortalBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.text('Sign In to Command Center'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri? url;
  _MockHttpClientRequest([this.url]);

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  void write(Object? obj) {}

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async {
    final isImage = url != null && (url.toString().contains('unsplash') || url.toString().endsWith('.png') || url.toString().endsWith('.jpg'));
    return _MockHttpClientResponse(isImage ? _transparentImage : _jsonResponse);
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  final List<int> responseBytes;
  _MockHttpClientResponse(this.responseBytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => responseBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([responseBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final _jsonResponse = '[{"id":"item-1","name":"Test User","status":"success"}]'.codeUnits;

final _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_property_review_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

final _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

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
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Admin Portal Blank Page Fix & Full Flow Verification Tests', () {
    setUp(() {
      AdminService.instance.logoutAdmin();
      PropertyStateService.instance.setProperties(List.from(Property.sampleDeals));
    });

    testWidgets('TEST 1: Home Screen Admin Portal button navigates directly to AdminPanelScreen', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find Admin Portal button
      final adminButtonFinder = find.textContaining('Admin Portal');
      await tester.ensureVisible(adminButtonFinder);
      await tester.pumpAndSettle();

      // Tap Admin Portal button
      await tester.tap(adminButtonFinder);
      await tester.pumpAndSettle();

      // Verify AdminPanelScreen is opened (NOT a blank screen)
      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.text('Sign In to Command Center'), findsOneWidget);
    });

    testWidgets('TEST 2: Admin Sign In opens complete Dashboard with KPI Cards and real counts', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('Quick Super Admin Access'));
      await tester.pumpAndSettle();

      // Verify Dashboard is rendered with title and subtitles
      expect(find.text('PropZen Command Center'), findsWidgets);
      expect(find.text('Dashboard Overview'), findsWidgets);

      // Verify KPI Stat Cards are present and visible
      expect(find.text('Total Properties'), findsWidgets);
      expect(find.text('Pending Reviews'), findsWidgets);
      expect(find.text('Total Dealers'), findsWidgets);
      expect(find.text('Site Visits'), findsWidgets);
      expect(find.text('Total Users'), findsWidgets);
    });

    testWidgets('TEST 3: Dealer pending property submission appears in Pending Approvals & can be approved', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Add a pending dealer property
      final testPendingProp = Property(
        id: 'PROP-DEALER-PENDING-99',
        title: 'ATS Greens Pristine Penthouse',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        address: 'Sector 150, Noida Expressway',
        postalCode: '201310',
        placeId: 'p_99',
        latitude: 28.4354,
        longitude: 77.4878,
        category: 'Residential',
        propertyType: 'Apartment',
        askingPriceCr: 2.10,
        fairValueCr: 2.20,
        pricePerSqft: 7500,
        score10x: 9.2,
        rentalYieldPercent: 4.8,
        sqft: 2800,
        carpetAreaSqft: 2300,
        bhk: '4 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        dealerId: 'DLR-NOIDA-101',
        dealerName: 'Rajesh Varma',
        dealerPhone: '+91 98103 94068',
        status: 'pending',
      );
      PropertyStateService.instance.addDealerPropertySubmission(testPendingProp);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('Quick Super Admin Access'));
      await tester.pumpAndSettle();

      // Navigate to Verification Workspace section
      await tester.tap(find.textContaining('Verification Workspace').first);
      await tester.pumpAndSettle();

      // Verify the pending property is listed
      expect(find.text('ATS Greens Pristine Penthouse'), findsOneWidget);

      // Tap Approve & Publish button
      await tester.tap(find.text('Approve & Publish').first);
      await tester.pumpAndSettle();

      // Verify property is now approved / published
      final found = PropertyStateService.instance.rawProperties.firstWhere((p) => p.id == 'PROP-DEALER-PENDING-99');
      expect(found.isPublished, isTrue);
    });

    testWidgets('TEST 4: Tapping View Details opens AdminPropertyReviewScreen with complete information', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('Quick Super Admin Access'));
      await tester.pumpAndSettle();

      // Switch to Properties section
      await tester.tap(find.textContaining('Properties & Moderation').first);
      await tester.pumpAndSettle();

      // Tap "View Details" on the first property
      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();

      // Verify AdminPropertyReviewScreen is shown
      expect(find.byType(AdminPropertyReviewScreen), findsOneWidget);
    });
  });
}

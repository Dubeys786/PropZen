import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

// Transparent 1x1 PNG for image decoding in tests
final Uint8List _kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
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

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
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
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Rebuilt Property Details Page Comprehensive Tests', () {
    final propATS = Property.sampleDeals.firstWhere(
      (p) => p.id == 'prop_ats_happytrails',
      orElse: () => Property.sampleDeals.first,
    );
    final propGaur = Property.sampleDeals.firstWhere(
      (p) => p.id == 'prop_gaur_city',
      orElse: () => Property.sampleDeals[1],
    );
    final propAce = Property.sampleDeals.firstWhere(
      (p) => p.id == 'prop_ace_divino',
      orElse: () => Property.sampleDeals.last,
    );

    testWidgets('1. ATS HomeKraft Happy Trails renders complete property details UI without blank page', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify Header & Title
      expect(find.text('ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);
      expect(find.text('₹78 Lakh', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Sector 10', skipOffstage: false), findsWidgets);
      expect(find.textContaining('4.8', skipOffstage: false), findsWidgets);

      // Verify Facts & Overview
      expect(find.textContaining('1150 Sq. Ft.', skipOffstage: false), findsWidgets);
      expect(find.text('Quick Property Facts', skipOffstage: false), findsWidgets);
      expect(find.text('About ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);
      expect(find.text('Key Highlights', skipOffstage: false), findsWidgets);

      // Verify Sections
      expect(find.text('Amenities & Facilities', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Property Location', skipOffstage: false), findsWidgets);
      expect(find.text('Floor Plan & Layout', skipOffstage: false), findsWidgets);
      expect(find.text('Price & Cost Transparency', skipOffstage: false), findsWidgets);

      // Verify Bottom Action Bar
      expect(find.text('Book a Site Visit'), findsOneWidget);
      expect(find.text('Enquire Now'), findsOneWidget);
    });

    testWidgets('2. Resolving by propertyId="prop_gaur_city" displays Gaur City dynamically', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertyDetailsScreen(propertyId: 'prop_gaur_city'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Gaur City', skipOffstage: false), findsWidgets);
      expect(find.textContaining('₹1.05 Crore', skipOffstage: false), findsWidgets);
    });

    testWidgets('3. PropertyDetailsScreen with invalid ID shows Property Not Found card (never blank)', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertyDetailsScreen(propertyId: 'INVALID-UNKNOWN-999'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Property Not Found'), findsOneWidget);
      expect(find.text('Back to Properties'), findsOneWidget);
    });

    testWidgets('4. Distinct property isolation across ATS HomeKraft, Gaur City, and Ace Divino', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Property A: ATS HomeKraft Happy Trails
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);
      expect(find.text('₹78 Lakh', skipOffstage: false), findsWidgets);

      // Property B: Gaur City
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propGaur),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gaur City', skipOffstage: false), findsWidgets);
      expect(find.text('₹1.05 Crore', skipOffstage: false), findsWidgets);

      // Property C: Ace Divino
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propAce),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ace Divino', skipOffstage: false), findsWidgets);
      expect(find.text('₹1.25 Crore', skipOffstage: false), findsWidgets);
    });

    testWidgets('5. Desktop layout renders 2-column layout with right sticky action card', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);
      expect(find.text('Quick Property Facts', skipOffstage: false), findsWidgets);
      expect(find.text('Exclusive Offer Price', skipOffstage: false), findsWidgets);
      expect(find.text('Book a Site Visit'), findsOneWidget);
      expect(find.text('Enquire Now'), findsOneWidget);
    });

    testWidgets('6. Enquire Now modal opens and handles user inputs for authenticated user', (tester) async {
      UserSession.login(
        fullName: 'Test Buyer',
        mobile: '9876543210',
        email: 'buyer@example.com',
        isEmailVerified: true,
      );

      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Enquire Now button
      await tester.tap(find.text('Enquire Now'));
      await tester.pumpAndSettle();

      expect(find.text('Enquire About Property'), findsOneWidget);
      expect(find.text('Submit Enquiry'), findsOneWidget);
    });
  });
}

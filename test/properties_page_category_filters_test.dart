import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/property_search_screen.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
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

  setUp(() {
    PropertyStateService.instance.setProperties(Property.sampleDeals);
  });

  group('Properties Page Category Filtering & Real Data Tests', () {
    testWidgets('TEST 1: Noida Extension chip returns 3+ properties and updates heading', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Noida Extension" chip
      await tester.tap(find.text('Noida Extension'));
      await tester.pumpAndSettle();

      // Verify header count shows at least 3 matching properties
      expect(find.textContaining('Results for "Noida Extension"'), findsOneWidget);

      // Verify all 3 required properties exist
      expect(find.text('ATS HomeKraft Happy Trails'), findsOneWidget);
      expect(find.text('Gaur City'), findsOneWidget);
      expect(find.text('Ace Divino'), findsOneWidget);
    });

    testWidgets('TEST 2: Sector 150 chip returns 3+ properties and updates heading', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Sector 150" chip
      await tester.tap(find.text('Sector 150'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "Sector 150" (3)'), findsOneWidget);
      expect(find.text('Tata Eureka Park'), findsOneWidget);
      expect(find.text('ATS Pious Orchards'), findsOneWidget);
      expect(find.text('Godrej Palm Retreat'), findsOneWidget);
    });

    testWidgets('TEST 3: Yamuna Expressway chip returns 3+ properties and updates heading', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Yamuna Expressway" chip
      await tester.tap(find.text('Yamuna Expressway'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "Yamuna Expressway" (3)'), findsOneWidget);
      expect(find.text('Jaypee Greens Wish Town'), findsOneWidget);
      expect(find.text('Gaur Yamuna City'), findsOneWidget);
      expect(find.text('ATS Allure'), findsOneWidget);
    });

    testWidgets('TEST 4: 2 BHK Apartments chip returns ONLY 2 BHK properties', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "2 BHK Apartments" chip
      await tester.tap(find.text('2 BHK Apartments'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "2 BHK Apartments" (3)'), findsOneWidget);
      expect(find.text('ATS HomeKraft Happy Trails'), findsOneWidget);
      expect(find.text('Tata Eureka Park'), findsOneWidget);
      expect(find.text('Jaypee Greens Wish Town'), findsOneWidget);

      // Verify no 3 BHK or Villa properties
      expect(find.text('Gaur City'), findsNothing);
      expect(find.text('ATS Pious Orchards'), findsNothing);
      expect(find.text('Gaur Saundaryam Villas'), findsNothing);
    });

    testWidgets('TEST 5: 3 BHK Apartments chip returns ONLY 3 BHK properties', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "3 BHK Apartments" chip
      await tester.tap(find.text('3 BHK Apartments'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "3 BHK Apartments" (6)'), findsOneWidget);
      expect(find.text('Gaur City'), findsOneWidget);
      expect(find.text('ATS Pious Orchards'), findsOneWidget);
      expect(find.text('Godrej Palm Retreat'), findsOneWidget);
      expect(find.text('Gaur Yamuna City'), findsOneWidget);
      expect(find.text('ATS Allure'), findsOneWidget);
      expect(find.text('Ace Divino'), findsOneWidget);

      // Verify no 2 BHK properties
      expect(find.text('ATS HomeKraft Happy Trails'), findsNothing);
      expect(find.text('Tata Eureka Park'), findsNothing);
    });

    testWidgets('TEST 6: Luxury Villas chip returns ONLY Villa properties', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Luxury Villas" chip
      await tester.tap(find.text('Luxury Villas'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "Luxury Villas" (3)'), findsOneWidget);
      expect(find.text('Gaur Saundaryam Villas'), findsOneWidget);
      expect(find.text('Godrej Golf Links Villa'), findsOneWidget);
      expect(find.text('Jaypee Greens Villa'), findsOneWidget);
      expect(find.text('ATS HomeKraft Happy Trails'), findsNothing);
    });

    testWidgets('TEST 7: Commercial Offices chip returns ONLY Commercial Office properties', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll and Tap "Commercial Offices" chip
      final commFinder = find.text('Commercial Offices');
      await tester.ensureVisible(commFinder);
      await tester.pumpAndSettle();
      await tester.tap(commFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "Commercial Offices" (3)'), findsOneWidget);
      expect(find.text('ATS Bouquet'), findsOneWidget);
      expect(find.text('Advant Navis Business Park'), findsOneWidget);
      expect(find.text('Logix Cyber Park'), findsOneWidget);
      expect(find.text('Gaur City'), findsNothing);
    });

    testWidgets('TEST 8: Ready to Move Flats chip returns ONLY Ready to Move properties', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll and Tap "Ready to Move Flats" chip
      final rtmFinder = find.text('Ready to Move Flats');
      await tester.ensureVisible(rtmFinder);
      await tester.pumpAndSettle();
      await tester.tap(rtmFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Results for "Ready to Move Flats" (6)'), findsOneWidget);
      expect(find.text('ATS HomeKraft Happy Trails'), findsOneWidget);
      expect(find.text('Tata Eureka Park'), findsOneWidget);
      expect(find.text('Gaur City'), findsOneWidget);
      expect(find.text('Jaypee Greens Wish Town'), findsOneWidget);
      expect(find.text('Gaur Yamuna City'), findsOneWidget);
      expect(find.text('ATS Pious Orchards'), findsOneWidget);

      // Verify Under Construction properties are excluded
      expect(find.text('Ace Divino'), findsNothing);
      expect(find.text('Godrej Palm Retreat'), findsNothing);
      expect(find.text('ATS Allure'), findsNothing);
    });

    testWidgets('TEST 9: Search Query + Category Chip Combination and Clear Filters', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select "2 BHK Apartments" category
      await tester.tap(find.text('2 BHK Apartments'));
      await tester.pumpAndSettle();

      // Enter search query "Noida Extension"
      await tester.enterText(find.byType(TextField), 'Noida Extension');
      await tester.pumpAndSettle();

      // Only ATS HomeKraft Happy Trails matches both 2 BHK and Noida Extension
      expect(find.textContaining('Results for "2 BHK Apartments" matching "Noida Extension" (1)'), findsOneWidget);
      expect(find.text('ATS HomeKraft Happy Trails'), findsOneWidget);
      expect(find.text('Tata Eureka Park'), findsNothing);
      expect(find.text('Gaur City'), findsNothing);

      // Tap Clear Search button
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      // Category filter should still be active (3 items)
      expect(find.textContaining('Results for "2 BHK Apartments" (3)'), findsOneWidget);

      // Tap Clear Filters
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      // Should show all available properties
      expect(find.textContaining('All Available Properties (15)'), findsOneWidget);
    });

    testWidgets('TEST 10: Tapping View Details on Property Card opens PropertyDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PropertySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap View Details on first card
      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();

      // Verify PropertyDetailsScreen opened
      expect(find.byType(PropertyDetailsScreen), findsOneWidget);
      expect(find.textContaining('ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);
    });
  });
}

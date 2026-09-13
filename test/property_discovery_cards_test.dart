import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/ai_recommendations_screen.dart';
import 'package:dealghar_ncr_10x/screens/near_me_properties_screen.dart';
import 'package:dealghar_ncr_10x/screens/trending_projects_screen.dart';
import 'package:dealghar_ncr_10x/screens/price_drop_deals_screen.dart';
import 'package:dealghar_ncr_10x/screens/new_launch_projects_screen.dart';
import 'package:dealghar_ncr_10x/screens/top_builders_screen.dart';
import 'package:dealghar_ncr_10x/screens/builder_details_screen.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

// 1x1 transparent PNG for image mocking
final _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
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
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  void write(Object? obj) {}
  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
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
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() {
    final stateService = PropertyStateService.instance;
    stateService.setProperties(List.from(Property.sampleDeals));
  });

  group('Property Discovery Cards Test Suite', () {
    testWidgets('TEST 1: AiRecommendationsScreen renders matching scores and published properties', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AiRecommendationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Recommendations'), findsOneWidget);
      expect(find.text('Curated AI Recommendations'), findsOneWidget);
      expect(find.text('Propzen 10X Match Engine'), findsOneWidget);
      expect(find.textContaining('Match'), findsWidgets);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('TEST 2: NearMePropertiesScreen calculates real distance and supports radius filters', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: NearMePropertiesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Properties Near Me'), findsOneWidget);
      expect(find.text('GPS ACTIVE'), findsOneWidget);
      expect(find.textContaining('km away'), findsWidgets);
      expect(find.text('All NCR'), findsOneWidget);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('TEST 3: TrendingProjectsScreen displays trending ranks and scores', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: TrendingProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trending Projects in NCR'), findsOneWidget);
      expect(find.text('Most In-Demand Projects'), findsOneWidget);
      expect(find.textContaining('Trending'), findsWidgets);
      expect(find.textContaining('Score:'), findsWidgets);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('TEST 4: PriceDropDealsScreen shows genuine price reductions and savings', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PriceDropDealsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Price Drop Deals'), findsOneWidget);
      expect(find.text('Exclusive Price Drop Deals'), findsOneWidget);
      expect(find.textContaining('Price Drop'), findsWidgets);
      expect(find.textContaining('Save'), findsWidgets);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('TEST 5: NewLaunchProjectsScreen shows new launch badges and possession dates', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: NewLaunchProjectsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Launch Projects'), findsOneWidget);
      expect(find.text('Exclusive New Launches in NCR'), findsOneWidget);
      expect(find.text('All Launches'), findsOneWidget);
      expect(find.text('Pre-Launch'), findsOneWidget);
      expect(find.text('Under Construction'), findsWidgets);
      expect(find.textContaining('Possession:'), findsWidgets);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('TEST 6: TopBuildersScreen lists verified builders and navigates to BuilderDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: TopBuildersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Builders & Developers'), findsOneWidget);
      expect(find.text('NCR’s Most Trusted Builders'), findsOneWidget);
      expect(find.text('Skyline Infratech'), findsOneWidget);
      expect(find.text('Elite Group'), findsOneWidget);
      expect(find.textContaining('View Properties'), findsWidgets);

      // Verify BuilderDetailsScreen renders builder properties portfolio
      await tester.pumpWidget(
        const MaterialApp(
          home: BuilderDetailsScreen(builderName: 'Godrej Properties'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Published Properties by Godrej Properties'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('TEST 7: HomeScreen quick action cards route to dedicated screens on tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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

      // Card 1: AI Recommendations
      expect(find.text('AI Recommendations'), findsWidgets);
      await tester.tap(find.text('AI Recommendations').first);
      await tester.pumpAndSettle();
      expect(find.text('Curated AI Recommendations'), findsOneWidget);

      // Pop back to Home
      Navigator.of(tester.element(find.text('Curated AI Recommendations'))).pop();
      await tester.pumpAndSettle();

      // Card 2: Near Me
      expect(find.text('Near Me'), findsWidgets);
      await tester.tap(find.text('Near Me').first);
      await tester.pumpAndSettle();
      expect(find.text('Properties Near Me'), findsOneWidget);

      // Pop back to Home
      Navigator.of(tester.element(find.text('Properties Near Me'))).pop();
      await tester.pumpAndSettle();

      // Card 3: Trending Projects
      expect(find.text('Trending Projects'), findsWidgets);
      await tester.tap(find.text('Trending Projects').first);
      await tester.pumpAndSettle();
      expect(find.text('Trending Projects in NCR'), findsOneWidget);

      // Pop back to Home
      Navigator.of(tester.element(find.text('Trending Projects in NCR'))).pop();
      await tester.pumpAndSettle();

      // Card 4: Price Drop Deals
      expect(find.text('Price Drop Deals'), findsWidgets);
      await tester.tap(find.text('Price Drop Deals').first);
      await tester.pumpAndSettle();
      expect(find.text('Exclusive Price Drop Deals'), findsOneWidget);

      // Pop back to Home
      Navigator.of(tester.element(find.text('Exclusive Price Drop Deals'))).pop();
      await tester.pumpAndSettle();

      // Card 5: New Launch Projects
      expect(find.text('New Launch Projects'), findsWidgets);
      await tester.tap(find.text('New Launch Projects').first);
      await tester.pumpAndSettle();
      expect(find.text('Exclusive New Launches in NCR'), findsOneWidget);

      // Pop back to Home
      Navigator.of(tester.element(find.text('Exclusive New Launches in NCR'))).pop();
      await tester.pumpAndSettle();

      // Card 6: Top Builders
      expect(find.text('Top Builders'), findsWidgets);
      await tester.tap(find.text('Top Builders').first);
      await tester.pumpAndSettle();
      expect(find.text('Top Builders & Developers'), findsOneWidget);
    });
  });
}

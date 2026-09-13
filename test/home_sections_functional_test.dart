import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Home Page Sections Functional Tests', () {
    setUp(() {
      PropertyStateService.instance.setProperties(List.from(Property.sampleDeals));
    });

    test('1. Category Filtering Engine accurately filters categories', () {
      // 1. Buy - Should return purchase properties (excluding PG)
      final buyDeals = PropertyFilterEngine.filter(
        sourceList: Property.sampleDeals,
        selectedCategory: 'Buy',
      );
      expect(buyDeals.isNotEmpty, isTrue);
      expect(buyDeals.every((p) => p.category.toLowerCase() != 'pg'), isTrue);

      // 2. Rent - Should return rental / high yield flats
      final rentDeals = PropertyFilterEngine.filter(
        sourceList: Property.sampleDeals,
        selectedCategory: 'Rent',
      );
      expect(rentDeals.isNotEmpty, isTrue);
      expect(rentDeals.any((p) => p.rentalYieldPercent >= 4.5), isTrue);

      // 3. Residential - Should return residential properties
      final resDeals = PropertyFilterEngine.filter(
        sourceList: Property.sampleDeals,
        selectedCategory: 'Residential',
      );
      expect(resDeals.isNotEmpty, isTrue);
      expect(resDeals.every((p) => p.category.toLowerCase() == 'residential'), isTrue);

      // 4. Commercial - Should return commercial office/shops
      final comDeals = PropertyFilterEngine.filter(
        sourceList: Property.sampleDeals,
        selectedCategory: 'Commercial',
      );
      expect(comDeals.isNotEmpty, isTrue);
      expect(comDeals.every((p) => p.category.toLowerCase() == 'commercial'), isTrue);
    });

    test('2. World-Class Amenities Filter Engine accurately filters amenities', () {
      final allAmenities = [
        'Club House',
        'Gym',
        'Swimming Pool',
        'Security',
        'Power Backup',
      ];

      for (final amenity in allAmenities) {
        final filtered = PropertyFilterEngine.filter(
          sourceList: Property.sampleDeals,
          selectedAmenities: {amenity},
        );
        expect(filtered.isNotEmpty, isTrue, reason: 'Amenity $amenity should match sample deals');
      }

      // Test multi-amenity (AND) filtering
      final multiFilter = PropertyFilterEngine.filter(
        sourceList: Property.sampleDeals,
        selectedAmenities: {'Gym', 'Swimming Pool'},
      );
      expect(multiFilter.isNotEmpty, isTrue);
      for (final p in multiFilter) {
        expect(p.amenities.any((a) => a.toLowerCase().contains('gym')), isTrue);
        expect(p.amenities.any((a) => a.toLowerCase().contains('pool')), isTrue);
      }
    });

    test('3. Upcoming Projects & New Launches exist in dataset with complete details', () {
      final expectedProjects = [
        {'id': 'prop_ats_happytrails', 'title': 'ATS HomeKraft Happy Trails'},
        {'id': 'prop_gaur_city', 'title': 'Gaur City'},
        {'id': 'prop_advant_navis', 'title': 'Advant Navis Business Park'},
      ];

      for (final proj in expectedProjects) {
        final match = Property.sampleDeals.firstWhere(
          (p) => p.id == proj['id'] && p.title.contains(proj['title']!),
        );
        expect(match, isNotNull);
        expect(match.askingPriceCr, greaterThan(0));
        expect(match.amenities.isNotEmpty, isTrue);
        expect(match.imageUrl.isNotEmpty, isTrue);
      }
    });

    testWidgets('4. HomeScreen UI category selection, upcoming projects, and amenities interaction', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(onNavigateTab: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Category filter tabs exist
      expect(find.text('Buy Properties'), findsWidgets);
      expect(find.text('Rent Properties'), findsWidgets);
      expect(find.text('PG/Co-living'), findsWidgets);
      expect(find.text('Commercial Spaces'), findsWidgets);

      // 2. Verify Upcoming Projects cards exist
      expect(find.text('Upcoming Projects', skipOffstage: false), findsOneWidget);
      final propFinder = find.text('ATS HomeKraft Happy Trails', skipOffstage: false);
      await tester.scrollUntilVisible(
        propFinder.first,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(propFinder, findsWidgets);

      // Tap on a property card to open details
      await tester.tap(propFinder.first);
      await tester.pumpAndSettle();

      // Verify PropertyDetailsScreen opened
      expect(find.byType(PropertyDetailsScreen), findsOneWidget);
      expect(find.text('ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);

      // Go back
      final backBtn = find.byTooltip('Back');
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
      } else {
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // 3. Verify Amenities section cards exist
      expect(find.text('Infinity Pool', skipOffstage: false), findsWidgets);
      expect(find.text('3-Tier Gym', skipOffstage: false), findsWidgets);
      expect(find.text('Sports Courts', skipOffstage: false), findsWidgets);
      expect(find.text('80% Green Parks', skipOffstage: false), findsWidgets);
      expect(find.text('EV Charging', skipOffstage: false), findsWidgets);
      expect(find.text('3-Tier Security', skipOffstage: false), findsWidgets);
      expect(find.text('Grand Clubhouse', skipOffstage: false), findsWidgets);
      expect(find.text('Kids Play Zone', skipOffstage: false), findsWidgets);
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
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

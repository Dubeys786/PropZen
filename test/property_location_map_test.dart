import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/widgets/interactive_property_map.dart';

final _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
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

  group('Web-Compatible Interactive Property Location Map Tests', () {
    final stateService = PropertyStateService.instance;
    final propATS = stateService.allProperties.firstWhere(
      (p) => p.id == 'prop_ats_happytrails',
      orElse: () => stateService.allProperties.first,
    );
    final propGaur = stateService.allProperties.firstWhere(
      (p) => p.id == 'prop_gaur_city',
      orElse: () => stateService.allProperties[1],
    );

    test('TEST 1: Property model has valid address, coordinates and nearby facilities', () {
      expect(propATS.latitude, inInclusiveRange(28.0, 29.0));
      expect(propATS.longitude, inInclusiveRange(77.0, 78.0));
      expect(propATS.fullAddress, isNotEmpty);
      expect(propATS.sector, isNotEmpty);
      expect(propATS.city, isNotEmpty);
      expect(propATS.nearby, isNotEmpty);
    });

    testWidgets('TEST 2: PropertyDetailsScreen embeds InteractivePropertyMap without platform exceptions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(
            property: propATS,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InteractivePropertyMap), findsOneWidget);
      expect(find.text('Property Location & Map', skipOffstage: false), findsWidgets);
      expect(find.text('FULL ADDRESS', skipOffstage: false), findsWidgets);
      expect(find.text(propATS.fullAddress, skipOffstage: false), findsWidgets);
    });

    testWidgets('TEST 3: InteractivePropertyMap renders zoom & layer controls dynamically', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractivePropertyMap(
              property: propATS,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Property Location'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('Terrain'), findsOneWidget);
      expect(find.text('Get Directions'), findsOneWidget);

      // Tap Satellite layer
      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();

      // Tap Terrain layer
      await tester.tap(find.text('Terrain'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST 4: Map dynamically adapts coordinates between different properties', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Property 1: ATS
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractivePropertyMap(
              property: propATS,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ATS HomeKraft Happy Trails', skipOffstage: false), findsWidgets);

      // Property 2: Gaur City
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractivePropertyMap(
              property: propGaur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gaur City', skipOffstage: false), findsWidgets);
    });
  });
}

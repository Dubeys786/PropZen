import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/ar_capability_helper.dart';
import 'package:dealghar_ncr_10x/services/property_visualization_service.dart';
import 'package:dealghar_ncr_10x/widgets/property_ar_view_dialog.dart';
import 'package:dealghar_ncr_10x/widgets/property_visualization_hub.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/property_ar_screen.dart';

final List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

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

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('PropZen AR Property Experience & Anti-External Redirect Tests', () {
    setUp(() {
      ArCapabilityHelper.resetPermissionState();
    });

    test('1. Security: External demo URLs and demo models are strictly rejected', () {
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl(
          'https://modelviewer.dev/examples/augmentedreality/?src=test.glb',
        ),
        isTrue,
      );
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl(
          'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
        ),
        isTrue,
      );
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl(
          'https://googlechromelabs.github.io/model-viewer/examples/test.glb',
        ),
        isTrue,
      );
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl('https://example.com/robot.glb'),
        isTrue,
      );
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl('https://example.com/chair.glb'),
        isTrue,
      );
      expect(PropertyVisualizationService.isDemoOrUnsafeModelUrl(null), isTrue);
      expect(PropertyVisualizationService.isDemoOrUnsafeModelUrl(''), isTrue);

      // Genuine PropZen architectural twin models are allowed
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl(
          'https://propzen.ai/models/properties/ats_pious_orchards_ar.glb',
        ),
        isFalse,
      );
      expect(
        PropertyVisualizationService.isDemoOrUnsafeModelUrl(
          'https://propzen.ai/models/properties/ats_happytrails_ar.glb',
        ),
        isFalse,
      );
    });

    test('2. Intent URL Generation: Never returns external demo/documentation URL', () {
      final service = PropertyVisualizationService.instance;

      // Demo URL input produces empty string (blocked)
      final demoArUrl = service.generateArLaunchUrl(
        glbUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
        propertyTitle: 'Demo Property',
      );
      expect(demoArUrl, isEmpty);
      expect(demoArUrl, isNot(contains('modelviewer.dev')));

      // Legitimate model URL generates native Android SceneViewer intent (never a website)
      final validArUrl = service.generateArLaunchUrl(
        glbUrl: 'https://propzen.ai/models/properties/ats_pious_orchards_ar.glb',
        propertyTitle: 'ATS Pious Orchards',
      );

      expect(validArUrl, isNot(contains('modelviewer.dev')));
      expect(validArUrl, isNot(contains('googlechromelabs')));
      expect(validArUrl, contains('intent://arvr.google.com/scene-viewer'));
      expect(validArUrl, contains('ats_pious_orchards_ar.glb'));
    });

    test('3. Selected Property Model Validation: Genuine models validated, missing models flagged', () {
      final service = PropertyVisualizationService.instance;

      // ATS Pious Orchards has dedicated AR model
      final atsPious = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_pious_150');
      expect(service.hasValidArModel(atsPious), isTrue);
      expect(atsPious.arModelUrl, contains('ats_pious_orchards_ar.glb'));
      expect(atsPious.arModelUrl, isNot(contains('Astronaut.glb')));
      expect(atsPious.arModelUrl, isNot(contains('modelviewer.dev')));

      // Gaur City has arModelUrl == null
      final gaurCity = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');
      expect(service.hasValidArModel(gaurCity), isFalse);
    });

    testWidgets('4. UI Test: AR Property Placement Dialog renders 5 steps and PropZen styling', (tester) async {
      final atsPious = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_pious_150');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyArViewDialog(property: atsPious),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and styling
      expect(find.text('AR Property Placement'), findsOneWidget);
      expect(find.text('Experience ${atsPious.title} in Augmented Reality'), findsOneWidget);

      // Verify Step 1
      expect(find.text('Step 1: Find a Flat Surface'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Explore in 3D'), findsOneWidget);
      expect(find.text('Launch AR View'), findsOneWidget);

      // Advance to Step 2
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2: Scan Surroundings'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('5. Fallback Test: Property without AR model shows "AR model is currently unavailable"', (tester) async {
      final gaurCity = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyArViewDialog(property: gaurCity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Launch AR View
      await tester.tap(find.text('Launch AR View'));
      await tester.pumpAndSettle();

      // Verify model unavailable notice
      expect(find.text('AR model is currently unavailable for this property.'), findsOneWidget);
      expect(find.text('Explore in 3D'), findsOneWidget);
      expect(find.text('Back to Steps'), findsOneWidget);

      // Verify Back to Steps returns to instructions
      await tester.tap(find.text('Back to Steps'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1: Find a Flat Surface'), findsOneWidget);
    });

    testWidgets('6. Fallback Test: Desktop / Unsupported device shows "AR is not supported on this device/browser"', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final atsPious = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_pious_150');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PropertyArViewDialog(property: atsPious),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Launch AR on desktop environment
        await tester.tap(find.text('Launch AR View'));
        await tester.pumpAndSettle();

        // Desktop platform must show "AR is not supported on this device/browser."
        expect(find.text('AR is not supported on this device/browser.'), findsOneWidget);
        expect(find.text('Explore in 3D'), findsWidgets);
        expect(find.text('Back to Steps'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('7. Permission Test: Graceful handling of camera permission prompt and denial', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        ArCapabilityHelper.resetPermissionState();
        final atsPious = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_pious_150');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PropertyArViewDialog(property: atsPious),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // On mobile with permission not yet granted, should show Camera Access Required explanation
        await tester.tap(find.text('Launch AR View'));
        await tester.pumpAndSettle();

        expect(find.text('Camera Access Required'), findsOneWidget);
        expect(find.textContaining('PropZen needs access to your device camera'), findsOneWidget);
        expect(find.text('Allow Camera'), findsOneWidget);
        expect(find.text('Explore in 3D'), findsWidgets);

        // Now test when permission was previously denied
        ArCapabilityHelper.markPermissionDenied();
        await tester.tap(find.text('Back to Steps'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Launch AR View'));
        await tester.pumpAndSettle();

        expect(find.text('Camera Permission Denied'), findsOneWidget);
        expect(find.textContaining('Camera access was denied or is restricted'), findsOneWidget);
        expect(find.text('Explore in 3D'), findsWidgets);
      } finally {
        ArCapabilityHelper.resetPermissionState();
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('8. Route Test: /property/:id/ar correctly generates PropertyArScreen with selected property details', (tester) async {
      final atsPious = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_pious_150');

      // Verify route generation
      final generatedRoute = AppRoutes.generateRoute(
        RouteSettings(
          name: AppRoutes.propertyArRoute(atsPious.id),
          arguments: atsPious,
        ),
      );
      expect(generatedRoute, isA<MaterialPageRoute>());

      // Pump PropertyArScreen directly
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyArScreen(property: atsPious),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PropertyArScreen), findsOneWidget);
      expect(find.text(atsPious.title), findsWidgets);
      expect(find.text('AR Property Placement'), findsOneWidget);
      expect(find.text('Step 1: Find a Flat Surface'), findsOneWidget);
      expect(find.text('Explore in 3D'), findsOneWidget);
      expect(find.text('Launch AR View'), findsOneWidget);
    });

    testWidgets('9. Hub Test: "View in AR" button opens the selected property AR experience', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final atsPious = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_pious_150');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyVisualizationHub(property: atsPious),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Card 3 "View in AR"
      expect(find.text('View in AR'), findsOneWidget);
      final ctaFinder = find.text('Try AR View →');
      expect(ctaFinder, findsOneWidget);

      await tester.ensureVisible(ctaFinder);
      await tester.pumpAndSettle();
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      // Verify that user transitioned to PropZen AR experience for ATS Pious Orchards
      expect(find.byType(PropertyArScreen), findsOneWidget);
      expect(find.text(atsPious.title), findsWidgets);
      expect(find.text('AR Property Placement'), findsOneWidget);
    });

    test('10. Verification: AR URL generation returns empty string for desktop/unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final service = PropertyVisualizationService.instance;
        final url = service.generateArLaunchUrl(
          glbUrl: 'https://propzen.ai/models/properties/ats_pious_orchards_ar.glb',
          propertyTitle: 'ATS Pious Orchards',
        );
        expect(url, isEmpty, reason: 'Must not generate intent:// on desktop platforms');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}


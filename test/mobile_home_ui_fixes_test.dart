import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_video_modal.dart';

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

  group('PropZen Mobile Home Screen & Header UI Fixes', () {
    const mobileBreakpoints = [
      Size(320, 700), // ultra compact mobile
      Size(360, 800), // standard android
      Size(375, 812), // iPhone SE / Mini
      Size(390, 844), // iPhone 12/13/14
      Size(412, 915), // Pixel / Samsung
      Size(430, 932), // iPhone Pro Max
      Size(768, 1024), // Tablet
      Size(1024, 768), // Large Tablet / Small Laptop
      Size(1366, 768), // Standard Desktop
      Size(1440, 900), // Wide Desktop
    ];

    testWidgets('TEST 1: Responsive Breakpoint Matrix verifies zero overflow at all screen sizes', (tester) async {
      for (final size in mobileBreakpoints) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: MainShell(),
          ),
        );
        await tester.pump();

        // Check logo exists & no exceptions thrown
        expect(find.byType(Image), findsWidgets);
        expect(find.text('Find Your Perfect\nProperty with Propzen'), findsOneWidget);
        expect(find.text('Search Properties'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('TEST 2: Mobile Header organizes secondary actions into Hamburger Popup Menu without crowding', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // Find hamburger menu
      final popupFinder = find.byType(PopupMenuButton<int>);
      expect(popupFinder, findsOneWidget);

      // Open popup menu
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      // Check essential secondary mobile items are present
      expect(find.text('Favorites / Saved'), findsOneWidget);
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('Offers & Deals 🎁'), findsOneWidget);
      expect(find.text('My Profile 👤'), findsOneWidget);
    });

    testWidgets('TEST 3: Watch Video button opens In-App PropzenVideoModal with player controls', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // Tap Watch Video button
      final watchVideoFinder = find.text('Watch Video');
      expect(watchVideoFinder, findsOneWidget);
      await tester.tap(watchVideoFinder);
      await tester.pumpAndSettle();

      // Verify Video Modal is presented inside the app
      expect(find.byType(PropzenVideoModal), findsOneWidget);
      expect(find.text('PropZen Property Experience'), findsOneWidget);
      expect(find.text('4K HDR'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Tap Close button in video modal
      final closeFinder = find.byTooltip('Close Video');
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();

      // Verify modal is dismissed and returned to Home screen
      expect(find.byType(PropzenVideoModal), findsNothing);
      expect(find.text('Find Your Perfect\nProperty with Propzen'), findsOneWidget);
    });

    testWidgets('TEST 4: Search Properties purple button is completely visible with label and icon', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify Search Properties button is visible
      expect(find.text('Search Properties'), findsOneWidget);
      expect(find.byIcon(LucideIcons.search), findsWidgets);
    });
  });
}

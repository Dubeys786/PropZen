import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/market_hub_screen.dart';

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

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Mobile Header Single Menu & Market Intelligence Test Suite', () {
    final mobileWidths = [320.0, 375.0, 390.0, 414.0];

    for (final width in mobileWidths) {
      testWidgets('Mobile view (${width}px): Only ONE hamburger menu exists on RIGHT side, Logo on LEFT', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: MainShell(),
          ),
        );
        await tester.pump();

        // 1. Verify exactly ONE hamburger icon exists
        final menuFinder = find.byIcon(LucideIcons.menu);
        expect(menuFinder, findsOneWidget);

        // 2. Verify it is a PopupMenuButton on the RIGHT side
        final popupFinder = find.byType(PopupMenuButton<int>);
        expect(popupFinder, findsOneWidget);

        final menuPosition = tester.getCenter(menuFinder);
        expect(menuPosition.dx, greaterThan(width / 2), reason: 'Hamburger menu must be on the RIGHT side');

        // 3. Verify NO DrawerButton or left hamburger icon exists
        expect(find.byType(DrawerButton), findsNothing);

        // 4. Verify PropZen Logo exists on the left
        final logoFinder = find.byType(Image);
        expect(logoFinder, findsWidgets);
        final firstLogoPos = tester.getTopLeft(logoFinder.first);
        expect(firstLogoPos.dx, lessThan(width / 2), reason: 'Logo must be on the LEFT side');

        // 5. Open right menu
        await tester.tap(menuFinder);
        await tester.pumpAndSettle();

        // 6. Verify Market Intelligence is present in the menu
        final marketIntelFinder = find.text('Market Intelligence 📊');
        expect(marketIntelFinder, findsOneWidget);

        // 7. Verify essential options exist
        expect(find.text('Properties'), findsWidgets);
        expect(find.text('AI Advisor'), findsWidgets);
        expect(find.text('Services Hub'), findsWidgets);
        expect(find.text('Dealers Directory'), findsWidgets);
        expect(find.text('Advanced Filters'), findsWidgets);
        expect(find.text('Compare Properties'), findsWidgets);
        expect(find.text('Loan Calculator'), findsWidgets);

        // 8. Tap Market Intelligence and verify navigation
        await tester.tap(marketIntelFinder);
        await tester.pumpAndSettle();
        expect(find.byType(MarketHubScreen), findsOneWidget);
      });
    }

    testWidgets('Tablet view (768px): Only ONE hamburger menu on RIGHT side and navigates correctly', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // Only ONE hamburger icon exists
      final menuFinder = find.byIcon(LucideIcons.menu);
      expect(menuFinder, findsOneWidget);
      expect(find.byType(DrawerButton), findsNothing);

      // Open right menu
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();

      expect(find.text('Market Intelligence 📊'), findsOneWidget);
      await tester.tap(find.text('Market Intelligence 📊'));
      await tester.pumpAndSettle();
      expect(find.byType(MarketHubScreen), findsOneWidget);
    });

    testWidgets('Desktop view (1200px): Preserves desktop navigation with Market Intelligence link', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // No hamburger menu on desktop
      expect(find.byIcon(LucideIcons.menu), findsNothing);
      expect(find.byType(DrawerButton), findsNothing);

      // Desktop nav links exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('AI Advisor'), findsOneWidget);
      expect(find.text('Services Hub'), findsOneWidget);
      expect(find.text('Market Intelligence'), findsOneWidget);
      expect(find.text('Dealers Directory'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);

      // Tap Market Intelligence
      await tester.tap(find.text('Market Intelligence'));
      await tester.pumpAndSettle();
      expect(find.byType(MarketHubScreen), findsOneWidget);
    });
  });
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Home Page Top Navigation & Section Scrolling Tests', () {
    testWidgets('HomeScreen renders with top search and property listings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              onNavigateTab: (idx) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('MainShell renders top navigation items and triggers smooth section scrolling', (WidgetTester tester) async {
      // Set desktop window size
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all desktop top nav items are visible
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Properties'), findsWidgets);
      expect(find.text('Deals'), findsWidgets);
      expect(find.text('AI Advisor'), findsWidgets);
      expect(find.text('Services Hub'), findsWidgets);
      expect(find.text('Dealers Directory'), findsWidgets);
      expect(find.text('Market Intelligence'), findsWidgets);
      expect(find.text('Compare'), findsWidgets);

      Finder navItem(String label) => find.descendant(of: find.byType(AppBar), matching: find.text(label)).first;

      // Tap "Properties" navigation link
      await tester.tap(navItem('Properties'));
      await tester.pumpAndSettle();

      // Tap "AI Advisor" navigation link
      await tester.tap(navItem('AI Advisor'));
      await tester.pumpAndSettle();

      // Tap "Services Hub" navigation link
      await tester.tap(navItem('Services Hub'));
      await tester.pumpAndSettle();

      // Tap "Compare" navigation link
      await tester.tap(navItem('Compare'));
      await tester.pumpAndSettle();

      // Tap "Home" navigation link to return to home
      await tester.tap(navItem('Home'));
      await tester.pumpAndSettle();
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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';

final Uint8List _kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
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
  bool followRedirects = true;
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool? preserveHeaderCase}) {}
  @override
  void set(String name, Object value, {bool? preserveHeaderCase}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_kTransparentImage)
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('PropZen Footer & Creator Credit Tests', () {
    testWidgets('1. HomeScreen footer renders copyright and creator credit "Designed & Developed by Sakshi Dubey"', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll to bottom to ensure footer is in view
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Designed & Developed by Sakshi Dubey'),
        500.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      // Assert complete footer text elements
      expect(find.text('AI-Powered Real Estate Discovery & Intelligence Platform'), findsOneWidget);
      expect(find.text('🔐 Admin Portal (Sign In / Setup)'), findsOneWidget);
      expect(find.text('© 2026 PropZen Technologies Inc. All rights reserved.'), findsOneWidget);
      expect(find.text('Designed & Developed by Sakshi Dubey'), findsOneWidget);
    });

    testWidgets('2. Creator credit has smaller font size and center alignment', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Designed & Developed by Sakshi Dubey'),
        500.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      final copyrightWidget = tester.widget<Text>(find.text('© 2026 PropZen Technologies Inc. All rights reserved.'));
      final creditWidget = tester.widget<Text>(find.text('Designed & Developed by Sakshi Dubey'));

      expect(creditWidget.style?.fontSize, isNotNull);
      expect(copyrightWidget.style?.fontSize, isNotNull);
      expect(creditWidget.style!.fontSize!, lessThan(copyrightWidget.style!.fontSize!));
      expect(creditWidget.textAlign, equals(TextAlign.center));
      expect(copyrightWidget.textAlign, equals(TextAlign.center));
    });

    testWidgets('3. Responsive rendering on Mobile (375x812) does not overflow and preserves creator text', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Designed & Developed by Sakshi Dubey'),
        500.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Designed & Developed by Sakshi Dubey'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

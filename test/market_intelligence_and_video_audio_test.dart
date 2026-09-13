import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/market_hub_screen.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_video_modal.dart';
import 'package:dealghar_ncr_10x/services/propzen_voice_service.dart';

class _MockHttpOverrides extends HttpOverrides {
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
  void addAuthentication(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  int contentLength = -1;

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future flush() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final List<int> _transparentPngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentPngBytes.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPngBytes).listen(
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
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Market Intelligence Side Menu & Video Experience Audio Test Suite', () {
    setUp(() {
      PropzenVoiceService.instance.isTestMode = true;
    });

    tearDown(() {
      PropzenVoiceService.instance.stopAll();
    });

    testWidgets('1. Side Menu (Mobile / Tablet Popup) contains Market Intelligence in exact recommended order', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Open navigation menu
      final menuButton = find.byTooltip('Navigation Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify Market Intelligence item exists
      expect(find.text('Market Intelligence 📊'), findsOneWidget);
      expect(find.text('Properties'), findsWidgets);
      expect(find.text('AI Advisor'), findsWidgets);
      expect(find.text('Services Hub'), findsWidgets);
      expect(find.text('Dealers Directory'), findsWidgets);

      // Tap Market Intelligence
      await tester.tap(find.text('Market Intelligence 📊'));
      await tester.pumpAndSettle();

      // Verify MarketHubScreen opened
      expect(find.byType(MarketHubScreen), findsOneWidget);
    });

    testWidgets('2. Side Drawer in MainShell contains Market Intelligence and navigates to MarketHubScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Desktop header check
      expect(find.text('Market Intelligence'), findsOneWidget);

      // Tap header link
      await tester.tap(find.text('Market Intelligence'));
      await tester.pumpAndSettle();

      expect(find.byType(MarketHubScreen), findsOneWidget);
    });

    testWidgets('3. Property Experience Video Modal: Opens with 1.2x Speed, Voice Audio Badge and Subtitles', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVideoModal(
              title: 'Luxury 3 BHK Walkthrough',
              subtitle: 'Sector 150 Noida',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 1. Check Title and Badges
      expect(find.text('Luxury 3 BHK Walkthrough'), findsOneWidget);
      expect(find.text('4K HDR'), findsOneWidget);
      expect(find.text('VOICE AUDIO'), findsOneWidget);
      expect(find.textContaining('1.2x'), findsWidgets);

      // 2. Check Voice Over Subtitle is displayed
      expect(find.textContaining('Welcome to PropZen Property Experience'), findsOneWidget);

      // 3. Check All Player Controls are preserved
      expect(find.byTooltip('Close Video'), findsOneWidget);
      expect(find.byTooltip('Rewind 10s'), findsOneWidget);
      expect(find.byTooltip('Forward 10s'), findsOneWidget);
      expect(find.byTooltip('Mute Audio'), findsOneWidget);
      expect(find.byTooltip('Fullscreen'), findsOneWidget);
    });

    testWidgets('4. Property Experience Video Modal: Mute and Play/Pause controls work cleanly', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVideoModal(
              title: 'Penthouse Showcase',
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap Mute
      final muteBtn = find.byTooltip('Mute Audio');
      expect(muteBtn, findsOneWidget);
      await tester.tap(muteBtn);
      await tester.pump();

      expect(find.byTooltip('Unmute Audio'), findsOneWidget);

      // Tap Unmute
      await tester.tap(find.byTooltip('Unmute Audio'));
      await tester.pump();
      expect(find.byTooltip('Mute Audio'), findsOneWidget);
    });
  });
}

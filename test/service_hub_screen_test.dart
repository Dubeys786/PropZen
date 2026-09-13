import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/ai_service_tool_data.dart';
import 'package:dealghar_ncr_10x/screens/all_features_screen.dart';

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
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  String? value(String name) => _headers[name.toLowerCase()]?.join(', ');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static final List<int> _kResponseBytes = utf8.encode(jsonEncode({'success': true, 'statusCode': 200, 'message': 'OK'}));

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kResponseBytes.length;
  @override
  bool get isRedirect => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get persistentConnection => true;
  @override
  List<Cookie> get cookies => const [];
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kResponseBytes]).listen(
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
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Service Hub - Dynamic Filtering, Clean Initial State & Unique Assets Test Suite', () {
    testWidgets('TEST 1 & TEST 7: Open Service Hub without input -> NO results displayed, shows clean initial prompt state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Service Hub title
      expect(find.text('PropZen Service Hub'), findsOneWidget);

      // Verify NO default/fake cards are rendered
      expect(find.text('CAD READY'), findsNothing);
      expect(find.text('VEDIC AUDIT'), findsNothing);
      expect(find.text('LEGAL AUDIT'), findsNothing);
      expect(find.text('AI DESIGN'), findsNothing);
      expect(find.text('LOWEST EMI'), findsNothing);

      // Verify clean initial prompt state
      expect(find.text('No results yet'), findsOneWidget);
      expect(find.textContaining('Please enter your requirements or select a service category'), findsOneWidget);
    });

    testWidgets('TEST 2: Select Home Design -> Only Home Design results and assets rendered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Home Design category chip
      final homeDesignChip = find.widgetWithText(ChoiceChip, 'Home Design');
      expect(homeDesignChip, findsOneWidget);
      await tester.tap(homeDesignChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify only Home Design tool is visible
      expect(find.text('CAD READY'), findsOneWidget);
      expect(find.text('Generate 2D Floor Plan'), findsOneWidget);

      // Verify unrelated services are NOT displayed
      expect(find.text('VEDIC AUDIT'), findsNothing);
      expect(find.text('LEGAL AUDIT'), findsNothing);
      expect(find.text('LOWEST EMI'), findsNothing);
      expect(find.text('AI DESIGN'), findsNothing);
    });

    testWidgets('TEST 3: Select Interior Design -> Only Interior Design results rendered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Interior Design category chip
      final interiorChip = find.widgetWithText(ChoiceChip, 'Interior Design');
      expect(interiorChip, findsOneWidget);
      await tester.tap(interiorChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify only Interior Design tools are visible
      expect(find.text('AI DESIGN'), findsOneWidget);
      expect(find.text('INTERIORS'), findsOneWidget);
      expect(find.text('Generate Room Design'), findsOneWidget);
      expect(find.text('Calculate Interior Specs'), findsOneWidget);

      // Verify unrelated services are NOT displayed
      expect(find.text('CAD READY'), findsNothing);
      expect(find.text('VEDIC AUDIT'), findsNothing);
      expect(find.text('LOWEST EMI'), findsNothing);
      expect(find.text('LEGAL AUDIT'), findsNothing);
    });

    testWidgets('TEST 4: Select Vastu Consultancy -> Only Vastu results rendered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Vastu Consultancy category chip
      final vastuChip = find.widgetWithText(ChoiceChip, 'Vastu Consultancy');
      expect(vastuChip, findsOneWidget);
      await tester.tap(vastuChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify only Vastu results are visible
      expect(find.text('VEDIC AUDIT'), findsOneWidget);
      expect(find.text('Analyze Vastu Score'), findsOneWidget);

      // Verify unrelated services are NOT displayed
      expect(find.text('CAD READY'), findsNothing);
      expect(find.text('AI DESIGN'), findsNothing);
      expect(find.text('LOWEST EMI'), findsNothing);
      expect(find.text('LEGAL AUDIT'), findsNothing);
    });

    testWidgets('TEST 5: Switch from Interior Design -> Vastu Consultancy -> Old results vanish immediately', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. First select Interior Design
      final interiorChip = find.widgetWithText(ChoiceChip, 'Interior Design');
      await tester.tap(interiorChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('AI DESIGN'), findsOneWidget);
      expect(find.text('VEDIC AUDIT'), findsNothing);

      // 2. Switch to Vastu Consultancy
      final vastuChip = find.widgetWithText(ChoiceChip, 'Vastu Consultancy');
      await tester.tap(vastuChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // 3. Verify old Interior Design results are completely gone and Vastu is shown
      expect(find.text('AI DESIGN'), findsNothing);
      expect(find.text('INTERIORS'), findsNothing);
      expect(find.text('VEDIC AUDIT'), findsOneWidget);
      expect(find.text('Analyze Vastu Score'), findsOneWidget);
    });

    testWidgets('TEST 6: Search for non-matching service -> "No matching services found" empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a non-matching query in the search bar
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'xyzunknownservice123');
      await tester.pumpAndSettle();

      // Verify No Matching State
      expect(find.text('No matching services found for your selection.'), findsOneWidget);
      expect(find.text('Try Another Service'), findsOneWidget);

      // Click "Try Another Service" button to reset
      await tester.tap(find.text('Try Another Service'));
      await tester.pumpAndSettle();

      // Verify reset back to initial prompt state
      expect(find.text('No results yet'), findsOneWidget);
    });

    testWidgets('TEST 8: Every Service has a unique domain-specific image (zero duplicate asset urls)', (tester) async {
      final allTools = AiServiceRegistry.allTools;
      final seenImages = <String, String>{};

      for (final tool in allTools) {
        expect(tool.uniqueImageUrl.isNotEmpty, isTrue, reason: 'Tool ${tool.id} must have an authentic image');
        expect(
          seenImages.containsKey(tool.uniqueImageUrl),
          isFalse,
          reason: 'Tool ${tool.id} reuses image already used by ${seenImages[tool.uniqueImageUrl]}',
        );
        seenImages[tool.uniqueImageUrl] = tool.id;
      }

      // Verify all 13 tools have 13 distinct unique image URLs
      expect(seenImages.length, equals(allTools.length));
    });
  });
}

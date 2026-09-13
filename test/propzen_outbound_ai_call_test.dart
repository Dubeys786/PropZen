import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/services/propzen_voice_service.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_voice_agent_modal.dart';

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
    PropzenVoiceService.instance.isTestMode = true;
  });

  group('PropZen AI Voice Agent - Call Removal Verification Test Suite', () {
    setUp(() {
      PropzenAiAgentService.instance.clearSession();
      PropzenVoiceService.instance.stopAll();
    });

    tearDown(() {
      PropzenVoiceService.instance.stopAll();
    });

    testWidgets('1. PropzenVoiceAgentModal Header Does NOT Contain Any Call/Phone Button or Tooltip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVoiceAgentModal(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Assert NO call text, buttons, or tooltips exist
      expect(find.byTooltip('Test PropZen AI Call'), findsNothing);
      expect(find.text('Test PropZen AI Call'), findsNothing);
      expect(find.text('Call Me'), findsNothing);
      expect(find.text('Call Now'), findsNothing);
      expect(find.text('Make a Call'), findsNothing);
      expect(find.text('Start Call'), findsNothing);
      expect(find.text('Phone Call'), findsNothing);

      // Assert NO phone call icons exist
      expect(find.byIcon(LucideIcons.phoneCall), findsNothing);
      expect(find.byIcon(LucideIcons.phone), findsNothing);
      expect(find.byIcon(LucideIcons.phoneForwarded), findsNothing);
      expect(find.byIcon(LucideIcons.phoneOff), findsNothing);

      // Assert remaining header action buttons are correctly present
      expect(find.byTooltip('Reset Conversation'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('2. PropzenVoiceAgentModal Does NOT Contain Test Call Chip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVoiceAgentModal(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Call chip must NOT exist anywhere
      expect(find.text('Test PropZen AI Call'), findsNothing);
      expect(find.byIcon(LucideIcons.phoneCall), findsNothing);
      expect(find.textContaining('Welcome to PropZen'), findsOneWidget);
    });

    testWidgets('3. PropzenVoiceAgentModal Voice Controls and Text Fallback Function Cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVoiceAgentModal(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Core Voice UI Elements
      expect(find.text('PropZen AI'), findsOneWidget);
      expect(find.textContaining('Voice Consultant'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data?.contains('Tap to Stop') == true || w.data?.contains('PropZen AI') == true)), findsWidgets);
      expect(find.byWidgetPredicate((w) => w is Icon && (w.icon == LucideIcons.mic || w.icon == LucideIcons.micOff)), findsWidgets);
      expect(find.byWidgetPredicate((w) => w is Icon && (w.icon == LucideIcons.languages || w.icon == LucideIcons.square)), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(LucideIcons.send), findsOneWidget);
    });
  });
}

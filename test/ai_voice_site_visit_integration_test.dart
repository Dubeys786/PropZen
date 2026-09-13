import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => -1;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  List<Cookie> get cookies => [];
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  bool get persistentConnection => false;
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final responseBytes = utf8.encode(jsonEncode({'success': true, 'statusCode': 200, 'message': 'OK', 'bookingId': 'VISIT-LIVE-101'}));
    return Stream.value(responseBytes).listen(
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
  HttpOverrides.global = _MockHttpOverrides();

  group('AI Voice Agent -> Site Visit Booking Flow Suite', () {
    final aiService = PropzenAiAgentService.instance;

    setUp(() {
      aiService.clearSession();
    });

    test('1. Natural Language Date Parsing (Kal, Parso, Saturday, Specific Date)', () async {
      aiService.context.updateFromUserInput('Mujhe kal Ace Starlit visit karna hai');
      expect(aiService.context.visitDate, isNotNull);
      expect(aiService.context.visitDateIso, isNotNull);
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(aiService.context.visitDateIso!), isTrue);

      aiService.context.updateFromUserInput('Saturday ko chalega');
      expect(aiService.context.visitDate!.contains('Saturday'), isTrue);
      expect(aiService.context.visitDateIso, isNotNull);

      aiService.context.updateFromUserInput('28 August ko 3 baje');
      expect(aiService.context.visitDate!.contains('28') || aiService.context.visitDate!.contains('August'), isTrue);
      expect(aiService.context.visitTime, equals('03:00 PM'));
    });

    test('2. Step-by-Step Interactive Gathering: Prompts only for missing items', () async {
      // Step 1: User says "Site visit book karni hai" for Sector 150 property
      await aiService.processDialogue('Sector 150 mein Ace Starlit dikhao.');
      final res1 = await aiService.processDialogue('Mujhe is project ki site visit karni hai.');
      expect(aiService.context.activeFlow, equals(AgentFlow.siteVisit));
      // Must prompt for date first
      expect(res1.speechResponse.toLowerCase().contains('date') || res1.speechResponse.toLowerCase().contains('tariq'), isTrue);

      // Step 2: User provides date
      final res2 = await aiService.processDialogue('Kal aana chahta hoon.');
      expect(aiService.context.visitDate, isNotNull);
      // Must prompt for time slot
      expect(res2.speechResponse.contains('10:00 AM') || res2.speechResponse.contains('12:00 PM') || res2.speechResponse.contains('03:00 PM'), isTrue);

      // Step 3: User provides time slot
      final res3 = await aiService.processDialogue('12:00 PM time theek hai.');
      expect(aiService.context.visitTime, equals('12:00 PM'));
      // Must prompt for name and 10-digit mobile number
      expect(res3.speechResponse.toLowerCase().contains('mobile') || res3.speechResponse.toLowerCase().contains('naam') || res3.speechResponse.toLowerCase().contains('name'), isTrue);

      // Step 4: User provides name and phone
      final res4 = await aiService.processDialogue('Mera naam Rohit Sharma mobile number 9876543210 hai.');
      expect(aiService.context.clientName, equals('Rohit Sharma'));
      expect(aiService.context.clientPhone, equals('9876543210'));
      // Must prompt for email address
      expect(res4.speechResponse.toLowerCase().contains('email'), isTrue);

      // Step 5: User provides email and cab details
      final res5 = await aiService.processDialogue('Email rohit@propzen.ai hai, 2 visitors honge aur cab chahiye.');
      expect(aiService.context.clientEmail, equals('rohit@propzen.ai'));
      expect(aiService.context.visitorCount, equals(2));
      expect(aiService.context.cabRequired, isTrue);
      // Must show pre-confirmation summary and ask for confirmation
      expect(res5.speechResponse.contains('confirm') || res5.speechResponse.contains('Ace Starlit') || res5.speechResponse.contains('12:00 PM'), isTrue);
    });

    test('3. Pre-Confirmation Check: Does NOT submit booking before user confirms', () async {
      aiService.clearSession();
      await aiService.processDialogue('Ace Starlit ki site visit kal 12 PM mera naam Rohit mobile 9876543210 email rohit@propzen.ai 2 visitors cab chahiye.');
      // Stage must be confirming, not yet booked
      expect(aiService.context.siteVisitStage, equals(SiteVisitStage.confirming));
      expect(aiService.context.bookingId, isNull);

      // Confirm
      final confirmRes = await aiService.processDialogue('Haan, confirm kar do.');
      expect(aiService.context.siteVisitStage, equals(SiteVisitStage.booked));
      expect(aiService.context.bookingId, isNotNull);
      expect(confirmRes.speechResponse.contains('VISIT-'), isTrue);
      expect(confirmRes.speechResponse.contains('successfully book ho gayi hai') || confirmRes.speechResponse.contains('Perfect'), isTrue);
    });

    test('4. Real Property ID & Dual Schema Persistence Check', () async {
      aiService.clearSession();
      final targetProp = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      aiService.context.selectedProperty = targetProp;

      final bookingRes = await aiService.processDialogue('Site visit confirm karo kal 12:00 PM Rohit 9876543210 rohit@propzen.ai 2 log cab yes.');
      expect(bookingRes.speechResponse.contains('confirm'), isTrue);

      final finalRes = await aiService.processDialogue('Haan confirm.');
      expect(finalRes.speechResponse.contains('VISIT-'), isTrue);
      expect(aiService.context.selectedProperty!.id, equals('prop_ats_happytrails'));

      // Check scheduled visits in PropertyStateService
      final scheduled = PropertyStateService.instance.scheduledVisits;
      expect(scheduled.isNotEmpty, isTrue);
      expect(scheduled.first['property_id'], equals('prop_ats_happytrails'));
      expect(scheduled.first['user_phone'], equals('9876543210'));
    });

    test('5. Duplicate Booking Prevention on repeat affirmation', () async {
      aiService.clearSession();
      await aiService.processDialogue('Ace Starlit kal 12 PM Rohit 9876543210 rohit@propzen.ai 2 visitors cab yes site visit');
      await aiService.processDialogue('Haan confirm.');
      final firstBookingId = aiService.context.bookingId;
      expect(firstBookingId, isNotNull);

      // Repeat affirmation
      final repeatRes = await aiService.processDialogue('Haan confirm karo');
      expect(repeatRes.speechResponse.contains('pehle se hi successfully booked hai') || repeatRes.speechResponse.contains('already successfully confirmed'), isTrue);
      expect(repeatRes.speechResponse.contains(firstBookingId!), isTrue);
    });
  });
}

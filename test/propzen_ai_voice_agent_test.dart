import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/services/propzen_voice_service.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_voice_agent_modal.dart';
import 'package:dealghar_ncr_10x/widgets/property_card.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

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
    PropzenVoiceService.instance.isTestMode = true;
  });

  group('PropZen AI Voice Agent - Professional Consultant & Sales Executive Suite', () {
    final aiService = PropzenAiAgentService.instance;
    final voiceService = PropzenVoiceService.instance;

    setUp(() {
      aiService.clearSession();
      voiceService.stopAll();
    });

    tearDown(() {
      voiceService.stopAll();
    });

    test('1. Proactive Opening Greeting: Speaks naturally without waiting silently', () {
      final greetingHinglish = aiService.getProactiveOpeningGreeting(language: 'hinglish');
      expect(greetingHinglish, contains('Welcome to PropZen'));
      expect(greetingHinglish, contains('property search'));
      expect(greetingHinglish.split(' ').length, greaterThanOrEqualTo(20)); // Substantial greeting

      final greetingHindi = aiService.getProactiveOpeningGreeting(language: 'hindi');
      expect(greetingHindi, contains('PropZen में आपका स्वागत है'));

      final greetingEnglish = aiService.getProactiveOpeningGreeting(language: 'english');
      expect(greetingEnglish, contains('Welcome to PropZen'));

      final proactiveMsg = aiService.startProactiveTurn(language: 'hinglish');
      expect(proactiveMsg.role, equals('assistant'));
      expect(proactiveMsg.suggestedChips!.isNotEmpty, isTrue);
    });

    test('2. Language Detection: Supports Hindi, Hinglish, and English', () {
      expect(aiService.detectLanguage('मुझे नोएडा एक्सटेंशन में 3 BHK फ्लैट चाहिए'), equals('hindi'));
      expect(aiService.detectLanguage('Main apne use ke liye 2 BHK flat search kar raha hoon.'), equals('hinglish'));
      expect(aiService.detectLanguage('I am looking for a luxury 4 BHK villa with golf course view.'), equals('english'));
    });

    test('3. Consultative Response Depth: Substantial, consultative word length with market context', () async {
      final res = await aiService.processDialogue('Apne rehne ke liye.');
      expect(aiService.context.purpose, equals('self-use'));
      expect(aiService.context.qualificationTier, equals('Self Use'));
      // Acknowledges purpose and explains before asking location
      expect(res.speechResponse.toLowerCase().contains('connectivity') || res.speechResponse.toLowerCase().contains('family') || res.speechResponse.toLowerCase().contains('living'), isTrue);
      expect(res.speechResponse.split(' ').length, greaterThanOrEqualTo(15));
    });

    test('4. Multi-Turn Step-by-Step Questioning without Repeating Information', () async {
      // Step 1: Purpose
      final t1 = await aiService.processDialogue('Apne use ke liye.');
      expect(aiService.context.purpose, equals('self-use'));
      expect(t1.speechResponse.toLowerCase().contains('location') || t1.speechResponse.toLowerCase().contains('area'), isTrue);

      // Step 2: Location
      final t2 = await aiService.processDialogue('Noida Extension.');
      expect(aiService.context.location, equals('Noida Extension'));
      expect(t2.speechResponse.toLowerCase().contains('bhk') || t2.speechResponse.toLowerCase().contains('configuration'), isTrue);
      expect(t2.speechResponse.contains('Noida Extension mein chahiye?'), isFalse); // Never re-asks known location

      // Step 3: BHK
      final t3 = await aiService.processDialogue('2 BHK.');
      expect(aiService.context.bedrooms, equals(2));
      expect(t3.speechResponse.toLowerCase().contains('budget'), isTrue);

      // Step 4: Budget -> Triggers full search & rich explanation
      final t4 = await aiService.processDialogue('80 lakh.');
      expect(aiService.context.maxBudget, equals(8000000.0));
      expect(t4.matchedProperties.isNotEmpty, isTrue);
      // Detailed explanation with amenities and recommendation rationale
      expect(t4.speechResponse.contains('Pehla option') || t4.speechResponse.contains('Prime Option') || t4.speechResponse.contains('verified options'), isTrue);
      expect(t4.speechResponse.contains('In dono options mein se') || t4.speechResponse.contains('kaisa lag raha hai'), isTrue);
      expect(t4.speechResponse.split(' ').length, greaterThanOrEqualTo(40)); // Rich description
    });

    test('5. Property Explanation Details & Interactive Customer Feedback', () async {
      aiService.clearSession();
      final res = await aiService.processDialogue('Sector 150 mein 3 BHK apartment chahiye budget 1.5 Cr.');
      expect(res.matchedProperties.isNotEmpty, isTrue);
      expect(res.speechResponse, contains('Sector 150'));
      expect(res.speechResponse.toLowerCase().contains('clubhouse') || res.speechResponse.toLowerCase().contains('amenities') || res.speechResponse.toLowerCase().contains('security'), isTrue);
      expect(res.speechResponse.toLowerCase().contains('recommend') || res.speechResponse.toLowerCase().contains('match'), isTrue);
      // Interactive feedback prompt
      expect(res.speechResponse.contains('In dono options mein se') || res.speechResponse.contains('kaisa lag raha hai') || res.speechResponse.contains('kaunsa option'), isTrue);
    });

    test('6. Property Q&A: Floor plan, Metro, RERA, Amenities from live dataset', () async {
      aiService.clearSession();
      await aiService.processDialogue('Sector 150 mein 3 BHK apartment chahiye budget 1.5 Cr.');
      
      // Floor Plan
      final fpRes = await aiService.processDialogue('Is property ka floor plan aur size batao.');
      expect(fpRes.speechResponse.contains('sq.ft') || fpRes.speechResponse.contains('carpet'), isTrue);
      expect(fpRes.speechResponse.contains('वेंटिलेशन') || fpRes.speechResponse.contains('ventilation') || fpRes.speechResponse.contains('layout'), isTrue);

      // Metro
      final metroRes = await aiService.processDialogue('Nearest metro kitni door hai?');
      expect(metroRes.speechResponse.toLowerCase().contains('metro') || metroRes.speechResponse.contains('km'), isTrue);

      // RERA
      final reraRes = await aiService.processDialogue('Kya ye RERA approved hai?');
      expect(reraRes.speechResponse.toLowerCase().contains('rera') || reraRes.speechResponse.contains('verified'), isTrue);
    });

    test('7. End-to-End Property Enquiry Lifecycle with Confirmation Summary', () async {
      aiService.clearSession();
      await aiService.processDialogue('Sector 150 mein 3 BHK apartment chahiye budget 1.5 Cr.');

      // Initiate Enquiry with contact info
      final enqStep1 = await aiService.processDialogue('Mujhe is property ke liye enquiry submit karni hai mera naam Amit Sharma mobile 9810394068 hai.');
      expect(aiService.context.activeFlow, equals(AgentFlow.enquiry));
      // Pre-submission summary & confirmation prompt
      expect(enqStep1.speechResponse.contains('confirm') || enqStep1.speechResponse.contains('submit kar doon') || enqStep1.speechResponse.contains('details'), isTrue);

      // Confirm Submission
      final enqStep2 = await aiService.processDialogue('Haan, submit kar do.');
      expect(enqStep2.speechResponse.contains('successfully register') || enqStep2.speechResponse.contains('Thank you'), isTrue);
    });

    test('8. End-to-End Site Visit Booking Lifecycle with Slot Checking & Confirmation', () async {
      aiService.clearSession();
      await aiService.processDialogue('Sector 150 mein 3 BHK apartment chahiye budget 1.5 Cr.');

      // Step 1: Initiate Site Visit
      final sv1 = await aiService.processDialogue('Mujhe site visit book karni hai.');
      expect(aiService.context.activeFlow, equals(AgentFlow.siteVisit));
      expect(sv1.speechResponse.toLowerCase().contains('date') || sv1.speechResponse.toLowerCase().contains('tariq'), isTrue);

      // Step 2: Provide Date
      final sv2 = await aiService.processDialogue('Kal.');
      expect(aiService.context.visitDate, isNotNull);
      expect(sv2.speechResponse.toLowerCase().contains('slot') || sv2.speechResponse.toLowerCase().contains('time') || sv2.speechResponse.contains('12:00 PM'), isTrue);

      // Step 3: Provide Time Slot, Contact info, Visitors, and Cab
      final sv3 = await aiService.processDialogue('12 PM, mera naam Amit Verma mobile 9810394068 email amit@propzen.ai, 2 visitors, cab assistance chahiye.');
      expect(aiService.context.visitTime, equals('12:00 PM'));
      expect(aiService.context.clientPhone, equals('9810394068'));
      expect(aiService.context.clientEmail, equals('amit@propzen.ai'));
      expect(aiService.context.visitorCount, equals(2));
      expect(aiService.context.cabRequired, isTrue);
      // Pre-booking summary & confirmation prompt
      expect(sv3.speechResponse.contains('booking confirm') || sv3.speechResponse.contains('confirm kar doon') || sv3.speechResponse.contains('12:00 PM'), isTrue);

      // Step 4: Confirm Booking
      final sv4 = await aiService.processDialogue('Haan, confirm kar do.');
      expect(sv4.speechResponse.contains('successfully book ho gayi hai') || sv4.speechResponse.contains('Perfect'), isTrue);
      expect(sv4.speechResponse.contains('VISIT-'), isTrue);
      expect(aiService.context.bookingId, isNotNull);
      expect(aiService.context.qualificationTier, equals('Site Visit Ready'));

      // Step 5: Duplicate Prevention on repeat affirmation
      final sv5 = await aiService.processDialogue('Haan confirm.');
      expect(sv5.speechResponse.contains('pehle se hi successfully booked hai') || sv5.speechResponse.contains('already successfully confirmed'), isTrue);
    });

    testWidgets('9. PropzenVoiceAgentModal: Proactively greets on open and displays action chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVoiceAgentModal(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PropZen AI'), findsOneWidget);
      expect(find.text('Voice Consultant • Hindi • Hinglish • English'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data?.contains('Tap to Stop') == true || w.data?.contains('PropZen AI') == true)), findsWidgets);
      // Proactive initial turn is already present in conversation
      expect(find.textContaining('Welcome to PropZen'), findsOneWidget);
      // Suggestion action chips are visible
      expect(find.byType(ActionChip), findsNothing); // Uses custom InkWell chip containers
      expect(find.byWidgetPredicate((w) => w is Text && (w.data?.contains('Residential') == true || w.data?.contains('Apne Rehne') == true || w.data?.contains('Investment') == true)), findsWidgets);
    });

    testWidgets('10. PropzenVoiceAgentModal: Zero Phone Call Buttons, Icons, or Tooltips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVoiceAgentModal(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.phoneCall), findsNothing);
      expect(find.byIcon(LucideIcons.phone), findsNothing);
      expect(find.byTooltip('Test PropZen AI Call'), findsNothing);
      expect(find.text('Call Me'), findsNothing);
      expect(find.text('Call Now'), findsNothing);
    });
  });
}

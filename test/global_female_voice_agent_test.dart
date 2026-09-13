import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/config/voice_config.dart';
import 'package:dealghar_ncr_10x/services/propzen_voice_service.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_voice_agent_modal.dart';

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

  setUp(() {
    PropzenVoiceService.instance.stopAll();
    PropzenVoiceService.instance.isTestMode = true;
  });

  group('PropZen AI Voice Agent - Global Female Indian Voice Configuration Tests', () {
    // TEST 1: Centralized Voice Configuration
    test('1. PropzenVoiceConfig strictly defines unified Indian Female Voice parameters', () {
      expect(PropzenVoiceConfig.voiceGender, equals('Female'));
      expect(PropzenVoiceConfig.defaultLanguageCode, equals('hi-IN'));
      expect(PropzenVoiceConfig.speechRate, equals(1.0));
      expect(PropzenVoiceConfig.speechPitch, equals(1.15));

      // Preferred Indian Female voices list
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('swara'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('neerja'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('kalpana'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('heera'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('ananya'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('google हिन्दी'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('lekha'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('aditi'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('kavya'));
      expect(PropzenVoiceConfig.preferredFemaleVoiceKeywords, contains('veena'));

      // Male blacklist prevents any male voice fallback
      expect(PropzenVoiceConfig.blacklistedMaleKeywords, contains('david'));
      expect(PropzenVoiceConfig.blacklistedMaleKeywords, contains('mark'));
      expect(PropzenVoiceConfig.blacklistedMaleKeywords, contains('ravi'));
      expect(PropzenVoiceConfig.blacklistedMaleKeywords, contains('hemant'));
      expect(PropzenVoiceConfig.blacklistedMaleKeywords, contains('madhur'));
      expect(PropzenVoiceConfig.blacklistedMaleKeywords, contains('rishi'));
    });

    // TEST 2: Centralized PropzenVoiceService TTS Flow
    test('2. PropzenVoiceService.speak invokes TTS and updates speaking state', () async {
      final service = PropzenVoiceService.instance;
      service.isTestMode = true;

      bool completed = false;
      await service.speak(
        'Namaste! Main PropZen AI assistant hoon. Main aapki kya madad kar sakti hoon?',
        onCompleted: () {
          completed = true;
        },
      );

      expect(service.lastSpokenAiResponseNotifier.value, contains('PropZen AI'));
      expect(completed, isTrue);
    });

    // TEST 3: Interruption / Barge-in Behavior
    test('3. PropzenVoiceService.stopSpeaking immediately stops speech and resets to idle', () {
      final service = PropzenVoiceService.instance;
      service.stateNotifier.value = VoiceAgentState.speaking;

      service.stopSpeaking();
      expect(service.stateNotifier.value, equals(VoiceAgentState.idle));
    });

    // TEST 4: Multi-Turn Conversation Consistency (Greeting, Search, Details, AI Match, Site Visit, Dealer, Error)
    test('4. PropzenAiAgentService generates natural conversational Hindi/Hinglish speech responses across all modules', () async {
      final agent = PropzenAiAgentService.instance;
      agent.clearSession();

      // Turn 1: Greeting
      final greetingRes = await agent.processDialogue('Hello');
      expect(greetingRes.speechResponse, isNotEmpty);
      expect(greetingRes.flowType, equals('general'));

      // Turn 2: Property Search in Sector 150
      final searchRes = await agent.processDialogue('Mujhe Sector 150 mein 3 BHK dikhao');
      expect(searchRes.speechResponse, isNotEmpty);
      expect(searchRes.matchedProperties.length, greaterThan(0));

      // Turn 3: Property Details
      final detailsRes = await agent.processDialogue('Is property ka price aur possession kab hai?');
      expect(detailsRes.speechResponse, isNotEmpty);

      // Turn 4: AI Property Match
      final matchRes = await agent.processDialogue('Find my perfect property under 80 lakh');
      expect(matchRes.speechResponse, isNotEmpty);

      // Turn 5: Site Visit Booking
      final visitRes = await agent.processDialogue('Mujhe is property ki site visit book karni hai');
      expect(visitRes.speechResponse, isNotEmpty);

      // Turn 6: Dealer flow
      final dealerRes = await agent.processDialogue('Property listing create karo aur description bana do');
      expect(dealerRes.speechResponse, isNotEmpty);

      // Turn 7: Fallback / Clarification
      final fallbackRes = await agent.processDialogue('asdfxyz unexpected input');
      expect(fallbackRes.speechResponse, isNotEmpty);
    });

    // TEST 5: Modal UI Visualizer & Speaking State
    testWidgets('5. PropzenVoiceAgentModal correctly displays Speaking state and visualizer', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenVoiceAgentModal(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PropZen AI'), findsOneWidget);
      expect(find.text('Talk to PropZen AI'), findsOneWidget);

      // Simulate AI speaking state
      PropzenVoiceService.instance.stateNotifier.value = VoiceAgentState.speaking;
      await tester.pump();

      expect(find.text('🔊 SPEAKING'), findsOneWidget);
      expect(find.text('Speaking... Tap to Interrupt'), findsOneWidget);

      // Tap interrupt
      await tester.tap(find.text('Speaking... Tap to Interrupt'));
      await tester.pump();

      // Verifies barge-in stops speech immediately
      expect(PropzenVoiceService.instance.stateNotifier.value, isNot(equals(VoiceAgentState.speaking)));
    });
  });
}

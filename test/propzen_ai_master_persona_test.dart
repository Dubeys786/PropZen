import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';

void main() {
  group('PropZen AI Master Persona & 4-Step Flow Test Suite', () {
    final aiService = PropzenAiAgentService.instance;

    setUp(() {
      aiService.clearSession();
    });

    test('1. Step 1: Professional Greeting & Consultant Inquiry', () async {
      final res = await aiService.processDialogue('Hello');
      expect(res.speechResponse, contains('PropZen'));
      expect(res.speechResponse.toLowerCase(), contains('property'));
    });

    test('2. Step 2 & Entity Acknowledgment: Location -> BHK -> Budget -> Recommendations', () async {
      // Step 2a: User gives location
      final stepA = await aiService.processDialogue('Mujhe Noida mein property chahiye.');
      expect(stepA.speechResponse, contains('Noida'));
      expect(stepA.speechResponse.toLowerCase().contains('configuration') || stepA.speechResponse.toLowerCase().contains('bhk'), isTrue);

      // Step 2b: User gives BHK
      final stepB = await aiService.processDialogue('3 BHK apartment.');
      expect(stepB.speechResponse.toLowerCase(), contains('budget'));

      // Step 2c: User gives budget -> Triggers recommendations
      final stepC = await aiService.processDialogue('1.5 Crore.');
      expect(stepC.matchedProperties.isNotEmpty, isTrue);
      expect(stepC.speechResponse.contains('option') || stepC.speechResponse.contains('Option'), isTrue);
    });

    test('3. Step 4 in Hindi Format with Recommendation Rationale', () async {
      aiService.context.location = 'नोएडा';
      aiService.context.maxBudget = 8000000.0;

      final res = await aiService.processDialogue('2 बीएचके चाहिए');

      expect(res.speechResponse, contains('ऑप्शन'));
      expect(res.speechResponse, contains('रेकमेंड'));
      expect(res.speechResponse.toLowerCase().contains('bhk') || res.speechResponse.contains('यूनिट'), isTrue);
    });

    test('4. Smart Affirmations Handling (ha, haan, bilkul, yes, Option 1)', () async {
      aiService.context.location = 'Noida';
      aiService.context.maxBudget = 8000000.0;
      aiService.context.bedrooms = 2;
      aiService.context.lastFoundProperties = aiService.searchRealProperties(aiService.context);
      if (aiService.context.lastFoundProperties.isNotEmpty) {
        aiService.context.selectedProperty = aiService.context.lastFoundProperties.first;
      }

      // User says "Option 1"
      final res = await aiService.processDialogue('Option 1 achha hai');
      expect(res.speechResponse.toLowerCase().contains('choice') || res.speechResponse.contains('पसंद') || res.speechResponse.contains('amenities') || res.speechResponse.contains('RERA'), isTrue);
    });

    test('5. Budget Parsing with 50k / Thousand format', () async {
      aiService.context.location = 'Gurgaon';
      final res = await aiService.processDialogue('50k per month');
      expect(aiService.context.maxBudget, equals(50000.0));
      expect(res.speechResponse.toLowerCase().contains('50k') || res.speechResponse.contains('50000') || res.speechResponse.contains('bhk') || res.speechResponse.contains('configuration'), isTrue);
    });

    test('6. Anti-Loop: Never repeats verbatim question', () async {
      aiService.context.location = 'Noida';
      final q1 = await aiService.processDialogue('Hi');
      final q2 = await aiService.processDialogue('kuch bhi');
      expect(q1.speechResponse, isNot(equals(q2.speechResponse)));
    });
  });
}

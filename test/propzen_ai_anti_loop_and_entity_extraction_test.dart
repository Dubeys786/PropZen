import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';

void main() {
  group('PropZen AI Voice Agent Anti-Loop & Entity Extraction Test Suite', () {
    final aiService = PropzenAiAgentService.instance;

    setUp(() {
      aiService.clearSession();
    });

    test('1. Extracts Budget from Comma-Formatted String (मेरा बजट 80,00,000 है।)', () async {
      aiService.context.location = 'Noida';

      final res = await aiService.processDialogue('मेरा बजट 80,00,000 है।');

      expect(aiService.context.maxBudget, equals(8000000.0));
      expect(res.speechResponse, contains('80 लाख'));
      expect(res.speechResponse, contains('BHK'));
      // Must NOT ask for budget again!
      expect(res.speechResponse, isNot(contains('आपका बजट कितना है')));
    });

    test('2. Extracts Budget from Typo & Comma String (मेरा पढ़ 1,00,00,000 है।)', () async {
      aiService.context.location = 'Noida';

      final res = await aiService.processDialogue('मेरा पढ़ 1,00,00,000 है।');

      expect(aiService.context.maxBudget, equals(10000000.0));
      expect(res.speechResponse, contains('1 करोड़'));
      expect(res.speechResponse, isNot(contains('आपका बजट कितना है')));
    });

    test('3. Extracts Budget from Isolated Number with Hindi Danda (1,00,00,000।)', () async {
      aiService.context.location = 'Noida';

      final res = await aiService.processDialogue('1,00,00,000।');

      expect(aiService.context.maxBudget, equals(10000000.0));
      expect(res.speechResponse, contains('1 करोड़'));
    });

    test('4. Extracts Budget from Devanagari Digits (८०,००,०००)', () async {
      aiService.context.location = 'Noida';

      final res = await aiService.processDialogue('८०,००,०००');

      expect(aiService.context.maxBudget, equals(8000000.0));
      expect(res.speechResponse, contains('80 लाख'));
    });

    test('5. Multi-Turn Anti-Loop Flow: Location -> Budget with Commas -> 2 BHK -> Real Results', () async {
      // Step 1: User gives location
      final step1 = await aiService.processDialogue('Mujhe Noida mein property chahiye.');
      expect(step1.speechResponse.toLowerCase().contains('configuration') || step1.speechResponse.toLowerCase().contains('bhk') || step1.speechResponse.toLowerCase().contains('budget'), isTrue);
      expect(step1.speechResponse, contains('Noida'));

      // Step 2: User gives budget with commas
      final step2 = await aiService.processDialogue('मेरा बजट 80,00,000 है।');
      expect(step2.speechResponse, contains('80 लाख'));
      expect(step2.speechResponse, contains('BHK'));

      // Verify Step 2 is completely different from Step 1 (NO LOOP)
      expect(step2.speechResponse, isNot(equals(step1.speechResponse)));

      // Step 3: User gives 2 BHK (within 80 lakh budget in Noida)
      final step3 = await aiService.processDialogue('2 BHK.');
      expect(step3.matchedProperties, isNotEmpty);
      expect(step3.speechResponse.contains('2 बेहतरीन ऑप्शंस') || step3.speechResponse.contains('पहला ऑप्शन') || step3.speechResponse.contains('शॉर्टलिस्ट'), isTrue);
    });

    test('6. Anti-Loop Rephrasing Protection', () async {
      aiService.context.location = 'Noida';

      // First question about configuration/budget
      final q1 = await aiService.processDialogue('mujhe property leni hai');
      expect(q1.speechResponse.toLowerCase().contains('configuration') || q1.speechResponse.toLowerCase().contains('budget') || q1.speechResponse.toLowerCase().contains('bhk'), isTrue);

      // If user gives unparseable response, AI must NOT repeat verbatim question
      final q2 = await aiService.processDialogue('kuch bhi');
      expect(q2.speechResponse, isNot(equals(q1.speechResponse)));
    });
  });
}

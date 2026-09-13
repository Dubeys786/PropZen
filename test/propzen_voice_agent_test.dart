import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen AI Female Voice Agent Comprehensive Tests', () {
    late PropzenAiAgentService service;

    setUp(() {
      service = PropzenAiAgentService.instance;
      service.clearSession();
    });

    test('1. Automatic Language Detection & Switching', () async {
      // Test Hindi
      final resHindi = await service.processDialogue('मुझे नोएडा में 3 BHK फ्लैट चाहिए');
      expect(resHindi.language, 'hindi');

      // Test English
      final resEnglish = await service.processDialogue('I want a luxury apartment near Sector 150');
      expect(resEnglish.language, 'english');

      // Explicit Language Switch command
      final switchHindi = await service.processDialogue('Hindi mein batao');
      expect(switchHindi.language, 'hindi');
      expect(switchHindi.speechResponse, contains('हिंदी'));

      final switchEnglish = await service.processDialogue('Speak in English');
      expect(switchEnglish.language, 'english');
      expect(switchEnglish.speechResponse, contains('switched to English'));

      final switchHinglish = await service.processDialogue('Hinglish mein samjhao');
      expect(switchHinglish.language, 'hinglish');
      expect(switchHinglish.speechResponse, contains('Hinglish'));
    });

    test('2. Property Search & Zero Hallucination Matching', () async {
      final res = await service.processDialogue('Sector 150 mein 3 BHK under 2 crore dikhao');
      expect(res.matchedProperties, isNotEmpty);
      expect(res.matchedProperties.first.sector, contains('150'));
      expect(res.speechResponse, contains(res.matchedProperties.first.title));
    });

    test('3. Safe Deal Room & Latest Offer Query', () async {
      final res = await service.processDialogue('Deal room kholo aur latest offer batao');
      expect(res.flowType, 'dealRoom');
      expect(res.speechResponse.toLowerCase(), contains('deal room'));
      expect(res.speechResponse, contains('Cr'));
    });

    test('4. AI Property Negotiation Insights', () async {
      final res = await service.processDialogue('Is property mein kitna negotiate ho sakta hai?');
      expect(res.flowType, 'negotiation');
      expect(res.speechResponse, contains('settlement range'));
      expect(res.speechResponse, contains('spread'));
    });

    test('5. AI Property Verification & 5-Pillar Deal Score', () async {
      final res = await service.processDialogue('Property ka verification score aur 5 pillars kya hain?');
      expect(res.flowType, 'verification');
      expect(res.speechResponse, contains('PropZen Deal Score'));
      expect(res.speechResponse, contains('100'));
    });

    test('6. Multi-Property Visit Planner & Digital Checklist Summary', () async {
      // Planner
      final resPlanner = await service.processDialogue('Kal 3 properties ka tour itinerary plan kar do');
      expect(resPlanner.flowType, 'planner');
      expect(resPlanner.speechResponse, contains('Stop 1'));

      // Checklist feedback
      final resChecklist = await service.processDialogue('Flat overall achha tha, balcony badi thi but parking chhoti thi');
      expect(resChecklist.flowType == 'checklist' || resChecklist.flowType == 'visitFeedback', isTrue);
      expect(resChecklist.speechResponse, contains('Pros'));
    });

    test('7. Dealer Voice Tools: Listing Creator & Lead Scoring', () async {
      // Listing Creator
      final resListing = await service.processDialogue('3 BHK flat hai Sector 150 mein, 1850 sqft, price 1.25 Cr, ready to move hai');
      expect(resListing.flowType, 'dealer');
      expect(resListing.speechResponse, contains('3 BHK'));
      expect(resListing.speechResponse, contains('1.25 Cr'));

      // Lead Scoring
      final resLead = await service.processDialogue('Rahul ka lead score kaisa hai?');
      expect(resLead.flowType, 'dealer');
      expect(resLead.speechResponse, contains('HOT LEAD'));
    });

    test('8. General Real Estate Concept FAQs & Property Comparison', () async {
      // RERA FAQ
      final resRera = await service.processDialogue('RERA kya hota hai?');
      expect(resRera.flowType, 'faq');
      expect(resRera.speechResponse, contains('RERA'));

      // Carpet Area FAQ
      final resCarpet = await service.processDialogue('Carpet area aur super built up area mein difference kya hai?');
      expect(resCarpet.flowType, 'faq');
      expect(resCarpet.speechResponse, contains('Carpet area'));

      // Comparison
      final resComp = await service.processDialogue('Dono properties mein se kaunsi better hai?');
      expect(resComp.flowType, 'comparison');
      expect(resComp.matchedProperties.length, greaterThanOrEqualTo(2));
    });

    test('9. Multi-turn Conversational Context Retention', () async {
      // Turn 1: Location
      final turn1 = await service.processDialogue('Mujhe Noida mein property chahiye');
      expect(service.context.location, 'Noida');

      // Turn 2: Budget
      final turn2 = await service.processDialogue('80 lakh');
      expect(service.context.maxBudget, 8000000);
      expect(service.context.location, 'Noida'); // Retained from turn 1

      // Turn 3: BHK
      final turn3 = await service.processDialogue('3 BHK');
      expect(service.context.bedrooms, 3);
      expect(service.context.maxBudget, 8000000); // Retained
      expect(service.context.location, 'Noida'); // Retained
    });

    test('10. Human Relationship Manager Handoff', () async {
      final res = await service.processDialogue('Mujhe agent se baat karni hai');
      expect(res.speechResponse, contains('98103 94068'));
    });
  });
}

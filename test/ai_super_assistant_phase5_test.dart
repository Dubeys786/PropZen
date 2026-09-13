import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/services/propzen_voice_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_lead_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/config/voice_config.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PropertyStateService.instance.initializeSampleData();
    DealerLeadService.instance.initializeSampleLeads();
    DealerSubscriptionService.instance.init();
    PropzenAiAgentService.instance.clearSession();
    UserSession.clear();
  });

  group('PropZen AI Super Assistant & Voice Agent (Phase 5)', () {
    test('1. Hindi & Hinglish Search Query ("Mujhe Greater Noida mein 80 lakh ke andar 3 BHK chahiye")', () async {
      final ai = PropzenAiAgentService.instance;
      final result = await ai.processDialogue('Mujhe Greater Noida mein 80 lakh ke andar 3 BHK chahiye');

      expect(ai.context.location, equals('Greater Noida'));
      expect(ai.context.bedrooms, equals(3));
      expect(ai.context.maxBudget, equals(8000000.0));
      expect(result.speechResponse.isNotEmpty, isTrue);
      expect(result.language, anyOf(equals('hinglish'), equals('hindi')));
    });

    test('2. English Location Search ("Show me properties near Yamuna Expressway")', () async {
      final ai = PropzenAiAgentService.instance;
      final result = await ai.processDialogue('Show me properties near Yamuna Expressway');

      expect(ai.context.location, equals('Yamuna Expressway'));
      expect(result.matchedProperties.isNotEmpty, isTrue);
      expect(result.matchedProperties.any((p) => p.sector.toLowerCase().contains('yamuna') || p.city.toLowerCase().contains('expressway') || p.address.toLowerCase().contains('yamuna')), isTrue);
    });

    test('3. Ready to Move Filter ("Mujhe ready to move property chahiye")', () async {
      final ai = PropzenAiAgentService.instance;
      final result = await ai.processDialogue('Mujhe ready to move property chahiye');

      expect(ai.context.status, equals('Ready to Move'));
      expect(result.speechResponse.isNotEmpty, isTrue);
    });

    test('4. Side-by-Side Property Comparison ("Compare these two properties")', () async {
      final ai = PropzenAiAgentService.instance;
      final result = await ai.processDialogue('Compare these two properties');

      expect(result.flowType, equals('comparison'));
      expect(result.comparisonData, isNotNull);
      expect(result.comparisonData!['betterBudget'], isNotNull);
      expect(result.comparisonData!['betterSize'], isNotNull);
      expect(result.matchedProperties.length, greaterThanOrEqualTo(2));
      expect(result.textResponse.contains('Comparison Summary') || result.textResponse.contains('तुलना सारांश') || result.textResponse.contains('Summary'), isTrue);
    });

    test('5. Direct Voice Actions (Open Details, Drone Tour, 360 Tour, 3D Model, Site Visit)', () async {
      final ai = PropzenAiAgentService.instance;

      // 5.1 Open Details
      final resDetails = await ai.processDialogue('Property details kholo');
      expect(resDetails.triggeredAction, equals('open_details'));

      // 5.2 Drone Tour
      final resDrone = await ai.processDialogue('Drone tour chalao');
      expect(resDrone.triggeredAction, equals('open_drone'));

      // 5.3 360 Tour
      final res360 = await ai.processDialogue('360 tour dikhao');
      expect(res360.triggeredAction, equals('open_360'));

      // 5.4 3D Model
      final res3d = await ai.processDialogue('3D model kholo');
      expect(res3d.triggeredAction, equals('open_3d'));

      // 5.5 Book Site Visit
      final resVisit = await ai.processDialogue('Site visit book karo');
      expect(resVisit.triggeredAction, equals('book_site_visit'));

      // 5.6 Remote Tour Request
      final resRemote = await ai.processDialogue('Remote tour request karo');
      expect(resRemote.triggeredAction, equals('request_remote_tour'));

      // 5.7 Subscription Plans
      final resPlans = await ai.processDialogue('Subscription plans dikhao');
      expect(resPlans.triggeredAction, equals('view_plans'));

      // 5.8 Investment Calculator
      final resCalc = await ai.processDialogue('Yield calculator kholo');
      expect(resCalc.triggeredAction, equals('open_investment_calc'));

      // 5.9 Home Loan Assistance
      final resLoan = await ai.processDialogue('Loan assistance');
      expect(resLoan.triggeredAction, equals('open_loan_assistance'));
    });

    test('6. Property Details Q&A via Voice (Price, Area, Parking, Possession, Metro, Drone availability)', () async {
      final ai = PropzenAiAgentService.instance;
      ai.context.selectedProperty = PropertyStateService.instance.allProperties.first;
      final prop = ai.context.selectedProperty!;

      // Price
      final resPrice = await ai.processDialogue('Is property ka price kya hai?');
      expect(resPrice.speechResponse.contains('price') || resPrice.speechResponse.contains('₹') || resPrice.speechResponse.contains('लाख') || resPrice.speechResponse.contains('करोड़'), isTrue);

      // Area
      final resArea = await ai.processDialogue('Kitna area hai?');
      expect(resArea.speechResponse.contains('sq.ft') || resArea.speechResponse.contains('${prop.sqft}'), isTrue);

      // Parking
      final resParking = await ai.processDialogue('Isme parking hai?');
      expect(resParking.speechResponse.toLowerCase().contains('parking') || resParking.speechResponse.contains('कवर्ड'), isTrue);

      // Possession
      final resPossession = await ai.processDialogue('Possession kab hai?');
      expect(resPossession.speechResponse.toLowerCase().contains('possession') || resPossession.speechResponse.contains('पजेशन'), isTrue);

      // Metro
      final resMetro = await ai.processDialogue('Nearby metro kitni door hai?');
      expect(resMetro.speechResponse.toLowerCase().contains('metro') || resMetro.speechResponse.contains('मेट्रो'), isTrue);

      // Drone
      final resDrone = await ai.processDialogue('Drone tour available hai?');
      expect(resDrone.speechResponse.toLowerCase().contains('drone') || resDrone.speechResponse.contains('ड्रोन'), isTrue);
    });

    test('7. Dealer AI Assistant (Show leads, top enquiries, listing copy, lead summary, follow-up, visits)', () async {
      final ai = PropzenAiAgentService.instance;
      UserSession.login(
        name: 'Sharma Properties',
        email: 'dealer@propzen.in',
        phone: '9810394068',
        role: 'Verified Dealer',
      );
      UserSession.setUserType('dealer');

      // 7.1 Show Leads
      final resLeads = await ai.processDialogue('Mere new leads dikhao');
      expect(resLeads.dealerLeads, isNotNull);
      expect(resLeads.dealerLeads!.isNotEmpty, isTrue);

      // 7.2 Top Enquiries
      final resEnquiries = await ai.processDialogue('Which property is getting the most enquiries?');
      expect(resEnquiries.dealerInsight, isNotNull);
      expect(resEnquiries.dealerInsight!['topProperty'], isNotNull);

      // 7.3 Create Property Description (Subscription Enforced)
      final resCopy = await ai.processDialogue('Create a property description');
      expect(resCopy.speechResponse.isNotEmpty, isTrue);

      // 7.4 Summarize Lead
      final resSummary = await ai.processDialogue('Summarize this lead');
      expect(resSummary.speechResponse.contains('Score') || resSummary.speechResponse.contains('स्कोर') || resSummary.speechResponse.contains('बजट'), isTrue);

      // 7.5 Create Follow-up Message
      final resFollowUp = await ai.processDialogue('Create follow-up message for this lead');
      expect(resFollowUp.speechResponse.contains('WhatsApp') || resFollowUp.speechResponse.contains('follow-up') || resFollowUp.speechResponse.contains('ड्राफ्ट'), isTrue);

      // 7.6 Show Site Visits Today
      final resVisits = await ai.processDialogue('Show my site visits today');
      expect(resVisits.speechResponse.contains('विजिट') || resVisits.speechResponse.contains('visit') || resVisits.speechResponse.contains('appointment'), isTrue);
    });

    test('8. NRI Mode Context & International Advisory', () async {
      final ai = PropzenAiAgentService.instance;
      UserSession.login(
        name: 'Vikram Mehta',
        email: 'vikram@dubai.com',
        phone: '+971501234567',
        role: 'Buyer',
      );
      UserSession.setUserType('nri', country: 'UAE (Dubai)');

      final resNri = await ai.processDialogue('I live in Dubai and want to explore properties');
      expect(resNri.flowType, equals('nri'));
      expect(resNri.speechResponse.toLowerCase().contains('nri') || resNri.speechResponse.contains('रिमोट') || resNri.speechResponse.contains('drone'), isTrue);
    });

    test('9. Multi-turn Session Memory Retention', () async {
      final ai = PropzenAiAgentService.instance;

      // Turn 1: Specify BHK
      await ai.processDialogue('I want a 3 BHK');
      expect(ai.context.bedrooms, equals(3));

      // Turn 2: Specify Location
      await ai.processDialogue('In Sector 150');
      expect(ai.context.bedrooms, equals(3));
      expect(ai.context.location, equals('Sector 150'));

      // Turn 3: Specify Budget
      await ai.processDialogue('Under 1.5 Crore');
      expect(ai.context.bedrooms, equals(3));
      expect(ai.context.location, equals('Sector 150'));
      expect(ai.context.maxBudget, equals(15000000.0));
    });

    test('10. Female Voice Persona Configuration Verification', () {
      expect(VoiceConfig.femaleVoiceTokens.isNotEmpty, isTrue);
      expect(VoiceConfig.femaleVoiceTokens.any((t) => t.toLowerCase().contains('swara') || t.toLowerCase().contains('neerja') || t.toLowerCase().contains('kalpana') || t.toLowerCase().contains('female')), isTrue);
      expect(VoiceConfig.blacklistedMaleKeywords.any((m) => m.toLowerCase().contains('male') || m.toLowerCase().contains('david') || m.toLowerCase().contains('george') || m.toLowerCase().contains('ravi')), isTrue);
    });
  });
}

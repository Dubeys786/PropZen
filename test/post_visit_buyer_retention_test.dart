import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/post_visit_retention_model.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/deal_room_model.dart';
import 'package:dealghar_ncr_10x/services/post_visit_retention_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/services/deal_room_service.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/widgets/post_visit_feedback_dialog.dart';
import 'package:dealghar_ncr_10x/screens/ai_property_rematch_screen.dart';
import 'package:dealghar_ncr_10x/screens/my_site_visits_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_site_visits_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PropertyStateService.instance.clearScheduledVisits();
    PropzenAiAgentService.instance.clearSession();
  });

  group('Post-Site-Visit Buyer Retention Engine Tests', () {
    test('1. NLP parser extracts Pros, Cons, Concerns, and Deal Breakers from natural speech', () {
      const input = 'Flat acha tha but parking chhoti thi. Balcony bahut achhi lagi aur location prime hai but price thoda high hai.';

      final feedback = PostVisitFeedback.parse(
        visitId: 'VISIT-101',
        propertyId: 'prop_ats_01',
        propertyTitle: 'ATS HomeKraft Happy Trails',
        buyerId: 'usr_aman',
        interestLevel: BuyerInterestLevel.wantMoreOptions,
        rawNotes: input,
      );

      expect(feedback.pros, isNotEmpty);
      expect(feedback.pros.any((p) => p.toLowerCase().contains('balcony') || p.toLowerCase().contains('layout')), isTrue);

      expect(feedback.cons, isNotEmpty);
      expect(feedback.cons.any((c) => c.toLowerCase().contains('parking') || c.toLowerCase().contains('price')), isTrue);

      expect(feedback.concerns, isNotEmpty);
      expect(feedback.dealBreakers.any((db) => db.toLowerCase().contains('parking')), isTrue);
      expect(feedback.interestLevel, equals(BuyerInterestLevel.wantMoreOptions));
      expect(feedback.recommendedNextStep.toLowerCase(), contains('find better properties'));
    });

    test('2. PostVisitRetentionService stores feedback and updates buyer preference profile', () async {
      final retentionService = PostVisitRetentionService.instance;

      PropertyStateService.instance.addScheduledVisit(
        propertyId: 'PROP-NCR-101',
        propertyTitle: 'Godrej Palm Retreat',
        sector: 'Sector 150, Noida',
        price: '₹1.45 Cr',
        date: '2026-08-25',
        time: '11:00 AM',
        name: 'Aman Sharma',
        phone: '9810394068',
        visitorCount: 2,
        cabRequired: true,
        status: 'Confirmed',
      );

      final visitId = PropertyStateService.instance.scheduledVisits.first['id'] as String;

      final fb = await retentionService.submitFeedback(
        visitId: visitId,
        propertyId: 'PROP-NCR-101',
        propertyTitle: 'Godrej Palm Retreat',
        interestLevel: BuyerInterestLevel.wantMoreOptions,
        rawNotes: 'Flat acha tha but parking chhoti thi.',
      );

      expect(fb.visitId, equals(visitId));
      expect(PropertyStateService.instance.scheduledVisits.first['status'], equals('Completed'));

      final storedFb = retentionService.getFeedbackForVisit(visitId);
      expect(storedFb, isNotNull);
      expect(storedFb!.dealBreakers, contains('Small parking space'));

      final buyerPref = retentionService.buyerPreferenceProfile;
      expect((buyerPref['dealBreakers'] as List), contains('Small parking space'));
    });

    test('3. AI Property Re-Match boosts alternatives with spacious covered parking', () {
      final retentionService = PostVisitRetentionService.instance;

      final feedback = PostVisitFeedback.parse(
        visitId: 'VISIT-TEST',
        propertyId: 'PROP-NCR-101',
        propertyTitle: 'Godrej Palm Retreat',
        buyerId: 'usr_aman',
        interestLevel: BuyerInterestLevel.wantMoreOptions,
        rawNotes: 'Parking chhoti thi aur price high tha.',
      );

      final rematches = retentionService.getReMatchedProperties(feedback: feedback);
      expect(rematches, isNotEmpty);

      final top = rematches.first;
      expect(top.matchPercentage, greaterThanOrEqualTo(80));
      expect(top.matchExplanation, isNotEmpty);
      expect(top.matchExplanation, contains('Match because'));
    });

    test('4. Dealer AI Follow-Up generator creates personalized message addressing parking concern', () {
      final retentionService = PostVisitRetentionService.instance;

      final feedback = PostVisitFeedback.parse(
        visitId: 'VISIT-TEST-2',
        propertyId: 'PROP-NCR-102',
        propertyTitle: 'DLF The Arbour Sector 63',
        buyerId: 'usr_rahul',
        buyerName: 'Rahul Verma',
        interestLevel: BuyerInterestLevel.wantMoreOptions,
        rawNotes: 'Flat acha tha but parking chhoti thi.',
      );

      final msg = retentionService.generateDealerFollowUpMessage(feedback);
      expect(msg, contains('Rahul'));
      expect(msg, contains('DLF The Arbour Sector 63'));
      expect(msg.toLowerCase(), contains('parking'));
    });

    test('5. Voice Agent handles complete post-visit query flow in natural Hindi/Hinglish', () async {
      final agent = PropzenAiAgentService.instance;

      // 1. Visit Feedback
      final res1 = await agent.processDialogue('Flat acha tha but parking chhoti thi.');
      expect(res1.speechResponse, contains('samajh gayi'));
      expect(res1.speechResponse, contains('parking'));

      // 2. Visit Summary
      final res2 = await agent.processDialogue('Jo flat maine kal dekha tha uska summary dikhao');
      expect(res2.speechResponse, contains('AI Summary'));
      expect(res2.speechResponse, contains('Pros:'));

      // 3. Property Re-Match
      final res3 = await agent.processDialogue('Us jaisi aur better properties dikhao');
      expect(res3.speechResponse, contains('Match'));

      // 4. Start Negotiation
      final res4 = await agent.processDialogue('Mujhe seller se negotiate karna hai');
      expect(res4.speechResponse, contains('Safe Deal Room'));
    });
  });

  group('Post-Visit Retention UI Widget & Screen Tests', () {
    testWidgets('6. MySiteVisitsScreen renders COMPLETED badge and post-visit action triggers', (tester) async {
      PropertyStateService.instance.addScheduledVisit(
        propertyId: 'PROP-NCR-101',
        propertyTitle: 'Skyline Heights Luxury 3 BHK',
        sector: 'Sector 150, Noida',
        price: '₹1.50 Cr',
        date: '2026-08-25',
        time: '11:00 AM',
        name: 'Aman Sharma',
        phone: '9810394068',
        visitorCount: 3,
        cabRequired: true,
        status: 'Completed',
      );

      final visitId = PropertyStateService.instance.scheduledVisits.first['id'] as String;

      await PostVisitRetentionService.instance.submitFeedback(
        visitId: visitId,
        propertyId: 'PROP-NCR-101',
        propertyTitle: 'Skyline Heights Luxury 3 BHK',
        interestLevel: BuyerInterestLevel.interested,
        rawNotes: 'Balcony bahut achhi lagi.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MySiteVisitsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('SITE VISIT COMPLETED ✓'), findsOneWidget);
      expect(find.text('Your Site Visit Feedback'), findsOneWidget);
      expect(find.text('View / Edit Summary'), findsOneWidget);
      expect(find.text('Find Better Properties'), findsOneWidget);
      expect(find.text('Open Safe Deal Room'), findsOneWidget);
    });

    testWidgets('7. AiPropertyRematchScreen renders matched properties with match % and why it matches', (tester) async {
      final feedback = PostVisitFeedback.parse(
        visitId: 'VISIT-REMATCH',
        propertyId: 'prop_01',
        propertyTitle: 'Godrej Palm Retreat',
        buyerId: 'usr_active',
        interestLevel: BuyerInterestLevel.wantMoreOptions,
        rawNotes: 'Flat acha tha but parking chhoti thi.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AiPropertyRematchScreen(feedback: feedback),
        ),
      );
      await tester.pump();

      expect(find.text('AI Property Re-Match'), findsOneWidget);
      expect(find.text('Properties Matched For You'), findsOneWidget);
      expect(find.text('Why this matches you'), findsWidgets);
      expect(find.text('Book Visit'), findsWidgets);
    });

    testWidgets('8. UserProfileScreen renders 10-Milestone My Property Journey section for Buyer', (tester) async {
      UserSession.login(
        name: 'Buyer User',
        email: 'buyer@propzen.in',
        role: 'Buyer',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Property Journey'), findsOneWidget);
      expect(find.text('Searches'), findsOneWidget);
      expect(find.text('Saved Deals'), findsOneWidget);
      expect(find.text('Site Visits'), findsWidgets);
      expect(find.text('Visit Feedback'), findsOneWidget);
      expect(find.text('AI Re-Match'), findsOneWidget);
      expect(find.text('Negotiations'), findsOneWidget);
      expect(find.text('Deal Rooms'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);

      UserSession.logout();
    });

    testWidgets('9. DealerSiteVisitsScreen displays AI Lead Insight and AI Suggested Follow-up button', (tester) async {
      UserSession.login(
        name: 'Sakshi Sharma',
        phone: '9810394068',
        email: 'dealer@propzen.in',
        role: 'DEALER',
        isEmailVerified: true,
      );

      PropertyStateService.instance.addScheduledVisit(
        propertyId: 'PROP-NCR-202',
        propertyTitle: 'ATS HomeKraft Happy Trails',
        sector: 'Sector 10, Greater Noida West',
        price: '₹95 Lakh',
        date: '2026-08-25',
        time: '02:00 PM',
        name: 'Sakshi Sharma',
        phone: '9810394068',
        visitorCount: 2,
        cabRequired: false,
        status: 'Completed',
      );

      final visitId = PropertyStateService.instance.scheduledVisits.first['id'] as String;

      await PostVisitRetentionService.instance.submitFeedback(
        visitId: visitId,
        propertyId: 'PROP-NCR-202',
        propertyTitle: 'ATS HomeKraft Happy Trails',
        interestLevel: BuyerInterestLevel.wantMoreOptions,
        rawNotes: 'Flat acha tha but parking chhoti thi.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DealerSiteVisitsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('AI Post-Visit Lead Insight'), findsOneWidget);
      expect(find.text('Lead Score: 92%'), findsOneWidget);
      expect(find.text('AI Suggested Follow-up'), findsOneWidget);
    });
  });
}

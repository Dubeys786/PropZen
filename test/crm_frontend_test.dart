import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_lead.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_dashboard_metrics.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_follow_up.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_task.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_campaign.dart';
import 'package:dealghar_ncr_10x/crm/models/customer_360.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_analytics.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_ai_models.dart';
import 'package:dealghar_ncr_10x/crm/widgets/crm_route_guard.dart';
import 'package:dealghar_ncr_10x/crm/widgets/crm_stat_card.dart';
import 'package:dealghar_ncr_10x/crm/screens/crm_unauthorized_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  group('CRM DTO Models Parsing & Validation', () {
    test('CrmLead model serializes and deserializes accurately with backend enums', () {
      final json = {
        'id': '7c85854f-124b-4a57-8ae9-67995166f0ee',
        'leadNumber': 'LEAD-2026-001',
        'name': 'Rahul Sharma',
        'email': 'rahul.sharma@example.com',
        'phone': '+919876543210',
        'message': 'Interested in 3 BHK in Noida Sector 150',
        'source': 'WEBSITE',
        'status': 'QUALIFIED',
        'stage': 'INTERESTED',
        'priority': 'HIGH',
        'leadScore': 85,
        'budgetMin': 15000000.0,
        'budgetMax': 20000000.0,
        'preferredCity': 'Noida',
        'preferredSector': 'Sector 150',
        'preferredBhk': '3 BHK',
        'createdAt': '2026-09-08T10:00:00Z',
      };

      final lead = CrmLead.fromJson(json);

      expect(lead.id, '7c85854f-124b-4a57-8ae9-67995166f0ee');
      expect(lead.leadNumber, 'LEAD-2026-001');
      expect(lead.name, 'Rahul Sharma');
      expect(lead.phone, '+919876543210');
      expect(lead.source, LeadSource.website);
      expect(lead.status, LeadStatus.qualified);
      expect(lead.stage, LeadStage.interested);
      expect(lead.priority, LeadPriority.high);
      expect(lead.leadScore, 85);
      expect(lead.budgetMin, 15000000.0);
      expect(lead.displayLocation, 'Sector 150, Noida');
      expect(lead.displayBudget, '₹15000000 - ₹20000000');

      // Test copyWith
      final updated = lead.copyWith(status: LeadStatus.converted, stage: LeadStage.converted);
      expect(updated.status, LeadStatus.converted);
      expect(updated.stage, LeadStage.converted);
      expect(updated.name, 'Rahul Sharma');
    });

    test('CrmDashboardMetrics parses backend calculation payload', () {
      final json = {
        'totalLeads': 120,
        'newLeads': 15,
        'contactedLeads': 40,
        'qualifiedLeads': 35,
        'followUpsDue': 8,
        'siteVisits': 18,
        'convertedLeads': 12,
        'lostLeads': 10,
        'conversionRate': 10.0,
      };

      final metrics = CrmDashboardMetrics.fromJson(json);

      expect(metrics.totalLeads, 120);
      expect(metrics.newLeads, 15);
      expect(metrics.contactedLeads, 40);
      expect(metrics.qualifiedLeads, 35);
      expect(metrics.followUpsDue, 8);
      expect(metrics.siteVisits, 18);
      expect(metrics.convertedLeads, 12);
      expect(metrics.lostLeads, 10);
      expect(metrics.conversionRate, 10.0);
    });

    test('CrmFollowUp evaluates overdue and today states properly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final json = {
        'id': 'fup-01',
        'leadId': 'lead-01',
        'leadName': 'Amit Verma',
        'scheduledAt': pastDate.toIso8601String(),
        'type': 'FOLLOW_UP',
        'channel': 'PHONE',
        'status': 'PENDING',
        'notes': 'Discuss payment schedule',
      };

      final fup = CrmFollowUp.fromJson(json);

      expect(fup.id, 'fup-01');
      expect(fup.leadName, 'Amit Verma');
      expect(fup.status, FollowUpStatus.pending);
      expect(fup.isOverdue, isTrue);
      expect(fup.isToday, isFalse);
    });

    test('CrmTask parses statuses and priorities', () {
      final json = {
        'id': 'task-01',
        'title': 'Verify property documents',
        'priority': 'URGENT',
        'status': 'IN_PROGRESS',
      };

      final task = CrmTask.fromJson(json);

      expect(task.id, 'task-01');
      expect(task.title, 'Verify property documents');
      expect(task.priority, 'URGENT');
      expect(task.status, TaskStatus.inProgress);
      expect(task.isCompleted, isFalse);
    });

    test('CrmCampaign computes real delivery and read percentage metrics', () {
      final json = {
        'id': 'camp-01',
        'name': 'Diwali Festive Launch',
        'type': 'PROMOTIONAL',
        'channel': 'WHATSAPP',
        'status': 'COMPLETED',
        'totalRecipients': 200,
        'sentCount': 190,
        'deliveredCount': 180,
        'readCount': 95,
        'failedCount': 10,
      };

      final camp = CrmCampaign.fromJson(json);

      expect(camp.id, 'camp-01');
      expect(camp.status, CampaignStatus.completed);
      expect(camp.deliveryRate, 95.0); // 190/200 = 95%
      expect(camp.readRate, 50.0); // 95/190 = 50%
    });

    test('Customer360Profile parses aggregated collections and total spend', () {
      final json = {
        'customerId': 'cust-01',
        'fullName': 'Priya Nair',
        'email': 'priya@example.com',
        'phone': '+919811122233',
        'totalLeads': 2,
        'totalEnquiries': 3,
        'totalSiteVisits': 1,
        'totalServiceRequests': 1,
        'totalSpent': 2500000.0,
        'leads': [],
        'followups': [],
        'tasks': [],
        'notes': [],
      };

      final profile = Customer360Profile.fromJson(json);

      expect(profile.customerId, 'cust-01');
      expect(profile.fullName, 'Priya Nair');
      expect(profile.totalLeads, 2);
      expect(profile.totalSpent, 2500000.0);
    });

    test('CrmAnalyticsData correctly maps pipeline velocity and stage distributions', () {
      final json = {
        'totalLeads': 50,
        'totalEnquiries': 45,
        'totalFollowUps': 30,
        'totalTasks': 20,
        'totalCommunications': 60,
        'leadsByStage': {'NEW_LEAD': 10, 'CONTACTED': 15, 'CONVERTED': 5},
        'followUpCompletionRate': 85.5,
        'taskCompletionRate': 90.0,
        'overallConversionRate': 10.0,
      };

      final analytics = CrmAnalyticsData.fromJson(json);

      expect(analytics.totalLeads, 50);
      expect(analytics.leadsByStage['NEW_LEAD'], 10);
      expect(analytics.leadsByStage['CONVERTED'], 5);
      expect(analytics.followUpCompletionRate, 85.5);
      expect(analytics.overallConversionRate, 10.0);
    });

    test('AI Models (AiLeadScore, AiNextAction, AiFollowUpDraft) parse Phase 11 payloads', () {
      final scoreJson = {
        'leadId': 'lead-01',
        'leadScore': 92,
        'scoreCategory': 'HOT',
        'reasons': ['Requested weekend site visit', 'High budget fit'],
        'confidence': 0.9,
      };
      final score = AiLeadScore.fromJson(scoreJson);
      expect(score.score, 92);
      expect(score.category, 'HOT');
      expect(score.reasons.length, 2);

      final actionJson = {
        'leadId': 'lead-01',
        'actionType': 'SITE_VISIT',
        'urgency': 'IMMEDIATE',
        'actionSummary': 'Confirm cab booking for site visit',
      };
      final action = AiNextAction.fromJson(actionJson);
      expect(action.urgency, 'IMMEDIATE');
      expect(action.actionSummary, 'Confirm cab booking for site visit');

      final draftJson = {
        'leadId': 'lead-01',
        'recommendedChannel': 'WHATSAPP',
        'draftMessage': 'Hi Rahul, we have reserved your site visit slot for Sunday 11 AM.',
        'messageIntent': 'CONFIRMATION',
      };
      final draft = AiFollowUpDraft.fromJson(draftJson);
      expect(draft.recommendedChannel, 'WHATSAPP');
      expect(draft.draftMessage, contains('Sunday 11 AM'));
    });
  });

  group('CRM Access Control & Route Guarding', () {
    setUp(() {
      UserSession.isLoggedInNotifier.value = false;
      UserSession.roleTierNotifier.value = 'Buyer';
      UserSession.emailNotifier.value = '';
    });

    test('Unauthenticated user is denied CRM access and guided to auth', () {
      expect(CrmRouteGuard.isUserAuthorized(), isFalse);
    });

    test('Normal Buyer user is denied CRM access', () {
      UserSession.isLoggedInNotifier.value = true;
      UserSession.roleTierNotifier.value = 'Buyer';
      UserSession.emailNotifier.value = 'buyer@gmail.com';

      expect(CrmRouteGuard.isUserAuthorized(), isFalse);
      expect(UserSession.isCrmAuthorized, isFalse);
    });

    test('Verified Dealer user is granted CRM access', () {
      UserSession.isLoggedInNotifier.value = true;
      UserSession.roleTierNotifier.value = 'DEALER';
      UserSession.phoneNotifier.value = '+919999988888';

      expect(CrmRouteGuard.isUserAuthorized(), isTrue);
      expect(UserSession.isCrmAuthorized, isTrue);
    });

    test('Staff / CRM Agent user is granted CRM access', () {
      UserSession.isLoggedInNotifier.value = true;
      UserSession.roleTierNotifier.value = 'CRM_AGENT';

      expect(CrmRouteGuard.isUserAuthorized(), isTrue);
      expect(UserSession.isCrmAuthorized, isTrue);
    });
  });

  group('CRM Widget Rendering Tests', () {
    testWidgets('CrmStatCard renders title, value, and subtitle properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrmStatCard(
              title: 'Total Leads',
              value: '428',
              icon: Icons.people,
              accentColor: Colors.blue,
              subtitle: 'Active prospects',
            ),
          ),
        ),
      );

      expect(find.text('Total Leads'), findsOneWidget);
      expect(find.text('428'), findsOneWidget);
      expect(find.text('Active prospects'), findsOneWidget);
    });

    testWidgets('CrmUnauthorizedScreen renders shield alert and explanation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CrmUnauthorizedScreen(),
        ),
      );

      expect(find.text('CRM Authorization Required'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);
      expect(find.text('Dealer Portal'), findsOneWidget);
    });
  });
}

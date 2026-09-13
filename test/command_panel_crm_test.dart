import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/widgets/admin_route_guard.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_follow_up.dart';
import 'package:dealghar_ncr_10x/crm/models/crm_lead.dart';

void main() {
  group('Command Panel CRM Integration - Route Architecture & Generation', () {
    test('AppRoutes declares all required Command Panel CRM paths', () {
      expect(AppRoutes.commandPanel, equals('/command-panel'));
      expect(AppRoutes.commandPanelCrm, equals('/command-panel/crm'));
      expect(AppRoutes.commandPanelCrmLeads, equals('/command-panel/crm/leads'));
      expect(AppRoutes.commandPanelCrmCustomers, equals('/command-panel/crm/customers'));
      expect(AppRoutes.commandPanelCrmFollowUps, equals('/command-panel/crm/follow-ups'));
      expect(AppRoutes.commandPanelCrmTasks, equals('/command-panel/crm/tasks'));
      expect(AppRoutes.commandPanelCrmProperties, equals('/command-panel/crm/properties'));
      expect(AppRoutes.commandPanelCrmSiteVisits, equals('/command-panel/crm/site-visits'));
      expect(AppRoutes.commandPanelCrmWhatsApp, equals('/command-panel/crm/whatsapp'));
      expect(AppRoutes.commandPanelCrmCampaigns, equals('/command-panel/crm/campaigns'));
      expect(AppRoutes.commandPanelCrmAnalytics, equals('/command-panel/crm/analytics'));
    });

    test('generateRoute correctly resolves /command-panel to AdminPanelScreen overview', () {
      final route = AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.commandPanel));
      expect(route, isA<MaterialPageRoute>());

      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(FakeBuildContext());

      expect(widget, isA<AdminRouteGuard>());
      final guard = widget as AdminRouteGuard;
      expect(guard.allowCrmRoles, isTrue);
      expect(guard.child, isA<AdminPanelScreen>());
      final screen = guard.child as AdminPanelScreen;
      expect(screen.initialNavIndex, equals(0));
    });

    test('generateRoute correctly resolves /command-panel/crm to index 20 (CRM Dashboard)', () {
      final route = AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.commandPanelCrm));
      final guard = (route as MaterialPageRoute).builder(FakeBuildContext()) as AdminRouteGuard;
      final screen = guard.child as AdminPanelScreen;
      expect(screen.initialNavIndex, equals(20));
    });

    test('generateRoute correctly resolves /command-panel/crm/leads to index 21 (Leads)', () {
      final route = AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.commandPanelCrmLeads));
      final guard = (route as MaterialPageRoute).builder(FakeBuildContext()) as AdminRouteGuard;
      final screen = guard.child as AdminPanelScreen;
      expect(screen.initialNavIndex, equals(21));
      expect(screen.initialLeadId, isNull);
    });

    test('generateRoute dynamically extracts lead ID for /command-panel/crm/leads/:id', () {
      const targetLeadId = 'lead-uuid-777-enterprise';
      final route = AppRoutes.generateRoute(const RouteSettings(name: '/command-panel/crm/leads/$targetLeadId'));
      final guard = (route as MaterialPageRoute).builder(FakeBuildContext()) as AdminRouteGuard;
      final screen = guard.child as AdminPanelScreen;
      expect(screen.initialNavIndex, equals(21));
      expect(screen.initialLeadId, equals(targetLeadId));
    });

    test('generateRoute correctly maps all other CRM workspaces', () {
      final expectations = <String, int>{
        AppRoutes.commandPanelCrmCustomers: 22,
        AppRoutes.commandPanelCrmFollowUps: 23,
        AppRoutes.commandPanelCrmTasks: 24,
        AppRoutes.commandPanelCrmProperties: 25,
        AppRoutes.commandPanelCrmSiteVisits: 26,
        AppRoutes.commandPanelCrmWhatsApp: 27,
        AppRoutes.commandPanelCrmCampaigns: 28,
        AppRoutes.commandPanelCrmAnalytics: 29,
      };

      for (final entry in expectations.entries) {
        final route = AppRoutes.generateRoute(RouteSettings(name: entry.key));
        final guard = (route as MaterialPageRoute).builder(FakeBuildContext()) as AdminRouteGuard;
        final screen = guard.child as AdminPanelScreen;
        expect(screen.initialNavIndex, equals(entry.value), reason: 'Failed for ${entry.key}');
      }
    });
  });

  group('Command Panel CRM Access Control & Strict Security', () {
    setUp(() {
      UserSession.clear();
    });

    tearDown(() {
      UserSession.clear();
    });

    test('Unauthenticated user is denied Command Panel CRM access', () {
      final status = AuthService.instance.checkCommandCenterAccess(currentRoute: AppRoutes.commandPanelCrm);
      expect(status, equals(AdminAccessStatus.unauthenticated));
    });

    test('Normal Buyer is strictly forbidden (403) from Command Panel CRM access', () {
      UserSession.setUser(
        name: 'Regular Buyer',
        email: 'buyer@propzen.in',
        phone: '9876543210',
        role: 'BUYER',
      );
      UserSession.verifyEmail();

      final status = AuthService.instance.checkCommandCenterAccess(currentRoute: AppRoutes.commandPanelCrm);
      expect(status, equals(AdminAccessStatus.forbidden403));
      expect(UserSession.isCrmAuthorized, isFalse);
    });

    test('CRM Manager has authorization for Command Panel CRM', () {
      UserSession.setUser(
        name: 'CRM Operations Lead',
        email: 'crm.manager@propzen.in',
        phone: '9876543211',
        role: 'CRM_MANAGER',
      );
      UserSession.verifyEmail();

      final status = AuthService.instance.checkCommandCenterAccess(currentRoute: AppRoutes.commandPanelCrm);
      expect(status, equals(AdminAccessStatus.allowed));
      expect(UserSession.isCrmAuthorized, isTrue);
    });

    test('CRM Agent has authorization for Command Panel CRM', () {
      UserSession.setUser(
        name: 'Agent Sarah',
        email: 'sarah.agent@propzen.in',
        phone: '9876543212',
        role: 'CRM_AGENT',
      );
      UserSession.verifyEmail();

      final status = AuthService.instance.checkCommandCenterAccess(currentRoute: AppRoutes.commandPanelCrmLeads);
      expect(status, equals(AdminAccessStatus.allowed));
      expect(UserSession.isCrmAuthorized, isTrue);
    });

    test('Permitted Dealer has authorization for Command Panel CRM', () {
      UserSession.setUser(
        name: 'Elite Realty Dealer',
        email: 'dealer@eliterealty.com',
        phone: '9876543213',
        role: 'DEALER',
      );
      UserSession.verifyEmail();

      final status = AuthService.instance.checkCommandCenterAccess(currentRoute: AppRoutes.commandPanelCrm);
      expect(status, equals(AdminAccessStatus.allowed));
      expect(UserSession.isCrmAuthorized, isTrue);
    });

    test('Super Admin has full clearance for Command Panel & CRM', () {
      UserSession.setUser(
        name: 'Sakshi Dubey',
        email: UserSession.designatedAdminEmail,
        phone: '9876543214',
        role: 'ADMIN',
      );
      UserSession.verifyEmail();

      final status = AuthService.instance.checkCommandCenterAccess(currentRoute: AppRoutes.commandPanel);
      expect(status, equals(AdminAccessStatus.allowed));
      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.isCrmAuthorized, isTrue);
    });
  });

  group('CRM DTO Models & Follow-up Communications', () {
    test('CrmFollowUp contains communication channels and parse fields properly', () {
      final followUp = CrmFollowUp(
        id: 'fu-01',
        leadId: 'lead-01',
        leadName: 'Vikram Mehta',
        leadPhone: '+919876543210',
        leadEmail: 'vikram@example.com',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        channel: 'WHATSAPP',
        notes: 'Review floor plan for 3BHK',
      );

      expect(followUp.leadPhone, equals('+919876543210'));
      expect(followUp.leadEmail, equals('vikram@example.com'));
      expect(followUp.isToday, isTrue);
      expect(followUp.isOverdue, isFalse);

      final json = followUp.toJson();
      expect(json['leadPhone'], equals('+919876543210'));
      expect(json['leadEmail'], equals('vikram@example.com'));

      final reconstructed = CrmFollowUp.fromJson(json);
      expect(reconstructed.leadPhone, equals('+919876543210'));
      expect(reconstructed.leadEmail, equals('vikram@example.com'));
    });

    test('CrmLead convenience getters provide fullName, phoneNumber, and city', () {
      const lead = CrmLead(
        id: 'lead-99',
        name: 'Ananya Sharma',
        phone: '9988776655',
        preferredCity: 'Gurugram',
        budgetMin: 15000000,
        budgetMax: 25000000,
      );

      expect(lead.fullName, equals('Ananya Sharma'));
      expect(lead.phoneNumber, equals('9988776655'));
      expect(lead.city, equals('Gurugram'));
    });
  });

  group('Command Panel Widget Mounting & CRM Dashboard', () {
    testWidgets('AdminPanelScreen mounts with initialNavIndex: 20 without crash', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.setUser(
        name: 'Sakshi Dubey',
        email: UserSession.designatedAdminEmail,
        phone: '9876543214',
        role: 'ADMIN',
      );
      UserSession.verifyEmail();
      AdminService.instance.setAdminLoggedIn(true, email: UserSession.designatedAdminEmail, name: 'Sakshi Dubey');
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPanelScreen(initialNavIndex: 20),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.text('CRM'), findsAtLeastNWidgets(1));
      expect(find.text('CRM Dashboard'), findsAtLeastNWidgets(1));
    });
  });
}

class FakeBuildContext extends Fake implements BuildContext {}

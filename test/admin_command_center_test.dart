import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/admin_models.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/services/property_intelligence_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

void main() {
  group('PropZen Phase 7 Admin Command Center Tests', () {
    late AdminCommandService commandService;

    setUp(() {
      commandService = AdminCommandService.instance;
    });

    test('1. RBAC Permissions Matrix verifies distinct permissions per role', () {
      // Super Admin has full permissions
      commandService.switchRole(AdminRole.superAdmin);
      expect(commandService.permissions.canManageUsers, isTrue);
      expect(commandService.permissions.canManageDealers, isTrue);
      expect(commandService.permissions.canVerifyProperties, isTrue);
      expect(commandService.permissions.canManagePayments, isTrue);
      expect(commandService.permissions.canManageSubscriptions, isTrue);
      expect(commandService.permissions.canManageAiConfig, isTrue);

      // Property Admin has property moderation only
      commandService.switchRole(AdminRole.propertyAdmin);
      expect(commandService.permissions.canVerifyProperties, isTrue);
      expect(commandService.permissions.canManagePayments, isFalse);
      expect(commandService.permissions.canManageUsers, isFalse);

      // Finance Admin has payment & subscription permissions only
      commandService.switchRole(AdminRole.financeAdmin);
      expect(commandService.permissions.canManagePayments, isTrue);
      expect(commandService.permissions.canManageSubscriptions, isTrue);
      expect(commandService.permissions.canVerifyProperties, isFalse);
      expect(commandService.permissions.canManageUsers, isFalse);

      // Support Admin has user & complaint permissions only
      commandService.switchRole(AdminRole.supportAdmin);
      expect(commandService.permissions.canManageUsers, isTrue);
      expect(commandService.permissions.canManageComplaints, isTrue);
      expect(commandService.permissions.canManagePayments, isFalse);

      // Content Admin has content management only
      commandService.switchRole(AdminRole.contentAdmin);
      expect(commandService.permissions.canManageContent, isTrue);
      expect(commandService.permissions.canManageDealers, isFalse);
    });

    test('2. User Management: Suspend and Reactivate with audit logging', () async {
      commandService.switchRole(AdminRole.superAdmin);
      final testUserId = commandService.users.first.id;

      // Suspend
      final suspendSuccess = await commandService.suspendUser(testUserId, 'Suspicious transaction pattern.');
      expect(suspendSuccess, isTrue);
      final suspendedUser = commandService.users.firstWhere((u) => u.id == testUserId);
      expect(suspendedUser.isSuspended, isTrue);
      expect(commandService.auditLogs.first.action, 'Suspended');

      // Reactivate
      final reactivateSuccess = await commandService.reactivateUser(testUserId);
      expect(reactivateSuccess, isTrue);
      final activeUser = commandService.users.firstWhere((u) => u.id == testUserId);
      expect(activeUser.isActive, isTrue);
      expect(commandService.auditLogs.first.action, 'Reactivated');
    });

    test('3. Dealer Management: Verification and Rejection workflows', () async {
      final dealer = commandService.dealers.firstWhere((d) => d.id == 'DLR-SEC150-102');

      // Verify
      final verifySuccess = await commandService.verifyDealer(dealer.id);
      expect(verifySuccess, isTrue);
      final verifiedDlr = commandService.dealers.firstWhere((d) => d.id == dealer.id);
      expect(verifiedDlr.isVerified, isTrue);
      expect(commandService.auditLogs.first.targetType, 'Dealer');
      expect(commandService.auditLogs.first.action.toUpperCase(), 'VERIFIED');
    });

    test('4. Complaint Ticket resolution workflow', () async {
      final ticket = commandService.complaints.first;

      final resolveSuccess = await commandService.updateComplaintStatus(
        ticket.id,
        'Resolved',
        notes: 'Discrepancy investigated and updated with builder bulletin.',
      );
      expect(resolveSuccess, isTrue);
      final resolvedTicket = commandService.complaints.firstWhere((c) => c.id == ticket.id);
      expect(resolvedTicket.status, 'Resolved');
      expect(resolvedTicket.resolutionNotes, isNotNull);
      expect(commandService.auditLogs.first.action, contains('Resolved'));
    });

    test('5. Dynamic Subscription Plan pricing update', () async {
      final starterPlan = commandService.plans.firstWhere((p) => p.id == 'plan_starter');
      final updated = starterPlan.copyWith(priceRupees: 2499.0);

      await commandService.saveSubscriptionPlan(updated);
      final savedPlan = commandService.plans.firstWhere((p) => p.id == 'plan_starter');
      expect(savedPlan.priceRupees, 2499.0);
      expect(commandService.auditLogs.first.targetType, 'Subscription Plan');
    });

    test('6. AI Feature Flag toggle works and records audit trail', () {
      commandService.toggleAiFeature('aiVoice', false);
      expect(commandService.featureFlags.aiVoiceEnabled, isFalse);
      expect(commandService.auditLogs.first.action, 'Disabled');

      commandService.toggleAiFeature('aiVoice', true);
      expect(commandService.featureFlags.aiVoiceEnabled, isTrue);
      expect(commandService.auditLogs.first.action, 'Enabled');
    });
  });

  group('PropZen Phase 6 Property Intelligence Tests', () {
    final intelService = PropertyIntelligenceService.instance;
    final sampleProp = Property.sampleDeals.first;

    test('1. Haversine distance calculator produces accurate geospatial distances in KM', () {
      // Distance between Noida Sec 150 (28.4485, 77.4930) and Sector 18 (28.5700, 77.3200) ~ 21.6 km
      final dist = intelService.calculateDistanceKm(28.4485, 77.4930, 28.5700, 77.3200);
      expect(dist, greaterThan(15.0));
      expect(dist, lessThan(30.0));
    });

    test('2. 5 KM POI Radius Filter extracts only landmarks within 5 KM', () {
      final pois = intelService.getNearbyPoisWithin5Km(sampleProp, radiusKm: 5.0);
      expect(pois, isNotEmpty);
      for (final poi in pois) {
        expect((poi['distanceKm'] as double), lessThanOrEqualTo(5.0));
      }
    });

    test('3. 5-Pillar Confidence Score evaluator scores between 0 and 100 with rating grade', () {
      final eval = intelService.evaluateConfidenceScore(sampleProp);
      final total = eval['totalScore'] as int;
      expect(total, greaterThanOrEqualTo(0));
      expect(total, lessThanOrEqualTo(100));
      expect(eval['ratingGrade'], isNotNull);
      expect(eval['reraPillar'], greaterThan(0));
      expect(eval['pricingPillar'], greaterThan(0));
    });

    test('4. True Cost Breakdown calculates all legal and registration charges', () {
      final cost = intelService.calculateTrueCostBreakdown(sampleProp, buyerCategory: 'Male');
      expect(cost.basePrice, greaterThan(0));
      expect(cost.stampDutyCharges, greaterThan(0));
      expect(cost.registrationCharges, greaterThan(0));
      expect(cost.estimatedTotalCost, greaterThan(cost.basePrice));
    });
  });
}

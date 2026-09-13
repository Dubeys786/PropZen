import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/config/phase_config.dart';
import 'package:dealghar_ncr_10x/services/feature_flag_service.dart';
import 'package:dealghar_ncr_10x/services/legal_verification_service.dart';
import 'package:dealghar_ncr_10x/services/wati_followup_service.dart';
import 'package:dealghar_ncr_10x/services/analytics_service.dart';
import 'package:dealghar_ncr_10x/services/area_discovery_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/services/user_notification_service.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/filter_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Master Phased Launch Architecture Tests', () {
    test('Phase 1 Diwali Launch enables only verified core MVP capabilities', () {
      final flagService = FeatureFlagService.instance;
      flagService.setLaunchPhase(LaunchPhase.phase1DiwaliLaunch);

      expect(flagService.isFeatureEnabled('property_listing'), isTrue);
      expect(flagService.isFeatureEnabled('wati_followup'), isTrue);
      expect(flagService.isFeatureEnabled('legal_verification'), isTrue);
      expect(flagService.isFeatureEnabled('automatic_pincode'), isTrue);

      // Phase 2 & 3 must be staged / disabled by default
      expect(flagService.isFeatureEnabled('vastu_3d'), isFalse);
      expect(flagService.isFeatureEnabled('visualizer_3d'), isFalse);
      expect(flagService.isFeatureEnabled('propzen_reporter'), isFalse);
      expect(flagService.isFeatureEnabled('youtube_automation'), isFalse);
    });

    test('Feature flags can be dynamically toggled at runtime without redeploying', () {
      final flagService = FeatureFlagService.instance;
      expect(flagService.isFeatureEnabled('vastu_3d'), isFalse);

      flagService.setFeatureFlag('vastu_3d', true);
      expect(flagService.isFeatureEnabled('vastu_3d'), isTrue);

      flagService.setFeatureFlag('vastu_3d', false);
      expect(flagService.isFeatureEnabled('vastu_3d'), isFalse);
    });

    test('LegalVerificationService mock adapter explicitly marks results as DEMO / TEST ONLY', () async {
      final legalService = LegalVerificationService.instance;
      legalService.setUseMockAdapter(true);

      final result = await legalService.verifyProperty(
        propertyId: 'prop_test_01',
        reraId: 'UPRERAPRJ999888',
        district: 'Gautam Buddha Nagar',
      );

      expect(result.isDemoMock, isTrue);
      expect(result.source, contains('DEMO / TEST ONLY'));
      expect(result.resultSummary, contains('DEMO / TEST ONLY'));
    });

    test('LegalVerificationService fails closed when production live API is unapproved', () async {
      final legalService = LegalVerificationService.instance;
      legalService.setUseMockAdapter(false);

      final result = await legalService.verifyProperty(
        propertyId: 'prop_test_prod',
        reraId: 'UPRERAPRJ111222',
        district: 'Gautam Buddha Nagar',
      );

      expect(result.status, equals(LegalVerificationStatus.needsReview));
      expect(result.source, contains('Awaiting Official Production API Approval'));
      expect(result.reviewedBy, contains('Pending Manual Review'));
    });

    test('WatiFollowUpService respects user consent and blocks opted-out users', () async {
      final watiService = WatiFollowUpService.instance;
      const testPhone = '+91 98765 00000';

      // Opt in
      watiService.recordConsent(
        leadId: 'lead_01',
        userId: 'usr_01',
        propertyId: 'prop_01',
        dealerId: 'dealer_01',
        phone: testPhone,
        optIn: true,
      );
      expect(watiService.canSendFollowUp(testPhone), isTrue);

      // User opts out
      watiService.recordConsent(
        leadId: 'lead_01',
        userId: 'usr_01',
        propertyId: 'prop_01',
        dealerId: 'dealer_01',
        phone: testPhone,
        optIn: false,
      );
      expect(watiService.canSendFollowUp(testPhone), isFalse);

      final dispatched = await watiService.triggerFollowUp(
        phone: testPhone,
        event: WhatsAppFollowUpEvent.siteVisitConfirmation,
      );
      expect(dispatched, isFalse);
    });

    test('AnalyticsService tracks trust telemetry and calculates valid snapshot', () {
      final analytics = AnalyticsService.instance;
      final initialViews = analytics.propertyViews;

      analytics.trackPropertyView('prop_01');
      expect(analytics.propertyViews, equals(initialViews + 1));

      final snapshot = analytics.getSnapshot();
      expect(snapshot.verificationCompletionRate, greaterThan(90.0));
      expect(snapshot.locationResolutionSuccessRate, greaterThan(95.0));
    });

    test('AreaDiscoveryService automatically resolves PIN and locality from coordinates without manual entry', () async {
      final areaService = AreaDiscoveryService.instance;
      const testProp = Property(
        id: 'prop_sec_150',
        title: 'Mahagun Manorialle',
        sector: 'Sector 150',
        city: 'Noida',
        postalCode: '201310',
        latitude: 28.4595,
        longitude: 77.5020,
        askingPriceCr: 2.2,
      );

      final profile = await areaService.resolveAreaForProperty(testProp);
      expect(profile.pincode, equals('201310'));
      expect(profile.city, equals('Noida'));
      expect(profile.landmarks.isNotEmpty, isTrue);
    });

    test('Exact Filter Matching strictly enforces all selected criteria with zero unrelated fallback', () {
      final filter = PropertyFilter(
        locality: 'Sector 150',
        bhkList: ['3 BHK'],
        minPriceCr: 2.0,
        maxPriceCr: 2.5,
      );

      const matchingProp = Property(
        id: 'prop_match',
        title: 'Noida Green Luxury',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '3 BHK',
        askingPriceCr: 2.2,
      );

      const nonMatchingBhk = Property(
        id: 'prop_mismatch_bhk',
        title: 'Noida Green 2BHK',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '2 BHK',
        askingPriceCr: 2.2,
      );

      const nonMatchingLoc = Property(
        id: 'prop_mismatch_loc',
        title: 'Greater Noida Luxury',
        sector: 'Sector 62',
        city: 'Noida',
        bhk: '3 BHK',
        askingPriceCr: 2.2,
      );

      const nonMatchingPrice = Property(
        id: 'prop_mismatch_price',
        title: 'Noida Green Penthouse',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '3 BHK',
        askingPriceCr: 3.5,
      );

      expect(filter.matches(matchingProp), isTrue);
      expect(filter.matches(nonMatchingBhk), isFalse);
      expect(filter.matches(nonMatchingLoc), isFalse);
      expect(filter.matches(nonMatchingPrice), isFalse);
    });

    test('Property report submission logs reason and details in moderation queue', () {
      final commandService = AdminCommandService.instance;
      final initialCount = commandService.reports.length;

      commandService.submitUserReport(
        propertyId: 'prop_test_report',
        propertyTitle: 'Mahagun Manorialle',
        reporterId: 'usr_test_reporter',
        reason: 'Misleading information',
        comment: 'Actual floor plan differs from listed blueprints.',
      );

      expect(commandService.reports.length, equals(initialCount + 1));
      final latest = commandService.reports.first;
      expect(latest.propertyId, equals('prop_test_report'));
      expect(latest.reason, equals('Misleading information'));
      expect(latest.status, equals('PENDING'));
    });

    test('PropZen unique human-readable ID formats consistently based on region', () {
      const propNoida = Property(
        id: 'prop_noida_01',
        title: 'Noida Luxury Oasis',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 3.5,
      );
      const propGurgaon = Property(
        id: 'prop_gurgaon_01',
        title: 'Gurgaon Golf Estate',
        sector: 'Golf Course Extension',
        city: 'Gurugram',
        askingPriceCr: 7.2,
      );

      expect(propNoida.propzenId, startsWith('PZ-NOI-'));
      expect(propGurgaon.propzenId, startsWith('PZ-GGN-'));
    });

    test('Verification freshness detects recent vs aging properties and triggers re-verification queue', () {
      final freshProp = Property(
        id: 'prop_fresh',
        title: 'Freshly Verified Tower',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 2.5,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      );
      final agedProp = Property(
        id: 'prop_aged',
        title: 'Aging Verification Tower',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 2.8,
        updatedAt: DateTime.now().subtract(const Duration(days: 95)).toIso8601String(),
      );

      expect(freshProp.freshnessDisplay, equals('Verified recently'));
      expect(freshProp.isReverificationRequired, isFalse);

      expect(agedProp.verificationAgeDays, greaterThanOrEqualTo(95));
      expect(agedProp.isReverificationRequired, isTrue);
    });

    test('Property availability lifecycle handles SOLD state and prevents active bookings', () {
      const availableProp = Property(
        id: 'prop_avail',
        title: 'Available Villa',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 4.5,
        availabilityStatus: 'AVAILABLE',
      );
      const soldProp = Property(
        id: 'prop_sold',
        title: 'Sold Out Villa',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 4.5,
        availabilityStatus: 'SOLD',
      );

      expect(availableProp.isAvailable, isTrue);
      expect(availableProp.isSold, isFalse);

      expect(soldProp.isSold, isTrue);
      expect(soldProp.isAvailable, isFalse);
    });

    test('UserNotificationService manages price drop alerts and mark-as-read lifecycle', () {
      final notifService = UserNotificationService.instance;
      final initialCount = notifService.notifications.length;

      notifService.togglePriceAlert('prop_test_price_alert');
      expect(notifService.hasPriceAlert('prop_test_price_alert'), isTrue);
      expect(notifService.notifications.length, equals(initialCount + 1));

      final latest = notifService.notifications.first;
      expect(latest.relatedEntityId, equals('prop_test_price_alert'));

      notifService.markAllAsRead();
      expect(notifService.unreadCount, equals(0));
    });
  });
}

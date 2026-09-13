import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/dealer_dashboard_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_lead_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/models/property.dart';

void main() {
  setUp(() {
    UserSession.logout();
    DealerSubscriptionService.instance.resetToNone();
  });

  group('PropZen Dealer Zero State & Real Data Binding Tests', () {
    testWidgets('1. New Dealer Dashboard displays 0 stats and NO fake numbers (14,820 / 418 / 126 / 48 / 18 / 7)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Vikram Sethi',
        userEmail: 'vikram@sethirealty.com',
        phone: '9811223344',
        role: 'Verified Dealer',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DealerDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header should show real dealer name
      expect(find.text('Vikram Sethi'), findsOneWidget);
      expect(find.text('Aman Sharma (Prime Realty)'), findsNothing);

      // Verify zero metrics
      expect(find.text('0 listed'), findsOneWidget);
      expect(find.text('0 views'), findsOneWidget);
      expect(find.text('0 active'), findsOneWidget);
      expect(find.text('0 qualified'), findsOneWidget);
      expect(find.text('0 visits'), findsOneWidget);
      expect(find.text('0 in Deal Room'), findsOneWidget);
      expect(find.text('₹0 Cr Volume'), findsOneWidget);

      // Verify NO fake numbers appear
      expect(find.text('14,820'), findsNothing);
      expect(find.text('418'), findsNothing);
      expect(find.text('126'), findsNothing);
      expect(find.text('48'), findsNothing);
      expect(find.text('18'), findsNothing);
      expect(find.text('7 Deals'), findsNothing);
      expect(find.text('+18.4% this month'), findsNothing);
      expect(find.text('92% Hot/Warm'), findsNothing);
      expect(find.text('75% Pre-approved'), findsNothing);
      expect(find.text('₹14.2 Cr Volume'), findsNothing);
    });

    testWidgets('2. Top Performing Listings displays empty state for new dealer with 0 properties', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'New Dealer',
        userEmail: 'new@dealer.com',
        phone: '9876500000',
        role: 'Verified Dealer',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DealerDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Empty state assertions
      expect(find.text('No properties listed yet'), findsOneWidget);
      expect(find.text('Create your first property listing to start receiving enquiries.'), findsOneWidget);
      expect(find.text('Add Property'), findsOneWidget);

      // Verify sample properties are NOT shown as this dealer's properties
      expect(find.text('ATS HomeKraft Happy Trails'), findsNothing);
      expect(find.text('Gaur City 2 Luxury Suites'), findsNothing);
    });

    testWidgets('3. Dealer Subscription card shows NO ACTIVE SUBSCRIPTION and View Plans for new dealer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Unsubscribed Dealer',
        userEmail: 'unsub@dealer.com',
        phone: '9876511111',
        role: 'Verified Dealer',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DealerDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('NO ACTIVE SUBSCRIPTION'), findsOneWidget);
      expect(find.text('NO SUBSCRIPTION'), findsOneWidget);
      expect(find.text('No active subscription • Select a plan to start'), findsOneWidget);
      expect(find.text('View Plans'), findsOneWidget);
    });

    testWidgets('4. Tenant Isolation: Dealer properties only returned for matching dealerId', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Rohan Gupta',
        userEmail: 'rohan@noidaestate.com',
        phone: '9822334455',
        role: 'Verified Dealer',
      );

      final dealerId = UserSession.dealerId;

      // Add a property belonging specifically to Rohan
      final rohanProp = Property(
        id: 'PROP-ROHAN-01',
        title: 'Rohan Exclusive Penthouse',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '4 BHK',
        askingPriceCr: 4.5,
        pricePerSqft: 11000,
        carpetAreaSqft: 3200,
        dealerId: dealerId,
        dealerName: 'Rohan Gupta',
        status: 'published',
      );
      PropertyStateService.instance.addProperty(rohanProp);

      final myProps = PropertyStateService.instance.getDealerPropertiesFor(dealerId);
      expect(myProps.length, 1);
      expect(myProps.first.title, 'Rohan Exclusive Penthouse');

      // Check another dealer's query
      final otherProps = PropertyStateService.instance.getDealerPropertiesFor('DLR-9999999999');
      expect(otherProps.isEmpty, true);
    });

    testWidgets('5. Tenant Isolation: Dealer Lead Service filters strictly by dealerId', (tester) async {
      final dealerId = 'DLR-9811223344';
      final leads = DealerLeadService.instance.getLeadsForDealer(dealerId);
      expect(leads.isEmpty, true);

      final visits = DealerLeadService.instance.getSiteVisitsForDealer(dealerId);
      expect(visits.isEmpty, true);

      final notifs = DealerLeadService.instance.getNotificationsForDealer(dealerId);
      expect(notifs.isEmpty, true);
    });

    testWidgets('6. Real Database Analytics calculation returns accurate 0s when no data', (tester) async {
      final analytics = DealerLeadService.instance.computeAnalyticsForDealer('DLR-EMPTY');
      expect(analytics.totalProperties, 0);
      expect(analytics.activeListings, 0);
      expect(analytics.totalViews, 0);
      expect(analytics.totalEnquiries, 0);
      expect(analytics.totalLeads, 0);
      expect(analytics.qualifiedLeads, 0);
      expect(analytics.siteVisitsCount, 0);
      expect(analytics.completedSiteVisits, 0);
      expect(analytics.conversionsCount, 0);
      expect(analytics.leadConversionRate, 0.0);
      expect(analytics.siteVisitConversionRate, 0.0);
      expect(analytics.topProperties.isEmpty, true);
    });

    testWidgets('7. Public Explore Properties catalogue remains fully accessible with 15 properties', (tester) async {
      final allPublic = PropertyStateService.instance.allProperties;
      expect(allPublic.length, greaterThanOrEqualTo(15));
      expect(allPublic.any((p) => p.title.contains('ATS HomeKraft')), true);
      expect(allPublic.any((p) => p.title.contains('Gaur City')), true);
    });
  });
}

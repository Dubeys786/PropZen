import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/widgets/property_card.dart';
import 'package:dealghar_ncr_10x/widgets/drone_tour_section.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/drone_subscription_service.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  group('PropZen - Universal Drone Tour on ALL 15 Property Cards Tests', () {
    testWidgets('1. Reusable DroneTourSection renders accurately for any property', (tester) async {
      final prop = Property.sampleDeals.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DroneTourSection(property: prop),
          ),
        ),
      );

      expect(find.text('Drone Tour'), findsOneWidget);
      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.text('Premium Aerial Experience'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
    });

    testWidgets('2. Unsubscribed user sees "Unlock" on PropertyCard', (tester) async {
      expect(UserSession.hasActiveDroneAccess, isFalse);
      final prop = Property.sampleDeals.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyCard(property: prop),
            ),
          ),
        ),
      );

      expect(find.byType(DroneTourSection), findsOneWidget);
      expect(find.text('Drone Tour'), findsOneWidget);
      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
    });

    testWidgets('3. Subscribed user sees "Watch Drone Tour" on PropertyCard', (tester) async {
      await DroneSubscriptionService.instance.verifyAndActivateSubscription(
        orderId: 'ord_test_sub',
        planId: 'drone_pass_3m',
        paymentId: 'pay_test_sub',
        transactionId: 'txn_test_sub',
      );
      expect(UserSession.hasActiveDroneAccess, isTrue);

      final prop = Property.sampleDeals.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyCard(property: prop),
            ),
          ),
        ),
      );

      expect(find.byType(DroneTourSection), findsOneWidget);
      expect(find.text('Watch Drone Tour'), findsOneWidget);
    });

    // Test ALL 15 properties in Property.sampleDeals
    for (int i = 0; i < Property.sampleDeals.length; i++) {
      final prop = Property.sampleDeals[i];
      testWidgets('Verify Property ${i + 1} (${prop.title}) displays Drone Tour Section', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PropertyCard(property: prop),
              ),
            ),
          ),
        );

        expect(find.byType(DroneTourSection), findsOneWidget,
            reason: 'Property #${i + 1} (${prop.title}) must contain DroneTourSection');
        expect(find.text('Drone Tour'), findsOneWidget);
        expect(find.text('PREMIUM'), findsOneWidget);
        expect(find.text('Premium Aerial Experience'), findsOneWidget);
      });
    }
  });
}

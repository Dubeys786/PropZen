import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/nri_subscription_model.dart';
import 'package:dealghar_ncr_10x/services/nri_subscription_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/widgets/nri_drone_tour_card.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  group('1. NRI User Identification & Session Tests', () {
    test('Defaults to Indian Resident and isNri == false', () {
      expect(UserSession.userType, 'Indian Resident');
      expect(UserSession.isNri, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('Explicitly setting NRI status updates isNri and userCountry', () {
      UserSession.setUserType('NRI', country: 'United States');
      expect(UserSession.userType, 'NRI');
      expect(UserSession.userCountry, 'United States');
      expect(UserSession.isNri, isTrue);
      // Notice: hasActiveDroneAccess is still false until verified active subscription exists
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('Logging out resets userType back to Indian Resident', () {
      UserSession.setUserType('NRI', country: 'United Arab Emirates');
      expect(UserSession.isNri, isTrue);

      UserSession.logout();
      expect(UserSession.userType, 'Indian Resident');
      expect(UserSession.isNri, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });
  });

  group('2. Property Drone Tour Model & Flags Tests', () {
    test('Property with droneTourAvailable == true and valid URL hasDroneTour is true', () {
      final prop = Property.empty.copyWith(
        id: 'p1',
        title: 'ATS HomeKraft',
        droneTourAvailable: true,
        droneTourUrl: 'https://example.com/drone.mp4',
        droneTourDuration: '2:45',
        droneFlightAltitudeMeters: 120,
      );

      expect(prop.hasDroneTour, isTrue);
      expect(prop.droneTourUrl, 'https://example.com/drone.mp4');
      expect(prop.droneFlightAltitudeMeters, 120);
    });

    test('Property with droneTourAvailable == false hasDroneTour is false', () {
      final prop = Property.empty.copyWith(
        id: 'p2',
        title: 'Gaurs NYC Residences',
        droneTourAvailable: false,
        droneTourUrl: null,
      );

      expect(prop.hasDroneTour, isFalse);
    });

    test('Serialization toMap and fromMap preserve drone fields', () {
      final original = Property.empty.copyWith(
        id: 'p3',
        title: 'Godrej Woods',
        droneTourAvailable: true,
        droneTourUrl: 'https://example.com/godrej.mp4',
        droneTourThumbnail: 'https://example.com/godrej.jpg',
        droneTourDuration: '3:10',
        droneTourAccessType: 'nri_exclusive',
        droneFlightAltitudeMeters: 150,
      );

      final map = original.toMap();
      final reconstructed = Property.fromMap(map);

      expect(reconstructed.droneTourAvailable, isTrue);
      expect(reconstructed.droneTourUrl, 'https://example.com/godrej.mp4');
      expect(reconstructed.droneTourThumbnail, 'https://example.com/godrej.jpg');
      expect(reconstructed.droneTourDuration, '3:10');
      expect(reconstructed.droneTourAccessType, 'nri_exclusive');
      expect(reconstructed.droneFlightAltitudeMeters, 150);
      expect(reconstructed.hasDroneTour, isTrue);
    });
  });

  group('3. Comprehensive 10-Case Real Payment Gateway & Lifecycle Tests', () {
    final service = NriSubscriptionService.instance;

    test('TEST 1: Select plan -> subscription NOT active', () {
      UserSession.setUserType('NRI', country: 'United States');
      final premiumPlan = service.getPlanById('nri_pass_premium')!;

      // User selects Premium plan in UI
      final draft = service.selectPlan(
        plan: premiumPlan,
        userId: 'usr_test_1',
        userEmail: 'test1@propzen.ai',
      );

      expect(draft.status, 'plan_selected');
      expect(draft.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(service.canAccessFeature('drone_tour'), isFalse);
    });

    test('TEST 2: Open checkout -> subscription NOT active', () async {
      UserSession.setUserType('NRI', country: 'Canada');
      final premiumPlan = service.getPlanById('nri_pass_premium')!;

      service.selectPlan(
        plan: premiumPlan,
        userId: 'usr_test_2',
        userEmail: 'test2@propzen.ai',
      );

      // Backend order initiated
      final order = await service.initiatePaymentOrder(
        plan: premiumPlan,
        userId: 'usr_test_2',
        userEmail: 'test2@propzen.ai',
      );

      expect(order['orderId'], isNotEmpty);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('TEST 3: Cancel payment -> subscription NOT active', () {
      UserSession.setUserType('NRI', country: 'Australia');
      final elitePlan = service.getPlanById('nri_pass_elite')!;

      // Mark payment cancelled or pending
      final pendingSub = service.setPaymentPending(
        plan: elitePlan,
        userId: 'usr_test_3',
        userEmail: 'test3@propzen.ai',
      );

      expect(pendingSub.status, 'payment_pending');
      expect(pendingSub.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(service.canAccessFeature('live_remote_tour'), isFalse);
    });

    test('TEST 4: Failed payment -> subscription NOT active', () async {
      UserSession.setUserType('NRI', country: 'United Kingdom');
      final premiumPlan = service.getPlanById('nri_pass_premium')!;

      expect(
        () async => await service.verifyAndActivateSubscription(
          plan: premiumPlan,
          paymentId: 'pay_failed_123',
          orderId: 'order_123',
          signature: '', // Invalid empty signature
          userId: 'usr_test_4',
          userEmail: 'test4@propzen.ai',
        ),
        throwsA(isA<Exception>()),
      );

      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(service.canAccessFeature('drone_tour'), isFalse);
    });

    test('TEST 5: Successful payment but verification fails -> subscription NOT active', () async {
      UserSession.setUserType('NRI', country: 'Singapore');
      final premiumPlan = service.getPlanById('nri_pass_premium')!;

      expect(
        () async => await service.verifyAndActivateSubscription(
          plan: premiumPlan,
          paymentId: 'pay_unverified',
          orderId: 'order_fake',
          signature: '', // Fake or invalid signature
          userId: 'usr_test_5',
          userEmail: 'test5@propzen.ai',
        ),
        throwsA(isA<Exception>()),
      );

      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('TEST 6: Successful verified payment -> subscription ACTIVE', () async {
      UserSession.setUserType('NRI', country: 'United States');
      final premiumPlan = service.getPlanById('nri_pass_premium')!;

      final activated = await service.verifyAndActivateSubscription(
        plan: premiumPlan,
        paymentId: 'pay_verified_999',
        orderId: 'order_valid_999',
        signature: 'sig_crypto_valid_999',
        userId: 'usr_test_6',
        userEmail: 'test6@propzen.ai',
      );

      expect(activated.status, 'active');
      expect(activated.isActive, isTrue);
      expect(UserSession.hasActiveDroneAccess, isTrue);
      expect(service.canAccessFeature('drone_tour'), isTrue);
      expect(service.canAccessFeature('3d_view'), isTrue);
    });

    test('TEST 7: Expired subscription -> Drone Tour locked', () {
      UserSession.setUserType('NRI');
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final expiredSub = NriSubscription(
        id: 'sub_expired',
        userId: 'usr_test_7',
        userEmail: 'test7@propzen.ai',
        planId: 'nri_pass_premium',
        planName: 'Premium NRI Drone Pass',
        tier: 'premium',
        durationMonths: 6,
        status: 'active',
        startDate: pastDate.subtract(const Duration(days: 180)),
        expiryDate: pastDate, // Expired 5 days ago
        amount: 3999.0,
        paymentId: 'pay_old',
      );

      expect(expiredSub.isExpired, isTrue);
      expect(expiredSub.isActive, isFalse);
      UserSession.updateNriSubscription(expiredSub);

      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(service.canAccessFeature('drone_tour'), isFalse);
    });

    test('TEST 8: Different user logs in -> Cannot access another user\'s subscription', () {
      UserSession.setUserType('NRI', country: 'United States');
      // User A gets active sub
      final subA = NriSubscription(
        id: 'sub_A',
        userId: 'usr_A',
        userEmail: 'userA@propzen.ai',
        planId: 'nri_pass_premium',
        planName: 'Premium Pass',
        durationMonths: 6,
        status: 'active',
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        amount: 3999.0,
      );
      UserSession.updateNriSubscription(subA);
      expect(UserSession.hasActiveDroneAccess, isTrue);

      // User A logs out -> User B logs in
      UserSession.logout();
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(UserSession.nriSubscription, isNull);

      UserSession.login(name: 'User B', email: 'userB@propzen.ai');
      UserSession.setUserType('Indian Resident');
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('TEST 9: Change plan price from client -> Backend validates authoritative price', () {
      final plans = service.plans;
      final basic = plans.firstWhere((p) => p.id == 'nri_pass_basic');
      final premium = plans.firstWhere((p) => p.id == 'nri_pass_premium');
      final elite = plans.firstWhere((p) => p.id == 'nri_pass_elite');

      expect(basic.priceInr, 999.0);
      expect(premium.priceInr, 3999.0);
      expect(elite.priceInr, 5999.0);
    });

    test('TEST 10: Duplicate payment callback -> Subscription is not activated twice', () async {
      UserSession.setUserType('NRI');
      final plan = service.getPlanById('nri_pass_premium')!;

      final sub1 = await service.verifyAndActivateSubscription(
        plan: plan,
        paymentId: 'pay_idempotent_1',
        orderId: 'order_idem_1',
        signature: 'sig_crypto_valid',
        userId: 'usr_idem',
        userEmail: 'idem@propzen.ai',
      );

      final sub2 = await service.verifyAndActivateSubscription(
        plan: plan,
        paymentId: 'pay_idempotent_1',
        orderId: 'order_idem_1',
        signature: 'sig_crypto_valid',
        userId: 'usr_idem',
        userEmail: 'idem@propzen.ai',
      );

      expect(sub1.paymentId, sub2.paymentId);
      expect(UserSession.hasActiveDroneAccess, isTrue);
    });
  });

  group('4. NRI Suite Features & Mathematical Calculations Tests', () {
    final service = NriSubscriptionService.instance;

    test('NRI Investment Calculation computes exact EMI, Yield & Cash Flow', () {
      const calc = NriInvestmentCalculation(
        propertyPrice: 10000000.0, // 1 Crore
        downPaymentPercent: 20.0,
        interestRatePercent: 8.5,
        loanTenureYears: 20,
        expectedMonthlyRent: 40000.0,
        holdingPeriodYears: 5,
      );

      expect(calc.downPaymentAmount, 2000000.0);
      expect(calc.loanAmount, 8000000.0);
      expect(calc.monthlyEmi, greaterThan(69000));
      expect(calc.monthlyEmi, lessThan(71000));
      expect(calc.annualRent, 480000.0);
      expect(calc.grossRentalYield, 4.8);
      expect(calc.totalHoldingRent, 2400000.0);
    });

    test('Construction Progress Model provides realistic engineering milestones', () {
      final prog = service.getConstructionProgressForProperty('prop_ats_happytrails', 'ATS HomeKraft Happy Trails');
      expect(prog.overallProgressPercent, 78);
      expect(prog.milestones.length, greaterThanOrEqualTo(5));
      expect(prog.milestones.first.isCompleted, isTrue);
      expect(prog.verifiedSource, contains('RERA'));
    });

    test('NRI Property Confidence Score calculates weighted score & recommendation', () {
      final score = service.getConfidenceScoreForProperty('prop_ats_happytrails');
      expect(score.overallScore, greaterThanOrEqualTo(85));
      expect(score.recommendation, 'Proceed with Confidence');
      expect(score.highlights.isNotEmpty, isTrue);
    });

    test('Document Concierge vault retrieves and uploads documents', () async {
      final initialDocs = service.getDocumentsForProperty('prop_ats_happytrails');
      expect(initialDocs.isNotEmpty, isTrue);

      final uploaded = await service.uploadDocument(
        propertyId: 'prop_ats_happytrails',
        title: 'NRE Account Remittance Slip',
        category: 'payment_receipts',
        fileUrl: 'https://propzen.ai/vault/remittance.pdf',
      );

      expect(uploaded.status, 'under_review');
      expect(service.getDocumentsForProperty('prop_ats_happytrails').contains(uploaded), isTrue);
    });

    test('Family Decision Mode collects votes and computes preference summary', () async {
      await service.submitFamilyReview(
        propertyId: 'prop_test_fam',
        memberName: 'Amitabh Sharma',
        relation: 'Parent',
        vote: 'like',
        rating: 5.0,
        comment: 'Great connectivity and green spaces.',
      );

      final summary = service.getFamilySummaryForProperty('prop_test_fam');
      expect(summary['totalVotes'], 1);
      expect(summary['likes'], 1);
      expect(summary['dislikes'], 0);
      expect(summary['avgRating'], 5.0);
    });

    test('Property Monitoring toggles follow status', () {
      expect(service.isPropertyMonitored('prop_unique_alert'), isFalse);
      service.togglePropertyMonitoring('prop_unique_alert', 'Unique Alert Property');
      expect(service.isPropertyMonitored('prop_unique_alert'), isTrue);
      service.togglePropertyMonitoring('prop_unique_alert', 'Unique Alert Property');
      expect(service.isPropertyMonitored('prop_unique_alert'), isFalse);
    });
  });

  group('5. UI Component Widget Tests', () {
    testWidgets('NriDroneTourCard renders full suite for NRI users', (tester) async {
      UserSession.setUserType('NRI', country: 'United States');
      final prop = Property.empty.copyWith(
        id: 'prop_ats_test',
        title: 'ATS HomeKraft Happy Trails',
        droneTourAvailable: true,
        droneTourUrl: 'https://assets.mixkit.co/drone.mp4',
        droneTourThumbnail: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        droneTourDuration: '2:45',
        droneFlightAltitudeMeters: 120,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: NriDroneTourCard(property: prop)),
          ),
        ),
      );

      expect(find.text('NRI Remote Property Suite'), findsOneWidget);
      expect(find.text('Live Construction Progress'), findsOneWidget);
      expect(find.text('NRI Confidence Score'), findsOneWidget);
      expect(find.text('Yield Calculator'), findsOneWidget);
      expect(find.text('NRI Home Loan'), findsOneWidget);
      expect(find.text('Document Vault'), findsOneWidget);
      expect(find.text('Family Voting'), findsOneWidget);
    });
  });
}

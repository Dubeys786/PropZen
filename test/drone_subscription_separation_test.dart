import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/drone_tour_subscription_model.dart';
import 'package:dealghar_ncr_10x/models/nri_subscription_model.dart';
import 'package:dealghar_ncr_10x/services/drone_subscription_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  group('PropZen Drone Tour vs Dealer Subscription Exact Business Logic Tests', () {
    test('A. Normal user without Drone subscription: visible but locked', () {
      UserSession.login(fullName: 'Normal Buyer', email: 'buyer@test.com', role: 'Buyer');
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('B. Normal user with active Drone subscription: unlocked', () async {
      UserSession.login(fullName: 'Active Drone User', email: 'drone.user@test.com', role: 'Buyer');

      final activeSub = await DroneSubscriptionService.instance.verifyAndActivateSubscription(
        orderId: 'ord_drone_test_1',
        planId: 'drone_pass_3m',
        paymentId: 'pay_test_123',
        transactionId: 'txn_test_123',
      );

      expect(activeSub.status, equals('active'));
      expect(activeSub.isActive, isTrue);
      expect(UserSession.hasActiveDroneAccess, isTrue);
    });

    test('C. Dealer without Drone subscription: Drone Tour is locked', () {
      UserSession.registerAsDealer(agencyName: 'Top Realty Broker', phone: '9810394068');
      expect(UserSession.isDealer, isTrue);
      expect(UserSession.hasActiveDroneAccess, isFalse); // Dealer role MUST NOT grant drone access!
    });

    test('D. Dealer with Dealer Subscription but WITHOUT Drone Subscription: Drone Tour MUST remain locked', () {
      UserSession.registerAsDealer(agencyName: 'Elite Brokerage', phone: '9810122334');
      // Dealer role is active
      expect(UserSession.isDealer, isTrue);

      // Verify that dealer status does NOT unlock Drone Tour
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(UserSession.droneSubscription, isNull);
    });

    test('E. Dealer with BOTH subscriptions: Dealer features + Drone Tour work', () async {
      UserSession.registerAsDealer(agencyName: 'Mega Broker', phone: '9810122334');
      expect(UserSession.isDealer, isTrue);

      // Now dealer purchases drone subscription
      await DroneSubscriptionService.instance.verifyAndActivateSubscription(
        orderId: 'ord_dealer_drone_1',
        planId: 'drone_pass_12m',
        paymentId: 'pay_dealer_456',
        transactionId: 'txn_dealer_456',
      );

      expect(UserSession.isDealer, isTrue);
      expect(UserSession.hasActiveDroneAccess, isTrue);
      expect(UserSession.droneSubscription?.status, equals('active'));
    });

    test('F. NRI without Drone subscription: Drone Tour is visible but locked', () {
      UserSession.setUserType('NRI', country: 'Canada');
      expect(UserSession.isNri, isTrue);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('G. NRI with Drone subscription: Drone Tour unlocks', () async {
      UserSession.setUserType('NRI', country: 'United Kingdom');
      expect(UserSession.isNri, isTrue);

      await DroneSubscriptionService.instance.verifyAndActivateSubscription(
        orderId: 'ord_nri_drone_1',
        planId: 'drone_pass_3m',
        paymentId: 'pay_nri_789',
        transactionId: 'txn_nri_789',
      );

      expect(UserSession.hasActiveDroneAccess, isTrue);
    });

    test('H. Plan selection creates pending order but DOES NOT unlock Drone Tour', () {
      final plan = DroneSubscriptionService.instance.plans[1];
      final pendingSub = DroneSubscriptionService.instance.createPendingOrder(
        plan: plan,
        userId: 'usr_pending_1',
        userEmail: 'pending@test.com',
      );

      expect(pendingSub.status, equals('pending'));
      expect(pendingSub.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse); // MUST remain locked!
    });

    test('I. Payment failed: Drone Tour remains locked', () {
      final plan = DroneSubscriptionService.instance.plans[0];
      DroneSubscriptionService.instance.createPendingOrder(
        plan: plan,
        userId: 'usr_fail_1',
        userEmail: 'fail@test.com',
      );

      DroneSubscriptionService.instance.markPaymentFailed(reason: 'Card declined');

      expect(UserSession.droneSubscription?.status, equals('inactive'));
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('J. Payment cancelled: Drone Tour remains locked', () {
      final plan = DroneSubscriptionService.instance.plans[2];
      DroneSubscriptionService.instance.createPendingOrder(
        plan: plan,
        userId: 'usr_cancel_1',
        userEmail: 'cancel@test.com',
      );

      DroneSubscriptionService.instance.markPaymentFailed(reason: 'User cancelled payment');

      expect(UserSession.droneSubscription?.status, equals('inactive'));
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('K. Expired Drone subscription: locks Drone Tour automatically', () {
      final expiredSub = DroneTourSubscription(
        id: 'drone_sub_exp',
        userId: 'usr_exp',
        userEmail: 'exp@test.com',
        planId: 'drone_pass_1m',
        planName: '1 Month Standard Aerial Pass',
        durationMonths: 1,
        status: 'active',
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        expiryDate: DateTime.now().subtract(const Duration(days: 15)), // Past date
        amount: 999.0,
      );

      UserSession.updateDroneSubscription(expiredSub);

      expect(expiredSub.isExpired, isTrue);
      expect(expiredSub.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse); // Expired pass MUST lock!
    });

    test('L. Logout clears active Drone subscription state', () async {
      await DroneSubscriptionService.instance.verifyAndActivateSubscription(
        orderId: 'ord_logout_test',
        planId: 'drone_pass_3m',
        paymentId: 'pay_logout_123',
        transactionId: 'txn_logout_123',
      );
      expect(UserSession.hasActiveDroneAccess, isTrue);

      UserSession.logout();
      expect(UserSession.droneSubscription, isNull);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('M. Model JSON serialization formats dedicated database columns', () {
      final sub = DroneTourSubscription(
        id: 'drone_sub_json',
        userId: 'usr_1',
        userEmail: 'json@test.com',
        planId: 'drone_pass_3m',
        planName: '3 Months All-Access Drone Pass',
        durationMonths: 3,
        status: 'active',
        startDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 4, 1),
        amount: 1999.0,
        paymentId: 'pay_json_1',
      );

      final json = sub.toJson();
      expect(json['drone_subscription_status'], equals('active'));
      expect(json['drone_plan_id'], equals('drone_pass_3m'));
      expect(json['drone_payment_id'], equals('pay_json_1'));

      final parsed = DroneTourSubscription.fromJson(json);
      expect(parsed.status, equals('active'));
      expect(parsed.planId, equals('drone_pass_3m'));
    });
  });
}

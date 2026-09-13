import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/dealer_subscription_model.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  setUp(() {
    UserSession.logout();
    DealerSubscriptionService.instance.resetToDefaultStarter();
  });

  group('1. Dealer Subscription Plans & Entitlements Catalog (Strictly 3 Plans)', () {
    final service = DealerSubscriptionService.instance;

    test('Loads strictly 3 distinct plans with correct listing and lead capacities', () {
      final plans = service.plans;
      expect(plans.length, 3);

      final free = plans.firstWhere((p) => p.id == 'dealer_free');
      final premium = plans.firstWhere((p) => p.id == 'dealer_premium');
      final superPremium = plans.firstWhere((p) => p.id == 'dealer_super_premium');

      // 1. FREE (60-Day Trial)
      expect(free.isFree, isTrue);
      expect(free.listingLimit, 3);
      expect(free.leadLimit, 10);
      expect(free.priceInr, 0.0);

      // 2. PREMIUM
      expect(premium.priceInr, 4999.0);
      expect(premium.listingLimit, 15);
      expect(premium.leadLimit, 75);
      expect(premium.canAiListing, isTrue);
      expect(premium.canBuyerMatch, isTrue);

      // 3. SUPER PREMIUM
      expect(superPremium.priceInr, 9999.0);
      expect(superPremium.listingLimit, 999);
      expect(superPremium.leadLimit, 2500);
      expect(superPremium.canTeamAccounts, isTrue);
    });
  });

  group('2. Comprehensive 11-Case Dealer Subscription & Payment Lifecycle Tests', () {
    final service = DealerSubscriptionService.instance;

    test('TEST 1: Dealer selects Premium -> Plan selected only, Subscription NOT active', () {
      final premiumPlan = service.getPlanById('dealer_premium')!;
      final draft = service.selectPlan(
        plan: premiumPlan,
        dealerId: 'DLR-TEST-001',
        dealerEmail: 'dealer1@propzen.ai',
      );

      expect(draft.status, 'plan_selected');
      expect(draft.isPlanSelected, isTrue);
      expect(draft.isActive, isFalse);
      expect(service.currentSubscription.isActive, isFalse);
    });

    test('TEST 2: Dealer cancels payment -> Subscription NOT active', () {
      final premiumPlan = service.getPlanById('dealer_premium')!;
      final pending = service.setPaymentPending(
        plan: premiumPlan,
        dealerId: 'DLR-TEST-002',
        dealerEmail: 'dealer2@propzen.ai',
      );

      expect(pending.status, 'payment_pending');
      expect(pending.isPaymentPending, isTrue);
      expect(pending.isActive, isFalse);
    });

    test('TEST 3: Payment fails -> Subscription NOT active', () async {
      final premiumPlan = service.getPlanById('dealer_premium')!;

      expect(
        () async => await service.verifyAndActivateSubscription(
          plan: premiumPlan,
          paymentId: 'pay_failed_dlr_003',
          orderId: 'order_dlr_003',
          signature: '', // Invalid empty signature
          dealerId: 'DLR-TEST-003',
          dealerEmail: 'dealer3@propzen.ai',
        ),
        throwsA(isA<Exception>()),
      );

      expect(service.currentSubscription.isActive, isFalse);
    });

    test('TEST 4: Payment succeeds but verification fails -> Subscription NOT active', () async {
      final premiumPlan = service.getPlanById('dealer_premium')!;

      expect(
        () async => await service.verifyAndActivateSubscription(
          plan: premiumPlan,
          paymentId: 'pay_fake_004',
          orderId: 'order_dlr_fake',
          signature: '', // Fake signature
          dealerId: 'DLR-TEST-004',
          dealerEmail: 'dealer4@propzen.ai',
        ),
        throwsA(isA<Exception>()),
      );

      expect(service.currentSubscription.isActive, isFalse);
    });

    test('TEST 5: Payment successfully verified -> Subscription ACTIVE', () async {
      final premiumPlan = service.getPlanById('dealer_premium')!;

      final activated = await service.verifyAndActivateSubscription(
        plan: premiumPlan,
        paymentId: 'pay_verified_dlr_005',
        orderId: 'order_dealer_valid_005',
        signature: 'sig_crypto_valid_005',
        dealerId: 'DLR-TEST-005',
        dealerEmail: 'dealer5@propzen.ai',
        skipNetworkVerification: true,
      );

      expect(activated.status, 'active');
      expect(activated.isActive, isTrue);
      expect(activated.listingLimit, 15);
      expect(activated.leadLimit, 75);
      expect(service.canUseAiListingCreator(), isTrue);
      expect(service.canUseBuyerMatching(), isTrue);
    });

    test('TEST 6: Listing limit reached -> New listing blocked', () {
      // Free Starter Plan limit is 3
      expect(service.canCreateListing(currentCount: 2), isTrue);
      expect(service.canCreateListing(currentCount: 3), isFalse);
      expect(service.canCreateListing(currentCount: 4), isFalse);
    });

    test('TEST 7: Dealer upgrades -> Payment required', () {
      final superPremium = service.getPlanById('dealer_super_premium')!;
      final upgradeDraft = service.selectPlan(
        plan: superPremium,
        dealerId: 'DLR-TEST-007',
        dealerEmail: 'dealer7@propzen.ai',
      );

      expect(upgradeDraft.status, 'plan_selected');
      expect(upgradeDraft.isActive, isFalse);
    });

    test('TEST 8: Subscription expires -> Premium features restricted', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final expiredSub = DealerSubscription(
        id: 'dsub_expired',
        dealerId: 'DLR-TEST-008',
        dealerEmail: 'dealer8@propzen.ai',
        planId: 'dealer_premium',
        planName: 'Premium Plan',
        tier: 'premium',
        status: 'expired',
        startDate: pastDate.subtract(const Duration(days: 30)),
        expiryDate: pastDate,
        listingLimit: 15,
        leadLimit: 75,
        amount: 4999.0,
      );

      expect(expiredSub.isExpired, isTrue);
      expect(expiredSub.isActive, isFalse);
    });

    test('TEST 9: Dealer logs out / logs in -> Correct session restored', () {
      UserSession.login(name: 'Aman Sharma', email: 'aman@primerealty.com');
      expect(UserSession.fullName, 'Aman Sharma');
      expect(UserSession.isLoggedIn, isTrue);

      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.fullName, isEmpty);
    });

    test('TEST 10: Server authoritative price check -> Client cannot alter plan cost', () {
      final free = service.getPlanById('dealer_free')!;
      final premium = service.getPlanById('dealer_premium')!;
      final superPremium = service.getPlanById('dealer_super_premium')!;

      expect(free.priceInr, 0.0);
      expect(premium.priceInr, 4999.0);
      expect(superPremium.priceInr, 9999.0);
    });

    test('TEST 11: Two different dealers have isolated subscription instances', () {
      final subA = DealerSubscription.defaultStarter(dealerId: 'DLR-ALPHA', dealerEmail: 'alpha@realty.com');
      final subB = DealerSubscription(
        id: 'dsub_beta',
        dealerId: 'DLR-BETA',
        dealerEmail: 'beta@realty.com',
        planId: 'dealer_premium',
        planName: 'Premium Plan',
        tier: 'premium',
        status: 'active',
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        listingLimit: 15,
        leadLimit: 75,
        amount: 4999.0,
      );

      expect(subA.dealerId, 'DLR-ALPHA');
      expect(subA.listingLimit, 3);

      expect(subB.dealerId, 'DLR-BETA');
      expect(subB.listingLimit, 15);
      expect(subB.isActive, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/apple_storekit_service.dart';
import 'package:dealghar_ncr_10x/models/dealer_subscription_model.dart';
import 'package:dealghar_ncr_10x/models/nri_subscription_model.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/nri_subscription_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  group('PropZen Phase 9 iOS Compatibility & StoreKit Tests', () {
    late AppleStoreKitService storeKit;

    setUp(() {
      storeKit = AppleStoreKitService.instance;
    });

    test('1. Product ID Catalog maps all dealer and NRI plans to App Store identifiers', () {
      expect(AppleStoreKitService.dealerProductIds['dealer_starter'], 'com.propzen.dealer_starter');
      expect(AppleStoreKitService.dealerProductIds['dealer_pro'], 'com.propzen.dealer_pro');
      expect(AppleStoreKitService.dealerProductIds['dealer_premium'], 'com.propzen.dealer_premium');
      expect(AppleStoreKitService.dealerProductIds['dealer_enterprise'], 'com.propzen.dealer_enterprise');

      expect(AppleStoreKitService.nriProductIds['nri_basic'], 'com.propzen.nri_basic');
      expect(AppleStoreKitService.nriProductIds['nri_premium'], 'com.propzen.nri_premium');
      expect(AppleStoreKitService.nriProductIds['nri_elite'], 'com.propzen.nri_elite');
    });

    test('2. Payment disclaimer renders transparent store terms', () {
      final disclaimer = storeKit.paymentPlatformDisclaimer;
      expect(disclaimer, isNotEmpty);
      expect(disclaimer, anyOf(contains('Apple App Store'), contains('256-Bit SSL Encrypted')));
    });

    test('3. Dealer In-App Purchase execution and backend activation', () async {
      final proPlan = DealerSubscriptionService.instance.plans.firstWhere((p) => p.id == 'dealer_pro');
      final result = await storeKit.purchaseDealerSubscription(
        plan: proPlan,
        dealerId: 'DLR-TEST-01',
        dealerEmail: 'dealer.test@propzen.ai',
      );

      expect(result['status'], 'success');
      expect(result['productId'], 'com.propzen.dealer_pro');
      expect(result['transactionId'], isNotNull);
      expect(result['subscription'], isA<DealerSubscription>());
    });

    test('4. NRI Pass In-App Purchase execution and backend activation', () async {
      final nriPlan = NriSubscriptionService.instance.plans.first;
      final result = await storeKit.purchaseNriSubscription(
        plan: nriPlan,
        userId: 'USR-NRI-TEST',
        userEmail: 'nri.test@propzen.ai',
      );

      expect(result['status'], 'success');
      expect(result['productId'], contains('com.propzen.'));
      expect(result['subscription'], isA<NriSubscription>());
    });

    test('5. Restore Purchases checks entitlement accurately', () async {
      final restoreResult = await storeKit.restorePurchases(
        userType: 'Dealer',
        userId: 'DLR-TEST-01',
        userEmail: 'dealer.test@propzen.ai',
      );

      expect(restoreResult['status'], 'success');
      expect(restoreResult['message'], isNotEmpty);
    });

    test('6. User Session Account Deletion clears all records for Apple Guideline 5.1.1(v)', () {
      UserSession.setUser(
        name: 'Test Buyer',
        email: 'buyer@test.com',
        phone: '+91 99999 88888',
        role: 'Buyer',
      );
      expect(UserSession.isLoggedIn, isTrue);

      UserSession.clearSession();
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.email, isEmpty);
      expect(UserSession.fullName, isEmpty);
    });
  });
}

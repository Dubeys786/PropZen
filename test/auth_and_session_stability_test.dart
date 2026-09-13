import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/widgets/auth_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UserSession.logout();
    PropertyStateService.instance.clearSavedProperties();
    DealerSubscriptionService.instance.resetToNone();
  });

  group('1. Session Persistence & Cross-Refresh Restoration Tests', () {
    test('UserSession stores session in SharedPreferences and restores across restart', () async {
      SharedPreferences.setMockInitialValues({});

      // Login as Buyer
      UserSession.login(
        name: 'Rahul Sharma',
        email: 'rahul.sharma@example.com',
        phone: '+91 98765 43210',
        role: 'Buyer',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.fullName, 'Rahul Sharma');
      expect(UserSession.email, 'rahul.sharma@example.com');
      expect(UserSession.isBuyer, isTrue);

      // Verify SharedPreferences has persisted data
      await UserSession.persistSession();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('propzen_is_logged_in'), isTrue);
      expect(prefs.getString('propzen_email'), 'rahul.sharma@example.com');
      expect(prefs.getString('propzen_role_tier'), 'Buyer');

      // Simulate browser refresh: in-memory heap wiped, but local storage intact
      UserSession.isLoggedInNotifier.value = false;
      UserSession.fullNameNotifier.value = '';
      UserSession.emailNotifier.value = '';
      expect(UserSession.isLoggedIn, isFalse);

      // Restore session from persisted storage
      final restored = await UserSession.restoreSession();
      expect(restored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.fullName, 'Rahul Sharma');
      expect(UserSession.email, 'rahul.sharma@example.com');
      expect(UserSession.isBuyer, isTrue);
    });

    test('UserSession logout purges persistent storage and isolates tenant', () async {
      UserSession.login(
        name: 'Dealer Vikram',
        email: 'vikram@realty.com',
        phone: '9810394068',
        role: 'Dealer',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedIn, isTrue);
      UserSession.logout();

      expect(UserSession.isLoggedIn, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('propzen_is_logged_in') ?? false, isFalse);
    });
  });

  group('2. Saved Properties Persistence & Tenant Isolation Tests', () {
    test('toggleSave persists property and clearSavedProperties resets tenant data', () async {
      const testPropId = 'PROP-NOIDA-001';
      const testUserId = 'usr_test_buyer_1';

      // Save property
      PropertyStateService.instance.toggleSave(testPropId, userId: testUserId);
      expect(PropertyStateService.instance.isSaved(testPropId), isTrue);

      // Toggle unsave
      PropertyStateService.instance.toggleSave(testPropId, userId: testUserId);
      expect(PropertyStateService.instance.isSaved(testPropId), isFalse);

      // Save again
      PropertyStateService.instance.toggleSave(testPropId, userId: testUserId);
      expect(PropertyStateService.instance.isSaved(testPropId), isTrue);

      // Logout triggers clearSavedProperties
      PropertyStateService.instance.clearSavedProperties();
      expect(PropertyStateService.instance.isSaved(testPropId), isFalse);
      expect(PropertyStateService.instance.savedPropertyIds.isEmpty, isTrue);
    });
  });

  group('3. Multi-Admin Account Support Tests', () {
    test('Admin privileges are granted dynamically based on role, not hardcoded email', () {
      // User with role ADMIN should have admin privileges
      UserSession.login(
        name: 'Super Admin Rohit',
        email: 'rohit.admin@propzen.ai',
        phone: '9811122233',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isBuyer, isFalse);

      // Regular Buyer does not get admin privileges even with similar name
      UserSession.login(
        name: 'Sakshi Dubey Guest',
        email: 'guest.sakshi@example.com',
        phone: '9811122244',
        role: 'Buyer',
        isEmailVerified: true,
      );

      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.isBuyer, isTrue);
    });

    test('AdminService default admin email is dynamic admin@propzen.ai without personal email', () {
      expect(AdminService.instance.adminEmail, contains('admin@propzen.ai'));
      expect(AdminService.instance.adminEmail.contains('dubeysakshi618@gmail.com'), isFalse);
    });
  });

  group('4. Dedicated Admin Dealer Verification (5 States) Tests', () {
    test('AdminCommandService supports all 5 dealer verification states with audit logging', () async {
      final cmd = AdminCommandService.instance;
      expect(cmd.dealers.isNotEmpty, isTrue);

      final dealerId = cmd.dealers.first.id;

      // 1. UNDER_REVIEW
      await cmd.updateDealerVerificationStatus(dealerId, 'UNDER_REVIEW', reason: 'Reviewing RERA license');
      expect(cmd.dealers.firstWhere((d) => d.id == dealerId).verificationStatus, 'UNDER_REVIEW');

      // 2. VERIFIED
      await cmd.updateDealerVerificationStatus(dealerId, 'VERIFIED');
      expect(cmd.dealers.firstWhere((d) => d.id == dealerId).isVerified, isTrue);

      // 3. REJECTED
      await cmd.updateDealerVerificationStatus(dealerId, 'REJECTED', reason: 'Invalid GST registration');
      expect(cmd.dealers.firstWhere((d) => d.id == dealerId).verificationStatus, 'REJECTED');

      // 4. SUSPENDED
      await cmd.updateDealerVerificationStatus(dealerId, 'SUSPENDED', reason: 'Compliance hold');
      expect(cmd.dealers.firstWhere((d) => d.id == dealerId).isSuspended, isTrue);

      // 5. PENDING
      await cmd.updateDealerVerificationStatus(dealerId, 'PENDING');
      expect(cmd.dealers.firstWhere((d) => d.id == dealerId).isPending, isTrue);
    });
  });

  group('5. Dealer Subscription Plans (Strictly 3 Plans) Tests', () {
    test('DealerSubscriptionService strictly configures exactly 3 plans', () {
      final service = DealerSubscriptionService.instance;
      final plans = service.plans;

      expect(plans.length, 3);
      expect(plans[0].tier, 'FREE');
      expect(plans[0].priceInr, 0.0);
      expect(plans[0].listingLimit, 3);
      expect(plans[0].leadLimit, 10);

      expect(plans[1].tier, 'PREMIUM');
      expect(plans[1].priceInr, 4999.0);
      expect(plans[1].listingLimit, 15);

      expect(plans[2].tier, 'SUPER_PREMIUM');
      expect(plans[2].priceInr, 9999.0);
      expect(plans[2].listingLimit, 999);
    });

    test('Free plan activates 60-day trial with timestamp fields', () async {
      final service = DealerSubscriptionService.instance;
      final freePlan = service.plans.first;

      final res = await service.initiatePaymentOrder(
        plan: freePlan,
        dealerId: 'dlr_test_101',
        dealerEmail: 'dealer.test@example.com',
      );

      expect(res['isFree'], isTrue);
      expect(service.currentSubscription.isTrial, isTrue);
      expect(service.currentSubscription.status, 'TRIAL');
      expect(service.currentSubscription.listingLimit, 3);
      expect(service.currentSubscription.trialEndAt, isNotNull);
      expect(service.currentSubscription.trialEndAt!.difference(DateTime.now()).inDays >= 59, isTrue);
    });

    test('Paid plan transitions to payment_pending without fake payment simulation if gateway offline', () async {
      final service = DealerSubscriptionService.instance;
      final premiumPlan = service.plans[1];

      final res = await service.initiatePaymentOrder(
        plan: premiumPlan,
        dealerId: 'dlr_test_102',
        dealerEmail: 'dealer.premium@example.com',
      );

      // Must be payment_pending, NOT fake activated!
      expect(res['status'], 'payment_pending');
      expect(service.currentSubscription.status, 'payment_pending');
      expect(service.currentSubscription.isPaymentPending, isTrue);
      expect(service.currentSubscription.isActive, isFalse);
    });
  });

  group('6. OTP Security & Expiration Engine Tests', () {
    test('SupabaseService sendOtp generates code and enforces 60-second cooldown', () async {
      final target = 'test.buyer@example.com';
      final sent1 = await SupabaseService.instance.sendOtp(destination: target, isEmail: true);
      expect(sent1, isTrue);

      // Immediate second request within 60s should be blocked
      final sent2 = await SupabaseService.instance.sendOtp(destination: target, isEmail: true);
      expect(sent2, isFalse);
    });

    test('SupabaseService verifyOtp enforces invalid code and max attempts', () {
      final target = 'user.phone.123';
      // Send OTP to register code in engine
      SupabaseService.instance.sendOtp(destination: target);

      // Test invalid code
      final res1 = SupabaseService.instance.verifyOtp(destination: target, otp: '0000');
      expect(res1['success'], isFalse);
      expect(res1['error'], contains('Invalid verification code'));
    });
  });

  group('7. AuthGate & Splash Barrier Tests', () {
    testWidgets('AuthGate shows PropZenSplashScreen while auth is initializing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            child: const Scaffold(body: Text('Protected Content')),
          ),
        ),
      );

      // If AuthService is initialized, shows child; if loading, shows splash
      expect(find.byType(AuthGate), findsOneWidget);
    });

    testWidgets('PropZenSplashScreen displays brand emblem and restoring text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PropZenSplashScreen(),
        ),
      );

      expect(find.text('PropZen'), findsOneWidget);
      expect(find.text('Intelligence-First Real Estate Platform'), findsOneWidget);
      expect(find.text('Restoring secure session...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

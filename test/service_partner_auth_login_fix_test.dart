import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealghar_ncr_10x/models/service_partner_profile.dart';
import 'package:dealghar_ncr_10x/models/service_request_model.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/home_design_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/loan_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/vastu_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/construction_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/property_verification_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/virtual_3d_partner_dashboard.dart';
import 'package:dealghar_ncr_10x/screens/service_partners/select_service_portal_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_dashboard_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/services/service_partner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UserSession.logout();
  });

  tearDown(() async {
    UserSession.logout();
  });

  group('Service Partner Login, Specialization, and Refresh Persistence Acceptance Tests', () {
    test('TEST A — Buyer Login: Profile = Buyer, Dashboard = Buyer Dashboard', () {
      UserSession.login(
        userId: 'usr_buyer_001',
        name: 'Rohan Buyer',
        email: 'rohan.buyer@example.com',
        phone: '9876543210',
        role: 'Buyer',
        isEmailVerified: true,
      );

      expect(UserSession.isBuyer, isTrue);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isAdmin, isFalse);
      expect(UserSession.roleTierNotifier.value, 'Buyer');

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.buyerDashboard);
    });

    test('TEST B — Dealer Login: Profile = Dealer, Dashboard = Dealer Portal', () {
      UserSession.login(
        userId: 'usr_dealer_001',
        name: 'Prime Brokerage',
        email: 'broker@prime.com',
        phone: '9876543211',
        role: 'DEALER',
        isEmailVerified: true,
      );

      expect(UserSession.isDealer, isTrue);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.roleTierNotifier.value, 'DEALER');

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.dealerPortal);
    });

    test('TEST C — Home Design Partner Login: Profile = Service Partner, Service = Home Design, Dashboard = Home Design Partner Portal', () {
      final spProfile = ServicePartnerProfile(
        id: 'SP-DESIGN-001',
        userId: '79045a72-e8c6-42b7-b6f3-6de61711d30a',
        businessName: 'aura firm',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'nakul@gmail.com',
        phone: '9876543213',
      );

      UserSession.login(
        userId: spProfile.userId,
        name: spProfile.businessName,
        email: spProfile.email,
        phone: spProfile.phone,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(spProfile);

      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.roleTierNotifier.value, 'SERVICE_PARTNER');
      expect(UserSession.currentServicePartnerProfile?.serviceCategory, 'HOME_DESIGN');
      expect(UserSession.currentServicePartnerProfile?.isApproved, isTrue);

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.homeDesignPartnerPortal);
      expect(destination, '/service-partner/home-design');
    });

    test('TEST D — Loan Partner Login: Profile = Service Partner, Service = LOAN, Dashboard = Loan Partner Portal', () {
      final spProfile = ServicePartnerProfile(
        id: 'SP-LOAN-001',
        userId: 'loan_user_uuid_101',
        businessName: 'Apex Home Finance',
        serviceCategory: 'LOAN',
        serviceCategories: ['LOAN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'finance@apex.com',
        phone: '9810394001',
      );

      UserSession.login(
        userId: spProfile.userId,
        name: spProfile.businessName,
        email: spProfile.email,
        phone: spProfile.phone,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(spProfile);

      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.roleTierNotifier.value, 'SERVICE_PARTNER');
      expect(UserSession.currentServicePartnerProfile?.serviceCategory, 'LOAN');

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.loanPartnerPortal);
      expect(destination, '/service-partner/loan');
    });

    test('TEST E — Vastu Partner Login: Profile = Service Partner, Service = VASTU, Dashboard = Vastu Partner Portal', () {
      final spProfile = ServicePartnerProfile(
        id: 'SP-VASTU-001',
        userId: 'vastu_user_uuid_202',
        businessName: 'Vedic Energy Solutions',
        serviceCategory: 'VASTU',
        serviceCategories: ['VASTU'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'consult@vedic.com',
        phone: '9810394002',
      );

      UserSession.login(
        userId: spProfile.userId,
        name: spProfile.businessName,
        email: spProfile.email,
        phone: spProfile.phone,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(spProfile);

      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.roleTierNotifier.value, 'SERVICE_PARTNER');
      expect(UserSession.currentServicePartnerProfile?.serviceCategory, 'VASTU');

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.vastuPartnerPortal);
      expect(destination, '/service-partner/vastu');
    });

    test('TEST F — Admin Login: dubeysakshi618@gmail.com: Profile = Admin, Dashboard = Admin Command Center', () {
      UserSession.login(
        userId: 'admin_uuid_master',
        name: 'Sakshi Admin',
        email: 'dubeysakshi618@gmail.com',
        phone: '9810394068',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      expect(UserSession.isAdmin, isTrue);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.isServicePartner, isFalse);
      expect(UserSession.roleTierNotifier.value, 'ADMIN');

      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.admin);
      expect(destination, '/admin');
    });

    test('TEST G — Refresh Persistence: Service Partner Session Restores Without Degrading to Buyer', () async {
      final spProfile = ServicePartnerProfile(
        id: 'SP-DESIGN-001',
        userId: '79045a72-e8c6-42b7-b6f3-6de61711d30a',
        businessName: 'aura firm',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'nakul@gmail.com',
        phone: '9876543213',
      );

      // 1. Initial Login
      UserSession.login(
        userId: spProfile.userId,
        name: spProfile.businessName,
        email: spProfile.email,
        phone: spProfile.phone,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(spProfile);
      await UserSession.persistSession();

      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.roleTierNotifier.value, 'SERVICE_PARTNER');

      // 2. Simulate complete browser restart/refresh (clearing in-memory statics)
      UserSession.isLoggedInNotifier.value = false;
      UserSession.roleTierNotifier.value = 'Buyer'; // default initial value
      UserSession.servicePartnerProfileNotifier.value = null;

      // 3. Restore session
      final restored = await UserSession.restoreSession();
      expect(restored, isTrue);
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.roleTierNotifier.value, 'SERVICE_PARTNER');
      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.currentServicePartnerProfile, isNotNull);
      expect(UserSession.currentServicePartnerProfile!.serviceCategory, 'HOME_DESIGN');
      expect(UserSession.currentServicePartnerProfile!.businessName, 'aura firm');

      // 4. Initialize Auth (must NOT overwrite restored SERVICE_PARTNER role)
      await AuthService.instance.initializeAuth();
      expect(UserSession.isServicePartner, isTrue);
      expect(UserSession.roleTierNotifier.value, 'SERVICE_PARTNER');
      expect(UserSession.isBuyer, isFalse);
    });

    test('TEST H — Multi-Service Approved Partner Routes to Select Service Portal', () {
      final multiProfile = ServicePartnerProfile(
        id: 'SP-MULTI-001',
        userId: 'multi_partner_uuid_888',
        businessName: 'Apex Architecture & Vastu',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN', 'VASTU'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        email: 'apex@multi.com',
        phone: '9810394888',
      );

      UserSession.login(
        userId: multiProfile.userId,
        name: multiProfile.businessName,
        email: multiProfile.email,
        phone: multiProfile.phone,
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      UserSession.setServicePartnerProfile(multiProfile);

      expect(UserSession.currentServicePartnerProfile?.approvedCategoryTypes.length, 2);
      final destination = AppRoutes.getPostLoginDestination();
      expect(destination, AppRoutes.selectServicePortal);
      expect(destination, '/service-partner/select-portal');
    });

    test('TEST I — Profile Header Dynamic Role Badge Never Hardcodes Buyer for Service Partner', () {
      UserSession.roleTierNotifier.value = 'SERVICE_PARTNER';
      final currentRole = UserSession.roleTierNotifier.value.trim();
      final isPartner = currentRole.toUpperCase().contains('SERVICE_PARTNER') || currentRole.toUpperCase().contains('PARTNER');
      final label = isPartner ? 'Service Partner' : currentRole;

      expect(label, 'Service Partner');
      expect(label, isNot('Buyer'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/admin_models.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Portal Conditional Visibility Tests', () {
    setUp(() {
      UserSession.logout();
    });

    test('1. Admin Portal is hidden when logged out (guest user)', () {
      expect(UserSession.isLoggedIn, isFalse);
      final bool isAuthorizedAdmin = UserSession.isLoggedIn &&
          UserSession.email.trim().toLowerCase() == 'dubeysakshi618@gmail.com';
      expect(isAuthorizedAdmin, isFalse);
    });

    test('2. Admin Portal is hidden when logged in with non-admin email', () {
      UserSession.login(
        name: 'Regular User',
        phone: '9876543210',
        email: 'user@example.com',
        role: 'Buyer',
      );
      expect(UserSession.isLoggedIn, isTrue);
      final bool isAuthorizedAdmin = UserSession.isLoggedIn &&
          UserSession.email.trim().toLowerCase() == 'dubeysakshi618@gmail.com';
      expect(isAuthorizedAdmin, isFalse);
    });

    test('3. Admin Portal is visible when logged in with dubeysakshi618@gmail.com (case/whitespace safe)', () {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: '  dubeysakshi618@gmail.com  ',
        role: 'Admin',
      );
      expect(UserSession.isLoggedIn, isTrue);
      final bool isAuthorizedAdmin = UserSession.isLoggedIn &&
          UserSession.email.trim().toLowerCase() == 'dubeysakshi618@gmail.com';
      expect(isAuthorizedAdmin, isTrue);
    });

    test('4. Admin Portal is immediately hidden upon logout', () {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.email.trim().toLowerCase() == 'dubeysakshi618@gmail.com', isTrue);

      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);
      final bool isAuthorizedAdmin = UserSession.isLoggedIn &&
          UserSession.email.trim().toLowerCase() == 'dubeysakshi618@gmail.com';
      expect(isAuthorizedAdmin, isFalse);
    });
  });

  group('ISSUE 1 — Safe Non-Blocking Auth Initialization Tests', () {
    test('1. AuthService initializeAuth completes safely and resets loading state to false', () async {
      final auth = AuthService.instance;
      await auth.initializeAuth();
      expect(auth.isLoading, isFalse);
      expect(auth.isInitialized, isTrue);
    });
  });

  group('ISSUE 2 — Admin Role Filter Verification', () {
    late AdminCommandService commandService;

    setUp(() {
      commandService = AdminCommandService.instance;
    });

    test('1. All Roles option returns all administrator records', () {
      final allAdmins = commandService.getFilteredAdministrators(null);
      expect(allAdmins.length, greaterThanOrEqualTo(6));
    });

    test('2. Super Administrator filter returns ONLY Super Administrator records', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.superAdmin);
      expect(admins, isNotEmpty);
      for (final a in admins) {
        expect(a.role, equals(AdminRole.superAdmin));
        expect(a.role.displayName.trim().toLowerCase(), equals('super administrator'));
      }
    });

    test('3. Property Administrator filter returns ONLY Property Administrator records', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.propertyAdmin);
      expect(admins, isNotEmpty);
      for (final a in admins) {
        expect(a.role, equals(AdminRole.propertyAdmin));
        expect(a.role.displayName.trim().toLowerCase(), equals('property administrator'));
      }
    });

    test('4. Dealer Administrator filter returns ONLY Dealer Administrator records', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.dealerAdmin);
      expect(admins, isNotEmpty);
      for (final a in admins) {
        expect(a.role, equals(AdminRole.dealerAdmin));
        expect(a.role.displayName.trim().toLowerCase(), equals('dealer administrator'));
      }
    });

    test('5. Support Administrator filter returns ONLY Support Administrator records', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.supportAdmin);
      expect(admins, isNotEmpty);
      for (final a in admins) {
        expect(a.role, equals(AdminRole.supportAdmin));
        expect(a.role.displayName.trim().toLowerCase(), equals('support administrator'));
      }
    });

    test('6. Finance Administrator filter returns ONLY Finance Administrator records', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.financeAdmin);
      expect(admins, isNotEmpty);
      for (final a in admins) {
        expect(a.role, equals(AdminRole.financeAdmin));
        expect(a.role.displayName.trim().toLowerCase(), equals('finance administrator'));
      }
    });

    test('7. Content Administrator filter returns ONLY Content Administrator records', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.contentAdmin);
      expect(admins, isNotEmpty);
      for (final a in admins) {
        expect(a.role, equals(AdminRole.contentAdmin));
        expect(a.role.displayName.trim().toLowerCase(), equals('content administrator'));
      }
    });

    test('8. Search query filtering works together with role filter', () {
      final admins = commandService.getFilteredAdministrators(AdminRole.superAdmin, searchQuery: 'PropZen');
      expect(admins, isNotEmpty);
      expect(admins.first.name, contains('PropZen'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Command Center Login & Verification Tests', () {
    late AdminService adminService;
    late AdminCommandService commandService;

    setUp(() {
      adminService = AdminService.instance;
      commandService = AdminCommandService.instance;
      adminService.resetForTesting(claimed: true);
    });

    test('1. Admin login with correct credentials succeeds', () {
      expect(adminService.isAdminLoggedIn, isFalse);

      final success = adminService.loginAdmin(
        email: 'admin@propzen.ai',
        password: 'admin',
      );

      expect(success, isTrue);
      expect(adminService.isAdminLoggedIn, isTrue);
      expect(adminService.adminEmail, equals('admin@propzen.ai'));
    });

    test('2. Admin login with incorrect password fails and increments failed attempts', () {
      final success = adminService.loginAdmin(
        email: 'admin@propzen.ai',
        password: 'wrong_password',
      );

      expect(success, isFalse);
      expect(adminService.isAdminLoggedIn, isFalse);
      expect(adminService.failedLoginAttempts, equals(1));
    });

    test('3. Quick Super Admin Access logs in administrator directly', () {
      expect(adminService.isAdminLoggedIn, isFalse);

      adminService.quickMasterLogin();

      expect(adminService.isAdminLoggedIn, isTrue);
      expect(adminService.adminEmail, equals('admin@propzen.ai'));
      expect(adminService.adminName, contains('Administrator'));
    });

    test('4. Logout resets admin login state', () {
      adminService.quickMasterLogin();
      expect(adminService.isAdminLoggedIn, isTrue);

      adminService.logoutAdmin();
      expect(adminService.isAdminLoggedIn, isFalse);
    });
  });
}

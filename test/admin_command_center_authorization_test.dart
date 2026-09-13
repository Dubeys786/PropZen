import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserSession.logout();
    AdminService.instance.resetForTesting(claimed: true);
    SupabaseService.instance.clearSession();
  });

  group('PropZen Admin Command Center Authorization Suite (Supabase RBAC)', () {
    test('1. Unauthenticated state returns AdminAccessStatus.unauthenticated', () {
      UserSession.logout();
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.unauthenticated));
    });

    test('2. Authenticated user with unverified email returns AdminAccessStatus.emailNotVerified', () {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: false,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.emailNotVerified));
    });

    test('3. Authenticated normal Buyer user returns AdminAccessStatus.forbidden403', () {
      UserSession.login(
        name: 'Amit Buyer',
        phone: '9876543210',
        email: 'amit.buyer@example.com',
        role: 'Buyer',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.forbidden403));
    });

    test('4. Authenticated Dealer user returns AdminAccessStatus.forbidden403', () {
      UserSession.login(
        name: 'Rajesh Broker',
        phone: '9811122233',
        email: 'rajesh@ncrproperties.com',
        role: 'Dealer',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.forbidden403));
    });

    test('5. Authenticated Builder user returns AdminAccessStatus.forbidden403', () {
      UserSession.login(
        name: 'ATS Developer',
        phone: '9811199988',
        email: 'dev@atsgreens.com',
        role: 'BUILDER',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.forbidden403));
    });

    test('6. Authenticated Admin user returns AdminAccessStatus.allowed', () {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.allowed));
      expect(AuthService.instance.isAdmin, isTrue);
      expect(UserSession.isAdmin, isTrue);
    });

    test('7. Force privilege refresh revalidates and preserves admin session', () async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: true,
      );
      final refreshed = await AuthService.instance.forceRefreshAdminPrivileges();
      expect(refreshed, isTrue);
      expect(AdminService.instance.isAdminLoggedIn, isTrue);
    });

    testWidgets('8. AdminPanelScreen renders Authentication Required when unauthenticated', (tester) async {
      UserSession.logout();
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Authentication Required'), findsOneWidget);
      expect(find.text('Sign In as Admin'), findsOneWidget);
      expect(find.text('Dashboard Overview'), findsNothing);
    });

    testWidgets('9. AdminPanelScreen renders Email Verification Required when email is unverified', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: false,
      );
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Email Verification Required'), findsOneWidget);
      expect(find.text('Refresh Status'), findsOneWidget);
      expect(find.text('Dashboard Overview'), findsNothing);
    });

    testWidgets('10. AdminPanelScreen renders Access Denied (403) for normal user / dealer / builder', (tester) async {
      UserSession.login(
        name: 'Normal User',
        phone: '9876543210',
        email: 'normal.user@gmail.com',
        role: 'USER',
        isEmailVerified: true,
      );
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Access Denied (403)'), findsOneWidget);
      expect(find.text('Switch Account'), findsOneWidget);
      expect(find.text('Return to Home Page'), findsOneWidget);
      expect(find.text('Dashboard Overview'), findsNothing);
    });

    testWidgets('11. AdminPanelScreen renders full Command Center when user is authenticated admin with verified email', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: true,
      );
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PropZen Command Center'), findsWidgets);
      expect(find.text('Dashboard Overview'), findsWidgets);
    });

    test('12. Case-insensitive and normalized role handling authorizes ADMIN, admin, and administrator', () {
      final rolesToTest = ['ADMIN', 'admin', 'Admin', 'administrator', 'super_admin'];
      for (final r in rolesToTest) {
        UserSession.login(
          name: 'Admin User',
          phone: '9810394068',
          email: 'admin.user@propzen.ai',
          role: r,
          isEmailVerified: true,
        );
        expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.allowed),
            reason: 'Role "$r" should normalize and grant admin access.');
      }
    });
  });
}

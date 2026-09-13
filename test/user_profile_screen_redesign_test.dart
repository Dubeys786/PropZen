import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  tearDown(() {
    UserSession.logout();
  });

  group('UserProfileScreen Premium Redesign Test Suite', () {
    testWidgets('1. Renders in unauthenticated state with clean luxury hero and sign-in button', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Account Settings'), findsOneWidget);

      // Check Unauthenticated Hero
      expect(find.text('Welcome to PropZen'), findsOneWidget);
      expect(find.text('Sign In / Create Account'), findsWidgets);

      // Check Go Premium CTA
      expect(find.text('Go Premium'), findsOneWidget);

      // Check Residency & Drone Tour
      expect(find.text('Residency Status'), findsOneWidget);
      expect(find.text('Drone Tour Subscription'), findsOneWidget);

      // Verify My Property Journey is hidden by default for unauthenticated guests
      expect(find.text('My Property Journey'), findsNothing);
      expect(find.text('Continuous Journey'), findsNothing);

      // Command Center should NOT be visible when unauthenticated
      expect(find.text('PropZen Command Center'), findsNothing);
    });

    testWidgets('2. Renders in authenticated admin state with Elite card, admin badge, and Command Center card', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      UserSession.login(
        name: 'PropZen Administrator',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Hero checks
      expect(find.text('PropZen Administrator'), findsOneWidget);
      expect(find.text('dubeysakshi618@gmail.com'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('PropZen Elite'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      // Admin Command Center card MUST be visible for authorized ADMIN
      expect(find.text('PropZen Command Center'), findsOneWidget);
      expect(find.text('Open Command Center →'), findsOneWidget);
      expect(find.text('SUPER ADMIN'), findsOneWidget);

      // My Property Journey MUST be hidden for ADMIN
      expect(find.text('My Property Journey'), findsNothing);
    });

    testWidgets('3. Renders across multiple responsive viewports without layout overflows', (tester) async {
      final viewports = [
        const Size(360, 780),  // Compact mobile
        const Size(414, 896),  // Standard mobile
        const Size(768, 1024), // Tablet
        const Size(1024, 768), // Small desktop / iPad landscape
        const Size(1440, 900), // Desktop
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: UserProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow occurred at $size');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('4. Residency Switcher toggles Resident and NRI state properly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Indian Resident Buyer'), findsOneWidget);
      expect(find.text('Switch to NRI'), findsOneWidget);

      // Tap Switch to NRI
      await tester.tap(find.text('Switch to NRI'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to Resident'), findsOneWidget);
      expect(find.text('Remote Journey'), findsOneWidget);
      expect(find.text('My Payments'), findsOneWidget);
    });
  });
}

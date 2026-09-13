import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/screens/deal_room_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/deal_room_service.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  group('PropZen Post-Login Routing & Default Page Tests', () {
    testWidgets('1. App initial route loads MainShell with Tab 0 (Explore Properties)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check Explore / Discovery search and property sections are visible
      expect(find.text('PropZen'), findsWidgets);
      expect(find.text('Deal Lifecycle Stage'), findsNothing); // Deal Overview must NOT be visible
    });

    testWidgets('2. Normal Buyer Post-Login navigates to Explore Properties (Tab 0)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Aarav Sharma',
        userEmail: 'aarav@example.com',
        phone: '9876543210',
        role: 'Buyer',
      );

      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(context),
              child: const Text('Simulate Post-Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Post-Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should land on MainShell with initialIndex 0 (Explore Properties)
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Deal Lifecycle Stage'), findsNothing);
    });

    testWidgets('3. Verified Dealer Post-Login navigates to Dealer Dashboard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Apex Realtors',
        userEmail: 'dealer@apex.com',
        phone: '9810394068',
        role: 'Verified Dealer',
      );

      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(context),
              child: const Text('Simulate Post-Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Post-Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Propzen Dealer Panel'), findsOneWidget);
    });

    testWidgets('4. Admin Post-Login navigates to Admin Command Center', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      UserSession.login(
        name: 'Super Admin',
        userEmail: 'admin@propzen.ai',
        phone: '9999999999',
        role: 'Super Admin',
      );

      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppRoutes.navigateToPostLoginDestination(context),
              child: const Text('Simulate Post-Login'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Simulate Post-Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.text('PropZen Command Center'), findsOneWidget);
    });

    testWidgets('5. DealRoomScreen shows "No active deals yet" empty state for new user', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      await tester.pumpWidget(
        const MaterialApp(
          home: DealRoomScreen(dealRoomId: 'NON_EXISTENT_ID'),
        ),
      );
      await tester.pump();

      expect(find.text('No active deals yet'), findsOneWidget);
      expect(find.text('Explore properties and start your property journey.'), findsOneWidget);
      expect(find.text('Explore Properties'), findsOneWidget);
      expect(find.text('Deal Lifecycle Stage'), findsNothing);
    });

    testWidgets('6. Tapping Explore Properties button in empty DealRoomScreen routes to Explore Properties', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      await tester.pumpWidget(
        const MaterialApp(
          home: DealRoomScreen(dealRoomId: ''),
        ),
      );
      await tester.pump();

      expect(find.text('No active deals yet'), findsOneWidget);
      await tester.tap(find.text('Explore Properties'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('7. DealRoomService does not contain fake seeded room by default', (tester) async {
      final rooms = DealRoomService.instance.allRooms;
      expect(rooms.isEmpty, isTrue);

      final buyerRooms = DealRoomService.instance.getRoomsForBuyer('new_user_123');
      expect(buyerRooms.isEmpty, isTrue);
    });

    testWidgets('8. User Logout clears session completely', (tester) async {
      UserSession.login(
        name: 'Jane Doe',
        userEmail: 'jane@example.com',
        phone: '9876543210',
        role: 'Buyer',
      );
      expect(UserSession.isLoggedIn, isTrue);

      UserSession.logout();
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.fullName, isEmpty);
      expect(UserSession.email, isEmpty);
      expect(UserSession.phone, isEmpty);
    });
  });
}

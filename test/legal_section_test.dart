import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/legal_hub_screen.dart';
import 'package:dealghar_ncr_10x/screens/settings_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  group('PropZen - Legal Section & Delete Account Tests', () {
    testWidgets('1. LegalHubScreen renders with policy tabs and defaults to Privacy Policy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalHubScreen(initialIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Legal & Compliance'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Refund & Cancellation Policy'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('2. Selecting a policy chip switches the displayed legal content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalHubScreen(initialIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Terms & Conditions chip
      final termsChip = find.text('Terms & Conditions');
      expect(termsChip, findsOneWidget);
      await tester.tap(termsChip);
      await tester.pumpAndSettle();

      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. Real Estate Regulatory Authority (RERA) Adherence'), findsOneWidget);

      // Tap on Refund & Cancellation Policy chip
      final refundChip = find.text('Refund & Cancellation Policy');
      expect(refundChip, findsOneWidget);
      await tester.tap(refundChip);
      await tester.pumpAndSettle();

      expect(find.text('1. 7-Day Refund Policy'), findsOneWidget);
      expect(find.text('2. Prorated Cancellations'), findsOneWidget);
    });

    testWidgets('2b. Direct initialIndex navigates straight to Grievance Officer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalHubScreen(initialIndex: 8),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1. Grievance Officer Information'), findsOneWidget);
      expect(find.textContaining('grievance@propzen.ai'), findsOneWidget);
      expect(find.textContaining('Alok Shrivastava'), findsOneWidget);
    });

    testWidgets('3. SettingsScreen displays Legal & Compliance section with all 9 policies and Delete Account', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Legal & Compliance'), findsOneWidget);
      expect(find.text('Legal & Policies Hub (All 9 Policies)'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Refund & Cancellation Policy'), findsOneWidget);
      expect(find.text('Subscription Terms'), findsOneWidget);
      expect(find.text('Property Verification Disclaimer'), findsOneWidget);
      expect(find.text('Dealer Terms & Code of Conduct'), findsOneWidget);
      expect(find.text('Drone Tour Terms'), findsOneWidget);
      expect(find.text('Service Partner Terms'), findsOneWidget);
      expect(find.text('Contact & Grievance Officer'), findsOneWidget);
      expect(find.text('Delete Account & Erase Personal Data'), findsOneWidget);
    });

    testWidgets('4. Delete Account flow requires typing "DELETE" to confirm and wipes session', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      UserSession.login(
        name: 'Test Buyer User',
        phone: '9876543210',
        email: 'testbuyer@propzen.ai',
        role: 'Buyer',
        isEmailVerified: true,
      );
      expect(UserSession.isLoggedIn, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete Account tile
      final deleteTile = find.text('Delete Account & Erase Personal Data');
      expect(deleteTile, findsOneWidget);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      // Verify Delete confirmation dialog elements
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('What will be permanently wiped:'), findsOneWidget);
      expect(find.text('Type "DELETE" below to confirm:'), findsOneWidget);

      // Attempt to submit without typing "DELETE"
      final deleteButton = find.text('Permanently Delete');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Error shown
      expect(find.text('Please type "DELETE" to confirm'), findsOneWidget);
      expect(UserSession.isLoggedIn, isTrue); // Not deleted yet

      // Enter "DELETE" in confirmation box
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'DELETE');
      await tester.pumpAndSettle();

      // Submit deletion
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify user session is wiped clean
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.fullName, isEmpty);
    });

    test('5. SupabaseService.deleteUserAccountPermanently executes successfully', () async {
      final success = await SupabaseService.instance.deleteUserAccountPermanently(
        email: 'test@example.com',
        phone: '9876543210',
        reason: 'Privacy and data concerns',
      );
      expect(success, isTrue);
    });
  });
}

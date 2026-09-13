import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/widgets/enquiry_auth_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserSession & Email Verification Tests', () {
    setUp(() {
      UserSession.logout();
    });

    test('Initial state is logged out and unverified', () {
      expect(UserSession.isLoggedInNotifier.value, isFalse);
      expect(UserSession.isEmailVerifiedNotifier.value, isFalse);
      expect(UserSession.emailNotifier.value, isEmpty);
    });

    test('User login sets user details and preserves unverified email flag', () {
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@example.com',
        phone: '9810394068',
        role: 'Verified Buyer / Owner',
        isEmailVerified: false,
      );

      expect(UserSession.isLoggedInNotifier.value, isTrue);
      expect(UserSession.fullNameNotifier.value, equals('Sakshi Sharma'));
      expect(UserSession.emailNotifier.value, equals('sakshi.sharma@example.com'));
      expect(UserSession.isEmailVerifiedNotifier.value, isFalse);
    });

    test('Calling verifyEmail updates isEmailVerifiedNotifier to true', () {
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@example.com',
        phone: '9810394068',
        role: 'Verified Buyer / Owner',
        isEmailVerified: false,
      );

      expect(UserSession.isEmailVerifiedNotifier.value, isFalse);

      UserSession.verifyEmail();

      expect(UserSession.isEmailVerifiedNotifier.value, isTrue);
    });

    test('Logging out resets isEmailVerifiedNotifier to false', () {
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@example.com',
        phone: '9810394068',
        role: 'Verified Buyer / Owner',
        isEmailVerified: true,
      );

      expect(UserSession.isEmailVerifiedNotifier.value, isTrue);

      UserSession.logout();

      expect(UserSession.isLoggedInNotifier.value, isFalse);
      expect(UserSession.isEmailVerifiedNotifier.value, isFalse);
    });

    testWidgets('EnquiryAuthDialog renders required verification components', (WidgetTester tester) async {
      bool verifiedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnquiryAuthDialog(
              actionLabel: 'site visit',
              onSuccess: () {
                verifiedCalled = true;
              },
            ),
          ),
        ),
      );

      // Verify Header & Copy
      expect(find.text('Verify to Continue'), findsWidgets);
    });
  });
}

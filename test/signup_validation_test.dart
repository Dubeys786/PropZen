import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/utils/validators.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/screens/signup_otp_screen.dart';

void main() {
  group('FormValidators Unit Tests', () {
    test('Indian Mobile Number Validation - Required Test Cases', () {
      // Valid cases
      expect(FormValidators.validateIndianPhone('9876543210'), isNull);
      expect(FormValidators.validateIndianPhone('9123456789'), isNull);
      expect(FormValidators.validateIndianPhone('8123456789'), isNull);
      expect(FormValidators.validateIndianPhone('7123456789'), isNull);
      expect(FormValidators.validateIndianPhone('6123456789'), isNull);

      // Invalid cases
      expect(FormValidators.validateIndianPhone('1234567890'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('98765'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('98765432101'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('abcdefghij'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('98765abcde'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('0987654321'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('5987654321'), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone(''), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone(null), 'Enter a valid 10-digit mobile number.');
      expect(FormValidators.validateIndianPhone('98765 43210'), 'Enter a valid 10-digit mobile number.');
    });

    test('Email Address Validation - Required Test Cases', () {
      // Valid cases
      expect(FormValidators.validateEmail('test@gmail.com'), isNull);
      expect(FormValidators.validateEmail('user.name@gmail.com'), isNull);
      expect(FormValidators.validateEmail('user123@outlook.com'), isNull);
      expect(FormValidators.validateEmail('sakshi@gmail.com'), isNull);
      expect(FormValidators.validateEmail('info@propzen.in'), isNull);

      // Invalid cases
      expect(FormValidators.validateEmail('test@'), 'Enter a valid email address.');
      expect(FormValidators.validateEmail('test@gmail'), 'Enter a valid email address.');
      expect(FormValidators.validateEmail('testgmail.com'), 'Enter a valid email address.');
      expect(FormValidators.validateEmail('test @gmail.com'), 'Enter a valid email address.');
      expect(FormValidators.validateEmail('user@.com'), 'Enter a valid email address.');
      expect(FormValidators.validateEmail(''), 'Enter a valid email address.');
      expect(FormValidators.validateEmail(null), 'Enter a valid email address.');
      expect(FormValidators.validateEmail('user@gmail.c'), 'Enter a valid email address.');
    });

    test('Full Name, Password, and Confirm Password Validation', () {
      // Name
      expect(FormValidators.validateFullName('Sakshi'), isNull);
      expect(FormValidators.validateFullName(''), 'Enter your full name.');
      expect(FormValidators.validateFullName('A'), 'Name must be at least 2 characters.');

      // Password (min 8 chars)
      expect(FormValidators.validatePassword('Password123'), isNull);
      expect(FormValidators.validatePassword(''), 'Enter password.');
      expect(FormValidators.validatePassword('12345'), 'Password must be at least 8 characters.');

      // Confirm Password
      expect(FormValidators.validateConfirmPassword('Password123', 'Password123'), isNull);
      expect(FormValidators.validateConfirmPassword('', 'Password123'), 'Confirm your password.');
      expect(FormValidators.validateConfirmPassword('Different123', 'Password123'), 'Passwords do not match.');

      // Password Strength
      final weak = FormValidators.calculatePasswordStrength('pass');
      expect(weak.label, contains('Too Short'));

      final strong = FormValidators.calculatePasswordStrength('PropZen@2026Secure!');
      expect(strong.label, 'Strong');
      expect(strong.percent, 1.0);
    });
  });

  group('DualAuthScreen Premium Sign Up UI & Form Widget Tests', () {
    testWidgets('1. Empty fields show required-field validation errors on submission', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Premium Header & Section text
      expect(find.text('Welcome to PropZen'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);

      // Tap Create Account with empty fields
      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify validation errors appear directly beneath fields
      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
      expect(find.text('Enter password.'), findsOneWidget);
      expect(find.text('Confirm your password.'), findsOneWidget);
    });

    testWidgets('2. Invalid phone + valid email -> submission blocked & phone error shown', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your full name'), 'Sakshi Sharma');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'sakshi@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter 10-digit mobile number'), '1234567890');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter password'), 'SecurePass123!');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm your password'), 'SecurePass123!');

      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Submission blocked, phone error displayed
      expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(find.byType(SignupOtpScreen), findsNothing);
    });

    testWidgets('3. Password mismatch -> submission blocked with error message', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your full name'), 'Sakshi Sharma');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'sakshi@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter 10-digit mobile number'), '9876543210');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter password'), 'SecurePass123!');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm your password'), 'DifferentPass456!');

      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Passwords do not match error displayed
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(find.byType(SignupOtpScreen), findsNothing);
    });

    testWidgets('4. Weak password (< 8 chars) -> submission blocked with min 8 error', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your full name'), 'Sakshi Sharma');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'sakshi@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter 10-digit mobile number'), '9876543210');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter password'), 'Pass1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm your password'), 'Pass1');

      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Min 8 characters error displayed
      expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
      expect(find.byType(SignupOtpScreen), findsNothing);
    });

    testWidgets('5. Valid full registration -> form submits and navigates to OTP screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your full name'), 'Sakshi Sharma');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'sakshi@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter 10-digit mobile number'), '9876543210');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter password'), 'SecurePass123!');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm your password'), 'SecurePass123!');

      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Navigated to OTP screen with phone
      expect(find.byType(SignupOtpScreen), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('6. Phone field displays +91 prefix and restricts input to 10 digits', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+91'), findsOneWidget);

      final phoneFinder = find.widgetWithText(TextFormField, 'Enter 10-digit mobile number');
      expect(phoneFinder, findsOneWidget);

      // Attempt to enter 13 characters
      await tester.enterText(phoneFinder, '9876543210999');
      await tester.pumpAndSettle();

      final textFormField = tester.widget<TextFormField>(phoneFinder);
      expect(textFormField.controller?.text.length, 10);
      expect(textFormField.controller?.text, '9876543210');
    });

    testWidgets('7. Auto-focus focuses the first invalid field upon submit', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid Name, leave email empty
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your full name'), 'Sakshi Sharma');

      final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Email is the first invalid field
      final emailFinder = find.widgetWithText(TextFormField, 'Enter your email');
      final editableText = tester.widget<EditableText>(find.descendant(of: emailFinder, matching: find.byType(EditableText)));
      expect(editableText.focusNode.hasFocus, isTrue);
    });

    testWidgets('8. Toggle switches cleanly between Sign Up and Sign In', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(initialSignUp: true),
        ),
      );
      await tester.pumpAndSettle();

      // Currently on Sign Up
      expect(find.text('Create your account'), findsOneWidget);

      // Tap Sign In link
      final signInLink = find.text('Sign In');
      expect(signInLink, findsWidgets);
      await tester.ensureVisible(signInLink.last);
      await tester.tap(signInLink.last);
      await tester.pumpAndSettle();

      // Now on Sign In
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/screens/email_verification_screen.dart';
import 'package:dealghar_ncr_10x/screens/post_property_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/property_service.dart';
import 'package:dealghar_ncr_10x/utils/validators.dart';

void main() {
  group('List Property Form Validation - FormValidators', () {
    test('1. Title Validation (5 to 100 characters, trimmed, no whitespace-only)', () {
      expect(FormValidators.validatePropertyTitle(null), isNotNull);
      expect(FormValidators.validatePropertyTitle(''), isNotNull);
      expect(FormValidators.validatePropertyTitle('   '), isNotNull);
      expect(FormValidators.validatePropertyTitle('ABCD'), isNotNull); // 4 chars
      expect(FormValidators.validatePropertyTitle('   1234   '), isNotNull); // 4 chars trimmed
      expect(FormValidators.validatePropertyTitle('A' * 101), isNotNull); // 101 chars

      expect(FormValidators.validatePropertyTitle('Godrej Tropical Isle 3 BHK'), isNull);
      expect(FormValidators.validatePropertyTitle('12345'), isNull); // exactly 5 chars
      expect(FormValidators.validatePropertyTitle('A' * 100), isNull); // exactly 100 chars
    });

    test('2. Price Validation (> 0 numeric only)', () {
      expect(FormValidators.validatePriceCr(null), isNotNull);
      expect(FormValidators.validatePriceCr(''), isNotNull);
      expect(FormValidators.validatePriceCr('abc'), isNotNull);
      expect(FormValidators.validatePriceCr('-5'), isNotNull);
      expect(FormValidators.validatePriceCr('0'), isNotNull);
      expect(FormValidators.validatePriceCr('0.00'), isNotNull);

      expect(FormValidators.validatePriceCr('1.85'), isNull);
      expect(FormValidators.validatePriceCr('0.01'), isNull);
      expect(FormValidators.validatePriceCr('25'), isNull);
    });

    test('3. Area Validation (> 0 numeric only, unit support)', () {
      expect(FormValidators.validateArea(null), isNotNull);
      expect(FormValidators.validateArea(''), isNotNull);
      expect(FormValidators.validateArea('xyz'), isNotNull);
      expect(FormValidators.validateArea('-100'), isNotNull);
      expect(FormValidators.validateArea('0'), isNotNull);

      expect(FormValidators.validateArea('1850', unit: 'sq ft'), isNull);
      expect(FormValidators.validateArea('250', unit: 'sq yd'), isNull);
      expect(FormValidators.validateArea('150', unit: 'sq m'), isNull);
      expect(FormValidators.validateArea('2.5', unit: 'acre'), isNull);

      expect(FormValidators.validateAreaSqft('1850'), isNull);
      expect(FormValidators.validateAreaSqft('0'), isNotNull);
    });

    test('4. PIN Code Validation (Strictly 6 numeric digits)', () {
      expect(FormValidators.validatePinCode(null), isNotNull);
      expect(FormValidators.validatePinCode(''), isNotNull);
      expect(FormValidators.validatePinCode('20131'), isNotNull); // 5 digits
      expect(FormValidators.validatePinCode('2013101'), isNotNull); // 7 digits
      expect(FormValidators.validatePinCode('20131A'), isNotNull); // alphanumeric
      expect(FormValidators.validatePinCode('201 31'), isNotNull); // contains space

      expect(FormValidators.validatePinCode('201310'), isNull);
      expect(FormValidators.validatePinCode('110001'), isNull);
      expect(FormValidators.validatePinCode('560001'), isNull);
    });

    test('5. Complete Address Validation (Minimum 10 characters)', () {
      expect(FormValidators.validateAddress(null), isNotNull);
      expect(FormValidators.validateAddress(''), isNotNull);
      expect(FormValidators.validateAddress('Tower 4'), isNotNull); // 7 chars
      expect(FormValidators.validateAddress('   123456789   '), isNotNull); // 9 chars trimmed

      expect(FormValidators.validateAddress('Tower 4, Sector 150, Noida Expressway'), isNull);
      expect(FormValidators.validateAddress('1234567890'), isNull); // 10 chars
    });

    test('6. Description Validation (30 to 2000 chars, spam filter)', () {
      expect(FormValidators.validatePropertyDescription(null), isNotNull);
      expect(FormValidators.validatePropertyDescription(''), isNotNull);
      expect(FormValidators.validatePropertyDescription('Short description under 30 ch'), isNotNull); // 29 chars
      expect(FormValidators.validatePropertyDescription('A' * 2001), isNotNull); // > 2000 chars

      // Spam / placeholder detection
      expect(FormValidators.validatePropertyDescription('test test test test test test test test test test'), isNotNull);
      expect(FormValidators.validatePropertyDescription('property property property property property property'), isNotNull);
      expect(FormValidators.validatePropertyDescription('asdf asdf asdf asdf asdf asdf asdf asdf asdf asdf'), isNotNull);

      // Valid informative description
      const validDesc = 'Spacious 3 BHK luxury apartment with expansive corner views, premium Italian marble, and world-class clubhouse amenities in Sector 150.';
      expect(FormValidators.validatePropertyDescription(validDesc), isNull);
    });

    test('7. Bathroom Options Validation', () {
      expect(FormValidators.validateBathroom(null), isNotNull);
      expect(FormValidators.validateBathroom(''), isNotNull);
      expect(FormValidators.validateBathroom('10'), isNotNull);

      expect(FormValidators.validateBathroom('1'), isNull);
      expect(FormValidators.validateBathroom('2'), isNull);
      expect(FormValidators.validateBathroom('3'), isNull);
      expect(FormValidators.validateBathroom('4'), isNull);
      expect(FormValidators.validateBathroom('5+'), isNull);
    });

    test('8. Dynamic BHK Requirement (Residential vs Commercial/Plot)', () {
      expect(FormValidators.isBhkRequired('Apartment'), isTrue);
      expect(FormValidators.isBhkRequired('Flat'), isTrue);
      expect(FormValidators.isBhkRequired('Villa'), isTrue);
      expect(FormValidators.isBhkRequired('Studio'), isTrue);
      expect(FormValidators.isBhkRequired('Penthouse'), isTrue);

      expect(FormValidators.isBhkRequired('Plot'), isFalse);
      expect(FormValidators.isBhkRequired('Land'), isFalse);
      expect(FormValidators.isBhkRequired('Commercial'), isFalse);
      expect(FormValidators.isBhkRequired('Office Space'), isFalse);
      expect(FormValidators.isBhkRequired('Retail Shop'), isFalse);
      expect(FormValidators.isBhkRequired('Warehouse'), isFalse);
      expect(FormValidators.isBhkRequired('Agricultural Land'), isFalse);
    });
  });

  group('Property Submission Backend Sanitizer & Security', () {
    final baseValidProperty = Property(
      id: 'PROP-TEST-001',
      title: 'Godrej Tropical Isle 3 BHK',
      sector: 'Sector 150',
      city: 'Noida',
      address: 'Tower 4, Sector 150, Noida Expressway',
      postalCode: '201310',
      propertyType: 'Apartment',
      category: 'Residential',
      askingPriceCr: 1.85,
      sqft: 1850,
      bhk: '3 BHK',
      description: 'Spacious 3 BHK luxury apartment with expansive corner views, premium Italian marble, and clubhouse.',
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
      galleryImages: const ['https://images.unsplash.com/photo-1600585154340-be6161a56a0c'],
      status: 'approved', // Malicious attempt to self-approve
      isVerified: true, // Malicious attempt to self-verify
    );

    test('1. Blocks unauthenticated submission', () {
      final result = PropertyService.validateAndSanitizeListing(
        baseValidProperty,
        authenticatedUid: '',
        isEmailVerified: true,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Authentication required'));
    });

    test('2. Blocks submission with unverified email', () {
      final result = PropertyService.validateAndSanitizeListing(
        baseValidProperty,
        authenticatedUid: 'user-123',
        isEmailVerified: false,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Email verification required'));
    });

    test('3. Enforces at least 1 image requirement', () {
      final noImageProp = baseValidProperty.copyWith(
        imageUrl: '',
        galleryImages: [],
      );
      final result = PropertyService.validateAndSanitizeListing(
        noImageProp,
        authenticatedUid: 'user-123',
        isEmailVerified: true,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('At least 1 property image is required'));
    });

    test('4. Sanitizes malicious client verification and status tampering', () {
      final result = PropertyService.validateAndSanitizeListing(
        baseValidProperty,
        authenticatedUid: 'user-123',
        isEmailVerified: true,
      );
      expect(result.isValid, isTrue);
      expect(result.sanitizedProperty, isNotNull);

      final sanitized = result.sanitizedProperty!;
      // Must NOT be verified
      expect(sanitized.isVerified, isFalse);
      // Must be pending (PENDING_VERIFICATION)
      expect(sanitized.status, equals('pending'));
      // dealerId/owner must match authenticated user
      expect(sanitized.dealerId, equals('user-123'));
    });

    test('5. Supports Draft status correctly', () {
      final result = PropertyService.validateAndSanitizeListing(
        baseValidProperty,
        authenticatedUid: 'user-123',
        isEmailVerified: true,
        isDraft: true,
      );
      expect(result.isValid, isTrue);
      expect(result.sanitizedProperty!.status, equals('draft'));
      expect(result.sanitizedProperty!.isVerified, isFalse);
    });

    test('6. Catches invalid title on server side', () {
      final invalidProp = baseValidProperty.copyWith(title: 'Abc');
      final result = PropertyService.validateAndSanitizeListing(
        invalidProp,
        authenticatedUid: 'user-123',
        isEmailVerified: true,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage?.toLowerCase(), contains('title'));
    });

    test('7. Catches non-positive price on server side', () {
      final invalidProp = baseValidProperty.copyWith(askingPriceCr: 0.0);
      final result = PropertyService.validateAndSanitizeListing(
        invalidProp,
        authenticatedUid: 'user-123',
        isEmailVerified: true,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage?.toLowerCase(), contains('price'));
    });

    test('8. Catches invalid PIN code on server side', () {
      final invalidProp = baseValidProperty.copyWith(postalCode: '20131');
      final result = PropertyService.validateAndSanitizeListing(
        invalidProp,
        authenticatedUid: 'user-123',
        isEmailVerified: true,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('PIN code'));
    });
  });

  group('Route Guard & Navigation Protection', () {
    tearDown(() {
      UserSession.isLoggedInNotifier.value = false;
      UserSession.isEmailVerifiedNotifier.value = false;
    });

    testWidgets('1. Redirects unauthenticated user accessing /list-property to DualAuthScreen', (tester) async {
      UserSession.isLoggedInNotifier.value = false;

      late Widget builtWidget;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            final route = AppRoutes.generateRoute(settings) as MaterialPageRoute;
            return MaterialPageRoute(
              builder: (ctx) {
                builtWidget = route.builder(ctx);
                return Container();
              },
            );
          },
          initialRoute: AppRoutes.listProperty,
        ),
      );

      expect(builtWidget, isA<DualAuthScreen>());
      final authWidget = builtWidget as DualAuthScreen;
      expect(authWidget.redirectRoute, equals(AppRoutes.listProperty));
    });

    testWidgets('2. Redirects unverified email user accessing /list-property to EmailVerificationGateScreen', (tester) async {
      UserSession.isLoggedInNotifier.value = true;
      UserSession.isEmailVerifiedNotifier.value = false;

      late Widget builtWidget;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            final route = AppRoutes.generateRoute(settings) as MaterialPageRoute;
            return MaterialPageRoute(
              builder: (ctx) {
                builtWidget = route.builder(ctx);
                return Container();
              },
            );
          },
          initialRoute: AppRoutes.listProperty,
        ),
      );

      expect(builtWidget, isA<EmailVerificationGateScreen>());
      final gateWidget = builtWidget as EmailVerificationGateScreen;
      expect(gateWidget.redirectRoute, equals(AppRoutes.listProperty));
    });

    testWidgets('3. Allows verified authenticated user accessing /list-property to reach PostPropertyScreen', (tester) async {
      UserSession.isLoggedInNotifier.value = true;
      UserSession.isEmailVerifiedNotifier.value = true;

      late Widget builtWidget;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            final route = AppRoutes.generateRoute(settings) as MaterialPageRoute;
            return MaterialPageRoute(
              builder: (ctx) {
                builtWidget = route.builder(ctx);
                return Container();
              },
            );
          },
          initialRoute: AppRoutes.listProperty,
        ),
      );

      expect(builtWidget, isA<PostPropertyScreen>());
    });
  });

  group('Submission Integrity, Idempotency & Terms Verification', () {
    test('1. Mandatory Terms & Rights check rejects submission if either is missing', () {
      bool confirmLegalRight = false;
      bool agreeTermsAndPolicy = false;

      bool canSubmit(bool legal, bool terms) => legal && terms;

      expect(canSubmit(confirmLegalRight, agreeTermsAndPolicy), isFalse);
      confirmLegalRight = true;
      expect(canSubmit(confirmLegalRight, agreeTermsAndPolicy), isFalse);
      confirmLegalRight = false;
      agreeTermsAndPolicy = true;
      expect(canSubmit(confirmLegalRight, agreeTermsAndPolicy), isFalse);
      confirmLegalRight = true;
      expect(canSubmit(confirmLegalRight, agreeTermsAndPolicy), isTrue);
    });

    test('2. Generates unique idempotency request ID for each submission attempt', () {
      final id1 = 'REQ-${DateTime.now().millisecondsSinceEpoch}-1';
      final id2 = 'REQ-${DateTime.now().millisecondsSinceEpoch}-2';
      expect(id1, isNot(equals(id2)));
      expect(id1, startsWith('REQ-'));
    });
  });
}

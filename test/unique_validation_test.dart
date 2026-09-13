import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/user_uniqueness_service.dart';
import 'package:dealghar_ncr_10x/utils/validators.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  setUp(() {
    UserSession.logout();
  });

  group('PropZen Unique Email & Phone Validation Tests', () {
    test('1. New email + new phone returns available (SUCCESS)', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: 'brand.new.user.${DateTime.now().millisecondsSinceEpoch}@example.com',
        phone: '9999900001',
      );

      expect(result.isAvailable, isTrue);
      expect(result.isEmailDuplicate, isFalse);
      expect(result.isPhoneDuplicate, isFalse);
      expect(result.emailErrorMessage, isNull);
      expect(result.phoneErrorMessage, isNull);
    });

    test('2. Existing email + new phone BLOCKS registration with inline message', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: 'admin@propzen.ai',
        phone: '9999900002',
      );

      expect(result.isAvailable, isFalse);
      expect(result.isEmailDuplicate, isTrue);
      expect(result.isPhoneDuplicate, isFalse);
      expect(
        result.emailErrorMessage,
        equals('This email address is already registered. Please use a different email address.'),
      );
    });

    test('3. New email + existing phone BLOCKS registration with inline message', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: 'unique.person.${DateTime.now().millisecondsSinceEpoch}@example.com',
        phone: '9810394068',
      );

      expect(result.isAvailable, isFalse);
      expect(result.isEmailDuplicate, isFalse);
      expect(result.isPhoneDuplicate, isTrue);
      expect(
        result.phoneErrorMessage,
        equals('This phone number is already registered. Please use a different phone number.'),
      );
    });

    test('4. Existing email + existing phone BLOCKS both fields', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: 'dealer@propzen.ai',
        phone: '9810122334',
      );

      expect(result.isAvailable, isFalse);
      expect(result.isEmailDuplicate, isTrue);
      expect(result.isPhoneDuplicate, isTrue);
      expect(result.emailErrorMessage, isNotNull);
      expect(result.phoneErrorMessage, isNotNull);
    });

    test('5. Email normalization: Uppercase / lowercase treated as identical', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: 'Admin@PropZen.AI',
        phone: '9999900003',
      );

      expect(result.isAvailable, isFalse);
      expect(result.isEmailDuplicate, isTrue);
    });

    test('6. Email normalization: Leading and trailing spaces trimmed', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: '   dealer@propzen.ai   ',
        phone: '9999900004',
      );

      expect(result.isAvailable, isFalse);
      expect(result.isEmailDuplicate, isTrue);
    });

    test('7. Phone normalization: Formatted Indian numbers (+91 XXXXX XXXXX) match standard digits', () async {
      final result = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: 'some.new.buyer.${DateTime.now().millisecondsSinceEpoch}@example.com',
        phone: '+91 98101 22334',
      );

      expect(result.isAvailable, isFalse);
      expect(result.isPhoneDuplicate, isTrue);
    });

    test('8. Form validator flags empty email', () {
      final err = FormValidators.validateEmail('');
      expect(err, isNotNull);
      expect(err, equals('Enter a valid email address.'));
    });

    test('9. Form validator flags invalid email format', () {
      final err1 = FormValidators.validateEmail('notanemail');
      final err2 = FormValidators.validateEmail('user@com');
      final err3 = FormValidators.validateEmail('user @gmail.com');

      expect(err1, isNotNull);
      expect(err2, isNotNull);
      expect(err3, isNotNull);
    });

    test('10. Form validator flags invalid phone length and starting digit', () {
      final errShort = FormValidators.validateIndianPhone('12345');
      final errInvalidStart = FormValidators.validateIndianPhone('5555555555');
      final errValid = FormValidators.validateIndianPhone('9810122334');

      expect(errShort, isNotNull);
      expect(errInvalidStart, isNotNull);
      expect(errValid, isNull);
    });

    test('11. Register identity updates local cache for subsequent uniqueness checks', () async {
      final uniqueEmail = 'new.registered.${DateTime.now().millisecondsSinceEpoch}@propzen.ai';
      final uniquePhone = '9999988888';

      // First check: should be available
      final initialCheck = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: uniqueEmail,
        phone: uniquePhone,
      );
      expect(initialCheck.isAvailable, isTrue);

      // Register identity
      UserUniquenessService.instance.registerIdentity(email: uniqueEmail, phone: uniquePhone);

      // Second check: must now be BLOCKED
      final secondCheck = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: uniqueEmail,
        phone: uniquePhone,
      );
      expect(secondCheck.isAvailable, isFalse);
      expect(secondCheck.isEmailDuplicate, isTrue);
      expect(secondCheck.isPhoneDuplicate, isTrue);
    });

    test('12. Normalization helpers correctly extract digits and lowercase', () {
      expect(UserUniquenessService.normalizeEmail('  MyUser@Domain.COM  '), equals('myuser@domain.com'));
      expect(UserUniquenessService.normalizePhoneDigits('+91 98101-22334'), equals('9810122334'));
      expect(UserUniquenessService.normalizePhoneDigits('09810122334'), equals('9810122334'));
      expect(UserUniquenessService.normalizePhoneDigits('919810122334'), equals('9810122334'));
    });
  });
}

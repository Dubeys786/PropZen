import 'dart:async';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Result of User Email & Phone Uniqueness Evaluation
class UniquenessValidationResult {
  final bool isAvailable;
  final bool isEmailDuplicate;
  final bool isPhoneDuplicate;
  final String? emailErrorMessage;
  final String? phoneErrorMessage;

  const UniquenessValidationResult({
    required this.isAvailable,
    this.isEmailDuplicate = false,
    this.isPhoneDuplicate = false,
    this.emailErrorMessage,
    this.phoneErrorMessage,
  });

  static const UniquenessValidationResult available = UniquenessValidationResult(
    isAvailable: true,
  );
}

/// Central Service for Enforcing Strict Email & Phone Uniqueness
class UserUniquenessService {
  static final UserUniquenessService instance = UserUniquenessService._internal();
  factory UserUniquenessService() => instance;

  UserUniquenessService._internal() {
    _initRegisteredStore();
  }

  // Local synchronized in-memory registry of registered identities
  final Set<String> _registeredEmails = {};
  final Set<String> _registeredPhoneDigits = {};

  void _initRegisteredStore() {
    // Standard system & demo accounts
    final initialEmails = [
      'admin@propzen.ai',
      'dealer@propzen.ai',
      'rajesh.varma@ncrprimerealty.com',
      'ananya.sen@example.com',
      'arjun.singhania@dubairealty.ae',
      'vikas@corptech.com',
      'amit.goel@sec150homes.in',
      'sanjay.gupta@yamunaproperties.com',
      'rohit@noidacommercial.in',
      'kavita.roy@gmail.com',
      'sunil.sharma@yahoo.com',
    ];

    final initialPhones = [
      '9810394068',
      '9810122334',
      '9811122334',
      '9822233445',
      '9833344556',
      '9844455667',
      '501234567',
    ];

    for (final email in initialEmails) {
      _registeredEmails.add(normalizeEmail(email));
    }

    for (final phone in initialPhones) {
      _registeredPhoneDigits.add(normalizePhoneDigits(phone));
    }
  }

  /// Normalize email: trim leading/trailing whitespace and convert to lowercase
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Normalize phone: extract digits and standardize Indian 10-digit mobile numbers
  static String normalizePhoneDigits(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return digits;
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      return digits.substring(1);
    }
    return digits;
  }

  /// Register new identity in memory
  void registerIdentity({required String email, required String phone}) {
    final cleanEmail = normalizeEmail(email);
    final cleanDigits = normalizePhoneDigits(phone);

    if (cleanEmail.isNotEmpty) _registeredEmails.add(cleanEmail);
    if (cleanDigits.isNotEmpty) _registeredPhoneDigits.add(cleanDigits);
  }

  /// Check if an email is already registered locally
  bool isEmailLocallyRegistered(String email) {
    final clean = normalizeEmail(email);
    return _registeredEmails.contains(clean);
  }

  /// Check if a phone number is already registered locally
  bool isPhoneLocallyRegistered(String phone) {
    final cleanDigits = normalizePhoneDigits(phone);
    return _registeredPhoneDigits.contains(cleanDigits);
  }

  /// Complete Dual-Check for Email & Phone Availability
  Future<UniquenessValidationResult> validateCredentialsAvailability({
    required String email,
    required String phone,
  }) async {
    final cleanEmail = normalizeEmail(email);
    final cleanPhoneDigits = normalizePhoneDigits(phone);

    bool emailTaken = false;
    bool phoneTaken = false;

    // 1. Local Store Check
    if (cleanEmail.isNotEmpty && isEmailLocallyRegistered(cleanEmail)) {
      emailTaken = true;
    }
    if (cleanPhoneDigits.isNotEmpty && isPhoneLocallyRegistered(cleanPhoneDigits)) {
      phoneTaken = true;
    }

    // 2. Targeted Remote Supabase Backend Queries
    if (!emailTaken && cleanEmail.isNotEmpty) {
      emailTaken = await SupabaseService.instance.checkEmailExists(cleanEmail);
    }

    if (!phoneTaken && cleanPhoneDigits.length >= 10) {
      phoneTaken = await SupabaseService.instance.checkPhoneExists(cleanPhoneDigits);
    }

    if (emailTaken || phoneTaken) {
      return UniquenessValidationResult(
        isAvailable: false,
        isEmailDuplicate: emailTaken,
        isPhoneDuplicate: phoneTaken,
        emailErrorMessage: emailTaken
            ? 'This email address is already registered. Please use a different email address.'
            : null,
        phoneErrorMessage: phoneTaken
            ? 'This phone number is already registered. Please use a different phone number.'
            : null,
      );
    }

    return UniquenessValidationResult.available;
  }
}

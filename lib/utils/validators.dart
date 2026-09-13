import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Password strength analysis model
class PasswordStrengthResult {
  final int score; // 0 to 4
  final String label;
  final Color color;
  final double percent;

  const PasswordStrengthResult({
    required this.score,
    required this.label,
    required this.color,
    required this.percent,
  });
}

/// Centralized validation utilities for PropZen forms and authentication flows.
class FormValidators {
  // Regex for Indian mobile numbers: exactly 10 digits, starts with 6, 7, 8, or 9
  static final RegExp _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

  // RFC-compliant and domain-strict Email regex: username @ domain . tld (min 2 chars)
  // Rejects spaces, rejects incomplete domains, requires valid TLD
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z]{2,})+$",
  );

  /// Validates standard Indian mobile numbers (10 digits starting with 6, 7, 8, or 9)
  static String? validateIndianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid 10-digit mobile number.';
    }

    final trimmed = value.trim();

    // Check for any spaces or non-digit characters
    if (trimmed.contains(RegExp(r'\D'))) {
      return 'Enter a valid 10-digit mobile number.';
    }

    // Check length and Indian starting digit rule (6, 7, 8, 9)
    if (!_indianPhoneRegex.hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number.';
    }

    return null;
  }

  /// Helper boolean check for phone validity (used for live UI success indicators)
  static bool isPhoneValid(String? value) {
    return validateIndianPhone(value) == null;
  }

  /// Validates standard email addresses
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid email address.';
    }

    final trimmed = value.trim();

    // Reject internal whitespace
    if (trimmed.contains(RegExp(r'\s'))) {
      return 'Enter a valid email address.';
    }

    // Must have '@' and '.' after '@'
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0 || atIndex == trimmed.length - 1) {
      return 'Enter a valid email address.';
    }

    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  /// Helper boolean check for email validity
  static bool isEmailValid(String? value) {
    return validateEmail(value) == null;
  }

  /// Validates Full Name (minimum 2 characters)
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  /// Helper boolean check for full name validity
  static bool isNameValid(String? value) {
    return validateFullName(value) == null;
  }

  /// Validates Password (minimum 8 characters for registration)
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Enter password.';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  /// Helper boolean check for password validity
  static bool isPasswordValid(String? value, {int minLength = 8}) {
    return validatePassword(value, minLength: minLength) == null;
  }

  /// Validates Confirm Password
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password.';
    }
    if (value != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Helper boolean check for confirm password validity
  static bool isConfirmPasswordValid(String? value, String? originalPassword) {
    return validateConfirmPassword(value, originalPassword) == null;
  }

  /// Calculates Password Strength score (0 to 4)
  static PasswordStrengthResult calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0,
        label: 'Empty',
        color: AppTheme.textHint,
        percent: 0.0,
      );
    }

    if (password.length < 8) {
      return const PasswordStrengthResult(
        score: 1,
        label: 'Too Short (min. 8)',
        color: AppTheme.coralDanger,
        percent: 0.25,
      );
    }

    int score = 1;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'\d'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-=+/\\]'));

    if (hasUpper && hasLower) score++;
    if (hasDigits) score++;
    if (hasSpecial) score++;
    if (password.length >= 12 && score < 4) score++;

    switch (score) {
      case 1:
        return const PasswordStrengthResult(
          score: 1,
          label: 'Weak',
          color: AppTheme.coralDanger,
          percent: 0.25,
        );
      case 2:
        return const PasswordStrengthResult(
          score: 2,
          label: 'Fair',
          color: AppTheme.amberWarning,
          percent: 0.50,
        );
      case 3:
        return const PasswordStrengthResult(
          score: 3,
          label: 'Good',
          color: AppTheme.indigoPrimary,
          percent: 0.75,
        );
      case 4:
      default:
        return const PasswordStrengthResult(
          score: 4,
          label: 'Strong',
          color: AppTheme.emeraldSuccess,
          percent: 1.0,
        );
    }
  }

  /// Validates Login Identifier which can be either a 10-digit Indian Mobile or Email
  static String? validateLoginIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your mobile number or email address.';
    }

    final trimmed = value.trim();

    if (trimmed.contains('@')) {
      return validateEmail(trimmed);
    } else {
      return validateIndianPhone(trimmed);
    }
  }

  /// Sanitizes text input to neutralize XSS and script injection attempts
  static String sanitizeTextInput(String input) {
    var clean = input.replaceAll(RegExp(r'<[^>]*>'), ''); // Strip HTML tags
    clean = clean.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'data:', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'vbscript:', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ''); // Strip control chars
    return clean.trim();
  }

  /// Validates Property Title:
  /// Required, 5-100 characters, trimmed, no space-only strings.
  static String? validatePropertyTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Property title is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      return 'Property title must be at least 5 characters.';
    }
    if (trimmed.length > 100) {
      return 'Property title cannot exceed 100 characters.';
    }
    return null;
  }

  /// Validates Property Description:
  /// Required, 30-2000 characters, rejects meaningless phrases.
  static String? validatePropertyDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Property description is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 30) {
      return 'Description must be at least 30 characters.';
    }
    if (trimmed.length > 2000) {
      return 'Description cannot exceed 2000 characters.';
    }

    final lower = trimmed.toLowerCase();
    final meaningless = ['test', 'abc', 'property', 'sample', 'demo', 'xyz'];
    if (meaningless.contains(lower) ||
        RegExp(r'^(.)\1+$').hasMatch(lower) ||
        RegExp(r'^(test[\s,.-]*)+$', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'^(property[\s,.-]*)+$', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'^(asdf[\s,.-]*)+$', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'^(sample[\s,.-]*)+$', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'^(.{1,8})\1{3,}$').hasMatch(lower)) {
      return 'Please enter a meaningful description of the property.';
    }

    return null;
  }

  /// Validates Asking Price in Crores (or general numeric value)
  /// Required, numeric only, strictly > 0.
  static String? validatePriceCr(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid price.';
    }
    final clean = value.trim().replaceAll(',', '');
    final parsed = double.tryParse(clean);
    if (parsed == null || parsed <= 0) {
      return 'Please enter a valid price.';
    }
    if (parsed > 1000.0) {
      return 'Price exceeds maximum supported limit (₹1,000 Cr).';
    }
    return null;
  }

  /// Validates Built-up Area in chosen unit:
  /// Required, numeric only, strictly > 0.
  static String? validateArea(String? value, {String unit = 'sq ft'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Area must be greater than 0.';
    }
    final clean = value.trim().replaceAll(',', '');
    final parsed = double.tryParse(clean);
    if (parsed == null || parsed <= 0) {
      return 'Area must be greater than 0.';
    }
    return null;
  }

  /// Backward compatible alias for sqft
  static String? validateAreaSqft(String? value) => validateArea(value, unit: 'sq ft');

  /// Validates PIN code:
  /// Exactly 6 digits, numeric only, reject letters/spaces/symbols/invalid length.
  static String? validatePinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN code must contain exactly 6 digits.';
    }
    final trimmed = value.trim();
    final pinRegex = RegExp(r'^\d{6}$');
    if (!pinRegex.hasMatch(trimmed)) {
      return 'PIN code must contain exactly 6 digits.';
    }
    return null;
  }

  /// Validates Complete Address:
  /// Required, minimum 10 characters, rejects blank/space-only.
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 10) {
      return 'Address must be at least 10 characters.';
    }
    return null;
  }

  /// Validates Bathroom count:
  /// Must be a valid positive selector option (1, 2, 3, 4, 5+).
  static String? validateBathroom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select number of bathrooms.';
    }
    const allowed = ['1', '2', '3', '4', '5', '5+'];
    if (!allowed.contains(value.trim())) {
      return 'Please select a valid bathroom count (1, 2, 3, 4, 5+).';
    }
    return null;
  }

  /// Check if property type requires BHK
  static bool isBhkRequired(String propertyType) {
    final lower = propertyType.trim().toLowerCase();
    return lower.contains('apartment') ||
        lower.contains('flat') ||
        lower.contains('villa') ||
        lower.contains('residential') ||
        lower.contains('penthouse') ||
        lower.contains('studio') ||
        lower.contains('builder floor');
  }
}

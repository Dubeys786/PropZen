import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web Email Verification Flow & HTTP Integration Tests', () {
    test('Server serves index.html with 200 OK and contains all 4-Step Verification & Redesigned UI Elements', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:8080/'));
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();

      expect(response.statusCode, equals(200));

      // 1. Verify View Containers
      expect(body.contains('id="auth-signup-view"'), isTrue, reason: 'Step 1 Sign Up view container must exist');
      expect(body.contains('id="auth-email-verify-view"'), isTrue, reason: 'Step 2 Email verification view container must exist');
      expect(body.contains('id="auth-mobile-verify-view"'), isTrue, reason: 'Step 3 Mobile SMS verification view container must exist');
      expect(body.contains('id="auth-email-verified-success-view"'), isTrue, reason: 'Step 4 Success view container must exist');

      // 2. Step 1 Sign Up UI Elements
      expect(body.contains('id="signup-role-group"'), isTrue, reason: 'Role selection radio group must exist');
      expect(body.contains('id="signup-name"'), isTrue, reason: 'Full name input must exist');
      expect(body.contains('id="signup-email"'), isTrue, reason: 'Email input must exist');
      expect(body.contains('id="signup-country-code"'), isTrue, reason: 'Country code dropdown must exist');
      expect(body.contains('id="signup-phone"'), isTrue, reason: 'Mobile phone input must exist');
      expect(body.contains('id="signup-captcha-code"'), isTrue, reason: 'Security captcha box must exist');
      expect(body.contains('id="signup-tnc"'), isTrue, reason: 'T&C checkbox must exist');
      expect(body.contains('openLegalPolicyModal(\'tnc\')'), isTrue, reason: 'Clickable T&C link must exist');
      expect(body.contains('openLegalPolicyModal(\'privacy\')'), isTrue, reason: 'Clickable Privacy Policy link must exist');
      expect(body.contains('openLegalPolicyModal(\'cookies\')'), isTrue, reason: 'Clickable Cookie Policy link must exist');
      expect(body.contains('id="submit-signup-btn"'), isTrue, reason: 'Submit Sign Up button must exist');

      // 3. Step 2 Email Verification Elements
      expect(body.contains('Verify Your Email'), isTrue, reason: 'Title "Verify Your Email" must exist');
      expect(body.contains('class="email-otp-box'), isTrue, reason: '6-digit email OTP boxes must exist');
      expect(body.contains('id="verify-email-btn"'), isTrue, reason: 'Primary button "verify-email-btn" must exist');
      expect(body.contains('id="resend-verify-email-btn"'), isTrue, reason: 'Secondary button "resend-verify-email-btn" must exist');
      expect(body.contains('id="change-email-toggle-btn"'), isTrue, reason: 'Option "change-email-toggle-btn" must exist');
      expect(body.contains('id="verify-user-email-display"'), isTrue, reason: 'User registered email display must exist');

      // 4. Step 3 Mobile Verification Elements
      expect(body.contains('Verify Mobile Number'), isTrue, reason: 'Title "Verify Mobile Number" must exist');
      expect(body.contains('class="mobile-otp-box'), isTrue, reason: '6-digit mobile OTP boxes must exist');
      expect(body.contains('id="verify-mobile-btn"'), isTrue, reason: 'Verify Mobile button must exist');
      expect(body.contains('id="resend-mobile-otp-btn"'), isTrue, reason: 'Resend SMS OTP button must exist');

      // 5. Step 4 Success Verification Elements
      expect(body.contains('Your PropZen account has been verified successfully.'), isTrue,
          reason: 'Exact success confirmation heading must exist');
      expect(body.contains('id="email-verified-continue-btn"'), isTrue, reason: 'Continue to PropZen button must exist');

      // 6. Policy Modal Container
      expect(body.contains('id="legal-policy-modal"'), isTrue, reason: 'Legal policy modal container must exist');

      client.close();
    });

    test('Server serves /verify-email endpoint with 200 OK and HTML Content-Type', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:8080/verify-email?verify_token=tok_test123'));
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();

      expect(response.statusCode, equals(200));
      expect(response.headers.contentType?.mimeType, equals('text/html'));
      expect(body.contains('id="auth-email-verify-view"'), isTrue);

      client.close();
    });

    test('app.js contains 4-Step OTP generation, input validation, 60s cooldowns, and cross-tab sync', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:8080/app.js'));
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();

      expect(response.statusCode, equals(200));

      // Token Generator & Verification Engine
      expect(body.contains('generateSecureToken'), isTrue);
      expect(body.contains('verifyEmailOtpCode'), isTrue);
      expect(body.contains('verifyMobileOtpCode'), isTrue);
      expect(body.contains('sendEmailOtp'), isTrue);
      expect(body.contains('sendMobileOtp'), isTrue);
      expect(body.contains('maskEmail'), isTrue);
      expect(body.contains('maskPhone'), isTrue);
      expect(body.contains('validateSignupFormInputs'), isTrue);

      // Cooldown Timers
      expect(body.contains('startEmailResendCooldown'), isTrue);
      expect(body.contains('startMobileResendCooldown'), isTrue);

      // Gating & Protected Actions
      expect(body.contains('requireAuthForEnquiry'), isTrue);
      expect(body.contains('isEmailVerified'), isTrue);
      expect(body.contains('isMobileVerified'), isTrue);

      // Cross-tab Synchronization
      expect(body.contains('BroadcastChannel'), isTrue);
      expect(body.contains('propzen_auth_sync'), isTrue);

      // Policy Modals
      expect(body.contains('openLegalPolicyModal'), isTrue);
      expect(body.contains('closeLegalPolicyModal'), isTrue);

      client.close();
    });
  });
}

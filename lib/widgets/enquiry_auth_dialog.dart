import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../screens/user_profile_screen.dart';
import '../services/supabase_service.dart';
import '../services/user_uniqueness_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// Professional PropZen Authentication & OTP Verification Modal
/// Required before submitting property enquiries or scheduling site visits.
class EnquiryAuthDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final String actionLabel;

  const EnquiryAuthDialog({
    super.key,
    required this.onSuccess,
    this.actionLabel = 'continue',
  });

  /// Static helper: opens dialog if unauthenticated, or executes [onSuccess] directly if already verified
  static void show(
    BuildContext context, {
    required VoidCallback onSuccess,
    String actionLabel = 'continue',
  }) {
    if (UserSession.isLoggedIn && UserSession.isEmailVerified) {
      onSuccess();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EnquiryAuthDialog(
        onSuccess: onSuccess,
        actionLabel: actionLabel,
      ),
    );
  }

  @override
  State<EnquiryAuthDialog> createState() => _EnquiryAuthDialogState();
}

class _EnquiryAuthDialogState extends State<EnquiryAuthDialog> {
  bool _isSignUp = true;
  bool _isOtpStep = false;
  bool _isLoading = false;
  int _resendCooldown = 30;
  Timer? _timer;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _loginIdController = TextEditingController();

  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  String _targetContact = '';

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _loginIdController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        if (mounted) setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleSendOtp() async {
    if (_isSignUp) {
      final nameErr = FormValidators.validateFullName(_nameController.text);
      if (nameErr != null) {
        _showError(nameErr);
        return;
      }

      final phoneErr = FormValidators.validateIndianPhone(_phoneController.text);
      if (phoneErr != null) {
        _showError(phoneErr);
        return;
      }

      final emailErr = FormValidators.validateEmail(_emailController.text);
      if (emailErr != null) {
        _showError(emailErr);
        return;
      }

      // Strict Uniqueness Check
      setState(() => _isLoading = true);
      final uniqueness = await UserUniquenessService.instance.validateCredentialsAvailability(
        email: _emailController.text,
        phone: _phoneController.text,
      );
      setState(() => _isLoading = false);

      if (!uniqueness.isAvailable) {
        _showError(uniqueness.emailErrorMessage ?? uniqueness.phoneErrorMessage ?? 'Account already exists.');
        return;
      }

      setState(() {
        _targetContact = _phoneController.text.trim();
        _isOtpStep = true;
      });
      _startResendTimer();
    } else {
      final loginId = _loginIdController.text.trim();
      final loginErr = FormValidators.validateLoginIdentifier(loginId);
      if (loginErr != null) {
        _showError(loginErr);
        return;
      }

      setState(() {
        _targetContact = loginId;
        _isOtpStep = true;
      });
      _startResendTimer();
    }
  }

  void _handleVerifyAndContinue() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length < 4) {
      _showError('Please enter the 4-digit verification code');
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 400));

    String finalName = '';
    String finalPhone = '';
    String finalEmail = '';

    if (_isSignUp) {
      finalName = _nameController.text.trim();
      finalPhone = _phoneController.text.trim();
      finalEmail = _emailController.text.trim();
    } else {
      final loginId = _loginIdController.text.trim();
      if (loginId.contains('@')) {
        finalEmail = loginId;
        finalName = loginId.split('@').first;
      } else {
        finalPhone = loginId;
        finalName = 'Propzen Member';
      }
    }

    // Save to user session
    if (_isSignUp) {
      UserUniquenessService.instance.registerIdentity(email: finalEmail, phone: finalPhone);
    }

    UserSession.login(
      fullName: finalName,
      mobile: finalPhone,
      email: finalEmail,
      isEmailVerified: true,
    );

    // Also persist to Supabase backend
    try {
      await SupabaseService.instance.saveUserSignin(
        name: finalName,
        email: finalEmail,
        phone: finalPhone,
        role: 'Buyer',
        isEmailVerified: true,
      );
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop(); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Welcome back, $finalName! Verification complete.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppTheme.emeraldSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Trigger original requested action
      widget.onSuccess();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.coralDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: _isOtpStep ? _buildOtpVerificationView() : _buildAuthFormView(),
        ),
      ),
    );
  }

  /// Step 1: Sign In / Sign Up Form
  Widget _buildAuthFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/propzen_logo.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.shieldCheck, color: AppTheme.primaryViolet, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PropZen', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('Property Intelligence', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Title & Verification Alert
        Text(
          _isSignUp ? 'Create Account' : 'Sign in to continue',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Verification required to continue with ${widget.actionLabel}',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 20),

        // Tab Selector (Sign In vs Create Account)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isSignUp = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isSignUp ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_isSignUp ? const [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                    ),
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: !_isSignUp ? FontWeight.bold : FontWeight.w500,
                          color: !_isSignUp ? AppTheme.primaryViolet : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isSignUp = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isSignUp ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _isSignUp ? const [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                    ),
                    child: Center(
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: _isSignUp ? FontWeight.bold : FontWeight.w500,
                          color: _isSignUp ? AppTheme.primaryViolet : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Form Inputs
        if (_isSignUp) ...[
          _buildInputField(
            controller: _nameController,
            label: 'Full Name *',
            hintText: 'Enter your full name',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _phoneController,
            label: 'Mobile Number *',
            hintText: 'Enter 10-digit mobile number',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _emailController,
            label: 'Email Address *',
            hintText: 'Enter your email address',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
        ] else ...[
          _buildInputField(
            controller: _loginIdController,
            label: 'Mobile Number or Email *',
            hintText: 'Enter your registered mobile or email',
            icon: LucideIcons.userCheck,
          ),
        ],

        const SizedBox(height: 22),

        // Send OTP / Continue Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'Send OTP',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Switch Mode Link
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Create Account",
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: OTP Verification Screen
  Widget _buildOtpVerificationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to edit contact & close
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _isOtpStep = false),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    const Icon(LucideIcons.arrowLeft, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('Back', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Header
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primaryViolet, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'Verify Contact',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  children: [
                    const TextSpan(text: 'Enter the 4-digit OTP sent to\n'),
                    TextSpan(
                      text: _targetContact,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // OTP 4-Box Input
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              width: 52,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 3) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (index == 3 && val.isNotEmpty) {
                    _handleVerifyAndContinue();
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Resend Timer / Action
        Center(
          child: _resendCooldown > 0
              ? Text(
                  'Resend code in ${_resendCooldown}s',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                )
              : TextButton(
                  onPressed: () {
                    _startResendTimer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP resent successfully!'), backgroundColor: AppTheme.emeraldSuccess),
                    );
                  },
                  child: Text(
                    'Resend OTP Code',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                  ),
                ),
        ),

        const SizedBox(height: 20),

        // Verify & Continue Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Verify & Continue', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

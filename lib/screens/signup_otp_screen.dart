import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SignupOtpScreen extends StatefulWidget {
  final String phone;
  final String email;
  final String generatedOtp;
  final VoidCallback? onVerified;
  final VoidCallback? onSuccess;

  const SignupOtpScreen({
    super.key,
    this.phone = '',
    this.email = '',
    this.generatedOtp = '',
    this.onVerified,
    this.onSuccess,
  });

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _resendCooldownSeconds = 60;
  int _expiryRemainingSeconds = 300; // 5 minutes expiration
  Timer? _cooldownTimer;
  Timer? _expiryTimer;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  late bool _isUsingEmail;

  @override
  void initState() {
    super.initState();
    _isUsingEmail = widget.phone.isEmpty && widget.email.isNotEmpty;
    _startTimers();
  }

  void _startTimers() {
    _startResendCooldown();
    _startExpiryTimer();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldownSeconds > 0) {
        if (mounted) setState(() => _resendCooldownSeconds--);
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    setState(() => _expiryRemainingSeconds = 300);
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_expiryRemainingSeconds > 0) {
        if (mounted) setState(() => _expiryRemainingSeconds--);
      } else {
        _expiryTimer?.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = 'OTP has expired. Please tap "Resend OTP" to generate a fresh code.';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_resendCooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final target = _isUsingEmail
        ? (widget.email.isNotEmpty ? widget.email : widget.phone)
        : (widget.phone.isNotEmpty ? widget.phone : widget.email);

    final success = await AuthService.instance.sendOtp(
      destination: target,
      isEmail: _isUsingEmail,
    );

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _startResendCooldown();
      _startExpiryTimer();
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh OTP was dispatched to $target (valid for 5 mins).'),
          backgroundColor: AppTheme.emeraldSuccess,
        ),
      );
    } else {
      setState(() {
        _errorMessage = AuthService.instance.lastError ?? 'Unable to resend OTP right now. Please try again.';
      });
    }
  }

  void _switchDeliveryChannel() {
    setState(() {
      _isUsingEmail = !_isUsingEmail;
      _errorMessage = null;
    });
    _resendOtp();
  }

  Future<void> _verifyOtp() async {
    final entered = _controllers.map((c) => c.text.trim()).join();
    if (entered.length < 4) {
      setState(() => _errorMessage = 'Please enter the complete 4-digit verification code.');
      return;
    }

    if (_expiryRemainingSeconds <= 0) {
      setState(() => _errorMessage = 'This OTP has expired. Please request a new code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final target = _isUsingEmail
        ? (widget.email.isNotEmpty ? widget.email : widget.phone)
        : (widget.phone.isNotEmpty ? widget.phone : widget.email);

    final result = await AuthService.instance.verifyOtp(
      destination: target,
      phone: widget.phone,
      email: widget.email,
      otp: entered,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.success) {
      UserSession.isLoggedInNotifier.value = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Verified Successfully! Welcome to PropZen.'),
          backgroundColor: AppTheme.emeraldSuccess,
        ),
      );
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        AppRoutes.navigateToPostLoginDestination(context);
      }
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Invalid verification code. Please check and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTarget = _isUsingEmail
        ? (widget.email.isNotEmpty ? widget.email : 'your registered email')
        : (widget.phone.isNotEmpty ? widget.phone : 'your registered number');

    final minutes = (_expiryRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_expiryRemainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text('Secure Verification', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Top Icon / Shield
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isUsingEmail ? LucideIcons.mail : LucideIcons.smartphone,
                color: AppTheme.primaryViolet,
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Enter the OTP sent via ${_isUsingEmail ? "Email" : "SMS"} to',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              displayTarget,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),

            // Expiry countdown banner
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _expiryRemainingSeconds > 60 ? const Color(0xFFF5F3FF) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _expiryRemainingSeconds > 60 ? const Color(0xFFDDD6FE) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 13,
                    color: _expiryRemainingSeconds > 60 ? AppTheme.primaryViolet : AppTheme.coralDanger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expiryRemainingSeconds > 0 ? 'Code expires in $minutes:$seconds' : 'Code has expired',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _expiryRemainingSeconds > 60 ? AppTheme.primaryViolet : AppTheme.coralDanger,
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // 4 Boxed Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  width: 58,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _controllers[i].text.isNotEmpty ? AppTheme.primaryViolet : AppTheme.borderLight,
                      width: _controllers[i].text.isNotEmpty ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {});
                        if (val.isNotEmpty && i < 3) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        } else if (val.isNotEmpty && i == 3) {
                          // Automatically trigger verify when last digit filled
                          _verifyOtp();
                        }
                      },
                      onSubmitted: (_) {
                        if (i == 3) _verifyOtp();
                      },
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // Resend Cooldown & Switch Channel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _resendCooldownSeconds > 0
                      ? 'Resend in 00:${_resendCooldownSeconds.toString().padLeft(2, '0')}'
                      : "Didn't receive code?",
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                if (_resendCooldownSeconds == 0)
                  InkWell(
                    onTap: _isResending ? null : _resendOtp,
                    child: Text(
                      _isResending ? 'Sending...' : 'Resend OTP',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                    ),
                  ),
              ],
            ),

            // Fallback to Alternate Channel (SMS <-> Email)
            if (widget.phone.isNotEmpty && widget.email.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _switchDeliveryChannel,
                child: Text(
                  _isUsingEmail ? 'Send OTP via SMS instead' : 'Send OTP via Email instead',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryViolet,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Verify & Continue',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Security Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shieldCheck, color: AppTheme.emeraldSuccess, size: 16),
                const SizedBox(width: 8),
                Text(
                  '256-bit encrypted secure verification',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

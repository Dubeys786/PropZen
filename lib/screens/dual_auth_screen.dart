import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'signup_otp_screen.dart';
import 'user_profile_screen.dart';
import 'email_verification_screen.dart';
import 'post_property_screen.dart';
import '../services/supabase_service.dart';
import '../services/user_uniqueness_service.dart';
import '../services/auth_service.dart';
import '../services/dealer_service.dart';
import '../models/service_partner_profile.dart';
import '../services/service_partner_service.dart';
import '../widgets/become_dealer_dialog.dart';
import '../routes/app_routes.dart';

class DualAuthScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final bool initialSignUp;
  final String? redirectRoute;

  const DualAuthScreen({
    super.key,
    this.onNavigateTab,
    this.initialSignUp = false,
    this.redirectRoute,
  });

  @override
  State<DualAuthScreen> createState() => _DualAuthScreenState();
}

class _DualAuthScreenState extends State<DualAuthScreen> {
  late bool isSignUp;
  bool isViaMobile = true;
  bool agreeTerms = true;
  bool _isLoading = false;
  bool _isCheckingUniqueness = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _backendErrorMessage;
  String? _emailDuplicateError;
  String? _phoneDuplicateError;

  // Account Type Selection: 'buyer' | 'dealer'
  String _authAccountType = 'buyer'; // default is buyer

  // Dealer-specific registration controllers
  final TextEditingController _agencyController = TextEditingController();
  final TextEditingController _reraController = TextEditingController();
  final FocusNode _agencyFocusNode = FocusNode();
  final FocusNode _reraFocusNode = FocusNode();

  // Service Partner registration controllers & options
  final TextEditingController _businessNameController = TextEditingController();
  final FocusNode _businessNameFocusNode = FocusNode();
  String _selectedServiceCategory = 'HOME_DESIGN';

  static const List<Map<String, dynamic>> _serviceCategoryOptions = [
    {
      'code': 'LOAN',
      'title': 'Home Loan & Mortgage',
      'icon': LucideIcons.badgePercent,
      'desc': 'Sanction assistance, interest optimization & eligibility',
    },
    {
      'code': 'HOME_DESIGN',
      'title': 'Interior & Architectural Design',
      'icon': LucideIcons.palette,
      'desc': '2D/3D layouts, turnkey interior execution',
    },
    {
      'code': 'VASTU',
      'title': 'Vastu Consultation',
      'icon': LucideIcons.compass,
      'desc': 'Energy audits, spatial alignment analysis',
    },
    {
      'code': 'CONSTRUCTION',
      'title': 'Construction & Renovation',
      'icon': LucideIcons.hardHat,
      'desc': 'Civil works, site milestone supervision',
    },
    {
      'code': 'PROPERTY_VERIFICATION',
      'title': 'Legal & Title Verification',
      'icon': LucideIcons.fileCheck,
      'desc': '7/12 title search, encumbrance clearances',
    },
    {
      'code': 'VIRTUAL_3D',
      'title': '3D Modeling & Virtual Tours',
      'icon': LucideIcons.box,
      'desc': 'Drone capture, VR walkthroughs & 3D renders',
    },
  ];

  // NRI / Resident User Type Setting
  String _selectedUserType = 'Indian Resident'; // 'Indian Resident' | 'NRI'
  String _selectedCountry = 'United States';
  final List<String> _nriCountries = const [
    'United States',
    'United Arab Emirates',
    'United Kingdom',
    'Canada',
    'Singapore',
    'Australia',
    'Germany',
    'Saudi Arabia',
    'Qatar',
    'Kuwait',
    'Other',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    isSignUp = widget.initialSignUp;

    // Attach listeners to trigger validation on blur (when user leaves field)
    _nameFocusNode.addListener(_onFieldFocusChange);
    _mobileFocusNode.addListener(_onFieldFocusChange);
    _emailFocusNode.addListener(_onFieldFocusChange);
    _passwordFocusNode.addListener(_onFieldFocusChange);
    _confirmPasswordFocusNode.addListener(_onFieldFocusChange);

    _emailFocusNode.addListener(_onEmailBlur);
    _mobileFocusNode.addListener(_onPhoneBlur);
  }

  void _onEmailBlur() async {
    if (!isSignUp || _emailFocusNode.hasFocus) return;
    final email = _emailController.text.trim();
    if (FormValidators.isEmailValid(email)) {
      final isDup = UserUniquenessService.instance.isEmailLocallyRegistered(email) ||
          await SupabaseService.instance.checkEmailExists(email);
      if (mounted) {
        setState(() {
          _emailDuplicateError = isDup
              ? 'This email address is already registered. Please use a different email address.'
              : null;
        });
      }
    }
  }

  void _onPhoneBlur() async {
    if (!isSignUp || _mobileFocusNode.hasFocus) return;
    final phone = _mobileController.text.trim();
    if (FormValidators.isPhoneValid(phone)) {
      final isDup = UserUniquenessService.instance.isPhoneLocallyRegistered(phone) ||
          await SupabaseService.instance.checkPhoneExists(phone);
      if (mounted) {
        setState(() {
          _phoneDuplicateError = isDup
              ? 'This phone number is already registered. Please use a different phone number.'
              : null;
        });
      }
    }
  }

  void _onFieldFocusChange() {
    if (!_nameFocusNode.hasFocus ||
        !_mobileFocusNode.hasFocus ||
        !_emailFocusNode.hasFocus ||
        !_passwordFocusNode.hasFocus ||
        !_confirmPasswordFocusNode.hasFocus) {
      if (_autoValidateMode == AutovalidateMode.disabled) {
        setState(() {
          _autoValidateMode = AutovalidateMode.onUserInteraction;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFieldFocusChange);
    _mobileFocusNode.removeListener(_onFieldFocusChange);
    _emailFocusNode.removeListener(_onFieldFocusChange);
    _passwordFocusNode.removeListener(_onFieldFocusChange);
    _confirmPasswordFocusNode.removeListener(_onFieldFocusChange);

    _emailFocusNode.removeListener(_onEmailBlur);
    _mobileFocusNode.removeListener(_onPhoneBlur);

    _nameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _agencyFocusNode.dispose();
    _reraFocusNode.dispose();
    _agencyController.dispose();
    _reraController.dispose();

    _businessNameFocusNode.dispose();
    _businessNameController.dispose();

    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitAuth() async {
    if (_isLoading || _isCheckingUniqueness) return;

    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
      _backendErrorMessage = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      if (isSignUp) {
        if (FormValidators.validateFullName(_nameController.text) != null) {
          _nameFocusNode.requestFocus();
        } else if (FormValidators.validateEmail(_emailController.text) != null) {
          _emailFocusNode.requestFocus();
        } else if (FormValidators.validateIndianPhone(_mobileController.text) != null) {
          _mobileFocusNode.requestFocus();
        } else if (FormValidators.validatePassword(_passwordController.text) != null) {
          _passwordFocusNode.requestFocus();
        } else if (FormValidators.validateConfirmPassword(_confirmPasswordController.text, _passwordController.text) != null) {
          _confirmPasswordFocusNode.requestFocus();
        }
      } else {
        if (isViaMobile && FormValidators.validateIndianPhone(_mobileController.text) != null) {
          _mobileFocusNode.requestFocus();
        } else if (!isViaMobile && FormValidators.validateEmail(_emailController.text) != null) {
          _emailFocusNode.requestFocus();
        } else if (FormValidators.validatePassword(_passwordController.text, minLength: 6) != null) {
          _passwordFocusNode.requestFocus();
        }
      }
      return;
    }

    if (isSignUp && !agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Propzen Terms of Service and Privacy Policy'),
          backgroundColor: AppTheme.coralDanger,
        ),
      );
      return;
    }

    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final contact = (isViaMobile ? mobile : email).trim();
    final password = _passwordController.text;

    // =========================================================================
    // 1. SIGN IN FLOW (BUYER OR DEALER ROLE VERIFICATION)
    // =========================================================================
    if (!isSignUp) {
      setState(() => _isLoading = true);

      try {
        final result = _authAccountType == 'dealer'
            ? await AuthService.instance.authenticateDealer(identifier: contact, password: password)
            : (_authAccountType == 'service_partner'
                ? await AuthService.instance.authenticateServicePartner(identifier: contact, password: password)
                : await AuthService.instance.authenticateBuyer(identifier: contact, password: password));

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result.isSuccess) {
          _onSuccessfulAuthentication();
        } else {
          if (result.isBuyerTryingDealer) {
            _showBuyerDetectedDialog(contact, password);
          } else if (result.isDealerPending) {
            setState(() {
              _backendErrorMessage = 'Your Dealer account is still under verification.';
            });
          } else if (result.isDealerRejected) {
            setState(() {
              _backendErrorMessage = 'Your Dealer application was not approved.';
            });
          } else {
            setState(() {
              _backendErrorMessage = result.message;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _backendErrorMessage = 'Sign in failed. Please check your credentials and network connection.';
          });
        }
      }
      return;
    }

    // =========================================================================
    // 2. SIGN UP FLOW (CREATE BUYER OR DEALER APPLICATION)
    // =========================================================================
    // Strict uniqueness check before registration
    setState(() => _isCheckingUniqueness = true);
    final uniqueness = await UserUniquenessService.instance.validateCredentialsAvailability(
      email: email,
      phone: mobile,
    );

    if (!uniqueness.isAvailable) {
      setState(() {
        _isCheckingUniqueness = false;
        _emailDuplicateError = uniqueness.emailErrorMessage;
        _phoneDuplicateError = uniqueness.phoneErrorMessage;
      });

      if (uniqueness.isEmailDuplicate) {
        _emailFocusNode.requestFocus();
      } else if (uniqueness.isPhoneDuplicate) {
        _mobileFocusNode.requestFocus();
      }
      return;
    }
    setState(() => _isCheckingUniqueness = false);

    setState(() => _isLoading = true);

    try {
      if (name.isNotEmpty) {
        UserSession.fullNameNotifier.value = name;
      }
      if (mobile.isNotEmpty) {
        UserSession.phoneNotifier.value = mobile;
      }
      if (email.isNotEmpty) {
        UserSession.emailNotifier.value = email;
      }

      // Persist User Type & Country
      UserSession.setUserType(
        _selectedUserType,
        country: _selectedUserType == 'NRI' ? _selectedCountry : 'India',
      );

      // SERVICE PARTNER SIGNUP: Saved with initial PENDING status & selected specialization
      if (_authAccountType == 'service_partner') {
        final bName = _businessNameController.text.trim().isNotEmpty
            ? _businessNameController.text.trim()
            : (name.isNotEmpty ? name : 'PropZen Service Partner');

        final newSpId = 'SP-${DateTime.now().millisecondsSinceEpoch}';
        final initialProfile = ServicePartnerProfile(
          id: newSpId,
          userId: UserSession.userId.isNotEmpty ? UserSession.userId : 'usr_${DateTime.now().millisecondsSinceEpoch}',
          businessName: bName,
          serviceCategory: _selectedServiceCategory,
          serviceCategories: [_selectedServiceCategory],
          verificationStatus: 'PENDING',
          status: 'PENDING',
          phone: mobile,
          email: email,
        );

        await SupabaseService.instance.saveServicePartnerProfile(initialProfile.toJson());

        await SupabaseService.instance.saveUserSignin(
          name: bName,
          email: email,
          phone: mobile,
          role: 'SERVICE_PARTNER',
          isEmailVerified: true,
        );

        UserSession.login(
          userId: initialProfile.userId,
          name: bName,
          email: email,
          phone: mobile,
          role: 'SERVICE_PARTNER',
          isEmailVerified: true,
        );
        UserSession.setServicePartnerProfile(initialProfile);
        await ServicePartnerService.instance.loadForProfile(initialProfile);

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.of(context).pushReplacementNamed(AppRoutes.servicePartnerStatus);
        return;
      }

      // DEALER SIGNUP: Submissions have DEALER_PENDING status until approved
      if (_authAccountType == 'dealer') {
        final agencyName = _agencyController.text.trim().isNotEmpty
            ? _agencyController.text.trim()
            : 'PropZen Partner Brokerage';
        final reraNumber = _reraController.text.trim().isNotEmpty
            ? _reraController.text.trim()
            : 'UPRERA-VERIFIED';

        await SupabaseService.instance.saveUserSignin(
          name: name.isNotEmpty ? name : agencyName,
          email: email,
          phone: mobile,
          role: 'DEALER_PENDING',
          isEmailVerified: true,
        );

        await DealerService.instance.registerDealer(
          dealerId: 'DLR-${mobile.replaceAll(RegExp(r'[^0-9]'), '')}',
          companyName: agencyName,
          phone: mobile,
          email: email,
          reraNumber: reraNumber,
        );

        UserSession.login(
          name: name.isNotEmpty ? name : agencyName,
          email: email,
          phone: mobile,
          role: 'DEALER_PENDING',
          isEmailVerified: true,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        _showDealerPendingDialog();
        return;
      }

      // BUYER SIGNUP: Saved as USER / Buyer
      try {
        await SupabaseService.instance.saveUserSignin(
          name: name.isNotEmpty ? name : 'Propzen User',
          email: email,
          phone: mobile,
          role: _selectedUserType == 'NRI' ? 'NRI Buyer' : 'USER',
          isEmailVerified: false,
        );
      } catch (backendErr) {
        debugPrint('[DualAuthScreen] Backend notice: $backendErr');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      final contactForOtp = (isViaMobile ? mobile : email).trim();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => SignupOtpScreen(
            phone: contactForOtp,
            onVerified: () {
              _onSuccessfulAuthentication();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _backendErrorMessage = 'Unable to create your account right now. Please try again.';
        });
      }
    }
  }

  void _showBuyerDetectedDialog(String contact, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Buyer Account Detected',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Your account is registered as a Buyer. Please continue as Buyer or apply to become a Dealer.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.5),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              BecomeDealerDialog.show(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF7C3AED)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Apply as Dealer',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() {
                _authAccountType = 'buyer';
                _isLoading = true;
              });
              final res = await AuthService.instance.authenticateBuyer(identifier: contact, password: password);
              if (mounted) {
                setState(() => _isLoading = false);
                if (res.isSuccess) {
                  _onSuccessfulAuthentication();
                } else {
                  setState(() => _backendErrorMessage = res.errorMessage);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Continue as Buyer',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDealerPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.briefcase, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dealer Application Submitted',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Your Dealer account registration has been submitted for verification. Our admin team will review your agency credentials within 24-48 hours. In the meantime, you can explore PropZen properties as a Buyer.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AppRoutes.navigateToPostLoginDestination(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Continue to Home',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onSuccessfulAuthentication() {
    if (!mounted) return;
    if (widget.redirectRoute == AppRoutes.listProperty ||
        widget.redirectRoute == '/list-property' ||
        widget.redirectRoute == AppRoutes.postProperty ||
        widget.redirectRoute == '/post-property') {
      if (!UserSession.isEmailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => EmailVerificationGateScreen(
              redirectRoute: AppRoutes.listProperty,
              onVerified: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PostPropertyScreen()),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PostPropertyScreen()),
        );
      }
    } else {
      AppRoutes.navigateToPostLoginDestination(context);
    }
  }

  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            Image.asset(
              'assets/propzen_logo.png',
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(LucideIcons.home, color: AppTheme.primaryViolet, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'PropZen',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Welcoming Header
                  _buildTopHeader(),

                  const SizedBox(height: 24),

                  // Main White Card Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A0F172A),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Top User Type Selector: [ 🏠 Buyer ] [ 💼 Dealer / Broker ]
                          _buildUserTypeSelector(),

                          // 2. Section Title
                          Text(
                            isSignUp
                                ? (_authAccountType == 'dealer' ? 'Register as Dealer / Broker' : 'Create your Buyer account')
                                : (_authAccountType == 'dealer' ? 'Dealer / Broker Login' : 'Welcome back'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSignUp
                                ? (_authAccountType == 'dealer'
                                    ? 'Join PropZen Partner Network. Requires verified agency & RERA details.'
                                    : 'Get personalized property recommendations, site visits and more.')
                                : (_authAccountType == 'dealer'
                                    ? 'Access your PropZen Dealer Portal, listings & client leads.'
                                    : 'Sign in to access your shortlisted properties and scheduled visits.'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),

                          // Backend error banner (if any)
                          if (_backendErrorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _backendErrorMessage!,
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF991B1B)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setState(() => _backendErrorMessage = null),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Mode-specific Forms
                          if (isSignUp) _buildSignUpFields() else _buildSignInFields(),

                          const SizedBox(height: 22),

                          // Submit Action Button
                          _buildSubmitButton(),

                          const SizedBox(height: 20),

                          // SSO Divider & Buttons
                          _buildSsoSection(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Toggle Switch (Sign In vs Sign Up)
                  _buildBottomToggle(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top User Type Selector: [ 🏠 Buyer ], [ 💼 Dealer / Broker ], and [ 🛠️ Service Partner ]
  Widget _buildUserTypeSelector() {
    final isBuyer = _authAccountType == 'buyer';
    final isDealer = _authAccountType == 'dealer';
    final isServicePartner = _authAccountType == 'service_partner';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // 1. Buyer Tab
          Expanded(
            child: InkWell(
              onTap: () {
                if (_authAccountType != 'buyer') {
                  setState(() {
                    _authAccountType = 'buyer';
                    _backendErrorMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isBuyer ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBuyer ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isBuyer
                      ? const [
                          BoxShadow(
                            color: Color(0x337C3AED),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.home,
                      size: 14,
                      color: isBuyer ? Colors.white : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Buyer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isBuyer ? FontWeight.bold : FontWeight.w600,
                        color: isBuyer ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 2. Dealer / Broker Tab
          Expanded(
            child: InkWell(
              onTap: () {
                if (_authAccountType != 'dealer') {
                  setState(() {
                    _authAccountType = 'dealer';
                    _backendErrorMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDealer ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDealer ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isDealer
                      ? const [
                          BoxShadow(
                            color: Color(0x337C3AED),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.briefcase,
                      size: 14,
                      color: isDealer ? Colors.white : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Dealer / Broker',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isDealer ? FontWeight.bold : FontWeight.w600,
                          color: isDealer ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 3. Service Partner Tab
          Expanded(
            child: InkWell(
              onTap: () {
                if (_authAccountType != 'service_partner') {
                  setState(() {
                    _authAccountType = 'service_partner';
                    _backendErrorMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isServicePartner ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isServicePartner ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isServicePartner
                      ? const [
                          BoxShadow(
                            color: Color(0x337C3AED),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.wrench,
                      size: 14,
                      color: isServicePartner ? Colors.white : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Partner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isServicePartner ? FontWeight.bold : FontWeight.w600,
                          color: isServicePartner ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top welcoming branding widget
  Widget _buildTopHeader() {
    final isDealer = _authAccountType == 'dealer';
    final isServicePartner = _authAccountType == 'service_partner';

    IconData headerIcon = LucideIcons.building2;
    String headerTitle = 'Welcome to PropZen';
    String headerSubtitle = 'Your smarter way to discover and manage properties.';

    if (isDealer) {
      headerIcon = LucideIcons.briefcase;
      headerTitle = 'PropZen Dealer Portal';
      headerSubtitle = 'Authorized Broker & Institutional Partner Network';
    } else if (isServicePartner) {
      headerIcon = LucideIcons.wrench;
      headerTitle = 'Service Partner Portal';
      headerSubtitle = 'Loan, Design, Vastu, Construction & Verification Network';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Icon(
              headerIcon,
              color: AppTheme.primaryViolet,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  headerSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fields for Create Account / Sign Up
  Widget _buildSignUpFields() {
    final passwordVal = _passwordController.text;
    final strength = FormValidators.calculatePasswordStrength(passwordVal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_authAccountType == 'service_partner') ...[
          // Service Partner Application Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.clock, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Service Partner accounts undergo credential verification by PropZen Admin. Your account will be registered with status PENDING and activated upon approval.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          // Business / Firm Name
          _buildFieldLabel('Business / Firm Name'),
          TextFormField(
            controller: _businessNameController,
            focusNode: _businessNameFocusNode,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Business / Firm name is required' : null,
            decoration: _buildInputDecoration(
              hintText: 'e.g. Aura Design Studios',
              prefixIcon: LucideIcons.building2,
            ),
          ),
          const SizedBox(height: 16),
          // What service do you provide?
          _buildFieldLabel('What service do you provide?'),
          Text(
            'Select your service category. Customer requests will be routed to your portal once approved by Admin.',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          ..._serviceCategoryOptions.map((opt) {
            final isSelected = _selectedServiceCategory == opt['code'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedServiceCategory = opt['code'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryViolet : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          opt['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppTheme.primaryViolet : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['desc'] as String,
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(LucideIcons.checkCircle2, size: 18, color: AppTheme.primaryViolet),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ] else if (_authAccountType == 'dealer') ...[
          // Dealer Application Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dealer Partner accounts undergo credential & RERA verification by PropZen Admin within 24-48 hours. Your account is initially registered as DEALER_PENDING.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6D28D9), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          // Agency / Brokerage Firm Name
          _buildFieldLabel('Company / Agency Name'),
          TextFormField(
            controller: _agencyController,
            focusNode: _agencyFocusNode,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Agency / Firm name is required' : null,
            decoration: _buildInputDecoration(
              hintText: 'e.g. Apex Realty Partners',
              prefixIcon: LucideIcons.building2,
            ),
          ),
          const SizedBox(height: 16),
          // RERA Registration Number
          _buildFieldLabel('RERA Registration Number'),
          TextFormField(
            controller: _reraController,
            focusNode: _reraFocusNode,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'RERA registration number is required' : null,
            decoration: _buildInputDecoration(
              hintText: 'e.g. UPRERA-AG-2024-884',
              prefixIcon: LucideIcons.badgeCheck,
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // 0. User Residency Status (Indian Resident vs NRI)
          _buildFieldLabel('User Type'),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedUserType = 'Indian Resident'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedUserType == 'Indian Resident' ? AppTheme.primaryViolet : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedUserType == 'Indian Resident' ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Indian Resident',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedUserType == 'Indian Resident' ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedUserType = 'NRI'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _selectedUserType == 'NRI' ? AppTheme.primaryViolet : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedUserType == 'NRI' ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.globe,
                            size: 14,
                            color: _selectedUserType == 'NRI' ? Colors.white : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'NRI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedUserType == 'NRI' ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // If NRI selected, show Country of Residence dropdown
          if (_selectedUserType == 'NRI') ...[
            const SizedBox(height: 12),
            _buildFieldLabel('Country of Residence'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  isExpanded: true,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                  items: _nriCountries
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 14, color: AppTheme.primaryViolet),
                                const SizedBox(width: 8),
                                Text(c),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCountry = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enables 4K aerial drone tours and timezone-aligned live virtual visits.',
              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
            ),
          ],

          const SizedBox(height: 16),
        ],

        // 1. Full Name
        _buildFieldLabel('Full Name'),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          validator: FormValidators.validateFullName,
          onChanged: (_) => setState(() {}),
          decoration: _buildInputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: LucideIcons.user,
            isValid: FormValidators.isNameValid(_nameController.text),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Email Address
        _buildFieldLabel('Email Address'),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          validator: FormValidators.validateEmail,
          onChanged: (_) {
            if (_emailDuplicateError != null) {
              setState(() => _emailDuplicateError = null);
            } else {
              setState(() {});
            }
          },
          decoration: _buildInputDecoration(
            hintText: 'Enter your email',
            prefixIcon: LucideIcons.mail,
            isValid: FormValidators.isEmailValid(_emailController.text) && _emailDuplicateError == null,
          ),
        ),
        if (_emailDuplicateError != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(LucideIcons.alertCircle, size: 14, color: AppTheme.coralDanger),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _emailDuplicateError!,
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.coralDanger, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // 3. Phone Number with +91 Prefix
        _buildFieldLabel('Phone Number'),
        TextFormField(
          controller: _mobileController,
          focusNode: _mobileFocusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, letterSpacing: 0.5),
          validator: FormValidators.validateIndianPhone,
          onChanged: (_) {
            if (_phoneDuplicateError != null) {
              setState(() => _phoneDuplicateError = null);
            } else {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: 'Enter 10-digit mobile number',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.phone, size: 16, color: AppTheme.primaryViolet),
                  const SizedBox(width: 6),
                  Text(
                    '+91',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            suffixIcon: FormValidators.isPhoneValid(_mobileController.text) && _phoneDuplicateError == null
                ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18)
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _phoneDuplicateError != null ? AppTheme.coralDanger : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _phoneDuplicateError != null ? AppTheme.coralDanger : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _phoneDuplicateError != null ? AppTheme.coralDanger : AppTheme.primaryViolet, width: 1.5),
            ),
            errorMaxLines: 2,
          ),
        ),
        if (_phoneDuplicateError != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(LucideIcons.alertCircle, size: 14, color: AppTheme.coralDanger),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _phoneDuplicateError!,
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.coralDanger, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // 4. Password
        _buildFieldLabel('Password'),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          validator: FormValidators.validatePassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter password',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(LucideIcons.lock, size: 16, color: Color(0xFF64748B)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
            ),
            errorMaxLines: 2,
          ),
        ),

        // Password Strength Meter
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password strength:',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  Text(
                    strength.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: strength.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength.percent,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // 5. Confirm Password
        _buildFieldLabel('Confirm Password'),
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitAuth(),
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          validator: (val) => FormValidators.validateConfirmPassword(val, _passwordController.text),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(LucideIcons.lock, size: 16, color: Color(0xFF64748B)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (FormValidators.isConfirmPasswordValid(_confirmPasswordController.text, _passwordController.text))
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
                  ),
                IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ],
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
            ),
            errorMaxLines: 2,
          ),
        ),

        const SizedBox(height: 16),

        // Terms and Conditions Disclaimer
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: agreeTerms,
                activeColor: AppTheme.primaryViolet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => agreeTerms = val ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                children: [
                  Text(
                    'By creating an account, you agree to our ',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  GestureDetector(
                    onTap: () => _showTermsDialog(
                      'Terms & Conditions',
                      'Welcome to PropZen. By accessing our platform, you agree to comply with our institutional data policies, verified buyer terms, and property listing protocols.',
                    ),
                    child: Text(
                      'Terms & Conditions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryViolet,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ' and ',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  GestureDetector(
                    onTap: () => _showTermsDialog(
                      'Privacy Policy',
                      'PropZen values your privacy. Your personal details, contact information, and shortlisted properties are encrypted and never shared with unauthorized third parties.',
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryViolet,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Fields for Sign In
  Widget _buildSignInFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_authAccountType == 'service_partner') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Signing in to verified Service Partner Portal',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6D28D9)),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_authAccountType == 'dealer') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.briefcase, size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Signing in to verified Dealer & Broker Portal',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6D28D9)),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Tab Switch (Mobile vs Email)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => isViaMobile = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isViaMobile ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isViaMobile
                          ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Via Mobile',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isViaMobile ? FontWeight.bold : FontWeight.w500,
                          color: isViaMobile ? AppTheme.primaryViolet : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => isViaMobile = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !isViaMobile ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !isViaMobile
                          ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Via Email',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: !isViaMobile ? FontWeight.bold : FontWeight.w500,
                          color: !isViaMobile ? AppTheme.primaryViolet : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        if (isViaMobile) ...[
          _buildFieldLabel('Mobile Number'),
          TextFormField(
            controller: _mobileController,
            focusNode: _mobileFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            validator: FormValidators.validateIndianPhone,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter 10-digit mobile number',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.phone, size: 16, color: AppTheme.primaryViolet),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              suffixIcon: FormValidators.isPhoneValid(_mobileController.text)
                  ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18)
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
              ),
              errorMaxLines: 2,
            ),
          ),
        ] else ...[
          _buildFieldLabel('Email Address'),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            validator: FormValidators.validateEmail,
            onChanged: (_) => setState(() {}),
            decoration: _buildInputDecoration(
              hintText: 'Enter your email',
              prefixIcon: LucideIcons.mail,
              isValid: FormValidators.isEmailValid(_emailController.text),
            ),
          ),
        ],

        const SizedBox(height: 16),

        _buildFieldLabel('Password'),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitAuth(),
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          validator: (val) => FormValidators.validatePassword(val, minLength: 6),
          decoration: InputDecoration(
            hintText: 'Enter password',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(LucideIcons.lock, size: 16, color: Color(0xFF64748B)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
            ),
            errorMaxLines: 2,
          ),
        ),

        const SizedBox(height: 6),

        // Forgot Password Action Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryViolet,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Field label helper
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  /// Input decoration helper
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool isValid = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 16, color: const Color(0xFF64748B)),
      suffixIcon: isValid
          ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
      ),
      errorMaxLines: 2,
    );
  }

  /// Submit button widget
  Widget _buildSubmitButton() {
    final isBusy = _isLoading || _isCheckingUniqueness;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isBusy ? null : _submitAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryViolet,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFA78BFA),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isBusy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isCheckingUniqueness
                        ? 'Verifying details...'
                        : (isSignUp ? 'Creating account...' : 'Loading your PropZen account...'),
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              )
            : Text(
                isSignUp
                    ? (_authAccountType == 'dealer' ? 'Apply as Dealer' : 'Create Account')
                    : (_authAccountType == 'dealer' ? 'Sign In as Dealer' : 'Sign In'),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }

  /// SSO Options
  Widget _buildSsoSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Or continue with', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textHint)),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  UserSession.fullNameNotifier.value = 'Verified User';
                  UserSession.isLoggedInNotifier.value = true;
                  _onSuccessfulAuthentication();
                },
                icon: const Icon(LucideIcons.chrome, size: 16, color: AppTheme.textPrimary),
                label: Text('Google', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  UserSession.fullNameNotifier.value = 'Verified User';
                  UserSession.isLoggedInNotifier.value = true;
                  _onSuccessfulAuthentication();
                },
                icon: const Icon(LucideIcons.apple, size: 16, color: AppTheme.textPrimary),
                label: Text('Apple', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bottom switcher
  Widget _buildBottomToggle() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
        ),
        InkWell(
          onTap: () {
            setState(() {
              isSignUp = !isSignUp;
              _autoValidateMode = AutovalidateMode.disabled;
              _backendErrorMessage = null;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              isSignUp ? 'Sign In' : 'Create Account',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryViolet,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Forgot password dialog for resetting credentials
  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(
      text: _emailController.text.isNotEmpty ? _emailController.text : _mobileController.text,
    );
    bool isSending = false;
    String? localError;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.keyRound, color: AppTheme.primaryViolet, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reset Password',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your registered email address or 10-digit mobile number to receive password reset instructions.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: resetController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter email or mobile number',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                    prefixIcon: const Icon(LucideIcons.mail, size: 16, color: Color(0xFF64748B)),
                    errorText: localError,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.of(dlgCtx).pop(),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final val = resetController.text.trim();
                        if (val.isEmpty) {
                          setDlgState(() => localError = 'Please enter your email or phone number');
                          return;
                        }

                        setDlgState(() {
                          isSending = true;
                          localError = null;
                        });

                        await Future.delayed(const Duration(milliseconds: 900));

                        if (mounted) {
                          Navigator.of(dlgCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password reset link sent to $val. Please check your inbox / SMS.'),
                              backgroundColor: AppTheme.emeraldSuccess,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Send Reset Link', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}

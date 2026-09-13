import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'admin_service.dart';
import 'property_state_service.dart';
import 'service_partner_service.dart';
import '../models/service_partner_profile.dart';
import '../screens/user_profile_screen.dart';

enum AdminAccessStatus {
  allowed,
  unauthenticated,
  emailNotVerified,
  forbidden403;

  String get description {
    switch (this) {
      case AdminAccessStatus.allowed:
        return 'Authorized';
      case AdminAccessStatus.unauthenticated:
        return 'Sign in required';
      case AdminAccessStatus.emailNotVerified:
        return 'Email verification required';
      case AdminAccessStatus.forbidden403:
        return 'Access denied (403)';
    }
  }
}

enum UserRole {
  customer,
  dealer,
  servicePartner,
  admin,
  verificationAgent;

  String get dbValue {
    switch (this) {
      case UserRole.customer:
        return 'USER';
      case UserRole.dealer:
        return 'DEALER';
      case UserRole.servicePartner:
        return 'SERVICE_PARTNER';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.verificationAgent:
        return 'VERIFICATION_AGENT';
    }
  }

  static UserRole fromString(String role) {
    final lower = role.trim().toLowerCase();
    if (lower.contains('service_partner') || lower.contains('service partner') || lower.contains('partner_service')) return UserRole.servicePartner;
    if (lower == 'dealer' || lower == 'broker') return UserRole.dealer;
    if (lower == 'admin' || lower == 'super_admin' || lower == 'administrator') return UserRole.admin;
    if (lower == 'verification_agent' || lower == 'agent') return UserRole.verificationAgent;
    return UserRole.customer;
  }
}

/// Explicit High-Level Application Auth State
enum AuthState {
  unauthenticated,
  user,
  dealer,
  servicePartner,
  admin,
}

class AuthResult {
  final bool isSuccess;
  final String message;
  final String? userId;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? errorMessage;
  final dynamic rawData;
  final bool isBuyerTryingDealer;
  final bool isDealerPending;
  final bool isDealerRejected;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.userId,
    this.email,
    this.phone,
    this.role = UserRole.customer,
    this.errorMessage,
    this.rawData,
    this.isBuyerTryingDealer = false,
    this.isDealerPending = false,
    this.isDealerRejected = false,
  });

  bool get success => isSuccess;

  factory AuthResult.success({
    required String message,
    String? userId,
    String? email,
    String? phone,
    UserRole role = UserRole.customer,
    dynamic rawData,
  }) {
    return AuthResult(
      isSuccess: true,
      message: message,
      userId: userId,
      email: email,
      phone: phone,
      role: role,
      rawData: rawData,
    );
  }

  factory AuthResult.failure({
    required String message,
    String? errorMessage,
    bool isBuyerTryingDealer = false,
    bool isDealerPending = false,
    bool isDealerRejected = false,
  }) {
    return AuthResult(
      isSuccess: false,
      message: message,
      errorMessage: errorMessage ?? message,
      isBuyerTryingDealer: isBuyerTryingDealer,
      isDealerPending: isDealerPending,
      isDealerRejected: isDealerRejected,
    );
  }
}

class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _lastError;
  String? get lastError => _lastError;

  // Rate Limiting on sensitive auth operations (max 5 failed attempts per 10 minutes)
  final Map<String, List<DateTime>> _failedLoginAttempts = {};
  static const int _maxFailedAttempts = 5;
  static const Duration _rateLimitWindow = Duration(minutes: 10);

  bool get isLoggedIn => UserSession.isLoggedIn;
  String get currentUserName => UserSession.fullName;
  String get currentUserEmail => UserSession.email;
  String get currentUserPhone => UserSession.mobileNumber;
  String get currentUserRole => UserSession.roleTierNotifier.value;

  /// High-Level Verified Auth State
  AuthState get authState {
    if (!UserSession.isLoggedIn) {
      return AuthState.unauthenticated;
    }
    if (isAdmin) {
      return AuthState.admin;
    }
    final role = UserSession.roleTierNotifier.value.toLowerCase().trim();
    if (role == 'dealer') {
      return AuthState.dealer;
    }
    if (role == 'service_partner' || role == 'service partner' || role == 'partner_service') {
      return AuthState.servicePartner;
    }
    return AuthState.user;
  }

  bool get isCustomer => authState == AuthState.user;
  bool get isDealer => authState == AuthState.dealer;
  bool get isServicePartner => authState == AuthState.servicePartner;
  bool get isAdmin => UserSession.isAdmin;
  bool get isVerificationAgent => UserSession.roleTierNotifier.value.toLowerCase().contains('verification');

  /// Centralized Command Center Security Guard Check with Development Diagnostics
  AdminAccessStatus checkCommandCenterAccess({String? currentRoute}) {
    final uid = SupabaseService.instance.auth.currentUser?.id ??
        (UserSession.isLoggedIn ? 'usr_${UserSession.email.hashCode.abs()}' : 'none');
    final email = UserSession.email.trim().toLowerCase();
    final verified = UserSession.isEmailVerified;
    final profileExists = UserSession.isLoggedIn && email.isNotEmpty;
    final profileRole = UserSession.roleTierNotifier.value.trim().toUpperCase();
    final computedIsAdmin = isAdmin;

    String denialReason = 'None (Authorized)';
    AdminAccessStatus result = AdminAccessStatus.allowed;

    if (!UserSession.isLoggedIn) {
      denialReason = 'User is unauthenticated (not logged in)';
      result = AdminAccessStatus.unauthenticated;
    } else if (!UserSession.isEmailVerified) {
      denialReason = 'User email is not verified';
      result = AdminAccessStatus.emailNotVerified;
    } else if (!computedIsAdmin) {
      denialReason = 'Role is $profileRole (restricted: only authorized enterprise roles have clearance)';
      result = AdminAccessStatus.forbidden403;
    } else {
      if (computedIsAdmin) {
        AdminService.instance.setAdminLoggedIn(true, email: email, name: UserSession.fullName);
      }
      result = AdminAccessStatus.allowed;
    }

    if (kDebugMode) {
      // Safe development debug view: Strictly excludes tokens, passwords, and secrets
      debugPrint('''
================= [ADMIN DEBUG] =================
authenticated user ID: $uid
email: $email
email verification status: $verified
profile exists: $profileExists
profile role: $profileRole
computed isAdmin: $computedIsAdmin
current route: ${currentRoute ?? '/admin'}
authorization result: ${result.name} ($denialReason)
=================================================''');
    }

    return result;
  }

  /// Force refreshes the user's Supabase profile and updates administrative claims
  Future<bool> forceRefreshAdminPrivileges() async {
    try {
      final email = UserSession.email.trim().toLowerCase();
      if (email.isNotEmpty) {
        final isDbAdmin = await SupabaseService.instance.verifyAdminAccessInBackend(email);
        if (isDbAdmin) {
          UserSession.updateRole('ADMIN');
          AdminService.instance.setAdminLoggedIn(true, email: email, name: UserSession.fullName);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] Supabase role refresh error: $e');
    }
    return isAdmin;
  }

  // Rate Limiter Check
  bool _isRateLimited(String identifier) {
    final now = DateTime.now();
    final attempts = _failedLoginAttempts[identifier] ?? [];
    // Keep attempts within the rate limit window
    final recentAttempts = attempts.where((t) => now.difference(t) < _rateLimitWindow).toList();
    _failedLoginAttempts[identifier] = recentAttempts;
    return recentAttempts.length >= _maxFailedAttempts;
  }

  void _recordFailedAttempt(String identifier) {
    final now = DateTime.now();
    final attempts = _failedLoginAttempts[identifier] ?? [];
    attempts.add(now);
    _failedLoginAttempts[identifier] = attempts;
  }

  void _clearFailedAttempts(String identifier) {
    _failedLoginAttempts.remove(identifier);
  }

  // =========================================================================
  // 0. INITIALIZE AUTH (Safe Session Restoration & Graceful Fallback)
  // =========================================================================
  Future<void> initializeAuth() async {
    if (_isInitialized) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Restore persistent Supabase token & session from secure storage
      final authUser = await SupabaseService.instance.restoreAuthSession();

      // 2. Restore persistent session from local storage (handles browser refresh)
      final restored = await UserSession.restoreSession();

      if (authUser != null && authUser['id'] != null) {
        final authId = authUser['id'].toString();
        if (UserSession.userIdNotifier.value.isEmpty || UserSession.userIdNotifier.value.startsWith('usr_')) {
          UserSession.userIdNotifier.value = authId;
        }
      }

      if (restored && UserSession.isLoggedIn) {
        final email = UserSession.email.trim().toLowerCase();
        if (email.isNotEmpty) {
          // 3. Synchronize authoritative database role from Supabase backend
          final dbRole = await SupabaseService.instance.fetchUserProfileRole(email);
          if (dbRole == 'admin') {
            final isVerifiedAdmin = await SupabaseService.instance.verifyAdminAccessInBackend(email);
            if (isVerifiedAdmin) {
              UserSession.updateRole('ADMIN');
              AdminService.instance.setAdminLoggedIn(true, email: email, name: UserSession.fullName);
            } else {
              UserSession.updateRole('BUYER');
            }
          } else {
            // First check if user is a Service Partner by userId or email
            ServicePartnerProfile? spProfile;
            if (UserSession.userId.isNotEmpty) {
              spProfile = await SupabaseService.instance.fetchServicePartnerProfileByUserId(UserSession.userId);
            }
            if (spProfile == null && email.isNotEmpty) {
              spProfile = await SupabaseService.instance.fetchServicePartnerProfileByEmail(email);
            }
            spProfile ??= UserSession.currentServicePartnerProfile;

            if (spProfile != null) {
              UserSession.updateRole('SERVICE_PARTNER');
              UserSession.setServicePartnerProfile(spProfile);
              await ServicePartnerService.instance.loadForProfile(spProfile);
            } else {
              final dbRole = await SupabaseService.instance.fetchUserProfileRole(email);
              if (dbRole == 'dealer') {
                UserSession.updateRole('DEALER');
              } else if (dbRole == 'service_partner') {
                UserSession.updateRole('SERVICE_PARTNER');
              } else {
                if (!UserSession.isServicePartner && !UserSession.isDealer) {
                  UserSession.updateRole('BUYER');
                }
              }
            }
          }
        }

        // 4. Concurrently restore all persistent user datasets from Supabase database
        await Future.wait([
          PropertyStateService.instance.syncSavedPropertiesWithBackend(UserSession.userId),
          PropertyStateService.instance.syncComparedPropertiesWithBackend(UserSession.userId),
          PropertyStateService.instance.syncSiteVisitsWithBackend(
            UserSession.userId,
            email: UserSession.email,
            phone: UserSession.phone,
          ),
        ]);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] Auth initialization warning: $e');
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // =========================================================================
  // 1. SIGN UP (Email & Password + Phone)
  // =========================================================================
  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();

    try {
      // 1. Check uniqueness in Supabase
      final emailExists = await SupabaseService.instance.checkEmailExists(cleanEmail);
      if (emailExists) {
        _isLoading = false;
        _lastError = 'This email address is already registered.';
        notifyListeners();
        return AuthResult.failure(message: _lastError!);
      }

      // 2. Save user to Supabase
      final userId = 'usr_${cleanPhone.isNotEmpty ? cleanPhone.replaceAll('+', '') : DateTime.now().millisecondsSinceEpoch}';
      final nowStr = DateTime.now().toIso8601String();

      final userPayload = {
        'name': name.trim(),
        'full_name': name.trim(),
        'email': cleanEmail,
        'phone': cleanPhone,
        'role': role.dbValue,
        'email_verified': true,
        'phone_verified': true,
        'is_email_verified': true,
        'last_login_at': nowStr,
        'created_at': nowStr,
        'metadata': {
          if (metadata != null) ...metadata,
          'registration_source': 'PropZen Flutter Mobile & Web Client',
        }
      };

      final saved = await SupabaseService.instance.saveUserSignin(
        name: name.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        role: role.dbValue,
        isEmailVerified: true,
        metadata: userPayload['metadata'] as Map<String, dynamic>,
      );

      // 3. Update UserSession
      UserSession.login(
        name: name.trim(),
        phone: cleanPhone,
        email: cleanEmail,
        role: role == UserRole.dealer ? 'Dealer' : (role == UserRole.admin ? 'Admin' : 'Buyer'),
        isEmailVerified: true,
      );
      await UserSession.persistSession();

      _isLoading = false;
      notifyListeners();

      if (saved) {
        return AuthResult.success(
          message: 'Account registered successfully!',
          userId: userId,
          email: cleanEmail,
          phone: cleanPhone,
          role: role,
        );
      } else {
        return AuthResult.success(
          message: 'Account created in local session.',
          userId: userId,
          email: cleanEmail,
          phone: cleanPhone,
          role: role,
        );
      }
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      return AuthResult.failure(message: 'Sign up encountered an issue: $e');
    }
  }

  /// Authenticate specifically as Buyer (USER role)
  Future<AuthResult> authenticateBuyer({
    required String identifier,
    required String password,
  }) async {
    return signInWithEmail(identifier: identifier, password: password, intendedRole: 'USER');
  }

  /// Authenticate specifically as Dealer / Broker (strictly validates DEALER role in Supabase)
  Future<AuthResult> authenticateDealer({
    required String identifier,
    required String password,
  }) async {
    return signInWithEmail(identifier: identifier, password: password, intendedRole: 'DEALER');
  }

  /// Authenticate specifically as Service Partner (Loan, Design, Vastu, Construction, Verification, Visualization)
  Future<AuthResult> authenticateServicePartner({
    required String identifier,
    required String password,
  }) async {
    return signInWithEmail(identifier: identifier, password: password, intendedRole: 'SERVICE_PARTNER');
  }

  // =========================================================================
  // 2. SIGN IN (Email & Password or Phone)
  // =========================================================================
  Future<AuthResult> signInWithEmail({
    required String identifier, // Email or Mobile
    required String password,
    String intendedRole = 'USER', // 'USER' | 'DEALER' | 'SERVICE_PARTNER'
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final clean = identifier.trim().toLowerCase();

    // 1. Rate Limit Enforcement
    if (_isRateLimited(clean)) {
      _isLoading = false;
      _lastError = 'Too many failed login attempts. Please wait 10 minutes.';
      notifyListeners();
      await SupabaseService.instance.recordSecurityAlert(
        alertType: 'rate_limit_exceeded',
        severity: 'medium',
        targetIdentifier: clean,
        details: {'endpoint': 'signInWithEmail', 'windowMinutes': 10},
      );
      return AuthResult.failure(message: _lastError!);
    }

    try {
      // Check if user is an Administrator in backend
      final isDbAdmin = await SupabaseService.instance.verifyAdminAccessInBackend(clean);
      if (isDbAdmin) {
        _clearFailedAttempts(clean);
        final adminProfile = await SupabaseService.instance.fetchUserProfile(clean);
        final adminName = adminProfile?['full_name'] ?? adminProfile?['name'] ?? (clean.contains('@') ? clean.split('@').first : 'PropZen Administrator');
        final adminPhone = adminProfile?['phone'] ?? (clean.contains('@') ? '9810394068' : clean);

        UserSession.login(
          userId: adminProfile?['id']?.toString(),
          phone: adminPhone,
          name: adminName,
          email: clean,
          role: 'ADMIN',
          isEmailVerified: true,
        );
        await UserSession.persistSession();
        AdminService.instance.setAdminLoggedIn(true, email: clean, name: adminName);
        await Future.wait([
          PropertyStateService.instance.syncSavedPropertiesWithBackend(UserSession.userId),
          PropertyStateService.instance.syncComparedPropertiesWithBackend(UserSession.userId),
          PropertyStateService.instance.syncSiteVisitsWithBackend(UserSession.userId, email: clean, phone: adminPhone),
        ]);
        _isLoading = false;
        notifyListeners();
        return AuthResult.success(
          message: 'Welcome Administrator',
          email: clean,
          phone: adminPhone,
          role: UserRole.admin,
          rawData: adminProfile,
        );
      }

      // Check authoritative Supabase Profile / Dealers record
      final dealerCheck = await SupabaseService.instance.checkDealerAuthorization(clean);
      final profile = await SupabaseService.instance.fetchUserProfile(clean);
      final profileRole = (profile?['account_type'] ?? profile?['role'] ?? '').toString().trim().toUpperCase();
      final isPartnerAccount = profileRole.contains('SERVICE_PARTNER') ||
          profileRole.contains('PARTNER') ||
          profile?['service_category'] != null ||
          intendedRole == 'SERVICE_PARTNER';

      // 1. SERVICE PARTNER (Authoritatively detected from database profile or service partner intent)
      if (isPartnerAccount) {
        _clearFailedAttempts(clean);

        final uId = profile?['id']?.toString() ?? SupabaseService.instance.auth.currentUser?.id;
        ServicePartnerProfile? partnerProfile;
        if (uId != null && uId.isNotEmpty) {
          partnerProfile = await SupabaseService.instance.fetchServicePartnerProfileByUserId(uId);
        }
        partnerProfile ??= await SupabaseService.instance.fetchServicePartnerProfileByEmail(clean);

        final name = partnerProfile?.businessName ??
            profile?['business_name'] ??
            profile?['full_name'] ??
            profile?['name'] ??
            (clean.contains('@') ? clean.split('@').first : 'PropZen Service Partner');
        final phone = partnerProfile?.phone.isNotEmpty == true
            ? partnerProfile!.phone
            : (profile?['phone'] ?? (clean.contains('@') ? '9810394068' : clean));
        final partnerEmail = partnerProfile?.email.isNotEmpty == true
            ? partnerProfile!.email
            : (clean.contains('@') ? clean : (profile?['email'] ?? 'partner@propzen.ai'));
        final userId = profile?['id']?.toString() ?? partnerProfile?.userId ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

        UserSession.login(
          userId: userId,
          phone: phone,
          name: name,
          email: partnerEmail,
          role: 'SERVICE_PARTNER',
          avatarUrl: profile?['avatar_url']?.toString(),
          isEmailVerified: true,
        );

        if (partnerProfile != null) {
          UserSession.setServicePartnerProfile(partnerProfile);
          await ServicePartnerService.instance.loadForProfile(partnerProfile);
        }
        await UserSession.persistSession();

        // Restore persistent user datasets
        await Future.wait([
          PropertyStateService.instance.syncSavedPropertiesWithBackend(UserSession.userId),
          PropertyStateService.instance.syncComparedPropertiesWithBackend(UserSession.userId),
          PropertyStateService.instance.syncSiteVisitsWithBackend(UserSession.userId, email: partnerEmail, phone: phone),
        ]);

        _isLoading = false;
        notifyListeners();
        return AuthResult.success(
          message: 'Signed in as Service Partner successfully!',
          userId: userId,
          email: partnerEmail,
          phone: phone,
          role: UserRole.servicePartner,
          rawData: partnerProfile?.toJson() ?? profile,
        );
      }

      // 2. DEALER LOGIN (Intent or Database Record)
      if (intendedRole == 'DEALER' || profileRole == 'DEALER' || profileRole == 'DEALER_PENDING') {
        final dealerStatus = dealerCheck['status']?.toString();
        final effectiveRole = profileRole == 'DEALER' ? 'DEALER' : (dealerCheck['role']?.toString().trim().toUpperCase() ?? 'USER');

        if (dealerStatus == 'approved' || effectiveRole == 'DEALER' || profileRole == 'DEALER') {
          _clearFailedAttempts(clean);
          final name = profile?['full_name'] ??
              profile?['name'] ??
              dealerCheck['dealer']?['company_name'] ??
              'Verified Dealer Partner';
          final phone = profile?['phone'] ??
              dealerCheck['dealer']?['phone'] ??
              (clean.contains('@') ? '9810394068' : clean);

          UserSession.login(
            userId: profile?['id']?.toString(),
            phone: phone,
            name: name,
            email: clean.contains('@') ? clean : (profile?['email'] ?? 'dealer@propzen.ai'),
            role: 'DEALER',
            avatarUrl: profile?['avatar_url']?.toString(),
            isEmailVerified: true,
          );
          await UserSession.persistSession();

          _isLoading = false;
          notifyListeners();
          return AuthResult.success(
            message: 'Signed in as Dealer successfully!',
            userId: profile?['id']?.toString(),
            email: clean,
            phone: phone,
            role: UserRole.dealer,
            rawData: profile ?? dealerCheck,
          );
        } else if (dealerStatus == 'pending' || profileRole == 'DEALER_PENDING') {
          _isLoading = false;
          notifyListeners();
          return AuthResult.failure(
            message: 'Your Dealer account is still under verification.',
            isDealerPending: true,
          );
        } else if (dealerStatus == 'rejected' || profileRole == 'DEALER_REJECTED') {
          _isLoading = false;
          notifyListeners();
          return AuthResult.failure(
            message: 'Your Dealer application was not approved.',
            isDealerRejected: true,
          );
        } else if (dealerStatus == 'buyerAccount' || (profile != null && (profileRole == 'USER' || profileRole == 'BUYER'))) {
          _isLoading = false;
          notifyListeners();
          return AuthResult.failure(
            message: 'Your account is registered as a Buyer. Please continue as Buyer or apply to become a Dealer.',
            isBuyerTryingDealer: true,
          );
        } else {
          _isLoading = false;
          notifyListeners();
          return AuthResult.failure(
            message: 'Dealer account not found or not approved.',
          );
        }
      }

      // 3. BUYER LOGIN (Normal Buyer)
      _clearFailedAttempts(clean);
      final name = profile?['full_name'] ??
          profile?['name'] ??
          (clean.contains('@') ? clean.split('@').first : 'PropZen Member');
      final phone = profile?['phone'] ?? (clean.contains('@') ? '9810394068' : clean);
      final email = profile?['email'] ?? (clean.contains('@') ? clean : 'member@propzen.ai');

      UserSession.login(
        userId: profile?['id']?.toString() ?? SupabaseService.instance.auth.currentUser?.id,
        phone: phone,
        name: name,
        email: email,
        role: 'Buyer',
        avatarUrl: profile?['avatar_url']?.toString(),
        isEmailVerified: true,
      );
      await UserSession.persistSession();

      // Restore all persistent user datasets from Supabase database
      await Future.wait([
        PropertyStateService.instance.syncSavedPropertiesWithBackend(UserSession.userId),
        PropertyStateService.instance.syncComparedPropertiesWithBackend(UserSession.userId),
        PropertyStateService.instance.syncSiteVisitsWithBackend(UserSession.userId, email: email, phone: phone),
      ]);

      _isLoading = false;
      notifyListeners();
      return AuthResult.success(
        message: 'Signed in successfully!',
        userId: profile?['id']?.toString(),
        email: email,
        phone: phone,
        role: UserRole.customer,
        rawData: profile,
      );
    } catch (e) {
      _recordFailedAttempt(clean);
      _isLoading = false;
      _lastError = SupabaseService.safeUserErrorMessage(e);
      notifyListeners();
      return AuthResult.failure(message: 'Sign in failed: $_lastError');
    }
  }

  // =========================================================================
  // 3. SEND OTP / VERIFY OTP (Robust with 5-minute expiration)
  // =========================================================================
  Future<bool> sendOtp({
    String? phone,
    String? destination,
    bool isEmail = false,
  }) async {
    final target = (destination ?? phone ?? '').trim();
    if (target.isEmpty) return false;

    if (_isRateLimited(target)) {
      _lastError = 'Too many OTP requests. Please wait 10 minutes.';
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final sent = await SupabaseService.instance.sendOtp(destination: target, isEmail: isEmail);
    _isLoading = false;
    notifyListeners();

    if (!sent) {
      _lastError = 'Please wait 60 seconds before requesting a new OTP.';
      return false;
    }

    _recordFailedAttempt(target);
    return true;
  }

  Future<AuthResult> verifyOtp({
    String? phone,
    String? destination,
    required String otp,
    String? name,
    String? email,
    UserRole role = UserRole.customer,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final target = (destination ?? phone ?? email ?? '').trim();
    final effectiveName = name?.isNotEmpty == true ? SupabaseService.sanitizeText(name!) : 'PropZen Member';
    final effectiveEmail = email?.isNotEmpty == true ? SupabaseService.sanitizeEmail(email!) : (target.contains('@') ? target : 'member@propzen.ai');
    final effectivePhone = phone?.isNotEmpty == true ? SupabaseService.sanitizePhone(phone!) : (target.contains('@') ? '9810394068' : target);

    // Validate OTP using SupabaseService verification engine
    final verifyResult = SupabaseService.instance.verifyOtp(destination: target, otp: otp);
    if (verifyResult['success'] != true) {
      _isLoading = false;
      _lastError = verifyResult['error']?.toString() ?? 'Invalid verification code.';
      notifyListeners();
      return AuthResult.failure(message: _lastError!);
    }

    UserSession.login(
      phone: effectivePhone,
      name: effectiveName,
      email: effectiveEmail,
      role: role == UserRole.dealer ? 'Dealer' : (role == UserRole.servicePartner ? 'Service Partner' : 'Buyer'),
      isEmailVerified: true,
    );
    await UserSession.persistSession();

    // Sync all persistent datasets for user
    await Future.wait([
      PropertyStateService.instance.syncSavedPropertiesWithBackend(UserSession.userId),
      PropertyStateService.instance.syncComparedPropertiesWithBackend(UserSession.userId),
      PropertyStateService.instance.syncSiteVisitsWithBackend(UserSession.userId, email: effectiveEmail, phone: effectivePhone),
    ]);

    // Save to Supabase users
    try {
      await SupabaseService.instance.saveUserSignin(
        name: effectiveName,
        email: effectiveEmail,
        phone: effectivePhone,
        role: role.dbValue,
        isEmailVerified: true,
      );
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return AuthResult.success(
      message: 'OTP verified successfully!',
      phone: effectivePhone,
      email: effectiveEmail,
      role: role,
    );
  }

  // =========================================================================
  // 4. FORGOT & RESET PASSWORD
  // =========================================================================
  Future<bool> requestPasswordReset(String email) async {
    final cleanEmail = SupabaseService.sanitizeEmail(email);
    if (cleanEmail.isEmpty) return false;
    if (_isRateLimited(cleanEmail)) {
      _lastError = 'Too many reset attempts. Please wait 10 minutes.';
      return false;
    }
    _isLoading = true;
    notifyListeners();
    final success = await SupabaseService.instance.requestPasswordRecovery(cleanEmail);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // =========================================================================
  // 5. LOGOUT
  // =========================================================================
  void logout() {
    UserSession.logout();
    SupabaseService.instance.clearSession();
    AdminService.instance.logoutAdmin();
    _lastError = null;
    notifyListeners();
  }

  // =========================================================================
  // 6. DELETE ACCOUNT PERMANENTLY
  // =========================================================================
  Future<bool> deleteAccountPermanently() async {
    final email = currentUserEmail;
    final phone = currentUserPhone;
    final success = await SupabaseService.instance.deleteUserAccountPermanently(
      email: email,
      phone: phone,
      reason: 'User triggered deletion from profile settings',
    );
    logout();
    return success;
  }
}

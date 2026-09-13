import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../services/admin_service.dart';
import 'my_enquiries_screen.dart';
import 'my_service_requests_screen.dart';
import 'my_site_visits_screen.dart';
import 'wishlist_screen.dart';
import 'property_compare_screen.dart';
import 'settings_screen.dart';
import 'legal_hub_screen.dart';
import 'help_support_screen.dart';
import 'dealer_dashboard_screen.dart';
import 'dual_auth_screen.dart';
import '../services/supabase_service.dart';
import '../services/deal_room_service.dart';
import '../services/post_visit_retention_service.dart';
import 'buyer_requirements_screen.dart';
import 'property_visit_planner_screen.dart';
import 'deal_room_screen.dart';
import 'ai_property_rematch_screen.dart';
import '../models/nri_subscription_model.dart';
import 'admin_panel_screen.dart';
import 'nri_remote_dashboard_screen.dart';
import '../widgets/my_payments_modal.dart';
import 'drone_tour_subscription_screen.dart';
import '../widgets/floating_social_buttons.dart';
import '../models/drone_tour_subscription_model.dart';
import '../services/dealer_subscription_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/profile_image_picker_service.dart';
import '../widgets/profile_image_preview_dialog.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/service_partner_service.dart';
import '../models/service_partner_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

// =============================================================================
// USER SESSION STATE HOLDER (PRESERVED FUNCTIONALITY)
// =============================================================================

class UserSession {
  static final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> userIdNotifier = ValueNotifier<String>('');
  static final ValueNotifier<String> fullNameNotifier = ValueNotifier<String>('');
  static final ValueNotifier<String> phoneNotifier = ValueNotifier<String>('');
  static final ValueNotifier<String> emailNotifier = ValueNotifier<String>('');
  static final ValueNotifier<bool> isEmailVerifiedNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> roleTierNotifier = ValueNotifier<String>('Buyer');
  static final ValueNotifier<String?> avatarUrlNotifier = ValueNotifier<String?>(null);

  // NRI Residency & Subscription State
  static final ValueNotifier<String> userTypeNotifier = ValueNotifier<String>('Indian Resident');
  static final ValueNotifier<String> userCountryNotifier = ValueNotifier<String>('India');
  static final ValueNotifier<NriSubscription?> nriSubscriptionNotifier = ValueNotifier<NriSubscription?>(null);

  // Drone Tour Subscription State
  static final ValueNotifier<DroneTourSubscription?> droneSubscriptionNotifier =
      ValueNotifier<DroneTourSubscription?>(null);

  // Service Partner Profile State
  static final ValueNotifier<ServicePartnerProfile?> servicePartnerProfileNotifier =
      ValueNotifier<ServicePartnerProfile?>(null);
  static ServicePartnerProfile? get currentServicePartnerProfile => servicePartnerProfileNotifier.value;
  static set currentServicePartnerProfile(ServicePartnerProfile? profile) {
    servicePartnerProfileNotifier.value = profile;
    ServicePartnerService.instance.setCurrentProfile(profile);
  }
  static void setServicePartnerProfile(ServicePartnerProfile? profile) {
    servicePartnerProfileNotifier.value = profile;
    ServicePartnerService.instance.setCurrentProfile(profile);
    persistSession().catchError((_) {});
  }

  // Alias getters
  static ValueNotifier<String> get mobileNumberNotifier => phoneNotifier;
  static String get userId => userIdNotifier.value.isNotEmpty
      ? userIdNotifier.value
      : (email.isNotEmpty ? 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}' : 'usr_propzen');
  static String get fullName => fullNameNotifier.value;
  static String get mobileNumber => phoneNotifier.value;
  static String get phone => phoneNotifier.value;
  static String get email => emailNotifier.value;
  static String? get avatarUrl => avatarUrlNotifier.value;
  static set avatarUrl(String? url) => avatarUrlNotifier.value = url;
  static bool get isLoggedIn => isLoggedInNotifier.value;
  static bool get isEmailVerified => isEmailVerifiedNotifier.value;
  static bool get isAuthenticated => isLoggedIn && isEmailVerified;
  static String get userType => userTypeNotifier.value;
  static String get userCountry => userCountryNotifier.value;
  static bool get isNri => userTypeNotifier.value.toLowerCase().trim().contains('nri');
  static DroneTourSubscription? get droneSubscription => droneSubscriptionNotifier.value;
  static NriSubscription? get nriSubscription => nriSubscriptionNotifier.value;

  /// Strict Drone Tour Access
  static bool get hasActiveDroneAccess {
    final droneSub = droneSubscriptionNotifier.value;
    if (droneSub != null &&
        droneSub.status.toLowerCase().trim() == 'active' &&
        droneSub.isActive) {
      return true;
    }
    final nriSub = nriSubscriptionNotifier.value;
    if (nriSub != null &&
        nriSub.status.toLowerCase().trim() == 'active' &&
        nriSub.isActive &&
        (nriSub.tier == 'premium' || nriSub.tier == 'elite')) {
      return true;
    }
    return false;
  }

  /// The single authorized administrator email for PropZen
  static const String designatedAdminEmail = 'dubeysakshi618@gmail.com';

  /// Check if the current user has an admin role (strictly verified via authoritative server role)
  static bool get isAdmin {
    if (!isLoggedIn) return false;
    final role = roleTierNotifier.value.toLowerCase().trim();
    return role == 'admin' || role == 'super admin' || role == 'super_admin' || role == 'administrator';
  }

  /// Strictly checks if the user's role is DEALER
  static bool get isDealer {
    final role = roleTierNotifier.value.toUpperCase().trim();
    return role == 'DEALER' || role == 'VERIFIED DEALER' || role == 'APPROVED_DEALER';
  }

  /// Checks if current session is authorized for enterprise CRM access
  static bool get isCrmAuthorized {
    if (!isLoggedIn) return false;
    if (isAdmin) return true;
    if (isDealer) return true;
    final r = roleTierNotifier.value.toUpperCase().trim();
    return r == 'ADMIN' || r == 'DEALER' || r == 'STAFF' || r == 'CRM_MANAGER' || r == 'CRM_AGENT';
  }

  /// Check if dealer account is pending verification
  static bool get isPendingDealer {
    final role = roleTierNotifier.value.toUpperCase().trim();
    return role == 'DEALER_PENDING' || role == 'PENDING' || role == 'UNDER_REVIEW';
  }

  /// Strictly checks if the user's role is SERVICE_PARTNER
  static bool get isServicePartner {
    final role = roleTierNotifier.value.toUpperCase().trim();
    return role == 'SERVICE_PARTNER' || role == 'SERVICE PARTNER' || role == 'PARTNER_SERVICE' || role == 'SERVICE';
  }

  /// Check if service partner account is pending verification
  static bool get isPendingServicePartner {
    final role = roleTierNotifier.value.toUpperCase().trim();
    if (role == 'SERVICE_PARTNER_PENDING') return true;
    final sp = currentServicePartnerProfile;
    if (sp != null && (sp.status.toLowerCase() == 'pending' || sp.verificationStatus.toLowerCase() == 'pending')) {
      return true;
    }
    return false;
  }

  /// Checks if user is a normal Buyer
  static bool get isBuyer {
    if (isDealer || isPendingDealer || isServicePartner || isAdmin) return false;
    final role = roleTierNotifier.value.toUpperCase().trim();
    return role == 'USER' || role == 'BUYER' || role.isEmpty || role == 'NRI BUYER' || role == 'CUSTOMER';
  }

  /// Strictly checks if the authenticated user has explicitly a Buyer role.
  /// Returns false for unauthenticated/guest users, dealers, service partners, and admins.
  static bool get isExplicitBuyer {
    if (!isLoggedIn) return false;
    if (isAdmin) return false;
    if (isDealer || isPendingDealer) return false;
    if (isServicePartner) return false;
    final role = roleTierNotifier.value.toUpperCase().trim();
    return role == 'USER' || role == 'BUYER' || role == 'CUSTOMER' || role == 'NRI BUYER';
  }

  static String get dealerId {
    if (phone.isNotEmpty) {
      final sanitized = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (sanitized.isNotEmpty) return 'DLR-$sanitized';
    }
    if (email.isNotEmpty) {
      return 'DLR-${email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    }
    if (fullName.isNotEmpty && fullName != 'Guest User') {
      return 'DLR-${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    }
    return '';
  }

  static String get servicePartnerId {
    if (currentServicePartnerProfile != null) {
      return currentServicePartnerProfile!.id;
    }
    if (phone.isNotEmpty) {
      final sanitized = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (sanitized.isNotEmpty) return 'SP-$sanitized';
    }
    if (email.isNotEmpty) {
      return 'SP-${email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    }
    if (fullName.isNotEmpty && fullName != 'Guest User') {
      return 'SP-${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    }
    return 'SP-default';
  }

  static void registerAsDealer({
    String? agencyName,
    String? phone,
    String? email,
    String? reraNumber,
  }) {
    if (agencyName != null && agencyName.trim().isNotEmpty && (fullName.isEmpty || fullName == 'Guest User')) {
      fullNameNotifier.value = agencyName.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      phoneNotifier.value = phone.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      emailNotifier.value = email.trim();
    }
    // Submissions are PENDING until approved by admin
    roleTierNotifier.value = 'DEALER_PENDING';
    isLoggedInNotifier.value = true;
    isEmailVerifiedNotifier.value = true;
    _sessionCreatedAt = DateTime.now();
    persistSession().catchError((_) {});

    try {
      SupabaseService.instance.saveUserSignin(
        name: fullNameNotifier.value.isNotEmpty ? fullNameNotifier.value : 'Dealer Applicant',
        email: emailNotifier.value,
        phone: phoneNotifier.value,
        role: 'DEALER_PENDING',
        isEmailVerified: true,
      );
    } catch (_) {}
  }

  static void login({
    String? userId,
    String? name,
    String? fullName,
    String? mobile,
    String? phone,
    String? email,
    String? userEmail,
    String? role,
    String? avatarUrl,
    bool isEmailVerified = true,
  }) {
    if (userId != null && userId.isNotEmpty) {
      userIdNotifier.value = userId;
    } else if (userIdNotifier.value.isEmpty) {
      final cleanEmail = (userEmail ?? email ?? '').trim().toLowerCase();
      if (cleanEmail.isNotEmpty) {
        userIdNotifier.value = 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
      }
    }
    fullNameNotifier.value = (name ?? fullName ?? '').trim();
    phoneNotifier.value = (phone ?? mobile ?? '').trim();
    final cleanEmail = (userEmail ?? email ?? '').trim().toLowerCase();
    emailNotifier.value = cleanEmail;
    final rawRole = (role != null && role.isNotEmpty) ? role.trim() : 'Buyer';
    if (rawRole.toUpperCase() == 'ADMIN' && !AdminService.instance.isAdminLoggedIn) {
      roleTierNotifier.value = 'Buyer';
    } else {
      roleTierNotifier.value = rawRole;
    }
    if (avatarUrl != null) {
      avatarUrlNotifier.value = avatarUrl;
    }
    isLoggedInNotifier.value = true;
    isEmailVerifiedNotifier.value = isEmailVerified;
    _sessionCreatedAt = DateTime.now();
    persistSession().catchError((_) {});

    if (fullNameNotifier.value.isNotEmpty || emailNotifier.value.isNotEmpty) {
      try {
        SupabaseService.instance.saveUserSignin(
          userId: userIdNotifier.value,
          name: fullNameNotifier.value,
          email: emailNotifier.value,
          phone: phoneNotifier.value,
          role: roleTierNotifier.value,
          isEmailVerified: isEmailVerified,
          metadata: servicePartnerProfileNotifier.value != null
              ? {
                  'account_type': 'SERVICE_PARTNER',
                  'business_name': servicePartnerProfileNotifier.value!.businessName,
                  'service_category': servicePartnerProfileNotifier.value!.serviceCategory,
                  'service_categories': servicePartnerProfileNotifier.value!.serviceCategories,
                  'verification_status': servicePartnerProfileNotifier.value!.verificationStatus,
                  'status': servicePartnerProfileNotifier.value!.status,
                }
              : null,
        );
      } catch (_) {}
    }
  }

  static void updateRole(String role) {
    if (role.isNotEmpty) {
      if (role.trim().toUpperCase() == 'ADMIN' && !AdminService.instance.isAdminLoggedIn) {
        roleTierNotifier.value = 'Buyer';
      } else {
        roleTierNotifier.value = role;
      }
      persistSession().catchError((_) {});
    }
  }

  static DateTime? _sessionCreatedAt;
  static String? _sessionToken;

  static DateTime? get sessionCreatedAt => _sessionCreatedAt;
  static String? get sessionToken => _sessionToken;
  static bool get isSessionExpired {
    if (_sessionCreatedAt == null) return false;
    return DateTime.now().difference(_sessionCreatedAt!).inDays >= 30;
  }

  static bool _globalMockInitialized = false;
  static Future<SharedPreferences?> safePrefs() async {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST') && !_globalMockInitialized) {
        try {
          // ignore: invalid_use_of_visible_for_testing_member
          SharedPreferences.setMockInitialValues({});
          _globalMockInitialized = true;
        } catch (_) {}
      }
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
  static Future<SharedPreferences?> _safePrefs() => safePrefs();

  /// Persist session to local storage for cross-refresh persistence
  static Future<void> persistSession() async {
    try {
      final prefs = await _safePrefs();
      if (prefs == null) return;
      await prefs.setBool('propzen_is_logged_in', isLoggedInNotifier.value);
      await prefs.setString('propzen_user_id', userIdNotifier.value);
      await prefs.setString('propzen_full_name', fullNameNotifier.value);
      await prefs.setString('propzen_phone', phoneNotifier.value);
      await prefs.setString('propzen_email', emailNotifier.value);
      await prefs.setBool('propzen_email_verified', isEmailVerifiedNotifier.value);
      await prefs.setString('propzen_role_tier', roleTierNotifier.value);
      if (avatarUrlNotifier.value != null) {
        await prefs.setString('propzen_avatar_url', avatarUrlNotifier.value!);
      } else {
        await prefs.remove('propzen_avatar_url');
      }
      await prefs.setString('propzen_user_type', userTypeNotifier.value);
      await prefs.setString('propzen_user_country', userCountryNotifier.value);
      if (servicePartnerProfileNotifier.value != null) {
        await prefs.setString(
          'propzen_service_partner_profile',
          jsonEncode(servicePartnerProfileNotifier.value!.toJson()),
        );
      } else {
        await prefs.remove('propzen_service_partner_profile');
      }
      if (_sessionCreatedAt != null) {
        await prefs.setInt('propzen_session_created_at', _sessionCreatedAt!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('[UserSession] persistSession error: $e');
    }
  }

  /// Restore session from local storage on app startup
  static Future<bool> restoreSession() async {
    try {
      final prefs = await _safePrefs();
      if (prefs == null) return false;
      final isLoggedIn = prefs.getBool('propzen_is_logged_in') ?? false;
      if (!isLoggedIn) return false;

      final sessionMs = prefs.getInt('propzen_session_created_at');
      if (sessionMs != null) {
        _sessionCreatedAt = DateTime.fromMillisecondsSinceEpoch(sessionMs);
        if (isSessionExpired) {
          await clearPersistentSession();
          return false;
        }
      } else {
        _sessionCreatedAt = DateTime.now();
      }

      final savedUid = prefs.getString('propzen_user_id') ?? '';
      final restoredEmail = (prefs.getString('propzen_email') ?? '').trim().toLowerCase();
      if (savedUid.isNotEmpty) {
        userIdNotifier.value = savedUid;
      } else if (restoredEmail.isNotEmpty) {
        userIdNotifier.value = 'usr_${restoredEmail.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
      } else {
        userIdNotifier.value = '';
      }
      fullNameNotifier.value = prefs.getString('propzen_full_name') ?? '';
      phoneNotifier.value = prefs.getString('propzen_phone') ?? '';
      emailNotifier.value = restoredEmail;
      isEmailVerifiedNotifier.value = prefs.getBool('propzen_email_verified') ?? false;
      final savedRole = prefs.getString('propzen_role_tier') ?? 'Buyer';
      roleTierNotifier.value = savedRole;
      avatarUrlNotifier.value = prefs.getString('propzen_avatar_url');
      userTypeNotifier.value = prefs.getString('propzen_user_type') ?? 'Indian Resident';
      userCountryNotifier.value = prefs.getString('propzen_user_country') ?? 'India';

      final spJson = prefs.getString('propzen_service_partner_profile');
      if (spJson != null) {
        try {
          final profile = ServicePartnerProfile.fromJson(jsonDecode(spJson) as Map<String, dynamic>);
          servicePartnerProfileNotifier.value = profile;
          ServicePartnerService.instance.setCurrentProfile(profile);
        } catch (e) {
          debugPrint('[UserSession] Error restoring service partner profile: $e');
        }
      }

      isLoggedInNotifier.value = true;
      return true;
    } catch (e) {
      debugPrint('[UserSession] restoreSession error: $e');
      return false;
    }
  }

  /// Clear persistent session from local storage on logout
  static Future<void> clearPersistentSession() async {
    try {
      final prefs = await _safePrefs();
      if (prefs == null) return;
      await prefs.remove('propzen_is_logged_in');
      await prefs.remove('propzen_user_id');
      await prefs.remove('propzen_full_name');
      await prefs.remove('propzen_phone');
      await prefs.remove('propzen_email');
      await prefs.remove('propzen_email_verified');
      await prefs.remove('propzen_role_tier');
      await prefs.remove('propzen_avatar_url');
      await prefs.remove('propzen_user_type');
      await prefs.remove('propzen_user_country');
      await prefs.remove('propzen_service_partner_profile');
      await prefs.remove('propzen_session_created_at');
    } catch (e) {
      debugPrint('[UserSession] clearPersistentSession error: $e');
    }
  }

  static void setUserType(String type, {String country = 'India'}) {
    userTypeNotifier.value = type;
    userCountryNotifier.value = country;
    persistSession().catchError((_) {});
  }

  static void setNriSubscription(NriSubscription? subscription) {
    nriSubscriptionNotifier.value = subscription;
  }
  static void updateNriSubscription(NriSubscription? sub) => setNriSubscription(sub);

  static void setDroneSubscription(DroneTourSubscription? subscription) {
    droneSubscriptionNotifier.value = subscription;
  }
  static void updateDroneSubscription(DroneTourSubscription? sub) => setDroneSubscription(sub);

  static void logout() {
    isLoggedInNotifier.value = false;
    isEmailVerifiedNotifier.value = false;
    userIdNotifier.value = '';
    fullNameNotifier.value = '';
    phoneNotifier.value = '';
    emailNotifier.value = '';
    avatarUrlNotifier.value = null;
    roleTierNotifier.value = 'Buyer';
    userTypeNotifier.value = 'Indian Resident';
    userCountryNotifier.value = 'India';
    nriSubscriptionNotifier.value = null;
    droneSubscriptionNotifier.value = null;
    servicePartnerProfileNotifier.value = null;
    _sessionCreatedAt = null;
    _sessionToken = null;
    clearPersistentSession().catchError((_) {});
    try {
      SupabaseService.instance.clearSession();
    } catch (_) {}
    try {
      AdminService.instance.logoutAdmin();
    } catch (_) {}
    try {
      DealerSubscriptionService.instance.resetToNone();
    } catch (_) {}
    try {
      ServicePartnerService.instance.resetState();
    } catch (_) {}
    try {
      PropertyStateService.instance.clearSavedProperties();
    } catch (_) {}
    try {
      PropertyStateService.instance.clearCompare();
    } catch (_) {}
    try {
      PropertyStateService.instance.clearScheduledVisits();
    } catch (_) {}
  }

  static void clear() => logout();
  static void clearSession() => logout();

  static void setUser({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) {
    login(name: name, email: email, phone: phone, role: role);
  }

  static void verifyEmail() {
    isEmailVerifiedNotifier.value = true;
  }
}

// =============================================================================
// REDESIGNED LUXURY PROFILE PAGE WIDGET
// =============================================================================

class UserProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final Function(int)? onNavigateTab;

  const UserProfileScreen({super.key, this.onBackToHome, this.onNavigateTab});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  bool _isUploadingPhoto = false;

  void _showPhotoOptionsModal() {
    final hasPhoto = UserSession.avatarUrl != null && UserSession.avatarUrl!.isNotEmpty;
    final isCameraSupported = ProfileImagePickerService.instance.isCameraSupported;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Change Profile Picture',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG or WEBP • Maximum size 5 MB',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Option: Take Photo (when supported)
                if (isCameraSupported) ...[
                  _buildPhotoOptionTile(
                    icon: LucideIcons.camera,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Take Photo',
                    subtitle: 'Use camera to take a new picture',
                    onTap: () {
                      Navigator.of(modalCtx).pop();
                      _pickAndUploadPhoto(source: 'camera');
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // Option: Upload from device
                _buildPhotoOptionTile(
                  icon: LucideIcons.uploadCloud,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Upload from device',
                  subtitle: 'Select from your photos or device files',
                  onTap: () {
                    Navigator.of(modalCtx).pop();
                    _pickAndUploadPhoto(source: 'device');
                  },
                ),

                // Option: Remove Photo (only visible if user already has a photo)
                if (hasPhoto) ...[
                  const SizedBox(height: 10),
                  _buildPhotoOptionTile(
                    icon: LucideIcons.trash2,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Remove Photo',
                    subtitle: 'Reset to default initials avatar',
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(modalCtx).pop();
                      _confirmRemovePhoto();
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(modalCtx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive ? const Color(0xFFFEE2E2) : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto({String source = 'device'}) async {
    try {
      final picker = ProfileImagePickerService.instance;
      final PickedImageResult? result = (source == 'camera')
          ? await picker.captureImageFromCamera()
          : await picker.pickImageFromDevice();

      if (result == null) return; // User cancelled

      if (!result.isSuccess || result.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Unable to select image.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show interactive circular crop & preview dialog
      await ProfileImagePreviewDialog.show(
        context,
        imageBytes: result.bytes!,
        fileName: result.fileName ?? 'avatar.jpg',
      );
    } catch (e) {
      debugPrint('[UserProfileScreen] _pickAndUploadPhoto error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _confirmRemovePhoto() {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove your profile picture?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'This will restore your default initials avatar.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(confirmCtx).pop();
              _removePhoto();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final userIdentifier = UserSession.email.isNotEmpty
          ? UserSession.email
          : (UserSession.phone.isNotEmpty ? UserSession.phone : 'propzen_user');
      final authUser = SupabaseService.instance.auth.currentUser;
      final effectiveUserId = (authUser != null && authUser.id.isNotEmpty)
          ? authUser.id
          : userIdentifier.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      // 1. Delete from Supabase Storage
      await SupabaseStorageService.instance.deleteAvatarForUser(effectiveUserId);

      // 2. Remove avatar_url from database
      if (userIdentifier.isNotEmpty) {
        await SupabaseService.instance.removeUserAvatarUrl(userIdentifier);
      }

      // 3. Reset local session notifier
      UserSession.avatarUrlNotifier.value = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed.'),
            backgroundColor: Color(0xFF64748B),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[UserProfileScreen] _removePhoto error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to remove profile picture. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _navigateToSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DualAuthScreen(
          initialSignUp: false,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: UserSession.fullName);
    final emailCtrl = TextEditingController(text: UserSession.email);
    final phoneCtrl = TextEditingController(text: UserSession.mobileNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.edit3, color: Color(0xFF7C3AED), size: 18),
            ),
            const SizedBox(width: 10),
            Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(LucideIcons.user, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(LucideIcons.mail, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(LucideIcons.phone, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                UserSession.fullNameNotifier.value = nameCtrl.text.trim();
              }
              if (emailCtrl.text.trim().isNotEmpty) {
                UserSession.emailNotifier.value = emailCtrl.text.trim();
              }
              if (phoneCtrl.text.trim().isNotEmpty) {
                UserSession.phoneNotifier.value = phoneCtrl.text.trim();
              }
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Profile updated successfully!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 650 && screenWidth < 1024;
    final isMobile = screenWidth < 650;

    return AnimatedBuilder(
      animation: _stateService,
      builder: (context, _) {
        final savedCount = _stateService.savedPropertyIds.length;
        final comparedCount = _stateService.comparedPropertyIds.length;
        final visitsCount = _stateService.scheduledVisits.length;
        final leadsCount = _stateService.leads.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildHeaderBar(context),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Premium Profile Hero Section
                        _buildHeroCard(context, isDesktop),

                        const SizedBox(height: 24),

                        // 2. Profile Statistics (4 Cards)
                        _buildStatisticsSection(
                          context,
                          savedCount: savedCount,
                          visitsCount: visitsCount,
                          comparedCount: comparedCount,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        ),

                        const SizedBox(height: 24),

                        // 3. Go Premium Luxury Banner Card
                        _buildGoPremiumCard(context),

                        const SizedBox(height: 24),

                        // 4. Residency Status + Drone Subscription Split Card
                        _buildResidencyAndDroneCard(context, isDesktop),

                        const SizedBox(height: 24),

                        // 5. My Property Journey (10 Milestones - strictly for authenticated Buyers)
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            UserSession.isLoggedInNotifier,
                            UserSession.roleTierNotifier,
                          ]),
                          builder: (ctx, _) {
                            if (!UserSession.isExplicitBuyer) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildPropertyJourneySection(
                                context,
                                visitsCount: visitsCount,
                                savedCount: savedCount,
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                            );
                          },
                        ),

                        // 6. Role-Based Partner / Dealer Section (Shown only for Verified Dealers)
                        _buildDealerPartnerCard(context),

                        // 6b. Role-Based Service Partner Section (Shown only for Service Partners)
                        _buildServicePartnerCard(context),

                        // 7. PropZen Command Center Card (Strictly for ADMIN)
                        ValueListenableBuilder<String>(
                          valueListenable: UserSession.roleTierNotifier,
                          builder: (ctx, _, __) {
                            if (!UserSession.isAdmin) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildAdminCommandCenterCard(context),
                            );
                          },
                        ),

                        // 8. AI Real Estate Tools & Account Services
                        _buildAccountServicesSection(
                          context,
                          leadsCount: leadsCount,
                          visitsCount: visitsCount,
                          savedCount: savedCount,
                          comparedCount: comparedCount,
                        ),

                        const SizedBox(height: 24),

                        // 9. Bottom Session Actions
                        _buildBottomSessionAction(context),

                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ),

              // 10. Floating Contact Action Buttons (Bottom-Right)
              Positioned(
                bottom: isMobile ? 16.0 : 24.0,
                right: isMobile ? 16.0 : 22.0,
                child: const FloatingSocialButtons(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. HEADER BAR
  // ===========================================================================

  PreferredSizeWidget _buildHeaderBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: isCompact ? 16 : 24,
      title: Text(
        'Profile',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: isCompact ? 12 : 20),
          child: Center(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.settings, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text(
                      isCompact ? 'Settings' : 'Account Settings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. PREMIUM PROFILE HERO CARD
  // ===========================================================================

  Widget _buildHeroCard(BuildContext context, bool isDesktop) {
    return ValueListenableBuilder<bool>(
      valueListenable: UserSession.isLoggedInNotifier,
      builder: (context, isLoggedIn, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isDesktop ? 28 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: isLoggedIn
              ? _buildAuthenticatedHero(context, isDesktop)
              : _buildUnauthenticatedHero(context, isDesktop),
        );
      },
    );
  }

  Widget _buildUnauthenticatedHero(BuildContext context, bool isDesktop) {
    final avatar = Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF7C3AED),
        ),
        child: const Center(
          child: Icon(LucideIcons.user, color: Colors.white, size: 30),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome to PropZen',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to access your shortlisted properties, verified documents & scheduled site tours.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );

    final signInBtn = ElevatedButton.icon(
      onPressed: _navigateToSignIn,
      icon: const Icon(LucideIcons.logIn, size: 16, color: Colors.white),
      label: Text(
        'Sign In / Create Account',
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          avatar,
          const SizedBox(width: 20),
          Expanded(child: details),
          const SizedBox(width: 20),
          signInBtn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(child: details),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: signInBtn),
      ],
    );
  }

  Widget _buildAuthenticatedHero(BuildContext context, bool isDesktop) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        UserSession.fullNameNotifier,
        UserSession.roleTierNotifier,
        UserSession.servicePartnerProfileNotifier,
      ]),
      builder: (ctx, _) {
        final name = UserSession.fullNameNotifier.value;
        final displayName = name.isNotEmpty
            ? name
            : (UserSession.isAdmin
                ? 'PropZen Administrator'
                : (UserSession.isServicePartner
                    ? (UserSession.currentServicePartnerProfile?.businessName.isNotEmpty == true
                        ? UserSession.currentServicePartnerProfile!.businessName
                        : 'PropZen Service Partner')
                    : 'Propzen Member'));
        final displayEmail = UserSession.email.isNotEmpty
            ? UserSession.email
            : 'member@propzen.ai';
        final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

        final avatar = ValueListenableBuilder<String?>(
          valueListenable: UserSession.avatarUrlNotifier,
          builder: (ctx, avatarUrl, _) {
            final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF7C3AED),
                              child: Center(
                                child: Text(
                                  initialLetter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initialLetter,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Subtle loading overlay when uploading
                if (_isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Camera / Edit Photo Button Overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Tooltip(
                    message: 'Change profile photo',
                    child: Semantics(
                      label: 'Change profile picture',
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isUploadingPhoto ? null : _showPhotoOptionsModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );

        final userDetails = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Role Badge
                if (UserSession.isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Admin',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6D28D9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (UserSession.isDealer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Dealer / Broker',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6D28D9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (UserSession.isPendingDealer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Dealer Applicant • Under Review',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (UserSession.isServicePartner) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.briefcase, size: 11, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          UserSession.currentServicePartnerProfile != null &&
                                  UserSession.currentServicePartnerProfile!.serviceCategory.isNotEmpty
                              ? 'Service Partner • ${UserSession.currentServicePartnerProfile!.serviceCategory.replaceAll('_', ' ')}'
                              : 'Service Partner',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (UserSession.isPendingServicePartner) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Service Partner • Under Review',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  Builder(
                    builder: (ctx) {
                      final rawRole = UserSession.roleTierNotifier.value.trim();
                      final upper = rawRole.toUpperCase();
                      final isPartner = upper.contains('SERVICE_PARTNER') || upper.contains('PARTNER');
                      final isDlr = upper.contains('DEALER');
                      final isAdm = upper.contains('ADMIN');
                      final badgeText = isPartner
                          ? 'Service Partner'
                          : (isDlr
                              ? 'Dealer'
                              : (isAdm
                                  ? 'Admin'
                                  : (rawRole.isNotEmpty ? rawRole : 'Buyer')));

                      final badgeColor = isPartner
                          ? const Color(0xFF0284C7)
                          : (isDlr
                              ? const Color(0xFF7C3AED)
                              : (isAdm
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFF64748B)));

                      final textColor = isPartner
                          ? const Color(0xFF0369A1)
                          : (isDlr
                              ? const Color(0xFF6D28D9)
                              : (isAdm
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFF334155)));

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                ],
                // Verified Account Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCheck, size: 11, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayEmail,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 3),
            Text(
              'Member since 2026 • Verified Platform Account',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        );

        final membershipBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF2E1065)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A1E1B4B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.crown, color: Color(0xFFFBBF24), size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'PropZen Elite',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Unlimited Access • All tools unlocked',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFC7D2FE)),
                  ),
                ],
              ),
            ],
          ),
        );

        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(LucideIcons.edit3, size: 14, color: Color(0xFF7C3AED)),
              label: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
              onPressed: () {
                UserSession.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully.'), backgroundColor: Color(0xFFEF4444)),
                );
              },
            ),
          ],
        );

        if (isDesktop) {
          return Row(
            children: [
              avatar,
              const SizedBox(width: 20),
              Expanded(child: userDetails),
              const SizedBox(width: 20),
              membershipBadge,
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: userDetails),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                membershipBadge,
                actionButtons,
              ],
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // 3. PROFILE STATISTICS SECTION (4 CARDS)
  // ===========================================================================

  Widget _buildStatisticsSection(
    BuildContext context, {
    required int savedCount,
    required int visitsCount,
    required int comparedCount,
    required bool isDesktop,
    required bool isTablet,
  }) {
    final cards = [
      _buildStatCard(
        title: 'Saved Properties',
        value: '$savedCount',
        subtitle: 'Shortlisted Deals',
        icon: LucideIcons.heart,
        iconColor: const Color(0xFFEC4899),
        iconBgColor: const Color(0xFFFCE7F3),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const WishlistScreen())),
      ),
      _buildStatCard(
        title: 'Site Visits',
        value: '$visitsCount',
        subtitle: 'Scheduled Tours',
        icon: LucideIcons.calendarCheck,
        iconColor: const Color(0xFF10B981),
        iconBgColor: const Color(0xFFD1FAE5),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const MySiteVisitsScreen())),
      ),
      _buildStatCard(
        title: 'Compared Properties',
        value: '$comparedCount',
        subtitle: 'Side-by-Side Analysis',
        icon: LucideIcons.scale,
        iconColor: const Color(0xFF7C3AED),
        iconBgColor: const Color(0xFFEDE9FE),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PropertyCompareScreen())),
      ),
      _buildStatCard(
        title: 'Premium Status',
        value: 'Active Elite',
        subtitle: 'View Plans',
        icon: LucideIcons.crown,
        iconColor: const Color(0xFFF59E0B),
        iconBgColor: const Color(0xFFFEF3C7),
        isStatusCard: true,
        onTap: () => DroneTourSubscriptionScreen.show(context),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    // 2x2 Grid on Tablet / Mobile
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                child: card,
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    bool isStatusCard = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Icon(LucideIcons.arrowUpRight, size: 15, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isStatusCard ? 16 : 22,
                fontWeight: FontWeight.bold,
                color: isStatusCard ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. GO PREMIUM CTA CARD
  // ===========================================================================

  Widget _buildGoPremiumCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF6B21A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x203B0764),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Color(0xFFFBBF24), size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Go Premium',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock exclusive benefits: HD 4K aerial drone tours, AI deal room access, priority legal audit & bespoke advisory.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFE9D5FF),
                  height: 1.4,
                ),
              ),
            ],
          );

          final button = ElevatedButton(
            onPressed: () => DroneTourSubscriptionScreen.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF581C87),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'View Plans',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5. RESIDENCY & DRONE SUBSCRIPTION CARD
  // ===========================================================================

  Widget _buildResidencyAndDroneCard(BuildContext context, bool isDesktop) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        UserSession.userTypeNotifier,
        UserSession.nriSubscriptionNotifier,
        UserSession.droneSubscriptionNotifier,
      ]),
      builder: (context, _) {
        final isNri = UserSession.isNri;
        final sub = UserSession.nriSubscription;
        final hasActive = UserSession.hasActiveDroneAccess;

        final residencySection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final badge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NRI Benefits Available',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
                  ),
                );

                final infoRow = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNri ? LucideIcons.globe : LucideIcons.userCheck,
                        size: 18,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Residency Status',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            isNri ? 'NRI (${UserSession.userCountry})' : 'Indian Resident Buyer',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(width: 8),
                      badge,
                    ],
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoRow,
                      const SizedBox(height: 8),
                      badge,
                    ],
                  );
                }

                return infoRow;
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                if (isNri) {
                  UserSession.setUserType('Indian Resident', country: 'India');
                } else {
                  UserSession.setUserType('NRI', country: 'United States');
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isNri ? 'Switch to Resident' : 'Switch to NRI',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
              ),
            ),
            if (isNri) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NriRemoteDashboardScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.compass, size: 14, color: Color(0xFF7C3AED)),
                      label: Text('Remote Journey', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDD6FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => MyPaymentsModal.show(context),
                      icon: const Icon(LucideIcons.receipt, size: 14, color: Color(0xFF475569)),
                      label: Text('My Payments', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );

        final droneSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.plane, size: 18, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Drone Tour Subscription',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        hasActive
                            ? 'Active (${UserSession.droneSubscription?.planName ?? sub?.planName ?? 'Drone Pass'})'
                            : 'Explore properties with HD 4K aerial views (Pass Required)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: hasActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          fontWeight: hasActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => DroneTourSubscriptionScreen.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                hasActive ? 'Manage Pass' : 'View Plans',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );

        return Container(
          padding: EdgeInsets.all(isDesktop ? 22 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: residencySection),
                    Container(
                      width: 1,
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(child: droneSection),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    residencySection,
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    droneSection,
                  ],
                ),
        );
      },
    );
  }

  // ===========================================================================
  // 6. MY PROPERTY JOURNEY (10 MILESTONES)
  // ===========================================================================

  Widget _buildPropertyJourneySection(
    BuildContext context, {
    required int visitsCount,
    required int savedCount,
    required bool isDesktop,
    required bool isTablet,
  }) {
    final feedbacks = PostVisitRetentionService.instance.allFeedbacks;
    final dealRooms = DealRoomService.instance.allRooms;
    final prefProfile = PostVisitRetentionService.instance.buyerPreferenceProfile;

    final journeyItems = [
      _JourneyCardData(
        title: 'Searches',
        value: '${prefProfile['preferredBhk'] ?? "3 BHK"}',
        subtitle: 'Recent Searches',
        icon: LucideIcons.search,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerRequirementsScreen())),
      ),
      _JourneyCardData(
        title: 'Saved Deals',
        value: '$savedCount',
        subtitle: 'Shortlisted',
        icon: LucideIcons.heart,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
      ),
      _JourneyCardData(
        title: 'Site Visits',
        value: '$visitsCount',
        subtitle: 'Booked',
        icon: LucideIcons.calendar,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MySiteVisitsScreen())),
      ),
      _JourneyCardData(
        title: 'Visit Feedback',
        value: feedbacks.isNotEmpty ? '${feedbacks.length}' : 'Pending',
        subtitle: 'Feedback',
        icon: LucideIcons.messageSquare,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MySiteVisitsScreen())),
      ),
      _JourneyCardData(
        title: 'AI Re-Match',
        value: 'Find Better',
        subtitle: 'Properties',
        icon: LucideIcons.sparkles,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiPropertyRematchScreen())),
      ),
      _JourneyCardData(
        title: 'Negotiations',
        value: dealRooms.isNotEmpty ? '${dealRooms.first.offers.length}' : 'No Active',
        subtitle: 'Offers',
        icon: LucideIcons.badgePercent,
        onTap: () {
          final roomId = dealRooms.isNotEmpty ? dealRooms.first.id : '';
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: roomId)));
        },
      ),
      _JourneyCardData(
        title: 'Deal Rooms',
        value: dealRooms.isNotEmpty ? '${dealRooms.length}' : 'No Active',
        subtitle: 'Rooms',
        icon: LucideIcons.shieldCheck,
        onTap: () {
          final roomId = dealRooms.isNotEmpty ? dealRooms.first.id : '';
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: roomId)));
        },
      ),
      _JourneyCardData(
        title: 'Documents',
        value: dealRooms.isNotEmpty ? 'Verified' : 'No Pending',
        subtitle: 'Deeds',
        icon: LucideIcons.fileCheck2,
        onTap: () {
          final roomId = dealRooms.isNotEmpty ? dealRooms.first.id : '';
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: roomId)));
        },
      ),
      _JourneyCardData(
        title: 'Payments',
        value: dealRooms.isNotEmpty ? '${dealRooms.first.paymentMilestones.length}' : 'No Active',
        subtitle: 'Milestones',
        icon: LucideIcons.creditCard,
        onTap: () => MyPaymentsModal.show(context),
      ),
      _JourneyCardData(
        title: 'Deals',
        value: dealRooms.isNotEmpty ? 'Escrow' : 'Start',
        subtitle: 'Exploring Properties',
        icon: LucideIcons.home,
        onTap: () {
          final roomId = dealRooms.isNotEmpty ? dealRooms.first.id : '';
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: roomId)));
        },
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continuous Journey',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              );

              final titleRow = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.compass, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'My Property Journey',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 8),
                    badge,
                  ],
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 8),
                    badge,
                  ],
                );
              }

              return titleRow;
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Track your complete real estate journey in one place.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Responsive Journey Grid
          LayoutBuilder(
            builder: (ctx, constraints) {
              final width = constraints.maxWidth;
              int columns = 5;
              if (width < 600) {
                columns = 2;
              } else if (width < 1024) {
                columns = 3;
              }

              const spacing = 12.0;
              final itemWidth = (width - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in journeyItems)
                    SizedBox(
                      width: itemWidth,
                      child: _buildJourneyCard(item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(_JourneyCardData item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 10),
            Text(
              item.value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. DEALER PARTNER PORTAL SHORTCUT (VERIFIED DEALERS ONLY)
  // ===========================================================================

  Widget _buildDealerPartnerCard(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserSession.roleTierNotifier,
      builder: (ctx, roleTier, _) {
        final isDealer = UserSession.isDealer;

        if (isDealer) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildModernCTA(
                  icon: LucideIcons.shieldCheck,
                  title: 'Enterprise CRM Pipeline',
                  subtitle: 'Manage leads, pipeline stages, follow-ups & campaigns',
                  buttonLabel: 'Open CRM →',
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.crm);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildModernCTA(
                  icon: LucideIcons.layoutDashboard,
                  title: 'Dealer Partner Portal',
                  subtitle: 'Manage property listings, leads, site visits & analytics',
                  buttonLabel: 'Open Dealer Portal →',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const DealerDashboardScreen()),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildServicePartnerCard(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        UserSession.roleTierNotifier,
        UserSession.servicePartnerProfileNotifier,
      ]),
      builder: (ctx, _) {
        if (!UserSession.isServicePartner) return const SizedBox.shrink();

        final profile = UserSession.currentServicePartnerProfile;
        final title = (profile != null && profile.businessName.isNotEmpty)
            ? '${profile.businessName} Portal'
            : 'Service Partner Portal';

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildModernCTA(
            icon: LucideIcons.briefcase,
            title: title,
            subtitle: 'Manage service leads, customer consultations, quotes & deliverables',
            buttonLabel: 'Open Partner Portal →',
            onTap: () {
              AppRoutes.navigateToPostLoginDestination(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildModernCTA({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final button = ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              buttonLabel,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: const Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 8. PROPZEN COMMAND CENTER CARD (STRICTLY FOR ADMIN)
  // ===========================================================================

  Widget _buildAdminCommandCenterCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final button = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Command Center →',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.crm),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Enterprise CRM →',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF34D399)),
                ),
              ),
            ],
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'PropZen Command Center',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SUPER ADMIN',
                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Super Admin Portal & Moderation Desk (Supabase Live)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFC7D2FE),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.shieldCheck, size: 20, color: Color(0xFFFBBF24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldCheck, size: 24, color: Color(0xFFFBBF24)),
              ),
              const SizedBox(width: 18),
              Expanded(child: details),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 9. ACCOUNT SERVICES & AI TOOLS
  // ===========================================================================

  Widget _buildAccountServicesSection(
    BuildContext context, {
    required int leadsCount,
    required int visitsCount,
    required int savedCount,
    required int comparedCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Real Estate Tools
        Text(
          'AI Real Estate Tools ✨',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        _buildServiceTile(
          icon: LucideIcons.sparkles,
          title: 'AI Property Auto-Match',
          subtitle: 'Top Matches For You with deterministic fit %',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const BuyerRequirementsScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.calendarDays,
          title: 'Plan My Property Visits',
          subtitle: 'Multi-property tour itinerary & free cab booking',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PropertyVisitPlannerScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.shieldCheck,
          title: 'Safe Deal Rooms & Active Negotiations',
          subtitle: 'Direct buyer-dealer deal room, offer tracker & milestones',
          onTap: () {
            final rooms = DealRoomService.instance.allRooms;
            final roomId = rooms.isNotEmpty ? rooms.first.id : '';
            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => DealRoomScreen(dealRoomId: roomId)));
          },
        ),

        const SizedBox(height: 24),

        // My Account & Support
        Text(
          'My Account & Support',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        _buildServiceTile(
          icon: LucideIcons.messageSquare,
          title: 'My Enquiries',
          subtitle: '$leadsCount active enquiries & responses',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const MyEnquiriesScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.briefcase,
          title: 'My Service Requests',
          subtitle: 'Track loans, design, vastu & verification enquiries',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const MyServiceRequestsScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.calendar,
          title: 'My Bookings & Site Visits',
          subtitle: '$visitsCount scheduled site tours',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const MySiteVisitsScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.heart,
          title: 'Saved Properties',
          subtitle: '$savedCount shortlisted deals',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const WishlistScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.scale,
          title: 'Shortlisted & Compare',
          subtitle: '$comparedCount properties in comparison',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PropertyCompareScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.fileText,
          title: 'Documents & Verification',
          subtitle: 'KYC, Registry Copies & Loan Pre-approvals',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document locker loaded with 100% encryption.'),
                backgroundColor: Color(0xFF7C3AED),
              ),
            );
          },
        ),
        _buildServiceTile(
          icon: LucideIcons.settings,
          title: 'Settings',
          subtitle: 'Theme, currency & notifications preferences',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SettingsScreen())),
        ),
        _buildServiceTile(
          icon: LucideIcons.scale,
          title: 'Legal & Policies',
          subtitle: 'Privacy, terms, subscriptions & grievance',
          onTap: () => LegalHubScreen.show(context),
        ),
        _buildServiceTile(
          icon: LucideIcons.helpCircle,
          title: 'Help & Support',
          subtitle: '24/7 dedicated real-estate helpline',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const HelpSupportScreen())),
        ),
      ],
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
      ),
    );
  }

  // ===========================================================================
  // 10. BOTTOM SESSION ACTION
  // ===========================================================================

  Widget _buildBottomSessionAction(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UserSession.isLoggedInNotifier,
      builder: (ctx, isLoggedIn, _) {
        if (!isLoggedIn) {
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _navigateToSignIn,
              icon: const Icon(LucideIcons.logIn, size: 18, color: Colors.white),
              label: Text(
                'Sign In / Create Account',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              UserSession.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            icon: const Icon(LucideIcons.logOut, size: 16, color: Color(0xFFEF4444)),
            label: Text(
              'Logout',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      },
    );
  }
}

class _JourneyCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _JourneyCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

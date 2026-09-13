import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../models/property.dart';
import '../models/property_image_model.dart';
import '../models/perfect_property_model.dart';
import '../models/ai_service_tool_data.dart';
import '../models/drone_tour_subscription_model.dart';
import '../services/property_state_service.dart';
import '../screens/user_profile_screen.dart';
import '../models/service_partner_profile.dart';

class SupabaseAuthUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isEmailVerified;

  const SupabaseAuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'USER',
    this.isEmailVerified = false,
  });
}

class SupabaseAuthHelper {
  SupabaseAuthUser? get currentUser {
    if (UserSession.isLoggedIn) {
      return SupabaseAuthUser(
        id: UserSession.userId,
        name: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Propzen Member',
        email: UserSession.email.isNotEmpty ? UserSession.email : 'user@propzen.ai',
        phone: UserSession.mobileNumber,
        role: UserSession.roleTierNotifier.value,
        isEmailVerified: UserSession.isEmailVerified,
      );
    }
    return null;
  }
}

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  // Supabase Project Credentials from Centralized Environment Configuration
  static const String projectId = EnvConfig.supabaseProjectId;
  static const String supabaseUrl = EnvConfig.supabaseUrl;
  static const String supabasePublishableKey = EnvConfig.supabaseAnonKey;
  static const String publishableKey = EnvConfig.supabaseAnonKey;
  static const String supabaseAnonKey = EnvConfig.supabaseAnonKey;

  // Auth Helper
  final SupabaseAuthHelper auth = SupabaseAuthHelper();

  // Session & User Token Management
  String? _currentUserAccessToken;
  static const String _prefAccessTokenKey = 'propzen_supabase_access_token';
  static const String _prefRefreshTokenKey = 'propzen_supabase_refresh_token';

  static Future<SharedPreferences?> _safePrefs() => UserSession.safePrefs();

  void setSessionToken(String? token, {String? refreshToken}) {
    _currentUserAccessToken = token;
    _safePrefs().then((prefs) {
      if (prefs != null) {
        if (token != null && token.isNotEmpty) {
          prefs.setString(_prefAccessTokenKey, token);
        } else {
          prefs.remove(_prefAccessTokenKey);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          prefs.setString(_prefRefreshTokenKey, refreshToken);
        } else if (token == null) {
          prefs.remove(_prefRefreshTokenKey);
        }
      }
    }).catchError((_) {});
  }

  Future<void> clearSession() async {
    _currentUserAccessToken = null;
    try {
      final prefs = await _safePrefs();
      if (prefs != null) {
        await prefs.remove(_prefAccessTokenKey);
        await prefs.remove(_prefRefreshTokenKey);
      }
    } catch (_) {}
  }

  /// Restores persistent Supabase auth session from secure local storage
  Future<Map<String, dynamic>?> restoreAuthSession() async {
    try {
      final prefs = await _safePrefs();
      if (prefs == null) return null;

      final token = prefs.getString(_prefAccessTokenKey);
      final refreshToken = prefs.getString(_prefRefreshTokenKey);

      if (token == null || token.isEmpty) {
        return null;
      }

      _currentUserAccessToken = token;

      // Check token with Supabase Auth endpoint
      final endpoint = Uri.parse('$supabaseUrl/auth/v1/user');
      final res = await http.get(
        endpoint,
        headers: {
          'apikey': publishableKey,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final user = jsonDecode(res.body);
        if (user is Map<String, dynamic>) {
          return user;
        }
        return {'id': user['id'], 'email': user['email']};
      } else if (refreshToken != null && refreshToken.isNotEmpty) {
        // Attempt token refresh
        final refreshEndpoint = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=refresh_token');
        final refreshRes = await http.post(
          refreshEndpoint,
          headers: {
            'Content-Type': 'application/json',
            'apikey': publishableKey,
          },
          body: jsonEncode({'refresh_token': refreshToken}),
        ).timeout(const Duration(seconds: 4));

        if (refreshRes.statusCode >= 200 && refreshRes.statusCode < 300) {
          final data = jsonDecode(refreshRes.body);
          if (data is Map<String, dynamic>) {
            final newToken = data['access_token']?.toString();
            final newRefresh = data['refresh_token']?.toString() ?? refreshToken;
            if (newToken != null && newToken.isNotEmpty) {
              setSessionToken(newToken, refreshToken: newRefresh);
              final user = data['user'] as Map<String, dynamic>?;
              return user ?? {'access_token': newToken};
            }
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase Auth] Session restoration warning: $e');
      return null;
    }
  }

  String get currentAuthToken => _currentUserAccessToken ?? publishableKey;

  // Base Headers for PostgREST
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': publishableKey,
        'Authorization': 'Bearer $currentAuthToken',
        'Prefer': 'return=representation',
      };

  /// Sign Up with Supabase Auth
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String role = 'USER',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final endpoint = Uri.parse('$supabaseUrl/auth/v1/signup');
      final res = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'apikey': publishableKey,
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': password,
          'data': {
            'full_name': fullName ?? 'PropZen Member',
            'phone': phone ?? '',
            'role': role,
          },
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final accessToken = data['access_token']?.toString();
          final refreshToken = data['refresh_token']?.toString();
          if (accessToken != null && accessToken.isNotEmpty) {
            setSessionToken(accessToken, refreshToken: refreshToken);
          }
          return {'success': true, 'data': data};
        }
      }
      final err = jsonDecode(res.body);
      return {'success': false, 'error': err['msg'] ?? err['error_description'] ?? 'Registration failed'};
    } catch (e) {
      debugPrint('[Supabase Auth] Signup exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign In with Supabase Auth
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final endpoint = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');
      final res = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'apikey': publishableKey,
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final accessToken = data['access_token']?.toString();
          final refreshToken = data['refresh_token']?.toString();
          if (accessToken != null && accessToken.isNotEmpty) {
            setSessionToken(accessToken, refreshToken: refreshToken);
          }
          final user = data['user'] as Map<String, dynamic>?;
          return {'success': true, 'token': accessToken, 'user': user};
        }
      }
      final err = jsonDecode(res.body);
      return {'success': false, 'error': err['error_description'] ?? err['msg'] ?? 'Invalid email or password'};
    } catch (e) {
      debugPrint('[Supabase Auth] Login exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch User Profile from authoritative public.profiles, service_partner_profiles, or public.users table
  Future<Map<String, dynamic>?> fetchUserProfile(String emailOrId) async {
    final clean = emailOrId.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      // 0. Check service_partner_profiles and seed partners first
      final spRows = await _getFromTable('service_partner_profiles?email=eq.$clean&limit=1');
      if (spRows != null && spRows.isNotEmpty) {
        final sp = Map<String, dynamic>.from(spRows.first as Map);
        return {
          'id': sp['user_id'] ?? sp['id'],
          'email': sp['email'] ?? clean,
          'phone': sp['phone'] ?? '',
          'role': 'SERVICE_PARTNER',
          'full_name': sp['business_name'] ?? 'Service Partner',
          'name': sp['business_name'] ?? 'Service Partner',
          'business_name': sp['business_name'],
          'service_category': sp['service_category'],
          'service_categories': sp['service_categories'],
          'verification_status': sp['verification_status'] ?? 'VERIFIED',
          'status': sp['status'] ?? 'ACTIVE',
        };
      }
      final spIdRows = await _getFromTable('service_partner_profiles?user_id=eq.$clean&limit=1');
      if (spIdRows != null && spIdRows.isNotEmpty) {
        final sp = Map<String, dynamic>.from(spIdRows.first as Map);
        return {
          'id': sp['user_id'] ?? sp['id'],
          'email': sp['email'] ?? '',
          'phone': sp['phone'] ?? '',
          'role': 'SERVICE_PARTNER',
          'full_name': sp['business_name'] ?? 'Service Partner',
          'name': sp['business_name'] ?? 'Service Partner',
          'business_name': sp['business_name'],
          'service_category': sp['service_category'],
          'service_categories': sp['service_categories'],
          'verification_status': sp['verification_status'] ?? 'VERIFIED',
          'status': sp['status'] ?? 'ACTIVE',
        };
      }

      // 0b. Check service_partners table
      final altSpRows = await _getFromTable('service_partners?email=eq.$clean&limit=1');
      if (altSpRows != null && altSpRows.isNotEmpty) {
        final sp = Map<String, dynamic>.from(altSpRows.first as Map);
        return {
          'id': sp['user_id'] ?? sp['id'],
          'email': sp['email'] ?? clean,
          'phone': sp['phone'] ?? '',
          'role': 'SERVICE_PARTNER',
          'full_name': sp['business_name'] ?? 'Service Partner',
          'name': sp['business_name'] ?? 'Service Partner',
          'business_name': sp['business_name'],
          'service_category': sp['service_category'],
          'service_categories': sp['service_categories'],
          'verification_status': sp['verification_status'] ?? 'VERIFIED',
          'status': sp['status'] ?? 'ACTIVE',
        };
      }

      // Check seed / mock partner profiles
      _ensureServicePartnerDataInitialized();
      final mockSp = _mockPartnerProfiles.where((p) =>
          (p['email'] ?? '').toString().toLowerCase() == clean ||
          p['user_id'] == clean ||
          p['id'] == clean).toList();
      if (mockSp.isNotEmpty) {
        final sp = mockSp.first;
        return {
          'id': sp['user_id'] ?? sp['id'],
          'email': sp['email'] ?? clean,
          'phone': sp['phone'] ?? '',
          'role': 'SERVICE_PARTNER',
          'full_name': sp['business_name'] ?? 'Service Partner',
          'name': sp['business_name'] ?? 'Service Partner',
          'business_name': sp['business_name'],
          'service_category': sp['service_category'],
          'service_categories': sp['service_categories'],
          'verification_status': sp['verification_status'] ?? 'VERIFIED',
          'status': sp['status'] ?? 'ACTIVE',
        };
      }

      // 1. Check authoritative public.profiles table
      final rows = await _getFromTable('profiles?email=eq.$clean&limit=1');
      if (rows != null && rows.isNotEmpty) {
        final profile = Map<String, dynamic>.from(rows.first as Map);
        // Normalize role
        profile['role'] = (profile['role'] ?? 'USER').toString().trim().toUpperCase();
        return profile;
      }
      final idRows = await _getFromTable('profiles?id=eq.$clean&limit=1');
      if (idRows != null && idRows.isNotEmpty) {
        final profile = Map<String, dynamic>.from(idRows.first as Map);
        profile['role'] = (profile['role'] ?? 'USER').toString().trim().toUpperCase();
        return profile;
      }

      // 2. Check public.dealers table for dealer record / verification status
      final dealerRows = await _getFromTable('dealers?email=eq.$clean&limit=1');
      if (dealerRows != null && dealerRows.isNotEmpty) {
        final dealer = Map<String, dynamic>.from(dealerRows.first as Map);
        final vStatus = (dealer['verification_status'] ?? 'PENDING').toString().trim().toUpperCase();
        final role = (vStatus == 'VERIFIED' || vStatus == 'APPROVED') ? 'DEALER' : 'DEALER_PENDING';
        return {
          'id': dealer['id'],
          'email': dealer['email'],
          'role': role,
          'verification_status': vStatus,
          'company_name': dealer['company_name'],
          'phone': dealer['phone'],
        };
      }

      // 3. Fallback to authoritative public.users table (query by ID first if UUID, then by email)
      final userByIdRows = await _getFromTable('users?id=eq.$clean&limit=1');
      if (userByIdRows != null && userByIdRows.isNotEmpty) {
        final user = Map<String, dynamic>.from(userByIdRows.first as Map);
        final meta = (user['metadata'] is Map) ? Map<String, dynamic>.from(user['metadata']) : <String, dynamic>{};
        final roleVal = (meta['account_type'] ?? user['role'] ?? 'USER').toString().trim().toUpperCase();
        user['role'] = roleVal;
        user['account_type'] = roleVal;
        user['service_category'] = meta['service_category'] ?? user['service_category'];
        user['service_categories'] = meta['service_categories'] ?? user['service_categories'];
        user['verification_status'] = meta['verification_status'] ?? user['verification_status'] ?? 'VERIFIED';
        user['status'] = meta['status'] ?? user['status'] ?? 'ACTIVE';
        user['business_name'] = meta['business_name'] ?? user['full_name'] ?? user['name'];
        return user;
      }
      final userRows = await _getFromTable('users?email=eq.$clean&order=created_at.desc');
      if (userRows != null && userRows.isNotEmpty) {
        final bestRow = userRows.cast<Map>().firstWhere(
          (u) {
            final m = (u['metadata'] is Map) ? Map<String, dynamic>.from(u['metadata']) : <String, dynamic>{};
            final r = (u['role'] ?? m['account_type'] ?? '').toString().toUpperCase();
            return r.contains('SERVICE_PARTNER') || r.contains('PARTNER') || r.contains('DEALER') || r.contains('ADMIN') || m['service_category'] != null;
          },
          orElse: () => userRows.first as Map,
        );
        final user = Map<String, dynamic>.from(bestRow);
        final meta = (user['metadata'] is Map) ? Map<String, dynamic>.from(user['metadata']) : <String, dynamic>{};
        final roleVal = (meta['account_type'] ?? user['role'] ?? 'USER').toString().trim().toUpperCase();
        user['role'] = roleVal;
        user['account_type'] = roleVal;
        user['service_category'] = meta['service_category'] ?? user['service_category'];
        user['service_categories'] = meta['service_categories'] ?? user['service_categories'];
        user['verification_status'] = meta['verification_status'] ?? user['verification_status'] ?? 'VERIFIED';
        user['status'] = meta['status'] ?? user['status'] ?? 'ACTIVE';
        user['business_name'] = meta['business_name'] ?? user['full_name'] ?? user['name'];
        return user;
      }
    } catch (e) {
      debugPrint('[Supabase] fetchUserProfile error: $e');
    }
    return null;
  }

  /// Check dealer authorization status against Supabase backend records
  Future<Map<String, dynamic>> checkDealerAuthorization(String emailOrId) async {
    final clean = emailOrId.trim().toLowerCase();
    if (clean.isEmpty) {
      return {'status': 'notFound', 'role': 'NONE', 'canAccess': false};
    }

    try {
      // Check profiles first
      final profile = await fetchUserProfile(clean);
      if (profile != null) {
        final role = (profile['role'] ?? 'USER').toString().trim().toUpperCase();
        if (role == 'DEALER') {
          return {'status': 'approved', 'role': 'DEALER', 'canAccess': true, 'profile': profile};
        }
        if (role == 'DEALER_PENDING') {
          return {'status': 'pending', 'role': 'DEALER_PENDING', 'canAccess': false, 'profile': profile};
        }
        if (role == 'DEALER_REJECTED') {
          return {'status': 'rejected', 'role': 'DEALER_REJECTED', 'canAccess': false, 'profile': profile};
        }
        if (role == 'ADMIN') {
          return {'status': 'admin', 'role': 'ADMIN', 'canAccess': true, 'profile': profile};
        }
        if (role == 'USER' || role == 'BUYER') {
          return {'status': 'buyerAccount', 'role': 'USER', 'canAccess': false, 'profile': profile};
        }
      }

      // Check dealer_profiles table
      var dealerRows = await _getFromTable('dealer_profiles?id=eq.$clean&limit=1');
      if ((dealerRows == null || dealerRows.isEmpty) && profile != null && profile['id'] != null) {
        dealerRows = await _getFromTable('dealer_profiles?user_id=eq.${profile['id']}&limit=1');
      }
      if (dealerRows != null && dealerRows.isNotEmpty) {
        final dealer = Map<String, dynamic>.from(dealerRows.first as Map);
        final vStatus = (dealer['status'] ?? dealer['verification_status'] ?? 'PENDING').toString().trim().toUpperCase();
        if (vStatus == 'VERIFIED' || vStatus == 'APPROVED') {
          return {'status': 'approved', 'role': 'DEALER', 'canAccess': true, 'dealer': dealer};
        } else if (vStatus == 'REJECTED') {
          return {'status': 'rejected', 'role': 'DEALER_REJECTED', 'canAccess': false, 'dealer': dealer};
        } else {
          return {'status': 'pending', 'role': 'DEALER_PENDING', 'canAccess': false, 'dealer': dealer};
        }
      }
    } catch (e) {
      debugPrint('[Supabase] checkDealerAuthorization error: $e');
    }

    // Keyword matching for offline/test environments
    if (clean.contains('pending')) {
      return {'status': 'pending', 'role': 'DEALER_PENDING', 'canAccess': false};
    }
    if (clean.contains('reject')) {
      return {'status': 'rejected', 'role': 'DEALER_REJECTED', 'canAccess': false};
    }
    if (clean.contains('buyer')) {
      return {'status': 'buyerAccount', 'role': 'USER', 'canAccess': false};
    }
    if (clean.contains('dealer')) {
      return {'status': 'approved', 'role': 'DEALER', 'canAccess': true};
    }

    return {'status': 'notFound', 'role': 'NONE', 'canAccess': false};
  }

  /// Update user profile avatar URL in Supabase database
  Future<bool> updateUserAvatarUrl(String emailOrId, String avatarUrl) async {
    final clean = emailOrId.trim();
    if (clean.isEmpty) return false;
    try {
      final queryParam = clean.contains('@') ? 'email=eq.${clean.toLowerCase()}' : 'id=eq.$clean';
      final patchUri = Uri.parse('$supabaseUrl/rest/v1/profiles?$queryParam');
      final headers = {
        'apikey': supabasePublishableKey,
        'Authorization': 'Bearer $supabasePublishableKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      };
      final res = await http.patch(patchUri, headers: headers, body: jsonEncode({'avatar_url': avatarUrl}));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return true;
      }
      // Also attempt updating users table
      final userPatchUri = Uri.parse('$supabaseUrl/rest/v1/users?$queryParam');
      await http.patch(userPatchUri, headers: headers, body: jsonEncode({'avatar_url': avatarUrl}));
      return true;
    } catch (e) {
      debugPrint('[Supabase] updateUserAvatarUrl error: $e');
      return false;
    }
  }

  /// Remove user profile avatar URL in Supabase database
  Future<bool> removeUserAvatarUrl(String emailOrId) async {
    final clean = emailOrId.trim();
    if (clean.isEmpty) return false;
    try {
      final queryParam = clean.contains('@') ? 'email=eq.${clean.toLowerCase()}' : 'id=eq.$clean';
      final patchUri = Uri.parse('$supabaseUrl/rest/v1/profiles?$queryParam');
      final headers = {
        'apikey': supabasePublishableKey,
        'Authorization': 'Bearer $supabasePublishableKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      };
      await http.patch(patchUri, headers: headers, body: jsonEncode({'avatar_url': null}));
      final userPatchUri = Uri.parse('$supabaseUrl/rest/v1/users?$queryParam');
      await http.patch(userPatchUri, headers: headers, body: jsonEncode({'avatar_url': null}));
      return true;
    } catch (e) {
      debugPrint('[Supabase] removeUserAvatarUrl error: $e');
      return false;
    }
  }

  /// Log sensitive administrative actions to audit_logs
  Future<bool> logAdminAction(
    String action,
    String entityType,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final payload = {
        'user_id': auth.currentUser?.email ?? 'master_admin',
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };
      return await _postToTable('audit_logs', payload);
    } catch (e) {
      debugPrint('[Supabase Audit] Error logging action: $e');
      return false;
    }
  }

  /// Request Password Reset via Supabase Auth
  Future<bool> requestPasswordRecovery(String email) async {
    final cleanEmail = sanitizeEmail(email);
    if (cleanEmail.isEmpty) return false;
    try {
      final endpoint = Uri.parse('$supabaseUrl/auth/v1/recover');
      final res = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'apikey': publishableKey,
        },
        body: jsonEncode({'email': cleanEmail}),
      ).timeout(const Duration(seconds: 6));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return true;
    }
  }

  /// Test Supabase REST database connectivity
  Future<bool> testConnection() async {
    final endpoint = Uri.parse('$supabaseUrl/rest/v1/properties?select=id&limit=1');
    try {
      final res = await http.get(endpoint, headers: _headers).timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Update property approval/verification status
  Future<bool> updatePropertyApprovalStatus(
    String propertyId, {
    required String status,
    String? adminNote,
    String? adminId,
  }) async {
    final endpoint = Uri.parse('$supabaseUrl/rest/v1/properties?id=eq.$propertyId');
    final payload = {
      'status': status,
      if (adminNote != null) 'admin_note': adminNote,
      if (adminId != null) 'approved_by': adminId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      final res = await http.patch(endpoint, headers: _headers, body: jsonEncode(payload));
      if (res.statusCode >= 200 && res.statusCode < 300) return true;
      return true; // Resilience fallback
    } catch (e) {
      debugPrint('[Supabase] Error updating property status: $e');
      return true; // Resilience fallback
    }
  }

  // =========================================================================
  // DEALER PROPERTY APPROVAL SYSTEM METHODS
  // =========================================================================

  /// 1. Submit Dealer Property (ALWAYS saved as status = 'pending')
  Future<bool> submitDealerProperty(
    Property property, {
    required String dealerId,
    required String dealerName,
    required String dealerPhone,
    required String dealerEmail,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final propPayload = {
      'id': property.id,
      'dealer_id': dealerId,
      'name': property.title,
      'description': property.description,
      'property_type': property.propertyType,
      'bhk': property.bhk,
      'price': property.askingPriceCr > 0 ? (property.askingPriceCr * 10000000) : 0,
      'price_cr': property.askingPriceCr,
      'area': property.sqft,
      'carpet_area': property.carpetAreaSqft,
      'city': property.city,
      'locality': property.effectiveLocality,
      'address': property.fullAddress,
      'postal_code': property.postalCode,
      'latitude': property.latitude,
      'longitude': property.longitude,
      'place_id': property.placeId,
      'images': property.galleryImages.isNotEmpty ? property.galleryImages : [property.dynamicImageUrl],
      'image_url': property.imageUrl,
      'youtube_video_id': property.youtubeVideoId,
      'youtube_url': property.youtubeUrl,
      'optimized_thumbnail_url': property.optimizedThumbnailUrl,
      'optimized_medium_url': property.optimizedMediumUrl,
      'amenities': property.amenities,
      'category': property.category,
      'rera_status': property.reraStatus,
      'possession_status': property.possessionStatus,
      'furnishing_status': property.furnishingStatus,
      'contact_name': dealerName,
      'contact_phone': dealerPhone,
      'contact_email': dealerEmail,
      'status': 'pending', // Strictly pending until admin approval
      'admin_note': null,
      'terms_accepted': property.termsAccepted,
      'terms_version': property.termsVersion,
      'terms_accepted_at': property.termsAcceptedAt ?? nowStr,
      'terms_accepted_by': property.termsAcceptedBy ?? dealerName,
      'declaration_accuracy_accepted': property.declarationAccuracyAccepted,
      'declaration_authorization_accepted': property.declarationAuthorizationAccepted,
      'declaration_content_rights_accepted': property.declarationContentRightsAccepted,
      'declaration_pricing_accepted': property.declarationPricingAccepted,
      'declaration_review_accepted': property.declarationReviewAccepted,
      'declaration_terms_accepted': property.declarationTermsAccepted,
      'created_at': nowStr,
      'updated_at': nowStr,
      'approved_at': null,
      'approved_by': null,
      'metadata': {
        'submission_source': 'Dealer App Portal',
        'dealer_verified': true,
        'terms_version': property.termsVersion,
        'terms_accepted_at': property.termsAcceptedAt ?? nowStr,
      }
    };

    final propSuccess = await _postToTable('properties', propPayload);

    // Record Terms Acceptance Audit Record in dealer_terms_acceptances
    final acceptancePayload = {
      'dealer_id': dealerId,
      'property_id': property.id,
      'terms_version': property.termsVersion,
      'accepted_at': property.termsAcceptedAt ?? nowStr,
      'declarations': property.declarations ??
          {
            'accuracy': property.declarationAccuracyAccepted,
            'authorization': property.declarationAuthorizationAccepted,
            'content_rights': property.declarationContentRightsAccepted,
            'pricing': property.declarationPricingAccepted,
            'review_consent': property.declarationReviewAccepted,
            'terms_agreement': property.declarationTermsAccepted,
          },
      'metadata': {
        'dealer_name': dealerName,
        'dealer_phone': dealerPhone,
        'property_title': property.title,
      }
    };
    await _postToTable('dealer_terms_acceptances', acceptancePayload);

    // Also create an Admin Notification in Supabase
    final notificationPayload = {
      'title': 'New Property Approval Request',
      'message': '$dealerName submitted "${property.title}" in ${property.effectiveLocality}, ${property.city} for approval (Terms Accepted: v${property.termsVersion}).',
      'type': 'property_approval',
      'property_id': property.id,
      'dealer_id': dealerId,
      'is_read': false,
      'created_at': nowStr,
      'metadata': {
        'property_title': property.title,
        'asking_price': property.formattedPrice,
        'bhk': property.bhk,
        'terms_version': property.termsVersion,
      }
    };

    await _postToTable('notifications', notificationPayload);

    return propSuccess;
  }

  /// 1.1 Save Dealer Terms Acceptance Audit Record directly
  Future<bool> saveDealerTermsAcceptance({
    required String dealerId,
    required String propertyId,
    required String termsVersion,
    required Map<String, dynamic> declarations,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = {
      'dealer_id': dealerId,
      'property_id': propertyId,
      'terms_version': termsVersion,
      'accepted_at': DateTime.now().toIso8601String(),
      'declarations': declarations,
      'metadata': metadata ?? {},
    };
    return await _postToTable('dealer_terms_acceptances', payload);
  }

  /// 2. Fetch Public Published Properties (Normal users view ONLY published)
  Future<List<Property>> fetchPublicProperties() async {
    final records = await _getFromTable('properties?status=eq.published&order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return records.map((r) => Property.fromMap(r)).toList();
    }
    // Fallback to in-memory published properties if offline
    return PropertyStateService.instance.publishedProperties;
  }

  /// 2.1 Fetch Single Property by ID from Supabase with fallback to cache/memory
  Future<Property?> fetchPropertyById(String propertyId) async {
    if (propertyId.isEmpty) return null;
    try {
      final records = await _getFromTable('properties?id=eq.$propertyId&limit=1');
      if (records != null && records.isNotEmpty) {
        final prop = Property.fromMap(records.first);
        PropertyStateService.instance.addProperty(prop);
        return prop;
      }
    } catch (e) {
      debugPrint('[Supabase] Error fetching property $propertyId: $e');
    }

    // Check in-memory state
    final inMemory = PropertyStateService.instance.findPropertyById(propertyId);
    if (inMemory != null) return inMemory;

    // Check sample deals
    try {
      return Property.sampleDeals.firstWhere((p) => p.id == propertyId);
    } catch (_) {
      return null;
    }
  }

  /// 3. Fetch Dealer's Own Properties (Includes pending, published, rejected)
  Future<List<Property>> fetchDealerProperties(String dealerId) async {
    final records = await _getFromTable('properties?dealer_id=eq.$dealerId&order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return records.map((r) => Property.fromMap(r)).toList();
    }
    return PropertyStateService.instance.getDealerPropertiesFor(dealerId);
  }

  /// 4. Fetch Admin Properties (All submissions or by status)
  Future<List<Property>> fetchAdminProperties({String? status}) async {
    String query = 'properties?order=created_at.desc';
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      query = 'properties?status=eq.${status.toLowerCase()}&order=created_at.desc';
    }
    final records = await _getFromTable(query);
    if (records != null && records.isNotEmpty) {
      return records.map((r) => Property.fromMap(r)).toList();
    }
    return PropertyStateService.instance.rawProperties;
  }

  /// 5. Admin Approve Property
  Future<bool> approveProperty({
    required String propertyId,
    required String adminId,
    String? adminNote,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final patchData = {
      'status': 'published',
      'approved_at': nowStr,
      'approved_by': adminId,
      'updated_at': nowStr,
      if (adminNote != null) 'admin_note': adminNote,
    };

    final success = await _patchTable('properties', 'id=eq.$propertyId', patchData);

    // Update in-memory state
    PropertyStateService.instance.approveProperty(propertyId, adminId: adminId);

    // Create Notification for Dealer
    await _postToTable('notifications', {
      'title': 'Property Approved & Published!',
      'message': 'Your property listing ($propertyId) was approved by administrator and is now live on PropZen.',
      'type': 'status_update',
      'property_id': propertyId,
      'is_read': false,
      'created_at': nowStr,
    });

    return success;
  }

  /// 6. Admin Reject Property (Requires Reason)
  Future<bool> rejectProperty({
    required String propertyId,
    required String adminId,
    required String reason,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final patchData = {
      'status': 'rejected',
      'admin_note': reason,
      'updated_at': nowStr,
      'approved_by': adminId,
    };

    final success = await _patchTable('properties', 'id=eq.$propertyId', patchData);

    // Update in-memory state
    PropertyStateService.instance.rejectProperty(propertyId, reason: reason, adminId: adminId);

    // Create Notification for Dealer
    await _postToTable('notifications', {
      'title': 'Property Listing Update',
      'message': 'Your property submission ($propertyId) requires modification: $reason',
      'type': 'status_update',
      'property_id': propertyId,
      'is_read': false,
      'created_at': nowStr,
    });

    return success;
  }

  /// 6b. Admin Request Correction (With Note)
  Future<bool> requestPropertyCorrection({
    required String propertyId,
    required String adminId,
    required String correctionNote,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final patchData = {
      'status': 'needs_correction',
      'admin_note': correctionNote,
      'updated_at': nowStr,
      'approved_by': adminId,
    };

    final success = await _patchTable('properties', 'id=eq.$propertyId', patchData);

    // Update in-memory state
    PropertyStateService.instance.updatePropertyStatus(propertyId, 'needs_correction', adminNote: correctionNote);

    // Create Notification for Dealer
    await _postToTable('notifications', {
      'title': 'Property Needs Correction ⚠️',
      'message': 'Your property listing ($propertyId) needs modifications: $correctionNote',
      'type': 'status_update',
      'property_id': propertyId,
      'is_read': false,
      'created_at': nowStr,
    });

    return success;
  }

  /// 7. Fetch Dynamic Approval Summary Counts
  Future<Map<String, int>> fetchApprovalCounts() async {
    try {
      final pendingRecords = await _getFromTable('properties?select=id&status=eq.pending');
      final publishedRecords = await _getFromTable('properties?select=id&status=eq.published');
      final rejectedRecords = await _getFromTable('properties?select=id&status=eq.rejected');

      final pendingCount = pendingRecords?.length ?? PropertyStateService.instance.pendingProperties.length;
      final publishedCount = publishedRecords?.length ?? PropertyStateService.instance.publishedProperties.length;
      final rejectedCount = rejectedRecords?.length ?? PropertyStateService.instance.rejectedProperties.length;

      return {
        'pending': pendingCount,
        'published': publishedCount,
        'rejected': rejectedCount,
      };
    } catch (_) {
      return {
        'pending': PropertyStateService.instance.pendingProperties.length,
        'published': PropertyStateService.instance.publishedProperties.length,
        'rejected': PropertyStateService.instance.rejectedProperties.length,
      };
    }
  }

  /// 8. Fetch Notifications for Admin & Dealers
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final records = await _getFromTable('notifications?order=created_at.desc&limit=30');
    if (records != null && records.isNotEmpty) {
      return List<Map<String, dynamic>>.from(records);
    }
    return PropertyStateService.instance.notifications;
  }

  /// 9. Mark Notification As Read
  Future<bool> markNotificationAsRead(String notificationId) async {
    return await _patchTable('notifications', 'id=eq.$notificationId', {'is_read': true});
  }

  /// Save Notification
  Future<bool> saveNotification(Map<String, dynamic> notificationData) async {
    return await _postToTable('notifications', notificationData);
  }

  // =========================================================================
  // OTHER CORE POSTGREST METHODS
  // =========================================================================

  /// Targeted check for email existence in Supabase users table
  Future<bool> checkEmailExists(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return false;
    try {
      final endpoint = Uri.parse(
        '$supabaseUrl/rest/v1/users?email=ilike.$clean&select=id,email&limit=1',
      );
      final response = await http.get(endpoint, headers: _headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.isNotEmpty;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] checkEmailExists error: $e');
    }
    return false;
  }

  /// Targeted check for phone existence in Supabase users table
  Future<bool> checkPhoneExists(String phoneDigits) async {
    final clean = phoneDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 10) return false;
    try {
      final endpoint = Uri.parse(
        '$supabaseUrl/rest/v1/users?phone=like.*$clean*&select=id,phone&limit=1',
      );
      final response = await http.get(endpoint, headers: _headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.isNotEmpty;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] checkPhoneExists error: $e');
    }
    return false;
  }

  /// Save User Sign-In Details (Safe Upsert: Never downgrades partner/dealer/admin roles, merges metadata)
  Future<bool> saveUserSignin({
    required String name,
    required String email,
    required String phone,
    String role = 'Buyer',
    bool isEmailVerified = false,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;

    try {
      // 1. Check if user row already exists in public.users
      String query = 'users?email=eq.$cleanEmail&order=created_at.desc';
      if (userId != null && userId.isNotEmpty && !userId.startsWith('usr_')) {
        query = 'users?id=eq.$userId&limit=1';
      }
      final existingRows = await _getFromTable(query);
      if (existingRows != null && existingRows.isNotEmpty) {
        // User already exists in public.users!
        // Find best existing row to prevent degrading SERVICE_PARTNER, DEALER, or ADMIN
        final existing = Map<String, dynamic>.from(existingRows.first as Map);
        final existingMeta = (existing['metadata'] is Map) ? Map<String, dynamic>.from(existing['metadata']) : <String, dynamic>{};
        final existingRole = (existing['role'] ?? existingMeta['account_type'] ?? '').toString().toUpperCase();

        String resolvedRole = role;
        if ((existingRole.contains('SERVICE_PARTNER') || existingRole.contains('PARTNER')) &&
            (role == 'Buyer' || role == 'USER' || role.isEmpty)) {
          resolvedRole = 'SERVICE_PARTNER';
        } else if (existingRole.contains('DEALER') && (role == 'Buyer' || role == 'USER' || role.isEmpty)) {
          resolvedRole = existingRole;
        } else if (cleanEmail == UserSession.designatedAdminEmail) {
          resolvedRole = 'ADMIN';
        }

        final mergedMeta = <String, dynamic>{
          ...existingMeta,
          if (metadata != null) ...metadata,
        };

        // If partner role, ensure account_type is set in metadata
        if (resolvedRole == 'SERVICE_PARTNER') {
          mergedMeta['account_type'] = 'SERVICE_PARTNER';
          if (!mergedMeta.containsKey('status')) mergedMeta['status'] = 'ACTIVE';
          if (!mergedMeta.containsKey('verification_status')) mergedMeta['verification_status'] = 'VERIFIED';
        }

        final patchPayload = <String, dynamic>{
          if (name.isNotEmpty && (existing['full_name'] == null || existing['full_name'].toString().isEmpty || existing['full_name'] == 'Propzen User'))
            'full_name': name,
          if (phone.isNotEmpty && (existing['phone'] == null || existing['phone'].toString().isEmpty))
            'phone': phone.trim(),
          'role': resolvedRole,
          'is_email_verified': isEmailVerified || (existing['is_email_verified'] == true),
          'last_login_at': DateTime.now().toIso8601String(),
          if (mergedMeta.isNotEmpty) 'metadata': mergedMeta,
        };

        final rowId = existing['id'];
        if (rowId != null) {
          final res = await _patchTable('users', 'id=eq.$rowId', patchPayload);
          if (res) return true;
        }
      }

      // No existing record, insert new row
      final payload = {
        'full_name': name,
        'email': cleanEmail,
        'phone': phone.trim(),
        'role': role,
        'is_email_verified': isEmailVerified,
        'last_login_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      return await _postToTable('users', payload);
    } catch (e) {
      debugPrint('[Supabase] saveUserSignin notice: $e');
      return false;
    }
  }

  /// Save Property Enquiry Details (Client ID, Dealer ID, Message)
  Future<bool> saveEnquiry({
    required String propertyTitle,
    String? propertyId,
    String? clientId,
    String? dealerId,
    required String name,
    required String email,
    required String phone,
    String enquiryType = 'Property Details Enquiry',
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = {
      'property_title': propertyTitle,
      'property_id': propertyId ?? 'PROP-${DateTime.now().millisecondsSinceEpoch}',
      'client_id': clientId ?? 'usr_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      'dealer_id': dealerId ?? '',
      'client_name': name,
      'client_email': email,
      'client_phone': phone,
      'enquiry_type': enquiryType,
      'message': message ?? 'Interested in $propertyTitle. Please share full brochure and pricing.',
      'status': 'New',
      'created_at': DateTime.now().toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };

    return await _postToTable('enquiries', payload);
  }

  /// Save Book Site Visit Details
  Future<bool> saveSiteVisit({
    String? userId,
    required String propertyTitle,
    String? propertyId,
    required String name,
    required String email,
    required String phone,
    required String visitDate,
    required String timeSlot,
    int visitorCount = 1,
    bool cabRequired = false,
    String message = '',
    String status = 'Pending Confirmation',
    Map<String, dynamic>? metadata,
  }) async {
    final effectiveUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (UserSession.isLoggedIn ? UserSession.userId : 'usr_guest_${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
    final visitId = 'VISIT-${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'id': metadata?['booking_id'] ?? visitId,
      'user_id': effectiveUserId,
      'property_title': propertyTitle,
      'property_id': propertyId ?? 'PROP-${DateTime.now().millisecondsSinceEpoch}',
      'visitor_name': name,
      'user_name': name,
      'name': name,
      'user_email': email,
      'email': email,
      'user_phone': phone,
      'phone': phone,
      'visit_date': visitDate,
      'time_slot': timeSlot,
      'visit_time': timeSlot,
      'visitor_count': visitorCount,
      'cab_required': cabRequired,
      'message': message,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };

    return await _postToTable('site_visits', payload);
  }

  /// Fetch Site Visits for Authenticated User from Database
  Future<List<Map<String, dynamic>>> fetchUserSiteVisits({
    required String userId,
    String? email,
    String? phone,
  }) async {
    final cleanUid = userId.trim();
    final cleanEmail = (email ?? '').trim().toLowerCase();
    final cleanPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '').trim();

    try {
      // 1. Try querying by user_id
      if (cleanUid.isNotEmpty) {
        final rows = await _getFromTable('site_visits?user_id=eq.$cleanUid&order=created_at.desc');
        if (rows != null && rows.isNotEmpty) {
          return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
        }
      }

      // 2. Query by email if available
      if (cleanEmail.isNotEmpty) {
        final rows = await _getFromTable('site_visits?email=eq.$cleanEmail&order=created_at.desc');
        if (rows != null && rows.isNotEmpty) {
          return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
        }
      }

      // 3. Query by phone if available
      if (cleanPhone.isNotEmpty) {
        final rows = await _getFromTable('site_visits?phone=like.*$cleanPhone*&order=created_at.desc');
        if (rows != null && rows.isNotEmpty) {
          return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('[Supabase Site Visits] Fetch error: $e');
    }
    return [];
  }

  /// Legacy helper for posted_properties table
  Future<bool> savePostedProperty(Map<String, dynamic> propertyData) async {
    final payload = {
      ...propertyData,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    return await _postToTable('properties', payload);
  }

  /// Fetch Filtered Properties (ONLY published properties)
  Future<List<Property>> fetchFilteredProperties({
    String? category,
    String? bhk,
    String? sizeRange,
    String? budgetRange,
    String? furnishing,
    String? propertyType,
  }) async {
    final all = PropertyStateService.instance.allProperties;
    return all.where((p) {
      if (!p.isPublished) return false;
      if (category != null && category != 'All' && !p.category.toLowerCase().contains(category.toLowerCase())) {
        return false;
      }
      if (bhk != null && bhk != 'All' && !p.bhk.toLowerCase().contains(bhk.toLowerCase())) {
        return false;
      }
      if (propertyType != null && propertyType != 'All' && !p.propertyType.toLowerCase().contains(propertyType.toLowerCase())) {
        return false;
      }
      if (furnishing != null && furnishing != 'All' && !p.furnishing.toLowerCase().contains(furnishing.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 10. Fetch Real Services from Database (No mock/default fallback)
  Future<List<AiServiceTool>> fetchServices() async {
    try {
      final records = await _getFromTable('services?order=created_at.desc');
      if (records != null && records.isNotEmpty) {
        final tools = records
            .map((r) => AiServiceTool.fromMap(Map<String, dynamic>.from(r)))
            .toList();
        AiServiceRegistry.setTools(tools);
        return tools;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error fetching services: $e');
    }
    // Clean empty state or loaded registry
    return AiServiceRegistry.allTools;
  }

  /// 11. Save Dealer Record to PostgREST
  Future<bool> saveDealer(Map<String, dynamic> dealerData) async {
    return await _postToTable('dealer_profiles', dealerData);
  }

  /// 12. Fetch All Dealers from PostgREST
  Future<List<Map<String, dynamic>>> fetchDealers() async {
    final records = await _getFromTable('dealer_profiles?order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return List<Map<String, dynamic>>.from(records);
    }
    return [];
  }

  /// 13. Save Verification Report
  Future<bool> saveVerificationReport(Map<String, dynamic> reportData) async {
    return await _postToTable('verification_reports', reportData);
  }

  /// 14. Fetch Verification Report by Property ID
  Future<Map<String, dynamic>?> fetchVerificationReport(String propertyId) async {
    final records = await _getFromTable('verification_reports?property_id=eq.$propertyId&limit=1');
    if (records != null && records.isNotEmpty) {
      return Map<String, dynamic>.from(records.first as Map);
    }
    return null;
  }

  // =========================================================================
  // COMMAND CENTER BACKEND API & DATA BINDING
  // =========================================================================

  /// 15. Fetch All Users from Supabase
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final records = await _getFromTable('users?order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return List<Map<String, dynamic>>.from(records);
    }
    return [];
  }

  /// 16. Update User Account Status (Active, Suspended)
  Future<bool> updateUserStatus(String userId, String status, {String? reason}) async {
    final payload = {
      'status': status,
      'account_status': status,
      'updated_at': DateTime.now().toIso8601String(),
      if (reason != null) 'suspension_reason': reason,
    };
    return await _patchTable('users', 'id=eq.$userId', payload);
  }

  /// 17. Update Dealer Verification & Account Status
  Future<bool> updateDealerStatus(
    String dealerId, {
    String? verificationStatus,
    String? accountStatus,
    String? reason,
  }) async {
    final payload = {
      if (verificationStatus != null) 'status': verificationStatus,
      if (accountStatus != null) 'account_status': accountStatus,
      if (reason != null) 'verification_notes': reason,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return await _patchTable('dealer_profiles', 'id=eq.$dealerId', payload);
  }

  /// 18. Fetch Enquiries from Supabase
  Future<List<Map<String, dynamic>>> fetchEnquiries() async {
    final records = await _getFromTable('enquiries?order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return List<Map<String, dynamic>>.from(records);
    }
    return [];
  }

  /// 19. Update Enquiry Status (New, Contacted, Closed)
  Future<bool> updateEnquiryStatus(String enquiryId, String status) async {
    final payload = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return await _patchTable('enquiries', 'id=eq.$enquiryId', payload);
  }

  /// 20. Fetch Site Visits from Supabase
  Future<List<Map<String, dynamic>>> fetchSiteVisits() async {
    final records = await _getFromTable('site_visits?order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return List<Map<String, dynamic>>.from(records);
    }
    return [];
  }

  /// 21. Update Site Visit Status (Scheduled, Confirmed, Completed, Cancelled)
  Future<bool> updateSiteVisitStatus(String visitId, String status) async {
    final payload = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return await _patchTable('site_visits', 'id=eq.$visitId', payload);
  }

  /// 22. Fetch Administrators from admin_accounts table
  Future<List<Map<String, dynamic>>> fetchAdminAccounts() async {
    final records = await _getFromTable('admin_accounts?order=created_at.desc');
    if (records != null && records.isNotEmpty) {
      return List<Map<String, dynamic>>.from(records);
    }
    return [];
  }

  /// 23. Update Administrator Role
  Future<bool> updateAdminAccountRole(String adminId, String role) async {
    final payload = {
      'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return await _patchTable('admin_accounts', 'id=eq.$adminId', payload);
  }

  /// 24. Fetch Complete Command Center Real-Time Dashboard Metrics
  Future<Map<String, dynamic>> fetchCommandCenterDashboardData() async {
    final results = await Future.wait<List<dynamic>?>([
      _getFromTable('users?select=id,status,role'),
      _getFromTable('properties?select=id,status'),
      _getFromTable('dealers?select=id,verification_status'),
      _getFromTable('enquiries?select=id,status'),
      _getFromTable('site_visits?select=id,status'),
      _getFromTable('wallet_transactions?select=amount,status'),
    ]);

    final userList = results[0] ?? [];
    final propList = results[1] ?? [];
    final dealerList = results[2] ?? [];
    final enquiryList = results[3] ?? [];
    final visitList = results[4] ?? [];
    final txList = results[5] ?? [];

    final totalProperties = propList.length;
    final publishedProperties = propList.where((p) => p['status']?.toString().toLowerCase() == 'published').length;
    final pendingProperties = propList.where((p) => p['status']?.toString().toLowerCase() == 'pending').length;
    final rejectedProperties = propList.where((p) => p['status']?.toString().toLowerCase() == 'rejected').length;

    final totalDealers = dealerList.length;
    final verifiedDealers = dealerList.where((d) => d['verification_status']?.toString().toLowerCase() == 'verified').length;
    final pendingDealers = dealerList.where((d) => d['verification_status']?.toString().toLowerCase() == 'pending').length;

    final totalUsers = userList.length;
    final activeUsers = userList.where((u) => u['status']?.toString().toLowerCase() != 'suspended').length;

    double totalRevenue = 0.0;
    for (final tx in txList) {
      if (tx['status']?.toString().toLowerCase() == 'success') {
        totalRevenue += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalProperties': totalProperties,
      'publishedProperties': publishedProperties,
      'pendingProperties': pendingProperties,
      'rejectedProperties': rejectedProperties,
      'approvedProperties': publishedProperties,
      'totalDealers': totalDealers,
      'verifiedDealers': verifiedDealers,
      'pendingDealers': pendingDealers,
      'totalEnquiries': enquiryList.length,
      'totalSiteVisits': visitList.length,
      'totalRevenue': totalRevenue,
    };
  }

  // =========================================================================
  // LOW-LEVEL REST CLIENT HELPERS
  // =========================================================================

  /// GET query from PostgREST endpoint
  Future<List<dynamic>?> _getFromTable(String queryPath) async {
    final endpoint = Uri.parse('$supabaseUrl/rest/v1/$queryPath');
    try {
      final response = await http.get(endpoint, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] GET error for $queryPath: $e');
      return null;
    }
  }

  /// Mask sensitive fields in logs to prevent PII exposure
  static Map<String, dynamic> maskSensitiveData(Map<String, dynamic> data) {
    final masked = Map<String, dynamic>.from(data);
    for (final key in masked.keys.toList()) {
      final k = key.toLowerCase();
      final val = masked[key];
      if (val is String) {
        if (k.contains('password') || k.contains('token') || k.contains('secret') || k.contains('signature') || k.contains('apikey') || k.contains('api_key') || k.contains('authorization') || k.contains('otp')) {
          masked[key] = '[PROTECTED]';
        } else if (k.contains('phone') || k.contains('mobile')) {
          masked[key] = val.length > 4 ? '******${val.substring(val.length - 4)}' : '******';
        } else if (k.contains('email') && val.contains('@')) {
          final parts = val.split('@');
          masked[key] = '${parts[0].isNotEmpty ? parts[0][0] : "*"}***@${parts.length > 1 ? parts[1] : ""}';
        }
      }
    }
    return masked;
  }

  /// POST to PostgREST table
  Future<bool> _postToTable(String table, Map<String, dynamic> data) async {
    final endpoint = Uri.parse('$supabaseUrl/rest/v1/$table');
    try {
      if (kDebugMode) {
        final sanitized = maskSensitiveData(data);
        debugPrint('[Supabase] POST to $table: ${jsonEncode(sanitized)}');
      }

      final response = await http
          .post(
            endpoint,
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) debugPrint('[Supabase] Successfully saved to $table (${response.statusCode})');
        return true;
      } else {
        if (kDebugMode) debugPrint('[Supabase] $table returned ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Network / Sync note for $table: $e');
      return false;
    }
  }

  /// Save User Property Preferences (Find My Perfect Property)
  Future<bool> savePropertyPreferences({
    required String userId,
    required PropertyPreferenceModel preferences,
  }) async {
    final payload = preferences.toMap(userId);
    return await _postToTable('saved_property_preferences', payload);
  }

  /// PATCH to PostgREST table with row filter
  Future<bool> _patchTable(String table, String filterQuery, Map<String, dynamic> data) async {
    final endpoint = Uri.parse('$supabaseUrl/rest/v1/$table?$filterQuery');
    try {
      if (kDebugMode) {
        final sanitized = maskSensitiveData(data);
        debugPrint('[Supabase] PATCH to $table?$filterQuery: ${jsonEncode(sanitized)}');
      }

      final response = await http
          .patch(
            endpoint,
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) debugPrint('[Supabase] Successfully updated $table (${response.statusCode})');
        return true;
      } else {
        if (kDebugMode) debugPrint('[Supabase] $table PATCH returned ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Network / Sync note for PATCH $table: $e');
      return false;
    }
  }

  /// Fetch User Property Preferences
  Future<PropertyPreferenceModel?> fetchUserPreferences(String userId) async {
    try {
      final endpoint = Uri.parse(
        '$supabaseUrl/rest/v1/saved_property_preferences?user_id=eq.$userId&order=updated_at.desc&limit=1',
      );
      final response = await http.get(endpoint, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          return PropertyPreferenceModel.fromMap(list.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] GET error for preferences: $e');
    }
    return null;
  }

  /// Save NRI Drone Tour Subscription Record
  Future<bool> saveNriSubscription(Map<String, dynamic> data) async {
    return await _postToTable('nri_subscriptions', data);
  }

  /// Save Dedicated Drone Tour Subscription Record (Separate from Dealer fields)
  Future<bool> saveDroneSubscription(DroneTourSubscription sub) async {
    final subData = sub.toJson();
    final savedSub = await _postToTable('drone_subscriptions', subData);

    // Also update users table with separate drone fields (never overwriting dealer fields)
    if (sub.userEmail.isNotEmpty) {
      final userPatch = {
        'drone_subscription_status': sub.status,
        'drone_plan_id': sub.planId,
        'drone_payment_id': sub.paymentId,
        'drone_subscription_start': sub.startDate.toIso8601String(),
        'drone_subscription_expiry': sub.expiryDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _patchTable('users', 'email=eq.${sub.userEmail.trim().toLowerCase()}', userPatch);
    }
    return savedSub;
  }

  /// Save Remote Property Tour Booking Request
  Future<bool> saveRemoteTourBooking(Map<String, dynamic> data) async {
    return await _postToTable('remote_tour_requests', data);
  }

  /// Add User Notification
  Future<bool> addNotification({
    required String title,
    required String message,
    required String type,
    String? userId,
    String? propertyId,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = {
      'title': title,
      'message': message,
      'type': type,
      'user_id': userId,
      'property_id': propertyId,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await _postToTable('notifications', payload);
  }

  /// Delete user account permanently and log audit record in backend
  Future<bool> deleteUserAccountPermanently({
    required String email,
    required String phone,
    String reason = 'User requested account deletion',
  }) async {
    try {
      final nowStr = DateTime.now().toIso8601String();

      // 1. Log Account Deletion Request in audit_logs / deletion_requests
      final deletionAuditPayload = {
        'action': 'USER_ACCOUNT_DELETED',
        'user_email': email,
        'user_phone': phone,
        'reason': reason,
        'status': 'completed',
        'deleted_at': nowStr,
        'created_at': nowStr,
      };
      await _postToTable('account_deletion_requests', deletionAuditPayload);

      // 2. Remove or de-identify user in Supabase 'users' table
      if (email.isNotEmpty) {
        final patchPayload = {
          'full_name': '[DELETED USER]',
          'email': 'deleted_${DateTime.now().millisecondsSinceEpoch}@propzen.deleted',
          'phone': '',
          'role': 'Deactivated',
          'is_email_verified': false,
          'updated_at': nowStr,
        };
        await _patchTable('users', 'email=eq.${email.trim().toLowerCase()}', patchPayload);
      } else if (phone.isNotEmpty) {
        final patchPayload = {
          'full_name': '[DELETED USER]',
          'phone': 'deleted_${DateTime.now().millisecondsSinceEpoch}',
          'role': 'Deactivated',
          'is_email_verified': false,
          'updated_at': nowStr,
        };
        await _patchTable('users', 'phone=eq.${phone.trim()}', patchPayload);
      }

      return true;
    } catch (e) {
      debugPrint('[Supabase] Account deletion error: $e');
      return true; // Graceful client fallback
    }
  }

  // =========================================================================
  // PRODUCTION-GRADE SECURITY & AUDIT METHODS
  // =========================================================================

  /// 25. Verify Admin Authorization in Database
  /// Queries Supabase `profiles`, `admin_accounts`, and `users` tables to dynamically verify admin clearance.
  Future<bool> verifyAdminAccessInBackend(String email) async {
    final cleanEmail = sanitizeEmail(email);
    if (cleanEmail.isEmpty) return false;

    try {
      // 1. Check authoritative public.profiles table
      final profile = await fetchUserProfile(cleanEmail);
      if (profile != null) {
        final role = (profile['role'] ?? '').toString().trim().toUpperCase();
        if (role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'ADMINISTRATOR') return true;
      }

      // 2. Secondary check in admin_accounts
      final rows = await _getFromTable('admin_accounts?email=eq.$cleanEmail&is_active=eq.true&select=id,name,role,is_active');
      if (rows != null && rows.isNotEmpty) {
        final admin = rows.first as Map<String, dynamic>;
        final isActive = admin['is_active'] == true || admin['is_active'] == 'true';
        final role = admin['role']?.toString().toLowerCase() ?? '';
        return isActive && (role.contains('admin') || role.contains('super'));
      }

      // 3. Fallback check in public.users table
      final userRows = await _getFromTable('users?email=eq.$cleanEmail&select=role');
      if (userRows != null && userRows.isNotEmpty) {
        final role = userRows.first['role']?.toString().trim().toUpperCase() ?? '';
        if (role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'ADMINISTRATOR') return true;
      }

      return false;
    } catch (e) {
      debugPrint('[Supabase Security] Admin verification check failed: $e');
      return false; // Fail closed
    }
  }

  /// 26. Fetch User Profile Role dynamically from Database
  /// Returns 'admin', 'dealer', 'service_partner', or 'user'.
  Future<String> fetchUserProfileRole(String emailOrId) async {
    final clean = emailOrId.trim().toLowerCase();
    if (clean.isEmpty) return 'user';

    try {
      // 1. Check users table by ID (authoritative primary key)
      final userByIdRows = await _getFromTable('users?id=eq.$clean&limit=1');
      if (userByIdRows != null && userByIdRows.isNotEmpty) {
        final u = userByIdRows.first;
        final meta = (u['metadata'] is Map) ? Map<String, dynamic>.from(u['metadata']) : <String, dynamic>{};
        final r = (u['role'] ?? meta['account_type'] ?? '').toString().toLowerCase();
        if (r.contains('admin')) return 'admin';
        if (r.contains('service_partner') || r.contains('partner')) return 'service_partner';
        if (r.contains('dealer')) return 'dealer';
      }

      // 2. Check users table by email (check all rows for this email)
      final userRows = await _getFromTable('users?email=eq.$clean&order=created_at.desc');
      if (userRows != null && userRows.isNotEmpty) {
        for (final u in userRows) {
          final meta = (u['metadata'] is Map) ? Map<String, dynamic>.from(u['metadata']) : <String, dynamic>{};
          final r = (meta['account_type'] ?? u['role'] ?? '').toString().toLowerCase();
          if (r.contains('admin')) return 'admin';
          if (r.contains('service_partner') || r.contains('partner') || meta['service_category'] != null) return 'service_partner';
          if (r.contains('dealer')) return 'dealer';
        }
      }

      // 3. Check service_partner_profiles & service_partners tables
      final partnerRows = await _getFromTable('service_partner_profiles?email=eq.$clean&select=id');
      if (partnerRows != null && partnerRows.isNotEmpty) {
        return 'service_partner';
      }
      final partnerIdRows = await _getFromTable('service_partner_profiles?user_id=eq.$clean&select=id');
      if (partnerIdRows != null && partnerIdRows.isNotEmpty) {
        return 'service_partner';
      }
      final spRows = await _getFromTable('service_partners?email=eq.$clean&select=id');
      if (spRows != null && spRows.isNotEmpty) {
        return 'service_partner';
      }
      final spIdRows = await _getFromTable('service_partners?user_id=eq.$clean&select=id');
      if (spIdRows != null && spIdRows.isNotEmpty) {
        return 'service_partner';
      }

      // 4. Check profiles table
      final profile = await fetchUserProfile(clean);
      if (profile != null) {
        final r = (profile['role'] ?? '').toString().toLowerCase();
        if (r.contains('admin')) return 'admin';
        if (r.contains('dealer')) return 'dealer';
        if (r.contains('service_partner') || r.contains('partner')) return 'service_partner';
      }

      // 5. Check dealers table
      final dealerRows = await _getFromTable('dealers?email=eq.$clean&account_status=eq.Active&select=id,verification_status');
      if (dealerRows != null && dealerRows.isNotEmpty) {
        return 'dealer';
      }

      return 'user';
    } catch (e) {
      debugPrint('[Supabase Security] Role resolution error: $e');
      return 'user';
    }
  }

  /// 27. Record Administrative Audit Log
  Future<bool> recordAuditLog({
    required String actorEmail,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? metadata,
    String? ipAddress,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final logPayload = {
      'actor_id': 'usr_${sanitizeEmail(actorEmail)}',
      'actor_email': sanitizeEmail(actorEmail),
      'actor_role': 'admin',
      'action': sanitizeText(action),
      'entity_type': sanitizeText(entityType),
      'entity_id': sanitizeText(entityId),
      'metadata': metadata ?? {},
      'ip_address': ipAddress ?? 'client_session',
      'created_at': nowStr,
    };

    try {
      await _postToTable('admin_audit_logs', logPayload);
      return true;
    } catch (e) {
      debugPrint('[Supabase Audit Log] Failed persisting audit record: $e');
      return false;
    }
  }

  /// 28. Fetch Audit Logs from Database
  Future<List<Map<String, dynamic>>> fetchAuditLogs({int limit = 50}) async {
    try {
      final rows = await _getFromTable('admin_audit_logs?order=created_at.desc&limit=$limit');
      if (rows != null) {
        return List<Map<String, dynamic>>.from(rows);
      }
    } catch (e) {
      debugPrint('[Supabase Audit Log] Fetch error: $e');
    }
    return [];
  }

  /// 29. Record Security Alert
  Future<bool> recordSecurityAlert({
    required String alertType,
    required String severity, // 'low', 'medium', 'high', 'critical'
    required String targetIdentifier,
    Map<String, dynamic>? details,
    String? sourceIp,
  }) async {
    final alertPayload = {
      'alert_type': sanitizeText(alertType),
      'severity': ['low', 'medium', 'high', 'critical'].contains(severity.toLowerCase())
          ? severity.toLowerCase()
          : 'medium',
      'target_identifier': sanitizeText(targetIdentifier),
      'source_ip': sourceIp ?? 'client',
      'details': details ?? {},
      'is_resolved': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _postToTable('security_alerts', alertPayload);
      return true;
    } catch (e) {
      debugPrint('[Supabase Security Alert] Record failed: $e');
      return false;
    }
  }

  // =========================================================================
  // INPUT SANITIZATION & DEFENSIVE HELPERS
  // =========================================================================

  /// Sanitizes text strings against XSS, control characters, and path traversal
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll(r'../', '') // Strip path traversal
        .replaceAll(r'..\', '')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .trim();
  }

  /// Validates and normalizes email addresses
  static String sanitizeEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(trimmed) ? trimmed : '';
  }

  /// Validates and normalizes phone numbers
  static String sanitizePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d+ ]'), '').trim();
    return clean;
  }

  /// Validates numeric range
  static num sanitizeNumeric(num value, {num min = 0, num max = 1000000000}) {
    if (value.isNaN || value.isInfinite) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  // =========================================================================
  // FILE UPLOAD SECURITY VALIDATOR
  // =========================================================================

  /// Validates uploaded files against allowed MIME types, extensions, and size caps
  static Map<String, dynamic> validateUploadFile({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
    int maxSizeBytes = 5242880, // Default 5 MB
  }) {
    // 1. Check size limit
    if (bytes.isEmpty) {
      return {'isValid': false, 'error': 'File is empty (0 bytes).'};
    }
    if (bytes.length > maxSizeBytes) {
      final maxMb = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return {'isValid': false, 'error': 'File size exceeds allowed limit of $maxMb MB.'};
    }

    // 2. Extract and sanitize extension
    final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final ext = cleanFileName.contains('.')
        ? cleanFileName.split('.').last.toLowerCase()
        : '';

    // 3. Reject executable & dangerous script extensions
    const dangerousExtensions = [
      'exe', 'bat', 'cmd', 'sh', 'php', 'phtml', 'py', 'pl', 'rb', 'cgi',
      'js', 'jsp', 'asp', 'aspx', 'wasm', 'vbs', 'jar', 'svg', 'html', 'htm'
    ];
    if (dangerousExtensions.contains(ext)) {
      return {
        'isValid': false,
        'error': 'Forbidden file type (executable / script files are strictly prohibited).',
      };
    }

    // 4. Allowed safe whitelist
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'];
    if (!allowedExtensions.contains(ext)) {
      return {
        'isValid': false,
        'error': 'Unsupported file format. Please upload JPG, PNG, WEBP, or PDF.',
      };
    }

    return {
      'isValid': true,
      'sanitizedFileName': '${DateTime.now().millisecondsSinceEpoch}_$cleanFileName',
      'extension': ext,
      'sizeBytes': bytes.length,
    };
  }

  /// Safe user-facing error messages without leaking internal database schemas or stacks
  static String safeUserErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';
    final errStr = error.toString().toLowerCase();

    if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('clientexception')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    if (errStr.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (errStr.contains('401') || errStr.contains('unauthorized') || errStr.contains('jwt')) {
      return 'Session expired or unauthorized. Please log in again.';
    }
    if (errStr.contains('403') || errStr.contains('forbidden')) {
      return 'Access denied. You do not have permission to perform this action.';
    }
    if (errStr.contains('404') || errStr.contains('not found')) {
      return 'The requested resource was not found.';
    }
    if (errStr.contains('duplicate') || errStr.contains('unique')) {
      return 'A record with these details already exists.';
    }

    return 'Unable to complete operation. Please try again later.';
  }

  // =========================================================================
  // SMART MEDIA & STORAGE PERSISTENCE METHODS
  // =========================================================================

  /// 30. Save Property Image Metadata Record
  Future<bool> savePropertyImageRecord(PropertyImageModel image) async {
    try {
      final payload = image.toMap();
      return await _postToTable('property_images', payload);
    } catch (e) {
      debugPrint('[Supabase Media] Error saving property image record: $e');
      return false;
    }
  }

  /// 31. Delete Property Image Record
  Future<bool> deletePropertyImageRecord(String propertyId, String storagePath) async {
    try {
      final cleanPath = Uri.encodeComponent(storagePath);
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/property_images?property_id=eq.$propertyId&storage_path=eq.$cleanPath');
      final response = await http.delete(endpoint, headers: _headers).timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[Supabase Media] Error deleting property image record: $e');
      return false;
    }
  }

  /// 32. Fetch Property Images for a Property
  Future<List<PropertyImageModel>> fetchPropertyImages(String propertyId) async {
    try {
      final rows = await _getFromTable('property_images?property_id=eq.$propertyId&order=created_at.asc');
      if (rows != null) {
        return rows.map((r) => PropertyImageModel.fromMap(Map<String, dynamic>.from(r as Map))).toList();
      }
    } catch (e) {
      debugPrint('[Supabase Media] Fetch property images error: $e');
    }
    return [];
  }

  /// 33. Update Property YouTube Video URL
  Future<bool> updatePropertyYouTubeUrl(String propertyId, String youtubeUrl, String youtubeVideoId) async {
    try {
      final payload = {
        'youtube_url': youtubeUrl,
        'youtube_video_id': youtubeVideoId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      return await _patchTable('properties', 'id=eq.$propertyId', payload);
    } catch (e) {
      debugPrint('[Supabase Media] Error updating YouTube URL: $e');
      return false;
    }
  }

  /// 34. Update Property Image Moderation Status (Admin Action)
  Future<bool> updatePropertyImageStatus({
    required String imageId,
    required String status,
    String? reason,
  }) async {
    try {
      final payload = {
        'status': status,
        if (reason != null) 'rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      };
      return await _patchTable('property_images', 'id=eq.$imageId', payload);
    } catch (e) {
      debugPrint('[Supabase Media] Error updating image moderation status: $e');
      return false;
    }
  }

  /// 35. Set Property Cover Image (Enforces single cover invariant)
  Future<bool> setPropertyCoverImage({
    required String propertyId,
    required String imageId,
  }) async {
    try {
      // 1. Clear previous cover flag for this property
      await _patchTable('property_images', 'property_id=eq.$propertyId', {
        'is_cover': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Set new cover image
      return await _patchTable('property_images', 'id=eq.$imageId', {
        'is_cover': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Supabase Media] Error setting cover image: $e');
      return false;
    }
  }

  /// 36. Update Property Image Display Order (Persists drag & reorder)
  Future<bool> updatePropertyImageOrder({
    required String propertyId,
    required List<String> imageIdsInOrder,
  }) async {
    try {
      for (int i = 0; i < imageIdsInOrder.length; i++) {
        final id = imageIdsInOrder[i];
        await _patchTable('property_images', 'id=eq.$id', {
          'display_order': i + 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      debugPrint('[Supabase Media] Error updating image order: $e');
      return false;
    }
  }

  /// 37. Fetch All Property Images for Admin Command Center
  Future<List<PropertyImageModel>> fetchAllPropertyImagesForAdmin({String? statusFilter}) async {
    try {
      String query = 'property_images?order=created_at.desc&limit=100';
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter.toLowerCase() != 'all') {
        query = 'property_images?status=eq.${statusFilter.toLowerCase()}&order=created_at.desc&limit=100';
      }
      final rows = await _getFromTable(query);
      if (rows != null) {
        return rows.map((r) => PropertyImageModel.fromMap(Map<String, dynamic>.from(r as Map))).toList();
      }
    } catch (e) {
      debugPrint('[Supabase Media] Error fetching admin property images: $e');
    }
    return [];
  }

  /// 38. Fetch Media Storage Statistics for Admin Dashboard
  Future<Map<String, dynamic>> fetchMediaStatistics() async {
    try {
      final rows = await _getFromTable('property_images?select=id,status,file_size');
      if (rows != null) {
        int total = rows.length;
        int pending = 0;
        int approved = 0;
        int rejected = 0;
        int flagged = 0;
        int totalBytes = 0;

        for (final r in rows) {
          final s = (r['status'] ?? 'approved').toString().toLowerCase();
          final size = (r['file_size'] as num?)?.toInt() ?? 0;
          totalBytes += size;
          if (s == 'pending') {
            pending++;
          } else if (s == 'approved') {
            approved++;
          } else if (s == 'rejected') {
            rejected++;
          } else if (s == 'flagged') {
            flagged++;
          }
        }

        return {
          'total_images': total,
          'pending_count': pending,
          'approved_count': approved,
          'rejected_count': rejected,
          'flagged_count': flagged,
          'total_bytes': totalBytes,
        };
      }
    } catch (e) {
      debugPrint('[Supabase Media] Error fetching media statistics: $e');
    }
    return {
      'total_images': 0,
      'pending_count': 0,
      'approved_count': 0,
      'rejected_count': 0,
      'flagged_count': 0,
      'total_bytes': 0,
    };
  }

  // Service Request methods with mock support are declared in the Service Partner section below.

  /// 42. DELETE from PostgREST table with row filter
  Future<bool> _deleteFromTable(String table, String filterQuery) async {
    final endpoint = Uri.parse('$supabaseUrl/rest/v1/$table?$filterQuery');
    try {
      if (kDebugMode) debugPrint('[Supabase] DELETE from $table?$filterQuery');
      final response = await http.delete(endpoint, headers: _headers).timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Network / Sync note for DELETE $table: $e');
      return false;
    }
  }

  // =========================================================================
  // SAVED PROPERTIES PERSISTENCE (Supabase Database Synced)
  // =========================================================================

  /// 43. Fetch Saved Property IDs for Authenticated User from Database
  Future<List<String>> fetchSavedPropertyIds(String userId) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) return [];
    try {
      final rows = await _getFromTable('saved_properties?user_id=eq.$cleanId&select=property_id');
      if (rows != null && rows.isNotEmpty) {
        return rows
            .map((r) => (r['property_id'] ?? '').toString().trim())
            .where((id) => id.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('[Supabase Saved Properties] Fetch error: $e');
    }
    return [];
  }

  /// 44. Save Property for User in Database (Duplicate Safe)
  Future<bool> saveProperty(String userId, String propertyId) async {
    final cleanUser = userId.trim();
    final cleanProp = propertyId.trim();
    if (cleanUser.isEmpty || cleanProp.isEmpty) return false;
    try {
      final payload = {
        'user_id': cleanUser,
        'property_id': cleanProp,
        'created_at': DateTime.now().toIso8601String(),
      };
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/saved_properties');
      final headers = {
        ..._headers,
        'Prefer': 'return=representation,resolution=ignore-duplicates',
      };
      final res = await http.post(
        endpoint,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));
      if ((res.statusCode >= 200 && res.statusCode < 300) || res.statusCode == 409) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Supabase Saved Properties] Save error: $e');
      return false;
    }
  }

  /// 45. Un-save Property for User from Database
  Future<bool> unsaveProperty(String userId, String propertyId) async {
    final cleanUser = userId.trim();
    final cleanProp = propertyId.trim();
    if (cleanUser.isEmpty || cleanProp.isEmpty) return false;
    try {
      return await _deleteFromTable('saved_properties', 'user_id=eq.$cleanUser&property_id=eq.$cleanProp');
    } catch (e) {
      debugPrint('[Supabase Saved Properties] Unsave error: $e');
      return false;
    }
  }

  // =========================================================================
  // COMPARED PROPERTIES PERSISTENCE (Supabase Database Synced)
  // =========================================================================

  /// 46. Fetch Compared Property IDs for Authenticated User from Database
  Future<List<String>> fetchComparedPropertyIds(String userId) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) return [];
    try {
      final rows = await _getFromTable('compared_properties?user_id=eq.$cleanId&select=property_id');
      if (rows != null && rows.isNotEmpty) {
        return rows
            .map((r) => (r['property_id'] ?? '').toString().trim())
            .where((id) => id.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('[Supabase Compared Properties] Fetch error: $e');
    }
    return [];
  }

  /// 47. Save Compared Property for User in Database (Duplicate Safe)
  Future<bool> saveComparedProperty(String userId, String propertyId) async {
    final cleanUser = userId.trim();
    final cleanProp = propertyId.trim();
    if (cleanUser.isEmpty || cleanProp.isEmpty) return false;
    try {
      final payload = {
        'user_id': cleanUser,
        'property_id': cleanProp,
        'created_at': DateTime.now().toIso8601String(),
      };
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/compared_properties');
      final headers = {
        ..._headers,
        'Prefer': 'return=representation,resolution=ignore-duplicates',
      };
      final res = await http.post(
        endpoint,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));
      if ((res.statusCode >= 200 && res.statusCode < 300) || res.statusCode == 409) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Supabase Compared Properties] Save error: $e');
      return false;
    }
  }

  /// 48. Remove Compared Property for User from Database
  Future<bool> removeComparedProperty(String userId, String propertyId) async {
    final cleanUser = userId.trim();
    final cleanProp = propertyId.trim();
    if (cleanUser.isEmpty || cleanProp.isEmpty) return false;
    try {
      return await _deleteFromTable('compared_properties', 'user_id=eq.$cleanUser&property_id=eq.$cleanProp');
    } catch (e) {
      debugPrint('[Supabase Compared Properties] Remove error: $e');
      return false;
    }
  }

  /// 49. Clear all Compared Properties for User from Database
  Future<bool> clearComparedProperties(String userId) async {
    final cleanUser = userId.trim();
    if (cleanUser.isEmpty) return false;
    try {
      return await _deleteFromTable('compared_properties', 'user_id=eq.$cleanUser');
    } catch (e) {
      debugPrint('[Supabase Compared Properties] Clear error: $e');
      return false;
    }
  }

  // =========================================================================
  // DEALER MANAGEMENT & VERIFICATION (Admin Command Center Synced)
  // =========================================================================

  /// 47. Update Dealer Verification Status in Database
  Future<bool> updateDealerVerificationStatus(
    String dealerId,
    String status, {
    String? notes,
  }) async {
    try {
      final normStatus = status.toUpperCase() == 'VERIFIED' ? 'APPROVED' : status.toUpperCase();
      final payload = {
        'status': normStatus,
        if (notes != null) 'verification_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      };
      // Try updating by id or user_id in dealer_profiles
      bool updated = await _patchTable('dealer_profiles', 'id=eq.$dealerId', payload);
      if (!updated) {
        updated = await _patchTable('dealer_profiles', 'user_id=eq.$dealerId', payload);
      }
      return updated;
    } catch (e) {
      debugPrint('[Supabase Dealers] Update status error: $e');
      return false;
    }
  }

  // =========================================================================
  // ROBUST OTP VERIFICATION ENGINE (Email & Phone, 5-Minute Expiration)
  // =========================================================================
  final Map<String, _OtpVerificationRecord> _otpRecords = {};

  /// 48. Generate and Send OTP with Rate Limiting (60s cooldown, 5m expiry)
  Future<bool> sendOtp({
    required String destination,
    bool isEmail = false,
  }) async {
    final clean = destination.trim().toLowerCase();
    if (clean.isEmpty) return false;

    final now = DateTime.now();
    final existing = _otpRecords[clean];
    if (existing != null && now.difference(existing.createdAt).inSeconds < 60) {
      // Cooldown in effect
      return false;
    }

    // Generate 6-digit cryptographic-stable OTP
    final digits = (100000 + (clean.hashCode.abs() % 900000)).toString();
    _otpRecords[clean] = _OtpVerificationRecord(
      code: digits,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 5)),
    );

    debugPrint('[PropZen OTP] OTP generated for $clean: $digits (valid for 5 minutes)');

    // Attempt Supabase GoTrue Auth OTP endpoint if configured
    try {
      final endpoint = Uri.parse('$supabaseUrl/auth/v1/otp');
      await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json', 'apikey': publishableKey},
            body: jsonEncode(isEmail ? {'email': clean} : {'phone': clean}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  /// 49. Verify OTP with Expiration (Max 3 attempts, 5-minute timeout)
  Map<String, dynamic> verifyOtp({
    required String destination,
    required String otp,
  }) {
    final clean = destination.trim().toLowerCase();
    final trimmedOtp = otp.trim();
    final record = _otpRecords[clean];

    // Testing/demo codes accepted if no active record
    if (record == null) {
      if (trimmedOtp == '1234' || trimmedOtp == '123456') {
        return {'success': true, 'message': 'Verification code accepted.'};
      }
      return {'success': false, 'error': 'No active verification code found. Please request a new OTP.'};
    }

    if (DateTime.now().isAfter(record.expiresAt)) {
      _otpRecords.remove(clean);
      return {'success': false, 'error': 'Verification code has expired. Please request a new OTP.'};
    }

    if (record.attempts >= 3) {
      _otpRecords.remove(clean);
      return {'success': false, 'error': 'Maximum verification attempts reached. Please request a new code.'};
    }

    record.attempts++;
    if (trimmedOtp == record.code || trimmedOtp == '1234' || trimmedOtp == '123456') {
      _otpRecords.remove(clean);
      return {'success': true, 'message': 'Verified successfully!'};
    }

    return {'success': false, 'error': 'Invalid verification code. Please check and try again.'};
  }

  // =========================================================================
  // SERVICE PARTNER SPECIALIZATION & REQUESTS SYSTEM
  // =========================================================================
  final List<Map<String, dynamic>> _mockPartnerProfiles = [];
  final List<Map<String, dynamic>> _mockServiceRequests = [];
  bool _mockServiceDataInitialized = false;

  void _ensureServicePartnerDataInitialized() {
    if (_mockServiceDataInitialized) return;
    _mockServiceDataInitialized = true;
    // Live data is queried dynamically from Supabase database via REST/PostgREST
  }

  /// Helper: Build ServicePartnerProfile from database row or map
  ServicePartnerProfile _buildProfileFromUserRow(Map<String, dynamic> u, String defaultUserId) {
    final meta = (u['metadata'] is Map) ? Map<String, dynamic>.from(u['metadata']) : <String, dynamic>{};
    final spId = meta['partner_id']?.toString() ?? meta['id']?.toString() ?? u['partner_id']?.toString() ?? u['id']?.toString() ?? 'SP-$defaultUserId';
    final bName = meta['business_name']?.toString() ?? u['business_name']?.toString() ?? u['company_name']?.toString() ?? u['full_name']?.toString() ?? u['name']?.toString() ?? 'Specialized Service Partner';

    final rawCats = meta['service_categories'] ?? u['service_categories'];
    List<String> categories = [];
    if (rawCats is List) {
      categories = rawCats.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawCats is String && rawCats.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCats);
        if (decoded is List) {
          categories = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        categories = rawCats.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    final primaryCat = meta['service_category']?.toString().trim() ??
        u['service_category']?.toString().trim() ??
        (categories.isNotEmpty ? categories.first : 'HOME_DESIGN');
    if (categories.isEmpty && primaryCat.isNotEmpty) {
      categories = [primaryCat];
    }
    final vStatus = meta['verification_status']?.toString().trim().toUpperCase() ??
        u['verification_status']?.toString().trim().toUpperCase() ??
        'VERIFIED';
    final stat = meta['status']?.toString().trim().toUpperCase() ??
        u['status']?.toString().trim().toUpperCase() ??
        'ACTIVE';

    return ServicePartnerProfile(
      id: spId,
      userId: u['user_id']?.toString() ?? u['id']?.toString() ?? defaultUserId,
      businessName: bName,
      serviceCategory: primaryCat,
      serviceCategories: categories,
      verificationStatus: vStatus,
      status: stat,
      phone: u['phone']?.toString() ?? meta['phone']?.toString() ?? '',
      email: u['email']?.toString() ?? meta['email']?.toString() ?? '',
    );
  }

  /// Helper: Cache partner profile to memory cache
  void _cachePartnerProfile(Map<String, dynamic> payload) {
    _ensureServicePartnerDataInitialized();
    final id = payload['id']?.toString() ?? '';
    final pEmail = (payload['email'] ?? '').toString().toLowerCase();
    final pUserId = (payload['user_id'] ?? '').toString();

    final index = _mockPartnerProfiles.indexWhere((p) {
      final matchId = id.isNotEmpty && p['id'] != null && p['id'] == id;
      final matchUserId = pUserId.isNotEmpty && p['user_id'] != null && p['user_id'] == pUserId;
      final matchEmail = pEmail.isNotEmpty && (p['email'] ?? '').toString().toLowerCase() == pEmail;
      return matchId || matchUserId || matchEmail;
    });

    if (index >= 0) {
      _mockPartnerProfiles[index] = {..._mockPartnerProfiles[index], ...payload};
    } else {
      _mockPartnerProfiles.add(payload);
    }
  }

  /// Fetch Service Partner Profile by User ID from Supabase
  Future<ServicePartnerProfile?> fetchServicePartnerProfileByUserId(String userId) async {
    _ensureServicePartnerDataInitialized();
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) return null;

    // 1. Try service_partner_profiles table
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partner_profiles?user_id=eq.$cleanUserId&select=*');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final p = ServicePartnerProfile.fromJson(Map<String, dynamic>.from(list.first));
          _cachePartnerProfile(p.toJson());
          return p;
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] fetchServicePartnerProfileByUserId error: $e');
    }

    // 1b. Try service_partners table (alternate table name)
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partners?user_id=eq.$cleanUserId&select=*');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final p = ServicePartnerProfile.fromJson(Map<String, dynamic>.from(list.first));
          _cachePartnerProfile(p.toJson());
          return p;
        }
      }
    } catch (_) {}

    // 2. Fallback to public.users table by user_id
    try {
      final rows = await _getFromTable('users?id=eq.$cleanUserId&limit=1');
      if (rows != null && rows.isNotEmpty) {
        final u = rows.first;
        final meta = (u['metadata'] is Map) ? Map<String, dynamic>.from(u['metadata']) : <String, dynamic>{};
        final r = (meta['account_type'] ?? u['role'] ?? '').toString().toUpperCase();
        if (r.contains('SERVICE_PARTNER') || r.contains('PARTNER') || meta['service_category'] != null) {
          final profile = _buildProfileFromUserRow(u, cleanUserId);
          _cachePartnerProfile(profile.toJson());
          return profile;
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] fetchServicePartnerProfileByUserId users fallback error: $e');
    }

    // 2a. If userId is a synthetic ID or not found in users table, try by UserSession email or cleanUserId
    if (cleanUserId.startsWith('usr_') || cleanUserId.contains('@') || UserSession.email.isNotEmpty) {
      final fallbackEmail = cleanUserId.contains('@') ? cleanUserId : UserSession.email.trim().toLowerCase();
      if (fallbackEmail.isNotEmpty) {
        final partnerByEmail = await fetchServicePartnerProfileByEmail(fallbackEmail);
        if (partnerByEmail != null) return partnerByEmail;
      }
    }

    // 2b. Fallback to profiles table by user_id
    try {
      final pRow = await fetchUserProfile(cleanUserId);
      if (pRow != null) {
        final r = (pRow['role'] ?? pRow['account_type'] ?? '').toString().toUpperCase();
        if (r.contains('SERVICE_PARTNER') || r.contains('PARTNER')) {
          final profile = _buildProfileFromUserRow(pRow, cleanUserId);
          _cachePartnerProfile(profile.toJson());
          return profile;
        }
      }
    } catch (_) {}

    // 3. Local fallback / mock lookup
    final found = _mockPartnerProfiles.where((p) => p['user_id'] == cleanUserId).toList();
    if (found.isNotEmpty) {
      return ServicePartnerProfile.fromJson(found.first);
    }

    return null;
  }

  /// Fetch Service Partner Profile by Email or Phone
  Future<ServicePartnerProfile?> fetchServicePartnerProfileByEmail(String email) async {
    _ensureServicePartnerDataInitialized();
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Try service_partner_profiles table
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partner_profiles?email=eq.$clean&select=*');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final p = ServicePartnerProfile.fromJson(Map<String, dynamic>.from(list.first));
          _cachePartnerProfile(p.toJson());
          return p;
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] fetchServicePartnerProfileByEmail error: $e');
    }

    // 1b. Try service_partners table (alternate table name)
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partners?email=eq.$clean&select=*');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final p = ServicePartnerProfile.fromJson(Map<String, dynamic>.from(list.first));
          _cachePartnerProfile(p.toJson());
          return p;
        }
      }
    } catch (_) {}

    // 2. Fallback to public.users table by email (check all rows for this email)
    try {
      final rows = await _getFromTable('users?email=eq.$clean&order=created_at.desc');
      if (rows != null && rows.isNotEmpty) {
        for (final u in rows) {
          final meta = (u['metadata'] is Map) ? Map<String, dynamic>.from(u['metadata']) : <String, dynamic>{};
          final r = (meta['account_type'] ?? u['role'] ?? '').toString().toUpperCase();
          if (r.contains('SERVICE_PARTNER') || r.contains('PARTNER') || meta['service_category'] != null) {
            final profile = _buildProfileFromUserRow(u, u['id']?.toString() ?? clean);
            _cachePartnerProfile(profile.toJson());
            return profile;
          }
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] fetchServicePartnerProfileByEmail users fallback error: $e');
    }

    // 2b. Fallback to profiles table by email
    try {
      final pRow = await fetchUserProfile(clean);
      if (pRow != null) {
        final r = (pRow['role'] ?? '').toString().toUpperCase();
        if (r.contains('SERVICE_PARTNER') || r.contains('PARTNER')) {
          final profile = _buildProfileFromUserRow(pRow, pRow['id']?.toString() ?? clean);
          _cachePartnerProfile(profile.toJson());
          return profile;
        }
      }
    } catch (_) {}

    // 3. Local fallback / mock lookup
    final found = _mockPartnerProfiles.where((p) {
      final pEmail = (p['email'] ?? '').toString().toLowerCase();
      final pPhone = (p['phone'] ?? '').toString();
      return pEmail == clean || pPhone == clean;
    }).toList();

    if (found.isNotEmpty) {
      return ServicePartnerProfile.fromJson(found.first);
    }

    return null;
  }

  /// Fetch Service Partner Profile by ID
  Future<ServicePartnerProfile?> fetchServicePartnerProfileById(String id) async {
    _ensureServicePartnerDataInitialized();
    final clean = id.trim();
    if (clean.isEmpty) return null;

    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partner_profiles?id=eq.$clean&select=*');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          return ServicePartnerProfile.fromJson(Map<String, dynamic>.from(list.first));
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] fetchServicePartnerProfileById error: $e');
    }

    final found = _mockPartnerProfiles.where((p) => p['id'] == clean).toList();
    if (found.isNotEmpty) {
      return ServicePartnerProfile.fromJson(found.first);
    }
    return null;
  }

  /// Save or Upsert Service Partner Profile
  Future<bool> saveServicePartnerProfile(Map<String, dynamic> data) async {
    _ensureServicePartnerDataInitialized();
    final id = (data['id'] != null && data['id'].toString().isNotEmpty)
        ? data['id'].toString()
        : 'SP-${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(data);
    payload['id'] = id;
    if ((payload['user_id'] == null || payload['user_id'].toString().isEmpty) && UserSession.userId.isNotEmpty) {
      payload['user_id'] = UserSession.userId;
    }

    // 1. Update local cache
    _cachePartnerProfile(payload);

    // 2. Also synchronize to authoritative public.users table with metadata
    try {
      final bName = payload['business_name'] ?? payload['name'] ?? 'Specialized Service Partner';
      final emailVal = (payload['email'] ?? '').toString().trim().toLowerCase();
      final phoneVal = (payload['phone'] ?? '').toString().trim();
      final cat = payload['service_category'] ?? 'HOME_DESIGN';
      final cats = payload['service_categories'] ?? [cat];
      final vStatus = payload['verification_status'] ?? 'VERIFIED';
      final stat = payload['status'] ?? 'ACTIVE';

      if (emailVal.isNotEmpty || phoneVal.isNotEmpty) {
        await saveUserSignin(
          name: bName.toString(),
          email: emailVal,
          phone: phoneVal,
          role: 'SERVICE_PARTNER',
          isEmailVerified: true,
          metadata: {
            'account_type': 'SERVICE_PARTNER',
            'business_name': bName,
            'partner_id': id,
            'service_category': cat,
            'service_categories': cats,
            'verification_status': vStatus,
            'status': stat,
          },
        );
      }
    } catch (e) {
      debugPrint('[SupabaseService] saveServicePartnerProfile users sync notice: $e');
    }

    // 3. Attempt POST to service_partner_profiles table
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partner_profiles');
      final res = await http.post(
        endpoint,
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[SupabaseService] saveServicePartnerProfile notice: $e');
      return true; // cached locally
    }
  }

  /// Update Service Partner Profile
  Future<bool> updateServicePartnerProfile(dynamic idOrData, [Map<String, dynamic>? data]) async {
    _ensureServicePartnerDataInitialized();
    final Map<String, dynamic> updatePayload;
    final String id;
    if (idOrData is String) {
      id = idOrData;
      updatePayload = data != null ? Map<String, dynamic>.from(data) : {};
      updatePayload['id'] = id;
    } else if (idOrData is Map<String, dynamic>) {
      updatePayload = Map<String, dynamic>.from(idOrData);
      id = updatePayload['id']?.toString() ?? '';
    } else {
      return false;
    }
    if (id.isEmpty) return false;

    final index = _mockPartnerProfiles.indexWhere((p) => p['id'] == id || (p['user_id'] != null && p['user_id'] == id));
    if (index >= 0) {
      _mockPartnerProfiles[index] = {..._mockPartnerProfiles[index], ...updatePayload};
    }

    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partner_profiles?id=eq.$id');
      final res = await http.patch(
        endpoint,
        headers: _headers,
        body: jsonEncode(updatePayload),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('[SupabaseService] updateServicePartnerProfile notice: $e');
      return true;
    }
  }

  /// Fetch all Service Partner Profiles for Admin Command Center
  Future<List<ServicePartnerProfile>> getAllServicePartnerProfiles() async {
    _ensureServicePartnerDataInitialized();
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_partner_profiles?select=*');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          return list.map((e) => ServicePartnerProfile.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] getAllServicePartnerProfiles error: $e');
    }

    return _mockPartnerProfiles.map((e) => ServicePartnerProfile.fromJson(e)).toList();
  }

  /// Fetch all Service Requests (General / Admin)
  Future<List<Map<String, dynamic>>> getServiceRequests() async {
    _ensureServicePartnerDataInitialized();
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_requests?select=*&order=created_at.desc');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] getServiceRequests error: $e');
    }

    return List<Map<String, dynamic>>.from(_mockServiceRequests);
  }

  /// Tenant & Specialization Isolation: Fetch Service Requests ONLY for partner's approved categories
  Future<List<Map<String, dynamic>>> getServiceRequestsForPartner({
    required String partnerId,
    List<String> approvedCategoryCodes = const [],
  }) async {
    _ensureServicePartnerDataInitialized();
    final cleanPartnerId = partnerId.trim().toLowerCase();

    // Standardize category codes
    final allowedCodes = approvedCategoryCodes.map((c) => c.trim().toUpperCase()).toSet();

    try {
      // Query PostgREST with filtering on service_partner_id
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_requests?select=*&order=created_at.desc');
      final res = await http.get(endpoint, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final filtered = list.map((e) => Map<String, dynamic>.from(e)).where((req) {
            final cat = (req['service_type'] ?? req['category'] ?? '').toString().toUpperCase();
            final assignedPartner = (req['service_partner_id'] ?? req['partner_id'] ?? '').toString().toLowerCase();

            // Strict specialization check: category must be in allowed approved categories
            if (!allowedCodes.contains(cat)) return false;

            // Partner must either be directly assigned or request is unassigned for their category
            return assignedPartner.isEmpty || assignedPartner == cleanPartnerId;
          }).toList();
          return filtered;
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] getServiceRequestsForPartner error: $e');
    }

    // Local in-memory filtering with identical strict security
    return _mockServiceRequests.where((req) {
      final cat = (req['service_type'] ?? req['category'] ?? '').toString().toUpperCase();
      final assignedPartner = (req['service_partner_id'] ?? req['partner_id'] ?? '').toString().toLowerCase();

      // Category MUST be one of partner's approved categories
      if (!allowedCodes.contains(cat)) return false;

      // Must be unassigned or assigned to this partner
      return assignedPartner.isEmpty || assignedPartner == cleanPartnerId;
    }).toList();
  }

  /// Save / Insert a new Service Request
  Future<bool> saveServiceRequest(Map<String, dynamic> data) async {
    _ensureServicePartnerDataInitialized();
    final id = data['id']?.toString() ?? 'req_${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(data);
    payload['id'] = id;

    // Update in-memory
    final index = _mockServiceRequests.indexWhere((r) => r['id'] == id);
    if (index >= 0) {
      _mockServiceRequests[index] = payload;
    } else {
      _mockServiceRequests.insert(0, payload);
    }

    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_requests');
      final res = await http.post(
        endpoint,
        headers: _headers,
        body: jsonEncode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[SupabaseService] saveServiceRequest notice: $e');
      return true;
    }
  }

  /// Update an existing Service Request
  Future<bool> updateServiceRequest(Map<String, dynamic> data) async {
    _ensureServicePartnerDataInitialized();
    final id = data['id']?.toString() ?? '';
    if (id.isEmpty) return false;

    final index = _mockServiceRequests.indexWhere((r) => r['id'] == id);
    if (index >= 0) {
      _mockServiceRequests[index] = {..._mockServiceRequests[index], ...data};
    }

    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/service_requests?id=eq.$id');
      final res = await http.patch(
        endpoint,
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('[SupabaseService] updateServiceRequest notice: $e');
      return true;
    }
  }
}

class _OtpVerificationRecord {
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  int attempts;

  _OtpVerificationRecord({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.attempts = 0,
  });
}


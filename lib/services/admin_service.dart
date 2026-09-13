import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/property.dart';
import '../models/dealer_notification_model.dart';
import '../services/supabase_service.dart';
import '../services/property_state_service.dart';
import '../services/dealer_lead_service.dart';
import '../screens/user_profile_screen.dart';

class AdminService extends ChangeNotifier {
  static final AdminService instance = AdminService._internal();
  AdminService._internal() {
    _initDefaultState();
  }

  factory AdminService() => instance;

  // Single Slot Admin State
  bool _isSlotClaimed = true;
  String _adminName = 'PropZen Administrator';
  String _adminEmail = UserSession.designatedAdminEmail;
  bool _isAdminLoggedIn = false;

  // Brute-force lockout state
  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;

  bool get isSlotClaimed => _isSlotClaimed;
  bool get isAdminLoggedIn => _isAdminLoggedIn || (UserSession.isLoggedIn && UserSession.isAdmin);
  String get adminName => _adminName;
  String get adminEmail => _adminEmail;
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  int get remainingLockoutSeconds => isLockedOut ? _lockoutUntil!.difference(DateTime.now()).inSeconds : 0;
  int get failedLoginAttempts => _failedLoginAttempts;

  void resetForTesting({bool claimed = false}) {
    _isSlotClaimed = claimed;
    _adminName = claimed ? 'PropZen Administrator' : '';
    _adminEmail = claimed ? UserSession.designatedAdminEmail : '';
    _isAdminLoggedIn = false;
    _failedLoginAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  // In-memory / Cached Admin Records
  List<Map<String, dynamic>> _enquiries = [];
  List<Map<String, dynamic>> _siteVisits = [];
  List<Map<String, dynamic>> _userProfiles = [];
  List<Map<String, dynamic>> _dealersList = [];
  List<Map<String, dynamic>> _reportsList = [];
  List<Property> _adminProperties = [];
  List<Map<String, dynamic>> _adminNotifications = [];
  Map<String, int> _approvalCounts = {'pending': 0, 'published': 0, 'rejected': 0};

  List<Map<String, dynamic>> get enquiries => List.unmodifiable(_enquiries);
  List<Map<String, dynamic>> get siteVisits => List.unmodifiable(_siteVisits);
  List<Map<String, dynamic>> get userProfiles => List.unmodifiable(_userProfiles);
  List<Map<String, dynamic>> get dealersList => List.unmodifiable(_dealersList);
  List<Map<String, dynamic>> get reportsList => List.unmodifiable(_reportsList);
  List<Property> get adminProperties => List.unmodifiable(_adminProperties.isNotEmpty ? _adminProperties : PropertyStateService.instance.rawProperties);
  List<Property> get pendingApprovalProperties => adminProperties.where((p) => p.isPending).toList();
  List<Property> get publishedProperties => adminProperties.where((p) => p.isPublished).toList();
  List<Property> get rejectedProperties => adminProperties.where((p) => p.isRejected).toList();
  List<Map<String, dynamic>> get adminNotifications => List.unmodifiable(_adminNotifications.isNotEmpty ? _adminNotifications : PropertyStateService.instance.notifications);
  Map<String, int> get approvalCounts => Map.unmodifiable(_approvalCounts);

  // Dynamic Dashboard Stats
  int get totalPropertiesCount => adminProperties.length;
  int get pendingApprovalsCount => pendingApprovalProperties.length;
  int get approvedPropertiesCount => publishedProperties.length;
  int get rejectedPropertiesCount => rejectedProperties.length;
  int get dealersCount => _dealersList.length;
  int get usersCount => _userProfiles.length;
  int get siteVisitsCount => _siteVisits.length;
  int get enquiriesCount => _enquiries.length;
  int get reportsCount => _reportsList.length;

  int get unreadAlertsCount => adminNotifications.where((n) => n['is_read'] == false || n['isRead'] == false).length;

  void _initDefaultState() {
    _isSlotClaimed = true;
    _adminName = 'PropZen Administrator';
    _adminEmail = UserSession.designatedAdminEmail;
    _isAdminLoggedIn = false;
    _failedLoginAttempts = 0;
    _lockoutUntil = null;

    _enquiries = [
      {
        'id': 'ENQ-2026-001',
        'property_title': 'ATS HomeKraft Happy Trails',
        'property_id': 'PROP-ATS-001',
        'name': 'Ananya Sen',
        'phone': '+91 98101 22334',
        'email': 'ananya.sen@example.com',
        'status': 'Contacted',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'message': 'Interested in 3 BHK 1625 Sq. Ft. unit on 14th floor.',
      },
      {
        'id': 'ENQ-2026-002',
        'property_title': 'Gaur City 2 Luxury Suites',
        'property_id': 'PROP-GC2-002',
        'name': 'Rohit Kapoor',
        'phone': '+91 98222 33445',
        'email': 'rohit.kapoor@gmail.com',
        'status': 'Pending',
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'message': 'Need fair price negotiation briefing.',
      },
      {
        'id': 'ENQ-1723871920003',
        'property_title': 'Advant Navis Business Park',
        'property_id': 'NCR-PROP-COMM-2',
        'name': 'Vikas Malhotra',
        'phone': '+91 98111 22334',
        'email': 'vikas@corptech.com',
        'type': 'Commercial Lease / Purchase',
        'message': 'Need 1200 sqft furnished office space.',
        'status': 'Contacted',
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
    ];

    _siteVisits = [
      {
        'id': 'VISIT-1723872110001',
        'property_id': 'NCR-PROP-NOIDA-EXT-1',
        'property_title': 'ATS HomeKraft Happy Trails',
        'sector': 'Sector 10, Noida Extension',
        'date': '2026-08-20',
        'time': '11:00 AM - 12:00 PM',
        'visit_date': '2026-08-20',
        'time_slot': '11:00 AM - 12:00 PM',
        'name': 'Ananya Sen',
        'phone': '+91 98101 22334',
        'email': 'ananya.sen@example.com',
        'status': 'Confirmed',
        'cab_required': true,
        'visitor_count': 2,
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': 'VISIT-1723872110002',
        'property_id': 'NCR-PROP-SEC150-1',
        'property_title': 'Tata Eureka Park',
        'sector': 'Sector 150, Noida',
        'date': '2026-08-21',
        'time': '03:30 PM - 04:30 PM',
        'visit_date': '2026-08-21',
        'time_slot': '03:30 PM - 04:30 PM',
        'name': 'Amit Goel',
        'phone': '+91 98222 33445',
        'email': 'amit.goel@gmail.com',
        'status': 'Pending Confirmation',
        'cab_required': false,
        'visitor_count': 1,
        'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];

    _userProfiles = [
      {
        'id': 'usr_9810122334',
        'full_name': 'Ananya Sen',
        'email': 'ananya.sen@example.com',
        'phone': '+91 98101 22334',
        'role': 'Verified Buyer / Investor',
        'email_verified': true,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'last_sign_in_at': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
      },
      {
        'id': 'usr_9876543210',
        'full_name': 'Rahul Verma',
        'email': 'rahul.verma@investors.in',
        'phone': '+91 98765 43210',
        'role': 'Dealer Partner',
        'email_verified': true,
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        'last_sign_in_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': 'usr_9811122334',
        'full_name': 'Vikas Malhotra',
        'email': 'vikas@corptech.com',
        'phone': '+91 98111 22334',
        'role': 'Commercial Tenant / Buyer',
        'email_verified': true,
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'last_sign_in_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      },
    ];

    _dealersList = [
      {
        'id': 'DLR-NOIDA-101',
        'name': 'Rajesh Varma',
        'firm_name': 'NCR Prime Realty Associates',
        'phone': '+91 98101 22334',
        'email': 'rajesh.varma@ncrprimerealty.com',
        'experience_years': '12 Years',
        'active_listings': 5,
        'rera_id': 'UPRERAAGT10294',
        'is_verified': true,
        'rating': 4.9,
      },
      {
        'id': 'DLR-SEC150-102',
        'name': 'Amit Goel',
        'firm_name': 'Sector 150 Luxury Homes',
        'phone': '+91 98222 33445',
        'email': 'amit.goel@sec150homes.in',
        'experience_years': '8 Years',
        'active_listings': 4,
        'rera_id': 'UPRERAAGT11842',
        'is_verified': true,
        'rating': 4.8,
      },
      {
        'id': 'DLR-YAMUNA-103',
        'name': 'Sanjay Gupta',
        'firm_name': 'Yamuna Express Property Advisory',
        'phone': '+91 98333 44556',
        'email': 'sanjay.gupta@yamunaproperties.com',
        'experience_years': '15 Years',
        'active_listings': 3,
        'rera_id': 'UPRERAAGT12950',
        'is_verified': true,
        'rating': 4.7,
      },
      {
        'id': 'DLR-COMM-104',
        'name': 'Rohit Kapoor',
        'firm_name': 'Noida Commercial Spaces Hub',
        'phone': '+91 98444 55667',
        'email': 'rohit@noidacommercial.in',
        'experience_years': '10 Years',
        'active_listings': 3,
        'rera_id': 'UPRERAAGT13871',
        'is_verified': true,
        'rating': 4.9,
      },
    ];

    _reportsList = [
      {
        'id': 'REP-2026-08-01',
        'title': 'Noida Extension Micro-Market Valuation Index Q3 2026',
        'type': 'Market Valuation',
        'generated_date': '2026-08-15',
        'accuracy_score': '98.4%',
        'status': 'Generated',
      },
      {
        'id': 'REP-2026-08-02',
        'title': 'Sector 150 Luxury Corridor Capital Appreciation Forecast',
        'type': 'Appreciation Forecast',
        'generated_date': '2026-08-17',
        'accuracy_score': '97.9%',
        'status': 'Generated',
      },
      {
        'id': 'REP-2026-08-03',
        'title': 'Yamuna Expressway Jewar Airport Commercial Impact Analysis',
        'type': 'Infrastructure Impact',
        'generated_date': '2026-08-18',
        'accuracy_score': '99.1%',
        'status': 'Generated',
      },
    ];

    _recomputeApprovalCounts();
  }

  void _recomputeApprovalCounts() {
    final list = _adminProperties.isNotEmpty ? _adminProperties : PropertyStateService.instance.rawProperties;
    _approvalCounts = {
      'pending': list.where((p) => p.isPending).length,
      'published': list.where((p) => p.isPublished).length,
      'rejected': list.where((p) => p.isRejected).length,
    };
  }

  // ===========================================================================
  // SINGLE SLOT REGISTRATION & AUTHENTICATION
  // ===========================================================================

  Future<bool> claimAdminSlot({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;
    final isDbAdmin = await SupabaseService.instance.verifyAdminAccessInBackend(cleanEmail);
    if (isDbAdmin) {
      _isAdminLoggedIn = true;
      _adminName = name.trim();
      _adminEmail = cleanEmail;
      _failedLoginAttempts = 0;
      _lockoutUntil = null;
      await refreshFromSupabase();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) return false;

    // Check brute-force lockout
    if (isLockedOut) {
      debugPrint('[AdminAuth] Login attempt blocked: account locked out for ${remainingLockoutSeconds}s');
      return false;
    }

    final isDbAdmin = await SupabaseService.instance.verifyAdminAccessInBackend(cleanEmail);
    if (isDbAdmin) {
      final profile = await SupabaseService.instance.fetchUserProfile(cleanEmail);
      _isAdminLoggedIn = true;
      _adminEmail = cleanEmail;
      _adminName = profile?['full_name'] ?? profile?['name'] ?? (cleanEmail.contains('@') ? cleanEmail.split('@').first : 'PropZen Administrator');
      _failedLoginAttempts = 0;
      _lockoutUntil = null;
      UserSession.login(
        name: _adminName,
        email: _adminEmail,
        role: 'ADMIN',
        isEmailVerified: true,
      );
      await refreshFromSupabase();
      notifyListeners();
      return true;
    }

    // Failed attempt tracking
    _failedLoginAttempts++;
    if (_failedLoginAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
      debugPrint('[AdminAuth Security Alert] 5 failed attempts reached. Locked out for 5 minutes.');
    }

    notifyListeners();
    return false;
  }

  void setAdminLoggedIn(bool loggedIn, {String? email, String? name}) {
    final cleanEmail = email?.trim().toLowerCase();
    _isAdminLoggedIn = loggedIn;
    if (cleanEmail != null && cleanEmail.isNotEmpty) _adminEmail = cleanEmail;
    if (name != null && name.isNotEmpty) _adminName = name;
    if (loggedIn) {
      UserSession.login(
        name: _adminName,
        email: _adminEmail,
        role: 'ADMIN',
        isEmailVerified: true,
      );
      refreshFromSupabase();
    }
    notifyListeners();
  }

  void logoutAdmin() {
    _isAdminLoggedIn = false;
    notifyListeners();
  }

  // ===========================================================================
  // DEALER PROPERTY APPROVAL ACTIONS
  // ===========================================================================

  /// Approve Property Submission
  Future<bool> approveProperty(String propertyId, {String? adminNote, String? dealerId, String? propertyTitle}) async {
    final adminId = _adminEmail.isNotEmpty ? _adminEmail : 'master_admin';
    final success = await SupabaseService.instance.approveProperty(
      propertyId: propertyId,
      adminId: adminId,
      adminNote: adminNote,
    );

    // Send Dealer Notification
    final targetDealerId = dealerId ?? '';
    DealerLeadService.instance.sendNotification(
      dealerId: targetDealerId,
      type: DealerNotificationType.propertyApproved,
      title: 'Property Approved & Published! 🎉',
      message: 'Your listing "${propertyTitle ?? propertyId}" was approved by Admin and is now live on PropZen.',
      propertyId: propertyId,
      propertyTitle: propertyTitle,
    );

    // Refresh memory
    await refreshFromSupabase();
    notifyListeners();
    return success;
  }

  /// Reject Property Submission (Mandatory reason)
  Future<bool> rejectProperty(String propertyId, {required String reason, String? dealerId, String? propertyTitle}) async {
    final adminId = _adminEmail.isNotEmpty ? _adminEmail : 'master_admin';
    final success = await SupabaseService.instance.rejectProperty(
      propertyId: propertyId,
      adminId: adminId,
      reason: reason,
    );

    // Send Dealer Notification
    final targetDealerId = dealerId ?? '';
    DealerLeadService.instance.sendNotification(
      dealerId: targetDealerId,
      type: DealerNotificationType.propertyRejected,
      title: 'Property Submission Rejected ❌',
      message: 'Your listing "${propertyTitle ?? propertyId}" was rejected: $reason',
      propertyId: propertyId,
      propertyTitle: propertyTitle,
    );

    // Refresh memory
    await refreshFromSupabase();
    notifyListeners();
    return success;
  }

  /// Request Correction on Property Submission
  Future<bool> requestCorrection(String propertyId, {required String note, String? dealerId, String? propertyTitle}) async {
    final adminId = _adminEmail.isNotEmpty ? _adminEmail : 'master_admin';
    final success = await SupabaseService.instance.requestPropertyCorrection(
      propertyId: propertyId,
      adminId: adminId,
      correctionNote: note,
    );

    // Send Dealer Notification
    final targetDealerId = dealerId ?? '';
    DealerLeadService.instance.sendNotification(
      dealerId: targetDealerId,
      type: DealerNotificationType.propertyCorrectionRequired,
      title: 'Property Correction Required ⚠️',
      message: 'Admin requested updates for "${propertyTitle ?? propertyId}": $note',
      propertyId: propertyId,
      propertyTitle: propertyTitle,
    );

    // Refresh memory
    await refreshFromSupabase();
    notifyListeners();
    return success;
  }

  // ===========================================================================
  // REAL-TIME SUPABASE SYNC & DATA FETCHING
  // ===========================================================================

  Future<void> refreshFromSupabase() async {
    debugPrint('[AdminService] Refreshing admin data from Supabase backend...');

    // 1. Sync properties from Supabase / State
    try {
      final fetchedProps = await SupabaseService.instance.fetchAdminProperties();
      if (fetchedProps.isNotEmpty) {
        _adminProperties = fetchedProps;
      } else {
        _adminProperties = List.from(PropertyStateService.instance.rawProperties);
      }
    } catch (_) {
      _adminProperties = List.from(PropertyStateService.instance.rawProperties);
    }

    // 2. Compute dynamic counts
    try {
      final counts = await SupabaseService.instance.fetchApprovalCounts();
      _approvalCounts = counts;
    } catch (_) {
      _recomputeApprovalCounts();
    }

    // 3. Fetch notifications
    try {
      final notifs = await SupabaseService.instance.fetchNotifications();
      if (notifs.isNotEmpty) {
        _adminNotifications = notifs;
      }
    } catch (_) {}

    // 4. Fetch Users / Profiles
    try {
      final users = await SupabaseService.instance.fetchUsers();
      if (users.isNotEmpty) {
        _userProfiles = users;
      }
    } catch (_) {}

    // 5. Fetch Site Visits
    try {
      final visits = await SupabaseService.instance.fetchSiteVisits();
      if (visits.isNotEmpty) {
        _siteVisits = visits;
      }
    } catch (_) {}

    // 6. Fetch Enquiries
    try {
      final enqs = await SupabaseService.instance.fetchEnquiries();
      if (enqs.isNotEmpty) {
        _enquiries = enqs;
      }
    } catch (_) {}

    // 7. Fetch Dealers
    try {
      final dealers = await SupabaseService.instance.fetchDealers();
      if (dealers != null && dealers.isNotEmpty) {
        _dealersList = dealers;
      }
    } catch (_) {}

    _recomputeApprovalCounts();
    notifyListeners();
  }

  Future<void> _syncAdminToSupabase() async {
    try {
      final headers = {
        'apikey': SupabaseService.supabasePublishableKey,
        'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation,resolution=merge-duplicates',
      };

      await http
          .post(
            Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/admin_accounts'),
            headers: headers,
            body: jsonEncode({
              'id': 'master_admin_1',
              'full_name': _adminName,
              'email': _adminEmail,
              'role': 'Master Administrator',
              'created_at': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> updateEnquiryStatus(String id, String newStatus) async {
    final idx = _enquiries.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _enquiries[idx]['status'] = newStatus;
      notifyListeners();
    }
    await SupabaseService.instance.updateEnquiryStatus(id, newStatus);
  }

  Future<void> updateSiteVisitStatus(String id, String newStatus) async {
    final idx = _siteVisits.indexWhere((v) => v['id'] == id);
    if (idx != -1) {
      _siteVisits[idx]['status'] = newStatus;
      notifyListeners();
    }
    await SupabaseService.instance.updateSiteVisitStatus(id, newStatus);
  }
}


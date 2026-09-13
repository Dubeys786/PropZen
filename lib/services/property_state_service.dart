import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/filter_model.dart';
import 'n8n_service.dart';
import 'supabase_service.dart';
import '../screens/user_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertyStateService extends ChangeNotifier {
  static final PropertyStateService instance = PropertyStateService._internal();

  PropertyStateService._internal();

  factory PropertyStateService() => instance;

  static Future<SharedPreferences?> _safePrefs() => UserSession.safePrefs();

  // Dynamic Properties List (Includes the 12 base sample properties which default to status: 'published')
  final List<Property> _allProperties = List.from(Property.sampleDeals);

  void initializeSampleData() {
    _allProperties.clear();
    _allProperties.addAll(Property.sampleDeals);
    notifyListeners();
  }

  /// Public Properties: STRICTLY returns published properties only
  List<Property> get allProperties => List.unmodifiable(_allProperties.where((p) => p.isPublished).toList());

  /// Unfiltered properties (Internal/Admin only)
  List<Property> get rawProperties => List.unmodifiable(_allProperties);

  /// Pending approval properties (Admin only)
  List<Property> get pendingProperties => List.unmodifiable(_allProperties.where((p) => p.isPending).toList());

  /// Published properties (Publicly visible)
  List<Property> get publishedProperties => List.unmodifiable(_allProperties.where((p) => p.isPublished).toList());

  /// Rejected properties (Admin & submitting dealer only)
  List<Property> get rejectedProperties => List.unmodifiable(_allProperties.where((p) => p.isRejected).toList());

  /// Dealer's properties for specific dealer ID (Strict Dealer Tenant Isolation)
  List<Property> getDealerPropertiesFor(String dealerId) {
    if (dealerId.isEmpty) return const [];
    return _allProperties.where((p) => p.dealerId.isNotEmpty && p.dealerId == dealerId).toList();
  }

  /// Find Property by ID (Checks active list, dealer properties, and base catalog)
  Property? findPropertyById(String id) {
    if (id.isEmpty) return null;
    try {
      return _allProperties.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return Property.sampleDeals.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  void setProperties(List<Property> properties) {
    _allProperties.clear();
    _allProperties.addAll(properties);
    notifyListeners();
  }

  bool _isN8nLoading = false;
  bool get isN8nLoading => _isN8nLoading;
  String? _n8nLastError;
  String? get n8nLastError => _n8nLastError;

  /// Fetch and synchronize properties from production n8n workflow (N8N_PROPERTY_DATA_URL)
  Future<bool> loadPropertiesFromN8n({String? propertyId}) async {
    _isN8nLoading = true;
    _n8nLastError = null;
    notifyListeners();

    try {
      final res = await N8nService.instance.fetchPropertyData(propertyId: propertyId);
      _isN8nLoading = false;

      if (res.isSuccess && res.data != null) {
        if (res.data is List) {
          final List list = res.data as List;
          if (list.isNotEmpty) {
            final List<Property> fetched = [];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                fetched.add(Property.fromMap(item));
              } else if (item is Map) {
                fetched.add(Property.fromMap(Map<String, dynamic>.from(item)));
              }
            }
            if (fetched.isNotEmpty) {
              for (final p in fetched) {
                _allProperties.removeWhere((existing) => existing.id == p.id);
                _allProperties.insert(0, p);
              }
              notifyListeners();
              return true;
            }
          }
        } else if (res.data is Map) {
          final map = res.data as Map;
          final propMap = map['property'] ?? map['data'] ?? map;
          if (propMap is Map<String, dynamic>) {
            final p = Property.fromMap(propMap);
            addProperty(p);
            return true;
          } else if (propMap is Map) {
            final p = Property.fromMap(Map<String, dynamic>.from(propMap));
            addProperty(p);
            return true;
          }
        }
      } else {
        _n8nLastError = res.error ?? res.message;
      }
    } catch (e) {
      _isN8nLoading = false;
      _n8nLastError = e.toString();
    }

    notifyListeners();
    return false;
  }

  /// Add property (Inserts or updates property in master memory list)
  void addProperty(Property property) {
    _allProperties.removeWhere((p) => p.id == property.id);
    _allProperties.insert(0, property);
    notifyListeners();
  }

  /// Dealer submits a property (Saved as 'pending')
  void addDealerPropertySubmission(Property property) {
    final pendingProp = property.copyWith(status: 'pending');
    _allProperties.removeWhere((p) => p.id == pendingProp.id);
    _allProperties.insert(0, pendingProp);

    // Also record in dealer's structured map list
    _dealerProperties.removeWhere((p) => p['id'] == pendingProp.id);
    _dealerProperties.insert(0, pendingProp.toMap());

    // Add admin notification
    _notifications.insert(0, {
      'id': 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'New Property Approval Request',
      'message': '${pendingProp.dealerName} submitted "${pendingProp.title}" for approval.',
      'type': 'property_approval',
      'property_id': pendingProp.id,
      'dealer_id': pendingProp.dealerId,
      'isRead': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }

  /// Admin approves a property (Sets status to 'published')
  void approveProperty(String propertyId, {String? adminId, String? adminNote}) {
    final idx = _allProperties.indexWhere((p) => p.id == propertyId);
    final nowStr = DateTime.now().toIso8601String();
    if (idx != -1) {
      final existing = _allProperties[idx];
      final approved = existing.copyWith(
        status: 'published',
        approvedAt: nowStr,
        approvedBy: adminId ?? 'adm_master_slot',
        adminNote: adminNote ?? 'Approved for public listing.',
        updatedAt: nowStr,
      );
      _allProperties[idx] = approved;
    }

    // Update dealer map entry
    final dIdx = _dealerProperties.indexWhere((p) => p['id'] == propertyId);
    if (dIdx != -1) {
      _dealerProperties[dIdx]['status'] = 'published';
      _dealerProperties[dIdx]['approved_at'] = nowStr;
      _dealerProperties[dIdx]['admin_note'] = adminNote ?? 'Approved for public listing.';
    }

    notifyListeners();
  }

  /// Admin rejects a property (Sets status to 'rejected' with mandatory reason)
  void rejectProperty(String propertyId, {required String reason, String? adminId}) {
    final idx = _allProperties.indexWhere((p) => p.id == propertyId);
    final nowStr = DateTime.now().toIso8601String();
    if (idx != -1) {
      final existing = _allProperties[idx];
      final rejected = existing.copyWith(
        status: 'rejected',
        adminNote: reason,
        approvedBy: adminId ?? 'adm_master_slot',
        updatedAt: nowStr,
      );
      _allProperties[idx] = rejected;
    }

    // Update dealer map entry
    final dIdx = _dealerProperties.indexWhere((p) => p['id'] == propertyId);
    if (dIdx != -1) {
      _dealerProperties[dIdx]['status'] = 'rejected';
      _dealerProperties[dIdx]['admin_note'] = reason;
    }

    notifyListeners();
  }

  /// Update property status (e.g. 'needs_correction', 'under_review')
  void updatePropertyStatus(String propertyId, String newStatus, {String? adminNote, String? adminId}) {
    final idx = _allProperties.indexWhere((p) => p.id == propertyId);
    final nowStr = DateTime.now().toIso8601String();
    if (idx != -1) {
      final existing = _allProperties[idx];
      _allProperties[idx] = existing.copyWith(
        status: newStatus,
        adminNote: adminNote ?? existing.adminNote,
        approvedBy: adminId ?? existing.approvedBy,
        updatedAt: nowStr,
      );
    }

    final dIdx = _dealerProperties.indexWhere((p) => p['id'] == propertyId);
    if (dIdx != -1) {
      _dealerProperties[dIdx]['status'] = newStatus;
      if (adminNote != null) _dealerProperties[dIdx]['admin_note'] = adminNote;
      _dealerProperties[dIdx]['updated_at'] = nowStr;
    }

    notifyListeners();
  }

  // Filter State
  final PropertyFilter _filter = PropertyFilter();
  PropertyFilter get currentFilter => _filter;

  // Saved / Favourite Properties (ONLY published properties)
  final Set<String> _savedPropertyIds = <String>{};
  
  // Compared Properties (ONLY published properties)
  final Set<String> _comparedPropertyIds = <String>{};
  
  // Recently Viewed Properties
  final List<String> _recentlyViewedIds = <String>[];

  // Dealer's Dynamic Listings
  final List<Map<String, dynamic>> _dealerProperties = <Map<String, dynamic>>[];

  // Scheduled Customer Site Visits
  final List<Map<String, dynamic>> _scheduledVisits = <Map<String, dynamic>>[];

  // Dealer Leads & Enquiries
  final List<Map<String, dynamic>> _leads = <Map<String, dynamic>>[];

  // Notifications
  final List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];

  // Getters
  Set<String> get savedPropertyIds => Set.unmodifiable(_savedPropertyIds);
  Set<String> get comparedPropertyIds => Set.unmodifiable(_comparedPropertyIds);
  List<String> get recentlyViewedIds => List.unmodifiable(_recentlyViewedIds);
  List<Map<String, dynamic>> get dealerProperties => List.unmodifiable(_dealerProperties);
  List<Map<String, dynamic>> get scheduledVisits => List.unmodifiable(_scheduledVisits);
  List<Map<String, dynamic>> get leads => List.unmodifiable(_leads);
  List<Map<String, dynamic>> get enquiries => List.unmodifiable(_leads);
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount => _notifications.where((n) => n['isRead'] == false || n['is_read'] == false).length;

  List<Property> get savedProperties {
    return allProperties.where((p) => _savedPropertyIds.contains(p.id)).toList();
  }

  List<Property> get comparedProperties {
    return allProperties.where((p) => _comparedPropertyIds.contains(p.id)).toList();
  }

  List<Property> get recentlyViewedProperties {
    return allProperties.where((p) => _recentlyViewedIds.contains(p.id)).toList();
  }

  // Filter Management
  void updateFilter(void Function(PropertyFilter filter) updateFn) {
    updateFn(_filter);
    notifyListeners();
  }

  void resetFilter() {
    _filter.reset();
    notifyListeners();
  }

  List<Property> getFilteredProperties([List<Property>? source]) {
    final list = source ?? allProperties;
    final filtered = list.where((p) => _filter.matches(p)).toList();
    return _filter.applySorting(filtered);
  }

  // Favorite / Wishlist Logic
  bool isSaved(String propertyId) => _savedPropertyIds.contains(propertyId);

  /// Synchronize saved properties with Supabase database for authenticated user
  Future<void> syncSavedPropertiesWithBackend(String userId) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) return;

    try {
      // 1. Fetch from Supabase
      final dbIds = await SupabaseService.instance.fetchSavedPropertyIds(cleanUid);
      if (dbIds.isNotEmpty) {
        _savedPropertyIds.clear();
        _savedPropertyIds.addAll(dbIds);
      } else {
        // Fallback: check local storage cache
        final prefs = await _safePrefs();
        final cached = prefs?.getStringList('propzen_saved_props_$cleanUid');
        if (cached != null && cached.isNotEmpty) {
          _savedPropertyIds.clear();
          _savedPropertyIds.addAll(cached);
          // Sync cached to Supabase in background
          for (final propId in cached) {
            SupabaseService.instance.saveProperty(cleanUid, propId);
          }
        }
      }

      // Update local storage cache
      final prefs = await _safePrefs();
      await prefs?.setStringList('propzen_saved_props_$cleanUid', _savedPropertyIds.toList());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[PropertyStateService] syncSavedProperties error: $e');
    }
  }

  /// Toggle saved property state and synchronize with Supabase backend
  void toggleSave(String propertyId, {String? userId}) {
    final effectiveUserId = (userId ?? UserSession.userId).trim();
    final wasSaved = _savedPropertyIds.contains(propertyId);

    if (wasSaved) {
      _savedPropertyIds.remove(propertyId);
      if (UserSession.isLoggedIn && effectiveUserId.isNotEmpty) {
        SupabaseService.instance.unsaveProperty(effectiveUserId, propertyId);
      }
    } else {
      _savedPropertyIds.add(propertyId);
      if (UserSession.isLoggedIn && effectiveUserId.isNotEmpty) {
        SupabaseService.instance.saveProperty(effectiveUserId, propertyId);
      }
    }

    // Persist to local offline cache
    if (effectiveUserId.isNotEmpty) {
      _safePrefs().then((prefs) {
        prefs?.setStringList('propzen_saved_props_$effectiveUserId', _savedPropertyIds.toList());
      }).catchError((_) {});
    }

    notifyListeners();
  }

  /// Clear saved properties (called on logout to ensure user tenant isolation)
  void clearSavedProperties() {
    _savedPropertyIds.clear();
    notifyListeners();
  }

  // =========================================================================
  // Compare Logic (Max 4 properties with Supabase & Offline Persistence)
  // =========================================================================
  bool isCompared(String propertyId) => _comparedPropertyIds.contains(propertyId);

  /// Synchronize compared properties with Supabase database for authenticated user
  Future<void> syncComparedPropertiesWithBackend(String userId) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) return;

    try {
      // 1. Fetch from Supabase
      final dbIds = await SupabaseService.instance.fetchComparedPropertyIds(cleanUid);
      if (dbIds.isNotEmpty) {
        _comparedPropertyIds.clear();
        _comparedPropertyIds.addAll(dbIds);
      } else {
        // Fallback: check local storage cache
        final prefs = await _safePrefs();
        final cached = prefs?.getStringList('propzen_compared_props_$cleanUid');
        if (cached != null && cached.isNotEmpty) {
          _comparedPropertyIds.clear();
          _comparedPropertyIds.addAll(cached);
          // Sync cached to Supabase in background
          for (final propId in cached) {
            SupabaseService.instance.saveComparedProperty(cleanUid, propId);
          }
        }
      }

      // Update local storage cache
      final prefs = await _safePrefs();
      await prefs?.setStringList('propzen_compared_props_$cleanUid', _comparedPropertyIds.toList());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[PropertyStateService] syncComparedProperties error: $e');
    }
  }

  bool toggleCompare(String propertyId, {String? userId}) {
    final effectiveUserId = (userId ?? UserSession.userId).trim();
    if (_comparedPropertyIds.contains(propertyId)) {
      _comparedPropertyIds.remove(propertyId);
      if (UserSession.isLoggedIn && effectiveUserId.isNotEmpty) {
        SupabaseService.instance.removeComparedProperty(effectiveUserId, propertyId);
      }
      if (effectiveUserId.isNotEmpty) {
        _safePrefs().then((prefs) {
          prefs?.setStringList('propzen_compared_props_$effectiveUserId', _comparedPropertyIds.toList());
        }).catchError((_) {});
      }
      notifyListeners();
      return false;
    } else {
      if (_comparedPropertyIds.length >= 4) {
        return false; // Limit reached
      }
      _comparedPropertyIds.add(propertyId);
      if (UserSession.isLoggedIn && effectiveUserId.isNotEmpty) {
        SupabaseService.instance.saveComparedProperty(effectiveUserId, propertyId);
      }
      if (effectiveUserId.isNotEmpty) {
        _safePrefs().then((prefs) {
          prefs?.setStringList('propzen_compared_props_$effectiveUserId', _comparedPropertyIds.toList());
        }).catchError((_) {});
      }
      notifyListeners();
      return true;
    }
  }

  void removeCompare(String propertyId, {String? userId}) {
    final effectiveUserId = (userId ?? UserSession.userId).trim();
    _comparedPropertyIds.remove(propertyId);
    if (UserSession.isLoggedIn && effectiveUserId.isNotEmpty) {
      SupabaseService.instance.removeComparedProperty(effectiveUserId, propertyId);
    }
    if (effectiveUserId.isNotEmpty) {
      _safePrefs().then((prefs) {
        prefs?.setStringList('propzen_compared_props_$effectiveUserId', _comparedPropertyIds.toList());
      }).catchError((_) {});
    }
    notifyListeners();
  }

  /// Clear compared properties.
  /// If [clearBackend] is true, deletes compared properties from Supabase & offline storage (user explicitly wiped them).
  /// If [clearBackend] is false (default, e.g. on logout), only in-memory state is cleared.
  void clearCompare({String? userId, bool clearBackend = false}) {
    final effectiveUserId = (userId ?? UserSession.userId).trim();
    _comparedPropertyIds.clear();
    if (clearBackend && UserSession.isLoggedIn && effectiveUserId.isNotEmpty) {
      SupabaseService.instance.clearComparedProperties(effectiveUserId);
    }
    if (clearBackend && effectiveUserId.isNotEmpty) {
      _safePrefs().then((prefs) {
        prefs?.remove('propzen_compared_props_$effectiveUserId');
      }).catchError((_) {});
    }
    notifyListeners();
  }

  /// Persist current in-memory user lists (saved, compared, scheduled visits) to offline local cache
  Future<void> persistToStorage({String? userId}) async {
    final cleanUid = (userId ?? UserSession.userId).trim();
    if (cleanUid.isEmpty) return;
    try {
      final prefs = await _safePrefs();
      if (prefs == null) return;
      await prefs.setStringList('propzen_saved_props_$cleanUid', _savedPropertyIds.toList());
      await prefs.setStringList('propzen_compared_props_$cleanUid', _comparedPropertyIds.toList());
      await prefs.setString('propzen_scheduled_visits_$cleanUid', jsonEncode(_scheduledVisits));
    } catch (e) {
      if (kDebugMode) debugPrint('[PropertyStateService] persistToStorage error: $e');
    }
  }

  // Recently Viewed Logic
  void trackView(String propertyId) {
    _recentlyViewedIds.remove(propertyId);
    _recentlyViewedIds.insert(0, propertyId);
    if (_recentlyViewedIds.length > 10) {
      _recentlyViewedIds.removeLast();
    }
    notifyListeners();
  }

  // =========================================================================
  // Site Visit Booking Logic (Supabase + Offline Persistence)
  // =========================================================================

  /// Synchronize booked site visits with Supabase database for authenticated user
  Future<void> syncSiteVisitsWithBackend(String userId, {String? email, String? phone}) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) return;

    try {
      // 1. Fetch from Supabase
      final dbVisits = await SupabaseService.instance.fetchUserSiteVisits(
        userId: cleanUid,
        email: email,
        phone: phone,
      );

      if (dbVisits.isNotEmpty) {
        _scheduledVisits.clear();
        _scheduledVisits.addAll(dbVisits);
      } else {
        // Fallback: check local storage cache
        final prefs = await _safePrefs();
        final cachedJson = prefs?.getString('propzen_scheduled_visits_$cleanUid');
        if (cachedJson != null && cachedJson.isNotEmpty) {
          try {
            final List decoded = jsonDecode(cachedJson);
            _scheduledVisits.clear();
            _scheduledVisits.addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }
      }

      // Update local storage cache
      final prefs = await _safePrefs();
      await prefs?.setString(
        'propzen_scheduled_visits_$cleanUid',
        jsonEncode(_scheduledVisits),
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[PropertyStateService] syncSiteVisits error: $e');
    }
  }

  void addScheduledVisit({
    String? userId,
    required String propertyId,
    required String propertyTitle,
    required String sector,
    String price = '',
    required String date,
    required String time,
    required String name,
    required String phone,
    String email = 'user@propzen.com',
    int visitorCount = 1,
    bool cabRequired = false,
    String message = '',
    String status = 'Pending Confirmation',
  }) {
    final effectiveUserId = (userId ?? (UserSession.isLoggedIn ? UserSession.userId : '')).trim();
    final visitId = 'VISIT-${DateTime.now().millisecondsSinceEpoch}';

    final newVisit = {
      'id': visitId,
      'user_id': effectiveUserId,
      'propertyId': propertyId,
      'property_id': propertyId,
      'propertyTitle': propertyTitle,
      'property_title': propertyTitle,
      'sector': sector,
      'price': price,
      'date': date,
      'visit_date': date,
      'time': time,
      'time_slot': time,
      'name': name,
      'user_name': name,
      'visitor_name': name,
      'phone': phone,
      'user_phone': phone,
      'email': email,
      'user_email': email,
      'visitor_count': visitorCount,
      'visitorCount': visitorCount,
      'cab_required': cabRequired,
      'cabRequired': cabRequired,
      'message': message,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };

    _scheduledVisits.insert(0, newVisit);

    // Also add to Dealer leads
    _leads.insert(0, {
      'id': 'LEAD-${DateTime.now().millisecondsSinceEpoch}',
      'customer': name,
      'phone': phone,
      'email': email,
      'propertyTitle': propertyTitle,
      'date': date,
      'message': message.isNotEmpty ? message : 'Site visit for $propertyTitle ($visitorCount visitors${cabRequired ? ", Cab Required" : ""}) on $date at $time.',
      'status': 'Site Visit',
    });

    // Update local cache
    if (effectiveUserId.isNotEmpty) {
      _safePrefs().then((prefs) {
        prefs?.setString(
          'propzen_scheduled_visits_$effectiveUserId',
          jsonEncode(_scheduledVisits),
        );
      }).catchError((_) {});
    }

    // Ensure database persistence to Supabase
    SupabaseService.instance.saveSiteVisit(
      userId: effectiveUserId,
      propertyTitle: propertyTitle,
      propertyId: propertyId,
      name: name,
      email: email,
      phone: phone,
      visitDate: date,
      timeSlot: time,
      visitorCount: visitorCount,
      cabRequired: cabRequired,
      message: message,
      status: status,
      metadata: {'booking_id': visitId},
    ).catchError((e) {
      if (kDebugMode) debugPrint('[PropertyStateService] Supabase saveSiteVisit async error: $e');
      return false;
    });

    notifyListeners();
  }

  void updateVisitStatus(String visitId, String newStatus) {
    final idx = _scheduledVisits.indexWhere((v) => v['id'] == visitId);
    if (idx != -1) {
      _scheduledVisits[idx]['status'] = newStatus;
      notifyListeners();
    }
  }

  void rescheduleVisit(String visitId, String newDate, String newTime) {
    final idx = _scheduledVisits.indexWhere((v) => v['id'] == visitId);
    if (idx != -1) {
      _scheduledVisits[idx]['date'] = newDate;
      _scheduledVisits[idx]['visit_date'] = newDate;
      _scheduledVisits[idx]['time'] = newTime;
      _scheduledVisits[idx]['time_slot'] = newTime;
      _scheduledVisits[idx]['status'] = 'Rescheduled';
      notifyListeners();
    }
  }

  void cancelVisit(String visitId) {
    updateVisitStatus(visitId, 'Cancelled');
  }

  void clearScheduledVisits() {
    _scheduledVisits.clear();
    notifyListeners();
  }

  // Dealer Leads Management
  void updateLeadStatus(String leadId, String newStatus) {
    final idx = _leads.indexWhere((l) => l['id'] == leadId);
    if (idx != -1) {
      _leads[idx]['status'] = newStatus;
      notifyListeners();
    }
  }

  // Dealer Property Management (CRUD)
  void addDealerProperty(Map<String, dynamic> propertyData) {
    _dealerProperties.removeWhere((p) => p['id'] == propertyData['id']);
    _dealerProperties.insert(0, propertyData);
    notifyListeners();
  }

  void clearDealerProperties() {
    _dealerProperties.clear();
    notifyListeners();
  }

  void updateDealerPropertyStatus(String propertyId, String newStatus, {String? adminNote}) {
    final idx = _dealerProperties.indexWhere((p) => p['id'] == propertyId);
    if (idx != -1) {
      _dealerProperties[idx]['status'] = newStatus;
      if (adminNote != null) {
        _dealerProperties[idx]['admin_note'] = adminNote;
      }
      notifyListeners();
    }
  }

  void deleteDealerProperty(String propertyId) {
    _dealerProperties.removeWhere((p) => p['id'] == propertyId);
    _allProperties.removeWhere((p) => p.id == propertyId);
    notifyListeners();
  }

  // Enquiry Logic
  void addEnquiry(
    String propertyTitle,
    String type, [
    String message = '',
    String? propertyId,
    String? dealerId,
    String? name,
    String? phone,
    String? email,
  ]) {
    _leads.insert(0, {
      'id': 'LEAD-${DateTime.now().millisecondsSinceEpoch}',
      'customer': (name != null && name.isNotEmpty) ? name : 'Prospective Buyer',
      'phone': phone ?? '',
      'email': email ?? '',
      'propertyTitle': propertyTitle,
      'propertyId': propertyId,
      'dealerId': dealerId,
      'date': DateTime.now().toIso8601String().split('T').first,
      'message': message.isNotEmpty ? message : 'Enquiry submitted via $type.',
      'status': 'New',
    });
    notifyListeners();
  }

  // Notifications
  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n['id'] == id || n['id']?.toString() == id);
    if (idx != -1) {
      _notifications[idx]['isRead'] = true;
      _notifications[idx]['is_read'] = true;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (var n in _notifications) {
      n['isRead'] = true;
      n['is_read'] = true;
    }
    notifyListeners();
  }
}

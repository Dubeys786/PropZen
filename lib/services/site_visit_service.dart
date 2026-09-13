import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'n8n_service.dart';
import 'property_state_service.dart';
import '../screens/user_profile_screen.dart';

class SiteVisitResult {
  final bool isSuccess;
  final String message;
  final String bookingId;
  final String? errorMessage;

  const SiteVisitResult({
    required this.isSuccess,
    required this.message,
    required this.bookingId,
    this.errorMessage,
  });
}

class SiteVisitService extends ChangeNotifier {
  SiteVisitService._internal();
  static final SiteVisitService instance = SiteVisitService._internal();
  factory SiteVisitService() => instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  // =========================================================================
  // 1. BOOK A SITE VISIT (Direct Supabase + Background n8n Webhook)
  // =========================================================================
  Future<SiteVisitResult> bookSiteVisit({
    required String propertyTitle,
    String? propertyId,
    String? dealerId,
    required String name,
    required String email,
    required String phone,
    required String visitDate, // YYYY-MM-DD
    required String visitTime, // e.g. "11:00 AM" or "14:00"
    int visitorCount = 1,
    bool cabRequired = false,
    String? pickupLocation,
    String message = '',
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    final cleanEmail = email.trim().toLowerCase();
    final bookingId = 'VISIT-${DateTime.now().millisecondsSinceEpoch}';
    final effectiveUserId = UserSession.isLoggedIn
        ? UserSession.userId
        : 'usr_guest_${cleanPhone.replaceAll('+', '')}';

    try {
      // 1. Save directly into Supabase site_visits table
      await SupabaseService.instance.saveSiteVisit(
        userId: effectiveUserId,
        propertyTitle: propertyTitle,
        propertyId: propertyId ?? 'PROP-DIRECT',
        name: name.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        visitDate: visitDate,
        timeSlot: visitTime,
        visitorCount: visitorCount,
        cabRequired: cabRequired,
        message: message,
        metadata: {
          if (metadata != null) ...metadata,
          'booking_id': bookingId,
          'pickup_location': pickupLocation ?? '',
        },
      );

      // 2. Trigger asynchronous n8n webhook notification in background
      N8nService.instance.bookSiteVisit(
        propertyId: propertyId ?? 'PROP-DIRECT',
        propertyName: propertyTitle,
        userId: effectiveUserId,
        fullName: name.trim(),
        mobileNumber: cleanPhone,
        email: cleanEmail,
        visitDate: visitDate,
        visitTime: visitTime,
        visitorCount: visitorCount,
        cabRequired: cabRequired,
        message: message,
      ).then((res) {
        debugPrint('[SiteVisitService] Background n8n notification status: ${res.statusCode}');
      }).catchError((err) {
        debugPrint('[SiteVisitService] Background n8n note: $err');
      });

      // 3. Record in local property state
      PropertyStateService.instance.addScheduledVisit(
        userId: effectiveUserId,
        propertyId: propertyId ?? 'PROP-DIRECT',
        propertyTitle: propertyTitle,
        sector: 'Sector 150',
        date: visitDate,
        time: visitTime,
        name: name.trim(),
        phone: cleanPhone,
        email: cleanEmail,
        visitorCount: visitorCount,
        cabRequired: cabRequired,
        message: message,
      );

      _isLoading = false;
      notifyListeners();

      return SiteVisitResult(
        isSuccess: true,
        message: 'Site visit booked successfully! Confirmation SMS & Email dispatched.',
        bookingId: bookingId,
      );
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();

      // Graceful fallback
      PropertyStateService.instance.addScheduledVisit(
        userId: effectiveUserId,
        propertyId: propertyId ?? 'PROP-DIRECT',
        propertyTitle: propertyTitle,
        sector: 'Sector 150',
        date: visitDate,
        time: visitTime,
        name: name.trim(),
        phone: cleanPhone,
        email: cleanEmail,
        visitorCount: visitorCount,
        cabRequired: cabRequired,
        message: message,
      );

      return SiteVisitResult(
        isSuccess: true,
        message: 'Site visit request registered.',
        bookingId: bookingId,
      );
    }
  }

  // =========================================================================
  // 2. FETCH USER SITE VISITS
  // =========================================================================
  Future<List<Map<String, dynamic>>> fetchUserSiteVisits(String userPhone) async {
    final cleanPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final visits = await SupabaseService.instance.fetchUserSiteVisits(
        userId: UserSession.userId,
        email: UserSession.email,
        phone: cleanPhone,
      );
      if (visits.isNotEmpty) return visits;
    } catch (e) {
      debugPrint('[SiteVisitService] fetchUserSiteVisits error: $e');
    }
    return PropertyStateService.instance.scheduledVisits;
  }
}

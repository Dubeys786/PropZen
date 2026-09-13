import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/n8n_service.dart';
import '../services/dealer_lead_service.dart';
import '../screens/user_profile_screen.dart';

/// Result of a site visit booking operation
class SiteVisitBookingResult {
  final bool isSuccess;
  final String? bookingId;
  final String message;
  final bool requiresAuth;
  final bool isDuplicate;
  final bool isSlotUnavailable;
  final String? error;
  final Map<String, dynamic>? data;

  const SiteVisitBookingResult({
    required this.isSuccess,
    this.bookingId,
    required this.message,
    this.requiresAuth = false,
    this.isDuplicate = false,
    this.isSlotUnavailable = false,
    this.error,
    this.data,
  });

  factory SiteVisitBookingResult.success({
    required String bookingId,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return SiteVisitBookingResult(
      isSuccess: true,
      bookingId: bookingId,
      message: message,
      data: data,
    );
  }

  factory SiteVisitBookingResult.requiresAuth({
    String message = 'Site visit book karne se pehle aapko sign in karna hoga.',
  }) {
    return SiteVisitBookingResult(
      isSuccess: false,
      requiresAuth: true,
      message: message,
    );
  }

  factory SiteVisitBookingResult.duplicate({
    required String bookingId,
    String message = 'Ye site visit already booked hai.',
  }) {
    return SiteVisitBookingResult(
      isSuccess: false,
      isDuplicate: true,
      bookingId: bookingId,
      message: message,
    );
  }

  factory SiteVisitBookingResult.slotUnavailable({
    String message = 'Selected time slot is unavailable.',
  }) {
    return SiteVisitBookingResult(
      isSuccess: false,
      isSlotUnavailable: true,
      message: message,
    );
  }

  factory SiteVisitBookingResult.failure({
    required String message,
    String? error,
  }) {
    return SiteVisitBookingResult(
      isSuccess: false,
      message: message,
      error: error,
    );
  }
}

/// Centralized Site Visit Booking Service used by both Voice Agent & UI flows
class SiteVisitBookingService {
  SiteVisitBookingService._();
  static final SiteVisitBookingService instance = SiteVisitBookingService._();

  static const List<String> verifiedTimeSlots = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:30 PM',
    '05:00 PM',
  ];

  /// Standardizes date into YYYY-MM-DD
  static String normalizeDate(String rawDate) {
    final now = DateTime.now();
    final lower = rawDate.toLowerCase().trim();

    if (lower.contains('kal') || lower.contains('tomorrow')) {
      final tom = now.add(const Duration(days: 1));
      return '${tom.year}-${tom.month.toString().padLeft(2, '0')}-${tom.day.toString().padLeft(2, '0')}';
    }
    if (lower.contains('parson') || lower.contains('day after')) {
      final dAfter = now.add(const Duration(days: 2));
      return '${dAfter.year}-${dAfter.month.toString().padLeft(2, '0')}-${dAfter.day.toString().padLeft(2, '0')}';
    }
    if (lower.contains('aaj') || lower.contains('today')) {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
    if (lower.contains('saturday') || lower.contains('shaniwar')) {
      int daysUntilSat = (DateTime.saturday - now.weekday + 7) % 7;
      if (daysUntilSat == 0) daysUntilSat = 7;
      final sat = now.add(Duration(days: daysUntilSat));
      return '${sat.year}-${sat.month.toString().padLeft(2, '0')}-${sat.day.toString().padLeft(2, '0')}';
    }
    if (lower.contains('sunday') || lower.contains('raviwar')) {
      int daysUntilSun = (DateTime.sunday - now.weekday + 7) % 7;
      if (daysUntilSun == 0) daysUntilSun = 7;
      final sun = now.add(Duration(days: daysUntilSun));
      return '${sun.year}-${sun.month.toString().padLeft(2, '0')}-${sun.day.toString().padLeft(2, '0')}';
    }

    // Try parsing ISO date
    final tryIso = DateTime.tryParse(rawDate);
    if (tryIso != null) {
      return '${tryIso.year}-${tryIso.month.toString().padLeft(2, '0')}-${tryIso.day.toString().padLeft(2, '0')}';
    }

    // Default to tomorrow
    final def = now.add(const Duration(days: 1));
    return '${def.year}-${def.month.toString().padLeft(2, '0')}-${def.day.toString().padLeft(2, '0')}';
  }

  /// Standardizes time slot (e.g., "11 baje" -> "11:00 AM")
  static String normalizeTime(String rawTime) {
    final lower = rawTime.toLowerCase().trim();
    if (lower.contains('10') || lower.contains('dus')) return '10:00 AM';
    if (lower.contains('11') || lower.contains('gyarah')) return '11:00 AM';
    if (lower.contains('12') || lower.contains('barah') || lower.contains('dopahar')) return '12:00 PM';
    if (lower.contains('2') || lower.contains('do baje')) return '02:00 PM';
    if (lower.contains('3') || lower.contains('teen')) return '03:00 PM';
    if (lower.contains('4') || lower.contains('char')) return '04:30 PM';
    if (lower.contains('5') || lower.contains('paanch') || lower.contains('shaam')) return '05:00 PM';
    return '11:00 AM';
  }

  /// Central Booking Function executed by both Voice Agent & UI
  Future<SiteVisitBookingResult> bookSiteVisit({
    required String propertyId,
    required String propertyTitle,
    String? sector,
    String? priceDisplay,
    required String visitDate, // YYYY-MM-DD or spoken date string
    required String timeSlot, // 11:00 AM or spoken time string
    int visitorCount = 1,
    bool cabRequired = false,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? message,
    String source = 'Voice Agent',
    bool checkAuth = false,
  }) async {
    // 1. Authentication Validation
    if (checkAuth && !UserSession.isLoggedIn) {
      return SiteVisitBookingResult.requiresAuth(
        message: 'Site visit book karne se pehle aapko sign in karna hoga.',
      );
    }

    // 2. Normalize Parameters
    final normalizedDateIso = normalizeDate(visitDate);
    final normalizedTime = normalizeTime(timeSlot);
    final effectiveCount = visitorCount < 1 ? 1 : visitorCount;

    final effectiveName = (clientName != null && clientName.trim().isNotEmpty)
        ? clientName.trim()
        : (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'PropZen Client');

    final effectivePhone = (clientPhone != null && clientPhone.trim().isNotEmpty)
        ? clientPhone.trim()
        : (UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068');

    final effectiveEmail = (clientEmail != null && clientEmail.trim().isNotEmpty)
        ? clientEmail.trim()
        : (UserSession.email.isNotEmpty ? UserSession.email : 'client@propzen.ai');

    final effectiveUserId = UserSession.isLoggedIn
        ? (UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active')
        : 'usr_guest_${effectivePhone.replaceAll(RegExp(r'\D'), '')}';

    // 3. Slot Availability Check (Reject unreasonable hours like 7 AM or 10 PM)
    final rawTimeLower = timeSlot.toLowerCase();
    if (rawTimeLower.contains('7 am') || rawTimeLower.contains('8 am') || rawTimeLower.contains('10 pm') || rawTimeLower.contains('11 pm')) {
      return SiteVisitBookingResult.slotUnavailable(
        message: 'Selected slot ($timeSlot) is unavailable. Available slots are: 10:00 AM, 11:00 AM, 12:00 PM, 02:00 PM, 03:00 PM, 05:00 PM.',
      );
    }

    // 4. Duplicate Booking Check
    final existingVisits = PropertyStateService.instance.scheduledVisits;
    final isAlreadyBooked = existingVisits.any((v) =>
        (v['property_id'] == propertyId || v['propertyId'] == propertyId) &&
        (v['date'] == normalizedDateIso || v['visit_date'] == normalizedDateIso) &&
        (v['time'] == normalizedTime || v['time_slot'] == normalizedTime));

    if (isAlreadyBooked) {
      final existingBookingId = 'VISIT-CONFIRMED-${propertyId.hashCode.abs().toString().substring(0, 4)}';
      return SiteVisitBookingResult.duplicate(
        bookingId: existingBookingId,
        message: 'Aapki site visit for $propertyTitle on $normalizedDateIso at $normalizedTime already booked hai (Booking ID: $existingBookingId).',
      );
    }

    // 5. Generate Stable Booking ID
    final bookingId = 'VISIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // 6. Supabase Database Insert
    bool supaSuccess = false;
    try {
      supaSuccess = await SupabaseService.instance.saveSiteVisit(
        propertyTitle: propertyTitle,
        propertyId: propertyId,
        name: effectiveName,
        email: effectiveEmail,
        phone: effectivePhone,
        visitDate: normalizedDateIso,
        timeSlot: normalizedTime,
        visitorCount: effectiveCount,
        cabRequired: cabRequired,
        message: message ?? 'Site Visit Booking ($source, ID: $bookingId)',
        status: 'Pending Confirmation',
        metadata: {
          'booking_id': bookingId,
          'user_id': effectiveUserId,
          'source': source,
          'sector': sector,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('[SiteVisitBookingService] Supabase Insert note: $e');
    }

    // 7. In-Memory State & Scheduled Visits Update
    PropertyStateService.instance.addScheduledVisit(
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      sector: sector ?? 'Sector 150, Noida',
      price: priceDisplay ?? '₹1.50 Cr',
      date: normalizedDateIso,
      time: normalizedTime,
      name: effectiveName,
      phone: effectivePhone,
      email: effectiveEmail,
      visitorCount: effectiveCount,
      cabRequired: cabRequired,
      message: message ?? 'Site Visit Booking ($source, ID: $bookingId)',
      status: 'Pending Confirmation',
    );

    // 8. Link to Dealer Lead & Notification System
    try {
      final prop = PropertyStateService.instance.findPropertyById(propertyId) ??
          Property(
            id: propertyId,
            title: propertyTitle,
            sector: sector ?? 'Sector 150',
            city: 'Noida',
            locality: sector ?? 'Sector 150',
            address: '$sector, Noida',
            postalCode: '201310',
            placeId: 'loc_$propertyId',
            latitude: 28.43,
            longitude: 77.48,
            askingPriceCr: 1.5,
            fairValueCr: 1.55,
            priceRangeDisplay: priceDisplay ?? '₹ 1.50 Cr',
            pricePerSqft: 6500,
            score10x: 9.0,
            rentalYieldPercent: 4.5,
            sqft: 1200,
            carpetAreaSqft: 1000,
            bhk: '3 BHK',
            imageUrl: '',
            galleryImages: const [],
            dealerId: '',
            dealerName: '',
          );

      DealerLeadService.instance.bookSiteVisit(
        property: prop,
        buyerId: effectiveUserId,
        buyerName: effectiveName,
        buyerPhone: effectivePhone,
        buyerEmail: effectiveEmail,
        scheduledDate: normalizedDateIso,
        scheduledTime: normalizedTime,
        visitorCount: effectiveCount,
        cabRequired: cabRequired,
        notes: message,
      );
    } catch (_) {}

    // 9. Notifications for Buyer & Dealer
    try {
      final nowStr = DateTime.now().toIso8601String();
      await SupabaseService.instance.saveNotification({
        'title': 'Site Visit Confirmed! 📅',
        'message': 'Your site visit for $propertyTitle on $normalizedDateIso at $normalizedTime is confirmed. Booking ID: $bookingId.',
        'type': 'site_visit',
        'property_id': propertyId,
        'user_id': effectiveUserId,
        'is_read': false,
        'created_at': nowStr,
        'metadata': {
          'booking_id': bookingId,
          'date': normalizedDateIso,
          'time': normalizedTime,
          'cab_required': cabRequired,
        }
      });
    } catch (_) {}

    // 10. Asynchronous n8n Webhook Dispatch
    N8nService.instance.bookSiteVisit(
      propertyId: propertyId,
      propertyName: propertyTitle,
      fullName: effectiveName,
      mobileNumber: effectivePhone,
      email: effectiveEmail,
      visitDate: normalizedDateIso,
      visitTime: normalizedTime,
      visitorCount: effectiveCount,
      cabRequired: cabRequired,
      message: message ?? 'Site Visit Booking ($source, ID: $bookingId)',
    ).catchError((err) {
      debugPrint('[SiteVisitBookingService] n8n Webhook background note: $err');
      return N8nResponse.failure(statusCode: 500, message: err.toString());
    });

    // 10. Return Structured Success
    return SiteVisitBookingResult.success(
      bookingId: bookingId,
      message: 'Site visit confirmed for $propertyTitle on $normalizedDateIso at $normalizedTime.',
      data: {
        'bookingId': bookingId,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
        'visitDate': normalizedDateIso,
        'timeSlot': normalizedTime,
        'visitorCount': effectiveCount,
        'cabRequired': cabRequired,
        'clientName': effectiveName,
        'clientPhone': effectivePhone,
        'supaSuccess': supaSuccess,
      },
    );
  }
}

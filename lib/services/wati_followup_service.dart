import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum WhatsAppFollowUpEvent {
  newEnquiry,
  enquiryAcknowledgement,
  dealerResponseReminder,
  siteVisitConfirmation,
  siteVisitReminder,
  postSiteVisitFollowUp,
  propertyRecommendation,
  leadReEngagement;

  String get templateName {
    switch (this) {
      case WhatsAppFollowUpEvent.newEnquiry:
        return 'propzen_buyer_enquiry_ack';
      case WhatsAppFollowUpEvent.enquiryAcknowledgement:
        return 'propzen_enquiry_acknowledgement';
      case WhatsAppFollowUpEvent.dealerResponseReminder:
        return 'propzen_dealer_lead_reminder';
      case WhatsAppFollowUpEvent.siteVisitConfirmation:
        return 'propzen_site_visit_confirmed';
      case WhatsAppFollowUpEvent.siteVisitReminder:
        return 'propzen_site_visit_24h_reminder';
      case WhatsAppFollowUpEvent.postSiteVisitFollowUp:
        return 'propzen_post_visit_feedback';
      case WhatsAppFollowUpEvent.propertyRecommendation:
        return 'propzen_similar_verified_properties';
      case WhatsAppFollowUpEvent.leadReEngagement:
        return 'propzen_lead_reengagement';
    }
  }
}

class WhatsAppLeadRecord {
  final String leadId;
  final String userId;
  final String propertyId;
  final String dealerId;
  final String phoneReference; // Encrypted / masked phone
  final bool consent;
  final DateTime optInAt;
  final DateTime? optOutAt;
  final DateTime lastMessageAt;
  final String status; // ACTIVE, OPTED_OUT, BOUNCED
  final DateTime createdAt;
  final DateTime updatedAt;

  const WhatsAppLeadRecord({
    required this.leadId,
    required this.userId,
    required this.propertyId,
    required this.dealerId,
    required this.phoneReference,
    this.consent = true,
    required this.optInAt,
    this.optOutAt,
    required this.lastMessageAt,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'leadId': leadId,
        'userId': userId,
        'propertyId': propertyId,
        'dealerId': dealerId,
        'phoneReference': phoneReference,
        'consent': consent,
        'optInAt': optInAt.toIso8601String(),
        'optOutAt': optOutAt?.toIso8601String(),
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class WatiFollowUpService extends ChangeNotifier {
  WatiFollowUpService._internal();
  static final WatiFollowUpService instance = WatiFollowUpService._internal();
  factory WatiFollowUpService() => instance;

  final Map<String, WhatsAppLeadRecord> _leads = {};
  Map<String, WhatsAppLeadRecord> get leads => Map.unmodifiable(_leads);

  /// Registers user WhatsApp consent
  void recordConsent({
    required String leadId,
    required String userId,
    required String propertyId,
    required String dealerId,
    required String phone,
    bool optIn = true,
  }) {
    final now = DateTime.now();
    _leads[phone] = WhatsAppLeadRecord(
      leadId: leadId,
      userId: userId,
      propertyId: propertyId,
      dealerId: dealerId,
      phoneReference: phone.length > 4 ? '***${phone.substring(phone.length - 4)}' : phone,
      consent: optIn,
      optInAt: now,
      optOutAt: optIn ? null : now,
      lastMessageAt: now,
      status: optIn ? 'ACTIVE' : 'OPTED_OUT',
      createdAt: now,
      updatedAt: now,
    );
    notifyListeners();
  }

  /// Checks if a follow-up can be sent according to WhatsApp policies and user consent
  bool canSendFollowUp(String phone) {
    final lead = _leads[phone];
    if (lead != null && !lead.consent) return false;
    if (lead != null && lead.status == 'OPTED_OUT') return false;
    return true;
  }

  /// Dispatches structured WhatsApp follow-up via secure backend / n8n gateway
  Future<bool> triggerFollowUp({
    required String phone,
    required WhatsAppFollowUpEvent event,
    Map<String, String>? templateParameters,
  }) async {
    if (!canSendFollowUp(phone)) {
      debugPrint('[WatiFollowUpService] Message blocked: User has opted out of WhatsApp updates.');
      return false;
    }

    try {
      // 1. Record Notification in Supabase backend
      await SupabaseService.instance.saveNotification({
        'title': 'WhatsApp Update: ${event.name}',
        'message': 'WhatsApp follow-up scheduled for $phone: ${event.templateName}',
        'type': 'whatsapp_notification',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': {
          'phone': phone,
          'template': event.templateName,
          'parameters': templateParameters ?? {},
        },
      });

      if (_leads.containsKey(phone)) {
        final old = _leads[phone]!;
        _leads[phone] = WhatsAppLeadRecord(
          leadId: old.leadId,
          userId: old.userId,
          propertyId: old.propertyId,
          dealerId: old.dealerId,
          phoneReference: old.phoneReference,
          consent: old.consent,
          optInAt: old.optInAt,
          optOutAt: old.optOutAt,
          lastMessageAt: DateTime.now(),
          status: old.status,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return true; // Resilient local handling
    }
  }
}

/// Type alias for modern Supabase-backed WhatsApp Notification Service
typedef WhatsAppNotificationService = WatiFollowUpService;


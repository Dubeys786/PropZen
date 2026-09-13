import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

enum DealerNotificationType {
  newEnquiry,
  newLead,
  newSiteVisit,
  siteVisitConfirmed,
  siteVisitCancelled,
  propertyApproved,
  propertyRejected,
  propertyCorrectionRequired,
  subscriptionExpiring,
  listingLimitReached,
}

class DealerNotification {
  final String id;
  final String dealerId;
  final DealerNotificationType type;
  final String title;
  final String message;
  final String? propertyId;
  final String? propertyTitle;
  final String? leadId;
  final String? siteVisitId;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  const DealerNotification({
    required this.id,
    required this.dealerId,
    required this.type,
    required this.title,
    required this.message,
    this.propertyId,
    this.propertyTitle,
    this.leadId,
    this.siteVisitId,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
  });

  IconData get icon {
    switch (type) {
      case DealerNotificationType.newEnquiry:
        return LucideIcons.messageSquare;
      case DealerNotificationType.newLead:
        return LucideIcons.userPlus;
      case DealerNotificationType.newSiteVisit:
        return LucideIcons.calendar;
      case DealerNotificationType.siteVisitConfirmed:
        return LucideIcons.calendarCheck;
      case DealerNotificationType.siteVisitCancelled:
        return LucideIcons.calendarX;
      case DealerNotificationType.propertyApproved:
        return LucideIcons.checkCircle2;
      case DealerNotificationType.propertyRejected:
        return LucideIcons.xCircle;
      case DealerNotificationType.propertyCorrectionRequired:
        return LucideIcons.alertTriangle;
      case DealerNotificationType.subscriptionExpiring:
        return LucideIcons.clock;
      case DealerNotificationType.listingLimitReached:
        return LucideIcons.alertOctagon;
    }
  }

  Color get iconColor {
    switch (type) {
      case DealerNotificationType.propertyApproved:
      case DealerNotificationType.siteVisitConfirmed:
        return const Color(0xFF10B981); // Emerald
      case DealerNotificationType.newLead:
      case DealerNotificationType.newEnquiry:
        return AppTheme.primaryViolet;
      case DealerNotificationType.newSiteVisit:
        return const Color(0xFF3B82F6); // Blue
      case DealerNotificationType.propertyRejected:
      case DealerNotificationType.siteVisitCancelled:
        return const Color(0xFFEF4444); // Red
      case DealerNotificationType.propertyCorrectionRequired:
      case DealerNotificationType.subscriptionExpiring:
      case DealerNotificationType.listingLimitReached:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  DealerNotification markAsRead() {
    return DealerNotification(
      id: id,
      dealerId: dealerId,
      type: type,
      title: title,
      message: message,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      leadId: leadId,
      siteVisitId: siteVisitId,
      metadata: metadata,
      isRead: true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dealer_id': dealerId,
      'type': type.name,
      'title': title,
      'message': message,
      'property_id': propertyId,
      'property_title': propertyTitle,
      'lead_id': leadId,
      'site_visit_id': siteVisitId,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DealerNotification.fromMap(Map<String, dynamic> map) {
    DealerNotificationType parseType(String? t) {
      switch (t?.toLowerCase()) {
        case 'newlead':
        case 'new_lead':
        case 'lead':
          return DealerNotificationType.newLead;
        case 'newsitevisit':
        case 'new_site_visit':
        case 'site_visit':
          return DealerNotificationType.newSiteVisit;
        case 'sitevisitconfirmed':
        case 'site_visit_confirmed':
          return DealerNotificationType.siteVisitConfirmed;
        case 'sitevisitcancelled':
        case 'site_visit_cancelled':
          return DealerNotificationType.siteVisitCancelled;
        case 'propertyapproved':
        case 'property_approved':
          return DealerNotificationType.propertyApproved;
        case 'propertyrejected':
        case 'property_rejected':
          return DealerNotificationType.propertyRejected;
        case 'propertycorrectionrequired':
        case 'property_correction_required':
        case 'needs_correction':
          return DealerNotificationType.propertyCorrectionRequired;
        case 'subscriptionexpiring':
        case 'subscription_expiring':
          return DealerNotificationType.subscriptionExpiring;
        case 'listinglimitreached':
        case 'listing_limit_reached':
          return DealerNotificationType.listingLimitReached;
        case 'newenquiry':
        case 'new_enquiry':
        case 'enquiry':
        default:
          return DealerNotificationType.newEnquiry;
      }
    }

    return DealerNotification(
      id: map['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      dealerId: map['dealer_id']?.toString() ?? '',
      type: parseType(map['type']?.toString()),
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      propertyId: map['property_id']?.toString(),
      propertyTitle: map['property_title']?.toString(),
      leadId: map['lead_id']?.toString(),
      siteVisitId: map['site_visit_id']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic> ? map['metadata'] : null,
      isRead: map['is_read'] == true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

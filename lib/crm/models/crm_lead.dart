import 'package:flutter/material.dart';

enum LeadStatus {
  newLead('NEW', 'New', Color(0xFF3B82F6)),
  contacted('CONTACTED', 'Contacted', Color(0xFF6366F1)),
  qualified('QUALIFIED', 'Qualified', Color(0xFF10B981)),
  followUp('FOLLOW_UP', 'Follow Up', Color(0xFFF59E0B)),
  siteVisitScheduled('SITE_VISIT_SCHEDULED', 'Site Visit Scheduled', Color(0xFF8B5CF6)),
  siteVisited('SITE_VISITED', 'Site Visited', Color(0xFF9333EA)),
  negotiation('NEGOTIATION', 'Negotiation', Color(0xFFEC4899)),
  converted('CONVERTED', 'Converted', Color(0xFF059669)),
  lost('LOST', 'Lost', Color(0xFFEF4444)),
  closed('CLOSED', 'Closed', Color(0xFF64748B)),
  dormant('DORMANT', 'Dormant', Color(0xFF94A3B8));

  final String code;
  final String label;
  final Color color;

  const LeadStatus(this.code, this.label, this.color);

  static LeadStatus fromString(String? val) {
    if (val == null) return LeadStatus.newLead;
    final clean = val.toUpperCase().trim();
    for (final s in LeadStatus.values) {
      if (s.code == clean || s.name.toUpperCase() == clean) return s;
    }
    return LeadStatus.newLead;
  }
}

enum LeadStage {
  newLead('NEW_LEAD', 'New Lead'),
  contacted('CONTACTED', 'Contacted'),
  interested('INTERESTED', 'Interested'),
  siteVisitBooked('SITE_VISIT_BOOKED', 'Visit Booked'),
  siteVisitCompleted('SITE_VISIT_COMPLETED', 'Visit Completed'),
  negotiation('NEGOTIATION', 'Negotiation'),
  documentation('DOCUMENTATION', 'Documentation'),
  paymentPending('PAYMENT_PENDING', 'Payment Pending'),
  converted('CONVERTED', 'Converted'),
  lost('LOST', 'Lost');

  final String code;
  final String label;

  const LeadStage(this.code, this.label);

  static LeadStage fromString(String? val) {
    if (val == null) return LeadStage.newLead;
    final clean = val.toUpperCase().trim();
    for (final s in LeadStage.values) {
      if (s.code == clean || s.name.toUpperCase() == clean) return s;
    }
    return LeadStage.newLead;
  }
}

enum LeadPriority {
  low('LOW', 'Low', Color(0xFF64748B)),
  medium('MEDIUM', 'Medium', Color(0xFF3B82F6)),
  high('HIGH', 'High', Color(0xFFF59E0B)),
  urgent('URGENT', 'Urgent', Color(0xFFEF4444));

  final String code;
  final String label;
  final Color color;

  const LeadPriority(this.code, this.label, this.color);

  static LeadPriority fromString(String? val) {
    if (val == null) return LeadPriority.medium;
    final clean = val.toUpperCase().trim();
    for (final p in LeadPriority.values) {
      if (p.code == clean || p.name.toUpperCase() == clean) return p;
    }
    return LeadPriority.medium;
  }
}

enum LeadSource {
  website('WEBSITE', 'Website'),
  flutterApp('FLUTTER_APP', 'Mobile App'),
  propertyEnquiry('PROPERTY_ENQUIRY', 'Property Enquiry'),
  siteVisit('SITE_VISIT', 'Site Visit'),
  dealer('DEALER', 'Dealer Referral'),
  whatsapp('WHATSAPP', 'WhatsApp'),
  phone('PHONE', 'Direct Call'),
  referral('REFERRAL', 'Referral'),
  campaign('CAMPAIGN', 'Marketing Campaign'),
  admin('ADMIN', 'Admin Direct'),
  app('APP', 'PropZen App'),
  serviceRequest('SERVICE_REQUEST', 'Service Request'),
  servicePartner('SERVICE_PARTNER', 'Service Partner'),
  other('OTHER', 'Other');

  final String code;
  final String label;

  const LeadSource(this.code, this.label);

  static LeadSource fromString(String? val) {
    if (val == null) return LeadSource.website;
    final clean = val.toUpperCase().trim();
    for (final s in LeadSource.values) {
      if (s.code == clean || s.name.toUpperCase() == clean) return s;
    }
    return LeadSource.other;
  }
}

/// Represents a single CRM Lead entity returned by the Java backend.
class CrmLead {
  final String id;
  final String? leadNumber;
  final String? userId;
  final String? propertyId;
  final String? dealerId;
  final String? assignedTo;
  final String name;
  final String? email;
  final String phone;
  final String? message;
  final LeadSource source;
  final LeadStatus status;
  final LeadStage stage;
  final String? leadType;
  final String? notes;
  final LeadPriority priority;
  final int? leadScore;
  final double? budgetMin;
  final double? budgetMax;
  final String? preferredCity;
  final String? preferredSector;
  final String? preferredPropertyType;
  final String? preferredBhk;
  final DateTime? nextFollowUpAt;
  final DateTime? lastContactedAt;
  final DateTime? convertedAt;
  final DateTime? lostAt;
  final String? lostReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CrmLead({
    required this.id,
    this.leadNumber,
    this.userId,
    this.propertyId,
    this.dealerId,
    this.assignedTo,
    required this.name,
    this.email,
    required this.phone,
    this.message,
    this.source = LeadSource.website,
    this.status = LeadStatus.newLead,
    this.stage = LeadStage.newLead,
    this.leadType,
    this.notes,
    this.priority = LeadPriority.medium,
    this.leadScore,
    this.budgetMin,
    this.budgetMax,
    this.preferredCity,
    this.preferredSector,
    this.preferredPropertyType,
    this.preferredBhk,
    this.nextFollowUpAt,
    this.lastContactedAt,
    this.convertedAt,
    this.lostAt,
    this.lostReason,
    this.createdAt,
    this.updatedAt,
  });

  factory CrmLead.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return CrmLead(
      id: json['id']?.toString() ?? '',
      leadNumber: json['leadNumber']?.toString(),
      userId: json['userId']?.toString(),
      propertyId: json['propertyId']?.toString(),
      dealerId: json['dealerId']?.toString(),
      assignedTo: json['assignedTo']?.toString(),
      name: json['name']?.toString().trim().isNotEmpty == true ? json['name'].toString().trim() : 'Lead',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      message: json['message']?.toString(),
      source: LeadSource.fromString(json['source']?.toString()),
      status: LeadStatus.fromString(json['status']?.toString()),
      stage: LeadStage.fromString(json['stage']?.toString()),
      leadType: json['leadType']?.toString(),
      notes: json['notes']?.toString(),
      priority: LeadPriority.fromString(json['priority']?.toString()),
      leadScore: json['leadScore'] is int ? json['leadScore'] as int : int.tryParse(json['leadScore']?.toString() ?? ''),
      budgetMin: parseDouble(json['budgetMin']),
      budgetMax: parseDouble(json['budgetMax']),
      preferredCity: json['preferredCity']?.toString(),
      preferredSector: json['preferredSector']?.toString(),
      preferredPropertyType: json['preferredPropertyType']?.toString(),
      preferredBhk: json['preferredBhk']?.toString(),
      nextFollowUpAt: parseDate(json['nextFollowUpAt']),
      lastContactedAt: parseDate(json['lastContactedAt']),
      convertedAt: parseDate(json['convertedAt']),
      lostAt: parseDate(json['lostAt']),
      lostReason: json['lostReason']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadNumber': leadNumber,
        'userId': userId,
        'propertyId': propertyId,
        'dealerId': dealerId,
        'assignedTo': assignedTo,
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'source': source.code,
        'status': status.code,
        'stage': stage.code,
        'leadType': leadType,
        'notes': notes,
        'priority': priority.code,
        'leadScore': leadScore,
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'preferredCity': preferredCity,
        'preferredSector': preferredSector,
        'preferredPropertyType': preferredPropertyType,
        'preferredBhk': preferredBhk,
        'nextFollowUpAt': nextFollowUpAt?.toIso8601String(),
        'lastContactedAt': lastContactedAt?.toIso8601String(),
        'convertedAt': convertedAt?.toIso8601String(),
        'lostAt': lostAt?.toIso8601String(),
        'lostReason': lostReason,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String get fullName => name;
  String get phoneNumber => phone;
  String? get city => preferredCity;

  String get displayBudget {
    if (budgetMin != null && budgetMax != null) {
      return '₹${budgetMin!.toStringAsFixed(0)} - ₹${budgetMax!.toStringAsFixed(0)}';
    } else if (budgetMin != null) {
      return 'Min ₹${budgetMin!.toStringAsFixed(0)}';
    } else if (budgetMax != null) {
      return 'Up to ₹${budgetMax!.toStringAsFixed(0)}';
    }
    return 'Not specified';
  }

  String get displayLocation {
    final parts = [preferredSector, preferredCity].where((s) => s != null && s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Not specified';
  }

  CrmLead copyWith({
    LeadStatus? status,
    LeadStage? stage,
    LeadPriority? priority,
    int? leadScore,
    String? notes,
    DateTime? nextFollowUpAt,
  }) {
    return CrmLead(
      id: id,
      leadNumber: leadNumber,
      userId: userId,
      propertyId: propertyId,
      dealerId: dealerId,
      assignedTo: assignedTo,
      name: name,
      email: email,
      phone: phone,
      message: message,
      source: source,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      leadType: leadType,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      leadScore: leadScore ?? this.leadScore,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      preferredCity: preferredCity,
      preferredSector: preferredSector,
      preferredPropertyType: preferredPropertyType,
      preferredBhk: preferredBhk,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      lastContactedAt: lastContactedAt,
      convertedAt: convertedAt,
      lostAt: lostAt,
      lostReason: lostReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Represents an activity item in the Lead chronological timeline.
class LeadActivity {
  final String id;
  final String leadId;
  final String activityType;
  final String summary;
  final String? details;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? performedBy;
  final bool isCompleted;
  final String? channel;
  final String? notes;
  final DateTime createdAt;

  const LeadActivity({
    required this.id,
    required this.leadId,
    required this.activityType,
    required this.summary,
    this.details,
    this.scheduledAt,
    this.completedAt,
    this.performedBy,
    this.isCompleted = false,
    this.channel,
    this.notes,
    required this.createdAt,
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val == null) return fallback ?? DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    return LeadActivity(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? 'NOTE',
      summary: json['summary']?.toString() ?? json['title']?.toString() ?? 'Activity',
      details: json['details']?.toString() ?? json['description']?.toString(),
      scheduledAt: json['scheduledAt'] != null ? parseDate(json['scheduledAt']) : null,
      completedAt: json['completedAt'] != null ? parseDate(json['completedAt']) : null,
      performedBy: json['performedBy']?.toString(),
      isCompleted: json['isCompleted'] as bool? ?? json['completed'] as bool? ?? false,
      channel: json['channel']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }
}

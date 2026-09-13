import 'package:flutter/material.dart';

enum FollowUpStatus {
  pending('PENDING', 'Pending', Color(0xFFF59E0B)),
  completed('COMPLETED', 'Completed', Color(0xFF10B981)),
  cancelled('CANCELLED', 'Cancelled', Color(0xFF64748B)),
  missed('MISSED', 'Missed / Overdue', Color(0xFFEF4444)),
  rescheduled('RESCHEDULED', 'Rescheduled', Color(0xFF8B5CF6));

  final String code;
  final String label;
  final Color color;

  const FollowUpStatus(this.code, this.label, this.color);

  static FollowUpStatus fromString(String? val) {
    if (val == null) return FollowUpStatus.pending;
    final clean = val.toUpperCase().trim();
    for (final s in FollowUpStatus.values) {
      if (s.code == clean || s.name.toUpperCase() == clean) return s;
    }
    return FollowUpStatus.pending;
  }
}

class CrmFollowUp {
  final String id;
  final String leadId;
  final String? leadName;
  final String? leadPhone;
  final String? leadEmail;
  final String? assignedTo;
  final DateTime scheduledAt;
  final String type;
  final String channel;
  final FollowUpStatus status;
  final String? notes;
  final String? outcome;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const CrmFollowUp({
    required this.id,
    required this.leadId,
    this.leadName,
    this.leadPhone,
    this.leadEmail,
    this.assignedTo,
    required this.scheduledAt,
    this.type = 'CALL',
    this.channel = 'PHONE',
    this.status = FollowUpStatus.pending,
    this.notes,
    this.outcome,
    this.completedAt,
    this.createdAt,
  });

  bool get isOverdue =>
      status == FollowUpStatus.pending && scheduledAt.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  factory CrmFollowUp.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val == null) return fallback ?? DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    return CrmFollowUp(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      leadName: json['leadName']?.toString() ?? 'Lead',
      leadPhone: json['leadPhone']?.toString() ?? json['phone']?.toString(),
      leadEmail: json['leadEmail']?.toString() ?? json['email']?.toString(),
      assignedTo: json['assignedTo']?.toString(),
      scheduledAt: parseDate(json['scheduledAt']),
      type: json['type']?.toString() ?? 'FOLLOW_UP',
      channel: json['channel']?.toString() ?? 'PHONE',
      status: FollowUpStatus.fromString(json['status']?.toString()),
      notes: json['notes']?.toString(),
      outcome: json['outcome']?.toString(),
      completedAt: json['completedAt'] != null ? parseDate(json['completedAt']) : null,
      createdAt: json['createdAt'] != null ? parseDate(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadId': leadId,
        'leadName': leadName,
        'leadPhone': leadPhone,
        'leadEmail': leadEmail,
        'assignedTo': assignedTo,
        'scheduledAt': scheduledAt.toIso8601String(),
        'type': type,
        'channel': channel,
        'status': status.code,
        'notes': notes,
        'outcome': outcome,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };
}

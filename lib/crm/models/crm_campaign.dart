import 'package:flutter/material.dart';

enum CampaignStatus {
  draft('DRAFT', 'Draft', Color(0xFF64748B)),
  scheduled('SCHEDULED', 'Scheduled', Color(0xFF3B82F6)),
  inProgress('IN_PROGRESS', 'In Progress', Color(0xFFF59E0B)),
  completed('COMPLETED', 'Completed', Color(0xFF10B981)),
  failed('FAILED', 'Failed', Color(0xFFEF4444)),
  cancelled('CANCELLED', 'Cancelled', Color(0xFF94A3B8));

  final String code;
  final String label;
  final Color color;

  const CampaignStatus(this.code, this.label, this.color);

  static CampaignStatus fromString(String? val) {
    if (val == null) return CampaignStatus.draft;
    final clean = val.toUpperCase().trim();
    for (final s in CampaignStatus.values) {
      if (s.code == clean || s.name.toUpperCase() == clean) return s;
    }
    return CampaignStatus.draft;
  }
}

class CrmCampaign {
  final String id;
  final String name;
  final String type;
  final String channel;
  final CampaignStatus status;
  final String? templateId;
  final String? createdBy;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalRecipients;
  final int sentCount;
  final int deliveredCount;
  final int readCount;
  final int failedCount;
  final DateTime? createdAt;

  const CrmCampaign({
    required this.id,
    required this.name,
    this.type = 'PROMOTIONAL',
    this.channel = 'WHATSAPP',
    this.status = CampaignStatus.draft,
    this.templateId,
    this.createdBy,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.totalRecipients = 0,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.readCount = 0,
    this.failedCount = 0,
    this.createdAt,
  });

  double get deliveryRate =>
      totalRecipients > 0 ? (sentCount / totalRecipients) * 100 : 0.0;

  double get readRate =>
      sentCount > 0 ? (readCount / sentCount) * 100 : 0.0;

  factory CrmCampaign.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return CrmCampaign(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Campaign',
      type: json['type']?.toString() ?? 'PROMOTIONAL',
      channel: json['channel']?.toString() ?? 'WHATSAPP',
      status: CampaignStatus.fromString(json['status']?.toString()),
      templateId: json['templateId']?.toString(),
      createdBy: json['createdBy']?.toString(),
      scheduledAt: parseDate(json['scheduledAt']),
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
      totalRecipients: parseInt(json['totalRecipients']),
      sentCount: parseInt(json['sentCount']),
      deliveredCount: parseInt(json['deliveredCount']),
      readCount: parseInt(json['readCount']),
      failedCount: parseInt(json['failedCount']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'channel': channel,
        'status': status.code,
        'templateId': templateId,
        'createdBy': createdBy,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'totalRecipients': totalRecipients,
        'sentCount': sentCount,
        'deliveredCount': deliveredCount,
        'readCount': readCount,
        'failedCount': failedCount,
        'createdAt': createdAt?.toIso8601String(),
      };
}

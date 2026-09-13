import 'package:flutter/material.dart';

/// AI predictive lead engagement score
class AiLeadScore {
  final String leadId;
  final int score;
  final String category; // HOT, WARM, COLD
  final List<String> reasons;
  final String? recommendedAction;
  final double confidence;

  const AiLeadScore({
    required this.leadId,
    required this.score,
    required this.category,
    this.reasons = const [],
    this.recommendedAction,
    this.confidence = 0.85,
  });

  Color get categoryColor {
    switch (category.toUpperCase()) {
      case 'HOT':
        return const Color(0xFFEF4444);
      case 'WARM':
        return const Color(0xFFF59E0B);
      case 'COLD':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  factory AiLeadScore.fromJson(Map<String, dynamic> json) {
    final rawReasons = json['reasons'] as List? ?? [];
    return AiLeadScore(
      leadId: json['leadId']?.toString() ?? '',
      score: json['leadScore'] is int
          ? json['leadScore'] as int
          : (int.tryParse(json['leadScore']?.toString() ?? '') ?? 0),
      category: json['scoreCategory']?.toString() ?? 'WARM',
      reasons: rawReasons.map((e) => e.toString()).toList(),
      recommendedAction: json['recommendedAction']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
    );
  }
}

/// AI recommended next best action
class AiNextAction {
  final String leadId;
  final String actionType;
  final String urgency; // IMMEDIATE, TODAY, THIS_WEEK
  final String actionSummary;
  final String? actionReason;
  final String priority;

  const AiNextAction({
    required this.leadId,
    required this.actionType,
    required this.urgency,
    required this.actionSummary,
    this.actionReason,
    this.priority = 'HIGH',
  });

  factory AiNextAction.fromJson(Map<String, dynamic> json) {
    return AiNextAction(
      leadId: json['leadId']?.toString() ?? '',
      actionType: json['actionType']?.toString() ?? 'FOLLOW_UP',
      urgency: json['urgency']?.toString() ?? 'TODAY',
      actionSummary: json['actionSummary']?.toString() ??
          json['recommendation']?.toString() ??
          'Schedule follow-up call with customer.',
      actionReason: json['actionReason']?.toString() ?? json['reason']?.toString(),
      priority: json['priority']?.toString() ?? 'HIGH',
    );
  }
}

/// AI generated follow-up draft message with timing suggestion
class AiFollowUpDraft {
  final String leadId;
  final String recommendedChannel;
  final String? suggestedSendTime;
  final String messageIntent;
  final String draftMessage;

  const AiFollowUpDraft({
    required this.leadId,
    this.recommendedChannel = 'WHATSAPP',
    this.suggestedSendTime,
    required this.messageIntent,
    required this.draftMessage,
  });

  factory AiFollowUpDraft.fromJson(Map<String, dynamic> json) {
    return AiFollowUpDraft(
      leadId: json['leadId']?.toString() ?? '',
      recommendedChannel: json['recommendedChannel']?.toString() ?? 'WHATSAPP',
      suggestedSendTime: json['suggestedSendTime']?.toString(),
      messageIntent: json['messageIntent']?.toString() ?? 'Follow-up regarding property interest',
      draftMessage: json['draftMessage']?.toString() ?? '',
    );
  }
}

/// AI synthesized executive summary for lead history
class CrmAiSummary {
  final String leadId;
  final String summary;
  final List<String> keyHighlights;
  final String? sentiment;
  final String? recommendedStage;

  const CrmAiSummary({
    required this.leadId,
    required this.summary,
    this.keyHighlights = const [],
    this.sentiment,
    this.recommendedStage,
  });

  factory CrmAiSummary.fromJson(Map<String, dynamic> json) {
    final rawHighlights = json['keyHighlights'] as List? ?? [];
    return CrmAiSummary(
      leadId: json['leadId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      keyHighlights: rawHighlights.map((e) => e.toString()).toList(),
      sentiment: json['sentiment']?.toString(),
      recommendedStage: json['recommendedStage']?.toString(),
    );
  }
}

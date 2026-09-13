import 'crm_api_client.dart';
import '../models/crm_ai_models.dart';

class CrmAiService {
  CrmAiService._internal();
  static final CrmAiService instance = CrmAiService._internal();

  final CrmApiClient _client = CrmApiClient.instance;

  /// Calculate or recalculate AI predictive lead score
  Future<AiLeadScore> calculateLeadScore(String leadId) async {
    final res = await _client.post('/api/v1/ai/crm/lead-score/$leadId');
    if (res is Map<String, dynamic>) {
      return AiLeadScore.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to calculate lead score');
  }

  /// Get recommended next best action for lead
  Future<AiNextAction> recommendNextAction(String leadId) async {
    final res = await _client.post('/api/v1/ai/crm/next-action/$leadId');
    if (res is Map<String, dynamic>) {
      return AiNextAction.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to generate next action');
  }

  /// Generate contextual AI follow-up draft message
  Future<AiFollowUpDraft> generateFollowUpDraft(String leadId) async {
    final res = await _client.post('/api/v1/ai/crm/follow-up/$leadId');
    if (res is Map<String, dynamic>) {
      return AiFollowUpDraft.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to generate follow-up draft');
  }

  /// Generate concise executive summary for lead history
  Future<CrmAiSummary> generateLeadSummary(String leadId) async {
    final res = await _client.post('/api/v1/ai/crm/lead-summary/$leadId');
    if (res is Map<String, dynamic>) {
      return CrmAiSummary.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to generate lead summary');
  }

  /// Summarize conversation notes or call transcript
  Future<CrmAiSummary> summarizeConversation(String leadId, String notes) async {
    final body = {'conversationText': notes};
    final res = await _client.post('/api/v1/ai/crm/conversation-summary/$leadId', body: body);
    if (res is Map<String, dynamic>) {
      return CrmAiSummary.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to summarize conversation');
  }
}

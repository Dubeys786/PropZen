import 'crm_api_client.dart';
import '../models/crm_follow_up.dart';

class CrmFollowUpService {
  CrmFollowUpService._internal();
  static final CrmFollowUpService instance = CrmFollowUpService._internal();

  final CrmApiClient _client = CrmApiClient.instance;

  /// Fetch all follow-ups assigned to the current caller
  Future<List<CrmFollowUp>> getFollowUps() async {
    final res = await _client.get('/api/v1/crm/follow-ups');
    if (res is List) {
      return res.map((e) => CrmFollowUp.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Schedule a new follow-up
  Future<CrmFollowUp> scheduleFollowUp({
    required String leadId,
    required DateTime scheduledAt,
    String type = 'FOLLOW_UP',
    String channel = 'PHONE',
    String? notes,
  }) async {
    final body = {
      'leadId': leadId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'type': type,
      'channel': channel,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final res = await _client.post('/api/v1/crm/follow-ups', body: body);
    if (res is Map<String, dynamic>) {
      return CrmFollowUp.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to schedule follow-up');
  }

  /// Mark follow-up as completed
  Future<void> completeFollowUp(String id) async {
    await _client.patch('/api/v1/crm/follow-ups/$id/complete');
  }

  /// Cancel or delete follow-up
  Future<void> cancelFollowUp(String id) async {
    await _client.delete('/api/v1/crm/follow-ups/$id');
  }
}

import 'crm_api_client.dart';
import '../models/crm_task.dart';

class CrmTaskService {
  CrmTaskService._internal();
  static final CrmTaskService instance = CrmTaskService._internal();

  final CrmApiClient _client = CrmApiClient.instance;

  /// Fetch CRM tasks assigned to the caller
  Future<List<CrmTask>> getTasks({int page = 0, int size = 50}) async {
    final res = await _client.get('/api/v1/crm/tasks', queryParams: {
      'page': page.toString(),
      'size': size.toString(),
    });

    if (res is Map<String, dynamic>) {
      final rawList = res['content'] as List? ?? [];
      return rawList.map((e) => CrmTask.fromJson(e as Map<String, dynamic>)).toList();
    } else if (res is List) {
      return res.map((e) => CrmTask.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Create an internal CRM task
  Future<CrmTask> createTask({
    required String title,
    String? description,
    String? leadId,
    String priority = 'MEDIUM',
    DateTime? dueDate,
  }) async {
    final body = {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (leadId != null && leadId.isNotEmpty) 'leadId': leadId,
      'priority': priority,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    };

    final res = await _client.post('/api/v1/crm/tasks', body: body);
    if (res is Map<String, dynamic>) {
      return CrmTask.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to create task');
  }

  /// Mark task as completed
  Future<CrmTask> completeTask(String id) async {
    final res = await _client.patch('/api/v1/crm/tasks/$id/complete');
    if (res is Map<String, dynamic>) {
      return CrmTask.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to complete task');
  }
}

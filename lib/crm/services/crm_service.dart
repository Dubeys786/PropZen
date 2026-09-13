import 'crm_api_client.dart';
import '../models/crm_lead.dart';
import '../models/crm_dashboard_metrics.dart';
import '../models/crm_note.dart';
import '../models/crm_task.dart';
import '../models/customer_360.dart';
import '../models/crm_analytics.dart';

class CrmLeadPage {
  final List<CrmLead> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;
  final bool isLast;

  const CrmLeadPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
    required this.isLast,
  });

  static const CrmLeadPage empty = CrmLeadPage(
    content: [],
    totalElements: 0,
    totalPages: 0,
    pageNumber: 0,
    pageSize: 20,
    isLast: true,
  );
}

class CrmService {
  CrmService._internal();
  static final CrmService instance = CrmService._internal();

  final CrmApiClient _client = CrmApiClient.instance;

  /// Fetch live CRM Dashboard metrics
  Future<CrmDashboardMetrics> getDashboardMetrics() async {
    final res = await _client.get('/api/v1/crm/dashboard');
    if (res is Map<String, dynamic>) {
      return CrmDashboardMetrics.fromJson(res);
    }
    return CrmDashboardMetrics.zero;
  }

  /// Search & filter leads using server-side pagination
  Future<CrmLeadPage> searchLeads({
    String? query,
    LeadStatus? status,
    LeadPriority? priority,
    LeadSource? source,
    String? city,
    String? sector,
    String? propertyId,
    String sort = 'newest',
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (status != null) 'status': status.code,
      if (priority != null) 'priority': priority.code,
      if (source != null) 'source': source.code,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (sector != null && sector.trim().isNotEmpty) 'sector': sector.trim(),
      if (propertyId != null && propertyId.trim().isNotEmpty) 'propertyId': propertyId.trim(),
      'sort': sort,
      'page': page.toString(),
      'size': size.toString(),
    };

    final res = await _client.get('/api/v1/crm/leads', queryParams: queryParams);

    if (res is Map<String, dynamic>) {
      final rawList = res['content'] as List? ?? [];
      final content = rawList.map((e) => CrmLead.fromJson(e as Map<String, dynamic>)).toList();
      return CrmLeadPage(
        content: content,
        totalElements: res['totalElements'] is int ? res['totalElements'] as int : content.length,
        totalPages: res['totalPages'] is int ? res['totalPages'] as int : 1,
        pageNumber: res['number'] is int ? res['number'] as int : page,
        pageSize: res['size'] is int ? res['size'] as int : size,
        isLast: res['last'] as bool? ?? true,
      );
    }
    return CrmLeadPage.empty;
  }

  /// Get details for a single lead
  Future<CrmLead> getLead(String id) async {
    final res = await _client.get('/api/v1/crm/leads/$id');
    if (res is Map<String, dynamic>) {
      return CrmLead.fromJson(res);
    }
    throw const CrmApiException(statusCode: 404, message: 'Lead not found');
  }

  /// Create a new lead manually
  Future<CrmLead> createLead({
    required String name,
    required String phone,
    String? email,
    String? message,
    LeadSource source = LeadSource.website,
    LeadPriority priority = LeadPriority.medium,
    double? budgetMin,
    double? budgetMax,
    String? preferredCity,
    String? preferredSector,
    String? preferredPropertyType,
    String? preferredBhk,
  }) async {
    final body = {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (message != null && message.isNotEmpty) 'message': message,
      'source': source.code,
      'priority': priority.code,
      if (budgetMin != null) 'budgetMin': budgetMin,
      if (budgetMax != null) 'budgetMax': budgetMax,
      if (preferredCity != null) 'preferredCity': preferredCity,
      if (preferredSector != null) 'preferredSector': preferredSector,
      if (preferredPropertyType != null) 'preferredPropertyType': preferredPropertyType,
      if (preferredBhk != null) 'preferredBhk': preferredBhk,
    };

    final res = await _client.post('/api/v1/crm/leads', body: body);
    if (res is Map<String, dynamic>) {
      return CrmLead.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to create lead');
  }

  /// Transition lead status
  Future<CrmLead> updateLeadStatus(String id, LeadStatus status, {String? reason, String? notes}) async {
    final body = {
      'status': status.code,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final res = await _client.patch('/api/v1/crm/leads/$id/status', body: body);
    if (res is Map<String, dynamic>) {
      return CrmLead.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to update status');
  }

  /// Update lead follow-up priority
  Future<CrmLead> updateLeadPriority(String id, LeadPriority priority) async {
    final body = {'priority': priority.code};
    final res = await _client.patch('/api/v1/crm/leads/$id/priority', body: body);
    if (res is Map<String, dynamic>) {
      return CrmLead.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to update priority');
  }

  /// Update pipeline funnel stage
  Future<CrmLead> updateLeadStage(String id, LeadStage stage, {String? notes}) async {
    final body = {
      'stage': stage.code,
      if (notes != null) 'notes': notes,
    };
    final res = await _client.patch('/api/v1/crm/leads/$id/stage', body: body);
    if (res is Map<String, dynamic>) {
      return CrmLead.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to update stage');
  }

  /// Assign lead to a dealer or agent (Admin only)
  Future<CrmLead> assignLead(String id, String dealerId, {String? notes}) async {
    final body = {
      'dealerId': dealerId,
      if (notes != null) 'notes': notes,
    };
    final res = await _client.patch('/api/v1/crm/leads/$id/assign', body: body);
    if (res is Map<String, dynamic>) {
      return CrmLead.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to assign lead');
  }

  /// Fetch chronological timeline activities for lead
  Future<List<LeadActivity>> getTimeline(String leadId) async {
    final res = await _client.get('/api/v1/crm/leads/$leadId/timeline');
    if (res is List) {
      return res.map((e) => LeadActivity.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Fetch internal CRM notes for lead
  Future<List<CrmNote>> getNotes(String leadId) async {
    final res = await _client.get('/api/v1/crm/leads/$leadId/notes');
    if (res is List) {
      return res.map((e) => CrmNote.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Add an internal CRM note
  Future<CrmNote> addNote(String leadId, String content, {bool isPinned = false}) async {
    final body = {
      'note': content,
      'isPinned': isPinned,
    };
    final res = await _client.post('/api/v1/crm/leads/$leadId/notes', body: body);
    if (res is Map<String, dynamic>) {
      return CrmNote.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to add note');
  }

  /// Fetch internal CRM tasks for lead
  Future<List<CrmTask>> getTasks(String leadId) async {
    final res = await _client.get('/api/v1/crm/leads/$leadId/tasks');
    if (res is List) {
      return res.map((e) => CrmTask.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Create a task associated with lead
  Future<CrmTask> createTask(
    String leadId, {
    required String title,
    String? description,
    String priority = 'MEDIUM',
    DateTime? dueDate,
  }) async {
    final body = {
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    };
    final res = await _client.post('/api/v1/crm/leads/$leadId/tasks', body: body);
    if (res is Map<String, dynamic>) {
      return CrmTask.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to create task');
  }

  /// Fetch unified Customer 360 profile
  Future<Customer360Profile> getCustomer360(String customerId) async {
    final res = await _client.get('/api/v1/crm/customers/$customerId/360');
    if (res is Map<String, dynamic>) {
      return Customer360Profile.fromJson(res);
    }
    throw const CrmApiException(statusCode: 404, message: 'Customer not found');
  }

  /// Fetch CRM pipeline analytics
  Future<CrmAnalyticsData> getAnalytics() async {
    final res = await _client.get('/api/v1/crm/analytics');
    if (res is Map<String, dynamic>) {
      return CrmAnalyticsData.fromJson(res);
    }
    return const CrmAnalyticsData();
  }
}

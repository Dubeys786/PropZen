import 'crm_api_client.dart';
import '../models/crm_campaign.dart';
import '../models/whatsapp_template.dart';
import '../models/crm_lead.dart';

class CrmCampaignService {
  CrmCampaignService._internal();
  static final CrmCampaignService instance = CrmCampaignService._internal();

  final CrmApiClient _client = CrmApiClient.instance;

  /// Fetch all campaigns (Admin only)
  Future<List<CrmCampaign>> getCampaigns() async {
    final res = await _client.get('/api/v1/crm/campaigns');
    if (res is List) {
      return res.map((e) => CrmCampaign.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get campaign details by ID
  Future<CrmCampaign> getCampaign(String id) async {
    final res = await _client.get('/api/v1/crm/campaigns/$id');
    if (res is Map<String, dynamic>) {
      return CrmCampaign.fromJson(res);
    }
    throw const CrmApiException(statusCode: 404, message: 'Campaign not found');
  }

  /// Fetch approved WhatsApp templates
  Future<List<WhatsAppTemplate>> getApprovedTemplates() async {
    final res = await _client.get('/api/v1/whatsapp/templates');
    if (res is List) {
      return res.map((e) => WhatsAppTemplate.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Create a new bulk campaign
  Future<CrmCampaign> createCampaign({
    required String name,
    required String templateId,
    String type = 'PROMOTIONAL',
    String channel = 'WHATSAPP',
    LeadStatus? targetStatus,
    String? targetCity,
    String? targetSector,
    DateTime? scheduledAt,
  }) async {
    final body = {
      'name': name,
      'templateId': templateId,
      'type': type,
      'channel': channel,
      if (targetStatus != null) 'targetStatus': targetStatus.code,
      if (targetCity != null && targetCity.isNotEmpty) 'targetCity': targetCity,
      if (targetSector != null && targetSector.isNotEmpty) 'targetSector': targetSector,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
    };

    final res = await _client.post('/api/v1/crm/campaigns', body: body);
    if (res is Map<String, dynamic>) {
      return CrmCampaign.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to create campaign');
  }

  /// Dispatch bulk campaign execution
  Future<CrmCampaign> sendCampaign(String id, {bool async = true}) async {
    final res = await _client.post(
      '/api/v1/crm/campaigns/$id/send',
      queryParams: {'async': async.toString()},
    );
    if (res is Map<String, dynamic>) {
      return CrmCampaign.fromJson(res);
    }
    throw const CrmApiException(statusCode: 500, message: 'Failed to dispatch campaign');
  }

  /// Dispatch one-click official WhatsApp notification to lead
  Future<void> sendOneClickWhatsApp({
    required String phone,
    required String templateName,
    String language = 'en',
    String? leadId,
    Map<String, String>? variables,
  }) async {
    final body = {
      'recipientPhone': phone,
      'templateName': templateName,
      'language': language,
      if (leadId != null) 'leadId': leadId,
      if (variables != null) 'variables': variables,
    };
    await _client.post('/api/v1/whatsapp/send', body: body);
  }
}

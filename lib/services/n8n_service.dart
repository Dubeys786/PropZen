import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../screens/user_profile_screen.dart';
import '../config/env_config.dart';

/// Centralized result model for all n8n workflow interactions
class N8nResponse {
  final bool isSuccess;
  final int statusCode;
  final String message;
  final dynamic data;
  final String? error;

  const N8nResponse({
    required this.isSuccess,
    required this.statusCode,
    required this.message,
    this.data,
    this.error,
  });

  factory N8nResponse.success({
    int statusCode = 200,
    String message = 'Success',
    dynamic data,
  }) {
    return N8nResponse(
      isSuccess: true,
      statusCode: statusCode,
      message: message,
      data: data,
    );
  }

  factory N8nResponse.failure({
    required int statusCode,
    required String message,
    String? error,
    dynamic data,
  }) {
    return N8nResponse(
      isSuccess: false,
      statusCode: statusCode,
      message: message,
      error: error ?? message,
      data: data,
    );
  }

  @override
  String toString() => 'N8nResponse(success: $isSuccess, code: $statusCode, msg: $message)';
}

/// Centralized client service for connecting to PropZen production n8n workflows
class N8nService {
  N8nService._();
  static final N8nService instance = N8nService._();

  // Production & Test n8n Webhook URLs
  static const String prodBookSiteVisitUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/site-visit';
  static const String prodPropertyEnquiryUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/enquiry';
  static const String testPropertyEnquiryUrl = 'https://propzen.app.n8n.cloud/webhook-test/propzen/enquiry';
  static const String prodPropertyDataUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/property';
  static const String prodServicesUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/services';
  static const String prodVerifyDocumentUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/verify-document';
  static const String prodOfficialSourceCheckUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/verify-source';
  static const String prodQuestionGeneratorUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/verification-question';
  static const String prodPropertyMonitorUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/property-monitor';

  bool useTestWebhookForEnquiry = false;

  // In-app mock or custom client for testing
  http.Client? _customClient;

  @visibleForTesting
  void setMockClient(http.Client? client) {
    _customClient = client;
  }

  http.Client get _client => _customClient ?? http.Client();

  String get _proxyBaseUrl => EnvConfig.backendApiBaseUrl;

  /// Standard Headers for Backend Proxy Requests
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // =========================================================================
  // 1. BOOK A SITE VISIT WORKFLOW
  // =========================================================================
  /// Connects to N8N_BOOK_SITE_VISIT_URL
  /// Payload schema:
  /// {
  ///   "propertyId": "<property_id>",
  ///   "propertyName": "<property_name>",
  ///   "userId": "<user_id>",
  ///   "fullName": "<full_name>",
  ///   "mobileNumber": "<mobile_number>",
  ///   "email": "<email>",
  ///   "visitDate": "<YYYY-MM-DD>",
  ///   "visitTime": "<HH:MM>",
  ///   "visitorCount": 1,
  ///   "cabRequired": false,
  ///   "message": "<optional_message>"
  /// }
  Future<N8nResponse> bookSiteVisit({
    required String propertyId,
    required String propertyName,
    String? userId,
    required String fullName,
    required String mobileNumber,
    required String email,
    required String visitDate, // YYYY-MM-DD
    required String visitTime, // HH:MM or 11:00 AM
    int visitorCount = 1,
    bool cabRequired = false,
    String message = '',
  }) async {
    final effectiveUserId = userId ??
        (UserSession.isLoggedIn
            ? (UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active')
            : 'usr_guest_${DateTime.now().millisecondsSinceEpoch}');

    // Clean Time Format (e.g. "11:00 AM" -> "11:00" or ISO format)
    final cleanedTime = visitTime.replaceAll(RegExp(r'\s*(AM|PM|am|pm)'), '').trim();

    final payload = {
      // 1. Exact snake_case fields matching n8n & Supabase schema
      'full_name': fullName,
      'name': fullName,
      'email': email,
      'phone': mobileNumber,
      'mobile_number': mobileNumber,
      'property_id': propertyId,
      'property_name': propertyName,
      'property_title': propertyName,
      'visit_date': visitDate,
      'visit_time': cleanedTime.isNotEmpty ? cleanedTime : visitTime,
      'time_slot': cleanedTime.isNotEmpty ? cleanedTime : visitTime,
      'visitor_count': visitorCount < 1 ? 1 : visitorCount,
      'cab_required': cabRequired,
      'message': message,
      'user_id': effectiveUserId,
      // 2. Exact camelCase fields for maximum node compatibility
      'propertyId': propertyId,
      'propertyName': propertyName,
      'userId': effectiveUserId,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'visitDate': visitDate,
      'visitTime': cleanedTime.isNotEmpty ? cleanedTime : visitTime,
      'visitorCount': visitorCount < 1 ? 1 : visitorCount,
      'cabRequired': cabRequired,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await _executePost(
      endpointPath: '/api/n8n/site-visit',
      directUrl: prodBookSiteVisitUrl,
      payload: payload,
      workflowName: 'Book a Site Visit',
    );
  }

  // =========================================================================
  // 2. PROPERTY ENQUIRY WORKFLOW
  // =========================================================================
  /// Connects to N8N_PROPERTY_ENQUIRY_URL
  /// Payload schema:
  /// {
  ///   "propertyId": "<property_id>",
  ///   "propertyName": "<property_name>",
  ///   "userId": "<user_id>",
  ///   "fullName": "<full_name>",
  ///   "mobileNumber": "<mobile_number>",
  ///   "email": "<email>",
  ///   "message": "<message>",
  ///   "preferredContactMethod": "<phone|email|whatsapp>"
  /// }
  Future<N8nResponse> submitPropertyEnquiry({
    required String propertyId,
    required String propertyName,
    String? userId,
    required String fullName,
    required String mobileNumber,
    required String email,
    required String message,
    String preferredContactMethod = 'phone', // phone | email | whatsapp
    bool? useTestWebhook,
  }) async {
    final effectiveUserId = userId ??
        (UserSession.isLoggedIn
            ? (UserSession.email.isNotEmpty ? UserSession.email : (UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active'))
            : 'usr_guest_${DateTime.now().millisecondsSinceEpoch}');

    // Normalize contact method to phone|email|whatsapp
    String method = preferredContactMethod.toLowerCase();
    if (method.contains('whatsapp')) {
      method = 'whatsapp';
    } else if (method.contains('email')) {
      method = 'email';
    } else {
      method = 'phone';
    }

    final payload = {
      // 1. Exact snake_case fields required by user & n8n schema
      'property_id': propertyId,
      'user_id': effectiveUserId,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'message': message,
      'preferred_contact_method': method,
      // 2. Exact camelCase fields for maximum workflow node compatibility
      'propertyId': propertyId,
      'propertyName': propertyName,
      'userId': effectiveUserId,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'preferredContactMethod': method,
      'requested_at': DateTime.now().toIso8601String(),
    };

    final isTest = useTestWebhook ?? useTestWebhookForEnquiry;
    final directUrl = isTest ? testPropertyEnquiryUrl : prodPropertyEnquiryUrl;

    return await _executePost(
      endpointPath: '/api/n8n/enquiry',
      directUrl: directUrl,
      payload: payload,
      workflowName: 'PropZen - Property Enquiry',
    );
  }

  // =========================================================================
  // 3. PROPERTY DATA WORKFLOW
  // =========================================================================
  /// Connects to N8N_PROPERTY_DATA_URL
  /// Retrieves property details or listings from n8n production workflow
  Future<N8nResponse> fetchPropertyData({
    String? propertyId,
    Map<String, dynamic>? queryParams,
  }) async {
    final Map<String, String> query = {};
    if (propertyId != null && propertyId.isNotEmpty) {
      query['propertyId'] = propertyId;
      query['id'] = propertyId;
    }
    if (queryParams != null) {
      queryParams.forEach((k, v) => query[k] = v.toString());
    }

    return await _executeGet(
      endpointPath: '/api/n8n/property',
      directUrl: prodPropertyDataUrl,
      queryParams: query,
      workflowName: 'Property Data',
    );
  }

  // =========================================================================
  // 4. SERVICES WORKFLOW
  // =========================================================================
  /// Connects to N8N_SERVICES_URL
  /// Connects existing PropZen services functionality to n8n
  Future<N8nResponse> requestService({
    required String serviceId,
    required String serviceName,
    required String category,
    String? userId,
    required String fullName,
    required String mobileNumber,
    required String email,
    String? notes,
    Map<String, dynamic>? params,
  }) async {
    final effectiveUserId = userId ??
        (UserSession.isLoggedIn
            ? (UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active')
            : 'usr_guest_${DateTime.now().millisecondsSinceEpoch}');

    final payload = {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'category': category,
      'userId': effectiveUserId,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'email': email,
      'notes': notes ?? 'Service consultation requested for $serviceName',
      'params': params ?? {},
      'requestedAt': DateTime.now().toIso8601String(),
    };

    return await _executePost(
      endpointPath: '/api/n8n/services',
      directUrl: prodServicesUrl,
      payload: payload,
      workflowName: 'PropZen Services',
    );
  }

  // =========================================================================
  // 5. AI DOCUMENT DETECTIVE WORKFLOW
  // =========================================================================
  /// Uploads property document metadata / text to n8n AI workflow for entity extraction & cross-check
  Future<N8nResponse> verifyDocumentWithAi({
    required String propertyId,
    required String documentType,
    required String fileName,
    String? fileUrl,
    String? fileBase64,
    Map<String, dynamic>? extraContext,
  }) async {
    final payload = {
      'property_id': propertyId,
      'document_type': documentType,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_base64': fileBase64,
      'extra_context': extraContext ?? {},
      'requested_at': DateTime.now().toIso8601String(),
    };

    return await _executePost(
      endpointPath: '/api/n8n/verify-document',
      directUrl: prodVerifyDocumentUrl,
      payload: payload,
      workflowName: 'AI Document Detective',
    );
  }

  // =========================================================================
  // 6. OFFICIAL SOURCE RECORD CHECK WORKFLOW
  // =========================================================================
  /// Compares property data against official government APIs (RERA, Sub-Registrar)
  Future<N8nResponse> checkOfficialSourceWithAi({
    required String propertyId,
    required String sourceName,
    required Map<String, dynamic> propertyClaimData,
  }) async {
    final payload = {
      'property_id': propertyId,
      'source_name': sourceName,
      'claim_data': propertyClaimData,
      'requested_at': DateTime.now().toIso8601String(),
    };

    return await _executePost(
      endpointPath: '/api/n8n/verify-source',
      directUrl: prodOfficialSourceCheckUrl,
      payload: payload,
      workflowName: 'Official Source Verification',
    );
  }

  // =========================================================================
  // 7. AI QUESTION GENERATOR WORKFLOW
  // =========================================================================
  /// Generates clarification questions for discrepancies detected in documents
  Future<N8nResponse> generateVerificationQuestionsWithAi({
    required String propertyId,
    required List<Map<String, dynamic>> discrepancies,
  }) async {
    final payload = {
      'property_id': propertyId,
      'discrepancies': discrepancies,
      'requested_at': DateTime.now().toIso8601String(),
    };

    return await _executePost(
      endpointPath: '/api/n8n/verification-question',
      directUrl: prodQuestionGeneratorUrl,
      payload: payload,
      workflowName: 'AI Verification Question Generator',
    );
  }

  // =========================================================================
  // 8. PROPERTY MONITORING WORKFLOW
  // =========================================================================
  /// Subscribes property to real-time update alerts
  Future<N8nResponse> triggerPropertyMonitoringCheck({
    required String propertyId,
    required String userId,
    required bool isEnabled,
  }) async {
    final payload = {
      'property_id': propertyId,
      'user_id': userId,
      'is_enabled': isEnabled,
      'requested_at': DateTime.now().toIso8601String(),
    };

    return await _executePost(
      endpointPath: '/api/n8n/property-monitor',
      directUrl: prodPropertyMonitorUrl,
      payload: payload,
      workflowName: 'Property Alert Monitoring',
    );
  }

  // =========================================================================
  // CENTRALIZED HTTP EXECUTION & ERROR HANDLING
  // =========================================================================
  Future<N8nResponse> _executePost({
    required String endpointPath,
    required String directUrl,
    required Map<String, dynamic> payload,
    required String workflowName,
  }) async {
    final targetUri = Uri.parse('$_proxyBaseUrl$endpointPath');
    final headers = _buildHeaders();

    if (kDebugMode) {
      debugPrint('[n8n Service] POST $workflowName -> $targetUri');
      debugPrint('[n8n Service] Payload: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client
          .post(
            targetUri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      return _handleResponse(response, workflowName);
    } on TimeoutException {
      if (kDebugMode) debugPrint('[n8n Service Timeout] $workflowName timed out');
      return N8nResponse.failure(
        statusCode: 408,
        message: 'Connection to n8n production workflow timed out. Please retry shortly.',
        error: 'Network Timeout (408)',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[n8n Service Error] $workflowName: $e');
      return N8nResponse.failure(
        statusCode: 500,
        message: 'Network error connecting to $workflowName: $e',
        error: e.toString(),
      );
    }
  }

  Future<N8nResponse> _executeGet({
    required String endpointPath,
    required String directUrl,
    required Map<String, String> queryParams,
    required String workflowName,
  }) async {
    final baseUri = Uri.parse('$_proxyBaseUrl$endpointPath');
    final targetUri = queryParams.isNotEmpty ? baseUri.replace(queryParameters: queryParams) : baseUri;
    final headers = _buildHeaders();

    if (kDebugMode) {
      debugPrint('[n8n Service] GET $workflowName -> $targetUri');
    }

    try {
      final response = await _client.get(targetUri, headers: headers).timeout(const Duration(seconds: 12));
      return _handleResponse(response, workflowName);
    } on TimeoutException {
      return N8nResponse.failure(
        statusCode: 408,
        message: 'Connection to n8n $workflowName timed out. Please retry.',
        error: 'Network Timeout (408)',
      );
    } catch (e) {
      return N8nResponse.failure(
        statusCode: 500,
        message: 'Network error connecting to $workflowName: $e',
        error: e.toString(),
      );
    }
  }

  N8nResponse _handleResponse(http.Response response, String workflowName) {
    final code = response.statusCode;
    dynamic decodedBody;

    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(response.body);
      }
    } catch (_) {
      decodedBody = response.body;
    }

    if (kDebugMode) {
      debugPrint('[n8n Service] Response ($code) from $workflowName: ${response.body}');
    }

    // Check if JSON body explicitly indicates success or returns a booking/reference ID
    final isExplicitSuccess = decodedBody is Map &&
        (decodedBody['success'] == true ||
            decodedBody['status'] == 'success' ||
            decodedBody['bookingId'] != null ||
            decodedBody['booking_id'] != null ||
            decodedBody['id'] != null);

    // 200/201/202 or explicit body success
    if (code >= 200 && code < 300 || isExplicitSuccess) {
      final msg = decodedBody is Map && decodedBody['message'] != null
          ? decodedBody['message'].toString()
          : '$workflowName completed successfully.';
      return N8nResponse.success(statusCode: code, message: msg, data: decodedBody);
    }

    // 400: Validation Error
    if (code == 400) {
      final msg = decodedBody is Map && decodedBody['error'] != null
          ? decodedBody['error'].toString()
          : 'Validation failed for $workflowName submission. Please check all fields.';
      return N8nResponse.failure(statusCode: 400, message: msg, data: decodedBody);
    }

    // 401 / 403: Authentication / Authorization Error
    if (code == 401 || code == 403) {
      return N8nResponse.failure(
        statusCode: code,
        message: 'Authentication error with n8n workflow. Verified production API key required.',
        error: 'Invalid or missing X-PropZen-Key credentials ($code)',
        data: decodedBody,
      );
    }

    // 404: Not Found
    if (code == 404) {
      return N8nResponse.failure(
        statusCode: 404,
        message: 'Requested $workflowName resource was not found on n8n workflow.',
        error: '404 Not Found',
        data: decodedBody,
      );
    }

    // 500+: Server / Workflow Error
    return N8nResponse.failure(
      statusCode: code,
      message: 'n8n workflow returned error ($code): ${response.reasonPhrase ?? "Internal Error"}',
      error: decodedBody?.toString() ?? response.body,
      data: decodedBody,
    );
  }
}

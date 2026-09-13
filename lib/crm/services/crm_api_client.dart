import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/env_config.dart';
import '../../services/supabase_service.dart';

/// Exception thrown when CRM API requests fail.
class CrmApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errorDetails;

  const CrmApiException({
    required this.statusCode,
    required this.message,
    this.errorDetails,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'CrmApiException [$statusCode]: $message';
}

/// Centralized API client for communicating with the PropZen Java/Spring Boot backend.
/// Automatically handles:
/// - Base URL configuration
/// - Bearer Supabase JWT authentication header
/// - Request ID tracing
/// - Timeout and error handling (401, 403, 429, 500)
/// - Response unwrapping for ApiResponse<T>
class CrmApiClient {
  CrmApiClient._internal();
  static final CrmApiClient instance = CrmApiClient._internal();

  final http.Client _httpClient = http.Client();
  static const Duration defaultTimeout = Duration(seconds: 15);

  String get baseUrl => EnvConfig.backendApiBaseUrl;

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final token = SupabaseService.instance.currentAuthToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Request-Id': 'crm-req-${DateTime.now().millisecondsSinceEpoch}',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _resolveUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final urlString = '$cleanBase$cleanEndpoint';

    if (queryParams == null || queryParams.isEmpty) {
      return Uri.parse(urlString);
    }

    final sanitizedParams = <String, String>{};
    queryParams.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        sanitizedParams[key] = value.toString().trim();
      }
    });

    return Uri.parse(urlString).replace(queryParameters: sanitizedParams);
  }

  dynamic _processResponse(http.Response res) {
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        // Handle Spring Boot ApiResponse<T> envelope
        if (decoded.containsKey('success')) {
          final success = decoded['success'] as bool? ?? true;
          if (!success) {
            final msg = decoded['message']?.toString() ?? 'Operation failed';
            throw CrmApiException(
              statusCode: res.statusCode,
              message: msg,
              errorDetails: decoded['error'],
            );
          }
          return decoded['data'];
        }
      }
      return decoded;
    }

    // Handle HTTP Error Codes
    String errorMessage = 'Request failed with status ${res.statusCode}';
    dynamic errorDetails;

    if (decoded is Map<String, dynamic>) {
      errorMessage = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          errorMessage;
      errorDetails = decoded['error'] ?? decoded['details'];
    }

    if (res.statusCode == 401) {
      errorMessage = 'Your session has expired. Please sign in again.';
    } else if (res.statusCode == 403) {
      errorMessage = 'You do not have permission to access CRM.';
    } else if (res.statusCode == 429) {
      errorMessage = 'Too many requests. Please wait a moment before retrying.';
    } else if (res.statusCode >= 500) {
      errorMessage = 'Server error occurred while processing CRM data. Please retry shortly.';
    }

    throw CrmApiException(
      statusCode: res.statusCode,
      message: errorMessage,
      errorDetails: errorDetails,
    );
  }

  String _sanitizeNetworkErrorMessage(dynamic e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[CrmApiClient] Network Error: $e');
    }
    return 'Unable to connect to PropZen server.';
  }

  /// Execute GET request with automatic 401 session refresh retry
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, Map<String, String>? headers, bool isRetry = false}) async {
    final uri = _resolveUri(endpoint, queryParams);
    try {
      final res = await _httpClient
          .get(uri, headers: _buildHeaders(headers))
          .timeout(defaultTimeout);
      if (res.statusCode == 401 && !isRetry) {
        final refreshed = await SupabaseService.instance.restoreAuthSession();
        if (refreshed != null) {
          return get(endpoint, queryParams: queryParams, headers: headers, isRetry: true);
        }
      }
      return _processResponse(res);
    } on TimeoutException {
      throw const CrmApiException(
        statusCode: 408,
        message: 'Network request timed out. Please check your connection.',
      );
    } catch (e) {
      if (e is CrmApiException) rethrow;
      throw CrmApiException(
        statusCode: 0,
        message: _sanitizeNetworkErrorMessage(e),
      );
    }
  }

  /// Execute POST request with automatic 401 session refresh retry
  Future<dynamic> post(String endpoint, {dynamic body, Map<String, dynamic>? queryParams, Map<String, String>? headers, bool isRetry = false}) async {
    final uri = _resolveUri(endpoint, queryParams);
    try {
      final res = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(defaultTimeout);
      if (res.statusCode == 401 && !isRetry) {
        final refreshed = await SupabaseService.instance.restoreAuthSession();
        if (refreshed != null) {
          return post(endpoint, body: body, queryParams: queryParams, headers: headers, isRetry: true);
        }
      }
      return _processResponse(res);
    } on TimeoutException {
      throw const CrmApiException(
        statusCode: 408,
        message: 'Network request timed out. Please check your connection.',
      );
    } catch (e) {
      if (e is CrmApiException) rethrow;
      throw CrmApiException(
        statusCode: 0,
        message: _sanitizeNetworkErrorMessage(e),
      );
    }
  }

  /// Execute PATCH request with automatic 401 session refresh retry
  Future<dynamic> patch(String endpoint, {dynamic body, Map<String, dynamic>? queryParams, Map<String, String>? headers, bool isRetry = false}) async {
    final uri = _resolveUri(endpoint, queryParams);
    try {
      final res = await _httpClient
          .patch(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(defaultTimeout);
      if (res.statusCode == 401 && !isRetry) {
        final refreshed = await SupabaseService.instance.restoreAuthSession();
        if (refreshed != null) {
          return patch(endpoint, body: body, queryParams: queryParams, headers: headers, isRetry: true);
        }
      }
      return _processResponse(res);
    } on TimeoutException {
      throw const CrmApiException(
        statusCode: 408,
        message: 'Network request timed out. Please check your connection.',
      );
    } catch (e) {
      if (e is CrmApiException) rethrow;
      throw CrmApiException(
        statusCode: 0,
        message: _sanitizeNetworkErrorMessage(e),
      );
    }
  }

  /// Execute DELETE request with automatic 401 session refresh retry
  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? queryParams, Map<String, String>? headers, bool isRetry = false}) async {
    final uri = _resolveUri(endpoint, queryParams);
    try {
      final res = await _httpClient
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(defaultTimeout);
      if (res.statusCode == 401 && !isRetry) {
        final refreshed = await SupabaseService.instance.restoreAuthSession();
        if (refreshed != null) {
          return delete(endpoint, queryParams: queryParams, headers: headers, isRetry: true);
        }
      }
      return _processResponse(res);
    } on TimeoutException {
      throw const CrmApiException(
        statusCode: 408,
        message: 'Network request timed out. Please check your connection.',
      );
    } catch (e) {
      if (e is CrmApiException) rethrow;
      throw CrmApiException(
        statusCode: 0,
        message: _sanitizeNetworkErrorMessage(e),
      );
    }
  }
}

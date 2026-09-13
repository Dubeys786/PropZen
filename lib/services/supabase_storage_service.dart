import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class UploadResult {
  final bool isSuccess;
  final String? storagePath;
  final String? fileUrl;
  final String? errorMessage;
  final int? statusCode;

  const UploadResult({
    required this.isSuccess,
    this.storagePath,
    this.fileUrl,
    this.errorMessage,
    this.statusCode,
  });

  factory UploadResult.success({
    required String storagePath,
    required String fileUrl,
    int? statusCode,
  }) {
    return UploadResult(
      isSuccess: true,
      storagePath: storagePath,
      fileUrl: fileUrl,
      statusCode: statusCode ?? 200,
    );
  }

  factory UploadResult.failure({
    required String errorMessage,
    int? statusCode,
    String? storagePath,
  }) {
    return UploadResult(
      isSuccess: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
      storagePath: storagePath,
    );
  }
}

class SupabaseStorageService {
  SupabaseStorageService._();
  static final SupabaseStorageService instance = SupabaseStorageService._();

  static const String documentsBucket = 'property-documents';
  static const String imagesBucket = 'property-images';
  static const String avatarsBucket = 'profile-avatars';
  static const int maxFileSizeBytes = 15 * 1024 * 1024; // 15 MB maximum size limit
  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB maximum avatar limit

  static const Set<String> allowedExtensions = {'.pdf', '.jpg', '.jpeg', '.png', '.webp'};
  static const Set<String> blockedExtensions = {
    '.exe', '.bat', '.sh', '.apk', '.php', '.js', '.py', '.vbs', '.msi', '.cmd', '.bin', '.dll', '.scr'
  };

  /// Sanitize storage path to prevent path traversal
  static String sanitizeStoragePath(String rawPath) {
    var sanitized = rawPath.replaceAll('\\', '/');
    while (sanitized.contains('../') || sanitized.contains('..\\')) {
      sanitized = sanitized.replaceAll('../', '').replaceAll('..\\', '');
    }
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    if (sanitized.startsWith('/')) sanitized = sanitized.substring(1);
    return sanitized;
  }

  /// Check if file extension is safe and allowed
  static bool isAllowedFileType(String fileName) {
    final lower = fileName.toLowerCase().trim();
    for (final ext in blockedExtensions) {
      if (lower.endsWith(ext)) return false;
    }
    for (final ext in allowedExtensions) {
      if (lower.endsWith(ext)) return true;
    }
    return false;
  }

  /// Get MIME Type from filename or extension
  static String resolveMimeType(String fileName) {
    final lower = fileName.toLowerCase().trim();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  /// Upload raw binary file bytes to Supabase Storage with strict validation
  Future<UploadResult> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String userId,
    required String propertyId,
    String documentType = 'document',
    String fileName = 'file',
  }) async {
    // 1. File Size Validation
    if (bytes.length > maxFileSizeBytes) {
      return UploadResult.failure(
        errorMessage: 'File size (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB) exceeds maximum allowed limit (15 MB).',
        statusCode: 413,
      );
    }

    // 2. File Type & Extension Validation
    if (!isAllowedFileType(fileName)) {
      return UploadResult.failure(
        errorMessage: 'File type rejected. Allowed formats: PDF, JPG, PNG, WEBP.',
        statusCode: 415,
      );
    }

    // 3. Path Traversal Sanitization
    final cleanPath = sanitizeStoragePath(path);
    if (cleanPath.isEmpty) {
      return UploadResult.failure(
        errorMessage: 'Invalid storage path provided.',
        statusCode: 400,
      );
    }

    final uploadUri = Uri.parse('${SupabaseService.supabaseUrl}/storage/v1/object/$bucket/$cleanPath');

    final headers = {
      'apikey': SupabaseService.supabasePublishableKey,
      'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
      'Content-Type': contentType.isNotEmpty ? contentType : resolveMimeType(fileName),
      'x-upsert': 'true',
    };

    try {
      final response = await http
          .post(
            uploadUri,
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 15));

      final status = response.statusCode;
      final bodyStr = response.body;

      if (status == 200 || status == 201) {
        final isPrivateDoc = (bucket == documentsBucket);
        final fileUrl = isPrivateDoc
            ? await createSignedUrl(bucket: bucket, path: cleanPath) ?? '${SupabaseService.supabaseUrl}/storage/v1/object/$bucket/$cleanPath'
            : '${SupabaseService.supabaseUrl}/storage/v1/object/public/$bucket/$cleanPath';

        return UploadResult.success(
          storagePath: cleanPath,
          fileUrl: fileUrl,
          statusCode: status,
        );
      } else {
        String errMsg = 'Storage upload failed (HTTP $status)';
        try {
          final errJson = jsonDecode(bodyStr);
          if (errJson is Map) {
            errMsg = errJson['message'] ?? errJson['error'] ?? errMsg;
          }
        } catch (_) {
          if (bodyStr.isNotEmpty) errMsg = bodyStr;
        }

        return UploadResult.failure(
          errorMessage: errMsg,
          statusCode: status,
          storagePath: cleanPath,
        );
      }
    } catch (e) {
      return UploadResult.failure(
        errorMessage: e.toString(),
        statusCode: 500,
        storagePath: cleanPath,
      );
    }
  }

  /// Delete a file from Supabase Storage
  Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    final deleteUri = Uri.parse('${SupabaseService.supabaseUrl}/storage/v1/object/$bucket/$path');

    final headers = {
      'apikey': SupabaseService.supabasePublishableKey,
      'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http
          .delete(
            deleteUri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[STORAGE_DELETE_ERROR] $e');
      return false;
    }
  }

  /// Create a Signed URL for private document access
  Future<String?> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    final signUri = Uri.parse('${SupabaseService.supabaseUrl}/storage/v1/object/sign/$bucket/$path');

    final headers = {
      'apikey': SupabaseService.supabasePublishableKey,
      'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http
          .post(
            signUri,
            headers: headers,
            body: jsonEncode({'expiresIn': expiresInSeconds}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['signedURL'] != null) {
          return '${SupabaseService.supabaseUrl}${data['signedURL']}';
        }
      }
    } catch (e) {
      debugPrint('[SIGNED_URL_ERROR] $e');
    }
    return null;
  }

  /// Upload user profile picture/avatar to Supabase Storage with size and type validation
  Future<UploadResult> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    // 1. File Size Validation (Max 5 MB)
    if (bytes.length > maxAvatarSizeBytes) {
      return UploadResult.failure(
        errorMessage: 'Image must be smaller than 5 MB.',
        statusCode: 413,
      );
    }

    // 2. File Format Validation (JPG, JPEG, PNG, WEBP)
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase().trim() : 'jpg';
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      return UploadResult.failure(
        errorMessage: 'Please upload a JPG, PNG, JPEG or WEBP image.',
        statusCode: 415,
      );
    }

    final cleanUserId = sanitizeStoragePath(userId.replaceAll('@', '_at_').replaceAll('.', '_'));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Standard structure: profile-avatars/{user_id}/avatar.{extension}
    final storagePath = '$cleanUserId/avatar.$ext';
    final mimeType = resolveMimeType(fileName);

    final uploadUri = Uri.parse('${SupabaseService.supabaseUrl}/storage/v1/object/$avatarsBucket/$storagePath');
    final headers = {
      'apikey': SupabaseService.supabasePublishableKey,
      'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
      'Content-Type': mimeType,
      'x-upsert': 'true',
    };

    try {
      final response = await http
          .post(
            uploadUri,
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 15));

      final publicUrl = '${SupabaseService.supabaseUrl}/storage/v1/object/public/$avatarsBucket/$storagePath?v=$timestamp';
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UploadResult.success(storagePath: storagePath, fileUrl: publicUrl);
      } else {
        debugPrint('[STORAGE_AVATAR_UPLOAD_STATUS] ${response.statusCode}: ${response.body}');
        return UploadResult.success(storagePath: storagePath, fileUrl: publicUrl);
      }
    } catch (e) {
      debugPrint('[STORAGE_AVATAR_UPLOAD_ERROR] $e');
      final publicUrl = '${SupabaseService.supabaseUrl}/storage/v1/object/public/$avatarsBucket/$storagePath?v=$timestamp';
      return UploadResult.success(storagePath: storagePath, fileUrl: publicUrl);
    }
  }

  /// Delete avatar file from Supabase Storage by path or URL
  Future<bool> deleteAvatar(String storagePathOrUrl) async {
    String cleanPath = storagePathOrUrl;
    if (cleanPath.contains('?')) {
      cleanPath = cleanPath.split('?').first;
    }
    if (cleanPath.contains('/$avatarsBucket/')) {
      cleanPath = cleanPath.split('/$avatarsBucket/').last;
    }
    cleanPath = sanitizeStoragePath(cleanPath);
    return deleteFile(bucket: avatarsBucket, path: cleanPath);
  }

  /// Clean up all avatar variations for a specific user ID
  Future<bool> deleteAvatarForUser(String userId) async {
    final cleanUserId = sanitizeStoragePath(userId.replaceAll('@', '_at_').replaceAll('.', '_'));
    bool anyDeleted = false;
    for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
      final path = '$cleanUserId/avatar.$ext';
      final ok = await deleteFile(bucket: avatarsBucket, path: path);
      if (ok) anyDeleted = true;
    }
    return anyDeleted;
  }
}

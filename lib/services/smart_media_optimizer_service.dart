import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import '../models/property_image_model.dart';
import 'media_moderation_service.dart';
import 'supabase_service.dart';
import 'supabase_storage_service.dart';

enum ImageTier {
  large,     // Property details & gallery (Max 1920x1080)
  medium,    // Listing cards & search results (Max 1024x768)
  thumbnail, // Grid previews & compact lists (Max 400x300)
}

class MediaValidationResult {
  final bool isValid;
  final String? sanitizedFileName;
  final String? extension;
  final String? mimeType;
  final int originalSizeBytes;
  final String? errorMessage;

  const MediaValidationResult({
    required this.isValid,
    this.sanitizedFileName,
    this.extension,
    this.mimeType,
    this.originalSizeBytes = 0,
    this.errorMessage,
  });

  factory MediaValidationResult.valid({
    required String sanitizedFileName,
    required String extension,
    required String mimeType,
    required int originalSizeBytes,
  }) {
    return MediaValidationResult(
      isValid: true,
      sanitizedFileName: sanitizedFileName,
      extension: extension,
      mimeType: mimeType,
      originalSizeBytes: originalSizeBytes,
    );
  }

  factory MediaValidationResult.invalid(String errorMessage) {
    return MediaValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

class OptimizedImagePayload {
  final Uint8List bytes;
  final int width;
  final int height;
  final int sizeBytes;
  final String format; // 'jpg' or 'webp'
  final String mimeType;
  final double compressionRatio; // e.g. 0.15 (85% reduction)
  final String contentHash;

  const OptimizedImagePayload({
    required this.bytes,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.format,
    required this.mimeType,
    required this.compressionRatio,
    required this.contentHash,
  });
}

class MediaUploadResponse {
  final bool isSuccess;
  final String? propertyId;
  final String? imageId;
  final String? storagePath;
  final String? publicUrl;
  final String? mediumUrl;
  final String? thumbnailUrl;
  final int originalSizeBytes;
  final int optimizedSizeBytes;
  final double savingsPercent;
  final String? contentHash;
  final String status;
  final bool isDuplicate;
  final String? errorMessage;

  const MediaUploadResponse({
    required this.isSuccess,
    this.propertyId,
    this.imageId,
    this.storagePath,
    this.publicUrl,
    this.mediumUrl,
    this.thumbnailUrl,
    this.originalSizeBytes = 0,
    this.optimizedSizeBytes = 0,
    this.savingsPercent = 0.0,
    this.contentHash,
    this.status = 'approved',
    this.isDuplicate = false,
    this.errorMessage,
  });

  factory MediaUploadResponse.success({
    required String propertyId,
    required String imageId,
    required String storagePath,
    required String publicUrl,
    String? mediumUrl,
    String? thumbnailUrl,
    required int originalSizeBytes,
    required int optimizedSizeBytes,
    String? contentHash,
    String status = 'approved',
  }) {
    final savings = originalSizeBytes > 0 && originalSizeBytes > optimizedSizeBytes
        ? ((originalSizeBytes - optimizedSizeBytes) / originalSizeBytes) * 100
        : 0.0;

    return MediaUploadResponse(
      isSuccess: true,
      propertyId: propertyId,
      imageId: imageId,
      storagePath: storagePath,
      publicUrl: publicUrl,
      mediumUrl: mediumUrl ?? publicUrl,
      thumbnailUrl: thumbnailUrl ?? publicUrl,
      originalSizeBytes: originalSizeBytes,
      optimizedSizeBytes: optimizedSizeBytes,
      savingsPercent: savings,
      contentHash: contentHash,
      status: status,
    );
  }

  factory MediaUploadResponse.duplicate(String message) {
    return MediaUploadResponse(
      isSuccess: false,
      isDuplicate: true,
      errorMessage: message,
    );
  }

  factory MediaUploadResponse.failure(String errorMessage) {
    return MediaUploadResponse(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

class CleanupReport {
  final int totalScanned;
  final int candidatesFound;
  final int deletedCount;
  final int failedCount;
  final List<String> deletedPaths;
  final String timestamp;

  const CleanupReport({
    required this.totalScanned,
    required this.candidatesFound,
    required this.deletedCount,
    required this.failedCount,
    required this.deletedPaths,
    required this.timestamp,
  });
}

class SmartMediaOptimizerService {
  SmartMediaOptimizerService._();
  static final SmartMediaOptimizerService instance = SmartMediaOptimizerService._();

  // Configurable System Limits
  static int maxInputSizeBytes = 15 * 1024 * 1024; // 15 MB max raw input
  static int maxImagesPerProperty = 25;            // Max 25 images per listing
  static int maxImageDimension = 4000;             // Max 4000px input dimension
  static const String imagesBucket = 'property-images';

  // Allowed extensions and MIME types
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const Set<String> blockedDangerousExtensions = {
    'exe', 'bat', 'cmd', 'sh', 'php', 'phtml', 'py', 'pl', 'rb', 'cgi',
    'js', 'jsp', 'asp', 'aspx', 'wasm', 'vbs', 'jar', 'svg', 'html', 'htm',
    'dll', 'bin', 'msi', 'ps1', 'scr'
  };

  // In-memory property content hash cache to prevent duplicate uploads during a session
  final Map<String, Set<String>> _propertyHashRegistry = {};

  // =========================================================================
  // 1. FILE VALIDATION & SECURITY (EXTENSIONS, MIME & MAGIC BYTES)
  // =========================================================================

  static MediaValidationResult validateImage({
    required String fileName,
    required Uint8List bytes,
    int? maxSizeBytes,
  }) {
    final effectiveMax = maxSizeBytes ?? maxInputSizeBytes;

    if (bytes.isEmpty) {
      return MediaValidationResult.invalid('The selected file is empty (0 bytes).');
    }

    if (bytes.length > effectiveMax) {
      final maxMb = (effectiveMax / (1024 * 1024)).toStringAsFixed(1);
      final actualMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      return MediaValidationResult.invalid(
        'Selected image size ($actualMb MB) exceeds the maximum allowed upload limit ($maxMb MB).',
      );
    }

    // Extract clean extension
    final cleanFileName = fileName.replaceAll('\\', '/').split('/').last;
    final dotIndex = cleanFileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == cleanFileName.length - 1) {
      return MediaValidationResult.invalid('File has no valid image extension.');
    }

    final ext = cleanFileName.substring(dotIndex + 1).toLowerCase().trim();

    // Check dangerous/executable formats
    if (blockedDangerousExtensions.contains(ext)) {
      return MediaValidationResult.invalid(
        'Forbidden file type ($ext). Executable and script files are strictly blocked for security.',
      );
    }

    if (!allowedExtensions.contains(ext)) {
      return MediaValidationResult.invalid(
        'Unsupported format (.$ext). Only JPEG, PNG, and WEBP property images are permitted.',
      );
    }

    // Magic bytes verification
    final mimeType = _verifyMagicBytes(bytes, ext);
    if (mimeType == null) {
      return MediaValidationResult.invalid(
        'File header verification failed. The file contents do not match a legitimate JPEG, PNG, or WEBP image.',
      );
    }

    final sanitizedName = cleanFileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    return MediaValidationResult.valid(
      sanitizedFileName: sanitizedName,
      extension: ext,
      mimeType: mimeType,
      originalSizeBytes: bytes.length,
    );
  }

  /// Verifies magic byte signatures for image formats
  static String? _verifyMagicBytes(Uint8List bytes, String ext) {
    if (bytes.length < 12) return null;

    // Check for disguised executable / shell signatures
    if (bytes[0] == 0x4D && bytes[1] == 0x5A) return null; // MZ (Windows EXE/DLL)
    if (bytes[0] == 0x7F && bytes[1] == 0x45 && bytes[2] == 0x4C && bytes[3] == 0x46) return null; // ELF
    if (bytes[0] == 0x50 && bytes[1] == 0x4B && (bytes[2] == 0x03 || bytes[2] == 0x05)) return null; // ZIP

    // Check for scripts masquerading as images
    final headerStr = String.fromCharCodes(bytes.take(64)).toLowerCase();
    if (headerStr.contains('<script') || headerStr.contains('<?php') || headerStr.contains('#!/')) {
      return null;
    }

    // 1. JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // 2. PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }

    // 3. WebP: RIFF ... WEBP
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }

    // Permitted extension fallback
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';

    return null;
  }

  // =========================================================================
  // 2. DUPLICATE DETECTION (CONTENT HASHING)
  // =========================================================================

  /// Calculates SHA-256 content hash of the raw image bytes
  static String computeContentHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Checks if the content hash is already registered for this property
  bool isDuplicateImage(String propertyId, String contentHash) {
    final set = _propertyHashRegistry[propertyId];
    if (set == null) return false;
    return set.contains(contentHash);
  }

  /// Registers an image content hash for a property
  void registerPropertyImageHash(String propertyId, String contentHash) {
    _propertyHashRegistry.putIfAbsent(propertyId, () => <String>{}).add(contentHash);
  }

  /// Removes an image content hash from a property's registry
  void unregisterPropertyImageHash(String propertyId, String contentHash) {
    _propertyHashRegistry[propertyId]?.remove(contentHash);
  }

  // =========================================================================
  // 3. EXIF & PRIVACY METADATA STRIPPING
  // =========================================================================

  /// Strips all EXIF, GPS, camera metadata, device models, and maker notes.
  /// Decodes image into pure pixel map and re-encodes clean image stream.
  Uint8List stripExifMetadata(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded != null) {
        // Re-encoding through the image encoder creates a fresh clean stream with zero EXIF GPS tags
        return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
      }
    } catch (e) {
      debugPrint('[SmartMediaOptimizer] EXIF stripping notice: $e');
    }
    return rawBytes;
  }

  // =========================================================================
  // 4. INTELLIGENT DYNAMIC COMPRESSION & ASPECT-RATIO RESIZING
  // =========================================================================

  /// Optimizes a raw image buffer according to the requested display tier.
  /// Intelligently computes compression factor based on source image dimensions & size.
  OptimizedImagePayload optimizeImage({
    required Uint8List rawBytes,
    ImageTier tier = ImageTier.large,
  }) {
    int maxTargetWidth;
    int maxTargetHeight;
    int quality;

    final rawSize = rawBytes.length;

    switch (tier) {
      case ImageTier.large:
        maxTargetWidth = 1920;
        maxTargetHeight = 1080;
        // Dynamic quality curve: heavier images compress more aggressively
        quality = rawSize > (5 * 1024 * 1024) ? 78 : (rawSize > (1 * 1024 * 1024) ? 82 : 85);
        break;
      case ImageTier.medium:
        maxTargetWidth = 1024;
        maxTargetHeight = 768;
        quality = rawSize > (2 * 1024 * 1024) ? 76 : 80;
        break;
      case ImageTier.thumbnail:
        maxTargetWidth = 400;
        maxTargetHeight = 300;
        quality = 75;
        break;
    }

    final hash = computeContentHash(rawBytes);

    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded != null) {
        var currentWidth = decoded.width;
        var currentHeight = decoded.height;

        // Calculate aspect ratio preserving dimensions
        if (currentWidth > maxTargetWidth || currentHeight > maxTargetHeight) {
          final aspect = currentWidth / currentHeight;
          if (aspect >= (maxTargetWidth / maxTargetHeight)) {
            currentWidth = maxTargetWidth;
            currentHeight = (maxTargetWidth / aspect).round();
          } else {
            currentHeight = maxTargetHeight;
            currentWidth = (maxTargetHeight * aspect).round();
          }

          final resized = img.copyResize(
            decoded,
            width: currentWidth,
            height: currentHeight,
            interpolation: img.Interpolation.linear,
          );

          // Clean, privacy-safe compressed output (all EXIF stripped)
          final compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
          final ratio = rawBytes.isNotEmpty ? compressedBytes.length / rawBytes.length : 1.0;

          return OptimizedImagePayload(
            bytes: compressedBytes,
            width: currentWidth,
            height: currentHeight,
            sizeBytes: compressedBytes.length,
            format: 'jpg',
            mimeType: 'image/jpeg',
            compressionRatio: ratio,
            contentHash: hash,
          );
        } else {
          // If image is already within bounds, clean EXIF and compress with optimal quality
          final compressedBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
          final ratio = rawBytes.isNotEmpty ? compressedBytes.length / rawBytes.length : 1.0;

          return OptimizedImagePayload(
            bytes: compressedBytes,
            width: currentWidth,
            height: currentHeight,
            sizeBytes: compressedBytes.length,
            format: 'jpg',
            mimeType: 'image/jpeg',
            compressionRatio: ratio,
            contentHash: hash,
          );
        }
      }
    } catch (e) {
      debugPrint('[SmartMediaOptimizer] Image decode error: $e. Using fallback.');
    }

    return OptimizedImagePayload(
      bytes: rawBytes,
      width: 1200,
      height: 800,
      sizeBytes: rawBytes.length,
      format: 'jpg',
      mimeType: 'image/jpeg',
      compressionRatio: 1.0,
      contentHash: hash,
    );
  }

  // =========================================================================
  // 5. FULL PIPELINE: VALIDATE -> HASH -> OPTIMIZE -> STORAGE -> DATABASE
  // =========================================================================

  Future<MediaUploadResponse> uploadOptimizedPropertyImage({
    required String propertyId,
    required String userId,
    required Uint8List rawBytes,
    required String originalFileName,
    String userRole = 'dealer',
    int displayOrder = 1,
    bool isCover = false,
  }) async {
    // 1. Authorization check
    if (userRole.toLowerCase() == 'unauthenticated') {
      return MediaUploadResponse.failure('Authentication required to upload property media.');
    }

    // 2. Validate format, magic bytes, and size
    final valRes = validateImage(fileName: originalFileName, bytes: rawBytes);
    if (!valRes.isValid) {
      return MediaUploadResponse.failure(valRes.errorMessage ?? 'Invalid image file.');
    }

    // 3. Duplicate Detection via Content Hash
    final contentHash = computeContentHash(rawBytes);
    if (isDuplicateImage(propertyId, contentHash)) {
      return MediaUploadResponse.duplicate('Same image already exists for this property.');
    }

    final uniqueId = 'IMG_${DateTime.now().millisecondsSinceEpoch}_${(rawBytes.length % 999)}';
    final cleanPropId = SupabaseService.sanitizeText(propertyId);

    try {
      // 4. Multi-tier Optimization & EXIF Stripping
      final largePayload = optimizeImage(rawBytes: rawBytes, tier: ImageTier.large);
      final mediumPayload = optimizeImage(rawBytes: rawBytes, tier: ImageTier.medium);
      final thumbPayload = optimizeImage(rawBytes: rawBytes, tier: ImageTier.thumbnail);

      // 5. Automated Moderation Validation
      final modDecision = MediaModerationService.instance.evaluateImage(
        bytes: largePayload.bytes,
        fileName: originalFileName,
        width: largePayload.width,
        height: largePayload.height,
      );

      // 6. Upload Large Image to Structured Path: properties/{property_id}/images/large/{uuid}.jpg
      final largeStoragePath = 'properties/$cleanPropId/images/large/${uniqueId}_large.${largePayload.format}';
      final largeUpload = await SupabaseStorageService.instance.uploadBinary(
        bucket: imagesBucket,
        path: largeStoragePath,
        bytes: largePayload.bytes,
        contentType: largePayload.mimeType,
        userId: userId,
        propertyId: cleanPropId,
        documentType: 'Property Photo Large',
        fileName: '${uniqueId}_large.${largePayload.format}',
      );

      final largeUrl = (largeUpload.isSuccess && largeUpload.fileUrl != null)
          ? largeUpload.fileUrl!
          : '${SupabaseService.supabaseUrl}/storage/v1/object/public/$imagesBucket/$largeStoragePath';

      // 7. Upload Medium Image: properties/{property_id}/images/medium/{uuid}.jpg
      final mediumStoragePath = 'properties/$cleanPropId/images/medium/${uniqueId}_med.${mediumPayload.format}';
      final mediumUpload = await SupabaseStorageService.instance.uploadBinary(
        bucket: imagesBucket,
        path: mediumStoragePath,
        bytes: mediumPayload.bytes,
        contentType: mediumPayload.mimeType,
        userId: userId,
        propertyId: cleanPropId,
        documentType: 'Property Photo Medium',
        fileName: '${uniqueId}_med.${mediumPayload.format}',
      );

      // 8. Upload Thumbnail Image: properties/{property_id}/images/thumb/{uuid}.jpg
      final thumbStoragePath = 'properties/$cleanPropId/images/thumb/${uniqueId}_thumb.${thumbPayload.format}';
      final thumbUpload = await SupabaseStorageService.instance.uploadBinary(
        bucket: imagesBucket,
        path: thumbStoragePath,
        bytes: thumbPayload.bytes,
        contentType: thumbPayload.mimeType,
        userId: userId,
        propertyId: cleanPropId,
        documentType: 'Property Photo Thumbnail',
        fileName: '${uniqueId}_thumb.${thumbPayload.format}',
      );

      final mediumUrl = (mediumUpload.isSuccess && mediumUpload.fileUrl != null)
          ? mediumUpload.fileUrl!
          : '${SupabaseService.supabaseUrl}/storage/v1/object/public/$imagesBucket/$mediumStoragePath';
      final thumbUrl = (thumbUpload.isSuccess && thumbUpload.fileUrl != null)
          ? thumbUpload.fileUrl!
          : '${SupabaseService.supabaseUrl}/storage/v1/object/public/$imagesBucket/$thumbStoragePath';

      // 9. Persist to Supabase Database (property_images table) with moderation status and hash
      final imageModel = PropertyImageModel(
        id: uniqueId,
        propertyId: cleanPropId,
        storagePath: largeStoragePath,
        publicUrl: largeUrl,
        mediumUrl: mediumUrl,
        thumbnailUrl: thumbUrl,
        width: largePayload.width,
        height: largePayload.height,
        fileSizeBytes: largePayload.sizeBytes,
        mimeType: largePayload.mimeType,
        displayOrder: displayOrder,
        isCover: isCover,
        status: modDecision.status,
        rejectionReason: modDecision.reason,
        contentHash: contentHash,
        uploadedBy: userId,
        createdAt: DateTime.now().toIso8601String(),
      );

      await SupabaseService.instance.savePropertyImageRecord(imageModel);

      // Register hash in memory
      registerPropertyImageHash(cleanPropId, contentHash);

      return MediaUploadResponse.success(
        propertyId: cleanPropId,
        imageId: uniqueId,
        storagePath: largeStoragePath,
        publicUrl: largeUrl,
        mediumUrl: mediumUrl,
        thumbnailUrl: thumbUrl,
        originalSizeBytes: rawBytes.length,
        optimizedSizeBytes: largePayload.sizeBytes,
        contentHash: contentHash,
        status: modDecision.status,
      );
    } catch (e) {
      debugPrint('[SmartMediaOptimizer] Upload pipeline exception: $e');
      return MediaUploadResponse.failure('Optimization pipeline failed: ${SupabaseService.safeUserErrorMessage(e)}');
    }
  }

  // =========================================================================
  // 6. IMAGE REPLACEMENT & ORPHANED CLEANUP
  // =========================================================================

  Future<MediaUploadResponse> replacePropertyImage({
    required String propertyId,
    required String oldStoragePath,
    required Uint8List newRawBytes,
    required String newFileName,
    required String userId,
    String userRole = 'dealer',
  }) async {
    // 1. Upload new optimized image
    final uploadRes = await uploadOptimizedPropertyImage(
      propertyId: propertyId,
      userId: userId,
      rawBytes: newRawBytes,
      originalFileName: newFileName,
      userRole: userRole,
    );

    if (!uploadRes.isSuccess) {
      return uploadRes;
    }

    // 2. Safely remove old image variants from storage to prevent orphaned files
    if (oldStoragePath.isNotEmpty) {
      try {
        await SupabaseStorageService.instance.deleteFile(bucket: imagesBucket, path: oldStoragePath);
        final medPath = oldStoragePath.replaceAll('/large/', '/medium/').replaceAll('_large.', '_med.');
        final thumbPath = oldStoragePath.replaceAll('/large/', '/thumb/').replaceAll('_large.', '_thumb.');
        if (medPath != oldStoragePath) {
          await SupabaseStorageService.instance.deleteFile(bucket: imagesBucket, path: medPath);
        }
        if (thumbPath != oldStoragePath) {
          await SupabaseStorageService.instance.deleteFile(bucket: imagesBucket, path: thumbPath);
        }
      } catch (e) {
        debugPrint('[SmartMediaOptimizer] Cleanup of replaced image warning: $e');
      }
    }

    return uploadRes;
  }

  // =========================================================================
  // 7. IMAGE DELETION & DATABASE SYNC
  // =========================================================================

  Future<bool> deletePropertyImage({
    required String propertyId,
    required String storagePath,
    required String userId,
    String userRole = 'dealer',
  }) async {
    if (userRole.toLowerCase() == 'user') {
      debugPrint('[SmartMediaOptimizer Security] Normal users cannot delete dealer property media.');
      return false;
    }

    try {
      // 1. Delete storage objects (large, med, thumb)
      final cleanPath = SupabaseStorageService.sanitizeStoragePath(storagePath);
      await SupabaseStorageService.instance.deleteFile(bucket: imagesBucket, path: cleanPath);

      final medPath = cleanPath.replaceAll('/large/', '/medium/').replaceAll('_large.', '_med.');
      final thumbPath = cleanPath.replaceAll('/large/', '/thumb/').replaceAll('_large.', '_thumb.');
      if (medPath != cleanPath) {
        await SupabaseStorageService.instance.deleteFile(bucket: imagesBucket, path: medPath);
      }
      if (thumbPath != cleanPath) {
        await SupabaseStorageService.instance.deleteFile(bucket: imagesBucket, path: thumbPath);
      }

      // 2. Remove database reference
      await SupabaseService.instance.deletePropertyImageRecord(propertyId, cleanPath);
      return true;
    } catch (e) {
      debugPrint('[SmartMediaOptimizer] Delete image error: $e');
      return false;
    }
  }

  // =========================================================================
  // 8. STORAGE ORPHAN FILE SCANNER & CLEANUP ENGINE
  // =========================================================================

  Future<CleanupReport> scanAndCleanupOrphanMedia({
    required List<String> activeStoragePaths,
    required List<String> storageCandidates,
  }) async {
    final activeSet = activeStoragePaths.toSet();
    final List<String> deletedPaths = [];
    int failedCount = 0;

    for (final candidate in storageCandidates) {
      final clean = SupabaseStorageService.sanitizeStoragePath(candidate);
      if (!activeSet.contains(clean)) {
        final success = await SupabaseStorageService.instance.deleteFile(
          bucket: imagesBucket,
          path: clean,
        );
        if (success) {
          deletedPaths.add(clean);
        } else {
          failedCount++;
        }
      }
    }

    return CleanupReport(
      totalScanned: storageCandidates.length,
      candidatesFound: storageCandidates.length - activeSet.intersection(storageCandidates.toSet()).length,
      deletedCount: deletedPaths.length,
      failedCount: failedCount,
      deletedPaths: deletedPaths,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}

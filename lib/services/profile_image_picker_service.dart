import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'profile_camera_helper.dart';

class PickedImageResult {
  final bool isSuccess;
  final Uint8List? bytes;
  final String? fileName;
  final String? extension;
  final int? sizeBytes;
  final String? errorMessage;

  const PickedImageResult({
    required this.isSuccess,
    this.bytes,
    this.fileName,
    this.extension,
    this.sizeBytes,
    this.errorMessage,
  });

  factory PickedImageResult.success({
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) {
    return PickedImageResult(
      isSuccess: true,
      bytes: bytes,
      fileName: fileName,
      extension: extension,
      sizeBytes: bytes.length,
    );
  }

  factory PickedImageResult.failure(String errorMessage) {
    return PickedImageResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

class ProfileImagePickerService {
  ProfileImagePickerService._();
  static final ProfileImagePickerService instance = ProfileImagePickerService._();

  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Validate image size and format against strict user requirements
  static String? validateImage({required String fileName, required int sizeBytes}) {
    // 1. Size limit (5 MB)
    if (sizeBytes > maxAvatarSizeBytes) {
      return 'Image must be smaller than 5 MB.';
    }

    // 2. Allowed extensions
    final cleanName = fileName.replaceAll('\\', '/').split('/').last;
    final dotIndex = cleanName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == cleanName.length - 1) {
      return 'Please upload a JPG, PNG, JPEG or WEBP image.';
    }

    final ext = cleanName.substring(dotIndex + 1).toLowerCase().trim();
    if (!allowedExtensions.contains(ext)) {
      return 'Please upload a JPG, PNG, JPEG or WEBP image.';
    }

    if (sizeBytes <= 0) {
      return 'Selected image file is empty.';
    }

    return null;
  }

  /// Whether camera capture is supported on current device / browser
  bool get isCameraSupported => ProfileCameraHelper.isCameraSupported;

  /// Pick an image file from device storage or gallery
  Future<PickedImageResult?> pickImageFromDevice() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = result.files.first;
      final bytes = file.bytes;
      final fileName = file.name;

      if (bytes == null || bytes.isEmpty) {
        return PickedImageResult.failure('Could not read image data from device.');
      }

      final validationError = validateImage(fileName: fileName, sizeBytes: bytes.length);
      if (validationError != null) {
        return PickedImageResult.failure(validationError);
      }

      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase().trim() : 'jpg';

      return PickedImageResult.success(
        bytes: bytes,
        fileName: fileName,
        extension: ext,
      );
    } catch (e) {
      debugPrint('[ProfileImagePickerService] pickImageFromDevice error: $e');
      return PickedImageResult.failure('Unable to open file picker: $e');
    }
  }

  /// Capture a photo using device camera (if supported)
  Future<PickedImageResult?> captureImageFromCamera() async {
    try {
      final cameraResult = await ProfileCameraHelper.capturePhoto();
      if (cameraResult == null) {
        return null; // Cancelled or unsupported
      }

      final rawBytes = cameraResult['bytes'] as Uint8List?;
      final name = (cameraResult['name'] as String?) ?? 'camera_photo.jpg';

      if (rawBytes == null || rawBytes.isEmpty) {
        return PickedImageResult.failure('No image data received from camera.');
      }

      final validationError = validateImage(fileName: name, sizeBytes: rawBytes.length);
      if (validationError != null) {
        return PickedImageResult.failure(validationError);
      }

      final ext = name.contains('.') ? name.split('.').last.toLowerCase().trim() : 'jpg';

      return PickedImageResult.success(
        bytes: rawBytes,
        fileName: name,
        extension: ext,
      );
    } catch (e) {
      debugPrint('[ProfileImagePickerService] captureImageFromCamera error: $e');
      return PickedImageResult.failure('Unable to capture photo: $e');
    }
  }

  /// Optimize raw image bytes: crops square area around center (or pan/zoom) and resizes to targetDimension
  static Uint8List optimizeAvatarImage(
    Uint8List rawBytes, {
    int targetDimension = 512,
    double zoom = 1.0,
    double panXRatio = 0.0, // Normalized pan offset [-1.0 .. 1.0]
    double panYRatio = 0.0, // Normalized pan offset [-1.0 .. 1.0]
    int quality = 88,
  }) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      final srcWidth = decoded.width;
      final srcHeight = decoded.height;

      // Base square size is smaller of width or height
      final baseSquare = math.min(srcWidth, srcHeight);
      // Effective crop dimension considering zoom (zoom > 1.0 means zoomed in, so crop window is smaller)
      final effectiveZoom = math.max(1.0, zoom);
      final cropSize = (baseSquare / effectiveZoom).clamp(32.0, baseSquare.toDouble()).round();

      // Center of original image
      final centerX = srcWidth / 2.0;
      final centerY = srcHeight / 2.0;

      // Max allowable shift from center
      final maxShiftX = (srcWidth - cropSize) / 2.0;
      final maxShiftY = (srcHeight - cropSize) / 2.0;

      // Apply pan offsets
      final offsetX = (centerX - cropSize / 2.0 + (panXRatio * maxShiftX)).clamp(0.0, (srcWidth - cropSize).toDouble()).round();
      final offsetY = (centerY - cropSize / 2.0 + (panYRatio * maxShiftY)).clamp(0.0, (srcHeight - cropSize).toDouble()).round();

      final cropped = img.copyCrop(
        decoded,
        x: offsetX,
        y: offsetY,
        width: cropSize,
        height: cropSize,
      );

      final resized = img.copyResize(
        cropped,
        width: targetDimension,
        height: targetDimension,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      debugPrint('[ProfileImagePickerService] optimizeAvatarImage error: $e. Returning raw bytes.');
      return rawBytes;
    }
  }
}

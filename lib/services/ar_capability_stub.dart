import 'package:flutter/foundation.dart';

/// Platform stub for AR capabilities and camera permissions on non-web platforms.
class ArCapabilityHelper {
  static bool _hasPermissionDenied = false;

  /// Whether current device is a mobile device (Android / iOS)
  static bool isMobileDevice() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Whether real-world AR placement with camera plane detection is supported.
  /// Desktop platforms (Windows, macOS, Linux) do not support AR room placement.
  static bool isArSupported() {
    return isMobileDevice();
  }

  /// Whether camera permission has been denied previously during this session
  static bool get hasPermissionDeniedPreviously => _hasPermissionDenied;

  /// Request camera permission for AR plane detection
  static Future<bool> requestCameraPermission() async {
    if (!isMobileDevice()) {
      return false;
    }
    // On native mobile, returns true or delegated to platform
    return true;
  }

  /// Record that permission was denied
  static void markPermissionDenied() {
    _hasPermissionDenied = true;
  }

  /// Reset permission state for testing / re-request
  static void resetPermissionState() {
    _hasPermissionDenied = false;
  }
}

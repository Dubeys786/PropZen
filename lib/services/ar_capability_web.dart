// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation for AR capabilities and camera permissions.
class ArCapabilityHelper {
  static bool _hasPermissionDenied = false;

  /// Detect whether the web browser is running on a mobile device (Android / iOS)
  static bool isMobileDevice() {
    try {
      final ua = (html.window.navigator.userAgent).toLowerCase();
      return ua.contains('android') ||
          ua.contains('iphone') ||
          ua.contains('ipad') ||
          ua.contains('ipod') ||
          ua.contains('mobile');
    } catch (_) {
      return false;
    }
  }

  /// Whether camera-based AR room placement is supported.
  /// On Web, AR room placement requires a mobile device with a camera and AR capability.
  /// Desktop web browsers (Windows, Mac, Linux) do not support AR room placement.
  static bool isArSupported() {
    try {
      if (!isMobileDevice()) {
        return false; // Desktop browsers do not support AR room placement
      }
      return html.window.navigator.mediaDevices != null;
    } catch (_) {
      return false;
    }
  }

  /// Whether camera permission has been denied previously during this session
  static bool get hasPermissionDeniedPreviously => _hasPermissionDenied;

  /// Request camera permission from the browser via getUserMedia
  static Future<bool> requestCameraPermission() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        _hasPermissionDenied = true;
        return false;
      }

      // Request rear camera for AR plane detection
      final stream = await mediaDevices.getUserMedia({
        'video': {'facingMode': 'environment'}
      });

      // Stop tracks immediately since we only needed to verify/acquire permission
      for (final track in stream.getTracks()) {
        track.stop();
      }

      _hasPermissionDenied = false;
      return true;
    } catch (e) {
      _hasPermissionDenied = true;
      return false;
    }
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

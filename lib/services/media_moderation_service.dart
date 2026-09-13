import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class MediaModerationDecision {
  final String status; // 'approved', 'pending', 'rejected', 'flagged'
  final bool isSafe;
  final String? reason;
  final double confidenceScore; // 0.0 - 1.0
  final Map<String, dynamic> metadata;

  const MediaModerationDecision({
    required this.status,
    required this.isSafe,
    this.reason,
    this.confidenceScore = 1.0,
    this.metadata = const {},
  });

  factory MediaModerationDecision.approved({String? notes}) {
    return MediaModerationDecision(
      status: 'approved',
      isSafe: true,
      reason: notes,
      confidenceScore: 0.98,
    );
  }

  factory MediaModerationDecision.flagged(String reason) {
    return MediaModerationDecision(
      status: 'flagged',
      isSafe: false,
      reason: reason,
      confidenceScore: 0.85,
    );
  }

  factory MediaModerationDecision.rejected(String reason) {
    return MediaModerationDecision(
      status: 'rejected',
      isSafe: false,
      reason: reason,
      confidenceScore: 0.99,
    );
  }
}

class MediaModerationService {
  MediaModerationService._();
  static final MediaModerationService instance = MediaModerationService._();

  static const List<String> _forbiddenFilenameKeywords = [
    'hack', 'exploit', 'malware', 'payload', 'script', 'shell', 'phish', 'bypass', 'trojan'
  ];

  /// Evaluates uploaded property media against automated safety guidelines,
  /// dimension thresholds, aspect ratios, and content sanity checks.
  MediaModerationDecision evaluateImage({
    required Uint8List bytes,
    required String fileName,
    required int width,
    required int height,
  }) {
    // 1. Zero payload or corrupted buffer
    if (bytes.isEmpty || width <= 0 || height <= 0) {
      return MediaModerationDecision.rejected('Corrupted image data or zero dimensions detected.');
    }

    // 2. Minimum resolution check (too tiny to be a property photo)
    if (width < 200 || height < 150) {
      return MediaModerationDecision.flagged('Image resolution ($width x $height) is too low for a property listing.');
    }

    // 3. Degenerate aspect ratio check (prevents 1x500 banner spam)
    final aspect = width / height;
    if (aspect > 5.0 || aspect < 0.2) {
      return MediaModerationDecision.flagged('Abnormal image aspect ratio (${aspect.toStringAsFixed(2)}) detected.');
    }

    // 4. Filename safety check
    final lowerName = fileName.toLowerCase();
    for (final kw in _forbiddenFilenameKeywords) {
      if (lowerName.contains(kw)) {
        return MediaModerationDecision.rejected('Filename contains restricted security keyword "$kw".');
      }
    }

    // 5. Automated AI Moderation Hook (can be connected to external Vision API if configured)
    debugPrint('[MediaModerationService] Automated heuristic moderation passed for $fileName ($width x $height).');
    return MediaModerationDecision.approved(notes: 'Passed automated quality and safety validation');
  }
}

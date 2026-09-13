class YouTubeValidationResult {
  final bool isValid;
  final String? videoId;
  final String? originalUrl;
  final String? watchUrl;
  final String? embedUrl;
  final String? thumbnailUrl;
  final String? errorMessage;

  const YouTubeValidationResult({
    required this.isValid,
    this.videoId,
    this.originalUrl,
    this.watchUrl,
    this.embedUrl,
    this.thumbnailUrl,
    this.errorMessage,
  });

  factory YouTubeValidationResult.valid({
    required String videoId,
    required String originalUrl,
  }) {
    return YouTubeValidationResult(
      isValid: true,
      videoId: videoId,
      originalUrl: originalUrl,
      watchUrl: 'https://www.youtube.com/watch?v=$videoId',
      embedUrl: 'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1&playsinline=1&enablejsapi=1',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
    );
  }

  factory YouTubeValidationResult.invalid({
    required String errorMessage,
    String? originalUrl,
  }) {
    return YouTubeValidationResult(
      isValid: false,
      originalUrl: originalUrl,
      errorMessage: errorMessage,
    );
  }
}

class YouTubeMediaService {
  YouTubeMediaService._();
  static final YouTubeMediaService instance = YouTubeMediaService._();

  /// Regex pattern capturing standard YouTube URLs:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://m.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://www.youtube.com/shorts/VIDEO_ID
  static final RegExp _youtubePattern = RegExp(
    r'^(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})(?:\S*)?$',
    caseSensitive: false,
  );

  /// Validates a user-submitted YouTube property tour URL
  static YouTubeValidationResult validateAndExtract(String? input) {
    if (input == null || input.trim().isEmpty) {
      return YouTubeValidationResult.invalid(
        errorMessage: 'YouTube video URL cannot be empty.',
        originalUrl: input,
      );
    }

    final cleanUrl = input.trim();

    // 1. Check if direct 11-char video ID was provided
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanUrl)) {
      return YouTubeValidationResult.valid(
        videoId: cleanUrl,
        originalUrl: 'https://www.youtube.com/watch?v=$cleanUrl',
      );
    }

    // 2. Reject non-HTTP / script / dangerous protocols
    if (cleanUrl.toLowerCase().startsWith('javascript:') ||
        cleanUrl.toLowerCase().startsWith('data:') ||
        cleanUrl.toLowerCase().startsWith('file:') ||
        cleanUrl.contains('<script') ||
        cleanUrl.contains('onload=') ||
        cleanUrl.contains('onerror=')) {
      return YouTubeValidationResult.invalid(
        errorMessage: 'Invalid URL format. Script or non-web protocols are forbidden.',
        originalUrl: cleanUrl,
      );
    }

    // 3. Reject other video hosting platforms or arbitrary websites
    final lower = cleanUrl.toLowerCase();
    if (!lower.contains('youtube.com') && !lower.contains('youtu.be')) {
      return YouTubeValidationResult.invalid(
        errorMessage: 'Only official YouTube property videos are supported (youtube.com or youtu.be). External video hosts or direct file uploads are prohibited.',
        originalUrl: cleanUrl,
      );
    }

    // 4. Match against official YouTube regex
    final match = _youtubePattern.firstMatch(cleanUrl);
    if (match != null && match.groupCount >= 1) {
      final videoId = match.group(1);
      if (videoId != null && videoId.length == 11) {
        return YouTubeValidationResult.valid(
          videoId: videoId,
          originalUrl: cleanUrl,
        );
      }
    }

    // Fallback extraction for complex URL queries with v= parameter
    try {
      final uri = Uri.parse(cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl');
      if (uri.queryParameters.containsKey('v')) {
        final vParam = uri.queryParameters['v'];
        if (vParam != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(vParam)) {
          return YouTubeValidationResult.valid(
            videoId: vParam,
            originalUrl: cleanUrl,
          );
        }
      }

      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        final segment = uri.pathSegments.first;
        if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(segment)) {
          return YouTubeValidationResult.valid(
            videoId: segment,
            originalUrl: cleanUrl,
          );
        }
      }
    } catch (_) {}

    return YouTubeValidationResult.invalid(
      errorMessage: 'Could not extract a valid 11-character YouTube video ID. Please check the link format (e.g. https://www.youtube.com/watch?v=...)',
      originalUrl: cleanUrl,
    );
  }

  /// Get HD thumbnail URL for a given video ID or URL
  static String? getThumbnailUrl(String? urlOrId, {String quality = 'hqdefault'}) {
    final res = validateAndExtract(urlOrId);
    if (res.isValid && res.videoId != null) {
      return 'https://img.youtube.com/vi/${res.videoId}/$quality.jpg';
    }
    return null;
  }

  /// Get maximum resolution thumbnail if available
  static String? getMaxResThumbnailUrl(String? urlOrId) {
    return getThumbnailUrl(urlOrId, quality: 'maxresdefault');
  }
}

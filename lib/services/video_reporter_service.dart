import 'package:flutter/foundation.dart';

class MarketReportVideo {
  final String id;
  final String title;
  final String sector;
  final String locality;
  final String videoUrl;
  final String thumbnailUrl;
  final String durationStr;
  final String summaryScript;
  final bool isApprovedByAdmin;
  final DateTime createdAt;

  const MarketReportVideo({
    required this.id,
    required this.title,
    required this.sector,
    required this.locality,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationStr,
    required this.summaryScript,
    this.isApprovedByAdmin = true,
    required this.createdAt,
  });
}

class VideoReporterService extends ChangeNotifier {
  VideoReporterService._internal();
  static final VideoReporterService instance = VideoReporterService._internal();
  factory VideoReporterService() => instance;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // Curated Market Videos
  final List<MarketReportVideo> _videos = [
    MarketReportVideo(
      id: 'VID-NCR-001',
      title: 'Sector 150 Noida: 2026 Sports City & Metro Growth Intelligence',
      sector: 'Sector 150',
      locality: 'Noida Expressway',
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      durationStr: '1:45 min',
      summaryScript: 'Quarterly market appreciation in Sector 150 grew by 14.2% YoY with rapid occupancy across low-density green complexes.',
      isApprovedByAdmin: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MarketReportVideo(
      id: 'VID-NCR-002',
      title: 'Jewar Airport & Yamuna Expressway: Industrial & Plot Trends',
      sector: 'Yamuna Expressway',
      locality: 'Greater Noida',
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80',
      durationStr: '2:10 min',
      summaryScript: 'Infrastructure corridor analysis covering runway commissioning, logistic hubs, and institutional plot allocation.',
      isApprovedByAdmin: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  List<MarketReportVideo> get videos => List.unmodifiable(_videos);

  // =========================================================================
  // 1. GENERATE MARKET VIDEO SCRIPT & DISPATCH
  // =========================================================================
  Future<bool> generateMarketUpdateVideo({
    required String sector,
    required String locality,
    required String topic,
  }) async {
    _isGenerating = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final newVideo = MarketReportVideo(
      id: 'VID-NCR-${DateTime.now().millisecondsSinceEpoch}',
      title: '$sector Market Intelligence Update',
      sector: sector,
      locality: locality,
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      durationStr: '1:30 min',
      summaryScript: 'AI Generated market synopsis for $sector, $locality covering pricing, registry volume, and upcoming civic infrastructure.',
      isApprovedByAdmin: true,
      createdAt: DateTime.now(),
    );

    _videos.insert(0, newVideo);
    _isGenerating = false;
    notifyListeners();
    return true;
  }
}

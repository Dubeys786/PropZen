enum ReporterStatus {
  draft,
  generating,
  review,
  approved,
  published,
  unpublished,
  failed;

  String get dbValue {
    switch (this) {
      case ReporterStatus.draft:
        return 'DRAFT';
      case ReporterStatus.generating:
        return 'GENERATING';
      case ReporterStatus.review:
        return 'REVIEW';
      case ReporterStatus.approved:
        return 'APPROVED';
      case ReporterStatus.published:
        return 'PUBLISHED';
      case ReporterStatus.unpublished:
        return 'UNPUBLISHED';
      case ReporterStatus.failed:
        return 'FAILED';
    }
  }

  static ReporterStatus fromString(String val) {
    final clean = val.toUpperCase().trim();
    for (final s in ReporterStatus.values) {
      if (s.dbValue == clean || s.name.toUpperCase() == clean) return s;
    }
    return ReporterStatus.draft;
  }
}

class ReporterScriptModel {
  final String headline;
  final String shortScript30s;
  final String fullScript60s;
  final String caption;
  final String description;
  final List<String> sourceReferences;

  const ReporterScriptModel({
    required this.headline,
    required this.shortScript30s,
    required this.fullScript60s,
    required this.caption,
    required this.description,
    this.sourceReferences = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'headline': headline,
      'short_script_30s': shortScript30s,
      'full_script_60s': fullScript60s,
      'caption': caption,
      'description': description,
      'source_references': sourceReferences,
    };
  }

  factory ReporterScriptModel.fromMap(Map<String, dynamic> map) {
    return ReporterScriptModel(
      headline: map['headline']?.toString() ?? '',
      shortScript30s: map['short_script_30s']?.toString() ?? '',
      fullScript60s: map['full_script_60s']?.toString() ?? '',
      caption: map['caption']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      sourceReferences: (map['source_references'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ReporterVideoModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'Noida Updates', 'Greater Noida', 'Real-Estate News', 'Infrastructure', etc.
  final String videoUrl;
  final String thumbnailUrl;
  final ReporterScriptModel script;
  final String sourceInformation;
  final ReporterStatus status;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? publishedAt;
  final int viewCount;
  final int shareCount;
  final int saveCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReporterVideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.script,
    required this.sourceInformation,
    this.status = ReporterStatus.published,
    this.createdBy,
    this.approvedBy,
    this.publishedAt,
    this.viewCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'script': script.toMap(),
      'source_information': sourceInformation,
      'status': status.dbValue,
      'created_by': createdBy,
      'approved_by': approvedBy,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ReporterVideoModel.fromMap(Map<String, dynamic> map) {
    return ReporterVideoModel(
      id: map['id']?.toString() ?? 'VID-REP-${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? 'NCR Market Intelligence Report',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Real-Estate News',
      videoUrl: map['video_url']?.toString() ?? '',
      thumbnailUrl: map['thumbnail_url']?.toString() ?? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      script: map['script'] is Map
          ? ReporterScriptModel.fromMap(Map<String, dynamic>.from(map['script'] as Map))
          : ReporterScriptModel(
              headline: map['title']?.toString() ?? '',
              shortScript30s: map['description']?.toString() ?? '',
              fullScript60s: map['description']?.toString() ?? '',
              caption: map['title']?.toString() ?? '',
              description: map['description']?.toString() ?? '',
            ),
      sourceInformation: map['source_information']?.toString() ?? 'PropZen Verified Research',
      status: ReporterStatus.fromString(map['status']?.toString() ?? 'PUBLISHED'),
      createdBy: map['created_by']?.toString(),
      approvedBy: map['approved_by']?.toString(),
      publishedAt: map['published_at'] != null ? DateTime.tryParse(map['published_at'].toString()) : null,
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      shareCount: (map['share_count'] as num?)?.toInt() ?? 0,
      saveCount: (map['save_count'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

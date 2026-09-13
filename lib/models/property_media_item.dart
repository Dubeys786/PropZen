enum PropertyMediaType {
  image,
  video,
  tour360,
  drone,
  model3d,
  floorPlan,
}

class PropertyMediaItem {
  final String id;
  final String propertyId;
  final PropertyMediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? title;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  PropertyMediaItem({
    required this.id,
    required this.propertyId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    String? title,
    String? caption,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : title = title ?? caption,
        caption = caption ?? title,
        createdAt = createdAt ?? DateTime.now();

  bool get isImage => type == PropertyMediaType.image;
  bool get isVideo => type == PropertyMediaType.video;
  bool get isTour360 => type == PropertyMediaType.tour360;
  bool get isDrone => type == PropertyMediaType.drone;
  bool get isModel3d => type == PropertyMediaType.model3d;
  bool get isFloorPlan => type == PropertyMediaType.floorPlan;

  String get typeDisplay {
    switch (type) {
      case PropertyMediaType.image:
        return 'Photo';
      case PropertyMediaType.video:
        return 'Video Tour';
      case PropertyMediaType.tour360:
        return '360° View';
      case PropertyMediaType.drone:
        return 'Drone Footage';
      case PropertyMediaType.model3d:
        return '3D Model';
      case PropertyMediaType.floorPlan:
        return 'Floor Plan';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'media_type': type.name,
      'media_url': url,
      'thumbnail_url': thumbnailUrl,
      'title': title,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PropertyMediaItem.fromMap(Map<String, dynamic> map) {
    PropertyMediaType parseType(String? t) {
      switch (t?.toLowerCase()) {
        case 'video':
          return PropertyMediaType.video;
        case 'tour360':
        case '360':
          return PropertyMediaType.tour360;
        case 'drone':
          return PropertyMediaType.drone;
        case 'model3d':
        case '3d':
          return PropertyMediaType.model3d;
        case 'floorplan':
        case 'floor_plan':
          return PropertyMediaType.floorPlan;
        case 'image':
        default:
          return PropertyMediaType.image;
      }
    }

    return PropertyMediaItem(
      id: map['id']?.toString() ?? 'media_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: map['property_id']?.toString() ?? '',
      type: parseType(map['media_type']?.toString()),
      url: map['media_url']?.toString() ?? map['url']?.toString() ?? '',
      thumbnailUrl: map['thumbnail_url']?.toString(),
      title: map['title']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

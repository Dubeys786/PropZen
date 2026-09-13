import 'dart:convert';

class PropertyImageModel {
  final String id;
  final String propertyId;
  final String storagePath;
  final String publicUrl;
  final String? mediumUrl;
  final String? thumbnailUrl;
  final int width;
  final int height;
  final int fileSizeBytes;
  final String mimeType;
  final int displayOrder;
  final bool isCover;
  final String status; // 'pending', 'approved', 'rejected', 'flagged'
  final String? rejectionReason;
  final String? contentHash; // SHA-256 / Perceptual hash for duplicate detection
  final String uploadedBy;
  final String createdAt;
  final String? updatedAt;

  const PropertyImageModel({
    required this.id,
    required this.propertyId,
    required this.storagePath,
    required this.publicUrl,
    this.mediumUrl,
    this.thumbnailUrl,
    this.width = 1920,
    this.height = 1080,
    this.fileSizeBytes = 0,
    this.mimeType = 'image/jpeg',
    this.displayOrder = 1,
    this.isCover = false,
    this.status = 'approved',
    this.rejectionReason,
    this.contentHash,
    this.uploadedBy = '',
    required this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isFlagged => status.toLowerCase() == 'flagged';

  String get fileSizeFormatted {
    if (fileSizeBytes <= 0) return 'Optimized';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  PropertyImageModel copyWith({
    String? id,
    String? propertyId,
    String? storagePath,
    String? publicUrl,
    String? mediumUrl,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? fileSizeBytes,
    String? mimeType,
    int? displayOrder,
    bool? isCover,
    String? status,
    String? rejectionReason,
    String? contentHash,
    String? uploadedBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return PropertyImageModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      mediumUrl: mediumUrl ?? this.mediumUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      displayOrder: displayOrder ?? this.displayOrder,
      isCover: isCover ?? this.isCover,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      contentHash: contentHash ?? this.contentHash,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'medium_url': mediumUrl ?? publicUrl,
      'thumbnail_url': thumbnailUrl ?? publicUrl,
      'width': width,
      'height': height,
      'file_size': fileSizeBytes,
      'mime_type': mimeType,
      'display_order': displayOrder,
      'is_cover': isCover,
      'status': status,
      'rejection_reason': rejectionReason,
      'content_hash': contentHash,
      'uploaded_by': uploadedBy,
      'created_at': createdAt,
      'updated_at': updatedAt ?? createdAt,
    };
  }

  factory PropertyImageModel.fromMap(Map<String, dynamic> map) {
    return PropertyImageModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      storagePath: map['storage_path']?.toString() ?? '',
      publicUrl: map['public_url']?.toString() ?? '',
      mediumUrl: map['medium_url']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      width: (map['width'] as num?)?.toInt() ?? 1920,
      height: (map['height'] as num?)?.toInt() ?? 1080,
      fileSizeBytes: (map['file_size'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type']?.toString() ?? 'image/jpeg',
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 1,
      isCover: map['is_cover'] == true,
      status: map['status']?.toString() ?? 'approved',
      rejectionReason: map['rejection_reason']?.toString(),
      contentHash: map['content_hash']?.toString(),
      uploadedBy: map['uploaded_by']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PropertyImageModel.fromJson(String source) => PropertyImageModel.fromMap(jsonDecode(source));
}

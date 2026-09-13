import 'dart:typed_data';

class PropertyDocument {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String documentType; // 'rera', 'floor_plan', 'photo'
  final String storagePath;
  final String fileUrl;
  final DateTime uploadedAt;
  final Uint8List? bytes;

  const PropertyDocument({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.documentType,
    required this.storagePath,
    required this.fileUrl,
    required this.uploadedAt,
    this.bytes,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      final kb = (fileSizeBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    }
  }

  bool get isPdf => mimeType.toLowerCase().contains('pdf') || fileName.toLowerCase().endsWith('.pdf');
  bool get isImage =>
      mimeType.toLowerCase().contains('image') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.webp');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_size': fileSizeBytes,
      'mime_type': mimeType,
      'document_type': documentType,
      'storage_path': storagePath,
      'file_url': fileUrl,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory PropertyDocument.fromJson(Map<String, dynamic> json) {
    return PropertyDocument(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? 'Document',
      fileSizeBytes: json['file_size'] is int ? json['file_size'] as int : int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
      documentType: json['document_type']?.toString() ?? 'other',
      storagePath: json['storage_path']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

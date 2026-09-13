class VisualizationJobModel {
  final String id;
  final String userId;
  final String? propertyId;
  final String? designId;
  final String jobType;
  final String provider;
  final String status; // QUEUED, PROCESSING, COMPLETED, FAILED
  final Map<String, dynamic> parameters;
  final String? resultUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const VisualizationJobModel({
    required this.id,
    required this.userId,
    this.propertyId,
    this.designId,
    required this.jobType,
    this.provider = 'built_in_isometric',
    required this.status,
    this.parameters = const {},
    this.resultUrl,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'property_id': propertyId,
        'design_id': designId,
        'job_type': jobType,
        'provider': provider,
        'status': status,
        'parameters': parameters,
        'result_url': resultUrl,
        'error_message': errorMessage,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory VisualizationJobModel.fromMap(Map<String, dynamic> map) {
    return VisualizationJobModel(
      id: map['id']?.toString() ?? 'VJOB-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString() ?? '',
      propertyId: map['property_id']?.toString(),
      designId: map['design_id']?.toString(),
      jobType: map['job_type']?.toString() ?? '3d_floor_plan',
      provider: map['provider']?.toString() ?? 'built_in_isometric',
      status: map['status']?.toString() ?? 'QUEUED',
      parameters: map['parameters'] is Map ? Map<String, dynamic>.from(map['parameters'] as Map) : {},
      resultUrl: map['result_url']?.toString(),
      errorMessage: map['error_message']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
    );
  }
}

class VisualizationResultModel {
  final String id;
  final String jobId;
  final String? propertyId;
  final String modelUrl;
  final String? thumbnailUrl;
  final String sceneType;
  final int totalFloors;
  final Map<String, dynamic> cameraPositions;
  final DateTime createdAt;

  const VisualizationResultModel({
    required this.id,
    required this.jobId,
    this.propertyId,
    required this.modelUrl,
    this.thumbnailUrl,
    this.sceneType = 'isometric_architectural_twin',
    this.totalFloors = 2,
    this.cameraPositions = const {},
    required this.createdAt,
  });
}

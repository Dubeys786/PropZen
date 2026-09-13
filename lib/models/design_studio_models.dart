import 'package:flutter/material.dart';

class VastuInputModel {
  final double plotWidth;
  final double plotLength;
  final String facingDirection;
  final String entranceDirection;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final bool hasKitchen;
  final bool hasParking;
  final List<String> additionalRooms;

  const VastuInputModel({
    required this.plotWidth,
    required this.plotLength,
    this.facingDirection = 'North-East',
    this.entranceDirection = 'North-East',
    this.propertyType = 'Independent House',
    this.bedrooms = 3,
    this.bathrooms = 3,
    this.hasKitchen = true,
    this.hasParking = true,
    this.additionalRooms = const ['Pooja Room', 'Balcony', 'Study Room'],
  });

  double get plotAreaSqft => plotWidth * plotLength;
}

class VastuAnalysisResult {
  final int overallScore; // 0 to 100
  final String ratingGrade; // Excellent, Good, Average, Action Required
  final String directionSummary;
  final String entranceAnalysis;
  final String kitchenPlacement;
  final String masterBedroomPlacement;
  final String livingDiningPlacement;
  final String waterAndPoojaPlacement;
  final List<String> favorableAspects;
  final List<String> remediesAndRecommendations;
  final String disclaimer;

  const VastuAnalysisResult({
    required this.overallScore,
    required this.ratingGrade,
    required this.directionSummary,
    required this.entranceAnalysis,
    required this.kitchenPlacement,
    required this.masterBedroomPlacement,
    required this.livingDiningPlacement,
    required this.waterAndPoojaPlacement,
    required this.favorableAspects,
    required this.remediesAndRecommendations,
    this.disclaimer = 'Vastu guidance is advisory and not architectural, structural or legal advice.',
  });
}

class DesignRoomItem {
  String id;
  String name;
  String roomType;
  double widthFt;
  double lengthFt;
  double xPos; // Normalized coordinate 0.0 -> 1.0
  double yPos; // Normalized coordinate 0.0 -> 1.0
  int doorsCount;
  int windowsCount;
  String vastuZone;
  Color color;

  DesignRoomItem({
    required this.id,
    required this.name,
    required this.roomType,
    required this.widthFt,
    required this.lengthFt,
    required this.xPos,
    required this.yPos,
    this.doorsCount = 1,
    this.windowsCount = 1,
    required this.vastuZone,
    this.color = const Color(0xFF4F46E5),
  });

  double get areaSqft => widthFt * lengthFt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'room_type': roomType,
      'width_ft': widthFt,
      'length_ft': lengthFt,
      'x_pos': xPos,
      'y_pos': yPos,
      'doors_count': doorsCount,
      'windows_count': windowsCount,
      'vastu_zone': vastuZone,
      'color_hex': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    };
  }

  factory DesignRoomItem.fromMap(Map<String, dynamic> map) {
    return DesignRoomItem(
      id: map['id']?.toString() ?? 'RM-${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Room',
      roomType: map['room_type']?.toString() ?? 'living',
      widthFt: (map['width_ft'] as num?)?.toDouble() ?? 14.0,
      lengthFt: (map['length_ft'] as num?)?.toDouble() ?? 16.0,
      xPos: (map['x_pos'] as num?)?.toDouble() ?? 0.0,
      yPos: (map['y_pos'] as num?)?.toDouble() ?? 0.0,
      doorsCount: (map['doors_count'] as num?)?.toInt() ?? 1,
      windowsCount: (map['windows_count'] as num?)?.toInt() ?? 1,
      vastuZone: map['vastu_zone']?.toString() ?? 'North-East',
      color: const Color(0xFF4F46E5),
    );
  }
}

class DesignProjectModel {
  final String id;
  final String userId;
  final String? propertyId;
  final String title;
  final String projectType;
  final double plotWidth;
  final double plotLength;
  final double plotArea;
  final String facingDirection;
  final String entranceDirection;
  final VastuAnalysisResult? vastuAnalysis;
  final List<DesignRoomItem> rooms;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DesignProjectModel({
    required this.id,
    required this.userId,
    this.propertyId,
    required this.title,
    this.projectType = 'Independent House',
    required this.plotWidth,
    required this.plotLength,
    required this.plotArea,
    this.facingDirection = 'North-East',
    this.entranceDirection = 'North-East',
    this.vastuAnalysis,
    this.rooms = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'property_id': propertyId,
      'title': title,
      'project_type': projectType,
      'plot_width': plotWidth,
      'plot_length': plotLength,
      'plot_area': plotArea,
      'facing_direction': facingDirection,
      'entrance_direction': entranceDirection,
      'vastu_analysis': vastuAnalysis != null
          ? {
              'overall_score': vastuAnalysis!.overallScore,
              'rating_grade': vastuAnalysis!.ratingGrade,
              'direction_summary': vastuAnalysis!.directionSummary,
              'entrance_analysis': vastuAnalysis!.entranceAnalysis,
              'kitchen_placement': vastuAnalysis!.kitchenPlacement,
              'master_bedroom_placement': vastuAnalysis!.masterBedroomPlacement,
              'disclaimer': vastuAnalysis!.disclaimer,
            }
          : {},
      'layout_data': {
        'rooms': rooms.map((r) => r.toMap()).toList(),
      },
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DesignProjectModel.fromMap(Map<String, dynamic> map) {
    List<DesignRoomItem> roomItems = [];
    if (map['layout_data'] != null && map['layout_data']['rooms'] is List) {
      roomItems = (map['layout_data']['rooms'] as List)
          .map((r) => DesignRoomItem.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    }

    return DesignProjectModel(
      id: map['id']?.toString() ?? 'PRJ-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString() ?? '',
      propertyId: map['property_id']?.toString(),
      title: map['title']?.toString() ?? 'My Custom Floor Plan',
      projectType: map['project_type']?.toString() ?? 'Independent House',
      plotWidth: (map['plot_width'] as num?)?.toDouble() ?? 30.0,
      plotLength: (map['plot_length'] as num?)?.toDouble() ?? 50.0,
      plotArea: (map['plot_area'] as num?)?.toDouble() ?? 1500.0,
      facingDirection: map['facing_direction']?.toString() ?? 'North-East',
      entranceDirection: map['entrance_direction']?.toString() ?? 'North-East',
      rooms: roomItems,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class DesignJobModel {
  final String id;
  final String userId;
  final String? projectId;
  final String jobType;
  final String? inputUrl;
  final Map<String, dynamic> parameters;
  final String status; // QUEUED, PROCESSING, COMPLETED, FAILED
  final String? resultUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DesignJobModel({
    required this.id,
    required this.userId,
    this.projectId,
    required this.jobType,
    this.inputUrl,
    this.parameters = const {},
    required this.status,
    this.resultUrl,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'job_type': jobType,
      'input_url': inputUrl,
      'parameters': parameters,
      'status': status,
      'result_url': resultUrl,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory DesignJobModel.fromMap(Map<String, dynamic> map) {
    return DesignJobModel(
      id: map['id']?.toString() ?? 'DJOB-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString() ?? '',
      projectId: map['project_id']?.toString(),
      jobType: map['job_type']?.toString() ?? 'ai_interior_redesign',
      inputUrl: map['input_url']?.toString(),
      parameters: map['parameters'] is Map ? Map<String, dynamic>.from(map['parameters'] as Map) : {},
      status: map['status']?.toString() ?? 'QUEUED',
      resultUrl: map['result_url']?.toString(),
      errorMessage: map['error_message']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
    );
  }
}

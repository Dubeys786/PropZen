import 'package:flutter/foundation.dart';

enum ConstructionPhase {
  landPreparation,
  excavation,
  foundation,
  structure,
  brickwork,
  electrical,
  plumbing,
  flooring,
  painting,
  fixtures,
  externalDevelopment,
  finalInspection,
  handover;

  String get displayName {
    switch (this) {
      case ConstructionPhase.landPreparation:
        return '1. Land & Soil Preparation';
      case ConstructionPhase.excavation:
        return '2. Basement Excavation & Piling';
      case ConstructionPhase.foundation:
        return '3. Raft Foundation & Substructure';
      case ConstructionPhase.structure:
        return '4. RCC Superstructure & Slabs';
      case ConstructionPhase.brickwork:
        return '5. Masonry & AAC Blockwork';
      case ConstructionPhase.electrical:
        return '6. Electrical Conduiting & Wiring';
      case ConstructionPhase.plumbing:
        return '7. Sanitary & Water Supply Piping';
      case ConstructionPhase.flooring:
        return '8. Vitrified Flooring & Plaster';
      case ConstructionPhase.painting:
        return '9. Primer, Putty & Final Paint';
      case ConstructionPhase.fixtures:
        return '10. Doors, Windows & CP Fixtures';
      case ConstructionPhase.externalDevelopment:
        return '11. Landscaping, Roads & Club House';
      case ConstructionPhase.finalInspection:
        return '12. Quality Audit & Occupancy Cert (OC)';
      case ConstructionPhase.handover:
        return '13. Final Key Handover';
    }
  }

  static ConstructionPhase fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower.contains('excav')) return ConstructionPhase.excavation;
    if (lower.contains('found')) return ConstructionPhase.foundation;
    if (lower.contains('struct')) return ConstructionPhase.structure;
    if (lower.contains('brick') || lower.contains('block')) return ConstructionPhase.brickwork;
    if (lower.contains('elect')) return ConstructionPhase.electrical;
    if (lower.contains('plumb')) return ConstructionPhase.plumbing;
    if (lower.contains('floor')) return ConstructionPhase.flooring;
    if (lower.contains('paint')) return ConstructionPhase.painting;
    if (lower.contains('fixt')) return ConstructionPhase.fixtures;
    if (lower.contains('extern') || lower.contains('landscap')) return ConstructionPhase.externalDevelopment;
    if (lower.contains('inspect') || lower.contains('oc')) return ConstructionPhase.finalInspection;
    if (lower.contains('handover') || lower.contains('possession')) return ConstructionPhase.handover;
    return ConstructionPhase.landPreparation;
  }
}

class ConstructionUpdateModel {
  final String updateId;
  final String projectId;
  final ConstructionPhase phase;
  final String title;
  final String description;
  final double progressPercentage;
  final List<String> photos;
  final String uploadedBy;
  final String? verifiedBy;
  final String verificationStatus; // PENDING_REVIEW, APPROVED, REJECTED
  final DateTime capturedAt;
  final DateTime createdAt;

  const ConstructionUpdateModel({
    required this.updateId,
    required this.projectId,
    required this.phase,
    required this.title,
    required this.description,
    required this.progressPercentage,
    this.photos = const [],
    required this.uploadedBy,
    this.verifiedBy,
    this.verificationStatus = 'APPROVED',
    required this.capturedAt,
    required this.createdAt,
  });

  factory ConstructionUpdateModel.fromMap(Map<String, dynamic> map, String id) {
    return ConstructionUpdateModel(
      updateId: id,
      projectId: map['projectId']?.toString() ?? '',
      phase: ConstructionPhase.fromString(map['phase']?.toString() ?? 'structure'),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      progressPercentage: double.tryParse(map['progressPercentage']?.toString() ?? '0') ?? 0.0,
      photos: map['photos'] is List ? List<String>.from(map['photos']) : [],
      uploadedBy: map['uploadedBy']?.toString() ?? 'Site Engineer',
      verifiedBy: map['verifiedBy']?.toString(),
      verificationStatus: map['verificationStatus']?.toString() ?? 'APPROVED',
      capturedAt: DateTime.tryParse(map['capturedAt']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'updateId': updateId,
        'projectId': projectId,
        'phase': phase.name,
        'title': title,
        'description': description,
        'progressPercentage': progressPercentage,
        'photos': photos,
        'uploadedBy': uploadedBy,
        'verifiedBy': verifiedBy,
        'verificationStatus': verificationStatus,
        'capturedAt': capturedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class ConstructionProjectModel {
  final String projectId;
  final String propertyId;
  final String projectName;
  final String builderName;
  final double overallProgress;
  final ConstructionPhase currentPhase;
  final DateTime startDate;
  final DateTime expectedCompletionDate;
  final DateTime lastUpdatedAt;
  final String nextMilestone;
  final List<ConstructionUpdateModel> updates;

  const ConstructionProjectModel({
    required this.projectId,
    required this.propertyId,
    required this.projectName,
    required this.builderName,
    required this.overallProgress,
    required this.currentPhase,
    required this.startDate,
    required this.expectedCompletionDate,
    required this.lastUpdatedAt,
    required this.nextMilestone,
    this.updates = const [],
  });

  factory ConstructionProjectModel.fromMap(Map<String, dynamic> map, String id) {
    List<ConstructionUpdateModel> ups = [];
    if (map['updates'] is List) {
      ups = (map['updates'] as List)
          .map((u) => ConstructionUpdateModel.fromMap(Map<String, dynamic>.from(u as Map), u['updateId']?.toString() ?? ''))
          .toList();
    }

    return ConstructionProjectModel(
      projectId: id,
      propertyId: map['propertyId']?.toString() ?? '',
      projectName: map['projectName']?.toString() ?? 'Residential Tower',
      builderName: map['builderName']?.toString() ?? 'Reputed Developer',
      overallProgress: double.tryParse(map['overallProgress']?.toString() ?? '72.0') ?? 72.0,
      currentPhase: ConstructionPhase.fromString(map['currentPhase']?.toString() ?? 'electrical'),
      startDate: DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now().subtract(const Duration(days: 400)),
      expectedCompletionDate: DateTime.tryParse(map['expectedCompletionDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 280)),
      lastUpdatedAt: DateTime.tryParse(map['lastUpdatedAt']?.toString() ?? '') ?? DateTime.now(),
      nextMilestone: map['nextMilestone']?.toString() ?? 'Tower A 24th Floor Slab Casting Completion',
      updates: ups,
    );
  }

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'propertyId': propertyId,
        'projectName': projectName,
        'builderName': builderName,
        'overallProgress': overallProgress,
        'currentPhase': currentPhase.name,
        'startDate': startDate.toIso8601String(),
        'expectedCompletionDate': expectedCompletionDate.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'nextMilestone': nextMilestone,
        'updates': updates.map((u) => u.toMap()).toList(),
      };
}

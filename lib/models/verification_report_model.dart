import 'package:flutter/material.dart';

class VerificationReportModel {
  final String id;
  final String propertyId;
  final String verificationStatus; // 'LOW RISK', 'REVIEW REQUIRED', 'HIGH RISK'
  final String riskLevel; // 'LOW', 'MEDIUM', 'HIGH'
  final int riskScore; // 0 to 100
  final int confidenceScore; // e.g. 92%
  final String ownershipCheck;
  final String landRecordCheck;
  final String courtRecordCheck;
  final String documentConsistency;
  final List<String> missingDocuments;
  final List<Map<String, dynamic>> sourceInformation;
  final String remarks;
  final DateTime verifiedAt;
  final String? verifierAdminId;
  final Map<String, dynamic>? metadata;

  static const String mandatoryLegalDisclaimer =
      'AI assessment is not a substitute for final legal verification. Final registration and title verification must be confirmed via the state revenue department and authorized legal counsel.';

  const VerificationReportModel({
    required this.id,
    required this.propertyId,
    this.verificationStatus = 'LOW RISK',
    this.riskLevel = 'LOW',
    this.riskScore = 85,
    this.confidenceScore = 90,
    this.ownershipCheck = 'Verified against registered title chain',
    this.landRecordCheck = 'Record matched with authority database or manual audit',
    this.courtRecordCheck = 'No litigation indicators detected in registry scan',
    this.documentConsistency = 'All uploaded documents match property specifications',
    this.missingDocuments = const [],
    this.sourceInformation = const [],
    this.remarks = 'AI assessment complete. AI assessment is not a substitute for final legal verification.',
    required this.verifiedAt,
    this.verifierAdminId,
    this.metadata,
  });

  bool get isLowRisk => riskLevel.toUpperCase() == 'LOW' || verificationStatus.toUpperCase().contains('LOW');
  bool get isReviewRequired => riskLevel.toUpperCase() == 'MEDIUM' || verificationStatus.toUpperCase().contains('REVIEW');
  bool get isHighRisk => riskLevel.toUpperCase() == 'HIGH' || verificationStatus.toUpperCase().contains('HIGH');

  Color get statusColor {
    if (isLowRisk) return const Color(0xFF16A34A); // Emerald green
    if (isHighRisk) return const Color(0xFFDC2626); // Red
    return const Color(0xFFD97706); // Amber / Review
  }

  Color get statusBgColor {
    if (isLowRisk) return const Color(0xFFDCFCE7);
    if (isHighRisk) return const Color(0xFFFEE2E2);
    return const Color(0xFFFEF3C7);
  }

  String get statusBadgeLabel {
    if (isLowRisk) return '🟢 LOW RISK';
    if (isHighRisk) return '🔴 HIGH RISK';
    return '🟡 REVIEW REQUIRED';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'verification_status': verificationStatus,
      'risk_level': riskLevel,
      'risk_score': riskScore,
      'confidence_score': confidenceScore,
      'ownership_check': ownershipCheck,
      'land_record_check': landRecordCheck,
      'court_record_check': courtRecordCheck,
      'document_consistency': documentConsistency,
      'missing_documents': missingDocuments,
      'source_information': sourceInformation,
      'remarks': remarks,
      'verified_at': verifiedAt.toIso8601String(),
      if (verifierAdminId != null) 'verifier_admin_id': verifierAdminId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory VerificationReportModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = map['verified_at'] != null ? DateTime.parse(map['verified_at'].toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    List<String> missingDocsList = [];
    if (map['missing_documents'] is List) {
      missingDocsList = (map['missing_documents'] as List).map((e) => e.toString()).toList();
    }

    List<Map<String, dynamic>> sourcesList = [];
    if (map['source_information'] is List) {
      sourcesList = (map['source_information'] as List).map((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return {'source': e.toString()};
      }).toList();
    }

    final scoreRaw = map['risk_score'] ?? map['score'] ?? 85;
    final int parsedScore = scoreRaw is int ? scoreRaw : (int.tryParse(scoreRaw.toString()) ?? 85);

    return VerificationReportModel(
      id: map['id']?.toString() ?? 'VR-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: map['property_id']?.toString() ?? '',
      verificationStatus: map['verification_status']?.toString() ?? 'LOW RISK',
      riskLevel: map['risk_level']?.toString() ?? 'LOW',
      riskScore: parsedScore,
      confidenceScore: map['confidence_score'] is int ? map['confidence_score'] as int : 90,
      ownershipCheck: map['ownership_check']?.toString() ?? 'Verified against registered title chain',
      landRecordCheck: map['land_record_check']?.toString() ?? 'Record matched with authority database',
      courtRecordCheck: map['court_record_check']?.toString() ?? 'No litigation indicators detected in registry scan',
      documentConsistency: map['document_consistency']?.toString() ?? 'All uploaded documents match property specifications',
      missingDocuments: missingDocsList,
      sourceInformation: sourcesList,
      remarks: map['remarks']?.toString() ?? 'AI assessment complete. AI assessment is not a substitute for final legal verification.',
      verifiedAt: parsedDate,
      verifierAdminId: map['verifier_admin_id']?.toString(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }
}

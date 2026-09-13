/// Status of consistency cross-check
enum VerificationStatus {
  consistent, // Green
  needsReview, // Yellow
  mismatch, // Red
  sourceUnavailable, // Gray / Unavailable
  pending // Slate
}

extension VerificationStatusExt on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.consistent:
        return 'Information appears consistent';
      case VerificationStatus.needsReview:
        return 'Manual review recommended';
      case VerificationStatus.mismatch:
        return 'Important mismatch detected';
      case VerificationStatus.sourceUnavailable:
        return 'Official verification source unavailable';
      case VerificationStatus.pending:
        return 'Verification Pending';
    }
  }

  String get code {
    switch (this) {
      case VerificationStatus.consistent:
        return 'consistent';
      case VerificationStatus.needsReview:
        return 'needs_review';
      case VerificationStatus.mismatch:
        return 'mismatch';
      case VerificationStatus.sourceUnavailable:
        return 'source_unavailable';
      case VerificationStatus.pending:
        return 'pending';
    }
  }

  static VerificationStatus fromString(String? val) {
    if (val == null) return VerificationStatus.pending;
    final lower = val.toLowerCase().trim();
    if (lower.contains('mismatch') || lower.contains('fail') || lower == 'red') {
      return VerificationStatus.mismatch;
    }
    if (lower.contains('review') || lower == 'yellow') {
      return VerificationStatus.needsReview;
    }
    if (lower.contains('consistent') || lower == 'match' || lower.contains('matched') || lower == 'green') {
      return VerificationStatus.consistent;
    }
    if (lower.contains('unavailable')) {
      return VerificationStatus.sourceUnavailable;
    }
    return VerificationStatus.pending;
  }
}

/// Model for uploaded property document
class PropertyDocumentModel {
  final String id;
  final String propertyId;
  final String? userId;
  final String? dealerId;
  final String documentType; // Sale Deed, Registry, RERA Certificate, etc.
  final String fileName;
  final String? fileUrl;
  final int fileSizeBytes;
  final String mimeType;
  final int pageCount;
  final bool isCompleteUpload;
  final VerificationStatus verificationStatus;
  final String statusReason;
  final String uploadedAt;
  final Map<String, dynamic> metadata;

  const PropertyDocumentModel({
    required this.id,
    required this.propertyId,
    this.userId,
    this.dealerId,
    required this.documentType,
    required this.fileName,
    this.fileUrl,
    this.fileSizeBytes = 0,
    this.mimeType = 'application/pdf',
    this.pageCount = 1,
    this.isCompleteUpload = true,
    this.verificationStatus = VerificationStatus.pending,
    this.statusReason = '',
    required this.uploadedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'dealer_id': dealerId,
      'document_type': documentType,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'page_count': pageCount,
      'is_complete_upload': isCompleteUpload,
      'verification_status': verificationStatus.code,
      'status_reason': statusReason,
      'uploaded_at': uploadedAt,
      'metadata': metadata,
    };
  }

  factory PropertyDocumentModel.fromMap(Map<String, dynamic> map) {
    return PropertyDocumentModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      dealerId: map['dealer_id']?.toString(),
      documentType: map['document_type']?.toString() ?? 'Other',
      fileName: map['file_name']?.toString() ?? 'document.pdf',
      fileUrl: map['file_url']?.toString(),
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type']?.toString() ?? 'application/pdf',
      pageCount: (map['page_count'] as num?)?.toInt() ?? 1,
      isCompleteUpload: map['is_complete_upload'] == true,
      verificationStatus: VerificationStatusExt.fromString(map['verification_status']?.toString()),
      statusReason: map['status_reason']?.toString() ?? '',
      uploadedAt: map['uploaded_at']?.toString() ?? DateTime.now().toIso8601String(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }
}

/// Model for AI Document Analysis entity extraction
class DocumentAnalysisModel {
  final String id;
  final String documentId;
  final String propertyId;
  final String documentType;
  final Map<String, dynamic> extractedData;
  final List<String> detectedIssues;
  final bool missingPagesDetected;
  final VerificationStatus consistencyStatus;
  final String analysisSummary;
  final String createdAt;

  const DocumentAnalysisModel({
    required this.id,
    required this.documentId,
    required this.propertyId,
    required this.documentType,
    required this.extractedData,
    this.detectedIssues = const [],
    this.missingPagesDetected = false,
    required this.consistencyStatus,
    required this.analysisSummary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'property_id': propertyId,
      'document_type': documentType,
      'extracted_data': extractedData,
      'detected_issues': detectedIssues,
      'missing_pages_detected': missingPagesDetected,
      'consistency_status': consistencyStatus.code,
      'analysis_summary': analysisSummary,
      'created_at': createdAt,
    };
  }

  factory DocumentAnalysisModel.fromMap(Map<String, dynamic> map) {
    return DocumentAnalysisModel(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      documentType: map['document_type']?.toString() ?? '',
      extractedData: map['extracted_data'] is Map ? Map<String, dynamic>.from(map['extracted_data']) : {},
      detectedIssues: map['detected_issues'] is List ? List<String>.from(map['detected_issues']) : [],
      missingPagesDetected: map['missing_pages_detected'] == true,
      consistencyStatus: VerificationStatusExt.fromString(map['consistency_status']?.toString()),
      analysisSummary: map['analysis_summary']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Model for field-level verification comparison checks
class VerificationCheckModel {
  final String id;
  final String propertyId;
  final String checkType;
  final String fieldName;
  final String sourceType;
  final String claimValue;
  final String sourceValue;
  final String status; // MATCH, REVIEW_REQUIRED, MISMATCH, SOURCE_UNAVAILABLE
  final String statusReason;
  final String? evidenceReference;
  final bool isOfficialSource;
  final String verifiedAt;
  final Map<String, dynamic> metadata;

  const VerificationCheckModel({
    required this.id,
    required this.propertyId,
    required this.checkType,
    required this.fieldName,
    required this.sourceType,
    required this.claimValue,
    required this.sourceValue,
    required this.status,
    required this.statusReason,
    this.evidenceReference,
    this.isOfficialSource = false,
    required this.verifiedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'check_type': checkType,
      'field_name': fieldName,
      'source_type': sourceType,
      'claim_value': claimValue,
      'source_value': sourceValue,
      'status': status,
      'status_reason': statusReason,
      'evidence_reference': evidenceReference,
      'is_official_source': isOfficialSource,
      'verified_at': verifiedAt,
      'metadata': metadata,
    };
  }

  factory VerificationCheckModel.fromMap(Map<String, dynamic> map) {
    return VerificationCheckModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      checkType: map['check_type']?.toString() ?? '',
      fieldName: map['field_name']?.toString() ?? '',
      sourceType: map['source_type']?.toString() ?? '',
      claimValue: map['claim_value']?.toString() ?? '',
      sourceValue: map['source_value']?.toString() ?? '',
      status: map['status']?.toString() ?? 'REVIEW_REQUIRED',
      statusReason: map['status_reason']?.toString() ?? '',
      evidenceReference: map['evidence_reference']?.toString(),
      isOfficialSource: map['is_official_source'] == true,
      verifiedAt: map['verified_at']?.toString() ?? DateTime.now().toIso8601String(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }
}

/// Model for Property History Event in Timeline
class PropertyHistoryEventModel {
  final String id;
  final String propertyId;
  final String eventDate;
  final String eventType;
  final String description;
  final String sourceName;
  final String? sourceUrl;
  final String verificationStatus;
  final String createdAt;

  const PropertyHistoryEventModel({
    required this.id,
    required this.propertyId,
    required this.eventDate,
    required this.eventType,
    required this.description,
    required this.sourceName,
    this.sourceUrl,
    this.verificationStatus = 'VERIFIED',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'event_date': eventDate,
      'event_type': eventType,
      'description': description,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'verification_status': verificationStatus,
      'created_at': createdAt,
    };
  }

  factory PropertyHistoryEventModel.fromMap(Map<String, dynamic> map) {
    return PropertyHistoryEventModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      eventDate: map['event_date']?.toString() ?? '',
      eventType: map['event_type']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      sourceName: map['source_name']?.toString() ?? '',
      sourceUrl: map['source_url']?.toString(),
      verificationStatus: map['verification_status']?.toString() ?? 'VERIFIED',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Model for AI-generated Clarification Question
class VerificationQuestionModel {
  final String id;
  final String propertyId;
  final String issueDetected;
  final String affectedField;
  final String questionText;
  final String? evidenceReference;
  final String status; // Pending, Answered, Needs Review, Resolved
  final String createdAt;
  final String updatedAt;

  const VerificationQuestionModel({
    required this.id,
    required this.propertyId,
    required this.issueDetected,
    required this.affectedField,
    required this.questionText,
    this.evidenceReference,
    this.status = 'Pending',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'issue_detected': issueDetected,
      'affected_field': affectedField,
      'question_text': questionText,
      'evidence_reference': evidenceReference,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory VerificationQuestionModel.fromMap(Map<String, dynamic> map) {
    return VerificationQuestionModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      issueDetected: map['issue_detected']?.toString() ?? '',
      affectedField: map['affected_field']?.toString() ?? '',
      questionText: map['question_text']?.toString() ?? '',
      evidenceReference: map['evidence_reference']?.toString(),
      status: map['status']?.toString() ?? 'Pending',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Model for Property Cost Calculation Breakdown
class PropertyCostEstimateModel {
  final String id;
  final String propertyId;
  final double basePrice;
  final double registrationPercent;
  final double registrationCharges;
  final double stampDutyPercent;
  final double stampDutyCharges;
  final double brokeragePercent;
  final double brokerageCharges;
  final double maintenanceDeposit;
  final double renovationEstimate;
  final double legalDueDiligence;
  final double otherCharges;
  final double estimatedTotalCost;
  final String buyerCategory; // Male, Female, Joint
  final String locationJurisdiction;
  final String disclaimer;

  const PropertyCostEstimateModel({
    required this.id,
    required this.propertyId,
    required this.basePrice,
    this.registrationPercent = 1.0,
    required this.registrationCharges,
    this.stampDutyPercent = 6.0,
    required this.stampDutyCharges,
    this.brokeragePercent = 1.0,
    required this.brokerageCharges,
    this.maintenanceDeposit = 150000,
    this.renovationEstimate = 300000,
    this.legalDueDiligence = 25000,
    this.otherCharges = 50000,
    required this.estimatedTotalCost,
    this.buyerCategory = 'Male',
    this.locationJurisdiction = 'Noida / Uttar Pradesh',
    this.disclaimer = 'Estimated cost — actual charges may vary based on registrar circle rates and buyer category.',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'base_price': basePrice,
      'registration_percent': registrationPercent,
      'registration_charges': registrationCharges,
      'stamp_duty_percent': stampDutyPercent,
      'stamp_duty_charges': stampDutyCharges,
      'brokerage_percent': brokeragePercent,
      'brokerage_charges': brokerageCharges,
      'maintenance_deposit': maintenanceDeposit,
      'renovation_estimate': renovationEstimate,
      'legal_due_diligence': legalDueDiligence,
      'other_charges': otherCharges,
      'estimated_total_cost': estimatedTotalCost,
      'buyer_category': buyerCategory,
      'location_jurisdiction': locationJurisdiction,
      'disclaimer': disclaimer,
    };
  }

  factory PropertyCostEstimateModel.fromMap(Map<String, dynamic> map) {
    final base = (map['base_price'] as num?)?.toDouble() ?? 0.0;
    final regPct = (map['registration_percent'] as num?)?.toDouble() ?? 1.0;
    final stampPct = (map['stamp_duty_percent'] as num?)?.toDouble() ?? 6.0;
    final bkrPct = (map['brokerage_percent'] as num?)?.toDouble() ?? 1.0;
    final regCost = (map['registration_charges'] as num?)?.toDouble() ?? (base * (regPct / 100.0));
    final stampCost = (map['stamp_duty_charges'] as num?)?.toDouble() ?? (base * (stampPct / 100.0));
    final bkrCost = (map['brokerage_charges'] as num?)?.toDouble() ?? (base * (bkrPct / 100.0));
    final maint = (map['maintenance_deposit'] as num?)?.toDouble() ?? 150000.0;
    final reno = (map['renovation_estimate'] as num?)?.toDouble() ?? 300000.0;
    final legal = (map['legal_due_diligence'] as num?)?.toDouble() ?? 25000.0;
    final other = (map['other_charges'] as num?)?.toDouble() ?? 50000.0;
    final total = (map['estimated_total_cost'] as num?)?.toDouble() ?? (base + regCost + stampCost + bkrCost + maint + reno + legal + other);

    return PropertyCostEstimateModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      basePrice: base,
      registrationPercent: regPct,
      registrationCharges: regCost,
      stampDutyPercent: stampPct,
      stampDutyCharges: stampCost,
      brokeragePercent: bkrPct,
      brokerageCharges: bkrCost,
      maintenanceDeposit: maint,
      renovationEstimate: reno,
      legalDueDiligence: legal,
      otherCharges: other,
      estimatedTotalCost: total,
      buyerCategory: map['buyer_category']?.toString() ?? 'Male',
      locationJurisdiction: map['location_jurisdiction']?.toString() ?? 'Noida / Uttar Pradesh',
      disclaimer: map['disclaimer']?.toString() ?? 'Estimated cost — actual charges may vary.',
    );
  }
}

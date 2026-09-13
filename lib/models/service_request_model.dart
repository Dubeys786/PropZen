/// The 6 major service categories in PropZen
enum ServiceCategoryType {
  loan,
  homeDesign,
  vastu,
  construction,
  propertyVerification,
  visualization;

  String get displayName {
    switch (this) {
      case ServiceCategoryType.loan:
        return 'Loan / Home Finance';
      case ServiceCategoryType.homeDesign:
        return 'Home Design';
      case ServiceCategoryType.vastu:
        return 'Vastu Consultation';
      case ServiceCategoryType.construction:
        return 'Construction';
      case ServiceCategoryType.propertyVerification:
        return 'Property Verification';
      case ServiceCategoryType.visualization:
        return 'Virtual & 3D Visualization';
    }
  }

  String get code {
    switch (this) {
      case ServiceCategoryType.loan:
        return 'LOAN';
      case ServiceCategoryType.homeDesign:
        return 'HOME_DESIGN';
      case ServiceCategoryType.vastu:
        return 'VASTU';
      case ServiceCategoryType.construction:
        return 'CONSTRUCTION';
      case ServiceCategoryType.propertyVerification:
        return 'PROPERTY_VERIFICATION';
      case ServiceCategoryType.visualization:
        return 'VIRTUAL_3D';
    }
  }

  List<String> get specializedSubServices {
    switch (this) {
      case ServiceCategoryType.homeDesign:
        return const [
          'INTERIOR DESIGN',
          'EXTERIOR DESIGN',
          '2D DESIGN',
          '3D DESIGN',
          'FLOOR PLAN',
          'FURNITURE / LAYOUT PLANNING',
          'DESIGN CONSULTATION',
          'DESIGN APPROVAL',
          'FINAL DESIGN DELIVERY',
        ];
      case ServiceCategoryType.loan:
        return const [
          'Home Loan Eligibility',
          'Document Collection',
          'Loan Application Filing',
          'Bank Underwriting & Review',
          'Sanction & Approval Status',
          'Disbursement Verification',
          'Balance Transfer & Top-Up',
        ];
      case ServiceCategoryType.vastu:
        return const [
          'Vastu Consultation',
          'Property & Site Analysis',
          'Floor Plan Analysis',
          'Vastu Recommendations',
          'Vastu Energy Reports',
          'Consultation Remediation',
        ];
      case ServiceCategoryType.construction:
        return const [
          'Turnkey Construction',
          'Site Assessment & Survey',
          'Detailed Cost Estimate',
          'Material Planning',
          'Contractor/Team Assignment',
          'Construction Schedule & Milestones',
          'Site Progress Monitoring',
          'Final Quality Inspection',
        ];
      case ServiceCategoryType.propertyVerification:
        return const [
          'Property Details Verification',
          'Document Review',
          'RERA Verification',
          'Ownership Title Verification',
          'Legal Due Diligence',
          'Location & Physical Verification',
          'Comprehensive Verification Report',
        ];
      case ServiceCategoryType.visualization:
        return const [
          'Virtual Tours & 360 Walkthrough',
          '3D Architectural Visualization',
          'Drone Video & Aerial Mapping',
          'AR & Plot Visualization',
          'Project Deliverables Package',
        ];
    }
  }

  static ServiceCategoryType fromCode(String code) {
    final lower = code.trim().toLowerCase();
    if (lower.contains('loan') || lower.contains('finance')) return ServiceCategoryType.loan;
    if (lower.contains('design') || lower.contains('interior')) return ServiceCategoryType.homeDesign;
    if (lower.contains('vastu')) return ServiceCategoryType.vastu;
    if (lower.contains('construction') || lower.contains('build')) return ServiceCategoryType.construction;
    if (lower.contains('verification') || lower.contains('legal') || lower.contains('rera')) return ServiceCategoryType.propertyVerification;
    if (lower.contains('visual') || lower.contains('tour') || lower.contains('3d') || lower.contains('drone') || lower.contains('ar') || lower.contains('virtual')) return ServiceCategoryType.visualization;
    return ServiceCategoryType.loan;
  }
}

/// Specialized Journey Stage for role-tailored workflows
class SpecializedJourneyStage {
  final String key;
  final String label;
  final String description;
  final int stepIndex;

  const SpecializedJourneyStage({
    required this.key,
    required this.label,
    required this.description,
    required this.stepIndex,
  });

  String get name => label;
}

/// Helper to get specialization-specific journey stages
class SpecializedJourneyHelper {
  static List<SpecializedJourneyStage> getStagesForCategory(ServiceCategoryType category) {
    switch (category) {
      case ServiceCategoryType.loan:
        return const [
          SpecializedJourneyStage(key: 'NEW_REQUEST', label: 'New Request', description: 'New loan application submitted', stepIndex: 1),
          SpecializedJourneyStage(key: 'CUSTOMER_VERIFICATION', label: 'Customer Verification', description: 'Borrower KYC & contact details verified', stepIndex: 2),
          SpecializedJourneyStage(key: 'ELIGIBILITY_CHECK', label: 'Eligibility Check', description: 'Income, credit score & FOIR calculation', stepIndex: 3),
          SpecializedJourneyStage(key: 'DOCUMENT_COLLECTION', label: 'Document Collection', description: 'ITR, salary slips & property title documents', stepIndex: 4),
          SpecializedJourneyStage(key: 'APPLICATION_SUBMITTED', label: 'Application Submitted', description: 'Formal loan file submitted to partner banks', stepIndex: 5),
          SpecializedJourneyStage(key: 'BANK_REVIEW', label: 'Bank Review', description: 'Legal and technical evaluation by underwriting team', stepIndex: 6),
          SpecializedJourneyStage(key: 'SANCTION', label: 'Sanction', description: 'Sanction letter issued with interest & tenure', stepIndex: 7),
          SpecializedJourneyStage(key: 'AGREEMENT', label: 'Agreement', description: 'Loan agreement and stamp duty signed by borrower', stepIndex: 8),
          SpecializedJourneyStage(key: 'DISBURSEMENT', label: 'Disbursement', description: 'Loan amount credited to builder/seller account', stepIndex: 9),
          SpecializedJourneyStage(key: 'COMPLETED', label: 'Completed', description: 'Loan case successfully closed', stepIndex: 10),
          SpecializedJourneyStage(key: 'CUSTOMER_FEEDBACK', label: 'Customer Feedback', description: 'Customer feedback and rating recorded', stepIndex: 11),
        ];

      case ServiceCategoryType.homeDesign:
        return const [
          SpecializedJourneyStage(key: 'REQUEST_RECEIVED', label: 'Request Received', description: 'Design request received from client', stepIndex: 1),
          SpecializedJourneyStage(key: 'CUSTOMER_DETAILS', label: 'Customer Details', description: 'Client contact and design preferences verified', stepIndex: 2),
          SpecializedJourneyStage(key: 'REQUIREMENT_COLLECTION', label: 'Requirement Collection', description: 'Space dimensions & styling specs collected', stepIndex: 3),
          SpecializedJourneyStage(key: 'SITE_PROPERTY_DETAILS', label: 'Site/Property Details', description: 'Floor plans & architectural drawings gathered', stepIndex: 4),
          SpecializedJourneyStage(key: 'MEASUREMENT_PLAN', label: 'Measurement/Plan', description: 'Physical / laser measurements & area zoning', stepIndex: 5),
          SpecializedJourneyStage(key: 'CONCEPT_DESIGN', label: 'Concept Design', description: 'Moodboards, material palettes & concept themes', stepIndex: 6),
          SpecializedJourneyStage(key: '2D_DESIGN', label: '2D Design', description: '2D CAD layout and space planning completed', stepIndex: 7),
          SpecializedJourneyStage(key: '3D_DESIGN', label: '3D Design', description: 'Photorealistic 3D render generated', stepIndex: 8),
          SpecializedJourneyStage(key: 'CUSTOMER_REVIEW', label: 'Customer Review', description: 'Designs submitted to customer for review', stepIndex: 9),
          SpecializedJourneyStage(key: 'REVISION', label: 'Revision', description: 'Iterating on customer feedback & refinements', stepIndex: 10),
          SpecializedJourneyStage(key: 'FINAL_APPROVAL', label: 'Final Approval', description: 'Client sign-off on design specs & BOQ', stepIndex: 11),
          SpecializedJourneyStage(key: 'FINAL_DELIVERY', label: 'Final Delivery', description: 'High-res blueprints, renders, & deliverables handed over', stepIndex: 12),
          SpecializedJourneyStage(key: 'COMPLETED', label: 'Completed', description: 'Design project successfully completed', stepIndex: 13),
          SpecializedJourneyStage(key: 'FEEDBACK', label: 'Feedback', description: 'Client rating and review recorded', stepIndex: 14),
        ];

      case ServiceCategoryType.vastu:
        return const [
          SpecializedJourneyStage(key: 'REQUEST_RECEIVED', label: 'Request Received', description: 'Vastu consultation request received', stepIndex: 1),
          SpecializedJourneyStage(key: 'CUSTOMER_DETAILS', label: 'Customer Details', description: 'Owner details & orientation preferences noted', stepIndex: 2),
          SpecializedJourneyStage(key: 'PROPERTY_DETAILS', label: 'Property Details', description: 'Geomagnetic plot orientation and layout map', stepIndex: 3),
          SpecializedJourneyStage(key: 'FLOOR_PLAN', label: 'Floor Plan', description: 'Zonal division and 16-zone mapping', stepIndex: 4),
          SpecializedJourneyStage(key: 'ANALYSIS', label: 'Analysis', description: 'Five-element elemental energy analysis', stepIndex: 5),
          SpecializedJourneyStage(key: 'RECOMMENDATIONS', label: 'Recommendations', description: 'Non-demolition remedies & zonal color cures', stepIndex: 6),
          SpecializedJourneyStage(key: 'CONSULTATION', label: 'Consultation', description: 'Detailed consultation session with Shastri', stepIndex: 7),
          SpecializedJourneyStage(key: 'REPORT_PREPARATION', label: 'Report Preparation', description: 'Comprehensive Vastu audit dossier created', stepIndex: 8),
          SpecializedJourneyStage(key: 'CUSTOMER_REVIEW', label: 'Customer Review', description: 'Customer reviews audit findings', stepIndex: 9),
          SpecializedJourneyStage(key: 'FINAL_REPORT', label: 'Final Report', description: 'Certified Vastu report delivered to customer', stepIndex: 10),
          SpecializedJourneyStage(key: 'COMPLETED', label: 'Completed', description: 'Consultation closed successfully', stepIndex: 11),
          SpecializedJourneyStage(key: 'FEEDBACK', label: 'Feedback', description: 'Client rating and satisfaction survey recorded', stepIndex: 12),
        ];

      case ServiceCategoryType.construction:
        return const [
          SpecializedJourneyStage(key: 'REQUEST_RECEIVED', label: 'Request Received', description: 'Construction project request placed', stepIndex: 1),
          SpecializedJourneyStage(key: 'CUSTOMER_VERIFICATION', label: 'Customer Verification', description: 'Client credentials & site possession verified', stepIndex: 2),
          SpecializedJourneyStage(key: 'SITE_ASSESSMENT', label: 'Site Assessment', description: 'Topography, soil test & access survey', stepIndex: 3),
          SpecializedJourneyStage(key: 'ESTIMATE', label: 'Estimate', description: 'Detailed BOQ and civil estimate finalized', stepIndex: 4),
          SpecializedJourneyStage(key: 'QUOTATION', label: 'Quotation', description: 'Formal commercial quotation submitted', stepIndex: 5),
          SpecializedJourneyStage(key: 'AGREEMENT', label: 'Agreement', description: 'Turnkey contract signed and token advance received', stepIndex: 6),
          SpecializedJourneyStage(key: 'PROJECT_STARTED', label: 'Project Started', description: 'Site mobilization and excavation commenced', stepIndex: 7),
          SpecializedJourneyStage(key: 'FOUNDATION', label: 'Foundation', description: 'Excavation, PCC & footings completed', stepIndex: 8),
          SpecializedJourneyStage(key: 'STRUCTURE', label: 'Structure', description: 'RCC columns, beams and slab casting', stepIndex: 9),
          SpecializedJourneyStage(key: 'BRICKWORK', label: 'Brickwork', description: 'Masonry walls and plastering completed', stepIndex: 10),
          SpecializedJourneyStage(key: 'ELECTRICAL_PLUMBING', label: 'Electrical/Plumbing', description: 'Concealed conduits, piping and sanitation lines', stepIndex: 11),
          SpecializedJourneyStage(key: 'FINISHING', label: 'Finishing', description: 'Flooring, tiling, painting and fixture fittings', stepIndex: 12),
          SpecializedJourneyStage(key: 'INSPECTION', label: 'Inspection', description: 'Quality inspection & structural audit', stepIndex: 13),
          SpecializedJourneyStage(key: 'HANDOVER', label: 'Handover', description: 'Possession keys & snag list sign-off handed over', stepIndex: 14),
          SpecializedJourneyStage(key: 'COMPLETED', label: 'Completed', description: 'Construction successfully delivered', stepIndex: 15),
          SpecializedJourneyStage(key: 'FEEDBACK', label: 'Feedback', description: 'Client feedback and testimonial recorded', stepIndex: 16),
        ];

      case ServiceCategoryType.propertyVerification:
        return const [
          SpecializedJourneyStage(key: 'REQUEST_RECEIVED', label: 'Request Received', description: 'Verification audit request received', stepIndex: 1),
          SpecializedJourneyStage(key: 'DOCUMENTS_COLLECTED', label: 'Documents Collected', description: 'Title deeds, encumbrance certs & mutation papers', stepIndex: 2),
          SpecializedJourneyStage(key: 'DOCUMENT_REVIEW', label: 'Document Review', description: 'Initial review of deed chain and authority stamps', stepIndex: 3),
          SpecializedJourneyStage(key: 'OWNERSHIP_CHECK', label: 'Ownership Check', description: '30-year sub-registrar title ownership chain checked', stepIndex: 4),
          SpecializedJourneyStage(key: 'RERA_CHECK', label: 'RERA Check', description: 'RERA registration, quarterly filings & complaints check', stepIndex: 5),
          SpecializedJourneyStage(key: 'REGISTRY_CHECK', label: 'Registry Check', description: 'Official registry record matching at Tehsil office', stepIndex: 6),
          SpecializedJourneyStage(key: 'LEGAL_REVIEW', label: 'Legal Review', description: 'High Court, civil court & tribunal dispute search', stepIndex: 7),
          SpecializedJourneyStage(key: 'LOCATION_CHECK', label: 'Location Check', description: 'Physical boundary demarcation & site inspection', stepIndex: 8),
          SpecializedJourneyStage(key: 'RISK_ASSESSMENT', label: 'Risk Assessment', description: 'Legal encumbrance & fraud risk scoring', stepIndex: 9),
          SpecializedJourneyStage(key: 'VERIFICATION_REPORT', label: 'Verification Report', description: 'Comprehensive legal clearance report generated', stepIndex: 10),
          SpecializedJourneyStage(key: 'CUSTOMER_DELIVERY', label: 'Customer Delivery', description: 'Report delivered to customer with attorney debrief', stepIndex: 11),
          SpecializedJourneyStage(key: 'COMPLETED', label: 'Completed', description: 'Verification successfully closed', stepIndex: 12),
          SpecializedJourneyStage(key: 'FEEDBACK', label: 'Feedback', description: 'Client rating and feedback collected', stepIndex: 13),
        ];

      case ServiceCategoryType.visualization:
        return const [
          SpecializedJourneyStage(key: 'REQUEST_RECEIVED', label: 'Request Received', description: 'Virtual / 3D visualization request received', stepIndex: 1),
          SpecializedJourneyStage(key: 'PROPERTY_DETAILS', label: 'Property Details', description: 'CAD plans, elevations and site dimensions gathered', stepIndex: 2),
          SpecializedJourneyStage(key: 'MEDIA_COLLECTION', label: 'Media Collection', description: 'High-res site photography & raw asset intake', stepIndex: 3),
          SpecializedJourneyStage(key: '3D_MODEL_CREATION', label: '3D Model Creation', description: 'High-fidelity 3D modeling & texture baking', stepIndex: 4),
          SpecializedJourneyStage(key: 'VIRTUAL_TOUR', label: 'Virtual Tour', description: 'Interactive Matterport / WebXR tour built', stepIndex: 5),
          SpecializedJourneyStage(key: '360_TOUR', label: '360° Tour', description: '360-degree panoramic interactive walkthrough', stepIndex: 6),
          SpecializedJourneyStage(key: 'DRONE_AR_PROCESSING', label: 'Drone/AR Processing', description: '4K aerial drone mapping & AR USDZ/GLB asset creation', stepIndex: 7),
          SpecializedJourneyStage(key: 'CUSTOMER_REVIEW', label: 'Customer Review', description: 'Interactive media links shared for client review', stepIndex: 8),
          SpecializedJourneyStage(key: 'REVISION', label: 'Revision', description: 'Lighting, angle and camera path revisions', stepIndex: 9),
          SpecializedJourneyStage(key: 'FINAL_DELIVERY', label: 'Final Delivery', description: 'High-res renders, embed codes & AR assets delivered', stepIndex: 10),
          SpecializedJourneyStage(key: 'COMPLETED', label: 'Completed', description: '3D visualization package completed', stepIndex: 11),
          SpecializedJourneyStage(key: 'FEEDBACK', label: 'Feedback', description: 'Customer feedback and rating recorded', stepIndex: 12),
        ];
    }
  }
}

/// 8-stage Complete Service Journey lifecycle
enum ServiceStatus {
  requested,
  accepted,
  documentsRequired,
  inProgress,
  awaitingCustomer,
  approvalPending,
  completed,
  closed;

  String get label {
    switch (this) {
      case ServiceStatus.requested:
        return 'REQUESTED';
      case ServiceStatus.accepted:
        return 'ACCEPTED';
      case ServiceStatus.documentsRequired:
        return 'DOCUMENTS_REQUIRED';
      case ServiceStatus.inProgress:
        return 'IN_PROGRESS';
      case ServiceStatus.awaitingCustomer:
        return 'AWAITING_CUSTOMER';
      case ServiceStatus.approvalPending:
        return 'APPROVAL_PENDING';
      case ServiceStatus.completed:
        return 'COMPLETED';
      case ServiceStatus.closed:
        return 'CLOSED';
    }
  }

  String get displayLabel {
    switch (this) {
      case ServiceStatus.requested:
        return 'Requested';
      case ServiceStatus.accepted:
        return 'Accepted';
      case ServiceStatus.documentsRequired:
        return 'Documents Required';
      case ServiceStatus.inProgress:
        return 'In Progress';
      case ServiceStatus.awaitingCustomer:
        return 'Awaiting Customer Action';
      case ServiceStatus.approvalPending:
        return 'Approval Pending';
      case ServiceStatus.completed:
        return 'Completed';
      case ServiceStatus.closed:
        return 'Closed';
    }
  }

  static ServiceStatus fromString(String val) {
    final clean = val.trim().toUpperCase();
    for (final s in ServiceStatus.values) {
      if (s.label == clean) return s;
    }
    if (clean.contains('ACCEPT')) return ServiceStatus.accepted;
    if (clean.contains('DOC')) return ServiceStatus.documentsRequired;
    if (clean.contains('PROGRESS')) return ServiceStatus.inProgress;
    if (clean.contains('AWAIT') || clean.contains('CUSTOMER')) return ServiceStatus.awaitingCustomer;
    if (clean.contains('APPROVAL')) return ServiceStatus.approvalPending;
    if (clean.contains('COMPLETE')) return ServiceStatus.completed;
    if (clean.contains('CLOSE') || clean.contains('REJECT')) return ServiceStatus.closed;
    return ServiceStatus.requested;
  }
}

/// A milestone inside an active service
class ServiceMilestone {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;
  final double amount;
  final int orderIndex;

  const ServiceMilestone({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.completedAt,
    this.amount = 0.0,
    this.orderIndex = 0,
  });

  ServiceMilestone copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    double? amount,
    int? orderIndex,
  }) {
    return ServiceMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      amount: amount ?? this.amount,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
    'amount': amount,
    'order_index': orderIndex,
  };

  factory ServiceMilestone.fromJson(Map<String, dynamic> json) {
    return ServiceMilestone(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Milestone',
      description: json['description']?.toString() ?? '',
      isCompleted: json['is_completed'] == true,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A document attached to a service request
class ServiceDocument {
  final String id;
  final String title;
  final String fileName;
  final String fileUrl;
  final String fileType; // PDF, JPG, PNG, CAD
  final DateTime uploadedAt;
  final String uploadedBy; // 'BUYER' or 'SERVICE_PARTNER'
  final bool isVerified;

  const ServiceDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.fileUrl,
    this.fileType = 'PDF',
    required this.uploadedAt,
    this.uploadedBy = 'BUYER',
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'file_name': fileName,
    'file_url': fileUrl,
    'file_type': fileType,
    'uploaded_at': uploadedAt.toIso8601String(),
    'uploaded_by': uploadedBy,
    'is_verified': isVerified,
  };

  factory ServiceDocument.fromJson(Map<String, dynamic> json) {
    return ServiceDocument(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Document',
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'PDF',
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'].toString()) ?? DateTime.now() : DateTime.now(),
      uploadedBy: json['uploaded_by']?.toString() ?? 'BUYER',
      isVerified: json['is_verified'] == true,
    );
  }
}

/// Feedback and rating submitted for a completed service
class ServiceFeedback {
  final int rating; // 1 to 5
  final String comment;
  final DateTime submittedAt;
  final String buyerName;

  const ServiceFeedback({
    required this.rating,
    required this.comment,
    required this.submittedAt,
    this.buyerName = 'Verified Buyer',
  });

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'submitted_at': submittedAt.toIso8601String(),
    'buyer_name': buyerName,
  };

  factory ServiceFeedback.fromJson(Map<String, dynamic> json) {
    return ServiceFeedback(
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now() : DateTime.now(),
      buyerName: json['buyer_name']?.toString() ?? 'Verified Buyer',
    );
  }
}

/// Comprehensive Service Request Model
class ServiceRequest {
  final String id;
  final String serviceNumber; // e.g. SR-89021
  final ServiceCategoryType category;
  final String subCategory; // e.g. "Home Loan Eligibility", "3D Interior Design", "Vastu Plot Analysis"
  final String title;
  final String description;

  // Property Context
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyAddress;
  final double? propertyPriceCr;

  // Customer / Buyer Details
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  // Service Partner Details
  final String? partnerId;
  final String? partnerName;
  final String? partnerCompany;

  // Status & Timestamps
  final ServiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Commercials & Progress
  final double estimatedPrice;
  final double paidAmount;
  final List<ServiceMilestone> milestones;
  final List<ServiceDocument> documents;
  final ServiceFeedback? feedback;
  final List<String> requiredDocumentsList;

  const ServiceRequest({
    required this.id,
    required this.serviceNumber,
    required this.category,
    required this.subCategory,
    required this.title,
    required this.description,
    this.propertyId,
    this.propertyTitle,
    this.propertyAddress,
    this.propertyPriceCr,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.partnerId,
    this.partnerName,
    this.partnerCompany,
    this.status = ServiceStatus.requested,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedPrice = 0.0,
    this.paidAmount = 0.0,
    this.milestones = const [],
    this.documents = const [],
    this.feedback,
    this.requiredDocumentsList = const [],
  });

  bool get isAssigned => partnerId != null && partnerId!.isNotEmpty;
  bool get isCompleted => status == ServiceStatus.completed;
  bool get isClosed => status == ServiceStatus.closed;
  bool get isActive => !isCompleted && !isClosed;

  int get completedMilestonesCount => milestones.where((m) => m.isCompleted).length;
  double get progressPercentage => milestones.isEmpty ? (isCompleted ? 1.0 : (status == ServiceStatus.inProgress ? 0.5 : 0.1)) : (completedMilestonesCount / milestones.length);

  String get currentStage {
    final pending = milestones.where((m) => !m.isCompleted).toList();
    if (pending.isNotEmpty) {
      return pending.first.title;
    }
    return status.displayLabel;
  }

  ServiceRequest copyWith({
    String? id,
    String? serviceNumber,
    ServiceCategoryType? category,
    String? subCategory,
    String? title,
    String? description,
    String? propertyId,
    String? propertyTitle,
    String? propertyAddress,
    double? propertyPriceCr,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? partnerId,
    String? partnerName,
    String? partnerCompany,
    ServiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? estimatedPrice,
    double? paidAmount,
    List<ServiceMilestone>? milestones,
    List<ServiceDocument>? documents,
    ServiceFeedback? feedback,
    List<String>? requiredDocumentsList,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      serviceNumber: serviceNumber ?? this.serviceNumber,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyPriceCr: propertyPriceCr ?? this.propertyPriceCr,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerCompany: partnerCompany ?? this.partnerCompany,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      paidAmount: paidAmount ?? this.paidAmount,
      milestones: milestones ?? this.milestones,
      documents: documents ?? this.documents,
      feedback: feedback ?? this.feedback,
      requiredDocumentsList: requiredDocumentsList ?? this.requiredDocumentsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_number': serviceNumber,
    'category': category.code,
    'service_type': category.code,
    'sub_category': subCategory,
    'title': title,
    'description': description,
    'property_id': propertyId,
    'property_title': propertyTitle,
    'property_address': propertyAddress,
    'property_price_cr': propertyPriceCr,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'customer_email': customerEmail,
    'partner_id': partnerId,
    'service_partner_id': partnerId,
    'partner_name': partnerName,
    'partner_company': partnerCompany,
    'status': status.label,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'estimated_price': estimatedPrice,
    'paid_amount': paidAmount,
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'documents': documents.map((d) => d.toJson()).toList(),
    'feedback': feedback?.toJson(),
    'required_documents': requiredDocumentsList,
  };

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final catCode = (json['service_type'] ?? json['category'] ?? 'LOAN').toString();
    final pId = (json['service_partner_id'] ?? json['partner_id'])?.toString();

    return ServiceRequest(
      id: json['id']?.toString() ?? '',
      serviceNumber: json['service_number']?.toString() ?? 'SR-000',
      category: ServiceCategoryType.fromCode(catCode),
      subCategory: json['sub_category']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Service Request',
      description: json['description']?.toString() ?? '',
      propertyId: json['property_id']?.toString(),
      propertyTitle: json['property_title']?.toString(),
      propertyAddress: json['property_address']?.toString(),
      propertyPriceCr: (json['property_price_cr'] as num?)?.toDouble(),
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Buyer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      partnerId: pId,
      partnerName: json['partner_name']?.toString(),
      partnerCompany: json['partner_company']?.toString(),
      status: ServiceStatus.fromString(json['status']?.toString() ?? 'REQUESTED'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      milestones: (json['milestones'] as List?)?.map((m) => ServiceMilestone.fromJson(Map<String, dynamic>.from(m as Map))).toList() ?? [],
      documents: (json['documents'] as List?)?.map((d) => ServiceDocument.fromJson(Map<String, dynamic>.from(d as Map))).toList() ?? [],
      feedback: json['feedback'] != null ? ServiceFeedback.fromJson(Map<String, dynamic>.from(json['feedback'] as Map)) : null,
      requiredDocumentsList: (json['required_documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

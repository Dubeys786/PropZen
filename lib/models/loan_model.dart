import 'dart:math';

enum LoanStatus {
  newRequest,
  documentsPending,
  underReview,
  manualProcessing,
  offerAvailable,
  customerReview,
  approved,
  rejected,
  closed;

  String get dbValue {
    switch (this) {
      case LoanStatus.newRequest:
        return 'NEW';
      case LoanStatus.documentsPending:
        return 'DOCUMENTS_PENDING';
      case LoanStatus.underReview:
        return 'UNDER_REVIEW';
      case LoanStatus.manualProcessing:
        return 'MANUAL_PROCESSING';
      case LoanStatus.offerAvailable:
        return 'OFFER_AVAILABLE';
      case LoanStatus.customerReview:
        return 'CUSTOMER_REVIEW';
      case LoanStatus.approved:
        return 'APPROVED';
      case LoanStatus.rejected:
        return 'REJECTED';
      case LoanStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case LoanStatus.newRequest:
        return 'New Application';
      case LoanStatus.documentsPending:
        return 'Documents Pending';
      case LoanStatus.underReview:
        return 'Under Review';
      case LoanStatus.manualProcessing:
        return 'Lender Comparison in Progress';
      case LoanStatus.offerAvailable:
        return 'Offer Available';
      case LoanStatus.customerReview:
        return 'Customer Review';
      case LoanStatus.approved:
        return 'Sanction Approved';
      case LoanStatus.rejected:
        return 'Declined';
      case LoanStatus.closed:
        return 'Disbursed / Closed';
    }
  }

  static LoanStatus fromString(String val) {
    final clean = val.toUpperCase().replaceAll(' ', '_');
    for (final s in LoanStatus.values) {
      if (s.dbValue == clean || s.name == val) return s;
    }
    return LoanStatus.newRequest;
  }
}

class LoanRequestModel {
  final String id;
  final String userId;
  final String? propertyId;
  final String propertyTitle;
  final double propertyPrice;
  final double downPayment;
  final double loanAmount;
  final String propertyType;
  final String propertyLocation;
  final String name;
  final String phone;
  final String email;
  final String city;
  final String employmentType; // Salaried / Self-Employed
  final double monthlyIncome;
  final double existingEmi;
  final int preferredTenureYears;
  final String? preferredLender;
  final double indicativeEligibility;
  final LoanStatus status;
  final String? adminRemarks;
  final List<LoanDocumentModel> documents;
  final List<LoanOfferModel> offers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoanRequestModel({
    required this.id,
    required this.userId,
    this.propertyId,
    required this.propertyTitle,
    required this.propertyPrice,
    required this.downPayment,
    required this.loanAmount,
    this.propertyType = 'Apartment',
    this.propertyLocation = 'Noida / NCR',
    required this.name,
    required this.phone,
    required this.email,
    this.city = 'Noida',
    this.employmentType = 'Salaried',
    required this.monthlyIncome,
    this.existingEmi = 0,
    this.preferredTenureYears = 20,
    this.preferredLender,
    required this.indicativeEligibility,
    this.status = LoanStatus.newRequest,
    this.adminRemarks,
    this.documents = const [],
    this.offers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'property_id': propertyId,
      'property_title': propertyTitle,
      'property_price': propertyPrice,
      'down_payment': downPayment,
      'loan_amount': loanAmount,
      'property_type': propertyType,
      'property_location': propertyLocation,
      'name': name,
      'phone': phone,
      'email': email,
      'city': city,
      'employment_type': employmentType,
      'monthly_income': monthlyIncome,
      'existing_emi': existingEmi,
      'preferred_tenure_years': preferredTenureYears,
      'preferred_lender': preferredLender,
      'indicative_eligibility': indicativeEligibility,
      'status': status.dbValue,
      'admin_remarks': adminRemarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LoanRequestModel.fromMap(Map<String, dynamic> map) {
    return LoanRequestModel(
      id: map['id']?.toString() ?? 'LOAN-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString() ?? '',
      propertyId: map['property_id']?.toString(),
      propertyTitle: map['property_title']?.toString() ?? 'PropZen Verified Property',
      propertyPrice: (map['property_price'] as num?)?.toDouble() ?? 0.0,
      downPayment: (map['down_payment'] as num?)?.toDouble() ?? 0.0,
      loanAmount: (map['loan_amount'] as num?)?.toDouble() ?? 0.0,
      propertyType: map['property_type']?.toString() ?? 'Apartment',
      propertyLocation: map['property_location']?.toString() ?? 'Noida / NCR',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      city: map['city']?.toString() ?? 'Noida',
      employmentType: map['employment_type']?.toString() ?? 'Salaried',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0.0,
      existingEmi: (map['existing_emi'] as num?)?.toDouble() ?? 0.0,
      preferredTenureYears: (map['preferred_tenure_years'] as num?)?.toInt() ?? 20,
      preferredLender: map['preferred_lender']?.toString(),
      indicativeEligibility: (map['indicative_eligibility'] as num?)?.toDouble() ?? 0.0,
      status: LoanStatus.fromString(map['status']?.toString() ?? 'NEW'),
      adminRemarks: map['admin_remarks']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class LoanDocumentModel {
  final String id;
  final String loanRequestId;
  final String documentType;
  final String documentUrl;
  final String fileName;
  final int fileSizeBytes;
  final DateTime uploadedAt;

  const LoanDocumentModel({
    required this.id,
    required this.loanRequestId,
    required this.documentType,
    required this.documentUrl,
    required this.fileName,
    this.fileSizeBytes = 0,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_request_id': loanRequestId,
      'document_type': documentType,
      'document_url': documentUrl,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory LoanDocumentModel.fromMap(Map<String, dynamic> map) {
    return LoanDocumentModel(
      id: map['id']?.toString() ?? 'LDOC-${DateTime.now().millisecondsSinceEpoch}',
      loanRequestId: map['loan_request_id']?.toString() ?? '',
      documentType: map['document_type']?.toString() ?? 'Identity Document',
      documentUrl: map['document_url']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? 'document.pdf',
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      uploadedAt: map['uploaded_at'] != null ? DateTime.tryParse(map['uploaded_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class LoanOfferModel {
  final String id;
  final String loanRequestId;
  final String lenderName;
  final double sanctionedAmount;
  final double interestRate;
  final int tenureYears;
  final double monthlyEmi;
  final double processingFee;
  final String? specialTerms;
  final DateTime? validUntil;
  final String status;
  final DateTime createdAt;

  const LoanOfferModel({
    required this.id,
    required this.loanRequestId,
    required this.lenderName,
    required this.sanctionedAmount,
    required this.interestRate,
    required this.tenureYears,
    required this.monthlyEmi,
    this.processingFee = 0,
    this.specialTerms,
    this.validUntil,
    this.status = 'Offered',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_request_id': loanRequestId,
      'lender_name': lenderName,
      'sanctioned_amount': sanctionedAmount,
      'interest_rate': interestRate,
      'tenure_years': tenureYears,
      'monthly_emi': monthlyEmi,
      'processing_fee': processingFee,
      'special_terms': specialTerms,
      'valid_until': validUntil?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LoanOfferModel.fromMap(Map<String, dynamic> map) {
    return LoanOfferModel(
      id: map['id']?.toString() ?? 'LOFR-${DateTime.now().millisecondsSinceEpoch}',
      loanRequestId: map['loan_request_id']?.toString() ?? '',
      lenderName: map['lender_name']?.toString() ?? 'Partner Bank',
      sanctionedAmount: (map['sanctioned_amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 8.5,
      tenureYears: (map['tenure_years'] as num?)?.toInt() ?? 20,
      monthlyEmi: (map['monthly_emi'] as num?)?.toDouble() ?? 0.0,
      processingFee: (map['processing_fee'] as num?)?.toDouble() ?? 0.0,
      specialTerms: map['special_terms']?.toString(),
      validUntil: map['valid_until'] != null ? DateTime.tryParse(map['valid_until'].toString()) : null,
      status: map['status']?.toString() ?? 'Offered',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class LoanEligibilityResult {
  final double maxEligibleLoan;
  final double estimatedMonthlyEmi;
  final double foirPercentage;
  final double netMonthlyDisposable;
  final List<String> requiredDocuments;
  final String legalDisclaimer;
  final String eligibilityStatus; // LIKELY_ELIGIBLE, MAY_BE_ELIGIBLE, NEEDS_REVIEW, NOT_ENOUGH_DATA

  const LoanEligibilityResult({
    required this.maxEligibleLoan,
    required this.estimatedMonthlyEmi,
    required this.foirPercentage,
    required this.netMonthlyDisposable,
    required this.requiredDocuments,
    this.legalDisclaimer = 'Indicative estimate only. Final eligibility and approval are determined by the lender.',
    this.eligibilityStatus = 'LIKELY_ELIGIBLE',
  });
}

class LoanProductModel {
  final String lenderId;
  final String lenderName;
  final String productName;
  final double interestRate;
  final String rateType; // Floating EBLR / Fixed
  final int minTenureYears;
  final int maxTenureYears;
  final String processingFee;
  final double maxLoanAmount;
  final String source;
  final String? sourceUrl;
  final DateTime lastUpdatedAt;
  final String status;

  const LoanProductModel({
    required this.lenderId,
    required this.lenderName,
    required this.productName,
    required this.interestRate,
    this.rateType = 'Floating EBLR',
    this.minTenureYears = 5,
    this.maxTenureYears = 30,
    this.processingFee = '0.25% - 0.50% (Max ₹10,000)',
    this.maxLoanAmount = 100000000,
    required this.source,
    this.sourceUrl,
    required this.lastUpdatedAt,
    this.status = 'ACTIVE',
  });

  Map<String, dynamic> toMap() => {
        'lenderId': lenderId,
        'lenderName': lenderName,
        'productName': productName,
        'interestRate': interestRate,
        'rateType': rateType,
        'minTenureYears': minTenureYears,
        'maxTenureYears': maxTenureYears,
        'processingFee': processingFee,
        'maxLoanAmount': maxLoanAmount,
        'source': source,
        'sourceUrl': sourceUrl,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'status': status,
      };
}


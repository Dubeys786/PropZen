import 'service_request_model.dart';

/// Represents a specialized Service Partner Profile in PropZen
class ServicePartnerProfile {
  final String id;
  final String userId;
  final String businessName;
  final String serviceCategory; // Primary specialization code, e.g. "HOME_DESIGN", "LOAN", etc.
  final List<String> serviceCategories; // All approved categories for multi-service partners
  final String verificationStatus; // "PENDING", "UNDER_REVIEW", "VERIFIED", "APPROVED", "REJECTED"
  final String status; // "ACTIVE", "SUSPENDED", "INACTIVE"
  final String phone;
  final String email;
  final double rating;
  final int completedProjectsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicePartnerProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.serviceCategory,
    this.serviceCategories = const [],
    this.verificationStatus = 'PENDING',
    this.status = 'ACTIVE',
    this.phone = '',
    this.email = '',
    this.rating = 4.8,
    this.completedProjectsCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Partner is authorized only when verified/approved and active
  bool get isApproved {
    final v = verificationStatus.trim().toUpperCase();
    final s = status.trim().toUpperCase();
    return (v == 'VERIFIED' || v == 'APPROVED') && s == 'ACTIVE';
  }

  /// Whether partner is suspended
  bool get isSuspended => status.trim().toUpperCase() == 'SUSPENDED';

  /// List of approved category types this partner can legally provide
  List<ServiceCategoryType> get approvedCategoryTypes {
    final codes = <String>{};
    if (serviceCategory.trim().isNotEmpty) {
      codes.add(serviceCategory.trim());
    }
    for (final c in serviceCategories) {
      if (c.trim().isNotEmpty) {
        codes.add(c.trim());
      }
    }

    if (codes.isEmpty) return const [];

    final types = <ServiceCategoryType>{};
    for (final code in codes) {
      types.add(ServiceCategoryType.fromCode(code));
    }
    return types.toList();
  }

  /// Primary specialization category type
  ServiceCategoryType? get primaryCategory {
    if (serviceCategory.trim().isNotEmpty) {
      return ServiceCategoryType.fromCode(serviceCategory);
    }
    if (approvedCategoryTypes.isNotEmpty) {
      return approvedCategoryTypes.first;
    }
    return null;
  }

  /// List of approved category codes as strings
  List<String> get approvedCategories {
    final codes = <String>{};
    if (serviceCategory.trim().isNotEmpty) {
      codes.add(serviceCategory.trim());
    }
    for (final c in serviceCategories) {
      if (c.trim().isNotEmpty) {
        codes.add(c.trim());
      }
    }
    return codes.toList();
  }

  /// Check whether partner has permission for a specific category
  bool canProvide(ServiceCategoryType type) {
    if (!isApproved) return false;
    return approvedCategoryTypes.contains(type);
  }

  /// Check whether partner can provide category by string code
  bool canProvideCategory(String code) {
    if (!isApproved) return false;
    final cat = ServiceCategoryType.fromCode(code);
    return approvedCategoryTypes.contains(cat);
  }

  /// Dynamic portal title based on specialization
  String portalTitle([ServiceCategoryType? activeCategory]) {
    final cat = activeCategory ?? (approvedCategoryTypes.isNotEmpty ? approvedCategoryTypes.first : null);
    if (cat == null) return 'Service Partner Portal';

    switch (cat) {
      case ServiceCategoryType.homeDesign:
        return 'Home Design Partner Portal';
      case ServiceCategoryType.loan:
        return 'Loan Partner Portal';
      case ServiceCategoryType.vastu:
        return 'Vastu Partner Portal';
      case ServiceCategoryType.construction:
        return 'Construction Partner Portal';
      case ServiceCategoryType.propertyVerification:
        return 'Property Verification Partner Portal';
      case ServiceCategoryType.visualization:
        return 'Virtual & 3D Partner Portal';
    }
  }

  /// Dynamic empty state message
  String emptyRequestsMessage([ServiceCategoryType? activeCategory]) {
    final cat = activeCategory ?? (approvedCategoryTypes.isNotEmpty ? approvedCategoryTypes.first : null);
    if (cat == null) return 'No service requests assigned yet.';

    switch (cat) {
      case ServiceCategoryType.homeDesign:
        return 'No Home Design requests yet.';
      case ServiceCategoryType.loan:
        return 'No Loan requests yet.';
      case ServiceCategoryType.vastu:
        return 'No Vastu requests yet.';
      case ServiceCategoryType.construction:
        return 'No Construction requests yet.';
      case ServiceCategoryType.propertyVerification:
        return 'No Property Verification requests yet.';
      case ServiceCategoryType.visualization:
        return 'No Virtual / 3D requests yet.';
    }
  }

  ServicePartnerProfile copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? serviceCategory,
    List<String>? serviceCategories,
    String? verificationStatus,
    String? status,
    String? phone,
    String? email,
    double? rating,
    int? completedProjectsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServicePartnerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      completedProjectsCount: completedProjectsCount ?? this.completedProjectsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether partner has any service specialization configured
  bool get hasSpecialization => approvedCategories.isNotEmpty;

  /// Whether partner is pending verification
  bool get isPending => verificationStatus.trim().toUpperCase() == 'PENDING';

  /// Whether partner is rejected
  bool get isRejected => verificationStatus.trim().toUpperCase() == 'REJECTED';

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'business_name': businessName,
    'service_category': serviceCategory,
    'service_categories': serviceCategories.isNotEmpty ? serviceCategories : (serviceCategory.isNotEmpty ? [serviceCategory] : []),
    'verification_status': verificationStatus,
    'status': status,
    'phone': phone,
    'email': email,
    'rating': rating,
    'completed_projects_count': completedProjectsCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ServicePartnerProfile.fromJson(Map<String, dynamic> json) {
    final rawCats = json['service_categories'];
    List<String> parsedCategories = [];
    if (rawCats is List) {
      parsedCategories = rawCats.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    final rawCat = json['service_category']?.toString().trim() ?? json['category']?.toString().trim();
    final primaryCat = (rawCat != null && rawCat.isNotEmpty)
        ? rawCat
        : (parsedCategories.isNotEmpty ? parsedCategories.first : '');

    if (parsedCategories.isEmpty && primaryCat.isNotEmpty) {
      parsedCategories = [primaryCat];
    }

    final effectiveStatus = json['partner_status']?.toString() ?? json['status']?.toString() ?? 'PENDING';
    final effectiveVerification = json['verification_status']?.toString() ?? (effectiveStatus == 'APPROVED' ? 'VERIFIED' : 'PENDING');

    return ServicePartnerProfile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? 'Specialized Service Partner',
      serviceCategory: primaryCat,
      serviceCategories: parsedCategories,
      verificationStatus: effectiveVerification,
      status: effectiveStatus,
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      completedProjectsCount: (json['completed_projects_count'] as num?)?.toInt() ?? (json['completed_projects'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

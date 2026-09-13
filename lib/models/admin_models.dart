import 'package:flutter/foundation.dart';

/// 6 Admin Roles
enum AdminRole {
  superAdmin,
  propertyAdmin,
  dealerAdmin,
  supportAdmin,
  financeAdmin,
  contentAdmin,
}

extension AdminRoleExt on AdminRole {
  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Administrator';
      case AdminRole.propertyAdmin:
        return 'Property Administrator';
      case AdminRole.dealerAdmin:
        return 'Dealer Administrator';
      case AdminRole.supportAdmin:
        return 'Support Administrator';
      case AdminRole.financeAdmin:
        return 'Finance Administrator';
      case AdminRole.contentAdmin:
        return 'Content Administrator';
    }
  }

  String get code {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.propertyAdmin:
        return 'property_admin';
      case AdminRole.dealerAdmin:
        return 'dealer_admin';
      case AdminRole.supportAdmin:
        return 'support_admin';
      case AdminRole.financeAdmin:
        return 'finance_admin';
      case AdminRole.contentAdmin:
        return 'content_admin';
    }
  }

  static AdminRole fromString(String? val) {
    if (val == null) return AdminRole.superAdmin;
    final lower = val.toLowerCase().replaceAll(' ', '_');
    if (lower.contains('property')) return AdminRole.propertyAdmin;
    if (lower.contains('dealer')) return AdminRole.dealerAdmin;
    if (lower.contains('support')) return AdminRole.supportAdmin;
    if (lower.contains('finance')) return AdminRole.financeAdmin;
    if (lower.contains('content')) return AdminRole.contentAdmin;
    return AdminRole.superAdmin;
  }
}

/// Centralized Permission Check Matrix
class AdminPermissions {
  final AdminRole role;

  const AdminPermissions(this.role);

  bool get canManageUsers =>
      role == AdminRole.superAdmin || role == AdminRole.supportAdmin;

  bool get canManageDealers =>
      role == AdminRole.superAdmin || role == AdminRole.dealerAdmin;

  bool get canVerifyProperties =>
      role == AdminRole.superAdmin || role == AdminRole.propertyAdmin;

  bool get canManagePayments =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  bool get canManageSubscriptions =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  bool get canManageContent =>
      role == AdminRole.superAdmin || role == AdminRole.contentAdmin;

  bool get canManageComplaints =>
      role == AdminRole.superAdmin || role == AdminRole.supportAdmin;

  bool get canViewAnalytics => true; // All admin roles can inspect operational analytics

  bool get canManageAiConfig => role == AdminRole.superAdmin;

  bool get canExportData =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin || role == AdminRole.propertyAdmin;
}

/// Admin User Profile Model
class AdminUser {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final bool isActive;
  final String lastLoginAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = AdminRole.superAdmin,
    this.isActive = true,
    required this.lastLoginAt,
  });

  AdminPermissions get permissions => AdminPermissions(role);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.code,
        'is_active': isActive,
        'last_login_at': lastLoginAt,
      };

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Administrator',
      email: map['email']?.toString() ?? 'admin@propzen.ai',
      role: AdminRoleExt.fromString(map['role']?.toString()),
      isActive: map['is_active'] != false,
      lastLoginAt: map['last_login_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

/// User Account Model for Admin User Management
class UserAccountModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String userType; // Buyer, NRI, Dealer, Admin
  final String accountStatus; // Active, Suspended, Pending Verification
  final String createdAt;
  final String lastActivityAt;
  final String? suspensionReason;

  const UserAccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.userType,
    this.accountStatus = 'Active',
    required this.createdAt,
    required this.lastActivityAt,
    this.suspensionReason,
  });

  bool get isSuspended => accountStatus.toLowerCase() == 'suspended';
  bool get isActive => accountStatus.toLowerCase() == 'active';

  UserAccountModel copyWith({
    String? accountStatus,
    String? suspensionReason,
  }) {
    return UserAccountModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      userType: userType,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'user_type': userType,
        'account_status': accountStatus,
        'created_at': createdAt,
        'last_activity_at': lastActivityAt,
        'suspension_reason': suspensionReason,
      };

  factory UserAccountModel.fromMap(Map<String, dynamic> map) {
    return UserAccountModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'User',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      userType: map['user_type']?.toString() ?? 'Buyer',
      accountStatus: map['account_status']?.toString() ?? 'Active',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      lastActivityAt: map['last_activity_at']?.toString() ?? DateTime.now().toIso8601String(),
      suspensionReason: map['suspension_reason']?.toString(),
    );
  }
}

/// Dealer Account Model for Admin Dealer Management
class DealerAccountModel {
  final String id;
  final String name;
  final String firmName;
  final String phone;
  final String email;
  final String verificationStatus; // Pending, Verified, Needs Review, Suspended
  final String subscriptionPlan; // Starter, Pro, Premium, Enterprise
  final int activeListings;
  final int leadsCount;
  final int siteVisitsCount;
  final String accountStatus; // Active, Suspended
  final String reraId;
  final String experienceYears;
  final double rating;
  final String? submissionDate;
  final List<String> submittedDocuments;
  final String? statusReason;

  const DealerAccountModel({
    required this.id,
    required this.name,
    required this.firmName,
    required this.phone,
    required this.email,
    this.verificationStatus = 'Pending',
    this.subscriptionPlan = 'Dealer Starter',
    this.activeListings = 0,
    this.leadsCount = 0,
    this.siteVisitsCount = 0,
    this.accountStatus = 'Active',
    this.reraId = '',
    this.experienceYears = '5 Years',
    this.rating = 4.8,
    this.submissionDate,
    this.submittedDocuments = const [],
    this.statusReason,
  });

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isPending => verificationStatus.toLowerCase() == 'pending';
  bool get isSuspended => accountStatus.toLowerCase() == 'suspended';

  DealerAccountModel copyWith({
    String? verificationStatus,
    String? accountStatus,
    String? statusReason,
    String? subscriptionPlan,
  }) {
    return DealerAccountModel(
      id: id,
      name: name,
      firmName: firmName,
      phone: phone,
      email: email,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      activeListings: activeListings,
      leadsCount: leadsCount,
      siteVisitsCount: siteVisitsCount,
      accountStatus: accountStatus ?? this.accountStatus,
      reraId: reraId,
      experienceYears: experienceYears,
      rating: rating,
      submissionDate: submissionDate,
      submittedDocuments: submittedDocuments,
      statusReason: statusReason ?? this.statusReason,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'firm_name': firmName,
        'phone': phone,
        'email': email,
        'verification_status': verificationStatus,
        'subscription_plan': subscriptionPlan,
        'active_listings': activeListings,
        'leads_count': leadsCount,
        'site_visits_count': siteVisitsCount,
        'account_status': accountStatus,
        'rera_id': reraId,
        'experience_years': experienceYears,
        'rating': rating,
        'submission_date': submissionDate,
        'submitted_documents': submittedDocuments,
        'status_reason': statusReason,
      };

  factory DealerAccountModel.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status']?.toString() ?? map['verification_status']?.toString() ?? 'Pending';
    final isApproved = rawStatus.toUpperCase() == 'APPROVED' || rawStatus.toUpperCase() == 'VERIFIED';
    return DealerAccountModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['agency_name']?.toString() ?? 'Dealer Partner',
      firmName: map['agency_name']?.toString() ?? map['firm_name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      verificationStatus: isApproved ? 'Verified' : rawStatus,
      subscriptionPlan: map['subscription_plan']?.toString() ?? 'Dealer Starter',
      activeListings: (map['active_listings'] as num?)?.toInt() ?? 0,
      leadsCount: (map['leads_count'] as num?)?.toInt() ?? 0,
      siteVisitsCount: (map['site_visits_count'] as num?)?.toInt() ?? 0,
      accountStatus: map['account_status']?.toString() ?? (rawStatus.toUpperCase() == 'SUSPENDED' ? 'Suspended' : 'Active'),
      reraId: map['license_number']?.toString() ?? map['rera_id']?.toString() ?? '',
      experienceYears: map['experience_years'] != null ? '${map['experience_years']} Years' : '5 Years',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      submissionDate: map['created_at']?.toString() ?? map['submission_date']?.toString(),
      submittedDocuments: map['submitted_documents'] is List ? List<String>.from(map['submitted_documents']) : [],
      statusReason: map['verification_notes']?.toString() ?? map['status_reason']?.toString(),
    );
  }
}

/// Immutable Admin Verification & Moderation Audit Log Model
class AdminAuditLogModel {
  final String id;
  final String timestamp;
  final String adminId;
  final String adminName;
  final String targetType; // Property, Dealer, User, Document, Payment, Subscription, Content, System
  final String targetId;
  final String targetTitle;
  final String action; // Approved, Rejected, Correction Requested, Suspended, Reactivated, Overridden, Refunded
  final String fieldChanged;
  final String oldValue;
  final String newValue;
  final String reason;
  final Map<String, dynamic> metadata;

  const AdminAuditLogModel({
    required this.id,
    required this.timestamp,
    required this.adminId,
    required this.adminName,
    required this.targetType,
    required this.targetId,
    this.targetTitle = '',
    required this.action,
    this.fieldChanged = 'status',
    this.oldValue = '',
    this.newValue = '',
    this.reason = '',
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp,
        'admin_id': adminId,
        'admin_name': adminName,
        'target_type': targetType,
        'target_id': targetId,
        'target_title': targetTitle,
        'action': action,
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'reason': reason,
        'metadata': metadata,
      };

  factory AdminAuditLogModel.fromMap(Map<String, dynamic> map) {
    return AdminAuditLogModel(
      id: map['id']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      adminId: map['admin_id']?.toString() ?? 'ADM-001',
      adminName: map['admin_name']?.toString() ?? 'Master Administrator',
      targetType: map['target_type']?.toString() ?? 'Property',
      targetId: map['target_id']?.toString() ?? '',
      targetTitle: map['target_title']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      fieldChanged: map['field_changed']?.toString() ?? 'status',
      oldValue: map['old_value']?.toString() ?? '',
      newValue: map['new_value']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }
}

/// Complaint & User Report Model
class ComplaintTicketModel {
  final String id;
  final String ticketNumber;
  final String reporterName;
  final String reporterEmail;
  final String targetType; // Property, Dealer, Incorrect Information, Payment Issue, Site Visit Issue, Abuse, Technical Issue, Other
  final String targetTitle;
  final String targetId;
  final String title;
  final String description;
  final String status; // New, Under Review, Waiting for Information, Resolved, Rejected
  final String priority; // Low, Medium, High, Urgent
  final String createdAt;
  final String? assignedAdmin;
  final String? resolutionNotes;
  final String? resolvedAt;

  const ComplaintTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.reporterName,
    required this.reporterEmail,
    required this.targetType,
    required this.targetTitle,
    required this.targetId,
    required this.title,
    required this.description,
    this.status = 'New',
    this.priority = 'Medium',
    required this.createdAt,
    this.assignedAdmin,
    this.resolutionNotes,
    this.resolvedAt,
  });

  ComplaintTicketModel copyWith({
    String? status,
    String? assignedAdmin,
    String? resolutionNotes,
    String? resolvedAt,
  }) {
    return ComplaintTicketModel(
      id: id,
      ticketNumber: ticketNumber,
      reporterName: reporterName,
      reporterEmail: reporterEmail,
      targetType: targetType,
      targetTitle: targetTitle,
      targetId: targetId,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      createdAt: createdAt,
      assignedAdmin: assignedAdmin ?? this.assignedAdmin,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ticket_number': ticketNumber,
        'reporter_name': reporterName,
        'reporter_email': reporterEmail,
        'target_type': targetType,
        'target_title': targetTitle,
        'target_id': targetId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'created_at': createdAt,
        'assigned_admin': assignedAdmin,
        'resolution_notes': resolutionNotes,
        'resolved_at': resolvedAt,
      };

  factory ComplaintTicketModel.fromMap(Map<String, dynamic> map) {
    return ComplaintTicketModel(
      id: map['id']?.toString() ?? '',
      ticketNumber: map['ticket_number']?.toString() ?? 'TKT-001',
      reporterName: map['reporter_name']?.toString() ?? 'Buyer',
      reporterEmail: map['reporter_email']?.toString() ?? '',
      targetType: map['target_type']?.toString() ?? 'Property',
      targetTitle: map['target_title']?.toString() ?? '',
      targetId: map['target_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'New',
      priority: map['priority']?.toString() ?? 'Medium',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      assignedAdmin: map['assigned_admin']?.toString(),
      resolutionNotes: map['resolution_notes']?.toString(),
      resolvedAt: map['resolved_at']?.toString(),
    );
  }
}

/// Dynamic Subscription Plan Config
class SubscriptionPlanConfig {
  final String id;
  final String planName;
  final String userType; // Dealer, NRI
  final String description;
  final double priceRupees;
  final String duration; // Monthly, Quarterly, Annual
  final int listingLimit;
  final int leadLimit;
  final List<String> features;
  final bool isActive;

  const SubscriptionPlanConfig({
    required this.id,
    required this.planName,
    required this.userType,
    required this.description,
    required this.priceRupees,
    this.duration = 'Monthly',
    this.listingLimit = 10,
    this.leadLimit = 50,
    this.features = const [],
    this.isActive = true,
  });

  SubscriptionPlanConfig copyWith({
    String? planName,
    String? description,
    double? priceRupees,
    int? listingLimit,
    int? leadLimit,
    bool? isActive,
    List<String>? features,
  }) {
    return SubscriptionPlanConfig(
      id: id,
      planName: planName ?? this.planName,
      userType: userType,
      description: description ?? this.description,
      priceRupees: priceRupees ?? this.priceRupees,
      duration: duration,
      listingLimit: listingLimit ?? this.listingLimit,
      leadLimit: leadLimit ?? this.leadLimit,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'plan_name': planName,
        'user_type': userType,
        'description': description,
        'price_rupees': priceRupees,
        'duration': duration,
        'listing_limit': listingLimit,
        'lead_limit': leadLimit,
        'features': features,
        'is_active': isActive,
      };

  factory SubscriptionPlanConfig.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanConfig(
      id: map['id']?.toString() ?? '',
      planName: map['plan_name']?.toString() ?? '',
      userType: map['user_type']?.toString() ?? 'Dealer',
      description: map['description']?.toString() ?? '',
      priceRupees: (map['price_rupees'] as num?)?.toDouble() ?? 0.0,
      duration: map['duration']?.toString() ?? 'Monthly',
      listingLimit: (map['listing_limit'] as num?)?.toInt() ?? 10,
      leadLimit: (map['lead_limit'] as num?)?.toInt() ?? 50,
      features: map['features'] is List ? List<String>.from(map['features']) : [],
      isActive: map['is_active'] != false,
    );
  }
}

/// Payment Record Model
class AdminPaymentRecord {
  final String id;
  final String orderId;
  final String userName;
  final String userEmail;
  final String userType; // Dealer, NRI
  final String planName;
  final double amountRupees;
  final String paymentId;
  final String status; // Success, Pending, Failed, Refunded
  final String date;
  final String paymentMethod;

  const AdminPaymentRecord({
    required this.id,
    required this.orderId,
    required this.userName,
    required this.userEmail,
    required this.userType,
    required this.planName,
    required this.amountRupees,
    required this.paymentId,
    required this.status,
    required this.date,
    this.paymentMethod = 'Razorpay / UPI',
  });

  AdminPaymentRecord copyWith({
    String? status,
  }) {
    return AdminPaymentRecord(
      id: id,
      orderId: orderId,
      userName: userName,
      userEmail: userEmail,
      userType: userType,
      planName: planName,
      amountRupees: amountRupees,
      paymentId: paymentId,
      status: status ?? this.status,
      date: date,
      paymentMethod: paymentMethod,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'order_id': orderId,
        'user_name': userName,
        'user_email': userEmail,
        'user_type': userType,
        'plan_name': planName,
        'amount_rupees': amountRupees,
        'payment_id': paymentId,
        'status': status,
        'date': date,
        'payment_method': paymentMethod,
      };

  factory AdminPaymentRecord.fromMap(Map<String, dynamic> map) {
    return AdminPaymentRecord(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? '',
      userEmail: map['user_email']?.toString() ?? '',
      userType: map['user_type']?.toString() ?? 'Dealer',
      planName: map['plan_name']?.toString() ?? '',
      amountRupees: (map['amount_rupees'] as num?)?.toDouble() ?? 0.0,
      paymentId: map['payment_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Success',
      date: map['date']?.toString() ?? DateTime.now().toIso8601String(),
      paymentMethod: map['payment_method']?.toString() ?? 'Razorpay',
    );
  }
}

/// Broadcast Notification Model
class AdminBroadcastNotification {
  final String id;
  final String title;
  final String message;
  final String notificationType; // System, Property, Subscription, Payment, Site Visit, Lead, Verification, NRI, Dealer
  final String audience; // All Users, Buyers, NRI Users, Dealers, Verified Dealers, Specific Users
  final String createdBy;
  final String createdAt;
  final String status; // Sent, Scheduled, Draft
  final int recipientCount;

  const AdminBroadcastNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.audience,
    required this.createdBy,
    required this.createdAt,
    this.status = 'Sent',
    this.recipientCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'notification_type': notificationType,
        'audience': audience,
        'created_by': createdBy,
        'created_at': createdAt,
        'status': status,
        'recipient_count': recipientCount,
      };

  factory AdminBroadcastNotification.fromMap(Map<String, dynamic> map) {
    return AdminBroadcastNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      notificationType: map['notification_type']?.toString() ?? 'System',
      audience: map['audience']?.toString() ?? 'All Users',
      createdBy: map['created_by']?.toString() ?? 'Admin',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      status: map['status']?.toString() ?? 'Sent',
      recipientCount: (map['recipient_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// AI Monitoring & Feature Flags Model
class AiMonitoringMetrics {
  final int totalRequests;
  final int voiceRequests;
  final int failedRequests;
  final double avgResponseTimeMs;
  final int apiErrors;
  final Map<String, int> featureUsage;

  const AiMonitoringMetrics({
    this.totalRequests = 1420,
    this.voiceRequests = 680,
    this.failedRequests = 12,
    this.avgResponseTimeMs = 380.0,
    this.apiErrors = 4,
    this.featureUsage = const {
      'AI Advisor': 820,
      'Voice Assistant': 680,
      'Listing Creator': 190,
      'Lead Assistant': 240,
      'Property Intelligence': 490,
    },
  });
}

class SystemFeatureFlags {
  final bool aiAdvisorEnabled;
  final bool aiVoiceEnabled;
  final bool aiListingCreatorEnabled;
  final bool aiLeadAssistantEnabled;
  final bool aiPropertyIntelligenceEnabled;

  const SystemFeatureFlags({
    this.aiAdvisorEnabled = true,
    this.aiVoiceEnabled = true,
    this.aiListingCreatorEnabled = true,
    this.aiLeadAssistantEnabled = true,
    this.aiPropertyIntelligenceEnabled = true,
  });

  SystemFeatureFlags copyWith({
    bool? aiAdvisorEnabled,
    bool? aiVoiceEnabled,
    bool? aiListingCreatorEnabled,
    bool? aiLeadAssistantEnabled,
    bool? aiPropertyIntelligenceEnabled,
  }) {
    return SystemFeatureFlags(
      aiAdvisorEnabled: aiAdvisorEnabled ?? this.aiAdvisorEnabled,
      aiVoiceEnabled: aiVoiceEnabled ?? this.aiVoiceEnabled,
      aiListingCreatorEnabled: aiListingCreatorEnabled ?? this.aiListingCreatorEnabled,
      aiLeadAssistantEnabled: aiLeadAssistantEnabled ?? this.aiLeadAssistantEnabled,
      aiPropertyIntelligenceEnabled: aiPropertyIntelligenceEnabled ?? this.aiPropertyIntelligenceEnabled,
    );
  }
}

/// System Health Item
class SystemHealthItem {
  final String serviceName;
  final String status; // Operational, Degraded, Down, Maintenance
  final String latencyMs;
  final String lastCheckedAt;
  final String details;

  const SystemHealthItem({
    required this.serviceName,
    required this.status,
    required this.latencyMs,
    required this.lastCheckedAt,
    required this.details,
  });
}

/// Property Report / Moderation Item
class PropertyReportModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String reporterId;
  final String reason;
  final String comment;
  final String status; // PENDING, INVESTIGATING, RESOLVED, DISMISSED
  final String createdAt;

  const PropertyReportModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.reporterId,
    required this.reason,
    required this.comment,
    this.status = 'PENDING',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
        'reporterId': reporterId,
        'reason': reason,
        'comment': comment,
        'status': status,
        'createdAt': createdAt,
      };

  factory PropertyReportModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyReportModel(
      id: id,
      propertyId: map['propertyId']?.toString() ?? '',
      propertyTitle: map['propertyTitle']?.toString() ?? '',
      reporterId: map['reporterId']?.toString() ?? '',
      reason: map['reason']?.toString() ?? 'Other',
      comment: map['comment']?.toString() ?? '',
      status: map['status']?.toString() ?? 'PENDING',
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

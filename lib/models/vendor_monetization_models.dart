enum WalletTransactionType {
  credit,
  debit,
  refund,
  bonus,
  adjustment;

  String get dbValue {
    switch (this) {
      case WalletTransactionType.credit:
        return 'CREDIT';
      case WalletTransactionType.debit:
        return 'DEBIT';
      case WalletTransactionType.refund:
        return 'REFUND';
      case WalletTransactionType.bonus:
        return 'BONUS';
      case WalletTransactionType.adjustment:
        return 'ADJUSTMENT';
    }
  }

  static WalletTransactionType fromString(String val) {
    final clean = val.toUpperCase().trim();
    for (final t in WalletTransactionType.values) {
      if (t.dbValue == clean || t.name.toUpperCase() == clean) return t;
    }
    return WalletTransactionType.credit;
  }
}

enum LeadAssignmentStatus {
  assigned,
  accepted,
  contacted,
  converted,
  rejected,
  expired,
  cancelled;

  String get dbValue {
    switch (this) {
      case LeadAssignmentStatus.assigned:
        return 'ASSIGNED';
      case LeadAssignmentStatus.accepted:
        return 'ACCEPTED';
      case LeadAssignmentStatus.contacted:
        return 'CONTACTED';
      case LeadAssignmentStatus.converted:
        return 'CONVERTED';
      case LeadAssignmentStatus.rejected:
        return 'REJECTED';
      case LeadAssignmentStatus.expired:
        return 'EXPIRED';
      case LeadAssignmentStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static LeadAssignmentStatus fromString(String val) {
    final clean = val.toUpperCase().trim();
    for (final s in LeadAssignmentStatus.values) {
      if (s.dbValue == clean || s.name.toUpperCase() == clean) return s;
    }
    return LeadAssignmentStatus.assigned;
  }
}

class VendorWalletModel {
  final String vendorId;
  final double balanceInr;
  final double totalCredited;
  final double totalDebited;
  final String currency;
  final String status;
  final DateTime updatedAt;

  const VendorWalletModel({
    required this.vendorId,
    required this.balanceInr,
    this.totalCredited = 0.0,
    this.totalDebited = 0.0,
    this.currency = 'INR',
    this.status = 'ACTIVE',
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'vendor_id': vendorId,
        'balance_inr': balanceInr,
        'total_credited': totalCredited,
        'total_debited': totalDebited,
        'currency': currency,
        'status': status,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VendorWalletModel.fromMap(Map<String, dynamic> map) {
    return VendorWalletModel(
      vendorId: map['vendor_id']?.toString() ?? '',
      balanceInr: (map['balance_inr'] as num?)?.toDouble() ?? 0.0,
      totalCredited: (map['total_credited'] as num?)?.toDouble() ?? 0.0,
      totalDebited: (map['total_debited'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'INR',
      status: map['status']?.toString() ?? 'ACTIVE',
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class WalletTransactionModel {
  final String id;
  final String vendorId;
  final double amount;
  final WalletTransactionType type;
  final String? referenceId;
  final String description;
  final double balanceAfter;
  final String status;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.vendorId,
    required this.amount,
    required this.type,
    this.referenceId,
    required this.description,
    required this.balanceAfter,
    this.status = 'COMPLETED',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vendor_id': vendorId,
        'amount': amount,
        'type': type.dbValue,
        'reference_id': referenceId,
        'description': description,
        'balance_after': balanceAfter,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map) {
    return WalletTransactionModel(
      id: map['id']?.toString() ?? 'WTX-${DateTime.now().millisecondsSinceEpoch}',
      vendorId: map['vendor_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: WalletTransactionType.fromString(map['type']?.toString() ?? 'CREDIT'),
      referenceId: map['reference_id']?.toString(),
      description: map['description']?.toString() ?? '',
      balanceAfter: (map['balance_after'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'COMPLETED',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class LeadDistributionRulesModel {
  final double subscriptionWeight;
  final double locationWeight;
  final double categoryWeight;
  final double verificationWeight;
  final double responseRateWeight;
  final double rotationWeight;
  final double defaultLeadCostInr;
  final int leadResponseTimeoutMins;

  const LeadDistributionRulesModel({
    this.subscriptionWeight = 0.25,
    this.locationWeight = 0.25,
    this.categoryWeight = 0.20,
    this.verificationWeight = 0.10,
    this.responseRateWeight = 0.10,
    this.rotationWeight = 0.10,
    this.defaultLeadCostInr = 350.0,
    this.leadResponseTimeoutMins = 30,
  });

  Map<String, dynamic> toMap() => {
        'subscription_weight': subscriptionWeight,
        'location_weight': locationWeight,
        'category_weight': categoryWeight,
        'verification_weight': verificationWeight,
        'response_rate_weight': responseRateWeight,
        'rotation_weight': rotationWeight,
        'default_lead_cost_inr': defaultLeadCostInr,
        'lead_response_timeout_mins': leadResponseTimeoutMins,
      };

  factory LeadDistributionRulesModel.fromMap(Map<String, dynamic> map) {
    return LeadDistributionRulesModel(
      subscriptionWeight: (map['subscription_weight'] as num?)?.toDouble() ?? 0.25,
      locationWeight: (map['location_weight'] as num?)?.toDouble() ?? 0.25,
      categoryWeight: (map['category_weight'] as num?)?.toDouble() ?? 0.20,
      verificationWeight: (map['verification_weight'] as num?)?.toDouble() ?? 0.10,
      responseRateWeight: (map['response_rate_weight'] as num?)?.toDouble() ?? 0.10,
      rotationWeight: (map['rotation_weight'] as num?)?.toDouble() ?? 0.10,
      defaultLeadCostInr: (map['default_lead_cost_inr'] as num?)?.toDouble() ?? 350.0,
      leadResponseTimeoutMins: (map['lead_response_timeout_mins'] as num?)?.toInt() ?? 30,
    );
  }
}

class LeadAssignmentModel {
  final String id;
  final String leadId;
  final String vendorId;
  final String customerName;
  final String maskedPhone;
  final String unmaskedPhone;
  final String maskedEmail;
  final String propertyTitle;
  final String locality;
  final double leadCostInr;
  final LeadAssignmentStatus status;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? contactedAt;
  final DateTime? convertedAt;

  const LeadAssignmentModel({
    required this.id,
    required this.leadId,
    required this.vendorId,
    required this.customerName,
    required this.maskedPhone,
    required this.unmaskedPhone,
    required this.maskedEmail,
    required this.propertyTitle,
    required this.locality,
    this.leadCostInr = 350.0,
    this.status = LeadAssignmentStatus.assigned,
    required this.assignedAt,
    this.acceptedAt,
    this.contactedAt,
    this.convertedAt,
  });

  bool get isCustomerContactUnlocked => status == LeadAssignmentStatus.accepted || status == LeadAssignmentStatus.contacted || status == LeadAssignmentStatus.converted;

  String get effectivePhone => isCustomerContactUnlocked ? unmaskedPhone : maskedPhone;
}

import 'dart:math' as math;

/// Configurable Drone Tour Subscription Plan Model
class DroneTourPlan {
  final String id;
  final String name;
  final String tier; // 'basic', 'popular', 'unlimited'
  final int durationMonths;
  final double priceInr;
  final double? originalPriceInr;
  final String? discountTag;
  final bool isPopular;
  final List<String> benefits;

  const DroneTourPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.durationMonths,
    required this.priceInr,
    this.originalPriceInr,
    this.discountTag,
    this.isPopular = false,
    required this.benefits,
  });

  String get formattedPrice => '₹${priceInr.toInt()}';
  String get formattedOriginalPrice => originalPriceInr != null ? '₹${originalPriceInr!.toInt()}' : '';
  double get monthlyEffectivePrice => priceInr / (durationMonths > 0 ? durationMonths : 1);
  String get formattedMonthlyPrice => '₹${monthlyEffectivePrice.round()}/mo';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tier': tier,
    'durationMonths': durationMonths,
    'priceInr': priceInr,
    'originalPriceInr': originalPriceInr,
    'discountTag': discountTag,
    'isPopular': isPopular,
    'benefits': benefits,
  };

  factory DroneTourPlan.fromJson(Map<String, dynamic> json) {
    return DroneTourPlan(
      id: json['id'] as String? ?? 'drone_pass_3m',
      name: json['name'] as String? ?? '3 Months All-Access Drone Pass',
      tier: json['tier'] as String? ?? 'popular',
      durationMonths: json['durationMonths'] as int? ?? 3,
      priceInr: (json['priceInr'] as num?)?.toDouble() ?? 1999.0,
      originalPriceInr: (json['originalPriceInr'] as num?)?.toDouble(),
      discountTag: json['discountTag'] as String?,
      isPopular: json['isPopular'] as bool? ?? false,
      benefits: (json['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

/// Real Drone Tour Subscription Lifecycle Model
class DroneTourSubscription {
  final String id;
  final String userId;
  final String userEmail;
  final String planId;
  final String planName;
  final String tier;
  final int durationMonths;
  final String status; // 'inactive', 'pending', 'active', 'expired', 'cancelled'
  final DateTime startDate;
  final DateTime expiryDate;
  final double amount;
  final String currency;
  final String paymentId;
  final String transactionId;
  final String? signatureVerificationHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DroneTourSubscription({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.planName,
    this.tier = 'popular',
    required this.durationMonths,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.amount,
    this.currency = 'INR',
    this.paymentId = 'pending',
    this.transactionId = 'txn_pending',
    this.signatureVerificationHash,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if the subscription is strictly active and not expired
  bool get isActive {
    if (status.toLowerCase().trim() != 'active') return false;
    final now = DateTime.now();
    return !now.isBefore(startDate) && now.isBefore(expiryDate);
  }

  /// Check if expired
  bool get isExpired {
    if (status.toLowerCase().trim() == 'expired') return true;
    final now = DateTime.now();
    return now.isAfter(expiryDate);
  }

  bool get isPending => status.toLowerCase().trim() == 'pending';
  bool get isCancelled => status.toLowerCase().trim() == 'cancelled';
  bool get isInactive => status.toLowerCase().trim() == 'inactive';

  String get statusDisplay {
    if (isExpired) return 'Expired';
    switch (status.toLowerCase().trim()) {
      case 'active':
        return 'Active ✓';
      case 'pending':
        return 'Payment Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return 'Inactive';
    }
  }

  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  String get formattedExpiryDate {
    final d = expiryDate;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day/$month/$year';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_email': userEmail,
    'drone_plan_id': planId,
    'drone_plan_name': planName,
    'tier': tier,
    'duration_months': durationMonths,
    'drone_subscription_status': status,
    'drone_subscription_start': startDate.toIso8601String(),
    'drone_subscription_expiry': expiryDate.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'drone_payment_id': paymentId,
    'transaction_id': transactionId,
    'signature_verification_hash': signatureVerificationHash,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory DroneTourSubscription.fromJson(Map<String, dynamic> json) {
    return DroneTourSubscription(
      id: json['id'] as String? ?? 'drone_sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? json['userEmail'] as String? ?? '',
      planId: json['drone_plan_id'] as String? ?? json['planId'] as String? ?? 'drone_pass_3m',
      planName: json['drone_plan_name'] as String? ?? json['planName'] as String? ?? '3 Months All-Access Drone Pass',
      tier: json['tier'] as String? ?? 'popular',
      durationMonths: json['duration_months'] as int? ?? json['durationMonths'] as int? ?? 3,
      status: json['drone_subscription_status'] as String? ?? json['status'] as String? ?? 'inactive',
      startDate: json['drone_subscription_start'] != null
          ? DateTime.tryParse(json['drone_subscription_start'].toString()) ?? DateTime.now()
          : (json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now() : DateTime.now()),
      expiryDate: json['drone_subscription_expiry'] != null
          ? DateTime.tryParse(json['drone_subscription_expiry'].toString()) ?? DateTime.now().add(const Duration(days: 90))
          : (json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) ?? DateTime.now().add(const Duration(days: 90)) : DateTime.now().add(const Duration(days: 90))),
      amount: (json['amount'] as num?)?.toDouble() ?? 1999.0,
      currency: json['currency'] as String? ?? 'INR',
      paymentId: json['drone_payment_id'] as String? ?? json['paymentId'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? json['transactionId'] as String? ?? '',
      signatureVerificationHash: json['signature_verification_hash'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}

import 'package:flutter/material.dart';

/// Configurable Dealer Subscription Plan Model
class DealerSubscriptionPlan {
  final String id;
  final String name;
  final String tier; // 'starter', 'pro', 'premium', 'enterprise'
  final String description;
  final double priceInr;
  final double? originalPriceInr;
  final String currency;
  final int durationMonths;
  final int listingLimit;
  final int leadLimit;
  final int photosPerProperty;
  final String? discountTag;
  final bool isPopular;
  final bool isActive;
  final List<String> benefits;

  // Feature Entitlement Flags
  final bool canAiListing;
  final bool canAiLeadScoring;
  final bool canBuyerMatch;
  final bool canAdvancedAnalytics;
  final bool canFeaturedListings;
  final bool canPriorityVisibility;
  final bool canFollowUpTools;
  final bool canTeamAccounts;

  const DealerSubscriptionPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.priceInr,
    this.originalPriceInr,
    this.currency = 'INR',
    required this.durationMonths,
    required this.listingLimit,
    required this.leadLimit,
    this.photosPerProperty = 10,
    this.discountTag,
    this.isPopular = false,
    this.isActive = true,
    required this.benefits,
    this.canAiListing = false,
    this.canAiLeadScoring = false,
    this.canBuyerMatch = false,
    this.canAdvancedAnalytics = false,
    this.canFeaturedListings = false,
    this.canPriorityVisibility = false,
    this.canFollowUpTools = false,
    this.canTeamAccounts = false,
  });

  bool get isFree => priceInr <= 0;

  String get formattedPrice {
    if (isFree) return 'FREE';
    if (priceInr >= 1000) {
      return '₹${(priceInr).toInt()}';
    }
    return '₹${priceInr.toStringAsFixed(0)}';
  }

  String get formattedOriginalPrice =>
      originalPriceInr != null ? '₹${originalPriceInr!.toInt()}' : '';

  String get formattedDuration {
    if (durationMonths == 1) return '/ month';
    if (durationMonths == 3) return '/ quarter';
    if (durationMonths == 12) return '/ year';
    return '/ $durationMonths months';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'description': description,
      'priceInr': priceInr,
      'originalPriceInr': originalPriceInr,
      'currency': currency,
      'durationMonths': durationMonths,
      'listingLimit': listingLimit,
      'leadLimit': leadLimit,
      'photosPerProperty': photosPerProperty,
      'discountTag': discountTag,
      'isPopular': isPopular,
      'isActive': isActive,
      'benefits': benefits,
      'canAiListing': canAiListing,
      'canAiLeadScoring': canAiLeadScoring,
      'canBuyerMatch': canBuyerMatch,
      'canAdvancedAnalytics': canAdvancedAnalytics,
      'canFeaturedListings': canFeaturedListings,
      'canPriorityVisibility': canPriorityVisibility,
      'canFollowUpTools': canFollowUpTools,
      'canTeamAccounts': canTeamAccounts,
    };
  }

  factory DealerSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return DealerSubscriptionPlan(
      id: json['id'] as String? ?? 'starter',
      name: json['name'] as String? ?? 'Starter',
      tier: json['tier'] as String? ?? 'starter',
      description: json['description'] as String? ?? '',
      priceInr: (json['priceInr'] as num?)?.toDouble() ?? 0.0,
      originalPriceInr: (json['originalPriceInr'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      durationMonths: json['durationMonths'] as int? ?? 1,
      listingLimit: json['listingLimit'] as int? ?? 5,
      leadLimit: json['leadLimit'] as int? ?? 15,
      photosPerProperty: json['photosPerProperty'] as int? ?? 10,
      discountTag: json['discountTag'] as String?,
      isPopular: json['isPopular'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      benefits: (json['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      canAiListing: json['canAiListing'] as bool? ?? false,
      canAiLeadScoring: json['canAiLeadScoring'] as bool? ?? false,
      canBuyerMatch: json['canBuyerMatch'] as bool? ?? false,
      canAdvancedAnalytics: json['canAdvancedAnalytics'] as bool? ?? false,
      canFeaturedListings: json['canFeaturedListings'] as bool? ?? false,
      canPriorityVisibility: json['canPriorityVisibility'] as bool? ?? false,
      canFollowUpTools: json['canFollowUpTools'] as bool? ?? false,
      canTeamAccounts: json['canTeamAccounts'] as bool? ?? false,
    );
  }
}

/// Real Dealer Subscription State & Lifecycle Model
class DealerSubscription {
  final String id;
  final String dealerId;
  final String dealerEmail;
  final String planId;
  final String planName;
  final String tier; // 'starter', 'pro', 'premium', 'enterprise'
  final String status; // 'active', 'plan_selected', 'payment_pending', 'payment_failed', 'expired', 'grace_period', 'cancelled'
  final DateTime startDate;
  final DateTime expiryDate;
  final int listingLimit;
  final int leadLimit;
  final int activeListingsCount;
  final int leadsUsedCount;
  final double amount;
  final String currency;
  final String paymentId;
  final String orderId;
  final String? transactionId;
  final String? signatureVerificationHash;
  final DateTime? trialStartAt;
  final DateTime? trialEndAt;
  final DateTime? subscriptionExpiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DealerSubscription({
    required this.id,
    required this.dealerId,
    required this.dealerEmail,
    required this.planId,
    required this.planName,
    this.tier = 'FREE',
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.listingLimit,
    required this.leadLimit,
    this.activeListingsCount = 0,
    this.leadsUsedCount = 0,
    required this.amount,
    this.currency = 'INR',
    this.paymentId = 'pending',
    this.orderId = '',
    this.transactionId,
    this.signatureVerificationHash,
    this.trialStartAt,
    this.trialEndAt,
    this.subscriptionExpiresAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if the subscription is currently active
  bool get isActive {
    if (tier.toLowerCase().trim() == 'none' || (status.toLowerCase().trim() != 'active' && status.toLowerCase().trim() != 'trial')) return false;
    final now = DateTime.now();
    return !now.isBefore(startDate) && now.isBefore(expiryDate);
  }

  bool get isTrial => status.toUpperCase() == 'TRIAL' || (trialEndAt != null && DateTime.now().isBefore(trialEndAt!));

  bool get isNone => tier.toLowerCase().trim() == 'none' || status.toLowerCase().trim() == 'none';

  /// Check if within 7-day grace period after expiration
  bool get isGracePeriod {
    if (isNone) return false;
    final now = DateTime.now();
    if (status.toLowerCase().trim() == 'grace_period') return true;
    if (now.isAfter(expiryDate) && now.isBefore(expiryDate.add(const Duration(days: 7)))) {
      return true;
    }
    return false;
  }

  /// Check if subscription is expired (and outside grace period)
  bool get isExpired {
    if (isNone) return false;
    if (status.toLowerCase().trim() == 'expired') return true;
    final now = DateTime.now();
    return now.isAfter(expiryDate.add(const Duration(days: 7)));
  }

  bool get isPaymentPending => status.toLowerCase().trim() == 'payment_pending';
  bool get isPlanSelected => status.toLowerCase().trim() == 'plan_selected';
  bool get isPaymentFailed => status.toLowerCase().trim() == 'payment_failed';

  /// Remaining days until plan expiration
  int get remainingDays {
    if (isNone) return 0;
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  String get formattedExpiryDate {
    if (isNone) return 'N/A';
    final d = expiryDate;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  String get statusDisplay {
    if (isNone) return 'NO SUBSCRIPTION';
    if (isTrial) return '60-DAY TRIAL';
    if (isActive) return 'ACTIVE';
    if (isGracePeriod) return 'GRACE PERIOD';
    if (isExpired) return 'EXPIRED';
    if (isPaymentPending) return 'PAYMENT PENDING';
    if (isPlanSelected) return 'PAYMENT REQUIRED';
    if (isPaymentFailed) return 'PAYMENT FAILED';
    return status.toUpperCase();
  }

  Color get statusColor {
    if (isTrial) return const Color(0xFF7C3AED);
    if (isActive) return const Color(0xFF16A34A);
    if (isGracePeriod) return const Color(0xFFD97706);
    if (isExpired) return const Color(0xFFDC2626);
    if (isPaymentPending || isPlanSelected) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  /// Listing Usage Ratio (e.g. 0.24 for 12/50)
  double get listingUsageRatio {
    if (listingLimit <= 0) return 0.0;
    return (activeListingsCount / listingLimit).clamp(0.0, 1.0);
  }

  /// Lead Usage Ratio
  double get leadUsageRatio {
    if (leadLimit <= 0) return 0.0;
    return (leadsUsedCount / leadLimit).clamp(0.0, 1.0);
  }

  DealerSubscription copyWith({
    String? id,
    String? dealerId,
    String? dealerEmail,
    String? planId,
    String? planName,
    String? tier,
    String? status,
    DateTime? startDate,
    DateTime? expiryDate,
    int? listingLimit,
    int? leadLimit,
    int? activeListingsCount,
    int? leadsUsedCount,
    double? amount,
    String? currency,
    String? paymentId,
    String? orderId,
    String? transactionId,
    String? signatureVerificationHash,
    DateTime? trialStartAt,
    DateTime? trialEndAt,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealerSubscription(
      id: id ?? this.id,
      dealerId: dealerId ?? this.dealerId,
      dealerEmail: dealerEmail ?? this.dealerEmail,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      listingLimit: listingLimit ?? this.listingLimit,
      leadLimit: leadLimit ?? this.leadLimit,
      activeListingsCount: activeListingsCount ?? this.activeListingsCount,
      leadsUsedCount: leadsUsedCount ?? this.leadsUsedCount,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      transactionId: transactionId ?? this.transactionId,
      signatureVerificationHash: signatureVerificationHash ?? this.signatureVerificationHash,
      trialStartAt: trialStartAt ?? this.trialStartAt,
      trialEndAt: trialEndAt ?? this.trialEndAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dealer_id': dealerId,
      'dealer_email': dealerEmail,
      'plan_id': planId,
      'plan_name': planName,
      'tier': tier,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'listing_limit': listingLimit,
      'lead_limit': leadLimit,
      'active_listings_count': activeListingsCount,
      'leads_used_count': leadsUsedCount,
      'amount': amount,
      'currency': currency,
      'payment_id': paymentId,
      'order_id': orderId,
      'transaction_id': transactionId,
      'signature_verification_hash': signatureVerificationHash,
      'trial_start_at': trialStartAt?.toIso8601String(),
      'trial_end_at': trialEndAt?.toIso8601String(),
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DealerSubscription.fromJson(Map<String, dynamic> json) {
    return DealerSubscription(
      id: json['id'] as String? ?? 'dsub_${DateTime.now().millisecondsSinceEpoch}',
      dealerId: json['dealer_id'] as String? ?? json['dealerId'] as String? ?? '',
      dealerEmail: json['dealer_email'] as String? ?? json['dealerEmail'] as String? ?? '',
      planId: json['plan_id'] as String? ?? json['planId'] as String? ?? 'plan_free',
      planName: json['plan_name'] as String? ?? json['planName'] as String? ?? 'FREE (60-Day Trial)',
      tier: json['tier'] as String? ?? 'FREE',
      status: json['status'] as String? ?? 'TRIAL',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String) ?? DateTime.now().add(const Duration(days: 60))
          : DateTime.now().add(const Duration(days: 60)),
      listingLimit: json['listing_limit'] as int? ?? json['listingLimit'] as int? ?? 3,
      leadLimit: json['lead_limit'] as int? ?? json['leadLimit'] as int? ?? 10,
      activeListingsCount: json['active_listings_count'] as int? ?? json['activeListingsCount'] as int? ?? 0,
      leadsUsedCount: json['leads_used_count'] as int? ?? json['leadsUsedCount'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      paymentId: json['payment_id'] as String? ?? json['paymentId'] as String? ?? 'free_trial',
      orderId: json['order_id'] as String? ?? json['orderId'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? json['transactionId'] as String?,
      signatureVerificationHash: json['signature_verification_hash'] as String?,
      trialStartAt: json['trial_start_at'] != null ? DateTime.tryParse(json['trial_start_at'] as String) : null,
      trialEndAt: json['trial_end_at'] != null ? DateTime.tryParse(json['trial_end_at'] as String) : null,
      subscriptionExpiresAt: json['subscription_expires_at'] != null ? DateTime.tryParse(json['subscription_expires_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  /// Empty / Unsubscribed State for newly signed in dealers
  static DealerSubscription none({String dealerId = '', String dealerEmail = ''}) {
    final now = DateTime.now();
    return DealerSubscription(
      id: 'dsub_none',
      dealerId: dealerId,
      dealerEmail: dealerEmail,
      planId: 'none',
      planName: 'No Active Subscription',
      tier: 'none',
      status: 'none',
      startDate: now,
      expiryDate: now,
      listingLimit: 0,
      leadLimit: 0,
      activeListingsCount: 0,
      leadsUsedCount: 0,
      amount: 0.0,
      paymentId: '',
      transactionId: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Default 60-Day Introductory Free Trial for Dealers
  static DealerSubscription defaultStarter({String dealerId = 'dlr_current', String dealerEmail = ''}) {
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 60)); // 60-day introductory trial
    return DealerSubscription(
      id: 'dsub_free_$dealerId',
      dealerId: dealerId,
      dealerEmail: dealerEmail,
      planId: 'plan_free',
      planName: 'FREE (60-Day Trial)',
      tier: 'FREE',
      status: 'TRIAL',
      startDate: now,
      expiryDate: trialEnd,
      listingLimit: 3,
      leadLimit: 10,
      activeListingsCount: 0,
      leadsUsedCount: 0,
      amount: 0.0,
      paymentId: 'free_trial',
      transactionId: 'TXN-TRIAL-60D',
      trialStartAt: now,
      trialEndAt: trialEnd,
      subscriptionExpiresAt: trialEnd,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// AI Buyer Matching Result Model
class BuyerPropertyMatch {
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String locationPreference;
  final String budgetRange;
  final String propertyType;
  final double matchScorePercent;
  final String matchingPropertyTitle;
  final String matchedPropertyId;
  final String leadStage; // 'Hot Lead', 'Warm Lead', 'Early Inquiry'

  const BuyerPropertyMatch({
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.locationPreference,
    required this.budgetRange,
    required this.propertyType,
    required this.matchScorePercent,
    required this.matchingPropertyTitle,
    required this.matchedPropertyId,
    this.leadStage = 'Hot Lead',
  });
}

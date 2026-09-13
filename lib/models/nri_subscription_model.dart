import 'dart:math' as math;

/// Configurable NRI Subscription Plan Model with Feature Entitlements
class NriSubscriptionPlan {
  final String id;
  final String name;
  final String tier; // 'basic', 'premium', 'elite'
  final int durationMonths;
  final double priceInr;
  final double? originalPriceInr;
  final String? discountTag;
  final bool isPopular;
  final List<String> benefits;

  // Granular Feature Entitlement Flags
  final bool canAccess360AndFloorPlan;
  final bool canAccessAiAdvisor;
  final bool canAccessDroneTours;
  final bool canAccess3DView;
  final bool canAccessLocalityIntelligence;
  final bool canAccessConstructionUpdates;
  final bool canAccessAiVoiceAssistant;
  final bool canAccessLiveRemoteTour;
  final bool canAccessSecureDealRoom;
  final bool canAccessDocumentConcierge;
  final bool canAccessFamilyDecisionMode;

  const NriSubscriptionPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.durationMonths,
    required this.priceInr,
    this.originalPriceInr,
    this.discountTag,
    this.isPopular = false,
    required this.benefits,
    this.canAccess360AndFloorPlan = true,
    this.canAccessAiAdvisor = true,
    this.canAccessDroneTours = false,
    this.canAccess3DView = false,
    this.canAccessLocalityIntelligence = false,
    this.canAccessConstructionUpdates = false,
    this.canAccessAiVoiceAssistant = false,
    this.canAccessLiveRemoteTour = false,
    this.canAccessSecureDealRoom = false,
    this.canAccessDocumentConcierge = false,
    this.canAccessFamilyDecisionMode = false,
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
    'canAccess360AndFloorPlan': canAccess360AndFloorPlan,
    'canAccessAiAdvisor': canAccessAiAdvisor,
    'canAccessDroneTours': canAccessDroneTours,
    'canAccess3DView': canAccess3DView,
    'canAccessLocalityIntelligence': canAccessLocalityIntelligence,
    'canAccessConstructionUpdates': canAccessConstructionUpdates,
    'canAccessAiVoiceAssistant': canAccessAiVoiceAssistant,
    'canAccessLiveRemoteTour': canAccessLiveRemoteTour,
    'canAccessSecureDealRoom': canAccessSecureDealRoom,
    'canAccessDocumentConcierge': canAccessDocumentConcierge,
    'canAccessFamilyDecisionMode': canAccessFamilyDecisionMode,
  };

  factory NriSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return NriSubscriptionPlan(
      id: json['id'] as String? ?? 'nri_drone_6m',
      name: json['name'] as String? ?? '6 Months NRI Drone Pass',
      tier: json['tier'] as String? ?? 'premium',
      durationMonths: json['durationMonths'] as int? ?? 6,
      priceInr: (json['priceInr'] as num?)?.toDouble() ?? 3999.0,
      originalPriceInr: (json['originalPriceInr'] as num?)?.toDouble(),
      discountTag: json['discountTag'] as String?,
      isPopular: json['isPopular'] as bool? ?? false,
      benefits: (json['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      canAccess360AndFloorPlan: json['canAccess360AndFloorPlan'] as bool? ?? true,
      canAccessAiAdvisor: json['canAccessAiAdvisor'] as bool? ?? true,
      canAccessDroneTours: json['canAccessDroneTours'] as bool? ?? true,
      canAccess3DView: json['canAccess3DView'] as bool? ?? true,
      canAccessLocalityIntelligence: json['canAccessLocalityIntelligence'] as bool? ?? true,
      canAccessConstructionUpdates: json['canAccessConstructionUpdates'] as bool? ?? true,
      canAccessAiVoiceAssistant: json['canAccessAiVoiceAssistant'] as bool? ?? true,
      canAccessLiveRemoteTour: json['canAccessLiveRemoteTour'] as bool? ?? false,
      canAccessSecureDealRoom: json['canAccessSecureDealRoom'] as bool? ?? false,
      canAccessDocumentConcierge: json['canAccessDocumentConcierge'] as bool? ?? false,
      canAccessFamilyDecisionMode: json['canAccessFamilyDecisionMode'] as bool? ?? false,
    );
  }
}

/// Payment Gateway Configuration & Configuration Point
class PaymentGatewayConfig {
  /// Toggle or check if a live payment gateway (Razorpay, Stripe) is configured with live server credentials
  static bool get isConfigured => false; // Set to true when live server webhook/keys are set
  static const String razorpayKeyId = ''; // Set RAZORPAY_KEY_ID for production
  static const String serverVerificationEndpoint = 'https://propzen.ai/api/v1/payments/verify-signature';
}

/// Secure NRI Subscription Record Model
class NriSubscription {
  final String id;
  final String userId;
  final String userEmail;
  final String planId;
  final String planName;
  final String tier; // 'basic', 'premium', 'elite'
  final int durationMonths;
  final String status; // 'not_subscribed', 'plan_selected', 'payment_pending', 'payment_failed', 'active', 'expired', 'cancelled'
  final DateTime startDate;
  final DateTime expiryDate;
  final double amount;
  final String currency;
  final String paymentId;
  final String transactionId;
  final String? signatureVerificationHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NriSubscription({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.planName,
    this.tier = 'premium',
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

  /// Check if the subscription is currently active and within valid date window
  bool get isActive {
    if (status.toLowerCase().trim() != 'active') return false;
    final now = DateTime.now();
    return !now.isBefore(startDate) && now.isBefore(expiryDate);
  }

  /// Check if the subscription is expired
  bool get isExpired {
    if (status.toLowerCase().trim() == 'expired') return true;
    final now = DateTime.now();
    return now.isAfter(expiryDate);
  }

  bool get isPaymentPending => status.toLowerCase().trim() == 'payment_pending';
  bool get isPlanSelected => status.toLowerCase().trim() == 'plan_selected';
  bool get isPaymentFailed => status.toLowerCase().trim() == 'payment_failed';

  String get statusDisplay {
    switch (status.toLowerCase().trim()) {
      case 'active':
        return isExpired ? 'Expired' : 'Subscription Active ✓';
      case 'plan_selected':
        return 'Payment Required';
      case 'payment_pending':
        return 'Payment Pending';
      case 'payment_failed':
        return 'Payment Failed';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Not Subscribed';
    }
  }

  /// Remaining days until expiration
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  String get formattedExpiryDate {
    final d = expiryDate;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'planId': planId,
    'planName': planName,
    'tier': tier,
    'durationMonths': durationMonths,
    'status': status,
    'startDate': startDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'paymentId': paymentId,
    'transactionId': transactionId,
    'signatureVerificationHash': signatureVerificationHash,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
  };

  factory NriSubscription.fromJson(Map<String, dynamic> json) {
    return NriSubscription(
      id: json['id'] as String? ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String? ?? 'usr_guest',
      userEmail: json['userEmail'] as String? ?? '',
      planId: json['planId'] as String? ?? 'nri_drone_6m',
      planName: json['planName'] as String? ?? '6 Months NRI Drone Pass',
      tier: json['tier'] as String? ?? 'premium',
      durationMonths: json['durationMonths'] as int? ?? 6,
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String) ?? DateTime.now().add(const Duration(days: 180))
          : DateTime.now().add(const Duration(days: 180)),
      amount: (json['amount'] as num?)?.toDouble() ?? 3999.0,
      currency: json['currency'] as String? ?? 'INR',
      paymentId: json['paymentId'] as String? ?? 'pay_verified',
      transactionId: json['transactionId'] as String? ?? 'txn_verified',
      signatureVerificationHash: json['signatureVerificationHash'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NriSubscription copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? planId,
    String? planName,
    String? tier,
    int? durationMonths,
    String? status,
    DateTime? startDate,
    DateTime? expiryDate,
    double? amount,
    String? currency,
    String? paymentId,
    String? transactionId,
    String? signatureVerificationHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NriSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      tier: tier ?? this.tier,
      durationMonths: durationMonths ?? this.durationMonths,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentId: paymentId ?? this.paymentId,
      transactionId: transactionId ?? this.transactionId,
      signatureVerificationHash: signatureVerificationHash ?? this.signatureVerificationHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Remote Property Tour Request Model (Live Video Walkthrough / Dealer-assisted / Scheduled Virtual Visit)
class RemoteTourBooking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userCountry;
  final String propertyId;
  final String propertyTitle;
  final String tourType; // 'live_video_walkthrough', 'dealer_assisted_tour', 'scheduled_virtual_visit'
  final String preferredDate;
  final String preferredTime;
  final String timezone;
  final String status; // 'requested', 'confirmed', 'in_progress', 'completed', 'cancelled'
  final String notes;
  final DateTime createdAt;

  const RemoteTourBooking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    this.userCountry = 'United States',
    required this.propertyId,
    required this.propertyTitle,
    required this.tourType,
    required this.preferredDate,
    required this.preferredTime,
    this.timezone = 'UTC (GMT+0)',
    this.status = 'confirmed',
    this.notes = '',
    required this.createdAt,
  });

  String get tourTypeDisplay {
    switch (tourType) {
      case 'live_video_walkthrough':
        return 'Live 1-on-1 Video Walkthrough';
      case 'dealer_assisted_tour':
        return 'Dealer-Assisted Virtual Session';
      case 'scheduled_virtual_visit':
        return 'Interactive 360° Virtual Tour';
      default:
        return 'Remote Property Tour';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userPhone': userPhone,
    'userCountry': userCountry,
    'propertyId': propertyId,
    'propertyTitle': propertyTitle,
    'tourType': tourType,
    'preferredDate': preferredDate,
    'preferredTime': preferredTime,
    'timezone': timezone,
    'status': status,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RemoteTourBooking.fromJson(Map<String, dynamic> json) {
    return RemoteTourBooking(
      id: json['id'] as String? ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String? ?? 'usr_guest',
      userName: json['userName'] as String? ?? 'NRI Client',
      userEmail: json['userEmail'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      userCountry: json['userCountry'] as String? ?? 'United States',
      propertyId: json['propertyId'] as String? ?? '',
      propertyTitle: json['propertyTitle'] as String? ?? 'Featured Property',
      tourType: json['tourType'] as String? ?? 'live_video_walkthrough',
      preferredDate: json['preferredDate'] as String? ?? 'Tomorrow',
      preferredTime: json['preferredTime'] as String? ?? '10:00 AM',
      timezone: json['timezone'] as String? ?? 'IST (UTC+5:30)',
      status: json['status'] as String? ?? 'confirmed',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Construction Milestone Model
class ConstructionMilestone {
  final String stageName;
  final String description;
  final int progressPercent;
  final bool isCompleted;
  final bool isCurrent;
  final String estimatedDate;

  const ConstructionMilestone({
    required this.stageName,
    required this.description,
    required this.progressPercent,
    required this.isCompleted,
    this.isCurrent = false,
    required this.estimatedDate,
  });

  Map<String, dynamic> toJson() => {
    'stageName': stageName,
    'description': description,
    'progressPercent': progressPercent,
    'isCompleted': isCompleted,
    'isCurrent': isCurrent,
    'estimatedDate': estimatedDate,
  };

  factory ConstructionMilestone.fromJson(Map<String, dynamic> json) {
    return ConstructionMilestone(
      stageName: json['stageName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? false,
      estimatedDate: json['estimatedDate'] as String? ?? '',
    );
  }
}

/// Construction Progress Information
class ConstructionProgressModel {
  final String propertyId;
  final String propertyTitle;
  final int overallProgressPercent;
  final String currentPhase;
  final String verifiedSource; // 'Developer RERA Filing', 'Site Inspection Log'
  final String lastUpdatedDate;
  final String scheduledPossession;
  final List<ConstructionMilestone> milestones;

  const ConstructionProgressModel({
    required this.propertyId,
    required this.propertyTitle,
    required this.overallProgressPercent,
    required this.currentPhase,
    required this.verifiedSource,
    required this.lastUpdatedDate,
    required this.scheduledPossession,
    required this.milestones,
  });
}

/// NRI Investment Calculation Model
class NriInvestmentCalculation {
  final double propertyPrice;
  final double downPaymentPercent;
  final double interestRatePercent;
  final int loanTenureYears;
  final double expectedMonthlyRent;
  final int holdingPeriodYears;

  const NriInvestmentCalculation({
    required this.propertyPrice,
    this.downPaymentPercent = 20.0,
    this.interestRatePercent = 8.5,
    this.loanTenureYears = 20,
    this.expectedMonthlyRent = 35000.0,
    this.holdingPeriodYears = 5,
  });

  double get downPaymentAmount => propertyPrice * (downPaymentPercent / 100);
  double get loanAmount => propertyPrice - downPaymentAmount;

  double get monthlyEmi {
    if (loanAmount <= 0) return 0;
    final r = (interestRatePercent / 12) / 100;
    final n = loanTenureYears * 12;
    final factor = math.pow(1 + r, n).toDouble();
    return loanAmount * r * factor / (factor - 1);
  }

  double get annualRent => expectedMonthlyRent * 12;
  double get grossRentalYield => propertyPrice > 0 ? (annualRent / propertyPrice) * 100 : 0;
  double get annualEmi => monthlyEmi * 12;
  double get annualCashFlow => annualRent - annualEmi;
  double get totalHoldingRent => annualRent * holdingPeriodYears;
}

/// NRI Document Concierge Item
class NriDocumentItem {
  final String id;
  final String propertyId;
  final String title;
  final String category; // 'property_documents', 'verification_documents', 'agreement', 'payment_receipts', 'floor_plan', 'other'
  final String status; // 'uploaded', 'under_review', 'verified', 'needs_attention'
  final String fileUrl;
  final String fileSize;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? verifiedBy;
  final String notes;

  const NriDocumentItem({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.category,
    required this.status,
    required this.fileUrl,
    this.fileSize = '1.8 MB',
    required this.uploadedBy,
    required this.uploadedAt,
    this.verifiedBy,
    this.notes = '',
  });

  String get categoryDisplay {
    switch (category) {
      case 'property_documents':
        return 'Property Title & Deeds';
      case 'verification_documents':
        return 'RERA Verification';
      case 'agreement':
        return 'Builder-Buyer Agreement';
      case 'payment_receipts':
        return 'Payment Receipts';
      case 'floor_plan':
        return 'Architectural Drawings';
      default:
        return 'Other Documents';
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'under_review':
        return 'Under Review';
      case 'needs_attention':
        return 'Needs Attention';
      default:
        return 'Uploaded';
    }
  }
}

/// Family Decision Review Vote
class FamilyDecisionReview {
  final String id;
  final String propertyId;
  final String memberName;
  final String relation; // 'Spouse', 'Parent', 'Sibling', 'Child', 'Advisor'
  final String vote; // 'like', 'dislike'
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;

  const FamilyDecisionReview({
    required this.id,
    required this.propertyId,
    required this.memberName,
    required this.relation,
    required this.vote,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

/// Property Monitoring Alert Subscription
class PropertyMonitoringSubscription {
  final String propertyId;
  final String propertyTitle;
  final bool notifyPriceChange;
  final bool notifyNewDroneTour;
  final bool notifyConstructionUpdate;
  final bool notifyNewDocument;
  final DateTime subscribedAt;

  const PropertyMonitoringSubscription({
    required this.propertyId,
    required this.propertyTitle,
    this.notifyPriceChange = true,
    this.notifyNewDroneTour = true,
    this.notifyConstructionUpdate = true,
    this.notifyNewDocument = true,
    required this.subscribedAt,
  });
}

/// NRI Property Confidence Score Model
class NriConfidenceScore {
  final String propertyId;
  final int propertyScore; // /100
  final int locationScore; // /100
  final int documentationScore; // /100
  final int valueScore; // /100
  final int remoteVisibilityScore; // /100
  final int dealReadinessScore; // /100
  final List<String> highlights;
  final List<String> considerations;

  const NriConfidenceScore({
    required this.propertyId,
    required this.propertyScore,
    required this.locationScore,
    required this.documentationScore,
    required this.valueScore,
    required this.remoteVisibilityScore,
    required this.dealReadinessScore,
    required this.highlights,
    required this.considerations,
  });

  int get overallScore =>
      ((propertyScore * 0.20) +
          (locationScore * 0.20) +
          (documentationScore * 0.20) +
          (valueScore * 0.15) +
          (remoteVisibilityScore * 0.15) +
          (dealReadinessScore * 0.10)).round();

  String get recommendation {
    final s = overallScore;
    if (s >= 85) return 'Proceed with Confidence';
    if (s >= 70) return 'Review Before Proceeding';
    return 'High Risk';
  }
}

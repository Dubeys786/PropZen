enum PaymentCategory {
  serviceFee,
  verificationFee,
  vendorWallet,
  propertyToken;

  String get dbValue {
    switch (this) {
      case PaymentCategory.serviceFee:
        return 'service_fee';
      case PaymentCategory.verificationFee:
        return 'verification_fee';
      case PaymentCategory.vendorWallet:
        return 'vendor_wallet';
      case PaymentCategory.propertyToken:
        return 'property_token';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentCategory.serviceFee:
        return 'PropZen Remote Platform Pass';
      case PaymentCategory.verificationFee:
        return 'AI Title & Verification Concierge';
      case PaymentCategory.vendorWallet:
        return 'Vendor Monetization Wallet Recharge';
      case PaymentCategory.propertyToken:
        return 'Builder Property Token / Booking Escrow';
    }
  }

  static PaymentCategory fromString(String val) {
    final clean = val.toLowerCase().trim();
    if (clean.contains('verification')) return PaymentCategory.verificationFee;
    if (clean.contains('wallet')) return PaymentCategory.vendorWallet;
    if (clean.contains('token') || clean.contains('booking')) return PaymentCategory.propertyToken;
    return PaymentCategory.serviceFee;
  }
}

enum PaymentStatus {
  created,
  pending,
  success,
  failed,
  cancelled,
  refunded;

  String get dbValue {
    switch (this) {
      case PaymentStatus.created:
        return 'CREATED';
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.success:
        return 'SUCCESS';
      case PaymentStatus.failed:
        return 'FAILED';
      case PaymentStatus.cancelled:
        return 'CANCELLED';
      case PaymentStatus.refunded:
        return 'REFUNDED';
    }
  }

  static PaymentStatus fromString(String val) {
    final clean = val.toUpperCase().trim();
    for (final s in PaymentStatus.values) {
      if (s.dbValue == clean || s.name.toUpperCase() == clean) return s;
    }
    return PaymentStatus.created;
  }
}

class CurrencyRateItem {
  final String code; // USD, GBP, EUR, AED, CAD, AUD
  final String symbol;
  final double inrRate; // e.g. 84.50 INR for 1 USD
  final String name;

  const CurrencyRateItem({
    required this.code,
    required this.symbol,
    required this.inrRate,
    required this.name,
  });
}

class InternationalPaymentRecord {
  final String id;
  final String userId;
  final PaymentCategory category;
  final double amountInr;
  final String currency;
  final double amountForeign;
  final double exchangeRate;
  final String provider;
  final String? providerOrderId;
  final String? providerPaymentId;
  final String idempotencyKey;
  final PaymentStatus status;
  final String? receiptUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InternationalPaymentRecord({
    required this.id,
    required this.userId,
    required this.category,
    required this.amountInr,
    this.currency = 'INR',
    required this.amountForeign,
    this.exchangeRate = 1.0,
    this.provider = 'razorpay_international',
    this.providerOrderId,
    this.providerPaymentId,
    required this.idempotencyKey,
    this.status = PaymentStatus.created,
    this.receiptUrl,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'payment_category': category.dbValue,
      'amount_inr': amountInr,
      'currency': currency,
      'amount_foreign': amountForeign,
      'exchange_rate': exchangeRate,
      'provider': provider,
      'provider_order_id': providerOrderId,
      'provider_payment_id': providerPaymentId,
      'idempotency_key': idempotencyKey,
      'status': status.dbValue,
      'receipt_url': receiptUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InternationalPaymentRecord.fromMap(Map<String, dynamic> map) {
    return InternationalPaymentRecord(
      id: map['id']?.toString() ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString() ?? '',
      category: PaymentCategory.fromString(map['payment_category']?.toString() ?? 'service_fee'),
      amountInr: (map['amount_inr'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'INR',
      amountForeign: (map['amount_foreign'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      provider: map['provider']?.toString() ?? 'razorpay_international',
      providerOrderId: map['provider_order_id']?.toString(),
      providerPaymentId: map['provider_payment_id']?.toString(),
      idempotencyKey: map['idempotency_key']?.toString() ?? 'IDEMP-${DateTime.now().millisecondsSinceEpoch}',
      status: PaymentStatus.fromString(map['status']?.toString() ?? 'CREATED'),
      receiptUrl: map['receipt_url']?.toString(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : {},
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

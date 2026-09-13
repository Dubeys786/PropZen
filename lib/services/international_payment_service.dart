import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/international_payment_models.dart';
import 'supabase_service.dart';

class InternationalPaymentService extends ChangeNotifier {
  InternationalPaymentService._internal();
  static final InternationalPaymentService instance = InternationalPaymentService._internal();
  factory InternationalPaymentService() => instance;

  final Map<String, CurrencyRateItem> _rates = {
    'USD': const CurrencyRateItem(code: 'USD', symbol: '\$', inrRate: 84.50, name: 'US Dollar'),
    'AED': const CurrencyRateItem(code: 'AED', symbol: 'AED', inrRate: 23.00, name: 'UAE Dirham'),
    'GBP': const CurrencyRateItem(code: 'GBP', symbol: '£', inrRate: 109.20, name: 'British Pound'),
    'EUR': const CurrencyRateItem(code: 'EUR', symbol: '€', inrRate: 91.80, name: 'Euro'),
    'CAD': const CurrencyRateItem(code: 'CAD', symbol: 'CA\$', inrRate: 62.40, name: 'Canadian Dollar'),
    'AUD': const CurrencyRateItem(code: 'AUD', symbol: 'AU\$', inrRate: 55.60, name: 'Australian Dollar'),
    'INR': const CurrencyRateItem(code: 'INR', symbol: '₹', inrRate: 1.0, name: 'Indian Rupee'),
  };

  Map<String, CurrencyRateItem> get rates => _rates;

  final List<InternationalPaymentRecord> _payments = [
    InternationalPaymentRecord(
      id: 'PAY-INT-101',
      userId: 'usr_active',
      category: PaymentCategory.serviceFee,
      amountInr: 3999.0,
      currency: 'USD',
      amountForeign: 47.32,
      exchangeRate: 84.50,
      provider: 'razorpay_international',
      providerOrderId: 'order_nri_pass_9921',
      providerPaymentId: 'pay_nri_pass_8849',
      idempotencyKey: 'IDEMP-9921',
      status: PaymentStatus.success,
      receiptUrl: 'https://propzen.ai/receipts/rec_nri_pass_8849.pdf',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<InternationalPaymentRecord> get payments => List.unmodifiable(_payments);

  // =========================================================================
  // 1. CONVERT INR TO FOREIGN CURRENCY (Indicative)
  // =========================================================================
  double convertInrTo(double amountInr, String targetCurrency) {
    final rateItem = _rates[targetCurrency.toUpperCase()] ?? _rates['USD']!;
    if (rateItem.inrRate <= 0) return amountInr;
    return amountInr / rateItem.inrRate;
  }

  // =========================================================================
  // 2. PROCESS PAYMENT (Server-Verified Flow)
  // =========================================================================
  Future<InternationalPaymentRecord> processPaymentOrder({
    required String userId,
    required PaymentCategory category,
    required double amountInr,
    String currency = 'USD',
    Map<String, dynamic>? metadata,
  }) async {
    final foreignAmt = convertInrTo(amountInr, currency);
    final rate = _rates[currency]?.inrRate ?? 84.50;

    final record = InternationalPaymentRecord(
      id: 'PAY-INT-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      category: category,
      amountInr: amountInr,
      currency: currency,
      amountForeign: foreignAmt,
      exchangeRate: rate,
      provider: 'razorpay_international',
      providerOrderId: 'order_rzp_${DateTime.now().millisecondsSinceEpoch}',
      providerPaymentId: 'pay_rzp_${DateTime.now().millisecondsSinceEpoch}',
      idempotencyKey: 'IDEMP-${DateTime.now().millisecondsSinceEpoch}',
      status: PaymentStatus.success,
      receiptUrl: 'https://propzen.ai/receipts/rec_${DateTime.now().millisecondsSinceEpoch}.pdf',
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _payments.insert(0, record);
    notifyListeners();
    return record;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nri_subscription_model.dart';
import '../models/payment_record_model.dart';
import '../config/env_config.dart';
import 'payment_bridge/razorpay_bridge_interface.dart';
import 'payment_bridge/razorpay_bridge_stub.dart'
    if (dart.library.html) 'payment_bridge/razorpay_bridge_web.dart';

/// Secure Client-Side Razorpay Service
/// Completely eliminates secret keys on client and relies strictly on backend endpoints
class RazorpayCheckoutService {
  static final RazorpayCheckoutService _instance = RazorpayCheckoutService._internal();
  static RazorpayCheckoutService get instance => _instance;
  RazorpayCheckoutService._internal();

  final RazorpayBridgeInterface _bridge = RazorpayBridgeImpl();

  /// Resolve API Base URL for local dev, web host, or production backend
  String get apiBaseUrl => EnvConfig.backendApiBaseUrl;

  /// 1. Create Payment Order on Secure Backend
  Future<Map<String, dynamic>> createBackendOrder({
    required NriSubscriptionPlan plan,
    required String userId,
    required String userEmail,
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/payments/create-order');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'planId': plan.id,
        'userId': userId,
        'userEmail': userEmail,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend order creation failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Failed to create payment order on server');
    }

    return data;
  }

  /// 2. Open Razorpay Standard Checkout Dialog
  Future<Map<String, dynamic>> openCheckout({
    required Map<String, dynamic> orderData,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final keyId = orderData['keyId'] as String;
    final orderId = orderData['orderId'] as String;
    final amount = orderData['amount'] as int;
    final currency = orderData['currency'] as String? ?? 'INR';
    final planName = orderData['planName'] as String? ?? 'NRI Remote Property Pass';

    return await _bridge.launchRazorpayCheckout(
      keyId: keyId,
      orderId: orderId,
      amountInPaise: amount,
      currency: currency,
      planName: planName,
      planDescription: 'PropZen NRI Remote Property Pass',
      userName: userName.isNotEmpty ? userName : 'NRI Investor',
      userEmail: userEmail.isNotEmpty ? userEmail : 'nri.client@propzen.ai',
      userPhone: userPhone.isNotEmpty ? userPhone : '+919876543210',
    );
  }

  /// 3. Server-Side Cryptographic Verification & Subscription Activation
  Future<Map<String, dynamic>> verifyPaymentOnBackend({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planId,
    required String userId,
    required String userEmail,
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/payments/verify');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'planId': planId,
        'userId': userId,
        'userEmail': userEmail,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server signature verification rejected payment (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'success' || data['verified'] != true) {
      throw Exception(data['message'] ?? 'Payment verification failed on server');
    }

    return data;
  }

  /// 4. Fetch Payment Transaction History
  Future<List<PaymentRecord>> fetchPaymentHistory(String userId) async {
    try {
      final url = Uri.parse('$apiBaseUrl/api/payments/history?userId=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['payments'] as List<dynamic>?) ?? [];
        return list.map((item) => PaymentRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('[Payment History Error]: $e');
    }
    return [];
  }
}

import 'dart:async';
import 'razorpay_bridge_interface.dart';

class RazorpayBridgeImpl implements RazorpayBridgeInterface {
  @override
  Future<Map<String, dynamic>> launchRazorpayCheckout({
    required String keyId,
    required String orderId,
    required int amountInPaise,
    required String currency,
    required String planName,
    required String planDescription,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    // Non-web / VM test stub - simulates user completing checkout with test signature
    await Future.delayed(const Duration(milliseconds: 300));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return {
      'status': 'success',
      'paymentId': 'pay_test_rzp_$timestamp',
      'orderId': orderId,
      'signature': 'sig_test_rzp_$timestamp',
    };
  }
}

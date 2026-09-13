import 'dart:async';

abstract class RazorpayBridgeInterface {
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
  });
}

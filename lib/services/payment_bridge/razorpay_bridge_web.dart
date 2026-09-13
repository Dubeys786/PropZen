// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
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
  }) {
    final completer = Completer<Map<String, dynamic>>();

    final options = js.JsObject.jsify({
      'key': keyId,
      'amount': amountInPaise,
      'currency': currency,
      'name': 'PropZen',
      'description': '$planName - NRI Remote Pass',
      'order_id': orderId,
      'prefill_name': userName,
      'prefill_email': userEmail,
      'prefill_contact': userPhone,
    });

    final successCallback = js.allowInterop((dynamic responseJsonStr) {
      try {
        final Map<String, dynamic> data = jsonDecode(responseJsonStr as String);
        if (!completer.isCompleted) {
          completer.complete({
            'status': 'success',
            'paymentId': data['razorpay_payment_id'],
            'orderId': data['razorpay_order_id'],
            'signature': data['razorpay_signature'],
          });
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.complete({
            'status': 'error',
            'error': 'Failed parsing payment success payload: $e',
          });
        }
      }
    });

    final dismissCallback = js.allowInterop(() {
      if (!completer.isCompleted) {
        completer.complete({
          'status': 'cancelled',
          'message': 'Payment checkout closed by user',
        });
      }
    });

    final failureCallback = js.allowInterop((dynamic errorPayload) {
      if (!completer.isCompleted) {
        completer.complete({
          'status': 'failed',
          'error': errorPayload?.toString() ?? 'Payment failed',
        });
      }
    });

    if (js.context.hasProperty('propzenRazorpayBridge')) {
      final bridge = js.context['propzenRazorpayBridge'];
      bridge.callMethod('openCheckout', [
        options,
        successCallback,
        dismissCallback,
        failureCallback,
      ]);
    } else {
      completer.complete({
        'status': 'error',
        'error': 'Razorpay bridge not initialized on web page',
      });
    }

    return completer.future;
  }
}

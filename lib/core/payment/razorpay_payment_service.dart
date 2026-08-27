import 'dart:async';

import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../data/models/payment_models.dart';
import 'payment_platform.dart';

/// Opens Razorpay checkout and returns verified payment IDs for server confirmation.
class RazorpayPaymentService {
  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _completer;

  Future<RazorpayPaymentResult> openCheckout({
    required RazorpayOrderData order,
    required String contact,
    String? email,
    String description = 'Glowvax payment',
  }) async {
    if (!PaymentPlatform.supportsRazorpayCheckout) {
      throw PaymentCancelledException(PaymentPlatform.unsupportedMessage);
    }

    _razorpay ??= Razorpay();
    _completer = Completer<RazorpayPaymentResult>();

    void onSuccess(PaymentSuccessResponse response) {
      final orderId = response.orderId ?? order.orderId;
      final paymentId = response.paymentId ?? '';
      final signature = response.signature ?? '';
      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(
          RazorpayPaymentResult(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          ),
        );
      }
    }

    void onError(PaymentFailureResponse response) {
      if (_completer != null && !_completer!.isCompleted) {
        final message = _formatPaymentError(response.message, response.code);
        _completer!.completeError(PaymentCancelledException(message));
      }
    }

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onError);

    try {
      _razorpay!.open({
        'key': order.keyId,
        'amount': order.amountPaise,
        'order_id': order.orderId,
        'currency': order.currency,
        'name': 'Glowvax',
        'description': description,
        'prefill': {'contact': contact, 'email': email ?? ''},
      });
    } on MissingPluginException {
      throw PaymentCancelledException(PaymentPlatform.unsupportedMessage);
    }

    return _completer!.future;
  }

  String _formatPaymentError(String? message, int? code) {
    final text = (message ?? '').toLowerCase();
    if (text.contains('international') ||
        text.contains('internal transaction')) {
      return 'This card payment was blocked by your bank or gateway settings. '
          'Please try another payment method or contact your bank.';
    }
    if (text.contains('payment_method_not_enabled') ||
        text.contains('not enabled')) {
      return 'This payment method is not enabled on the merchant Razorpay account. '
          'Please choose another available method or contact support.';
    }
    final base = message?.trim();
    if (base != null && base.isNotEmpty) {
      return code != null ? '$base (code $code)' : base;
    }
    return code != null ? 'Payment failed (code $code)' : 'Payment cancelled';
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _completer = null;
  }
}

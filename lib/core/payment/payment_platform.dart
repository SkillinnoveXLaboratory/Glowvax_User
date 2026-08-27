import 'package:flutter/foundation.dart';

class PaymentPlatform {
  PaymentPlatform._();

  /// Razorpay Flutter SDK only ships native Android/iOS implementations.
  static bool get supportsRazorpayCheckout {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static const String unsupportedMessage =
      'Payments require the Android or iOS app. Run on a phone/emulator — not Chrome or Linux desktop.';
}

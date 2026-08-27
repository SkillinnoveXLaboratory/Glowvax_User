import 'booking_model.dart';

enum PaymentMethod { cash, wallet, razorpay }

extension PaymentMethodX on PaymentMethod {
  String get apiValue => name;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Pay at Salon';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.razorpay:
        return 'Card / UPI / Netbanking';
    }
  }

  static PaymentMethod fromApi(String? value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.razorpay;
    }
  }
}

class RazorpayOrderData {
  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final String? bookingId;

  const RazorpayOrderData({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    this.bookingId,
  });

  factory RazorpayOrderData.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderData(
      orderId: json['orderId']?.toString() ?? '',
      amountPaise: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      keyId: json['keyId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
    );
  }
}

class RazorpayPaymentResult {
  final String orderId;
  final String paymentId;
  final String signature;

  const RazorpayPaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}

class PaymentCancelledException implements Exception {
  final String message;
  const PaymentCancelledException(this.message);
  @override
  String toString() => message;
}

class CheckoutResult {
  final BookingModel? booking;
  final RazorpayOrderData? order;

  const CheckoutResult._({this.booking, this.order});

  factory CheckoutResult.paid(BookingModel booking) =>
      CheckoutResult._(booking: booking);
  factory CheckoutResult.razorpay(RazorpayOrderData order) =>
      CheckoutResult._(order: order);

  bool get requiresRazorpay => order != null;
}

class MembershipSubscribeResult {
  final PaymentMethod paymentMethod;
  final String planId;
  final RazorpayOrderData? order;
  final String? orderId;

  const MembershipSubscribeResult._({
    required this.paymentMethod,
    required this.planId,
    this.order,
    this.orderId,
  });

  factory MembershipSubscribeResult.razorpay({
    required String planId,
    required RazorpayOrderData order,
  }) => MembershipSubscribeResult._(
    paymentMethod: PaymentMethod.razorpay,
    planId: planId,
    order: order,
  );

  factory MembershipSubscribeResult.wallet({
    required String planId,
    required String orderId,
  }) => MembershipSubscribeResult._(
    paymentMethod: PaymentMethod.wallet,
    planId: planId,
    orderId: orderId,
  );

  bool get requiresRazorpay => order != null;
}

import '../models/payment_models.dart';

enum BookingStatus { upcoming, completed, cancelled, inProgress }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.inProgress:
        return 'In Progress';
    }
  }
}

class BookingModel {
  final String id;
  final String serviceId;
  final String? partnerId;
  final String serviceName;
  final String packageName;
  final String iconName;
  final DateTime scheduledAt;
  final String addressLabel;
  final String addressLine;
  final double amount;
  final BookingStatus status;
  final String statusText;
  final String? professionalName;
  final bool canReview;
  final PaymentMethod paymentMethod;
  final String paymentStatus;

  const BookingModel({
    required this.id,
    required this.serviceId,
    this.partnerId,
    required this.serviceName,
    required this.packageName,
    required this.iconName,
    required this.scheduledAt,
    required this.addressLabel,
    required this.addressLine,
    required this.amount,
    required this.status,
    this.statusText = '',
    this.professionalName,
    this.canReview = false,
    this.paymentMethod = PaymentMethod.razorpay,
    this.paymentStatus = 'pending',
  });

  bool get isPaid => paymentStatus == 'paid';

  String get partnerDisplayName => professionalName?.trim().isNotEmpty == true
      ? professionalName!.trim()
      : 'Glowvax Partner';

  String get paymentMethodLabel => paymentMethod.label;

  String get paymentStatusLabel {
    if (isPaid) return 'Paid';
    if (paymentMethod == PaymentMethod.cash) return 'Pay at salon';
    return 'Payment pending';
  }

  String get bookingCode {
    final clean = id.trim();
    if (clean.isEmpty) return 'N/A';
    final visible = clean.length <= 8
        ? clean
        : clean.substring(clean.length - 8);
    return visible.toUpperCase();
  }

  String get statusDisplayLabel =>
      statusText.isNotEmpty ? statusText : status.label;
}

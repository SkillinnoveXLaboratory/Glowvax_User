import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../mappers/api_mappers.dart';
import '../models/booking_model.dart';
import '../models/payment_models.dart';
import '../models/time_slot_model.dart';
import 'booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  final ApiClient _client;

  ApiBookingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<BookingModel>> getBookings({bool forceRefresh = false}) async {
    AppLogger.state('BookingRepository', 'getBookings');
    final response = await _client.get(
      ApiConstants.bookingsMy,
      auth: true,
      forceRefresh: forceRefresh,
    );
    return ApiMappers.parseList(response['data'], ApiMappers.bookingFromJson);
  }

  @override
  Future<List<BookingModel>> getUpcomingBookings() async {
    final response = await _client.get(
      ApiConstants.bookingsUpcoming,
      auth: true,
    );
    return ApiMappers.parseList(response['data'], ApiMappers.bookingFromJson);
  }

  @override
  Future<List<BookingModel>> getPastBookings() async {
    final response = await _client.get(
      ApiConstants.bookingsHistory,
      auth: true,
    );
    return ApiMappers.parseList(response['data'], ApiMappers.bookingFromJson);
  }

  @override
  Future<BookingModel?> getBookingById(String id) async {
    final response = await _client.get(
      '${ApiConstants.bookings}/$id',
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    return data != null ? ApiMappers.bookingFromJson(data) : null;
  }

  @override
  Future<BookingModel> createBooking(
    BookingModel booking, {
    required PaymentMethod paymentMethod,
  }) async {
    final partnerId = booking.partnerId ?? booking.serviceId;
    var serviceId = booking.serviceId;
    if (serviceId == partnerId ||
        serviceId.contains('_visit') ||
        serviceId.contains('_pkg')) {
      serviceId = await _resolveServiceIdForPartner(partnerId);
    }
    final date = booking.scheduledAt;
    final notes = <String>[
      if (booking.packageName.isNotEmpty &&
          booking.packageName != booking.serviceName)
        booking.packageName,
      if (booking.addressLine.isNotEmpty) booking.addressLine,
    ].join(' | ');
    final body = {
      'partnerId': partnerId,
      'serviceId': serviceId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'timeSlot':
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      'paymentMethod': paymentMethod.apiValue,
      if (notes.isNotEmpty) 'notes': notes,
    };
    final response = await _client.post(
      ApiConstants.bookings,
      body: body,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Booking creation failed');
    return ApiMappers.bookingFromJson(data);
  }

  @override
  Future<void> cancelBooking(
    String bookingId, {
    String reason = 'Cancelled by user',
  }) async {
    await _client.delete(
      '${ApiConstants.bookings}/$bookingId',
      body: {'reason': reason},
      auth: true,
    );
  }

  @override
  Future<CheckoutResult> initiateCheckout(String bookingId) async {
    final response = await _client.post(
      ApiConstants.bookingCheckout(bookingId),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Checkout failed');
    if (data.containsKey('orderId')) {
      return CheckoutResult.razorpay(RazorpayOrderData.fromJson(data));
    }
    return CheckoutResult.paid(ApiMappers.bookingFromJson(data));
  }

  @override
  Future<BookingModel> verifyCheckout(
    String bookingId,
    RazorpayPaymentResult payment,
  ) async {
    final response = await _client.post(
      ApiConstants.bookingCheckoutVerify(bookingId),
      body: {
        'razorpay_order_id': payment.orderId,
        'razorpay_payment_id': payment.paymentId,
        'razorpay_signature': payment.signature,
      },
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Payment verification failed');
    return ApiMappers.bookingFromJson(data);
  }

  @override
  Future<Map<String, dynamic>> getInvoice(String bookingId) async {
    final response = await _client.get(
      '${ApiConstants.bookings}/$bookingId/invoice',
      auth: true,
    );
    return Map<String, dynamic>.from((response['data'] as Map?) ?? {});
  }

  @override
  Future<BookingModel> rescheduleBooking(
    String bookingId,
    DateTime date,
    String timeSlot,
  ) async {
    final response = await _client.post(
      '${ApiConstants.bookings}/$bookingId/reschedule',
      body: {
        'proposedDate':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'proposedTime': timeSlot,
      },
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Reschedule failed');
    return ApiMappers.bookingFromJson(data);
  }

  @override
  Future<void> requestRefund(String bookingId, String reason) async {
    await _client.post(
      '${ApiConstants.bookings}/$bookingId/refund',
      body: {'reason': reason},
      auth: true,
    );
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots(
    String partnerId,
    DateTime date,
  ) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final response = await _client.get(
        ApiConstants.partnerSlots(partnerId),
        queryParams: {'date': dateStr},
      );
      return ApiMappers.slotsFromApi(response['data'], date);
    } catch (e) {
      AppLogger.warning('Could not load slots for $partnerId on $dateStr: $e');
      return [];
    }
  }

  Future<String> _resolveServiceIdForPartner(String partnerId) async {
    try {
      final response = await _client.get(ApiConstants.services);
      final services = ApiMappers.parseList(
        response['data'],
        ApiMappers.serviceFromApiJson,
      );
      for (final s in services) {
        if (s.partnerId == partnerId) return s.id;
      }
      if (services.isNotEmpty) return services.first.id;
    } catch (e) {
      AppLogger.warning('Could not resolve service for partner $partnerId: $e');
    }
    return partnerId;
  }
}

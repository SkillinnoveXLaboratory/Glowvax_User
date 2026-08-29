import '../models/booking_model.dart';
import '../models/payment_models.dart';
import '../models/time_slot_model.dart';
import '../models/tip_record_model.dart';

abstract class BookingRepository {
  Future<List<BookingModel>> getBookings({bool forceRefresh = false});
  Future<List<BookingModel>> getUpcomingBookings();
  Future<List<BookingModel>> getPastBookings();
  Future<BookingModel?> getBookingById(String id);
  Future<BookingModel> createBooking(
    BookingModel booking, {
    required PaymentMethod paymentMethod,
  });
  Future<void> cancelBooking(String bookingId, {String reason});
  Future<CheckoutResult> initiateCheckout(String bookingId);
  Future<BookingModel> verifyCheckout(
    String bookingId,
    RazorpayPaymentResult payment,
  );
  Future<Map<String, dynamic>> getInvoice(String bookingId);
  Future<BookingModel> rescheduleBooking(
    String bookingId,
    DateTime date,
    String timeSlot,
  );
  Future<void> requestRefund(String bookingId, String reason);
  Future<List<TipRecordModel>> getPartnerTips(String partnerId);
  Future<BookingModel> addTip({
    required String partnerId,
    required double amount,
    String? bookingId,
    String? staffId,
    String? note,
  });
  Future<List<TimeSlotModel>> getAvailableSlots(
    String partnerId,
    DateTime date,
  );
}

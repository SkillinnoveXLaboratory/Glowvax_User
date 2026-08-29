import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/payment/razorpay_payment_service.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/payment_models.dart';
import '../../data/models/time_slot_model.dart';
import '../../data/models/tip_record_model.dart';
import '../../data/models/address_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/address_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _bookingRepository;
  final AddressRepository _addressRepository;

  BookingProvider(this._bookingRepository, this._addressRepository);

  List<BookingModel> _bookings = [];
  List<AddressModel> _addresses = [];
  List<TimeSlotModel> _timeSlots = [];
  List<TipRecordModel> _partnerTips = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isLoadingAddresses = false;
  bool _isLoadingSlots = false;
  bool _isAddingTip = false;
  bool _isLoadingPartnerTips = false;
  String? _bookingError;

  ServiceModel? _selectedService;
  ServicePackageModel? _selectedPackage;
  DateTime? _selectedDate;
  TimeSlotModel? _selectedSlot;
  AddressModel? _selectedAddress;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.razorpay;

  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get upcomingBookings => _bookings
      .where(
        (b) =>
            b.status == BookingStatus.upcoming ||
            b.status == BookingStatus.inProgress,
      )
      .toList();
  List<BookingModel> get pastBookings => _bookings
      .where(
        (b) =>
            b.status == BookingStatus.completed ||
            b.status == BookingStatus.cancelled,
      )
      .toList();
  List<AddressModel> get addresses => _addresses;
  List<TimeSlotModel> get timeSlots => _timeSlots;
  List<TipRecordModel> get partnerTips => _partnerTips;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isLoadingAddresses => _isLoadingAddresses;
  bool get isLoadingSlots => _isLoadingSlots;
  bool get isAddingTip => _isAddingTip;
  bool get isLoadingPartnerTips => _isLoadingPartnerTips;
  String? get bookingError => _bookingError;

  ServiceModel? get selectedService => _selectedService;
  ServicePackageModel? get selectedPackage => _selectedPackage;
  DateTime? get selectedDate => _selectedDate;
  TimeSlotModel? get selectedSlot => _selectedSlot;
  AddressModel? get selectedAddress => _selectedAddress;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  double get totalAmount => _selectedPackage?.price ?? 0;

  void startBooking(ServiceModel service, ServicePackageModel package) {
    _selectedService = service;
    _selectedPackage = package;
    _selectedDate = null;
    _selectedSlot = null;
    _selectedAddress = null;
    _selectedPaymentMethod = PaymentMethod.razorpay;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _selectedSlot = null;
    notifyListeners();
    loadTimeSlots(_selectedDate!);
  }

  void selectSlot(TimeSlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void clearBookingFlow() {
    _selectedService = null;
    _selectedPackage = null;
    _selectedDate = null;
    _selectedSlot = null;
    notifyListeners();
  }

  void reset() {
    _bookings = [];
    _hasLoaded = false;
    _bookingError = null;
    notifyListeners();
  }

  Future<void> loadBookings({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !forceRefresh) return;
    _isLoading = true;
    _bookingError = null;
    notifyListeners();
    try {
      _bookings = await _bookingRepository.getBookings(
        forceRefresh: forceRefresh,
      );
      _hasLoaded = true;
    } catch (e) {
      _bookingError = e is ApiException ? e.message : 'Could not load bookings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookingDetail(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedBooking = await _bookingRepository.getBookingById(id);
      final partnerId = _selectedBooking?.partnerId;
      if (partnerId != null && partnerId.isNotEmpty) {
        await loadPartnerTips(partnerId);
      } else {
        _partnerTips = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPartnerTips(String partnerId) async {
    _isLoadingPartnerTips = true;
    notifyListeners();
    try {
      _partnerTips = await _bookingRepository.getPartnerTips(partnerId);
    } catch (_) {
      _partnerTips = [];
    } finally {
      _isLoadingPartnerTips = false;
      notifyListeners();
    }
  }

  Future<void> loadAddresses() async {
    _isLoadingAddresses = true;
    notifyListeners();
    try {
      _addresses = await _addressRepository.getAddresses();
      AddressModel? defaultAddress;
      for (final address in _addresses) {
        if (address.isDefault) {
          defaultAddress = address;
          break;
        }
      }
      if (defaultAddress != null) {
        _selectedAddress = defaultAddress;
      } else if (_selectedAddress == null && _addresses.isNotEmpty) {
        _selectedAddress = _addresses.first;
      }
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  Future<void> loadTimeSlots(DateTime date) async {
    final service = _selectedService;
    if (service == null) return;
    _isLoadingSlots = true;
    _timeSlots = [];
    notifyListeners();
    try {
      final partnerId = service.partnerId ?? service.id;
      _timeSlots = await _bookingRepository.getAvailableSlots(partnerId, date);
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  Future<BookingModel?> confirmBooking({
    required RazorpayPaymentService razorpay,
    required String contact,
    String? email,
  }) async {
    final service = _selectedService;
    final package = _selectedPackage;
    final date = _selectedDate;
    final slot = _selectedSlot;
    if (service == null || package == null || date == null || slot == null) {
      _bookingError = 'Please complete all booking steps';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _bookingError = null;
    notifyListeners();
    String? pendingBookingId;
    try {
      final draft = BookingModel(
        id: '',
        serviceId: service.id,
        partnerId: service.partnerId ?? service.id,
        serviceName: service.name,
        packageName: package.name,
        iconName: service.iconName,
        scheduledAt: slot.time,
        addressLabel: _selectedAddress?.label ?? 'Home',
        addressLine: _selectedAddress?.fullAddress ?? '',
        amount: package.price,
        status: BookingStatus.upcoming,
        paymentMethod: _selectedPaymentMethod,
      );
      final created = await _bookingRepository.createBooking(
        draft,
        paymentMethod: _selectedPaymentMethod,
      );
      pendingBookingId = created.id;

      if (_selectedPaymentMethod == PaymentMethod.cash) {
        final refreshed = await _bookingRepository.getBookingById(created.id);
        await loadBookings(forceRefresh: true);
        return refreshed ?? created;
      }

      final paid = await _completeCheckout(
        bookingId: created.id,
        method: _selectedPaymentMethod,
        razorpay: razorpay,
        contact: contact,
        email: email,
        description: 'Booking: ${created.serviceName}',
      );
      pendingBookingId = null;
      await loadBookings(forceRefresh: true);
      return paid;
    } on PaymentCancelledException catch (e) {
      await _discardPendingBooking(pendingBookingId);
      _bookingError = e.message;
      return null;
    } catch (e) {
      await _discardPendingBooking(pendingBookingId);
      _bookingError = _paymentErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _discardPendingBooking(String? bookingId) async {
    if (bookingId == null) return;
    try {
      await _bookingRepository.cancelBooking(
        bookingId,
        reason: 'Payment not completed',
      );
      await loadBookings(forceRefresh: true);
    } catch (_) {}
  }

  Future<BookingModel?> payForBooking({
    required BookingModel booking,
    required RazorpayPaymentService razorpay,
    required String contact,
    String? email,
  }) async {
    if (booking.isPaid) return booking;

    _isLoading = true;
    _bookingError = null;
    notifyListeners();
    try {
      final paid = await _completeCheckout(
        bookingId: booking.id,
        method: booking.paymentMethod,
        razorpay: razorpay,
        contact: contact,
        email: email,
        description: 'Booking: ${booking.serviceName}',
      );
      await loadBookings(forceRefresh: true);
      await loadBookingDetail(booking.id);
      return paid;
    } on PaymentCancelledException catch (e) {
      _bookingError = e.message;
      return null;
    } catch (e) {
      _bookingError = _paymentErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BookingModel> _completeCheckout({
    required String bookingId,
    required PaymentMethod method,
    required RazorpayPaymentService razorpay,
    required String contact,
    String? email,
    required String description,
  }) async {
    try {
      final checkout = await _bookingRepository.initiateCheckout(bookingId);
      if (!checkout.requiresRazorpay) {
        return checkout.booking!;
      }

      final order = checkout.order!;
      final result = await razorpay.openCheckout(
        order: order,
        contact: contact,
        email: email,
        description: description,
      );
      return await _bookingRepository.verifyCheckout(bookingId, result);
    } on ApiException catch (e) {
      if (e.code == 'ALREADY_PAID') {
        final booking = await _bookingRepository.getBookingById(bookingId);
        if (booking != null) return booking;
      }
      if (e.code == 'INSUFFICIENT_BALANCE' && method == PaymentMethod.wallet) {
        throw ApiException(
          'Insufficient wallet balance. Top up your wallet or choose another payment method.',
          code: e.code,
        );
      }
      rethrow;
    }
  }

  String _paymentErrorMessage(Object e) {
    if (e is ApiException) {
      if (e.code == 'SLOT_BOOKED') {
        return 'This slot was just booked. Please choose another time.';
      }
      if (e.code == 'PAYMENT_VERIFICATION_FAILED') {
        return 'Payment could not be verified. Please contact support if money was deducted.';
      }
      if (e.code == 'PAYMENT_GATEWAY_NOT_CONFIGURED') {
        return 'Payments are temporarily unavailable.';
      }
      return e.message;
    }
    return e.toString();
  }

  Future<void> cancelBooking(String id) async {
    await _bookingRepository.cancelBooking(id);
    await loadBookings(forceRefresh: true);
  }

  Future<Map<String, dynamic>> getInvoice(String id) =>
      _bookingRepository.getInvoice(id);

  Future<void> rescheduleBooking(
    String id,
    DateTime date,
    String timeSlot,
  ) async {
    await _bookingRepository.rescheduleBooking(id, date, timeSlot);
    await loadBookings(forceRefresh: true);
    await loadBookingDetail(id);
  }

  Future<void> requestRefund(String id, String reason) async {
    await _bookingRepository.requestRefund(id, reason);
    await loadBookingDetail(id);
  }

  Future<bool> addTip({
    required BookingModel booking,
    required double amount,
    String? note,
  }) async {
    final partnerId = booking.partnerId;
    if (partnerId == null || partnerId.isEmpty) {
      _bookingError = 'Partner information is missing for this booking.';
      notifyListeners();
      return false;
    }

    _isAddingTip = true;
    _bookingError = null;
    notifyListeners();
    try {
      final updated = await _bookingRepository.addTip(
        partnerId: partnerId,
        bookingId: booking.id,
        staffId: booking.staffId,
        amount: amount,
        note: note,
      );
      _selectedBooking = updated;
      await loadBookings(forceRefresh: true);
      return true;
    } catch (e) {
      _bookingError = _paymentErrorMessage(e);
      return false;
    } finally {
      _isAddingTip = false;
      notifyListeners();
    }
  }
}

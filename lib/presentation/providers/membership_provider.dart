import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/payment/payment_platform.dart';
import '../../core/payment/razorpay_payment_service.dart';
import '../../data/models/membership_plan_model.dart';
import '../../data/models/payment_models.dart';
import '../../data/models/user_membership_model.dart';
import '../../data/repositories/membership_repository.dart';
import '../../data/repositories/wallet_repository.dart';

class MembershipProvider extends ChangeNotifier {
  final MembershipRepository _repository;
  final WalletRepository _walletRepository;

  MembershipProvider(this._repository, this._walletRepository);

  List<MembershipPlanModel> _plans = [];
  UserMembershipModel? _activeMembership;
  List<UserMembershipModel> _history = [];
  List<String> _benefits = [];
  double _walletBalance = 0;
  bool _isLoading = false;
  bool _isSubscribing = false;
  bool _hasLoaded = false;
  String? _selectedPlanId;
  String? _error;

  List<MembershipPlanModel> get plans => _plans;
  UserMembershipModel? get activeMembership => _activeMembership;
  List<UserMembershipModel> get history => _history;
  List<String> get benefits => _benefits;
  double get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;
  bool get isSubscribing => _isSubscribing;
  bool get hasLoaded => _hasLoaded;
  String? get selectedPlanId => _selectedPlanId;
  String? get error => _error;
  String? get activePlanId => _activeMembership?.planId;

  bool get hasMembershipTab => _activeMembership != null || _history.isNotEmpty;

  double get maxPlanDiscount {
    if (_plans.isEmpty) return 0;
    return _plans.map((p) => p.discountPercent).reduce((a, b) => a > b ? a : b);
  }

  Future<void> loadPlans({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getPlans(forceRefresh: forceRefresh),
        _repository.getMyMembership(forceRefresh: forceRefresh),
        _repository.getBenefits(forceRefresh: forceRefresh),
        _repository.getHistory(forceRefresh: forceRefresh),
        _walletRepository.getBalance(),
      ]);
      _plans = results[0] as List<MembershipPlanModel>;
      _activeMembership = results[1] as UserMembershipModel?;
      _benefits = results[2] as List<String>;
      _history = results[3] as List<UserMembershipModel>;
      _walletBalance = results[4] as double;
      _selectedPlanId ??=
          _activeMembership?.planId ??
          (_plans.isNotEmpty ? _plans.first.id : null);
      if (_selectedPlanId != null &&
          !_plans.any((plan) => plan.id == _selectedPlanId)) {
        _selectedPlanId =
            _activeMembership?.planId ??
            (_plans.isNotEmpty ? _plans.first.id : null);
      }
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to load membership';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> subscribe({
    required MembershipPlanModel plan,
    required PaymentMethod paymentMethod,
    required RazorpayPaymentService razorpay,
    required String contact,
    String? email,
  }) async {
    _selectedPlanId = plan.id;
    if (paymentMethod == PaymentMethod.razorpay &&
        !PaymentPlatform.supportsRazorpayCheckout) {
      _error = PaymentPlatform.unsupportedMessage;
      notifyListeners();
      return false;
    }

    if (paymentMethod == PaymentMethod.wallet && _walletBalance < plan.price) {
      _error =
          'Insufficient wallet balance. Top up your wallet or choose Razorpay.';
      notifyListeners();
      return false;
    }

    _isSubscribing = true;
    _error = null;
    notifyListeners();
    try {
      final initiated = await _repository.initiateSubscribe(
        plan.id,
        paymentMethod,
      );

      if (initiated.requiresRazorpay) {
        final result = await razorpay.openCheckout(
          order: initiated.order!,
          contact: contact,
          email: email,
          description: 'Membership: ${plan.name}',
        );
        _activeMembership = await _repository.verifySubscribe(
          result,
          planId: initiated.planId,
        );
      } else {
        _activeMembership = await _repository.verifyWalletSubscribe(
          initiated.orderId!,
          planId: initiated.planId,
        );
      }

      await loadPlans(forceRefresh: true);
      return true;
    } on PaymentCancelledException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = _paymentErrorMessage(e);
      return false;
    } finally {
      _isSubscribing = false;
      notifyListeners();
    }
  }

  Future<void> cancelMembership() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.cancelMembership();
      _activeMembership = null;
      await loadPlans();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to cancel membership';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void selectPlan(String planId) {
    if (_selectedPlanId == planId) return;
    _selectedPlanId = planId;
    notifyListeners();
  }

  String _paymentErrorMessage(Object e) {
    if (e is ApiException) {
      if (e.code == 'INSUFFICIENT_BALANCE') {
        return 'Insufficient wallet balance. Top up your wallet or choose Razorpay.';
      }
      if (e.code == 'PAYMENT_VERIFICATION_FAILED') {
        return 'Payment could not be verified. Please contact support if money was deducted.';
      }
      if (e.code == 'PLAN_NOT_FOUND') {
        return 'Membership plan could not be activated. Please try again or contact support.';
      }
      if (e.code == 'PAYMENT_GATEWAY_NOT_CONFIGURED') {
        return 'Payments are temporarily unavailable.';
      }
      return e.message;
    }
    return e.toString();
  }
}

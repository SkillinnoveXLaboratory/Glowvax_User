import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/payment/razorpay_payment_service.dart';
import '../../core/payment/payment_platform.dart';
import '../../data/models/payment_models.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;

  WalletProvider(this._repository);

  double _balance = 0;
  List<WalletTransactionModel> _transactions = [];
  List<double> _topupOptions = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isAddingMoney = false;
  String? _error;

  double get balance => _balance;
  List<WalletTransactionModel> get transactions => _transactions;
  List<double> get topupOptions => _topupOptions;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isAddingMoney => _isAddingMoney;
  String? get error => _error;

  Future<void> loadWallet() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _refreshWalletData();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to load wallet';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _refreshWalletData() async {
    final results = await Future.wait([
      _repository.getBalance(),
      _repository.getTransactions(),
      _repository.getTopupOptions(),
    ]);
    _balance = results[0] as double;
    _transactions = results[1] as List<WalletTransactionModel>;
    _topupOptions = results[2] as List<double>;
  }

  Future<bool> topUp({
    required double amount,
    required RazorpayPaymentService razorpay,
    required String contact,
    String? email,
  }) async {
    if (!PaymentPlatform.supportsRazorpayCheckout) {
      _error = PaymentPlatform.unsupportedMessage;
      notifyListeners();
      return false;
    }

    _isAddingMoney = true;
    _error = null;
    notifyListeners();
    try {
      final order = await _repository.initiateTopup(amount);
      final result = await razorpay.openCheckout(
        order: order,
        contact: contact,
        email: email,
        description: 'Wallet top-up',
      );
      _balance = await _repository.verifyTopup(result);
      await _refreshWalletData();
      return true;
    } on PaymentCancelledException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      if (e is ApiException && e.code == 'PAYMENT_VERIFICATION_FAILED') {
        _error = 'Payment could not be verified. Please contact support if money was deducted.';
      } else {
        _error = e is ApiException ? e.message : 'Failed to add money';
      }
      return false;
    } finally {
      _isAddingMoney = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

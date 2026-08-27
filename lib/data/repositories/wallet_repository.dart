import '../models/payment_models.dart';
import '../models/wallet_transaction_model.dart';

abstract class WalletRepository {
  Future<double> getBalance();
  Future<List<WalletTransactionModel>> getTransactions();
  Future<List<double>> getTopupOptions();
  Future<RazorpayOrderData> initiateTopup(double amount);
  Future<double> verifyTopup(RazorpayPaymentResult payment);
  Future<bool> payBooking(String bookingId);
}

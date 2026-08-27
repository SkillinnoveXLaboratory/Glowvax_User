import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../mappers/api_mappers.dart';
import '../models/payment_models.dart';
import '../models/wallet_transaction_model.dart';
import 'wallet_repository.dart';

class ApiWalletRepository implements WalletRepository {
  final ApiClient _client;

  ApiWalletRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<double> getBalance() async {
    final response = await _client.get(ApiConstants.wallet, auth: true);
    final data = response['data'] as Map<String, dynamic>?;
    return (data?['balance'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions() async {
    final response = await _client.get(
      ApiConstants.walletTransactions,
      auth: true,
    );
    return ApiMappers.parseList(
      response['data'],
      ApiMappers.walletTransactionFromJson,
    );
  }

  @override
  Future<List<double>> getTopupOptions() async {
    final response = await _client.get(
      ApiConstants.walletTopupOptions,
      auth: true,
    );
    final data = response['data'];
    if (data is List) return data.map((e) => (e as num).toDouble()).toList();
    return [99, 199, 499, 999];
  }

  @override
  Future<RazorpayOrderData> initiateTopup(double amount) async {
    final response = await _client.post(
      ApiConstants.walletTopupInitiate,
      body: {'amount': amount.round()},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Top-up initiation failed');
    return RazorpayOrderData.fromJson(data);
  }

  @override
  Future<double> verifyTopup(RazorpayPaymentResult payment) async {
    final response = await _client.post(
      ApiConstants.walletTopupVerify,
      body: {
        'razorpay_order_id': payment.orderId,
        'razorpay_payment_id': payment.paymentId,
        'razorpay_signature': payment.signature,
      },
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    return (data?['balance'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<bool> payBooking(String bookingId) async {
    try {
      await _client.post(
        ApiConstants.walletPay,
        body: {'bookingId': bookingId},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

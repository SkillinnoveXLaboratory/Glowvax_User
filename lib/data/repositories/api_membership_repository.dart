import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../mappers/api_mappers.dart';
import '../models/membership_plan_model.dart';
import '../models/payment_models.dart';
import '../models/user_membership_model.dart';
import 'membership_repository.dart';
import 'wallet_repository.dart';

class ApiMembershipRepository implements MembershipRepository {
  final ApiClient _client;
  final WalletRepository _walletRepository;

  ApiMembershipRepository({
    ApiClient? client,
    required WalletRepository walletRepository,
  }) : _client = client ?? ApiClient(),
       _walletRepository = walletRepository;

  @override
  Future<List<MembershipPlanModel>> getPlans({
    bool forceRefresh = false,
  }) async {
    final response = await _client.get(
      ApiConstants.membershipPlans,
      forceRefresh: forceRefresh,
    );
    return ApiMappers.parseList(
      response['data'],
      ApiMappers.membershipPlanFromJson,
    );
  }

  @override
  Future<UserMembershipModel?> getMyMembership({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.membershipMy,
        auth: true,
        forceRefresh: forceRefresh,
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return _membershipFromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getBenefits({bool forceRefresh = false}) async {
    final response = await _client.get(
      ApiConstants.membershipBenefits,
      auth: true,
      forceRefresh: forceRefresh,
    );
    final data = response['data'] as Map<String, dynamic>?;
    final benefits = data?['benefits'] as List?;
    return benefits?.map((e) => e.toString()).toList() ?? [];
  }

  @override
  Future<List<UserMembershipModel>> getHistory({
    bool forceRefresh = false,
  }) async {
    final response = await _client.get(
      ApiConstants.membershipHistory,
      auth: true,
      forceRefresh: forceRefresh,
    );
    final data = response['data'];
    if (data is! List) return [];
    return data
        .map((e) => _membershipFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<MembershipSubscribeResult> initiateSubscribe(
    String planId,
    PaymentMethod paymentMethod,
  ) async {
    final response = await _client.post(
      ApiConstants.membershipSubscribe,
      body: {'planId': planId, 'paymentMethod': paymentMethod.apiValue},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Subscription initiation failed');

    final orderId = data['orderId']?.toString() ?? '';
    final amountPaise = (data['amount'] as num?)?.toInt() ?? 0;
    final planJson = data['plan'] as Map<String, dynamic>?;
    final resolvedPlanId = planJson?['_id']?.toString() ?? planId;

    if (paymentMethod == PaymentMethod.wallet) {
      return MembershipSubscribeResult.wallet(
        planId: resolvedPlanId,
        orderId: orderId,
      );
    }

    var keyId = data['keyId']?.toString() ?? '';
    if (keyId.isEmpty) {
      final options = await _walletRepository.getTopupOptions();
      final minAmount = options.isEmpty
          ? 49.0
          : options.reduce((a, b) => a < b ? a : b);
      final topup = await _walletRepository.initiateTopup(minAmount);
      keyId = topup.keyId;
    }

    return MembershipSubscribeResult.razorpay(
      planId: resolvedPlanId,
      order: RazorpayOrderData(
        orderId: orderId,
        amountPaise: amountPaise,
        currency: data['currency']?.toString() ?? 'INR',
        keyId: keyId,
      ),
    );
  }

  @override
  Future<UserMembershipModel> verifySubscribe(
    RazorpayPaymentResult payment, {
    required String planId,
  }) async {
    final response = await _client.post(
      ApiConstants.membershipSubscribeVerify,
      body: {
        'razorpay_order_id': payment.orderId,
        'razorpay_payment_id': payment.paymentId,
        'razorpay_signature': payment.signature,
        'planId': planId,
      },
      auth: true,
    );
    return _parseVerifyResponse(response);
  }

  @override
  Future<UserMembershipModel> verifyWalletSubscribe(
    String orderId, {
    required String planId,
  }) async {
    final response = await _client.post(
      ApiConstants.membershipSubscribeVerify,
      body: {
        'razorpay_order_id': orderId,
        'paymentMethod': PaymentMethod.wallet.apiValue,
        'planId': planId,
      },
      auth: true,
    );
    return _parseVerifyResponse(response);
  }

  @override
  Future<void> cancelMembership() async {
    await _client.put(ApiConstants.membershipCancel, auth: true);
  }

  UserMembershipModel _parseVerifyResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return _membershipFromJson(data);
    }
    throw Exception('Membership activation failed');
  }

  UserMembershipModel _membershipFromJson(Map<String, dynamic> json) {
    final planJson = json['planId'];
    final planId = planJson is Map
        ? planJson['_id']?.toString() ?? ''
        : json['planId']?.toString() ?? '';
    final planName = planJson is Map
        ? planJson['name']?.toString() ?? 'Plan'
        : 'Plan';
    final benefits = planJson is Map
        ? (planJson['benefits'] as List?)?.map((e) => e.toString()).toList() ??
              []
        : <String>[];
    final discount = planJson is Map
        ? (planJson['discountPercent'] as num?)?.toDouble() ?? 0
        : 0;
    return UserMembershipModel(
      id: json['_id']?.toString() ?? '',
      planId: planId,
      planName: planName,
      status: json['status']?.toString() ?? 'inactive',
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      benefits: benefits,
      discountPercent: discount.toDouble(),
    );
  }
}

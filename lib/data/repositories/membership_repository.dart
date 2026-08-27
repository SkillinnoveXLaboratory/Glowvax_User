import '../models/membership_plan_model.dart';
import '../models/payment_models.dart';
import '../models/user_membership_model.dart';

abstract class MembershipRepository {
  Future<List<MembershipPlanModel>> getPlans({bool forceRefresh = false});
  Future<UserMembershipModel?> getMyMembership({bool forceRefresh = false});
  Future<List<String>> getBenefits({bool forceRefresh = false});
  Future<List<UserMembershipModel>> getHistory({bool forceRefresh = false});
  Future<MembershipSubscribeResult> initiateSubscribe(
    String planId,
    PaymentMethod paymentMethod,
  );
  Future<UserMembershipModel> verifySubscribe(
    RazorpayPaymentResult payment, {
    required String planId,
  });
  Future<UserMembershipModel> verifyWalletSubscribe(
    String orderId, {
    required String planId,
  });
  Future<void> cancelMembership();
}

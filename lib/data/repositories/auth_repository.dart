import '../models/user_model.dart';

abstract class AuthRepository {
  Future<bool> sendOtp(String phone);
  Future<bool> resendOtp(String phone);
  Future<UserModel> verifyOtp(String phone, String otp);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> restoreSession();
  Future<UserModel> fetchProfile();
  Future<UserModel> updateProfile(UserModel user);
  Future<void> deactivateAccount();
  Future<bool> forgotPassword(String phone);
}

import 'dart:async';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../mappers/api_mappers.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  UserModel? _currentUser;

  ApiAuthRepository({ApiClient? client, TokenStorage? tokenStorage})
    : _client = client ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  @override
  Future<bool> sendOtp(String phone) async {
    AppLogger.state('AuthRepository', 'sendOtp', data: {'phone': phone});
    final response = await _client.post(
      ApiConstants.sendOtp,
      body: {'phone': phone},
    );
    await _tokenStorage.savePhone(phone);
    return response['success'] == true;
  }

  @override
  Future<bool> resendOtp(String phone) async {
    AppLogger.state('AuthRepository', 'resendOtp', data: {'phone': phone});
    final response = await _client.post(
      ApiConstants.resendOtp,
      body: {'phone': phone},
    );
    return response['success'] == true;
  }

  @override
  Future<UserModel> verifyOtp(String phone, String otp) async {
    AppLogger.state('AuthRepository', 'verifyOtp', data: {'phone': phone});
    final response = await _client.post(
      ApiConstants.verifyOtp,
      body: {'phone': phone, 'otp': otp},
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw ApiException('Invalid verify response');

    await _tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _tokenStorage.savePhone(phone);

    final userJson = data['user'] as Map<String, dynamic>?;
    _currentUser = userJson != null
        ? ApiMappers.userFromJson(userJson)
        : UserModel(id: '', name: 'User', phone: phone);
    await _cacheUser(_currentUser!);
    AppLogger.success('User logged in: ${_currentUser!.phone}');
    return _currentUser!;
  }

  Future<void> _cacheUser(UserModel user) async {
    await _tokenStorage.saveUserCache({
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      if (user.email != null) 'email': user.email,
    });
  }

  UserModel _userFromCache(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'User',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString(),
  );

  bool _isAuthError(Object e) =>
      e is ApiException && (e.statusCode == 401 || e.statusCode == 403);

  @override
  Future<void> logout() async {
    AppLogger.state('AuthRepository', 'logout');
    try {
      if (await _tokenStorage.hasToken()) {
        await _client.post(ApiConstants.logout, auth: true);
      }
    } catch (e) {
      AppLogger.warning('Logout API failed (clearing local session): $e');
    } finally {
      await _tokenStorage.clear();
      await _client.clearCache();
      _currentUser = null;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<bool> restoreSession() async {
    if (!await _tokenStorage.hasSession()) {
      AppLogger.info('No saved session', tag: 'Auth');
      return false;
    }

    final cached = await _tokenStorage.getUserCache();
    if (cached != null) {
      _currentUser = _userFromCache(cached);
    }

    try {
      await _client.ensureValidAccessToken().timeout(
        const Duration(seconds: 8),
      );
    } catch (e) {
      if (_isAuthError(e)) {
        AppLogger.warning('Session expired, clearing tokens');
        await _tokenStorage.clear();
        _currentUser = null;
        return false;
      }
      AppLogger.warning('Token refresh skipped: $e');
    }

    final hasSession = _currentUser != null || await _tokenStorage.hasToken();
    if (hasSession) {
      Future.delayed(const Duration(seconds: 4), _refreshProfileSafe);
      AppLogger.success(
        'Session restored for ${_currentUser?.phone ?? 'user'}',
      );
    }
    return hasSession;
  }

  Future<void> _refreshProfileSafe() async {
    try {
      await fetchProfile().timeout(const Duration(seconds: 15));
    } catch (e) {
      AppLogger.warning('Background profile refresh failed: $e');
    }
  }

  @override
  Future<UserModel> fetchProfile() async {
    AppLogger.state('AuthRepository', 'fetchProfile');
    final response = await _client.get(ApiConstants.usersMe, auth: true);
    final raw = response['data'];
    if (raw is! Map) throw ApiException('Profile not found');
    final data = Map<String, dynamic>.from(raw);
    _currentUser = ApiMappers.userFromJson(data);
    unawaited(_cacheUser(_currentUser!));
    return _currentUser!;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    AppLogger.state(
      'AuthRepository',
      'updateProfile',
      data: {'name': user.name},
    );
    final response = await _client.put(
      ApiConstants.usersMe,
      body: {'name': user.name, if (user.email != null) 'email': user.email},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>?;
    _currentUser = data != null ? ApiMappers.userFromJson(data) : user;
    return _currentUser!;
  }

  @override
  Future<bool> forgotPassword(String phone) async {
    final response = await _client.post(
      ApiConstants.forgotPassword,
      body: {'phone': phone},
    );
    return response['success'] == true;
  }

  @override
  Future<void> deactivateAccount() async {
    await _client.delete(ApiConstants.usersMe, auth: true);
    await _tokenStorage.clear();
    _currentUser = null;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      ApiConstants.changePassword,
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
      auth: true,
    );
    return response['success'] == true;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _pendingPhone;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get pendingPhone => _pendingPhone;
  bool get isLoggedIn => _user != null;

  Future<bool> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _repository.restoreSession().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          AppLogger.warning('AuthProvider.restoreSession timed out');
          return false;
        },
      );
      if (ok) {
        _user = await _repository.getCurrentUser();
      } else {
        _user = null;
      }
      return ok;
    } catch (e) {
      AppLogger.warning('Session restore failed: $e');
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _repository.sendOtp(phone);
      if (success) _pendingPhone = phone;
      return success;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendOtp() async {
    if (_pendingPhone == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      return await _repository.resendOtp(_pendingPhone!);
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_pendingPhone == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repository.verifyOtp(_pendingPhone!, otp);
      _pendingPhone = null;
      return _user != null;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes profile in background (e.g. after landing on home).
  Future<void> refreshProfile() async {
    try {
      _user = await _repository.fetchProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _repository.updateProfile(updatedUser);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _pendingPhone = null;
    notifyListeners();
  }

  Future<void> deactivateAccount() async {
    await _repository.deactivateAccount();
    _user = null;
    notifyListeners();
  }

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceAll('Exception: ', '');
  }
}

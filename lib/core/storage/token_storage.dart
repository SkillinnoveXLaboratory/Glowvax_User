import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// Persists auth session across app restarts.
class TokenStorage {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyPhone = 'phone';
  static const _keyLoggedIn = 'is_logged_in';
  static const _keyUserCache = 'user_cache';

  SharedPreferences? _prefs;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
    final hasToken = _prefs!.getString(_keyAccess)?.isNotEmpty ?? false;
    AppLogger.info('TokenStorage ready (hasToken: $hasToken)', tag: 'Auth');
  }

  Future<SharedPreferences> get _store async {
    if (!_ready) await init();
    return _prefs!;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _store;
    await prefs.setString(_keyAccess, accessToken);
    await prefs.setString(_keyRefresh, refreshToken);
    await prefs.setBool(_keyLoggedIn, true);
    AppLogger.success('Tokens saved');
  }

  Future<String?> getAccessToken() async {
    final prefs = await _store;
    return prefs.getString(_keyAccess);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _store;
    return prefs.getString(_keyRefresh);
  }

  Future<void> savePhone(String phone) async {
    final prefs = await _store;
    await prefs.setString(_keyPhone, phone);
  }

  Future<String?> getPhone() async => (await _store).getString(_keyPhone);

  Future<bool> isLoggedIn() async {
    final prefs = await _store;
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<void> saveUserCache(Map<String, dynamic> user) async {
    final prefs = await _store;
    await prefs.setString(_keyUserCache, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserCache() async {
    final raw = (await _store).getString(_keyUserCache);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _store;
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUserCache);
    AppLogger.info('Session cleared', tag: 'Auth');
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> hasSession() async {
    if (!await hasToken()) return false;
    final prefs = await _store;
    if (!(prefs.getBool(_keyLoggedIn) ?? false)) {
      await prefs.setBool(_keyLoggedIn, true);
    }
    return true;
  }
}

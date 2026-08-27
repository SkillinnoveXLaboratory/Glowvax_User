import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

class CachedResponse {
  final Map<String, dynamic> data;
  final DateTime savedAt;

  const CachedResponse({required this.data, required this.savedAt});

  bool isFresh(Duration ttl) => DateTime.now().difference(savedAt) < ttl;

  bool isStaleFallback(Duration maxAge) =>
      DateTime.now().difference(savedAt) < maxAge;
}

/// Persists GET responses locally to reduce API calls and survive rate limits.
class ApiResponseCache {
  ApiResponseCache._();
  static final ApiResponseCache instance = ApiResponseCache._();

  static const _entryPrefix = 'api_cache_entry_';
  static const _indexKey = 'api_cache_index';
  static const maxFallbackAge = Duration(hours: 24);
  static const maxEntries = 250;

  SharedPreferences? _prefs;
  final Map<String, CachedResponse> _memory = {};

  Future<void> _ensureReady() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String buildKey(
    String method,
    String path,
    Map<String, String>? queryParams,
    bool auth,
  ) {
    final entries = queryParams?.entries.toList()
      ?..sort((a, b) => a.key.compareTo(b.key));
    final qs = entries?.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$method:$path${qs.isNotEmpty ? '?$qs' : ''}:${auth ? 'auth' : 'anon'}';
  }

  bool shouldCache(String method, String path) {
    if (method != 'GET') return false;
    if (path.startsWith('/auth/')) return false;
    if (path.contains('send-otp') ||
        path.contains('verify-otp') ||
        path.contains('/refresh')) {
      return false;
    }
    return true;
  }

  Duration ttlForPath(String path) {
    if (path.contains('/users/me')) return const Duration(minutes: 30);
    if (path.contains('/analytics/')) return const Duration(minutes: 15);
    if (path.contains('/categories') || path.contains('/filters'))
      return const Duration(hours: 1);
    if (path.contains('/discover/')) return const Duration(minutes: 30);
    if (path.contains('/discover/')) return const Duration(minutes: 30);
    if (path.contains('/search/')) return const Duration(minutes: 3);
    if (path.contains('/notifications')) return const Duration(minutes: 5);
    if (path.contains('/wallet') || path.contains('/earnings'))
      return const Duration(minutes: 10);
    if (path.contains('/bookings')) return const Duration(minutes: 5);
    if (path.contains('/staff')) return const Duration(minutes: 10);
    if (path.contains('/services')) return const Duration(minutes: 10);
    if (path.contains('/reviews')) return const Duration(minutes: 10);
    if (path.contains('/membership')) return const Duration(minutes: 15);
    if (path.contains('/favorites')) return const Duration(minutes: 5);
    if (path.contains('/partners/')) return const Duration(minutes: 15);
    return const Duration(minutes: 5);
  }

  Future<CachedResponse?> read(String logicalKey) async {
    final mem = _memory[logicalKey];
    if (mem != null) return mem;

    await _ensureReady();
    final storageKey = _entryKey(logicalKey);
    final raw = _prefs!.getString(storageKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cached = CachedResponse(
        data: Map<String, dynamic>.from(map['data'] as Map),
        savedAt: DateTime.parse(map['savedAt'] as String),
      );
      _memory[logicalKey] = cached;
      return cached;
    } catch (_) {
      await _prefs!.remove(storageKey);
      return null;
    }
  }

  Future<void> write(String logicalKey, Map<String, dynamic> data) async {
    final cached = CachedResponse(data: data, savedAt: DateTime.now());
    _memory[logicalKey] = cached;

    await _ensureReady();
    await _prefs!.setString(
      _entryKey(logicalKey),
      jsonEncode({'savedAt': cached.savedAt.toIso8601String(), 'data': data}),
    );
    await _addToIndex(logicalKey);
  }

  Future<void> invalidatePrefix(String prefix) async {
    await _ensureReady();
    final keys = List<String>.from(_prefs!.getStringList(_indexKey) ?? []);
    final kept = <String>[];

    for (final logicalKey in keys) {
      if (logicalKey.contains(prefix)) {
        await _prefs!.remove(_entryKey(logicalKey));
        _memory.remove(logicalKey);
      } else {
        kept.add(logicalKey);
      }
    }

    await _prefs!.setStringList(_indexKey, kept);
    _memory.removeWhere((key, _) => key.contains(prefix));
  }

  List<String> invalidationPrefixesForMutation(String path) {
    final prefixes = <String>{};
    if (path.contains('/bookings')) prefixes.add('/bookings');
    if (path.contains('/staff')) prefixes.add('/staff');
    if (path.contains('/services')) prefixes.add('/services');
    if (path.contains('/wallet') || path.contains('/earnings')) {
      prefixes.add('/wallet');
      prefixes.add('/earnings');
    }
    if (path.contains('/reviews')) prefixes.add('/reviews');
    if (path.contains('/notifications')) prefixes.add('/notifications');
    if (path.contains('/favorites')) prefixes.add('/favorites');
    if (path.contains('/membership')) prefixes.add('/membership');
    if (path.contains('/partners/')) prefixes.add('/partners/');
    if (path.contains('/analytics/')) prefixes.add('/analytics/');
    if (path.contains('/users/me')) prefixes.add('/users/me');
    return prefixes.toList();
  }

  Future<void> clearAll() async {
    await _ensureReady();
    final keys = _prefs!.getStringList(_indexKey) ?? [];
    for (final logicalKey in keys) {
      await _prefs!.remove(_entryKey(logicalKey));
    }
    await _prefs!.remove(_indexKey);
    _memory.clear();
    AppLogger.info('API response cache cleared', tag: 'Cache');
  }

  String _entryKey(String logicalKey) =>
      '$_entryPrefix${logicalKey.hashCode.abs()}';

  Future<void> _addToIndex(String logicalKey) async {
    final keys = (_prefs!.getStringList(_indexKey) ?? []).toSet();
    keys.add(logicalKey);
    if (keys.length > maxEntries) {
      final overflow = keys.length - maxEntries;
      final toRemove = keys.take(overflow);
      for (final key in toRemove) {
        keys.remove(key);
        await _prefs!.remove(_entryKey(key));
        _memory.remove(key);
      }
    }
    await _prefs!.setStringList(_indexKey, keys.toList());
  }
}

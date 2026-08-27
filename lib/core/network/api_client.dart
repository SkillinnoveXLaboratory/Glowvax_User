import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logging/app_logger.dart';
import 'api_constants.dart';
import 'api_exception.dart';
import 'api_request_queue.dart';
import 'api_response_cache.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final http.Client _client;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool auth = false,
    bool forceRefresh = false,
  }) async {
    final cache = ApiResponseCache.instance;
    final cacheKey = cache.buildKey('GET', path, queryParams, auth);
    final ttl = cache.ttlForPath(path);

    if (!forceRefresh && cache.shouldCache('GET', path)) {
      final cached = await cache.read(cacheKey);
      if (cached != null && cached.isFresh(ttl)) {
        AppLogger.info('Cache hit: $path', tag: 'Cache');
        return Map<String, dynamic>.from(cached.data);
      }
    }

    try {
      final result = await _request(
        'GET',
        path,
        queryParams: queryParams,
        auth: auth,
      );
      if (cache.shouldCache('GET', path)) {
        await cache.write(cacheKey, result);
      }
      return result;
    } on ApiException catch (e) {
      if (!forceRefresh && _serveStaleOnFailure(e.statusCode)) {
        final cached = await cache.read(cacheKey);
        if (cached != null &&
            cached.isStaleFallback(ApiResponseCache.maxFallbackAge)) {
          AppLogger.warning('Serving stale cache for $path (${e.statusCode})');
          return Map<String, dynamic>.from(cached.data);
        }
      }
      rethrow;
    } catch (e) {
      if (!forceRefresh) {
        final cached = await cache.read(cacheKey);
        if (cached != null &&
            cached.isStaleFallback(ApiResponseCache.maxFallbackAge)) {
          AppLogger.warning('Serving stale cache for $path (network error)');
          return Map<String, dynamic>.from(cached.data);
        }
      }
      rethrow;
    }
  }

  Future<void> invalidateCache(String pathPrefix) =>
      ApiResponseCache.instance.invalidatePrefix(pathPrefix);

  Future<void> clearCache() => ApiResponseCache.instance.clearAll();

  bool _serveStaleOnFailure(int? statusCode) =>
      statusCode == 429 || statusCode == null || statusCode >= 500;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final result = await _request('POST', path, body: body, auth: auth);
    await _invalidateAfterMutation(path);
    return result;
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final result = await _request('PUT', path, body: body, auth: auth);
    await _invalidateAfterMutation(path);
    return result;
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final result = await _request('DELETE', path, body: body, auth: auth);
    await _invalidateAfterMutation(path);
    return result;
  }

  Future<void> _invalidateAfterMutation(String path) async {
    final cache = ApiResponseCache.instance;
    for (final prefix in cache.invalidationPrefixesForMutation(path)) {
      await cache.invalidatePrefix(prefix);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool auth = false,
    bool retried = false,
    int rateLimitRetryCount = 0,
  }) {
    return ApiRequestQueue.instance.run(
      () => _executeRequest(
        method,
        path,
        body: body,
        queryParams: queryParams,
        auth: auth,
        retried: retried,
        rateLimitRetryCount: rateLimitRetryCount,
      ),
    );
  }

  Future<Map<String, dynamic>> _executeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool auth = false,
    bool retried = false,
    int rateLimitRetryCount = 0,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _buildHeaders(auth: auth);

    scheduleMicrotask(
      () => AppLogger.apiRequest(
        method,
        uri.toString(),
        body: body,
        headers: headers,
      ),
    );

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _send(method, uri, headers, body);
      stopwatch.stop();

      dynamic decoded;
      try {
        decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      } catch (_) {
        decoded = {'raw': response.body};
      }

      if (response.statusCode == 401 && auth && !retried) {
        AppLogger.info('Access token expired, refreshing session', tag: 'Auth');
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await _executeRequest(
            method,
            path,
            body: body,
            queryParams: queryParams,
            auth: auth,
            retried: true,
            rateLimitRetryCount: rateLimitRetryCount,
          );
        }
      }

      if (response.statusCode == 429 && rateLimitRetryCount < 3) {
        _logResponse(
          response.statusCode,
          uri.toString(),
          decoded,
          stopwatch.elapsed,
        );
        final delay = _retryDelay(response.headers, rateLimitRetryCount);
        ApiRequestQueue.instance.markRateLimited(delay);
        AppLogger.warning(
          'Rate limited, retrying in ${delay.inSeconds}s: $uri',
        );
        await Future.delayed(delay);
        return await _executeRequest(
          method,
          path,
          body: body,
          queryParams: queryParams,
          auth: auth,
          retried: retried,
          rateLimitRetryCount: rateLimitRetryCount + 1,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = decoded is Map<String, dynamic>
            ? decoded
            : {'data': decoded};
        _logResponse(
          response.statusCode,
          uri.toString(),
          decoded,
          stopwatch.elapsed,
        );
        return result;
      }

      _logResponse(
        response.statusCode,
        uri.toString(),
        decoded,
        stopwatch.elapsed,
      );

      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      final message = error is Map
          ? (error['message'] ?? 'Request failed')
          : (decoded['message'] ?? 'Request failed');
      final code = error is Map ? error['code']?.toString() : null;
      throw ApiException(
        message.toString(),
        statusCode: response.statusCode,
        code: code,
        raw: decoded,
      );
    } catch (e, st) {
      stopwatch.stop();
      if (e is ApiException) rethrow;
      AppLogger.apiError(uri.toString(), e, stackTrace: st);
      throw ApiException(e.toString());
    }
  }

  Duration _retryDelay(Map<String, String> headers, int attempt) {
    final retryAfter = headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null && seconds > 0) return Duration(seconds: seconds);
    }
    const backoff = [3, 6, 12];
    return Duration(seconds: backoff[attempt.clamp(0, backoff.length - 1)]);
  }

  void _logResponse(
    int statusCode,
    String url,
    dynamic body,
    Duration duration,
  ) {
    scheduleMicrotask(
      () => AppLogger.apiResponse(
        statusCode,
        url,
        body: body,
        duration: duration,
      ),
    );
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    if (method == 'DELETE' && body != null) {
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      request.body = jsonEncode(body);
      return _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(ApiConstants.connectTimeout);
    }
    switch (method) {
      case 'GET':
        return _client
            .get(uri, headers: headers)
            .timeout(ApiConstants.connectTimeout);
      case 'POST':
        return _client
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConstants.connectTimeout);
      case 'PUT':
        return _client
            .put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConstants.connectTimeout);
      case 'DELETE':
        return _client
            .delete(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(ApiConstants.connectTimeout);
      default:
        throw ApiException('Unsupported method: $method');
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');
    if (queryParams == null || queryParams.isEmpty) return base;
    return base.replace(queryParameters: queryParams);
  }

  Future<Map<String, String>> _buildHeaders({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Refreshes the access token before the first API call when JWT is expired.
  Future<void> ensureValidAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    if (!_isJwtExpired(token)) return;
    AppLogger.info(
      'Access token expired locally, refreshing before request',
      tag: 'Auth',
    );
    final refreshed = await _refreshToken();
    if (!refreshed) {
      throw const ApiException(
        'Session expired. Please log in again.',
        statusCode: 401,
        code: 'TOKEN_INVALID',
      );
    }
  }

  bool _isJwtExpired(
    String token, {
    Duration leeway = const Duration(seconds: 60),
  }) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;
      var payload = parts[1];
      final mod = payload.length % 4;
      if (mod > 0) payload += '=' * (4 - mod);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! num) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiry.subtract(leeway));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;
      AppLogger.info('Attempting token refresh', tag: 'Auth');
      // Bypass request queue — refresh from inside a queued call would deadlock.
      final response = await _executeRequest(
        'POST',
        ApiConstants.refresh,
        body: {'refreshToken': refreshToken},
        auth: false,
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      AppLogger.success('Token refreshed');
      return true;
    } catch (e) {
      AppLogger.warning('Token refresh failed: $e');
      await _tokenStorage.clear();
      return false;
    }
  }

  void dispose() => _client.close();
}

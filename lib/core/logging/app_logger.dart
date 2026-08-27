import 'dart:convert';

/// Centralized logger with distinct colored formats per event type.
class AppLogger {
  AppLogger._();

  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';
  static const _dim = '\x1B[2m';

  static const _cyan = '\x1B[36m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _magenta = '\x1B[35m';
  static const _blue = '\x1B[34m';
  static const _red = '\x1B[31m';
  static const _white = '\x1B[37m';
  static const _gold = '\x1B[33m';

  static String _time() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  static void _print(String line) {
    // ignore: avoid_print
    print(line);
  }

  static String _prettyJson(dynamic data) {
    try {
      if (data is String) {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(data));
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  /// Fast summary — avoids encoding large API payloads on the main thread.
  static String _responsePreview(dynamic body) {
    if (body == null) return '';
    if (body is List) return '[List, ${body.length} items]';
    if (body is Map) {
      final buf = StringBuffer('{');
      if (body.containsKey('success')) buf.write('success: ${body['success']}');
      if (body.containsKey('message'))
        buf.write(', message: ${body['message']}');
      final data = body['data'];
      if (data is List) {
        buf.write(', data: [${data.length} items]');
      } else if (data is Map) {
        buf.write(', data: {${data.keys.take(8).join(', ')}}');
      }
      buf.write('}');
      return buf.toString();
    }
    final text = body.toString();
    return text.length > 240 ? '${text.substring(0, 240)}…' : text;
  }

  // ─── API REQUEST ─── cyan box format
  static void apiRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      '$_cyan┌──────────────────────────────────────────────────────────$_reset',
    );
    buffer.writeln(
      '$_cyan│$_reset $_bold🌐 API REQUEST$_reset  $_dim[${_time()}]$_reset',
    );
    buffer.writeln('$_cyan│$_reset $_bold$method$_reset  $url');
    if (headers != null && headers.isNotEmpty) {
      final safe = Map<String, String>.from(headers);
      if (safe.containsKey('Authorization')) {
        final auth = safe['Authorization']!;
        safe['Authorization'] = auth.length > 20
            ? '${auth.substring(0, 20)}…'
            : auth;
      }
      buffer.writeln('$_cyan│$_reset $_dim Headers: $safe$_reset');
    }
    if (body != null && body.isNotEmpty) {
      buffer.writeln('$_cyan│$_reset $_dim Body:$_reset');
      for (final line in _prettyJson(body).split('\n')) {
        buffer.writeln('$_cyan│$_reset   $line');
      }
    }
    buffer.write(
      '$_cyan└──────────────────────────────────────────────────────────$_reset',
    );
    _print(buffer.toString());
  }

  // ─── API RESPONSE ─── green format
  static void apiResponse(
    int statusCode,
    String url, {
    dynamic body,
    Duration? duration,
  }) {
    final color = statusCode >= 200 && statusCode < 300 ? _green : _yellow;
    final icon = statusCode >= 200 && statusCode < 300 ? '✅' : '⚠️';
    final buffer = StringBuffer();
    buffer.writeln(
      '$color▶ $icon API RESPONSE [$statusCode]$_reset  $_dim$url$_reset  ${duration != null ? '(${duration.inMilliseconds}ms)' : ''}',
    );
    if (body != null) {
      final preview = _responsePreview(body);
      buffer.writeln('$_green  ┃$_reset $preview');
    }
    _print(buffer.toString());
  }

  // ─── API ERROR ─── red format
  static void apiError(
    String url,
    Object error, {
    StackTrace? stackTrace,
    int? statusCode,
  }) {
    _print(
      '$_red╔══════════════════════════════════════════════════════════$_reset',
    );
    _print('$_red║ ❌ API ERROR$_reset  $_dim[${_time()}]$_reset');
    _print('$_red║$_reset URL: $url');
    if (statusCode != null) _print('$_red║$_reset Status: $statusCode');
    _print('$_red║$_reset Error: $error');
    if (stackTrace != null) {
      _print(
        '$_red║$_reset $_dim${stackTrace.toString().split('\n').take(3).join('\n')}$_reset',
      );
    }
    _print(
      '$_red╚══════════════════════════════════════════════════════════$_reset',
    );
  }

  // ─── NAVIGATION ─── magenta arrow format
  static void navigation(
    String action,
    String route, {
    String? from,
    Map<String, dynamic>? args,
  }) {
    final fromPart = from != null ? '$_dim$from$_reset $_magenta→$_reset ' : '';
    _print(
      '$_magenta➜ NAVIGATION$_reset  $_dim[${_time()}]$_reset  $fromPart$_bold$route$_reset  $_dim($action)$_reset',
    );
    if (args != null && args.isNotEmpty) {
      _print('$_magenta  └─ args:$_reset $_dim$args$_reset');
    }
  }

  // ─── BUTTON CLICK ─── blue format
  static void buttonClick(String label, {String? screen, String? action}) {
    final screenPart = screen != null ? ' on $_bold$screen$_reset' : '';
    final actionPart = action != null ? ' → $action' : '';
    _print(
      '$_blue🔘 BUTTON$_reset  $_dim[${_time()}]$_reset  "$_bold$label$_reset"$screenPart$actionPart',
    );
  }

  // ─── PROVIDER / STATE ─── white format
  static void state(
    String provider,
    String event, {
    Map<String, dynamic>? data,
  }) {
    _print(
      '$_white⚡ STATE$_reset  $_dim[${_time()}]$_reset  $_bold$provider$_reset.$event',
    );
    if (data != null) _print('$_white  └─$_reset $_dim$data$_reset');
  }

  // ─── INFO ─── gold format
  static void info(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _print('$_goldℹ️  INFO$_reset  $_dim[${_time()}]$_reset  $prefix$message');
  }

  // ─── WARNING ─── yellow format
  static void warning(String message) {
    _print('$_yellow⚠️  WARN$_reset  $_dim[${_time()}]$_reset  $message');
  }

  // ─── ERROR ─── red format
  static void error(String message, [Object? e, StackTrace? stackTrace]) {
    _print('$_red💥 ERROR$_reset  $_dim[${_time()}]$_reset  $message');
    if (e != null) _print('$_red  └─$_reset $e');
    if (stackTrace != null) {
      _print(
        '$_red  └─$_reset $_dim${stackTrace.toString().split('\n').take(2).join('\n')}$_reset',
      );
    }
  }

  // ─── SUCCESS ─── green check format
  static void success(String message) {
    _print('$_green✓ SUCCESS$_reset  $_dim[${_time()}]$_reset  $message');
  }

  // ─── LIFECYCLE ─── dim format
  static void lifecycle(String screen, String event) {
    _print('$_dim🔄 LIFECYCLE [${_time()}] $screen — $event$_reset');
  }
}

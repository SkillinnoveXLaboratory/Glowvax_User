import 'dart:async';

/// Serializes API calls with a minimum gap to avoid bursting the server.
class ApiRequestQueue {
  ApiRequestQueue._();
  static final ApiRequestQueue instance = ApiRequestQueue._();

  Future<void>? _chain;
  DateTime _lastFinished = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _cooldownUntil;

  static const _minGap = Duration(milliseconds: 800);

  void markRateLimited(Duration cooldown) {
    final until = DateTime.now().add(cooldown);
    if (_cooldownUntil == null || until.isAfter(_cooldownUntil!)) {
      _cooldownUntil = until;
    }
  }

  Future<T> run<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _chain = (_chain ?? Future.value()).then((_) async {
      final cooldown = _cooldownUntil;
      if (cooldown != null && DateTime.now().isBefore(cooldown)) {
        await Future.delayed(cooldown.difference(DateTime.now()));
      }

      final elapsed = DateTime.now().difference(_lastFinished);
      if (elapsed < _minGap) {
        await Future.delayed(_minGap - elapsed);
      }

      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _lastFinished = DateTime.now();
      }
    });
    return completer.future;
  }
}

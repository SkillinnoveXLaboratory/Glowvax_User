import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _ready = false;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isReady => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    _mode = _parse(stored);
    _ready = true;
    AppLogger.info('Theme ready (mode: ${_mode.name})', tag: 'Theme');
    notifyListeners();
  }

  Future<void> setDark(bool dark) =>
      setMode(dark ? ThemeMode.dark : ThemeMode.light);

  Future<void> toggle() async {
    switch (_mode) {
      case ThemeMode.light:
        await setMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        await setMode(ThemeMode.dark);
        break;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    notifyListeners();
  }

  ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

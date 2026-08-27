import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/storage/token_storage.dart';
import 'presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('Glowvax app starting', tag: 'App');

  final tokenStorage = TokenStorage();
  final themeProvider = ThemeProvider();
  await Future.wait([tokenStorage.init(), themeProvider.init()]);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(GlowvaxApp(tokenStorage: tokenStorage, themeProvider: themeProvider));
}

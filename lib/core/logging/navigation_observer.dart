import 'package:flutter/material.dart';

import '../logging/app_logger.dart';

/// Logs all screen navigation events via NavigatorObserver.
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final to = _routeName(route);
    final from = _routeName(previousRoute);
    AppLogger.navigation('PUSH', to, from: from);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final from = _routeName(route);
    final to = _routeName(previousRoute);
    AppLogger.navigation('POP', to, from: from);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.navigation(
      'REPLACE',
      _routeName(newRoute),
      from: _routeName(oldRoute),
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.navigation(
      'REMOVE',
      _routeName(previousRoute),
      from: _routeName(route),
    );
    super.didRemove(route, previousRoute);
  }

  String _routeName(Route<dynamic>? route) {
    if (route == null) return 'none';
    return route.settings.name ?? route.runtimeType.toString();
  }
}

/// Wraps any tappable widget with button-click logging.
class LogTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String label;
  final String? screen;

  const LogTap({
    super.key,
    required this.child,
    required this.onTap,
    required this.label,
    this.screen,
  });

  @override
  Widget build(BuildContext context) {
    final routeName =
        screen ?? ModalRoute.of(context)?.settings.name ?? 'unknown';
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppLogger.buttonClick(label, screen: routeName);
              onTap!();
            },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

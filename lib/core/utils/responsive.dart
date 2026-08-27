import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => width(context) < 360;

  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w >= 600) return 32;
    if (w >= 400) return 20;
    return 16;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int compact = 2,
    int expanded = 3,
  }) {
    return width(context) >= 600 ? expanded : compact;
  }

  static double serviceCardWidth(BuildContext context) {
    final w = width(context);
    if (w >= 600) return 280;
    if (w >= 400) return 240;
    return w * 0.68;
  }
}

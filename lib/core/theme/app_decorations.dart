import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppDecorations {
  AppDecorations._();

  static const double cardRadius = 18.0;
  static const double buttonRadius = 16.0;
  static const double bottomNavRadius = 24.0;

  static List<BoxShadow> cardShadow(BuildContext context) => [
    BoxShadow(
      color: AppColors.isDark(context)
          ? Colors.black.withValues(alpha: 0.22)
          : const Color(0xFFCCD2E0).withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glowShadow(BuildContext context) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.18),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonShadow(BuildContext context) => [
    BoxShadow(
      color: AppColors.gold.withValues(
        alpha: AppColors.isDark(context) ? 0.24 : 0.2,
      ),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration premiumCard(
    BuildContext context, {
    Color? color,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: gradient == null ? (color ?? AppColors.surfaceOf(context)) : null,
      gradient: gradient ?? AppColors.cardGradientOf(context),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: AppColors.cardBorderOf(context)),
      boxShadow: cardShadow(context),
    );
  }

  static BoxDecoration heroCard(BuildContext context) {
    return BoxDecoration(
      gradient: AppColors.heroGradientOf(context),
      borderRadius: BorderRadius.circular(cardRadius + 2),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      boxShadow: cardShadow(context),
    );
  }

  static BoxDecoration goldBadge(BuildContext context) {
    return BoxDecoration(
      gradient: AppColors.goldGradient,
      borderRadius: BorderRadius.circular(999),
      boxShadow: buttonShadow(context),
    );
  }

  static BoxDecoration navBar(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surfaceOf(context),
      border: Border(
        top: BorderSide(color: AppColors.cardBorderOf(context), width: 0.8),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: AppColors.isDark(context) ? 0.14 : 0.05,
          ),
          blurRadius: 12,
          offset: const Offset(0, -3),
        ),
      ],
    );
  }

  static BoxDecoration searchBar(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: AppColors.cardBorderOf(context)),
      boxShadow: cardShadow(context),
    );
  }

  static BoxDecoration goldCircleOutline(BuildContext context) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.isDark(context)
          ? AppColors.surfaceElevatedOf(context)
          : AppColors.primary.withValues(alpha: 0.08),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.3),
        width: 1.3,
      ),
    );
  }

  static ShapeBorder bottomSheetShape() {
    return const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    );
  }
}

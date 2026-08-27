import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF7A3DB8);
  static const Color primaryDark = Color(0xFF5B248F);
  static const Color primaryLight = Color(0xFFB493E1);
  static const Color secondary = Color(0xFF9A72CE);
  static const Color accent = Color(0xFFD4AF37);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFF1C2);
  static const Color rose = Color(0xFF7A3DB8);
  static const Color rating = Color(0xFFD4AF37);

  static const Color success = Color(0xFF1FA971);
  static const Color warning = Color(0xFFE39A1F);
  static const Color error = Color(0xFFD9536D);
  static const Color info = Color(0xFF5C7FD6);

  static const Color background = Color(0xFF120E18);
  static const Color backgroundTint = Color(0xFF1A1322);
  static const Color surface = Color(0xFF1E1728);
  static const Color surfaceElevated = Color(0xFF281F34);
  static const Color cardBorder = Color(0xFF493657);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC4B7CF);
  static const Color textHint = Color(0xFF8E809A);

  static const Color textOnGold = Color(0xFF1A1A1A);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF120E18) : const Color(0xFFFFFFFF);

  static Color backgroundTintOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1322) : const Color(0xFFFAFAFC);

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E1728) : const Color(0xFFFFFFFF);

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF281F34) : const Color(0xFFF7F7FA);

  static Color cardBorderOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF493657) : const Color(0xFFE7E8EE);

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? const Color(0xFFFFFFFF) : const Color(0xFF201827);

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? const Color(0xFFC4B7CF) : const Color(0xFF6E5D75);

  static Color textHintOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF8E809A) : const Color(0xFF9A8A9F);

  static LinearGradient pageGradientOf(BuildContext context) => LinearGradient(
    colors: isDark(context)
        ? const [Color(0xFF120E18), Color(0xFF1A1322), Color(0xFF120E18)]
        : const [Color(0xFFFFFFFF), Color(0xFFFCFCFD), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient heroGradientOf(BuildContext context) => LinearGradient(
    colors: isDark(context)
        ? const [Color(0xFF241533), Color(0xFF110A1A)]
        : const [Color(0xFFF1E9FB), Color(0xFFFCFAFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradientOf(BuildContext context) => LinearGradient(
    colors: isDark(context)
        ? const [Color(0xFF241B31), Color(0xFF1A1322)]
        : const [Color(0xFFFFFFFF), Color(0xFFF8F9FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFB493E1), Color(0xFF9A72CE), Color(0xFF7A3DB8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = goldGradient;

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFE7A0), Color(0xFFD4AF37), Color(0xFFB58A1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = brandGradient;

  static LinearGradient navActiveGradientOf(BuildContext context) =>
      LinearGradient(
        colors: isDark(context)
            ? const [Color(0xFF2A2038), Color(0xFF1E172B)]
            : const [Color(0xFFE9DDF8), Color(0xFFF5EFFD)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient bannerOverlayOf(BuildContext context) => LinearGradient(
    colors: isDark(context)
        ? const [Colors.transparent, Color(0xD9110A1A)]
        : const [Colors.transparent, Color(0xCCFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

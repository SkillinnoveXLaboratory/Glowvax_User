import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scaffold = isDark ? const Color(0xFF120E18) : const Color(0xFFFFFFFF);
    final surface = isDark ? const Color(0xFF1E1728) : const Color(0xFFFFFFFF);
    final surfaceContainer = isDark
        ? const Color(0xFF281F34)
        : const Color(0xFFF7F7FA);
    final outline = isDark ? const Color(0xFF493657) : const Color(0xFFE7E8EE);
    final onSurface = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF201827);
    final onSurfaceMuted = isDark
        ? const Color(0xFFC4B7CF)
        : const Color(0xFF6E5D75);
    final dayForeground = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return onSurfaceMuted.withValues(alpha: 0.45);
      }
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return onSurface;
    });
    final dayBackground = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    });
    final yearForeground = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return onSurface;
    });
    final yearBackground = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    });

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );

    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: onSurface),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: onSurface),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: onSurface),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: onSurface),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: onSurface),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: onSurface),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: onSurfaceMuted),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: onSurfaceMuted),
      labelLarge: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textOnPrimary,
      ),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: onSurfaceMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: colorScheme,
      textTheme: textTheme,
      dividerColor: outline.withValues(alpha: 0.65),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scaffold,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          side: BorderSide(color: outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textOnGold,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textOnGold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.75),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.gold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppTextStyles.titleMedium.copyWith(
            color: AppColors.gold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: onSurfaceMuted),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: onSurfaceMuted.withValues(alpha: 0.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: AppDecorations.bottomSheetShape(),
        showDragHandle: false,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        dayForegroundColor: dayForeground,
        dayBackgroundColor: dayBackground,
        todayForegroundColor: WidgetStatePropertyAll(AppColors.primary),
        todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        todayBorder: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.65),
        ),
        yearForegroundColor: yearForeground,
        yearBackgroundColor: yearBackground,
        dividerColor: outline.withValues(alpha: 0.65),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: onSurfaceMuted),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: onSurface),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        textColor: onSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF2A2034)
            : const Color(0xFF2A2034),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textOnGold,
      ),
      dividerTheme: DividerThemeData(color: outline.withValues(alpha: 0.65)),
      iconTheme: IconThemeData(color: onSurface),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.poppins();

  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle get headlineLarge => _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineMedium =>
      _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get titleLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25);

  static TextStyle get titleMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.25);

  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle get bodyMedium =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle get bodySmall =>
      _base.copyWith(fontSize: 11.5, fontWeight: FontWeight.w400, height: 1.35);

  static TextStyle get labelLarge => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get price => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle get brandTitle => GoogleFonts.cormorantGaramond(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 2.6,
  );

  static TextStyle get overline => _base.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.1,
  );
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type scale for Malihub.
///
/// We use the system-bundled Roboto everywhere (reliable offline, no font
// download step) but carry personality through weight, letter-spacing,
// and case rather than an exotic typeface: big balance figures are tight
// and heavy, section eyebrows are small, spaced-out, and uppercase — two
// distinct voices from one font family.
class AppText {
  AppText._();

  // Display — big money figures (balance, budget totals)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  // Eyebrow — small spaced-out uppercase labels above content
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: AppColors.textSecondary,
  );

  // Section titles
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Soft, brand-tinted elevation used instead of borders-everywhere or
/// generic black drop shadows.
class AppShadows {
  AppShadows._();
  static List<BoxShadow> soft = [
    const BoxShadow(
        color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> subtle = [
    const BoxShadow(
        color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
  ];
}

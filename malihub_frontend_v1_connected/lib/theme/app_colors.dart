import 'package:flutter/material.dart';

/// Malihub color system.
///
/// "Mali" means wealth in Swahili — the palette leans into that: forest
/// greens for growth/money, a muted gold reserved for milestones and goals
/// reached (used sparingly, never as decoration), and an ink-green text
/// color instead of flat black so the whole app feels like one family of
/// hues rather than green-on-generic-gray.
class AppColors {
  AppColors._();

  // Core greens
  static const Color primary = Color(0xFF1F8A4C);
  static const Color primaryDeep = Color(0xFF124A29); // depth, headers, pressed states
  static const Color primaryLight = Color(0xFF34A65F);
  static const Color primaryPale = Color(0xFFE3F3E8);

  // Signature accent — reserved for milestones, streaks, goals reached
  static const Color gold = Color(0xFFD9A441);
  static const Color goldPale = Color(0xFFFBF0DC);
  static const Color goldDeep = Color(0xFF8A6420);

  // Backgrounds & surfaces
  static const Color background = Color(0xFFEFF6F1); // sage mist
  static const Color surface = Colors.white;
  static const Color surfaceSunken = Color(0xFFE6F0E9);

  // Text — ink-green family, not flat black/gray
  static const Color textPrimary = Color(0xFF16241C);
  static const Color textSecondary = Color(0xFF5B6B60);
  static const Color textMuted = Color(0xFF8A9990);
  static const Color textOnPrimary = Colors.white;

  // Status
  static const Color expense = Color(0xFFB33F32); // brick red, deliberate distance from generic orange-terracotta
  static const Color expensePale = Color(0xFFF8E9E6);
  static const Color income = primary;
  static const Color incomePale = primaryPale;

  // Structural
  static const Color border = Color(0xFFDCE8E0);
  static const Color divider = Color(0xFFE9F1EB);
  static const Color shadow = Color(0x14124A29); // low-opacity deep-green shadow, not generic black
}

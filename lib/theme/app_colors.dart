import 'package:flutter/material.dart';

/// Central brand + semantic palette for SevaSetu.
///
/// Deep blue is the primary civic-trust brand colour, teal the secondary
/// action colour, and a muted purple is reserved for AI-related surfaces.
class AppColors {
  AppColors._();

  // Brand primaries.
  static const Color primary = Color(0xFF17439B); // Deep trust blue.
  static const Color primaryDark = Color(0xFF0F2F6E);
  static const Color secondary = Color(0xFF0E9488); // Teal.
  static const Color secondaryDark = Color(0xFF0B6E65);
  static const Color aiPurple = Color(0xFF6D4FC4); // Subtle AI accent.
  static const Color aiPurpleSoft = Color(0xFFEFEAFB);

  // Neutrals.
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F3F9);
  static const Color ink = Color(0xFF16233B);
  static const Color inkSoft = Color(0xFF43506B);
  static const Color inkFaint = Color(0xFF74809B);
  static const Color hairline = Color(0xFFE3E8F1);

  // Semantic status colours (paired light backgrounds).
  static const Color success = Color(0xFF1E7F4F);
  static const Color successBg = Color(0xFFE7F4EC);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFDF1DE);
  static const Color danger = Color(0xFFBE3A34);
  static const Color dangerBg = Color(0xFFFCECEA);
  static const Color info = Color(0xFF1D5FA8);
  static const Color infoBg = Color(0xFFE8F1FB);

  /// Shade of [primary] at a given opacity (used for soft fills).
  static Color primarySoft({double opacity = 0.08}) =>
      Color.alphaBlend(primary.withValues(alpha: opacity), Colors.white);

  static Color secondarySoft({double opacity = 0.10}) =>
      Color.alphaBlend(secondary.withValues(alpha: opacity), Colors.white);
}

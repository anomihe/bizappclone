import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0E5E4A); // Deep Emerald Green
  static const Color primaryLight = Color(0xFF147A61);
  static const Color primaryDark = Color(0xFF0A4435);

  static const Color accent = Color(0xFFF2A900); // Warm Gold / Amber
  static const Color accentLight = Color(0xFFFFC033);

  // Surface & Canvas
  static const Color background = Color(0xFF08110E); // Deep Dark Canvas
  static const Color surface = Color(0xFF0F1F1A); // Dark Card Surface
  static const Color surfaceLight = Color(0xFF162D26);
  static const Color navbar = Color(0xFF0B1512);

  // Light Mode Canvas (for clean onboarding variants)
  static const Color lightBackground = Color(0xFFF8FAF9);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8E5);

  // Neutral Greys & Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9EABA5);
  static const Color textMuted = Color(0xFF64746E);
  static const Color border = Color(0x1FFFFFFF); // 12% White
  static const Color borderSubtle = Color(0x0FFFFFFF); // 6% White

  // Light Mode Text
  static const Color lightTextPrimary = Color(0xFF111916);
  static const Color lightTextSecondary = Color(0xFF4A5551);
  static const Color lightTextMuted = Color(0xFF8B9893);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

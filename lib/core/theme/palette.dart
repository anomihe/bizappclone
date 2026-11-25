import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Brightness-aware colour tokens. Use `context.p.text` etc. instead of
/// repeating `isDark ? ... : ...` in every widget.
class Palette {
  final bool isDark;
  const Palette(this.isDark);

  Color get bg => isDark ? AppColors.background : const Color(0xFFF1F3F2);
  Color get card => isDark ? AppColors.surface : Colors.white;
  Color get cardAlt => isDark ? AppColors.surfaceLight : const Color(0xFFF5F7F6);
  Color get text => isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.lightTextMuted;
  Color get border => isDark ? AppColors.border : AppColors.lightBorder;
  Color get primarySoft => isDark ? const Color(0xFF173A30) : const Color(0xFFE3EFEB);
  Color get accentSoft => isDark ? const Color(0xFF3A2E0E) : const Color(0xFFFFF4D9);
  Color get errorSoft => isDark ? const Color(0xFF3A1717) : const Color(0xFFFDECEC);
  Color get infoSoft => isDark ? const Color(0xFF152A45) : const Color(0xFFE8F0FE);

  /// Brand green for text, icons and outlines. The fill colour
  /// (AppColors.primary) is too dark to read on dark surfaces, so dark mode
  /// uses a lighter mint with ~7:1 contrast.
  Color get brand => isDark ? const Color(0xFF4CC9A0) : AppColors.primary;

  /// Lift a status/semantic colour so it stays legible on dark surfaces.
  Color readable(Color c) => isDark ? Color.lerp(c, Colors.white, 0.35)! : c;

  /// Info/warning/error text colours tuned per theme.
  Color get info => isDark ? const Color(0xFF7AA7FF) : AppColors.info;
  Color get error => isDark ? const Color(0xFFFF8A8A) : AppColors.error;

  /// Warm cream → mint brand gradient from the Figma (top-left cream-yellow,
  /// fading to pale mint). Used behind tab headers.
  List<Color> get headerGradient => isDark
      ? [const Color(0xFF1B2A1F), AppColors.background]
      : [const Color(0xFFF7EECB), const Color(0xFFE8EFDC), const Color(0xFFE2ECE2)];

  /// Same gradient stretched over a whole screen (Home dashboard): white
  /// cards float on it. Opaque colours only — alpha gradients render muddy
  /// on some GPUs.
  LinearGradient get screenGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A20), Color(0xFF0F1C17), AppColors.background],
          stops: [0, 0.45, 1],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7EECB), Color(0xFFE9F0DD), Color(0xFFDDEADF)],
          stops: [0, 0.4, 1],
        );
}

extension PaletteX on BuildContext {
  Palette get p => Palette(Theme.of(this).brightness == Brightness.dark);
}

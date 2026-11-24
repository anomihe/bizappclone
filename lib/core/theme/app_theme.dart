import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'palette.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// One builder for both modes so every component gets the same treatment;
  /// only the [Palette] values differ.
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = Palette(isDark);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? p.brand : AppColors.primary,
      onPrimary: isDark ? const Color(0xFF04140E) : Colors.white,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: p.brand,
      secondary: AppColors.accent,
      onSecondary: const Color(0xFF111916),
      error: p.error,
      onError: Colors.white,
      surface: p.card,
      onSurface: p.text,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerHighest: p.cardAlt,
      outline: p.border,
      outlineVariant: p.border,
    );

    OutlineInputBorder border(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: w));

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: GoogleFonts.figtree().fontFamily,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.card,
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(bodyColor: p.text, displayColor: p.text),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: p.text),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.border)),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
      iconTheme: IconThemeData(color: p.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(fontSize: 14, color: p.textMuted),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(p.brand, 1.5),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error, 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.brand,
        selectionColor: p.brand.withValues(alpha: 0.3),
        selectionHandleColor: p.brand,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : p.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primaryLight : p.cardAlt),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : p.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primaryLight : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: p.textMuted, width: 1.4),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(p.brand)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        modalBackgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        // Sheets stay phone-width on tablets / desktop instead of stretching edge to edge.
        constraints: const BoxConstraints(maxWidth: 560),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1F3A31) : AppColors.primaryDark,
        contentTextStyle: GoogleFonts.figtree(color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        width: null,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2A3A35) : const Color(0xFF1F2A26), borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.figtree(color: Colors.white, fontSize: 12),
      ),
      listTileTheme: ListTileThemeData(textColor: p.text, iconColor: p.textSecondary),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.card,
        indicatorColor: AppColors.primary,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: p.textMuted),
        selectedLabelTextStyle: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: p.brand),
        unselectedLabelTextStyle: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w500, color: p.textMuted),
      ),
    );
  }
}

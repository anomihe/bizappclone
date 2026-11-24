import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  white,

  /// Gold call-to-action ("View Receipt", "Issue Invoice").
  accent,

  /// Destructive confirm ("Void Invoice", "Cancel Link").
  danger,

  /// Tinted green secondary ("Not Now", "Log in").
  soft,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  /// Icon after the label ("Next →").
  final Widget? trailingIcon;
  final double height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.height = 50,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
        fg = isDark ? Colors.white : AppColors.lightTextPrimary;
        break;
      case ButtonVariant.outline:
        bg = isDark ? Colors.transparent : Colors.white;
        fg = isDark ? Colors.white : AppColors.primary;
        border = BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder, width: 1.2);
        break;
      case ButtonVariant.white:
        bg = Colors.white;
        fg = const Color(0xFF0F1F1A);
        break;
      case ButtonVariant.accent:
        bg = AppColors.accent;
        fg = const Color(0xFF111916);
        break;
      case ButtonVariant.danger:
        bg = const Color(0xFFC62828);
        fg = Colors.white;
        break;
      case ButtonVariant.soft:
        bg = isDark ? const Color(0xFF173A30) : const Color(0xFFE3EFEB);
        fg = isDark ? Colors.white : AppColors.primary;
        break;
    }

    final disabled = onPressed == null && !isLoading;
    final disabledBg = isDark ? const Color(0xFF1E2B27) : const Color(0xFFDDE3E0);
    final disabledFg = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final textColor = disabled ? disabledFg : fg;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        // While loading keep the enabled colours (design shows a filled button with a spinner).
        onPressed: isLoading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledFg,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: disabled ? BorderSide.none : border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    IconTheme(data: IconThemeData(color: textColor, size: 18), child: icon!),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    IconTheme(data: IconThemeData(color: textColor, size: 18), child: trailingIcon!),
                  ],
                ],
              ),
      ),
    );
  }
}

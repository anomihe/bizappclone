import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  white,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 54,
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
        bg = Colors.transparent;
        fg = isDark ? Colors.white : AppColors.primary;
        border = BorderSide(
          color: isDark ? AppColors.border : AppColors.primary,
          width: 1.5,
        );
        break;
      case ButtonVariant.white:
        bg = Colors.white;
        fg = const Color(0xFF0F1F1A);
        break;
    }

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // Pill shape
          ),
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
                    icon!,
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.figtree(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

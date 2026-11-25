import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum LogoVariant {
  /// White stem and bowl with the gold arc — the official splash artwork,
  /// for green or dark backgrounds.
  whiteOnGreen,

  /// Green stem and bowl with the gold arc, for light backgrounds.
  /// Automatically switches to [whiteOnGreen] in dark mode.
  emeraldAndGold,

  /// Kept for API compatibility; renders the official white + gold mark.
  whiteMonochrome,
}

/// The Bizpaddi "b" mark, drawn from the official artwork
/// (assets/images/logo_mark_on_green.png) everywhere in the app.
class BizpaddiLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;
  final LogoVariant variant;
  final Color? textColor;

  const BizpaddiLogo({
    super.key,
    this.size = 64,
    this.showText = false,
    this.showTagline = false,
    this.variant = LogoVariant.emeraldAndGold,
    this.textColor,
  });

  static const asset = 'assets/images/logo_mark_on_green.png';

  /// Recolours the artwork's white stem/bowl to brand green while leaving the
  /// gold arc untouched. Works because gold has no blue component:
  ///   R' = R + (g.r − 1)·B,  G' = G + (g.g − 1)·B,  B' = g.b·B
  /// so white (1,1,1) → brand green and gold (r,g,0) → itself.
  static final _toGreen = ColorFilter.matrix(<double>[
    1, 0, AppColors.primary.r - 1, 0, 0, //
    0, 1, AppColors.primary.g - 1, 0, 0, //
    0, 0, AppColors.primary.b, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onLight = variant == LogoVariant.emeraldAndGold && !isDark;

    final mark = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: showText ? null : 'Bizpaddi',
    );
    final iconWidget = SizedBox(
      width: size,
      height: size,
      child: onLight ? ColorFiltered(colorFilter: _toGreen, child: mark) : mark,
    );

    if (!showText) return iconWidget;

    final resolvedTextColor = textColor ?? (onLight ? AppColors.primaryDark : Colors.white);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            SizedBox(width: size * 0.22),
            Text(
              'Bizpaddi',
              style: GoogleFonts.figtree(
                fontSize: size * 0.72,
                fontWeight: FontWeight.w800,
                color: resolvedTextColor,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Invoice. Get Paid. Done',
            style: GoogleFonts.figtree(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

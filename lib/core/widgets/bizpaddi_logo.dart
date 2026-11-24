import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum LogoVariant {
  /// White stem and loop with gold lower arc (used on green splash)
  whiteOnGreen,

  /// Emerald green stem and loop with gold lower arc (used on light backgrounds)
  emeraldAndGold,

  /// Full monochrome white (for dark mode headers)
  whiteMonochrome,
}

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The emerald mark disappears on dark surfaces; use the white + gold version there.
    final resolvedVariant = isDark && variant == LogoVariant.emeraldAndGold ? LogoVariant.whiteOnGreen : variant;

    final resolvedTextColor = textColor ??
        (variant == LogoVariant.whiteOnGreen
            ? Colors.white
            : (isDark ? Colors.white : AppColors.primaryDark));

    final iconWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BizpaddiMarkPainter(variant: resolvedVariant),
      ),
    );

    if (!showText) {
      return iconWidget;
    }

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

class _BizpaddiMarkPainter extends CustomPainter {
  final LogoVariant variant;

  _BizpaddiMarkPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final Color mainColor;
    final Color goldColor = AppColors.accent;

    switch (variant) {
      case LogoVariant.whiteOnGreen:
        mainColor = Colors.white;
        break;
      case LogoVariant.emeraldAndGold:
        mainColor = AppColors.primary;
        break;
      case LogoVariant.whiteMonochrome:
        mainColor = Colors.white;
        break;
    }

    // Stem & upper loop of the 'b'
    final mainPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final goldPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Center circle coordinates
    final stemWidth = w * 0.25;
    final radius = w * 0.36;
    final centerX = w * 0.58;
    final centerY = h * 0.58;

    // 1. Draw Gold crescent (lower-left quadrant sweeping under bowl)
    final goldPath = Path();
    goldPath.moveTo(w * 0.16, centerY + radius * 0.1);
    goldPath.arcToPoint(
      Offset(centerX + radius * 0.6, h * 0.92),
      radius: Radius.circular(radius * 1.05),
      clockwise: false,
    );
    goldPath.lineTo(centerX + radius * 0.3, h * 0.75);
    goldPath.arcToPoint(
      Offset(w * 0.32, centerY + radius * 0.2),
      radius: Radius.circular(radius * 0.75),
      clockwise: true,
    );
    goldPath.close();
    canvas.drawPath(goldPath, goldPaint);

    // 2. Draw Main Lower Bowl (donut shape outer minus inner)
    final bowlPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    final holePath = Path()
      ..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.5));
    final donutPath = Path.combine(PathOperation.difference, bowlPath, holePath);
    canvas.drawPath(donutPath, mainPaint);

    // 3. Draw Vertical Upper Stem (Left upright pillar)
    final stemRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.22, h * 0.08, stemWidth, h * 0.62),
      topLeft: Radius.circular(stemWidth * 0.5),
      topRight: Radius.circular(stemWidth * 0.5),
      bottomLeft: Radius.circular(stemWidth * 0.3),
      bottomRight: Radius.circular(stemWidth * 0.3),
    );
    canvas.drawRRect(stemRRect, mainPaint);
  }

  @override
  bool shouldRepaint(covariant _BizpaddiMarkPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

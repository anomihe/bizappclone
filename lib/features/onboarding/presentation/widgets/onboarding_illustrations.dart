import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingIllustration extends StatelessWidget {
  final int index;

  const OnboardingIllustration({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: 260,
        height: 240,
        child: CustomPaint(
          painter: _IllustrationPainter(index: index, isDark: isDark),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final int index;
  final bool isDark;

  _IllustrationPainter({required this.index, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..isAntiAlias = true;

    final primaryFill = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final goldPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..isAntiAlias = true;

    final goldFill = Paint()
      ..color = AppColors.accent.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    // Draw central phone frame
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: 110, height: 170),
      const Radius.circular(20),
    );

    final phoneBg = Paint()
      ..color = isDark ? AppColors.surface : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(phoneRect, phoneBg);
    canvas.drawRRect(phoneRect, primaryPaint);

    // Screen notch
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.5 - 72), width: 36, height: 8),
        const Radius.circular(4),
      ),
      Paint()..color = isDark ? Colors.white24 : Colors.black12,
    );

    if (index == 0) {
      // 1. "Run your business in one place" (Charts, analytics, checklist)
      // Mini graph bars inside phone
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 34, h * 0.5 + 10, 16, 40), const Radius.circular(3)),
        goldFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 34, h * 0.5 + 10, 16, 40), const Radius.circular(3)),
        goldPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 10, h * 0.5 - 15, 16, 65), const Radius.circular(3)),
        primaryFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 10, h * 0.5 - 15, 16, 65), const Radius.circular(3)),
        primaryPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 + 14, h * 0.5 + 25, 16, 25), const Radius.circular(3)),
        goldFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 + 14, h * 0.5 + 25, 16, 25), const Radius.circular(3)),
        goldPaint,
      );

      // Orbiting store icon (left)
      final storeCenter = Offset(w * 0.18, h * 0.42);
      canvas.drawCircle(storeCenter, 22, isDark ? (Paint()..color = AppColors.surfaceLight) : primaryFill);
      canvas.drawCircle(storeCenter, 22, primaryPaint);
      canvas.drawLine(storeCenter + const Offset(-10, -4), storeCenter + const Offset(10, -4), primaryPaint);
      canvas.drawLine(storeCenter + const Offset(-8, -4), storeCenter + const Offset(-8, 8), primaryPaint);
      canvas.drawLine(storeCenter + const Offset(8, -4), storeCenter + const Offset(8, 8), primaryPaint);

      // Orbiting project calendar (right)
      final calCenter = Offset(w * 0.82, h * 0.42);
      canvas.drawCircle(calCenter, 22, goldFill);
      canvas.drawCircle(calCenter, 22, goldPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: calCenter, width: 18, height: 18), const Radius.circular(4)),
        goldPaint,
      );

      // Orbiting checklist (bottom right)
      final checkCenter = Offset(w * 0.76, h * 0.78);
      canvas.drawCircle(checkCenter, 18, primaryFill);
      canvas.drawCircle(checkCenter, 18, primaryPaint);
    } else if (index == 1) {
      // 2. "Sell, bill and get paid easily" (Invoice checkmark, card, coins)
      // Green verified badge inside phone
      final badgeCenter = Offset(w * 0.5, h * 0.46);
      canvas.drawCircle(badgeCenter, 24, goldFill);
      canvas.drawCircle(badgeCenter, 24, goldPaint);
      // Checkmark
      final checkPath = Path()
        ..moveTo(badgeCenter.dx - 10, badgeCenter.dy - 1)
        ..lineTo(badgeCenter.dx - 3, badgeCenter.dy + 7)
        ..lineTo(badgeCenter.dx + 11, badgeCenter.dy - 7);
      canvas.drawPath(checkPath, primaryPaint..strokeWidth = 3);

      // Floating credit card (right)
      final cardRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.8, h * 0.45), width: 55, height: 36),
        const Radius.circular(6),
      );
      canvas.drawRRect(cardRect, primaryFill);
      canvas.drawRRect(cardRect, primaryPaint..strokeWidth = 2);

      // Floating invoice sheet (left)
      final sheetRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.2, h * 0.48), width: 44, height: 56),
        const Radius.circular(6),
      );
      canvas.drawRRect(sheetRect, goldFill);
      canvas.drawRRect(sheetRect, goldPaint);
    } else {
      // 3. "Everything works together" (Connecting nodes, chat, team)
      // Chat bubble in phone
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.44), width: 64, height: 36),
        const Radius.circular(10),
      );
      canvas.drawRRect(bubbleRect, primaryFill);
      canvas.drawRRect(bubbleRect, primaryPaint..strokeWidth = 2);

      // Link node (top left)
      final linkCenter = Offset(w * 0.22, h * 0.38);
      canvas.drawCircle(linkCenter, 20, goldFill);
      canvas.drawCircle(linkCenter, 20, goldPaint);

      // User avatar node (bottom right)
      final userCenter = Offset(w * 0.78, h * 0.62);
      canvas.drawCircle(userCenter, 20, primaryFill);
      canvas.drawCircle(userCenter, 20, primaryPaint);
      canvas.drawCircle(userCenter + const Offset(0, -4), 7, primaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.isDark != isDark;
}

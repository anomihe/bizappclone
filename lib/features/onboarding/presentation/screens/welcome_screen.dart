import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/theme_toggle.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';

/// "Welcome to your business workspace" — Create an Account / Log in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;

    return Scaffold(
      backgroundColor: p.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: p.isDark
                ? [const Color(0xFF102820), AppColors.background, AppColors.background]
                // Pre-blended to opaque colours: gradients that mix alpha render
                // muddy on some renderers.
                : [Color.alphaBlend(AppColors.primary.withValues(alpha: 0.06), p.bg), p.bg],
          ),
        ),
        child: Stack(children: [
          // Faint "desk" line art behind the logo (Get Started · white variant).
          const Positioned(left: 0, right: 0, top: 0, child: IgnorePointer(child: _DeskLineArt())),
          SafeArea(
          child: ContentWidth(
            maxWidth: Breakpoints.form,
            child: FillScroll(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(children: [
                const Align(alignment: Alignment.centerRight, child: ThemeToggleButton()),
                const Spacer(flex: 3),
                const BizpaddiLogo(size: 72),
                const SizedBox(height: 24),
                Text(
                  'Welcome to your\nbusiness workspace',
                  textAlign: TextAlign.center,
                  style: tx(context, 28, weight: FontWeight.w800, height: 1.25),
                ),
                const SizedBox(height: 12),
                Text(
                  "Everything you need to manage, grow, and simplify your business is right here. Let's get you started.",
                  textAlign: TextAlign.center,
                  style: tx(context, 14, weight: FontWeight.w400, color: p.textSecondary, height: 1.45),
                ),
                const Spacer(flex: 4),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Create an Account',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Log in',
                  variant: ButtonVariant.soft,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
                const SizedBox(height: 20),
                Text(
                  'By continuing you agree to Bizpaddi Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: tx(context, 12, weight: FontWeight.w400, color: p.textMuted),
                ),
              ]),
            ),
          ),
        ),
        ]),
      ),
    );
  }
}

/// Outline "desk" doodles (laptop, receipts, phone, glasses, pen) from the
/// white Get Started frame, drawn with icons so no image asset is needed.
class _DeskLineArt extends StatelessWidget {
  const _DeskLineArt();

  static const _items = <(IconData, double, double, double, double)>[
    // icon, x (0–1), y (px), size, rotation (turns)
    (Icons.laptop_outlined, 0.70, 12, 96, -0.03),
    (Icons.receipt_long_outlined, 0.30, 70, 70, 0.04),
    (Icons.description_outlined, 0.05, 20, 56, -0.06),
    (Icons.calculate_outlined, 0.86, 150, 50, 0.05),
    (Icons.phone_iphone_outlined, 0.62, 150, 58, -0.04),
    (Icons.visibility_outlined, 0.15, 180, 46, 0.0),
    (Icons.edit_outlined, 0.92, 70, 40, 0.1),
    (Icons.local_cafe_outlined, 0.02, 120, 44, -0.02),
    (Icons.event_note_outlined, 0.42, 190, 40, 0.06),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final base = p.isDark ? Colors.white : AppColors.primary;
    final maxAlpha = p.isDark ? 0.07 : 0.13;
    return ExcludeSemantics(
      child: SizedBox(
        height: 260,
        child: LayoutBuilder(
          builder: (context, c) => Stack(children: [
            for (final (icon, x, y, size, turns) in _items)
              Positioned(
                left: (c.maxWidth - size) * x,
                top: y,
                // Doodles fade as they get closer to the logo.
                child: Transform.rotate(angle: turns * 6.2832, child: Icon(icon, size: size, color: base.withValues(alpha: maxAlpha * (1 - y / 300)))),
              ),
          ]),
        ),
      ),
    );
  }
}

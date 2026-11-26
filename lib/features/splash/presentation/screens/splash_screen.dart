import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../auth/presentation/screens/welcome_back_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool startWithGreen;

  const SplashScreen({super.key, this.startWithGreen = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentStep = 0; // 0: Green Splash, 1: White Splash

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Stage 1: Green splash for 1.4 seconds
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() {
        _currentStep = 1;
      });
    }

    // Stage 2: White/Themed splash for 1.4 seconds, then proceed to onboarding
    // Live mode: a saved login goes to "Welcome back" instead of onboarding.
    final returning = await LiveSession.instance.hasSavedSession();
    if (returning) BizStore.instance.hasRememberedUser = true;
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => returning ? const WelcomeBackScreen() : const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _currentStep == 0
            ? const _GreenSplashScreen(key: ValueKey('green'))
            : const _WhiteSplashScreen(key: ValueKey('white')),
      ),
    );
  }
}

class _GreenSplashScreen extends StatelessWidget {
  const _GreenSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primary,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner watermarks: the logo mark, tinted a shade off the green and cropped.
          Positioned(top: -70, right: -90, child: _Swoosh(size: 230, turns: 0.5)),
          Positioned(bottom: -90, left: -80, child: _Swoosh(size: 250, turns: 0)),

          // Central icon: official mark artwork (white stem + gold arc).
          Center(child: Image.asset('assets/images/logo_mark_on_green.png', width: 120, height: 120, semanticLabel: 'Bizpaddi')),
        ],
      ),
    );
  }
}

class _WhiteSplashScreen extends StatelessWidget {
  const _WhiteSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? AppColors.background : Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Brand wordmark (official artwork in light mode; the drawn white
          // version in dark mode, where the green text would disappear).
          Center(
            child: isDark
                ? const BizpaddiLogo(size: 58, variant: LogoVariant.whiteMonochrome, showText: true)
                : Image.asset('assets/images/bizpaddi_wordmark.png', width: 200, semanticLabel: 'Bizpaddi'),
          ),

          // Bottom Tagline
          Positioned(
            bottom: 40,
            child: Text(
              'Invoice. Get Paid. Done',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The logo mark, recoloured as a subtle corner watermark.
class _Swoosh extends StatelessWidget {
  final double size;
  final double turns;
  const _Swoosh({required this.size, required this.turns});

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(turns),
      child: Image.asset(
        'assets/images/logo_mark_on_green.png',
        width: size,
        height: size,
        color: Colors.white.withValues(alpha: 0.07),
        colorBlendMode: BlendMode.srcIn,
        excludeFromSemantics: true,
      ),
    );
  }
}

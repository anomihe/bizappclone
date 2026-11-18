import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
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
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
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
          // Top-right decorative background watermarks
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Central Icon
          const Center(
            child: BizpaddiLogo(
              size: 110,
              variant: LogoVariant.whiteOnGreen,
              showText: false,
            ),
          ),
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
          // Centered Brand Logo with Text
          Center(
            child: BizpaddiLogo(
              size: 58,
              variant: isDark ? LogoVariant.whiteMonochrome : LogoVariant.emeraldAndGold,
              showText: true,
            ),
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

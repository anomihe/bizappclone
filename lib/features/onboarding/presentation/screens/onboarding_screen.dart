import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../widgets/onboarding_illustrations.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'prefix': 'Run your ',
      'highlight': 'business',
      'suffix': '\nin one place',
      'subtitle':
          'Get an overview of your entire operations from invoicing, projects, staff to customer orders.',
    },
    {
      'prefix': 'Sell, bill and get\n',
      'highlight': 'paid',
      'suffix': ' easily',
      'subtitle':
          'Generate professional invoices, convert quotes, and accept automated instant bank transfers.',
    },
    {
      'prefix': 'Everything works\n',
      'highlight': 'together',
      'suffix': '',
      'subtitle':
          'Omnichannel CRM, staff attendance & payroll, contracts and autonomous AI staff.',
    },
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToWelcome();
    }
  }

  void _goToWelcome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: 3 Progress Segments & Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // 3 Progress Segments
                  Expanded(
                    child: Row(
                      children: List.generate(3, (index) {
                        final isActive = index <= _currentPage;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Small Brand Icon
                  BizpaddiLogo(
                    size: 26,
                    variant: isDark ? LogoVariant.whiteMonochrome : LogoVariant.emeraldAndGold,
                  ),
                ],
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Title with Highlighted Pill
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item['prefix']!,
                              style: GoogleFonts.figtree(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                item['highlight']!,
                                style: GoogleFonts.figtree(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (item['suffix']!.isNotEmpty)
                              Text(
                                item['suffix']!,
                                style: GoogleFonts.figtree(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Subtitle
                        Text(
                          item['subtitle']!,
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          ),
                        ),

                        const Spacer(),

                        // Center Vector Illustration
                        OnboardingIllustration(index: index),

                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _currentPage < 2
                  ? Row(
                      children: [
                        // Skip Button
                        TextButton(
                          onPressed: _goToWelcome,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Continue Button
                        CustomButton(
                          width: 140,
                          height: 50,
                          text: 'Continue',
                          onPressed: _onNext,
                        ),
                      ],
                    )
                  : CustomButton(
                      height: 52,
                      text: 'Get Started',
                      onPressed: _goToWelcome,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

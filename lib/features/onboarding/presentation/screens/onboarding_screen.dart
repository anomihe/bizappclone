import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Copy and artwork from the latest Splash-Onboard frames.
  final List<Map<String, String>> _pages = [
    {
      'prefix': 'Send an ',
      'highlight': 'invoice.',
      'suffix': ' Get paid from your phone.',
      'subtitle': 'Invoice customers, share the payment link and see who has paid.',
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'prefix': 'Sell online with your own ',
      'highlight': 'store.',
      'suffix': '',
      'subtitle': 'Add products, share your store link and fulfil orders as they come in.',
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'prefix': 'Know where your ',
      'highlight': 'money',
      'suffix': ' is.',
      'subtitle': 'Track payments, your wallet and simple reports in one place.',
      'image': 'assets/images/onboarding_3.png',
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the artwork up front so swiping never shows a blank frame.
    for (final p in _pages) {
      precacheImage(AssetImage(p['image']!), context);
    }
  }

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
        child: ContentWidth(
          maxWidth: 1000,
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

                  // Title with Highlighted Pill
                  // One rich text so the sentence wraps naturally with the pill inline.
                  final titleStyle = GoogleFonts.figtree(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  );
                  final title = Text.rich(TextSpan(style: titleStyle, children: [
                    TextSpan(text: item['prefix']),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9999)),
                        child: Text(item['highlight']!, style: titleStyle.copyWith(color: Colors.white, height: 1.2)),
                      ),
                    ),
                    TextSpan(text: item['suffix']),
                  ]));

                  final subtitle = Text(
                    item['subtitle']!,
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  );

                  // Illustration scales down to whatever space is left.
                  final art = Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: item['subtitle'],
                    ),
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(builder: (context, c) {
                      // Landscape / tablet: text left, illustration right.
                      if (c.maxWidth >= 640 && c.maxWidth > c.maxHeight) {
                        return Row(children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                title,
                                const SizedBox(height: 14),
                                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: subtitle),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(child: art),
                        ]);
                      }
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 12),
                        title,
                        const SizedBox(height: 14),
                        subtitle,
                        const SizedBox(height: 24),
                        Expanded(child: art),
                      ]);
                    }),
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
                        // Boxed "Skip" + wide "Next →", as in the frames.
                        CustomButton(
                          width: 76,
                          height: 50,
                          text: 'Skip',
                          variant: ButtonVariant.soft,
                          onPressed: _goToWelcome,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            height: 50,
                            text: 'Next',
                            trailingIcon: const Icon(Icons.arrow_forward),
                            onPressed: _onNext,
                          ),
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
      ),
    );
  }
}

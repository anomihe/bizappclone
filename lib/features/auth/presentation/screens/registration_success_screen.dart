import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String businessName;
  final String slug;

  const RegistrationSuccessScreen({
    super.key,
    required this.businessName,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Green Checkmark Badge with Gold Arc
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Headline
              Text(
                "You're all set!",
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Your business workspace has been successfully created with 14 days of full feature access.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.border : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Business Name',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          businessName.isNotEmpty ? businessName : 'Acme Solutions',
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      height: 24,
                      color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Storefront Link',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          'store/${slug.isNotEmpty ? slug : "acme"}',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      height: 24,
                      color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Plan',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            '14-Day Free Trial',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Button: "Go to Dashboard"
              CustomButton(
                text: 'Go to Dashboard',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

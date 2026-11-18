import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background Aesthetic Decoration
          if (isDark)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF102820).withOpacity(0.85),
                      AppColors.background,
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.04),
                      AppColors.lightBackground,
                    ],
                  ),
                ),
              ),
            ),

          // Theme Switcher Floating Action in Top Bar
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: () {
                ThemeController.instance.toggleTheme();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surfaceLight : Colors.white,
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: isDark ? AppColors.border : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Central Logo Mark
                  BizpaddiLogo(
                    size: 72,
                    variant: isDark ? LogoVariant.emeraldAndGold : LogoVariant.emeraldAndGold,
                  ),

                  const SizedBox(height: 28),

                  // Headline
                  Text(
                    'Welcome to your\nbusiness workspace',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'The all-in-one platform for invoicing, banking, project delivery and customer operations.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Primary Button: "Create an Account"
                  CustomButton(
                    text: 'Create an Account',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Secondary Button: "Log In"
                  CustomButton(
                    text: 'Log In',
                    variant: isDark ? ButtonVariant.white : ButtonVariant.outline,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Terms & Privacy Footer
                  Text(
                    'By continuing you agree to Bizpaddi Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

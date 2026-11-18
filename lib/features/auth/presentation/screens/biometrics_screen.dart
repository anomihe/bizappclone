import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import 'workspace_setup_screen.dart';

class BiometricsScreen extends StatefulWidget {
  final String currency;

  const BiometricsScreen({super.key, required this.currency});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen> {
  bool _isProcessing = false;

  void _onEnable() async {
    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _proceed();
    }
  }

  void _proceed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkspaceSetupScreen(defaultCurrency: widget.currency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: BizpaddiLogo(size: 26),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Shield Icon with Biometrics Vector
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Headline
              Text(
                'Quick & secure access',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Enable Face ID or fingerprint login to quickly and securely access your business workspace without entering your password every time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Enable Button
              CustomButton(
                text: 'Enable Biometrics',
                isLoading: _isProcessing,
                icon: const Icon(Icons.fingerprint, color: Colors.white, size: 20),
                onPressed: _onEnable,
              ),

              const SizedBox(height: 14),

              // Skip for Now Button
              TextButton(
                onPressed: _proceed,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.figtree(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

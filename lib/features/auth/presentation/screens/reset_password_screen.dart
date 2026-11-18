import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _onReset() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create new password',
                style: GoogleFonts.figtree(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the reset code sent to ${widget.email} and create a strong new password.',
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
              ),

              const SizedBox(height: 28),

              CustomTextField(
                label: 'Reset Code',
                hint: '6-digit code',
                controller: _codeController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(
                  Icons.vpn_key_outlined,
                  size: 20,
                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),

              const SizedBox(height: 18),

              CustomTextField(
                label: 'New Password',
                hint: '••••••••',
                controller: _newPasswordController,
                isPassword: true,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),

              const SizedBox(height: 18),

              CustomTextField(
                label: 'Confirm New Password',
                hint: '••••••••',
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Reset Password',
                isLoading: _isLoading,
                onPressed: _onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

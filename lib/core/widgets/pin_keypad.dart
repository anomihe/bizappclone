import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PinKeypad extends StatelessWidget {
  final Function(String) onDigitPress;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometricPress;
  final bool showBiometric;

  const PinKeypad({
    super.key,
    required this.onDigitPress,
    required this.onBackspace,
    this.onBiometricPress,
    this.showBiometric = false,
  });

  Widget _buildKey(BuildContext context, String text, {Widget? icon, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (onTap != null) {
              onTap();
            } else {
              onDigitPress(text);
            }
          },
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.surface : Colors.white,
              border: Border.fromBorderSide(
                BorderSide(
                  color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: icon ??
                  Text(
                    text,
                    style: GoogleFonts.figtree(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            _buildKey(context, '1'),
            _buildKey(context, '2'),
            _buildKey(context, '3'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '4'),
            _buildKey(context, '5'),
            _buildKey(context, '6'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '7'),
            _buildKey(context, '8'),
            _buildKey(context, '9'),
          ],
        ),
        Row(
          children: [
            if (showBiometric && onBiometricPress != null)
              _buildKey(
                context,
                '',
                icon: Icon(
                  Icons.fingerprint,
                  size: 28,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
                onTap: onBiometricPress,
              )
            else
              const Expanded(child: SizedBox(height: 64)),
            _buildKey(context, '0'),
            _buildKey(
              context,
              '',
              icon: Icon(
                Icons.backspace_outlined,
                size: 22,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
              onTap: onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

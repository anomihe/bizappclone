import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/pin_keypad.dart';
import 'biometrics_screen.dart';

class ConfirmPinScreen extends StatefulWidget {
  final String originalPin;
  final String currency;

  const ConfirmPinScreen({
    super.key,
    required this.originalPin,
    required this.currency,
  });

  @override
  State<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  String _pin = '';
  String? _errorMessage;

  void _onDigit(String d) {
    if (_pin.length < 6) {
      setState(() {
        _pin += d;
        _errorMessage = null;
      });

      if (_pin.length == 6) {
        if (_pin == widget.originalPin) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BiometricsScreen(currency: widget.currency),
                ),
              );
            }
          });
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Please try again.';
            _pin = '';
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
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
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Headline
            Text(
              'Confirm security PIN',
              style: GoogleFonts.figtree(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Re-enter your 6-digit security PIN to confirm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // 6 PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? AppColors.primary
                          : (isDark ? AppColors.border : AppColors.lightBorder),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],

            const Spacer(),

            // Custom On-Screen Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: PinKeypad(
                onDigitPress: _onDigit,
                onBackspace: _onBackspace,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

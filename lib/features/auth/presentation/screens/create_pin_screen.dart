import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/pin_keypad.dart';
import 'confirm_pin_screen.dart';

class CreatePinScreen extends StatefulWidget {
  final String currency;

  const CreatePinScreen({super.key, required this.currency});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length < 6) {
      setState(() {
        _pin += d;
      });

      if (_pin.length == 6) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConfirmPinScreen(
                  originalPin: _pin,
                  currency: widget.currency,
                ),
              ),
            );
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
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
              'Set security PIN',
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
                'Create a 6-digit PIN to securely authorize invoices, payouts, and sensitive workspace actions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
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

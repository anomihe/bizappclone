import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';

/// "Reset Password" — step 1: ask for email or phone.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _id = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          title: "Verify it's you.",
          subtitle: 'Please enter the 6-digit code sent to your phone number: +234 ****** 484. Enter it below to continue.',
          onVerified: (ctx) => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const ResetPasswordScreen())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return AuthScaffold(
      title: 'Reset Password',
      subtitle: "Enter the email or phone number on your account. We'll send a code to verify it's you.",
      footer: Text.rich(TextSpan(children: [
        TextSpan(text: 'Remembered my password? ', style: tx(context, 12.5, color: p.textSecondary)),
        TextSpan(
          text: 'Log in',
          style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand),
          recognizer: TapGestureRecognizer()..onTap = () => Navigator.pop(context),
        ),
      ])),
      children: [
        CustomTextField(
          label: 'Email or Phone',
          hint: 'Enter your email',
          controller: _id,
          keyboardType: TextInputType.emailAddress,
          suffixIcon: _id.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.cancel_outlined, size: 18, color: p.textMuted),
                  onPressed: () => setState(() => _id.clear()),
                ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        CustomButton(text: 'Reset Password', isLoading: _loading, onPressed: _id.text.trim().isEmpty ? null : _send),
      ],
    );
  }
}

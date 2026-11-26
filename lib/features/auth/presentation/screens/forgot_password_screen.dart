import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'reset_password_screen.dart';

/// "Reset Password" — step 1: ask for the account email.
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
    // The backend emails a reset link / code.
    if (!Fmt.isEmail(_id.text)) {
      showToast(context, 'Enter the email address on your account');
      return;
    }
    setState(() => _loading = true);
    try {
      await LiveSession.instance.sendResetLink(_id.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetLinkSentScreen(email: _id.text.trim())));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return AuthScaffold(
      title: 'Reset Password',
      subtitle: "Enter the email on your account. We'll email you a link and code to reset your password.",
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
          label: 'Email',
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

/// Live mode: the backend emails a password-reset link.
class ResetLinkSentScreen extends StatelessWidget {
  final String email;
  const ResetLinkSentScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: FillScroll(
          child: Center(
            child: ContentWidth(
              maxWidth: Breakpoints.form,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text('Check your email', textAlign: TextAlign.center, style: tx(context, 19, weight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'If an account exists for $email, we’ve sent a link to reset your password. Open it, choose a new password, then log in here.',
                    textAlign: TextAlign.center,
                    style: tx(context, 12.5, color: p.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  CustomButton(text: 'Back to Log in', onPressed: () => Navigator.pop(context)),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'I have a reset code',
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email))),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

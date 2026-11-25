import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';
import '../widgets/auth_scaffold.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _error;

  // The backend logs in by email only.
  bool get _valid => (LiveSession.enabled ? Fmt.isEmail(_id.text) : _id.text.trim().isNotEmpty) && _password.text.isNotEmpty;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    if (LiveSession.enabled) {
      try {
        await LiveSession.instance.login(_id.text, _password.text);
        // The backend has no device-verification code; go straight in.
        if (mounted) MainNavigationScreen.go(context);
      } on ApiException catch (e) {
        if (mounted) setState(() => _error = e.message);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          title: 'Verify your device',
          subtitle: 'Please enter the 6-digit code sent to your phone number: +234 ****** 484. Enter it below to continue.',
          onVerified: (ctx) {
            BizStore.instance.loadDemoWorkspace();
            MainNavigationScreen.go(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return AuthScaffold(
      title: 'Log in',
      subtitle: "Enter your email or phone number. We'll send a one-time code to verify it's you.",
      footer: Text.rich(TextSpan(children: [
        TextSpan(text: "Don't have an account? ", style: tx(context, 12.5, color: p.textSecondary)),
        TextSpan(
          text: 'Sign up',
          style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
        ),
      ])),
      children: [
        CustomTextField(
          label: LiveSession.enabled ? 'Email' : 'Email or Phone',
          hint: 'Enter your email',
          controller: _id,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Password',
          hint: 'Enter Password',
          controller: _password,
          isPassword: true,
          prefixIcon: Icon(Icons.lock_outline, size: 18, color: p.textMuted),
          onChanged: (_) => setState(() {}),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            child: Text('Forgot Password?', style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand)),
          ),
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.errorSoft, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.error_outline, size: 18, color: p.error),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: tx(context, 12.5, color: p.error))),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        CustomButton(text: 'Log in', isLoading: _loading, onPressed: _valid ? _login : null),
      ],
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/api/repositories.dart' show TwoFactorRequired;
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/biometrics.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';
import '../../../onboarding/presentation/screens/welcome_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'two_factor_challenge.dart';

/// Returning user on this device: password, or fingerprint / Face ID if they turned it on.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  final _password = TextEditingController();
  bool _loading = false;
  String? _savedEmail;
  bool _biometricOn = false;

  @override
  void initState() {
    super.initState();
    LiveSession.instance.savedEmail().then((e) {
      if (mounted) setState(() => _savedEmail = e);
    });
    Biometrics.isEnabled().then((on) {
      if (mounted) setState(() => _biometricOn = on);
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// No remembered email: fall back to the full login form.
  void _toLogin() => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);

  Future<void> _continue() async {
    if (_savedEmail == null) return _toLogin();
    setState(() => _loading = true);
    try {
      await LiveSession.instance.login(_savedEmail!, _password.text);
      if (mounted) MainNavigationScreen.go(context);
    } on TwoFactorRequired catch (t) {
      if (mounted) await openTwoFactorChallenge(context, t.challengeToken, onSignedIn: MainNavigationScreen.go);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The real OS fingerprint / Face ID prompt re-opens the saved session.
  Future<void> _fingerprint() async {
    final passed = await Biometrics.authenticate('Unlock Bizpaddi');
    if (!mounted) return;
    if (!passed) {
      showToast(context, 'Fingerprint / Face ID not confirmed. Enter your password to continue.');
      return;
    }
    try {
      await LiveSession.instance.resume();
      if (mounted) MainNavigationScreen.go(context);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.isUnauthorized ? 'Your session ended. Enter your password to continue.' : e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    // The account isn't loaded yet, so greet by the saved email.
    final displayName = _savedEmail ?? '';

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          const AuthTopBar(showClose: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(children: [
                InitialsAvatar(displayName.isEmpty ? '?' : displayName, size: 64),
                const SizedBox(height: 12),
                Text('Welcome Back,', style: tx(context, 13, color: p.textSecondary)),
                Text(displayName, style: tx(context, 18, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Enter your login password to continue.', style: tx(context, 12.5, color: p.textSecondary)),
                const SizedBox(height: 22),
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
                CustomButton(text: 'Continue', isLoading: _loading, onPressed: _password.text.isEmpty ? null : _continue),
                if (_biometricOn) ...[
                  const SizedBox(height: 10),
                  CustomButton(text: 'Log in with Fingerprint', variant: ButtonVariant.outline, icon: const Icon(Icons.fingerprint), onPressed: _fingerprint),
                ],
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Not You? ', style: tx(context, 12.5, color: p.textSecondary)),
              TextSpan(
                text: 'Log Out',
                style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    BizStore.instance.hasRememberedUser = false;
                    LiveSession.instance.logout();
                    LiveSession.instance.tokens.clearAll();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
                  },
              ),
            ])),
          ),
        ]),
      ),
    );
  }
}

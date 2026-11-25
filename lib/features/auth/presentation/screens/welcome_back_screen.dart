import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';
import '../../../onboarding/presentation/screens/welcome_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';

/// Returning user on this device: password or fingerprint.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    if (LiveSession.enabled) {
      LiveSession.instance.savedEmail().then((e) {
        if (mounted) setState(() => _savedEmail = e);
      });
    }
  }

  /// Live mode with no remembered email: fall back to the full login form.
  void _toLogin() => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);

  void _enter() {
    if (!LiveSession.enabled) BizStore.instance.loadDemoWorkspace();
    MainNavigationScreen.go(context);
  }

  Future<void> _continue() async {
    setState(() => _loading = true);
    if (LiveSession.enabled) {
      if (_savedEmail == null) return _toLogin();
      try {
        await LiveSession.instance.login(_savedEmail!, _password.text);
        if (mounted) _enter();
      } on ApiException catch (e) {
        if (mounted) showToast(context, e.message);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _enter();
  }

  /// Live mode: biometrics re-open the saved session token.
  Future<void> _resumeLive() async {
    try {
      await LiveSession.instance.resume();
      if (mounted) _enter();
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.isUnauthorized ? 'Your session ended. Enter your password to continue.' : e.message);
    }
  }

  /// Visual stand-in for the OS biometric prompt (needs `local_auth` for real).
  Future<void> _fingerprint() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (ctx.mounted) Navigator.pop(ctx, true);
        });
        return Dialog(
          backgroundColor: ctx.p.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ctx.p.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: const BizpaddiLogo(size: 30),
              ),
              const SizedBox(height: 12),
              Text('Bizpaddi', style: tx(ctx, 15, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Verify Fingerprint', style: tx(ctx, 12.5, color: ctx.p.textSecondary)),
              const SizedBox(height: 20),
              Icon(Icons.fingerprint, size: 56, color: context.p.brand),
            ]),
          ),
        );
      },
    );
    if (ok == true && mounted) LiveSession.enabled ? await _resumeLive() : _enter();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final account = BizStore.instance.account;
    // Live mode: the workspace isn't loaded yet, so greet by the saved email.
    final displayName = LiveSession.enabled ? (_savedEmail ?? '') : account.ownerFullName;

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
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Log in with Fingerprint',
                  variant: ButtonVariant.outline,
                  icon: const Icon(Icons.fingerprint),
                  onPressed: _fingerprint,
                ),
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
                    if (LiveSession.enabled) {
                      LiveSession.instance.logout();
                      LiveSession.instance.tokens.clearAll();
                    }
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

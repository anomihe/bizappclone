import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/password_rules.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';

/// "Set New Password" — step 3 of reset.
///
/// With [email] (live mode) it also asks for the code from the reset email
/// and calls `POST /api/v1/auth/reset-password`.
class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _withToken => widget.email != null && LiveSession.enabled;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _mismatch => _confirm.text.isNotEmpty && _confirm.text != _password.text;
  bool get _valid => PasswordRules.isValid(_password.text) && _confirm.text == _password.text && (!_withToken || _token.text.trim().isNotEmpty);

  /// Accepts the raw token or the whole link from the email (…/reset-password/{token}?email=…).
  String get _tokenValue {
    final t = _token.text.trim();
    final uri = Uri.tryParse(t);
    if (uri != null && uri.pathSegments.isNotEmpty && t.contains('/')) return uri.pathSegments.last;
    return t;
  }

  Future<void> _save() async {
    setState(() => (_loading = true, _error = null));
    try {
      if (_withToken) {
        await LiveSession.instance.resetPassword(token: _tokenValue, email: widget.email!, password: _password.text);
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => (_loading = false, _error = e.message));
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PasswordUpdatedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set New Password',
      children: [
        if (_withToken) ...[
          CustomTextField(label: 'Reset code', hint: 'Paste the code or link from the email', controller: _token, onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
        ],
        CustomTextField(label: 'New Password', hint: 'Enter New Password', controller: _password, isPassword: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Confirm New Password',
          hint: 'Enter New Password',
          controller: _confirm,
          isPassword: true,
          errorText: _mismatch ? 'Passwords do not match' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        PasswordRulesView(password: _password.text),
        const SizedBox(height: 20),
        if (_error != null) ...[Text(_error!, style: tx(context, 12.5, color: context.p.error)), const SizedBox(height: 10)],
        CustomButton(text: 'Continue', isLoading: _loading, onPressed: _valid && !_loading ? _save : null),
      ],
    );
  }
}

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: FillScroll(child: Center(
          child: ContentWidth(maxWidth: Breakpoints.form, alignment: Alignment.center, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.password, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 18),
              Text('Password Updated\nSuccessfully', textAlign: TextAlign.center, style: tx(context, 19, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'You can now login with your new password. All other devices have been signed out for your security.',
                textAlign: TextAlign.center,
                style: tx(context, 12.5, color: p.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 22),
              CustomButton(
                text: 'Proceed to Login',
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => r.isFirst,
                ),
              ),
            ]),
          )),
        )),
      ),
    );
  }
}

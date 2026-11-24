import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/password_rules.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';

/// "Set New Password" — step 3 of reset.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _mismatch => _confirm.text.isNotEmpty && _confirm.text != _password.text;
  bool get _valid => PasswordRules.isValid(_password.text) && _confirm.text == _password.text;

  Future<void> _save() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PasswordUpdatedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set New Password',
      children: [
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
        CustomButton(text: 'Continue', isLoading: _loading, onPressed: _valid ? _save : null),
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

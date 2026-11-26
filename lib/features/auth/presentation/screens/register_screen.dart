import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/password_rules.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'biometrics_screen.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

/// Sign-up, the same as the web (app.bizpaddi.com/dashboard/register):
/// email → 6-digit email code → business and owner details.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const SignupEmailScreen();
}

Widget _loginLink(BuildContext context) => Text.rich(TextSpan(children: [
      TextSpan(text: 'Already have an account? ', style: tx(context, 12.5, color: context.p.textSecondary)),
      TextSpan(
        text: 'Log in',
        style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand),
        recognizer: TapGestureRecognizer()
          ..onTap = () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      ),
    ]));

/// Step 1 of 3: the email that gets the verification code.
class SignupEmailScreen extends StatefulWidget {
  const SignupEmailScreen({super.key});

  @override
  State<SignupEmailScreen> createState() => _SignupEmailScreenState();
}

class _SignupEmailScreenState extends State<SignupEmailScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<String?> _send() async {
    try {
      await LiveSession.instance.sendSignupCode(_email.text.trim());
      return null;
    } on ApiException catch (e) {
      return e.errorFor('email') ?? e.message;
    }
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _send();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    if (error != null) return;

    final email = _email.text.trim();
    var code = '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          title: 'Verify your email',
          subtitle: 'Step 2 of 3 — We sent a 6-digit code to $email. It expires in 15 minutes.',
          onSubmit: (c) async {
            code = c;
            try {
              await LiveSession.instance.verifySignupCode(email, c);
              return null;
            } on ApiException catch (e) {
              return e.errorFor('otp_code') ?? e.message;
            }
          },
          onResend: _send,
          onVerified: (ctx) => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => SignupDetailsScreen(email: email, code: code))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Get started with Bizpaddi',
      subtitle: 'Step 1 of 3 — Enter your email address to receive a verification code.',
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        CustomButton(text: 'Continue & Send Code', isLoading: _loading, onPressed: Fmt.isEmail(_email.text) ? _continue : null),
        const SizedBox(height: 12),
        _loginLink(context),
      ]),
      children: [
        CustomTextField(
          label: 'Email Address',
          hint: 'name@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(Icons.alternate_email, size: 18, color: context.p.textMuted),
          errorText: _error,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 8),
        Text('Personal or business email accepted. We’ll send a 6-digit code to verify it.',
            style: tx(context, 12, color: context.p.textSecondary, height: 1.4)),
      ],
    );
  }
}

/// Step 3 of 3: business and owner details; creates the workspace.
class SignupDetailsScreen extends StatefulWidget {
  final String email;
  final String code;
  const SignupDetailsScreen({super.key, required this.email, required this.code});

  @override
  State<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends State<SignupDetailsScreen> {
  final _company = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  CountryInfo _country = CountryInfo.all.first;
  bool _agreed = false;
  bool _loading = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final c in [_company, _first, _last, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _company.text.trim().isNotEmpty &&
      _first.text.trim().isNotEmpty &&
      _last.text.trim().isNotEmpty &&
      PasswordRules.isValid(_password.text) &&
      _agreed;

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LiveSession.instance.register(
        companyName: _company.text,
        firstName: _first.text,
        lastName: _last.text,
        email: widget.email,
        dialCode: _country.dialCode,
        phone: _phone.text,
        password: _password.text,
        otp: widget.code,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BiometricsScreen()), (r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      // An expired code can't be fixed here: start again from the email.
      if (e.errorFor('otp_code') != null) {
        showToast(context, e.errorFor('otp_code')!);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupEmailScreen()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void refresh(_) => setState(() {});
    final e = _error;
    final general = e != null && e.fieldErrors.isEmpty ? e.message : null;

    return AuthScaffold(
      title: 'Set up your workspace',
      subtitle: 'Step 3 of 3 — ${widget.email} is verified. Tell us about your business.',
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        if (general != null) ...[
          Text(general, textAlign: TextAlign.center, style: tx(context, 12.5, color: context.p.error)),
          const SizedBox(height: 10),
        ],
        CustomButton(text: 'Create My Workspace', isLoading: _loading, onPressed: _valid ? _create : null),
      ]),
      children: [
        CustomTextField(
          label: 'Business Name',
          hint: 'Enter your business name',
          controller: _company,
          textCapitalization: TextCapitalization.words,
          errorText: e?.errorFor('company_name'),
          onChanged: refresh,
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: CustomTextField(
              label: 'First Name',
              hint: 'First name',
              controller: _first,
              textCapitalization: TextCapitalization.words,
              errorText: e?.errorFor('first_name'),
              onChanged: refresh,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomTextField(
              label: 'Last Name',
              hint: 'Last name',
              controller: _last,
              textCapitalization: TextCapitalization.words,
              errorText: e?.errorFor('last_name'),
              onChanged: refresh,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        PhoneField(controller: _phone, country: _country, onCountryChanged: (c) => setState(() => _country = c), onChanged: refresh),
        if (e?.errorFor('phone') != null) Text(e!.errorFor('phone')!, style: tx(context, 11.5, color: context.p.error)),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Password',
          hint: 'Enter Password',
          controller: _password,
          isPassword: true,
          errorText: e?.errorFor('password'),
          onChanged: refresh,
        ),
        const SizedBox(height: 10),
        PasswordRulesView(password: _password.text),
        const SizedBox(height: 16),
        _TermsRow(agreed: _agreed, onChanged: (v) => setState(() => _agreed = v)),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;
  const _TermsRow({required this.agreed, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!agreed),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: agreed,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('By continuing you accept the Bizpaddi terms and privacy policy.',
                style: tx(context, 12, color: context.p.textSecondary, height: 1.4)),
          ),
        ]),
      );
}


import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/password_rules.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'biometrics_screen.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

const businessCategories = [
  'Food & Drinks',
  'Fashion & Tailoring',
  'Beauty & Cosmetics',
  'Electronics & Gadgets',
  'Retail & Provisions',
  'Services',
  'Other',
];

const currencies = ['Naira (NGN)', 'Ghana Cedi (GHS)', 'Kenyan Shilling (KES)', 'US Dollar (USD)', 'British Pound (GBP)'];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  CountryInfo _country = CountryInfo.all.first;
  String? _category;
  String _currency = currencies.first;
  bool _agreed = false;
  bool _loading = false;
  bool _emailTouched = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailValid => Fmt.isEmail(_email.text);
  bool get _phoneValid => _phone.text.replaceAll(' ', '').length >= 7;

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _emailValid &&
      _phoneValid &&
      _category != null &&
      PasswordRules.isValid(_password.text) &&
      _agreed;

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);

    final masked = Fmt.maskPhone(_country.dialCode, _phone.text);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          title: 'Verify your phone',
          subtitle: 'We sent a 6-digit code to $masked. It expires in 5 minutes.',
          onVerified: (ctx) {
            BizStore.instance.startNewWorkspace(
              businessName: _name.text.trim(),
              email: _email.text.trim(),
              dialCode: _country.dialCode,
              phone: _phone.text.trim(),
              category: _category!,
              currency: _currency,
            );
            Navigator.pushAndRemoveUntil(
              ctx,
              MaterialPageRoute(builder: (_) => const BiometricsScreen()),
              (r) => r.isFirst,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    void refresh(_) => setState(() {});

    return AuthScaffold(
      title: 'Create an account.',
      subtitle: 'It takes about a minute.',
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        CustomButton(text: 'Continue', isLoading: _loading, onPressed: _valid ? _submit : null),
        const SizedBox(height: 12),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Already have an account? ', style: tx(context, 12.5, color: p.textSecondary)),
          TextSpan(
            text: 'Log in',
            style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ])),
      ]),
      children: [
        CustomTextField(
          label: 'Business Name',
          hint: 'Enter your business name',
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: refresh,
        ),
        const SizedBox(height: 14),
        Focus(
          onFocusChange: (f) {
            if (!f) setState(() => _emailTouched = true);
          },
          child: CustomTextField(
            label: 'Business Email',
            hint: 'Enter your email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailTouched && _email.text.isNotEmpty && !_emailValid ? 'Invalid email address' : null,
            onChanged: refresh,
          ),
        ),
        const SizedBox(height: 14),
        PhoneField(
          controller: _phone,
          country: _country,
          onCountryChanged: (c) => setState(() => _country = c),
          onChanged: refresh,
        ),
        const SizedBox(height: 14),
        SelectField(
          label: 'Business Category',
          hint: 'Select category',
          value: _category,
          options: businessCategories,
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 14),
        SelectField(
          label: 'Currency',
          hint: 'Select currency',
          value: _currency,
          options: currencies,
          onChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 14),
        CustomTextField(label: 'Password', hint: 'Enter Password', controller: _password, isPassword: true, onChanged: refresh),
        const SizedBox(height: 10),
        PasswordRulesView(password: _password.text),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => setState(() => _agreed = !_agreed),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('By continuing you accept the Bizpaddi terms and privacy policy.',
                  style: tx(context, 12, color: p.textSecondary, height: 1.4)),
            ),
          ]),
        ),
      ],
    );
  }
}

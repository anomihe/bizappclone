import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/presentation/screens/otp_verification_screen.dart';

const nigerianBanks = ['Access Bank', 'GTBank', 'First Bank', 'UBA', 'Zenith Bank', 'Wema Bank', 'Opay', 'Moniepoint', 'Kuda'];

/// Security gate before bank details can change:
/// fingerprint or password → phone OTP → bank form.
Future<void> startBankChange(BuildContext context) async {
  final method = await showBpSheet<String>(
    context,
    showHandle: true,
    builder: (ctx) {
      final p = ctx.p;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(width: 56, height: 56, decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle), child: Icon(Icons.fingerprint, color: p.brand, size: 30)),
        ),
        const SizedBox(height: 12),
        Text('Confirm it is you', textAlign: TextAlign.center, style: tx(ctx, 16, weight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Bank details are sensitive. Confirm with your fingerprint or password, then a code.', textAlign: TextAlign.center, style: tx(ctx, 12.5, color: p.textSecondary)),
        const SizedBox(height: 18),
        CustomButton(text: 'Use Fingerprint', icon: const Icon(Icons.fingerprint), onPressed: () => Navigator.pop(ctx, 'bio')),
        const SizedBox(height: 10),
        CustomButton(text: 'Use Password', variant: ButtonVariant.soft, icon: const Icon(Icons.key_outlined), onPressed: () => Navigator.pop(ctx, 'password')),
      ]);
    },
  );
  if (method == null || !context.mounted) return;

  if (method == 'password') {
    final ok = await showBpSheet<bool>(context, title: 'Bank details', builder: (_) => const _PasswordCheck());
    if (ok != true || !context.mounted) return;
  } else {
    // Real biometric prompt needs `local_auth`.
    showToast(context, 'Fingerprint confirmed');
  }

  final profile = BizStore.instance.profile;
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OtpVerificationScreen(
        title: 'Verify your phone',
        subtitle: 'We sent a 6-digit code to ${Fmt.maskPhone(profile.dialCode, profile.phone.isEmpty ? '0000' : profile.phone)}. It expires in 5 minutes.',
        onVerified: (ctx) => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const BankDetailsScreen())),
      ),
    ),
  );
}

class _PasswordCheck extends StatefulWidget {
  const _PasswordCheck();
  @override
  State<_PasswordCheck> createState() => _PasswordCheckState();
}

class _PasswordCheckState extends State<_PasswordCheck> {
  final _password = TextEditingController();
  bool _wrong = false;
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Demo rule until auth exists: fewer than 6 characters is "wrong".
  Future<void> _check() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_password.text.length < 6) {
      setState(() {
        _loading = false;
        _wrong = true;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('To protect your money, enter your password to continue.', style: tx(context, 12.5, color: context.p.textSecondary)),
      const SizedBox(height: 14),
      CustomTextField(
        label: 'Password',
        hint: 'Enter Password',
        controller: _password,
        isPassword: true,
        autofocus: true,
        prefixIcon: Icon(Icons.lock_outline, size: 18, color: context.p.textMuted),
        errorText: _wrong ? 'Wrong password. Try again' : null,
        onChanged: (_) => setState(() => _wrong = false),
      ),
      const SizedBox(height: 16),
      CustomButton(text: 'Continue', isLoading: _loading, onPressed: _password.text.isEmpty ? null : _check),
    ]);
  }
}

class BankSettlementScreen extends StatelessWidget {
  const BankSettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final bank = store.profile.bank;
        return InnerScaffold(
          title: 'Bank and Settlement',
          bottom: CustomButton(
            text: bank == null ? 'Add Bank Details' : 'Change Bank Details',
            variant: ButtonVariant.soft,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => startBankChange(context),
          ),
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (bank != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.brand.withValues(alpha: 0.4))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PAYOUTS GO TO', style: tx(context, 10.5, weight: FontWeight.w700, color: p.brand).copyWith(letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(bank.bank, style: tx(context, 12.5, color: p.textSecondary)),
                  Text(bank.masked, style: tx(context, 20, weight: FontWeight.w800)),
                  Text(bank.name, style: tx(context, 11.5, weight: FontWeight.w700, color: p.textSecondary)),
                ]),
              )
            else
              const EmptyState(icon: Icons.account_balance_outlined, title: 'No settlement account added', message: 'Add a bank account to receive payouts.'),
            const SizedBox(height: 18),
            if (store.profile.bankHistory.isNotEmpty) ...[
              const SectionLabel('Change History'),
              for (final h in store.profile.bankHistory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BpCard(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h.title, style: tx(context, 13, weight: FontWeight.w700)),
                          Text(h.detail, style: tx(context, 11.5, color: p.textMuted)),
                        ]),
                      ),
                      Text(Fmt.date(h.date), style: tx(context, 11, color: p.textMuted)),
                    ]),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text('Changes to your payout account need your password and a code. Every change is logged here.',
                textAlign: TextAlign.center, style: tx(context, 11, color: p.textMuted)),
          ]),
        );
      },
    );
  }
}

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _number = TextEditingController();
  String? _bank;
  String? _accountName;
  bool _resolving = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() => _accountName = null);
    if (_bank == null || _number.text.length != 10) return;
    setState(() => _resolving = true);
    final name = await BizStore.instance.resolveAccountName(_bank!, _number.text);
    if (!mounted) return;
    setState(() {
      _resolving = false;
      _accountName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InnerScaffold(
      title: 'Bank Details',
      bottom: CustomButton(
        text: 'Save Bank Details',
        onPressed: _accountName == null
            ? null
            : () {
                BizStore.instance.setBankAccount(BankAccount(bank: _bank!, number: _number.text, name: _accountName!));
                showToast(context, 'Bank details saved');
                Navigator.pop(context);
              },
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SelectField(
          label: 'Bank',
          hint: 'Select bank',
          value: _bank,
          options: nigerianBanks,
          onChanged: (v) {
            setState(() => _bank = v);
            _resolve();
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Account Number',
          hint: 'Enter 10-digit account number',
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          onChanged: (_) => _resolve(),
        ),
        const SizedBox(height: 4),
        Text('${_number.text.length}/10 digits', style: tx(context, 11, color: p.textMuted)),
        const SizedBox(height: 14),
        Text('Account Name', style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
          child: Row(children: [
            Expanded(
              child: Text(
                _resolving ? 'Checking account…' : (_accountName ?? 'Shows after you enter the account number'),
                style: tx(context, 13.5, weight: _accountName == null ? FontWeight.w400 : FontWeight.w700, color: _accountName == null ? p.textMuted : p.text),
              ),
            ),
            if (_resolving) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            if (_accountName != null) const Icon(Icons.verified, size: 18, color: AppColors.primaryLight),
          ]),
        ),
        const SizedBox(height: 14),
        Text('Use an account in your business name. Payouts can only go to this account.', style: tx(context, 11, color: p.textMuted)),
      ]),
    );
  }
}

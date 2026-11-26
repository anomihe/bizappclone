import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/presentation/screens/otp_verification_screen.dart';

/// Opens the bank form. Saving it asks for the account password and an
/// emailed code; the backend checks both before the payout account changes.
Future<void> startBankChange(BuildContext context) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDetailsScreen()));

/// Asks for the account password (the backend checks it with the code).
Future<String?> _askPassword(BuildContext context) =>
    showBpSheet<String>(context, title: 'Confirm it is you', builder: (_) => const _PasswordStep());

class _PasswordStep extends StatefulWidget {
  const _PasswordStep();
  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Bank details are sensitive. Enter your password, then the code we email you.', style: tx(context, 12.5, color: context.p.textSecondary)),
      const SizedBox(height: 14),
      CustomTextField(
        label: 'Password',
        hint: 'Enter Password',
        controller: _password,
        isPassword: true,
        autofocus: true,
        prefixIcon: Icon(Icons.lock_outline, size: 18, color: context.p.textMuted),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      CustomButton(text: 'Continue', onPressed: _password.text.isEmpty ? null : () => Navigator.pop(context, _password.text)),
    ]);
  }
}

class BankSettlementScreen extends StatefulWidget {
  const BankSettlementScreen({super.key});

  @override
  State<BankSettlementScreen> createState() => _BankSettlementScreenState();
}

class _BankSettlementScreenState extends State<BankSettlementScreen> {
  @override
  void initState() {
    super.initState();
    // Latest account and change history from the backend.
    LiveSession.instance.refreshSettlementAccount().catchError((_) {});
  }

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

typedef _Bank = ({String name, String code});

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _number = TextEditingController();
  List<_Bank>? _banks;
  String? _bankError;
  _Bank? _bank;
  String? _accountName;
  String? _resolveError;
  bool _resolving = false;
  bool _saving = false;
  int _lookup = 0;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() => _bankError = null);
    try {
      final list = await LiveSession.instance.settlementBanks();
      if (!mounted) return;
      setState(() => _banks = [for (final b in list) (name: '${b['name'] ?? ''}', code: '${b['code'] ?? ''}')]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _bankError = e.message);
    }
  }

  Future<void> _resolve() async {
    final ticket = ++_lookup;
    setState(() {
      _accountName = null;
      _resolveError = null;
      _resolving = false;
    });
    if (_bank == null || _number.text.length != 10) return;
    setState(() => _resolving = true);
    String? name;
    String? error;
    try {
      name = await LiveSession.instance.resolveBankAccount(_bank!.code, _number.text);
      if (name.isEmpty) error = 'We couldn’t find that account.';
    } on ApiException catch (e) {
      error = e.message;
    }
    if (!mounted || ticket != _lookup) return;
    setState(() {
      _resolving = false;
      _accountName = error == null ? name : null;
      _resolveError = error;
    });
  }

  Future<String?> _guard(Future<void> Function() fn) async {
    try {
      await fn();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> _save() async {
    final password = await _askPassword(context);
    if (password == null || !mounted) return;
    setState(() => _saving = true);
    var sentTo = 'your email';
    final sendError = await _guard(() async {
      final to = await LiveSession.instance.sendSettlementCode();
      if (to.isNotEmpty) sentTo = to;
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (sendError != null) {
      showToast(context, sendError);
      return;
    }
    final bank = _bank!;
    final number = _number.text;
    final form = context;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          title: 'Enter the code',
          subtitle: 'We sent a 6-digit code to $sentTo. It expires in 10 minutes.',
          onSubmit: (code) => _guard(() => LiveSession.instance.saveSettlementAccount(bankCode: bank.code, number: number, password: password, otp: code)),
          onResend: () => _guard(() => LiveSession.instance.sendSettlementCode()),
          onVerified: (ctx) {
            Navigator.pop(ctx); // the code screen
            if (form.mounted) {
              showToast(form, 'Bank details saved');
              Navigator.pop(form); // the bank form
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final banks = _banks;
    return InnerScaffold(
      title: 'Bank Details',
      bottom: CustomButton(text: 'Save Bank Details', isLoading: _saving, onPressed: _accountName == null ? null : _save),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_bankError != null)
          BpCard(
            child: Row(children: [
              Expanded(child: Text(_bankError!, style: tx(context, 12.5, color: p.error))),
              TextButton(onPressed: _loadBanks, child: const Text('Retry')),
            ]),
          )
        else if (banks == null)
          const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
        else
          SelectField(
            label: 'Bank',
            hint: 'Select bank',
            value: _bank?.name,
            options: [for (final b in banks) b.name],
            onChanged: (v) {
              setState(() => _bank = banks.firstWhere((b) => b.name == v));
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
          errorText: _resolveError,
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

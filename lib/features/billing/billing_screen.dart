import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/api/live_session.dart';
import '../../core/api/mappers.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/ui_kit.dart';

/// More → Wallet & Billing: operating wallet, plan, what actions cost.
///
/// Money goes in by bank transfer to a Billway account. That's offered on
/// Android only: on iOS, Apple doesn't allow paying for the service outside
/// in-app purchase, so the iOS app shows the balance and plan read-only.
class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  /// Whether this build may start a payment (see class docs).
  static bool get canPay => kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  /// Prompts for an amount, creates the Billway virtual account, and shows
  /// transfer details. Usable from both Home and Wallet & Billing.
  static Future<void> topUp(BuildContext context, {Future<void> Function()? onPaid}) async {
    final t = await _askAndCreateTopUp(context);
    if (t == null || !context.mounted) return;
    await _showTransferSheet(context, t, 'Top up your wallet', onPaid: onPaid ?? LiveSession.instance.refreshBilling);
  }

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _loading = false;
  int? _activatingPlanId;
  String? _error;

  Map<String, dynamic>? get _data => LiveSession.instance.billing.value;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LiveSession.instance.refreshBilling();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _topUp() => BillingScreen.topUp(context, onPaid: _refresh);

  Future<void> _activate(Map plan) async {
    final id = ApiMappers.intOrNull(plan['id']);
    if (id == null || _activatingPlanId != null) return;
    setState(() => _activatingPlanId = id);
    try {
      final t = await LiveSession.instance.business.checkoutPlan(id);
      if (mounted) await _showTransferSheet(context, t, 'Activate ${plan['name']}', onPaid: _refresh);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _activatingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: LiveSession.instance.billing,
      builder: (context, _, _) {
        final d = _data;
        return InnerScaffold(
          title: 'Wallet & Billing',
          subtitle: 'Balance, plan and charges',
          actions: [CircleIconButton(icon: Icons.refresh, tooltip: 'Refresh', onTap: _loading ? () {} : _refresh)],
          body: d == null
              ? (_error != null
                  ? EmptyState(icon: Icons.cloud_off, title: 'Couldn’t load billing', message: _error, action: CustomButton(text: 'Try Again', onPressed: _refresh))
                  : const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
              : _body(context, d),
        );
      },
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> d) {
    final p = context.p;
    final payg = ApiMappers.str(d['billing_model']) != 'subscription';
    final sub = d['subscription'] is Map ? d['subscription'] as Map : null;
    final plans = (d['plans'] as List? ?? const []).whereType<Map>().toList();
    final txns = (d['wallet_transactions'] as List? ?? const []).whereType<Map>().toList();
    final rates = (d['rates'] as List? ?? const []).whereType<Map>().toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Operating wallet', style: tx(context, 12.5, color: p.textSecondary)),
          const SizedBox(height: 6),
          MoneyText(ApiMappers.num0(d['wallet_balance']), size: 26),
          const SizedBox(height: 8),
          Text(
            payg ? 'Pay as you go: each action below is paid from this wallet.' : 'Unlimited plan: actions aren’t charged while your plan is active.',
            style: tx(context, 12, color: p.textSecondary, height: 1.4),
          ),
          if (BillingScreen.canPay) ...[
            const SizedBox(height: 14),
            CustomButton(text: 'Top Up Wallet', icon: const Icon(Icons.add), onPressed: _topUp),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      const SectionLabel('Your plan'),
      BpCard(
        child: Column(children: [
          InfoRow(label: 'Billing', value: payg ? 'Pay as you go' : 'Subscription'),
          if (sub != null) ...[
            InfoRow(label: 'Plan', value: ApiMappers.str((sub['plan'] as Map?)?['name'])),
            InfoRow(label: 'Status', value: ApiMappers.str(sub['status'])),
            if (ApiMappers.date(sub['current_period_end']) != null) InfoRow(label: 'Renews', value: Fmt.date(ApiMappers.date(sub['current_period_end'])!)),
          ],
        ]),
      ),
      if (plans.isNotEmpty) ...[
        const SizedBox(height: 16),
        const SectionLabel('Plans'),
        for (final plan in plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BpCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(ApiMappers.str(plan['name']), style: tx(context, 14.5, weight: FontWeight.w800))),
                  MoneyText(ApiMappers.num0(plan['price']), size: 14),
                  Text(' /${ApiMappers.str(plan['billing_interval']).replaceAll('ly', '')}', style: tx(context, 12, color: p.textSecondary)),
                ]),
                for (final f in (plan['features'] as List? ?? const []))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      Icon(Icons.check_circle, size: 14, color: p.brand),
                      const SizedBox(width: 6),
                      Expanded(child: Text('$f'.replaceAll(RegExp(r'<[^>]*>'), ''), style: tx(context, 12, color: p.textSecondary))),
                    ]),
                  ),
                if (BillingScreen.canPay) ...[
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Activate ${ApiMappers.str(plan['name'])}',
                    variant: ButtonVariant.outline,
                    isLoading: _activatingPlanId != null && _activatingPlanId == ApiMappers.intOrNull(plan['id']),
                    onPressed: _activatingPlanId != null ? null : () => _activate(plan),
                  ),
                ],
              ]),
            ),
          ),
      ],
      if (rates.isNotEmpty) ...[
        const SizedBox(height: 6),
        const SectionLabel('What actions cost (pay as you go)'),
        BpCard(
          child: Column(children: [
            for (final r in rates) InfoRow(label: ApiMappers.str(r['name']), valueWidget: MoneyText(ApiMappers.num0(r['fee']), size: 13)),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      const SectionLabel('Wallet activity'),
      if (txns.isEmpty)
        const EmptyState(icon: Icons.receipt_long_outlined, title: 'No wallet activity yet')
      else
        for (final t in txns)
          RecordTile(
            leading: LeadingIcon(ApiMappers.str(t['type']) == 'credit' ? Icons.south_west : Icons.north_east),
            title: ApiMappers.str(t['description']).isEmpty ? ApiMappers.str(t['action']) : ApiMappers.str(t['description']),
            subtitle: ApiMappers.date(t['created_at']) == null ? '' : Fmt.relativeDay(ApiMappers.date(t['created_at'])!),
            amount: ApiMappers.str(t['type']) == 'credit' ? ApiMappers.num0(t['amount']) : -ApiMappers.num0(t['amount']),
          ),
    ]);
  }
}

/// Prompts for the amount and creates the Billway transfer account while
/// keeping a loading spinner + inline error inside the sheet.
Future<Map<String, dynamic>?> _askAndCreateTopUp(BuildContext context) async {
  final c = TextEditingController();
  Map<String, dynamic>? created;
  var loading = false;
  String? apiError;

  await showBpSheet(
    context,
    showHandle: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final v = double.tryParse(c.text.replaceAll(',', '').trim());
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Top up wallet', style: tx(sheet, 16, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Amount',
            hint: 'Minimum ₦500',
            controller: c,
            prefixText: '₦ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: v != null && v < 500 ? 'The minimum top-up is ₦500' : apiError,
            onChanged: (_) => setSheet(() => apiError = null),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Continue',
            isLoading: loading,
            onPressed: loading || v == null || v < 500
                ? null
                : () async {
                    setSheet(() {
                      loading = true;
                      apiError = null;
                    });
                    try {
                      created = await LiveSession.instance.business.topUp(v);
                      if (sheet.mounted) Navigator.pop(sheet);
                    } on ApiException catch (e) {
                      if (sheet.mounted) {
                        setSheet(() {
                          loading = false;
                          apiError = e.message;
                        });
                      }
                    }
                  },
          ),
        ]);
      },
    ),
  );
  c.dispose();
  return created;
}

/// Bank details for the transfer, then "I've sent it" checks the payment.
Future<void> _showTransferSheet(
  BuildContext context,
  Map<String, dynamic> t,
  String title, {
  Future<void> Function()? onPaid,
}) async {
  final reference = ApiMappers.str(t['reference']);
  final acct = ApiMappers.str(t['account_number']);
  if (acct.isEmpty) {
    showToast(context, 'Could not get a virtual account number. Please try again.');
    return;
  }
  var checking = false;

  await showBpSheet(
    context,
    showHandle: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: tx(sheet, 16, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Transfer exactly this amount to the account below. It usually arrives in a few minutes.',
            style: tx(sheet, 12.5, color: sheet.p.textSecondary, height: 1.4)),
        const SizedBox(height: 14),
        BpCard(
          child: Column(children: [
            InfoRow(label: 'Amount', valueWidget: MoneyText(ApiMappers.num0(t['amount']))),
            InfoRow(label: 'Bank', value: ApiMappers.str(t['bank_name'])),
            InfoRow(
              label: 'Account number',
              valueWidget: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(acct, style: tx(sheet, 13, weight: FontWeight.w800)),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 14, color: sheet.p.brand),
              ]),
              onTap: () {
                Clipboard.setData(ClipboardData(text: acct));
                showToast(sheet, 'Account number copied');
              },
            ),
            InfoRow(label: 'Account name', value: ApiMappers.str(t['account_name'])),
          ]),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'I’ve Sent the Money',
          isLoading: checking,
          onPressed: () async {
            setSheet(() => checking = true);
            try {
              final s = await LiveSession.instance.business.paymentStatus(reference);
              if (!sheet.mounted) return;
              if (s['status'] == 'successful') {
                Navigator.pop(sheet);
                if (context.mounted) showToast(context, 'Payment received. Thank you!');
                await onPaid?.call();
              } else {
                showToast(sheet, 'We haven’t received it yet. Give it a few minutes and check again.');
              }
            } on ApiException catch (e) {
              if (sheet.mounted) showToast(sheet, e.message);
            } finally {
              if (sheet.mounted) setSheet(() => checking = false);
            }
          },
        ),
      ]),
    ),
  );
}

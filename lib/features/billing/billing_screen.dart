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

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _loading = false;
  String? _error;

  static final Map<String, dynamic> _demo = {
    'billing_model': 'payg',
    'wallet_balance': 3250,
    'currency': 'NGN',
    'subscription': null,
    'plans': [
      {'id': 1, 'name': 'Starter', 'price': 8000, 'billing_interval': 'monthly', 'included_users': 2, 'features': ['Unlimited invoices', 'Payment links', '2 team members']},
      {'id': 2, 'name': 'Growth', 'price': 20000, 'billing_interval': 'monthly', 'included_users': 5, 'features': ['Everything in Starter', 'Storefront & orders', 'Custom domain']},
    ],
    'wallet_transactions': [
      {'id': 1, 'type': 'debit', 'amount': 50, 'description': 'Smart Invoice Generation', 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
      {'id': 2, 'type': 'credit', 'amount': 5000, 'description': 'Wallet top-up', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
    ],
    'rates': [
      {'name': 'Invoice', 'fee': 50},
      {'name': 'Quotation', 'fee': 50},
      {'name': 'Add a product', 'fee': 20},
    ],
  };

  Map<String, dynamic>? get _data => LiveSession.enabled ? LiveSession.instance.billing.value : _demo;

  @override
  void initState() {
    super.initState();
    if (LiveSession.enabled) _refresh();
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

  Future<void> _topUp() async {
    final amount = await _askAmount(context);
    if (amount == null || !mounted) return;
    if (!LiveSession.enabled) {
      showToast(context, 'Demo: wallet top-ups need a live account');
      return;
    }
    try {
      final t = await LiveSession.instance.business.topUp(amount);
      if (mounted) await _showTransfer(t, 'Top up your wallet');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _activate(Map plan) async {
    if (!LiveSession.enabled) {
      showToast(context, 'Demo: plans need a live account');
      return;
    }
    final id = ApiMappers.intOrNull(plan['id']);
    if (id == null) return;
    try {
      final t = await LiveSession.instance.business.checkoutPlan(id);
      if (mounted) await _showTransfer(t, 'Activate ${plan['name']}');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  /// Bank details for the transfer, then "I've sent it" checks the payment.
  Future<void> _showTransfer(Map<String, dynamic> t, String title) async {
    final reference = ApiMappers.str(t['reference']);
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
                value: ApiMappers.str(t['account_number']),
                bold: true,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ApiMappers.str(t['account_number'])));
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
                  if (!mounted) return;
                  showToast(context, 'Payment received. Thank you!');
                  _refresh();
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

  @override
  Widget build(BuildContext context) {
    final live = LiveSession.enabled;
    return ValueListenableBuilder(
      valueListenable: LiveSession.instance.billing,
      builder: (context, _, _) {
        final d = _data;
        return InnerScaffold(
          title: 'Wallet & Billing',
          subtitle: 'Balance, plan and charges',
          actions: [if (live) CircleIconButton(icon: Icons.refresh, tooltip: 'Refresh', onTap: _loading ? () {} : _refresh)],
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
                      Expanded(child: Text('$f', style: tx(context, 12, color: p.textSecondary))),
                    ]),
                  ),
                if (BillingScreen.canPay) ...[
                  const SizedBox(height: 12),
                  CustomButton(text: 'Activate ${ApiMappers.str(plan['name'])}', variant: ButtonVariant.outline, onPressed: () => _activate(plan)),
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

Future<double?> _askAmount(BuildContext context) async {
  final c = TextEditingController();
  double? result;
  await showBpSheet(
    context,
    showHandle: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final v = double.tryParse(c.text.replaceAll(',', ''));
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Top up wallet', style: tx(sheet, 16, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Amount',
            hint: 'Minimum ₦500',
            controller: c,
            prefixText: '₦ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: v != null && v < 500 ? 'The minimum top-up is ₦500' : null,
            onChanged: (_) => setSheet(() {}),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Continue',
            onPressed: v == null || v < 500
                ? null
                : () {
                    result = v;
                    Navigator.pop(sheet);
                  },
          ),
        ]);
      },
    ),
  );
  return result;
}

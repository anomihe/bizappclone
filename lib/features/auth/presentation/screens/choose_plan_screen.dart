import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/api/mappers.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../billing/billing_screen.dart';
import '../widgets/auth_scaffold.dart';
import 'registration_success_screen.dart';

/// "Choose how to start", after sign-up. Shows the new business's trial,
/// or pay-as-you-go, and the real plans from `GET /admin/billing`.
class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  Map<String, dynamic>? _billing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final j = await LiveSession.instance.refreshBilling();
      if (mounted) setState(() => _billing = j);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _continue() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()));

  Future<void> _pickPlan() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()));
    if (mounted) _continue();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final b = _billing;
    final plans = [for (final x in (b?['plans'] as List? ?? const [])) if (x is Map) x];
    final onTrial = b?['on_trial'] == true;
    final trialEnds = ApiMappers.date(b?['trial_ends_at']);
    final payg = b != null && ApiMappers.str(b['billing_model']) != 'subscription';
    final prices = [for (final x in plans) ApiMappers.num0(x['price'])]..sort();

    final String headline;
    final String detail;
    if (onTrial) {
      headline = 'Free trial';
      detail = trialEnds == null ? 'No payment needed while your trial runs.' : 'No payment needed until ${Fmt.date(trialEnds)}.';
    } else if (payg) {
      headline = 'Pay as you go';
      detail = 'No monthly fee. Small charges come from your wallet only when you use a feature.';
    } else {
      headline = 'Your workspace is ready';
      detail = 'Pick a plan to keep using every feature.';
    }

    return AuthScaffold(
      showClose: false,
      title: 'Choose how to start',
      subtitle: onTrial ? 'No card needed for your trial.' : 'You can change this any time in Wallet & Billing.',
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        if (prices.isNotEmpty) Text('Plans from ${Fmt.money(prices.first)} a month.', style: tx(context, 12, color: p.textSecondary)),
        const SizedBox(height: 12),
        CustomButton(text: onTrial ? 'Start My Free Trial' : 'Continue', variant: ButtonVariant.accent, onPressed: b == null && _error == null ? null : _continue),
        if (plans.isNotEmpty) ...[
          const SizedBox(height: 8),
          CustomButton(text: 'Choose a Plan Now', variant: ButtonVariant.outline, onPressed: _pickPlan),
        ],
      ]),
      children: [
        if (_error != null)
          BpCard(
            child: Row(children: [
              Expanded(child: Text(_error!, style: tx(context, 12.5, color: p.error))),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ]),
          )
        else if (b == null)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(headline, style: tx(context, 15, weight: FontWeight.w800))),
                const SizedBox(width: 8),
                const StatusPill(StatusStyle.current),
              ]),
              const SizedBox(height: 6),
              Text(detail, style: tx(context, 12.5, color: p.textSecondary, height: 1.4)),
            ]),
          ),
          for (final plan in plans) ...[
            const SizedBox(height: 10),
            BpCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(ApiMappers.str(plan['name']), style: tx(context, 14, weight: FontWeight.w800))),
                  Text('${Fmt.money(ApiMappers.num0(plan['price']))}/${ApiMappers.str(plan['billing_interval']) == 'yearly' ? 'yr' : 'mo'}',
                      style: tx(context, 13, weight: FontWeight.w700, color: p.brand)),
                ]),
                const SizedBox(height: 6),
                for (final f in (plan['features'] as List? ?? const []).take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(Icons.check, size: 15, color: p.brand),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$f', style: tx(context, 12, weight: FontWeight.w600))),
                    ]),
                  ),
              ]),
            ),
          ],
        ],
      ],
    );
  }
}

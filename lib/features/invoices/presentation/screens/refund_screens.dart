import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/doc_header_card.dart';
import '../widgets/refund_form.dart';

class RequestRefundScreen extends StatefulWidget {
  final Invoice invoice;
  const RequestRefundScreen({super.key, required this.invoice});

  @override
  State<RequestRefundScreen> createState() => _RequestRefundScreenState();
}

class _RequestRefundScreenState extends State<RequestRefundScreen> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    RefundRequest? created;
    final ok = await runLiveAction(context, () async => created = await LiveSession.instance.requestRefund(widget.invoice, double.parse(_amount.text), _reason.text.trim()));
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok || created == null) return;
    final refund = created!;
    await showSuccessSheet(
      context,
      title: 'Refund request submitted!',
      message: 'Your refund request has been successfully submitted and is awaiting review.',
      actionLabel: 'View Refund Status',
      onAction: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RefundStatusScreen(invoice: widget.invoice, refund: refund)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.invoice;
    final refundable = i.refundableBalance;
    return InnerScaffold(
      title: 'Request a Refund',
      subtitle: 'For Invoice ${i.number}',
      bottom: CustomButton(
        text: 'Continue',
        variant: ButtonVariant.accent,
        isLoading: _loading,
        onPressed: RefundForm.valid(_amount, _reason, refundable) ? _submit : null,
      ),
      body: RefundForm(refundable: refundable, creditIssued: i.credited, amount: _amount, reason: _reason, onChanged: () => setState(() {})),
    );
  }
}

class RefundStatusScreen extends StatelessWidget {
  final Invoice invoice;
  final RefundRequest refund;
  const RefundStatusScreen({super.key, required this.invoice, required this.refund});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final steps = [
      ('Refund Requested', 'You asked for ${Fmt.money(refund.amount)}'),
      ('Approved by Admin', 'An admin reviews every refund'),
      ('Confirmed by Billway', 'Billway sends the money back'),
      ('Refunded', 'The customer has their money'),
    ];
    final done = refund.stage.index; // index of the last completed step

    return ListenableBuilder(
      listenable: BizStore.instance,
      builder: (context, _) => InnerScaffold(
        title: 'Refund Status',
        subtitle: 'For Invoice ${invoice.number}',
        body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DocHeaderCard(
            label: 'Refund for',
            name: invoice.customerName,
            amount: refund.amount,
            status: StatusStyle.refund(refund.stage),
            extra: [
              const SizedBox(height: 10),
              Text('Reason', style: tx(context, 11, color: p.textMuted)),
              Text(refund.reason, style: tx(context, 13, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 18),
          const SectionLabel('Progress'),
          for (var s = 0; s < steps.length; s++)
            _Step(
              title: steps[s].$1,
              subtitle: steps[s].$2,
              state: s <= done ? _StepState.done : (s == done + 1 ? _StepState.current : _StepState.todo),
              isLast: s == steps.length - 1,
            ),
        ]),
      ),
    );
  }
}

enum _StepState { done, current, todo }

class _Step extends StatelessWidget {
  final String title;
  final String subtitle;
  final _StepState state;
  final bool isLast;
  const _Step({required this.title, required this.subtitle, required this.state, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final icon = switch (state) {
      _StepState.done => const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 22),
      _StepState.current => const Icon(Icons.timelapse, color: AppColors.accent, size: 22),
      _StepState.todo => Icon(Icons.radio_button_unchecked, color: p.textMuted, size: 22),
    };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          icon,
          if (!isLast) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: state == _StepState.done ? AppColors.primaryLight : p.border)),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tx(context, 13.5, weight: FontWeight.w700, color: state == _StepState.todo ? p.textMuted : p.text)),
              Text(subtitle, style: tx(context, 11.5, color: p.textMuted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

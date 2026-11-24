import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../invoices/presentation/widgets/doc_header_card.dart';
import '../../../payments/presentation/screens/payment_details_screen.dart';

const cancelReasons = ['Out of Stock', 'Customer asked to cancel', 'Could not deliver to this address', 'Others'];

/// "ORD-1012": pending (awaiting payment) or paid (processing).
class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final store = BizStore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => store.markOrderSeen(widget.order));
  }

  Future<void> _cancel() async {
    final reason = await showBpSheet<String>(context, showHandle: true, builder: (_) => const _CancelOrderForm());
    if (reason != null && mounted) {
      store.cancelOrder(widget.order, reason);
      showToast(context, 'Order cancelled — the customer has been notified');
    }
  }

  /// Calling / WhatsApp need `url_launcher`; copy the number meanwhile.
  void _contact(String via) {
    Clipboard.setData(ClipboardData(text: widget.order.phone));
    showToast(context, 'Number copied — open $via to reach the customer');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final p = context.p;
    final o = widget.order;
    final open = o.status == OrderStatus.pending || o.status == OrderStatus.processing;

    return InnerScaffold(
      title: o.number,
      subtitle: o.customerName,
      titleTrailing: StatusPill(BizStatus.order(o.status)),
      bottom: open
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              if (o.status == OrderStatus.processing) ...[
                CustomButton(text: 'Mark as Delivered', onPressed: () => store.completeOrder(o)),
                const SizedBox(height: 10),
              ],
              _DangerSoftButton(label: 'Cancel Order', onTap: _cancel),
            ])
          : null,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DocHeaderCard(
          label: 'Placed by',
          name: o.customerName,
          amount: o.total,
          status: BizStatus.orderStage(o.status),
          subline: 'Placed ${Fmt.relativeDay(o.placedAt)} · Card',
          sublineColor: p.textMuted,
        ),
        if (o.status == OrderStatus.pending) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accent.withValues(alpha: 0.6))),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: p.readable(AppColors.warning)),
              const SizedBox(width: 8),
              Expanded(child: Text('Waiting for the customer’s payment. Pack and ship it after Billway confirms.', style: tx(context, 12, color: p.textSecondary))),
            ]),
          ),
        ],
        if (o.status == OrderStatus.cancelled && o.cancelReason != null) ...[
          const SizedBox(height: 12),
          InfoBanner('Cancelled: ${o.cancelReason}'),
        ],
        const SizedBox(height: 18),
        const SectionLabel('Items'),
        ItemsList(items: o.items),
        Divider(color: p.border),
        Row(children: [
          Expanded(child: Text('Total', style: tx(context, 14, weight: FontWeight.w800))),
          MoneyText(o.total, size: 15),
        ]),
        const SizedBox(height: 18),
        const SectionLabel('Customer'),
        BpCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _field('Name', o.customerName)),
              Expanded(child: _field('Phone', o.phone)),
            ]),
            const SizedBox(height: 12),
            _field('Delivery address', o.address),
            const SizedBox(height: 12),
            Row(children: [
              _ContactChip(icon: Icons.call_outlined, label: 'Call', color: p.brand, onTap: () => _contact('your phone app')),
              const SizedBox(width: 8),
              _ContactChip(icon: Icons.chat_outlined, label: 'WhatsApp', color: const Color(0xFF25D366), onTap: () => _contact('WhatsApp')),
            ]),
          ]),
        ),
        if (o.payments.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionLabel('Payments'),
          for (final pay in o.payments)
            RecordTile(
              leading: const LeadingIcon(Icons.receipt_outlined),
              title: pay.customerName,
              subtitle: 'Paid by Customer · ${Fmt.relativeDay(pay.date)}',
              amount: pay.amount,
              status: StatusStyle.payment(pay.status),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailsScreen(payment: pay))),
            ),
        ],
      ]),
    );
  }

  Widget _field(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: tx(context, 11.5, color: context.p.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: tx(context, 13, weight: FontWeight.w700)),
      ]);
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: tx(context, 12, weight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// Soft red full-width button ("Cancel Order", "Log Out").
class _DangerSoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerSoftButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.errorSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 50,
          child: Center(child: Text(label, style: tx(context, 14, weight: FontWeight.w700, color: p.error))),
        ),
      ),
    );
  }
}

class _CancelOrderForm extends StatefulWidget {
  const _CancelOrderForm();
  @override
  State<_CancelOrderForm> createState() => _CancelOrderFormState();
}

class _CancelOrderFormState extends State<_CancelOrderForm> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: p.errorSoft, shape: BoxShape.circle),
          child: Icon(Icons.remove_shopping_cart_outlined, color: p.error),
        ),
      ),
      const SizedBox(height: 12),
      Text('Cancel this order?', textAlign: TextAlign.center, style: tx(context, 16, weight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('The customer will be told the order was cancelled.', textAlign: TextAlign.center, style: tx(context, 12.5, color: p.textSecondary)),
      const SizedBox(height: 16),
      CustomTextField(label: 'Reason', hint: 'Why are you cancelling?', controller: _reason, onChanged: (_) => setState(() {})),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final r in cancelReasons)
          SelectChip(
            label: r,
            selected: _reason.text == r,
            onTap: () => setState(() => _reason.text = r == 'Others' ? '' : r),
          ),
      ]),
      const SizedBox(height: 18),
      _DangerSoftButton(
        label: 'Cancel Order',
        onTap: () {
          if (_reason.text.trim().isEmpty) {
            showToast(context, 'Add a reason so the customer knows why');
            return;
          }
          Navigator.pop(context, _reason.text.trim());
        },
      ),
      const SizedBox(height: 10),
      CustomButton(text: 'Keep Order', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
    ]);
  }
}

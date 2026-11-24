import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/calendar_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../payments/presentation/screens/payment_details_screen.dart';
import '../../../payments/presentation/screens/receipt_screen.dart';
import '../widgets/doc_header_card.dart';
import '../widgets/invoice_sheets.dart';
import 'create_payment_link_screen.dart';

/// "Gucci Bags · Payment link #0001" — active, pending, paid, expired, disabled.
class PaymentLinkDetailsScreen extends StatefulWidget {
  final Invoice link;
  final bool justCreated;
  const PaymentLinkDetailsScreen({super.key, required this.link, this.justCreated = false});

  @override
  State<PaymentLinkDetailsScreen> createState() => _PaymentLinkDetailsScreenState();
}

class _PaymentLinkDetailsScreenState extends State<PaymentLinkDetailsScreen> {
  final store = BizStore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.justCreated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSharePayLinkSheet(context, widget.link);
      });
    }
  }

  Future<void> _changeExpiry() async {
    DateTime? picked = widget.link.dueDate;
    final result = await showBpSheet<String>(
      context,
      title: 'Link Expiry',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Link expires on (optional)', style: tx(ctx, 12.5, weight: FontWeight.w600, color: ctx.p.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final d = await showDatePickerSheet(ctx, initial: picked ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now());
              if (d != null) setSheet(() => picked = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: ctx.p.border, width: 1.2)),
              child: Row(children: [
                Expanded(child: Text(picked == null ? 'dd/mm/yyyy' : Fmt.dateNumeric(picked!), style: tx(ctx, 14, color: picked == null ? ctx.p.textMuted : ctx.p.text))),
                Icon(Icons.calendar_today_outlined, size: 17, color: ctx.p.textMuted),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: CustomButton(text: 'No Expiry', variant: ButtonVariant.soft, onPressed: () => Navigator.pop(ctx, 'none'))),
            const SizedBox(width: 10),
            Expanded(child: CustomButton(text: 'Save Expiry', onPressed: picked == null ? null : () => Navigator.pop(ctx, 'save'))),
          ]),
        ]),
      ),
    );
    if (result == null) return;
    store.setLinkExpiry(widget.link, result == 'none' ? null : picked);
    if (mounted) showToast(context, result == 'none' ? 'Link no longer expires' : 'Expiry date updated');
  }

  Future<void> _disable() async {
    final ok = await showConfirmSheet(
      context,
      title: 'Disable this payment link?',
      message: 'The link stops working straight away. The customer can no longer pay it.',
      confirmLabel: 'Disable Link',
      icon: Icons.link_off,
    );
    if (ok) {
      store.voidInvoice(widget.link);
      if (mounted) showToast(context, 'Payment link disabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final p = context.p;
    final l = widget.link;
    final style = BizStatus.link(l);
    final disabled = l.status == InvoiceStatus.cancelled;
    final paid = l.status == InvoiceStatus.paid;
    final paidPayments = l.payments.where((x) => x.paidByCustomer).toList();

    Widget? bottom;
    if (paid && paidPayments.isNotEmpty) {
      bottom = CustomButton(
        text: 'View Receipt',
        variant: ButtonVariant.accent,
        icon: const Icon(Icons.receipt_outlined),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: paidPayments.last))),
      );
    } else if (!disabled) {
      bottom = CustomButton(text: 'Share Link', variant: ButtonVariant.accent, icon: const Icon(Icons.ios_share), onPressed: () => showSharePayLinkSheet(context, l));
    }

    return InnerScaffold(
      title: l.purpose,
      subtitle: 'Payment link ${l.linkNumber}',
      bottom: bottom,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DocHeaderCard(
          label: 'Billed to',
          name: l.customerName == 'No customer' ? 'Anyone with the link' : l.customerName,
          amount: l.total,
          status: style,
          badge: 'Payment link',
          subline: disabled ? 'Link disabled' : (l.dueDate == null ? 'Never expires' : '${l.status == InvoiceStatus.overdue ? 'Expired' : 'Expires'} ${Fmt.date(l.dueDate!)}'),
          sublineColor: l.status == InvoiceStatus.overdue ? p.error : p.textMuted,
          extra: [
            const SizedBox(height: 12),
            Text('Link', style: tx(context, 11, color: p.textMuted)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(8), border: Border.all(color: p.brand.withValues(alpha: 0.35))),
                  child: Text(l.payLink, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 12, weight: FontWeight.w600, color: disabled ? p.textMuted : p.brand)),
                ),
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                icon: Icons.copy,
                size: 36,
                tooltip: 'Copy link',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://${l.payLink}'));
                  showToast(context, 'Link copied');
                },
              ),
            ]),
          ],
        ),
        if (l.payments.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionLabel('Payments'),
          for (final pay in l.payments)
            RecordTile(
              leading: const LeadingIcon(Icons.receipt_outlined),
              title: pay.customerName,
              subtitle: 'Paid by Customer · ${Fmt.relativeDay(pay.date)}',
              amount: pay.amount,
              status: StatusStyle.payment(pay.status),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailsScreen(payment: pay))),
            ),
        ],
        if (!disabled) ...[
          const SizedBox(height: 18),
          const SectionLabel('Actions'),
          ActionTile(
            icon: Icons.event_outlined,
            title: 'Change Expiry Date',
            subtitle: l.dueDate == null ? 'No expiry' : 'Expires ${Fmt.date(l.dueDate!)}',
            onTap: _changeExpiry,
          ),
          if (!paid) ActionTile(icon: Icons.link_off, title: 'Disable Payment Link', subtitle: 'Customers can no longer pay it', danger: true, onTap: _disable),
        ],
      ]),
    );
  }
}

/// More → Payment Links.
class PaymentLinksScreen extends StatefulWidget {
  const PaymentLinksScreen({super.key});

  @override
  State<PaymentLinksScreen> createState() => _PaymentLinksScreenState();
}

class _PaymentLinksScreenState extends State<PaymentLinksScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Active', 'Pending', 'Paid', 'Expired', 'Disabled'];

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final all = store.paymentLinks;
        final list = all.where((l) => _filter == 'All' || BizStatus.link(l).label == _filter).toList();
        void create() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePaymentLinkScreen()));

        return InnerScaffold(
          title: 'Payment Links',
          scroll: false,
          bodyPadding: EdgeInsets.zero,
          titleTrailing: CircleIconButton(icon: Icons.add_link, background: p.isDark ? p.primarySoft : const Color(0xFF0E5E4A), color: Colors.white, tooltip: 'New payment link', onTap: create),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final f in _filters)
                  Padding(padding: const EdgeInsets.only(right: 8), child: SelectChip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f))),
              ]),
            ),
            const SizedBox(height: 14),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: EmptyState(
                  icon: Icons.link,
                  title: 'No payment links here',
                  message: 'Create a link, share it on WhatsApp and get paid.',
                  action: CustomButton(text: 'New Link', variant: ButtonVariant.accent, icon: const Icon(Icons.add_link), width: 150, height: 40, onPressed: create),
                ),
              )
            else if (list.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.search_off, title: 'No $_filter links'))
            else
              for (final l in list)
                RecordTile(
                  leading: LeadingIcon(Icons.link, color: l.status == InvoiceStatus.cancelled ? p.textMuted : null),
                  title: l.purpose,
                  subtitle: '${l.linkNumber} · ${Fmt.date(l.createdAt)}',
                  amount: l.total,
                  status: BizStatus.link(l),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentLinkDetailsScreen(link: l))),
                ),
          ]),
        );
      },
    );
  }
}

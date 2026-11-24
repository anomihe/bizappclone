import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../payments/presentation/screens/payment_details_screen.dart';
import '../../../payments/presentation/screens/receipt_screen.dart';
import '../widgets/doc_header_card.dart';
import '../widgets/invoice_sheets.dart';
import 'create_document_screen.dart';
import 'credit_note_screens.dart';
import 'document_preview_screen.dart';
import 'payment_link_details_screen.dart';
import 'refund_screens.dart';

/// "Invoice #0044" in every state, and the detail page for payment links.
class InvoiceDetailsScreen extends StatefulWidget {
  final Invoice invoice;
  final bool justIssued;
  const InvoiceDetailsScreen({super.key, required this.invoice, this.justIssued = false});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final store = BizStore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.justIssued && !_isLink) {
      // Offer the share sheet right after issuing — that's the next step.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSharePayLinkSheet(context, widget.invoice);
      });
    }
  }

  bool get _isLink => widget.invoice.kind == DocKind.paymentLink;

  Future<void> _void() async {
    final i = widget.invoice;
    final ok = await showConfirmSheet(
      context,
      title: _isLink ? 'Cancel this payment link?' : 'Void invoice ${i.number}?',
      message: _isLink
          ? 'The link stops working straight away. The customer can no longer pay it.'
          : 'A voided invoice cannot be paid. This can not be undone.',
      confirmLabel: _isLink ? 'Cancel Link' : 'Void Invoice',
    );
    if (ok) {
      store.voidInvoice(i);
      if (mounted) showToast(context, _isLink ? 'Payment link cancelled' : 'Invoice voided');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Payment links have their own detail layout.
    if (_isLink) return PaymentLinkDetailsScreen(link: widget.invoice, justCreated: widget.justIssued);
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final p = context.p;
    final i = widget.invoice;
    final status = i.status;
    final open = status == InvoiceStatus.unpaid || status == InvoiceStatus.partlyPaid || status == InvoiceStatus.overdue;
    final closed = status == InvoiceStatus.voided || status == InvoiceStatus.cancelled;
    final lastPaid = i.payments.where((x) => x.paidByCustomer).toList();

    Widget? bottom;
    if (status == InvoiceStatus.draft) {
      bottom = CustomButton(
        text: 'Preview & Issue',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen.invoice(i))),
      );
    } else if (status == InvoiceStatus.paid && lastPaid.isNotEmpty) {
      bottom = CustomButton(
        text: 'Share Receipt',
        variant: ButtonVariant.outline,
        icon: const Icon(Icons.ios_share),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: lastPaid.last))),
      );
    } else if (open) {
      bottom = CustomButton(
        text: _isLink ? 'Share Payment Link' : 'Share Invoice',
        variant: ButtonVariant.outline,
        icon: const Icon(Icons.ios_share),
        onPressed: () => showSharePayLinkSheet(context, i),
      );
    }

    String? dueLine;
    if (closed) {
      dueLine = status == InvoiceStatus.cancelled ? 'Link cancelled' : 'Voided';
    } else if (status == InvoiceStatus.draft) {
      dueLine = 'Not issued yet';
    } else if (i.dueDate != null) {
      dueLine = '${_isLink ? 'Expires' : 'Due'} ${Fmt.date(i.dueDate!)}';
    }

    return InnerScaffold(
      title: 'Invoice ${i.number}',
      bottom: bottom,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DocHeaderCard(
          label: 'Billed to',
          name: i.customerName,
          amount: i.total,
          status: StatusStyle.invoice(status),
          badge: _isLink ? 'Payment link' : null,
          subline: dueLine,
          sublineColor: status == InvoiceStatus.overdue ? p.error : (closed || status == InvoiceStatus.paid ? p.textMuted : p.readable(AppColors.warning)),
          figures: closed
              ? const []
              : [
                  ('Paid by customer', i.paid, i.paid > 0 ? p.brand : null),
                  ('Still to pay', i.balance, null),
                ],
        ),
        const SizedBox(height: 18),
        const SectionLabel('Items'),
        ItemsList(items: i.items),
        if (i.discount > 0) InfoRow(label: 'Discount', value: '-${Fmt.money(i.discount)}'),
        if (i.payments.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionLabel('Payments'),
          for (final pay in i.payments)
            RecordTile(
              leading: const LeadingIcon(Icons.receipt_outlined),
              title: pay.customerName,
              subtitle: 'Paid by Customer · ${Fmt.relativeDay(pay.date)}',
              amount: pay.amount,
              status: StatusStyle.payment(pay.status),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailsScreen(payment: pay))),
            ),
        ],
        if (i.refunds.isNotEmpty || i.creditNotes.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionLabel('Refunds'),
          for (final r in i.refunds)
            RecordTile(
              leading: const LeadingIcon(Icons.undo, color: AppColors.info),
              title: r.stage == RefundStage.refunded ? 'Refunded' : 'Refund requested',
              subtitle: r.reason,
              amount: r.amount,
              status: StatusStyle.refund(r.stage),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RefundStatusScreen(invoice: i, refund: r))),
            ),
          for (final cn in i.creditNotes)
            RecordTile(
              leading: LeadingIcon(Icons.description_outlined, color: p.textSecondary),
              title: 'Credit Note ${cn.number}',
              subtitle: 'Linked to invoice',
              amount: cn.amount,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreditNoteScreen(invoice: i, note: cn))),
            ),
        ],
        if (!closed && (status == InvoiceStatus.draft || open || (status == InvoiceStatus.paid && i.refundableBalance > 0))) ...[
          const SizedBox(height: 14),
          const SectionLabel('Actions'),
          if (status == InvoiceStatus.draft)
            CustomButton(
              text: 'Edit Invoice',
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.invoice(draft: i))),
            ),
          if (open) ...[
            ActionTile(icon: Icons.notifications_active_outlined, title: 'Send Reminder', subtitle: 'Reminders stop once it is paid', onTap: () => showSendReminderSheet(context, i)),
            ActionTile(icon: Icons.share_outlined, title: 'Share pay link', subtitle: i.payLink, onTap: () => showSharePayLinkSheet(context, i)),
            ActionTile(icon: Icons.block, title: _isLink ? 'Cancel Payment Link' : 'Void invoice', danger: true, onTap: _void),
          ],
          if (status == InvoiceStatus.paid && i.refundableBalance > 0) ...[
            ActionTile(
              icon: Icons.receipt_long_outlined,
              title: 'Issue credit note',
              subtitle: 'Then request a refund',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IssueCreditNoteScreen(invoice: i))),
            ),
            ActionTile(
              icon: Icons.undo,
              title: 'Request a refund',
              subtitle: 'Send money back to the customer',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestRefundScreen(invoice: i))),
            ),
          ],
        ],
      ]),
    );
  }
}

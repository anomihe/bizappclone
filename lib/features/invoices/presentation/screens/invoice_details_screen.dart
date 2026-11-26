import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../payments/presentation/screens/payment_details_screen.dart';
import '../../../payments/presentation/screens/receipt_screen.dart';
import '../widgets/doc_header_card.dart';
import '../widgets/invoice_sheets.dart';
import 'create_document_screen.dart';
import 'document_preview_screen.dart';

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
    // Live mode: lists come without line items; load them now.
    LiveSession.instance.refreshInvoice(widget.invoice);
    if (widget.justIssued) {
      // Offer the share sheet right after issuing — that's the next step.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSharePayLinkSheet(context, widget.invoice);
      });
    }
  }

  Future<void> _deleteDraft() async {
    final i = widget.invoice;
    final ok = await showConfirmSheet(
      context,
      title: 'Delete draft ${i.number}?',
      message: 'The draft will be removed. This can’t be undone.',
      confirmLabel: 'Delete Draft',
      cancelLabel: 'Keep It',
    );
    if (!ok || !mounted) return;
    BizStore.instance.deleteDraft(i);
    showToast(context, 'Draft deleted');
    Navigator.pop(context);
  }

  Future<void> _void() async {
    final i = widget.invoice;
    final ok = await showConfirmSheet(
      context,
      title: 'Void invoice ${i.number}?',
      message: 'A voided invoice cannot be paid. This can not be undone.',
      confirmLabel: 'Void Invoice',
    );
    if (ok) {
      store.voidInvoice(i);
      if (mounted) showToast(context, 'Invoice voided');
    }
  }

  Future<void> _email() => runLiveAction(
    context,
    () => LiveSession.instance.emailInvoice(widget.invoice),
    done: widget.invoice.customer?.email.isNotEmpty == true ? 'Invoice emailed to ${widget.invoice.customer!.email}' : 'Invoice emailed',
  );

  Future<void> _markPaid() async {
    final i = widget.invoice;
    final ok = await showConfirmSheet(
      context,
      title: 'Mark ${i.number} as paid?',
      message:
          'Use this when the customer paid you directly (cash, POS or a transfer to your own account). The full ${Fmt.money(i.balance)} is recorded as received.',
      confirmLabel: 'Mark as Paid',
      cancelLabel: 'Not Yet',
    );
    if (!ok || !mounted) return;
    await runLiveAction(context, () => LiveSession.instance.markInvoicePaid(i), done: 'Invoice marked as paid');
  }

  Future<void> _pdf() => sharePdf(context, () => LiveSession.instance.invoicePdf(widget.invoice), 'Invoice-${widget.invoice.number.replaceAll('#', '')}.pdf');

  @override
  Widget build(BuildContext context) {
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
        text: 'Share Invoice',
        variant: ButtonVariant.outline,
        icon: const Icon(Icons.ios_share),
        onPressed: () => showSharePayLinkSheet(context, i),
      );
    }

    String? dueLine;
    if (closed) {
      dueLine = 'Voided';
    } else if (status == InvoiceStatus.draft) {
      dueLine = 'Not issued yet';
    } else if (i.dueDate != null) {
      dueLine = 'Due ${Fmt.date(i.dueDate!)}';
    }

    return InnerScaffold(
      title: 'Invoice ${i.number}',
      bottom: bottom,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocHeaderCard(
            label: 'Billed to',
            name: i.customerName,
            amount: i.total,
            status: StatusStyle.invoice(status),
            subline: dueLine,
            sublineColor: status == InvoiceStatus.overdue ? p.error : (closed || status == InvoiceStatus.paid ? p.textMuted : p.readable(AppColors.warning)),
            figures: closed ? const [] : [('Paid by customer', i.paid, i.paid > 0 ? p.brand : null), ('Still to pay', i.balance, null)],
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
          if (!closed && (status == InvoiceStatus.draft || open)) ...[
            const SizedBox(height: 14),
            const SectionLabel('Actions'),
            if (status == InvoiceStatus.draft)
              CustomButton(
                text: 'Edit Invoice',
                variant: ButtonVariant.outline,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.invoice(draft: i))),
              ),
            if (status == InvoiceStatus.draft) ...[
              const SizedBox(height: 8),
              ActionTile(icon: Icons.delete_outline, title: 'Delete draft', danger: true, onTap: _deleteDraft),
            ],
            if (open) ...[
              ActionTile(
                icon: Icons.mail_outline,
                title: 'Email to customer',
                subtitle: i.customer?.email.isNotEmpty == true ? i.customer!.email : 'Sends the invoice and pay details',
                onTap: _email,
              ),
              ActionTile(icon: Icons.task_alt, title: 'Mark as paid', subtitle: 'Customer paid you directly', onTap: _markPaid),
              ActionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Send Reminder',
                subtitle: 'Reminders stop once it is paid',
                onTap: () => showSendReminderSheet(context, i),
              ),
              ActionTile(icon: Icons.share_outlined, title: 'Share pay link', subtitle: i.payLink, onTap: () => showSharePayLinkSheet(context, i)),
              ActionTile(icon: Icons.block, title: 'Void invoice', danger: true, onTap: _void),
            ],
          ],
          if (status != InvoiceStatus.draft) ...[
            const SizedBox(height: 8),
            ActionTile(icon: Icons.picture_as_pdf_outlined, title: 'Download PDF', subtitle: 'Save or share the invoice', onTap: _pdf),
          ],
        ],
      ),
    );
  }
}

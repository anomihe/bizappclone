import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'invoice_details_screen.dart';
import 'quotation_details_screen.dart';

/// "Preview — This is what your customer sees".
class DocumentPreviewScreen extends StatefulWidget {
  final Invoice? invoice;
  final Quotation? quotation;

  const DocumentPreviewScreen.invoice(Invoice this.invoice, {super.key}) : quotation = null;
  const DocumentPreviewScreen.quotation(Quotation this.quotation, {super.key}) : invoice = null;

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final store = BizStore.instance;
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    if (widget.invoice != null) {
      store.saveInvoice(widget.invoice!, issue: true);
      nav.push(MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: widget.invoice!, justIssued: true)));
    } else {
      store.saveQuotation(widget.quotation!, send: true);
      nav.push(MaterialPageRoute(builder: (_) => QuotationDetailsScreen(quotation: widget.quotation!, justSent: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final isInvoice = widget.invoice != null;
    final number = isInvoice ? widget.invoice!.number : widget.quotation!.number;
    final customer = isInvoice ? widget.invoice!.customerName : (widget.quotation!.customer?.name ?? '');
    final items = isInvoice ? widget.invoice!.items : widget.quotation!.items;
    final discount = isInvoice ? widget.invoice!.discount : widget.quotation!.discount;
    final total = isInvoice ? widget.invoice!.total : widget.quotation!.total;
    final account = BizStore.instance.account;

    return InnerScaffold(
      title: 'Preview',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        CustomButton(text: isInvoice ? 'Issue Invoice' : 'Send Quotation', variant: ButtonVariant.accent, isLoading: _loading, onPressed: _confirm),
        const SizedBox(height: 10),
        CustomButton(text: isInvoice ? 'Edit Invoice' : 'Edit Quotation', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
      ]),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const InfoBanner('This is what your customer sees'),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
            child: const BizpaddiLogo(size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.businessName, style: tx(context, 13.5, weight: FontWeight.w800)),
              Text(account.businessPhone, style: tx(context, 11.5, color: p.textMuted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(isInvoice ? 'INVOICE' : 'Quotation', style: tx(context, 13, weight: FontWeight.w800, color: context.p.brand)),
            Text(number, style: tx(context, 11.5, color: p.textMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isInvoice ? 'Billed to' : 'Proposed for', style: tx(context, 11.5, color: p.textMuted)),
              Text(customer, style: tx(context, 13.5, weight: FontWeight.w700)),
            ]),
          ),
          if (isInvoice && widget.invoice!.dueDate != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Due', style: tx(context, 11.5, color: p.textMuted)),
              Text(Fmt.date(widget.invoice!.dueDate!), style: tx(context, 13.5, weight: FontWeight.w700)),
            ]),
        ]),
        const SizedBox(height: 14),
        Divider(color: p.border),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.name, style: tx(context, 13, weight: FontWeight.w700)),
                  Text('${it.qty} × ${Fmt.money(it.unitPrice)}', style: tx(context, 11.5, color: p.textMuted)),
                ]),
              ),
              Text(Fmt.money(it.total), style: tx(context, 13, weight: FontWeight.w700)),
            ]),
          ),
        if (discount > 0) InfoRow(label: 'Discount', value: '-${Fmt.money(discount)}'),
        if (!isInvoice && widget.quotation!.addVat) InfoRow(label: 'VAT (7.5%)', value: Fmt.money(widget.quotation!.vat)),
        if (!isInvoice) InfoRow(label: 'Valid for', value: '${widget.quotation!.validityDays} days after sending'),
        Divider(color: p.border),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(isInvoice ? 'Total' : 'Quotation total', style: tx(context, 14, weight: FontWeight.w800))),
            MoneyText(total, size: 20),
          ]),
        ),
        if (isInvoice && widget.invoice!.allowPartPayment)
          Text('You can pay in part payments.', style: tx(context, 12, weight: FontWeight.w600, color: p.info)),
        if ((isInvoice ? widget.invoice!.notes : widget.quotation!.notes).isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(isInvoice ? widget.invoice!.notes : widget.quotation!.notes, style: tx(context, 12, color: p.textSecondary)),
        ],
      ]),
    );
  }
}

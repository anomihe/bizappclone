import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/doc_header_card.dart';
import '../widgets/invoice_sheets.dart';
import 'create_document_screen.dart';
import 'invoice_details_screen.dart';

/// "Quotation #Q016" — sent / accepted / expired / draft.
class QuotationDetailsScreen extends StatefulWidget {
  final Quotation quotation;
  final bool justSent;
  const QuotationDetailsScreen({super.key, required this.quotation, this.justSent = false});

  @override
  State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.justSent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _share();
      });
    }
  }

  void _share() {
    final q = widget.quotation;
    showShareSheet(
      context,
      title: 'Share Quotation',
      heading: '${q.customer?.name ?? ''} · ${q.number}',
      link: q.link,
      amount: q.total,
      footnote: 'Your customer can view and accept the quotation on a web page.',
    );
  }

  /// The server copies the items into a new draft invoice.
  Future<void> _convert() async {
    Invoice? created;
    final ok = await runLiveAction(context, () async => created = await LiveSession.instance.convertQuotation(widget.quotation),
        done: 'Invoice created from the quotation');
    if (ok && created != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: created!)));
    }
  }

  Future<void> _email() => runLiveAction(context, () => LiveSession.instance.emailQuotation(widget.quotation), done: 'Quotation emailed to the customer');

  Future<void> _pdf() => sharePdf(context, () => LiveSession.instance.quotationPdf(widget.quotation), 'Quotation-${widget.quotation.number}.pdf');

  Future<void> _delete() async {
    final q = widget.quotation;
    final ok = await showConfirmSheet(context, title: 'Delete quotation ${q.number}?', message: 'Your customer won’t be able to open it any more. This can’t be undone.', confirmLabel: 'Delete', cancelLabel: 'Keep It');
    if (!ok || !mounted) return;
    BizStore.instance.deleteQuotation(q);
    showToast(context, 'Quotation deleted');
    Navigator.pop(context);
  }

  void _reuse() {
    final copy = BizStore.instance.duplicateQuotation(widget.quotation);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.quotation(draft: copy)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: BizStore.instance, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final p = context.p;
    final q = widget.quotation;
    final status = q.status;
    final isDraft = status == QuotationStatus.draft;

    final Widget bottom = switch (status) {
      QuotationStatus.draft => CustomButton(text: 'Edit Quotation', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.quotation(draft: q)))),
      QuotationStatus.accepted => CustomButton(text: 'Convert to Invoice', variant: ButtonVariant.accent, onPressed: _convert),
      QuotationStatus.expired => CustomButton(text: 'Use to Create New Quotation', variant: ButtonVariant.outline, onPressed: _reuse),
      QuotationStatus.sent => Column(mainAxisSize: MainAxisSize.min, children: [
          CustomButton(text: 'Mark as Accepted', variant: ButtonVariant.soft, onPressed: () => BizStore.instance.acceptQuotation(q)),
          const SizedBox(height: 10),
          CustomButton(text: 'Convert to Invoice', variant: ButtonVariant.outline, onPressed: _convert),
        ]),
    };

    return InnerScaffold(
      title: 'Quotation #${q.number.replaceAll('-', '')}',
      subtitle: q.customer?.name,
      actions: [CircleIconButton(icon: Icons.delete_outline, tooltip: 'Delete quotation', color: p.error, onTap: _delete)],
      bottom: bottom,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DocHeaderCard(
          label: 'Proposed for',
          name: q.customer?.name ?? '—',
          amount: q.total,
          status: StatusStyle.quotation(status),
          subline: isDraft
              ? 'Valid for ${q.validityDays} days after sending'
              : 'Valid until ${q.validTill == null ? '—' : Fmt.date(q.validTill!)}',
          sublineColor: status == QuotationStatus.expired ? p.error : p.textMuted,
        ),
        if (status == QuotationStatus.expired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: p.readable(const Color(0xFFB07400))),
              const SizedBox(width: 8),
              Expanded(child: Text('This quotation has expired, so it cannot be converted. Create a new one from it.', style: tx(context, 12, color: p.textSecondary))),
            ]),
          ),
        ],
        const SizedBox(height: 18),
        const SectionLabel('Items'),
        ItemsList(items: q.items),
        if (q.discount > 0) InfoRow(label: 'Discount', value: '-${Fmt.money(q.discount)}'),
        if (q.addVat) InfoRow(label: 'VAT (7.5%)', value: Fmt.money(q.vat)),
        if (q.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(q.notes, style: tx(context, 12, color: p.textSecondary)),
        ],
        if (!isDraft) ...[
          const SizedBox(height: 14),
          const SectionLabel('Actions'),
          ...[
            if (status == QuotationStatus.sent)
              ActionTile(icon: Icons.mail_outline, title: 'Email to customer', subtitle: q.customer?.email.isNotEmpty == true ? q.customer!.email : 'Sends the quotation by email', onTap: _email),
            ActionTile(icon: Icons.picture_as_pdf_outlined, title: 'Download PDF', subtitle: 'Save or share the quotation', onTap: _pdf),
          ],
          ActionTile(icon: Icons.share_outlined, title: 'Share Quotation Link', subtitle: q.link, onTap: _share),
        ],
      ]),
    );
  }
}

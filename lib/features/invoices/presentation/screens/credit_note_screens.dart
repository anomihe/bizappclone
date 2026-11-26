import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/doc_header_card.dart';
import '../widgets/refund_form.dart';
import 'invoice_details_screen.dart';
import 'refund_screens.dart';

/// "Issue Credit Note or Refund" chooser from a paid payment.
Future<void> showCreditOrRefundSheet(BuildContext context, Invoice invoice) {
  return showBpSheet(
    context,
    title: 'Issue Credit Note or Refund',
    builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      ActionTile(
        icon: Icons.description_outlined,
        title: 'Issue credit note',
        subtitle: 'Reduce what the customer owes, then refund if needed',
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(context, MaterialPageRoute(builder: (_) => IssueCreditNoteScreen(invoice: invoice)));
        },
      ),
      ActionTile(
        icon: Icons.undo,
        title: 'Request a refund',
        subtitle: 'Send money back to the customer',
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(context, MaterialPageRoute(builder: (_) => RequestRefundScreen(invoice: invoice)));
        },
      ),
    ]),
  );
}

class IssueCreditNoteScreen extends StatefulWidget {
  final Invoice invoice;
  const IssueCreditNoteScreen({super.key, required this.invoice});

  @override
  State<IssueCreditNoteScreen> createState() => _IssueCreditNoteScreenState();
}

class _IssueCreditNoteScreenState extends State<IssueCreditNoteScreen> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.invoice;
    final refundable = i.refundableBalance;
    return InnerScaffold(
      title: 'Issue Credit Note',
      subtitle: 'For Invoice ${i.number}',
      bottom: CustomButton(
        text: 'Issue Credit Notice',
        onPressed: RefundForm.valid(_amount, _reason, refundable)
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreditNotePreviewScreen(invoice: i, amount: double.parse(_amount.text), reason: _reason.text.trim()),
                  ),
                )
            : null,
      ),
      body: RefundForm(refundable: refundable, amount: _amount, reason: _reason, onChanged: () => setState(() {})),
    );
  }
}

class CreditNotePreviewScreen extends StatefulWidget {
  final Invoice invoice;
  final double amount;
  final String reason;
  const CreditNotePreviewScreen({super.key, required this.invoice, required this.amount, required this.reason});

  @override
  State<CreditNotePreviewScreen> createState() => _CreditNotePreviewScreenState();
}

class _CreditNotePreviewScreenState extends State<CreditNotePreviewScreen> {
  bool _loading = false;

  Future<void> _issue({required bool withRefund}) async {
    setState(() => _loading = true);
    final s = LiveSession.instance;
    CreditNote? note;
    RefundRequest? refund;
    final ok = await runLiveAction(context, () async {
      note = await s.issueCreditNote(widget.invoice, widget.amount, widget.reason);
      if (withRefund) refund = await s.requestRefund(widget.invoice, widget.amount, widget.reason);
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok || note == null) return;
    final nav = Navigator.of(context);
    // Drop the form + preview, land on the issued credit note.
    nav.pop();
    nav.pushReplacement(MaterialPageRoute(builder: (_) => CreditNoteScreen(invoice: widget.invoice, note: note!, refund: refund)));
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'Credit Note Preview',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        CustomButton(text: 'Request a Refund', variant: ButtonVariant.accent, isLoading: _loading, onPressed: () => _issue(withRefund: true)),
        const SizedBox(height: 10),
        CustomButton(text: 'Issue Credit Note Only', variant: ButtonVariant.outline, onPressed: _loading ? null : () => _issue(withRefund: false)),
      ]),
      body: _CreditNoteBody(
        invoice: widget.invoice,
        number: 'New credit note', // the backend numbers it when issued
        amount: widget.amount,
        reason: widget.reason,
        date: DateTime.now(),
      ),
    );
  }
}

class CreditNoteScreen extends StatelessWidget {
  final Invoice invoice;
  final CreditNote note;
  final RefundRequest? refund;
  const CreditNoteScreen({super.key, required this.invoice, required this.note, this.refund});

  @override
  Widget build(BuildContext context) {
    final linkedRefund = refund ?? (invoice.refunds.isEmpty ? null : invoice.refunds.last);
    return InnerScaffold(
      title: 'Credit Note',
      bottom: linkedRefund == null
          ? null
          : CustomButton(
              text: 'View Refund Status',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RefundStatusScreen(invoice: invoice, refund: linkedRefund))),
            ),
      body: _CreditNoteBody(invoice: invoice, number: note.number, amount: note.amount, reason: note.reason, date: note.date),
    );
  }
}

class _CreditNoteBody extends StatelessWidget {
  final Invoice invoice;
  final String number;
  final double amount;
  final String reason;
  final DateTime date;
  const _CreditNoteBody({required this.invoice, required this.number, required this.amount, required this.reason, required this.date});

  @override
  Widget build(BuildContext context) {
    return DocHeaderCard(
      label: 'Credit note',
      name: number,
      amountCaption: 'Amount Credited',
      amount: amount,
      extra: [
        const SizedBox(height: 10),
        InfoRow(label: 'Customer', value: invoice.customerName),
        InfoRow(label: 'Date', value: Fmt.date(date)),
        InfoRow(label: 'Reason', value: reason),
        InfoRow(
          label: 'Linked invoice',
          value: invoice.number,
          valueColor: AppColors.primary,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: invoice))),
        ),
      ],
    );
  }
}

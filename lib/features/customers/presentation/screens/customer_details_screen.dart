import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../invoices/presentation/screens/create_document_screen.dart';
import '../../../invoices/presentation/screens/invoice_details_screen.dart';
import '../../../invoices/presentation/screens/quotation_details_screen.dart';
import '../../../payments/presentation/screens/payment_details_screen.dart';
import 'customer_form_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  int _tab = 0; // invoices, quotations, payments

  /// Calling / WhatsApp / email need `url_launcher`; until then copy the contact.
  void _contact(String what, String value) {
    if (value.trim().isEmpty) {
      showToast(context, 'No $what saved for this customer');
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    showToast(context, '${what[0].toUpperCase()}${what.substring(1)} copied');
  }

  Future<void> _delete(Customer c) async {
    final ok = await showConfirmSheet(context, title: 'Delete ${c.name}?', message: 'Their invoices and payments stay in your records. This can’t be undone.', confirmLabel: 'Delete Customer', cancelLabel: 'Keep');
    if (!ok || !mounted) return;
    BizStore.instance.deleteCustomer(c);
    showToast(context, 'Customer deleted');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context, store));
  }

  Widget _build(BuildContext context, BizStore store) {
    final p = context.p;
    final c = widget.customer;
    final first = c.name.split(' ').first;

    Widget quick(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 4),
                Text(label, style: tx(context, 11.5, color: p.textSecondary)),
              ]),
            ),
          ),
        );

    Widget money(String label, double v, Color header) => Expanded(
          child: Container(
            decoration: BoxDecoration(color: header, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(10, 6, 10, 6), child: Text(label, style: tx(context, 11, weight: FontWeight.w600, color: Colors.white))),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(3, 0, 3, 3),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10)),
                child: MoneyText(v, size: 16),
              ),
            ]),
          ),
        );

    final invoices = store.invoicesFor(c);
    final quotes = store.quotationsFor(c);
    final payments = store.paymentsFor(c);

    final List<Widget> list = switch (_tab) {
      0 => [
          for (final i in invoices)
            RecordTile(
              leading: const LeadingIcon(Icons.receipt_long_outlined),
              title: i.customerName,
              subtitle: '${i.number} · ${Fmt.date(i.createdAt)}',
              amount: i.total,
              status: StatusStyle.invoice(i.status),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: i))),
            ),
        ],
      1 => [
          for (final q in quotes)
            RecordTile(
              leading: const LeadingIcon(Icons.request_quote_outlined, color: AppColors.accent),
              title: q.customer?.name ?? c.name,
              subtitle: '${q.number} · ${Fmt.date(q.createdAt)}',
              amount: q.total,
              status: StatusStyle.quotation(q.status),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationDetailsScreen(quotation: q))),
            ),
        ],
      _ => [
          for (final pay in payments)
            RecordTile(
              leading: const LeadingIcon(Icons.receipt_outlined),
              title: pay.customerName,
              subtitle: '${pay.sourceLabel} · ${Fmt.relativeDay(pay.date)}',
              amount: pay.amount,
              status: StatusStyle.payment(pay.status),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailsScreen(payment: pay))),
            ),
        ],
    };
    final (emptyTitle, emptyMsg) = switch (_tab) {
      0 => ('No invoice yet', 'Invoices you send to $first show up here.'),
      1 => ('No quotation yet', 'Quotes you send to $first show up here.'),
      _ => ('No payment yet', 'When a customer pays, it shows up here with the invoice it settled.'),
    };

    return InnerScaffold(
      title: '',
      actions: [
        CircleIconButton(
          icon: Icons.manage_accounts_outlined,
          tooltip: 'Edit customer',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: c))),
        ),
        const SizedBox(width: 8),
        CircleIconButton(icon: Icons.delete_outline, tooltip: 'Delete customer', color: context.p.error, onTap: () => _delete(c)),
      ],
      bottom: CustomButton(
        text: 'New Invoice for $first',
        variant: ButtonVariant.accent,
        icon: const Icon(Icons.receipt_long_outlined),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.invoice(customer: c))),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BpCard(
          child: Row(children: [
            InitialsAvatar(c.name, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: tx(context, 16, weight: FontWeight.w800)),
                Text('${c.dialCode} ${c.phone}', style: tx(context, 12, color: p.textSecondary)),
                if (c.email.isNotEmpty) Text(c.email, style: tx(context, 12, color: p.textMuted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          quick(Icons.call_outlined, 'Call', p.brand, () => _contact('phone number', '${c.dialCode} ${c.phone}')),
          quick(Icons.chat_outlined, 'WhatsApp', const Color(0xFF25D366), () => _contact('phone number', '${c.dialCode} ${c.phone}')),
          quick(Icons.email_outlined, 'Email', p.info, () => _contact('email', c.email)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          money('Balance Owed', store.owedBy(c), const Color(0xFF9A6A0B)),
          const SizedBox(width: 10),
          money('Paid So Far', store.paidBy(c), AppColors.primary),
        ]),
        if (c.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          BpCard(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Note: ', style: tx(context, 12.5, weight: FontWeight.w700)),
              TextSpan(text: c.notes, style: tx(context, 12.5, color: p.textSecondary)),
            ])),
          ),
        ],
        const SizedBox(height: 16),
        SegmentedPills(options: const ['Invoices', 'Quotations', 'Payments'], index: _tab, fontSize: 12, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 12),
        if (list.isEmpty) EmptyState(icon: Icons.receipt_long_outlined, title: emptyTitle, message: emptyMsg) else ...list,
      ]),
    );
  }
}

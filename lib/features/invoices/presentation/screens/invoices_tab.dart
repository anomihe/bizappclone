import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/invoice_sheets.dart';
import 'create_document_screen.dart';
import 'invoice_details_screen.dart';
import 'quotation_details_screen.dart';

class InvoicesTab extends StatefulWidget {
  const InvoicesTab({super.key});

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _segment == 0 ? CreateDocumentScreen.invoice() : CreateDocumentScreen.quotation()),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF111916),
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: Text('Create New', style: tx(context, 13, weight: FontWeight.w700, color: const Color(0xFF111916))),
      ),
      body: Column(children: [
        TabHeader(
          title: 'Invoices',
          bottom: SegmentedPills(options: const ['Invoices', 'Quotations'], index: _segment, onChanged: (i) => setState(() => _segment = i)),
        ),
        Expanded(child: TabPanel(child: _segment == 0 ? const InvoiceList() : const QuotationList())),
      ]),
    );
  }
}

bool _matches(String q, String name, String number) {
  if (q.isEmpty) return true;
  final n = q.toLowerCase();
  return name.toLowerCase().contains(n) || number.toLowerCase().contains(n);
}

/// Filterable, searchable list of invoices (payment links have their own screen).
class InvoiceList extends StatefulWidget {
  const InvoiceList({super.key});

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  String _filter = 'All';
  String _q = '';
  static const _filters = ['All', 'Draft', 'Unpaid', 'Paid', 'Last 7 Days', 'Overdue'];

  bool _match(Invoice i) => switch (_filter) {
        'Draft' => i.status == InvoiceStatus.draft,
        'Unpaid' => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partlyPaid,
        'Paid' => i.status == InvoiceStatus.paid,
        'Overdue' => i.status == InvoiceStatus.overdue,
        'Last 7 Days' => i.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))),
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final all = store.invoices.where((i) => i.kind == DocKind.invoice).toList();
        final list = all.where((i) => _match(i) && _matches(_q, i.customerName, i.number)).toList();

        return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 96), children: [
          SearchField(hint: 'Search customer or number', onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final f in _filters)
                Padding(padding: const EdgeInsets.only(right: 8), child: SelectChip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f))),
            ]),
          ),
          const SizedBox(height: 12),
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Invoices Here',
                message: 'Create your first invoice and share the pay link.',
                action: CustomButton(
                  text: 'Create Invoice',
                  variant: ButtonVariant.accent,
                  icon: const Icon(Icons.add),
                  width: 190,
                  height: 42,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.invoice())),
                ),
              ),
            )
          else if (list.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 50), child: EmptyState(icon: Icons.search_off, title: 'Nothing here', message: 'No invoices match this search or filter.'))
          else
            for (final i in list)
              RecordTile(
                leading: const LeadingIcon(Icons.receipt_long_outlined),
                title: i.customerName,
                subtitle: '${i.number} · ${i.dueDate == null ? Fmt.date(i.createdAt) : 'Due ${Fmt.date(i.dueDate!)}'}',
                amount: i.total,
                status: StatusStyle.invoice(i.status),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: i))),
                footer: i.status == InvoiceStatus.overdue
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => showSendReminderSheet(context, i),
                          icon: Icon(Icons.notifications_active_outlined, size: 15, color: p.textSecondary),
                          label: Text('Send Reminder', style: tx(context, 11.5, weight: FontWeight.w700, color: p.textSecondary)),
                        ),
                      )
                    : null,
              ),
        ]);
      },
    );
  }
}

class QuotationList extends StatefulWidget {
  const QuotationList({super.key});

  @override
  State<QuotationList> createState() => _QuotationListState();
}

class _QuotationListState extends State<QuotationList> {
  QuotationStatus? _filter;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.quotations
            .where((q) => (_filter == null || q.status == _filter) && _matches(_q, q.customer?.name ?? '', q.number))
            .toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 96), children: [
          SearchField(hint: 'Search customer or number', onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: SelectChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null))),
              for (final s in QuotationStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SelectChip(label: StatusStyle.quotation(s).label, selected: _filter == s, onTap: () => setState(() => _filter = s)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          if (store.quotations.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: EmptyState(
                icon: Icons.request_quote_outlined,
                title: 'No Quotations Here',
                message: 'Send a quote before the job starts, then convert it to an invoice once the customer accepts.',
                action: CustomButton(
                  text: 'Add Quotation',
                  variant: ButtonVariant.accent,
                  icon: const Icon(Icons.add),
                  width: 190,
                  height: 42,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.quotation())),
                ),
              ),
            )
          else if (list.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 50), child: EmptyState(icon: Icons.search_off, title: 'Nothing here', message: 'No quotations match this search or filter.'))
          else
            for (final q in list)
              RecordTile(
                leading: const LeadingIcon(Icons.request_quote_outlined, color: AppColors.accent),
                title: q.customer?.name ?? '—',
                subtitle: '${q.number} · ${Fmt.date(q.createdAt)}',
                amount: q.total,
                status: StatusStyle.quotation(q.status),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationDetailsScreen(quotation: q))),
              ),
        ]);
      },
    );
  }
}

/// More → Quotations.
class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Quotations',
        scroll: false,
        bodyPadding: EdgeInsets.zero,
        titleTrailing: CircleIconButton(
          icon: Icons.note_add_outlined,
          background: AppColors.primary,
          color: Colors.white,
          tooltip: 'New quotation',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.quotation())),
        ),
        body: const QuotationList(),
      );
}

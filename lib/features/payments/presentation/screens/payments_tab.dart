import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/calendar_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'payment_details_screen.dart';

enum DatePreset { allTime, today, yesterday, last7, last30, last90, custom }

const _presetLabels = {
  DatePreset.allTime: 'All Time',
  DatePreset.today: 'Today',
  DatePreset.yesterday: 'Yesterday',
  DatePreset.last7: 'Last 7 Days',
  DatePreset.last30: 'Last 30 Days',
  DatePreset.last90: 'Last 90 Days',
  DatePreset.custom: 'Custom',
};

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  final store = BizStore.instance;
  final _search = TextEditingController();
  String _query = '';
  bool _showFilters = false;
  Set<PaymentStatus> _statuses = {};
  Set<DocKind> _types = {};
  DatePreset _date = DatePreset.allTime;
  DateTimeRange? _custom;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _inDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_date) {
      DatePreset.allTime => true,
      DatePreset.today => !d.isBefore(today),
      DatePreset.yesterday => !d.isBefore(today.subtract(const Duration(days: 1))) && d.isBefore(today),
      DatePreset.last7 => !d.isBefore(today.subtract(const Duration(days: 6))),
      DatePreset.last30 => !d.isBefore(today.subtract(const Duration(days: 29))),
      DatePreset.last90 => !d.isBefore(today.subtract(const Duration(days: 89))),
      DatePreset.custom => _custom != null && !d.isBefore(_custom!.start) && d.isBefore(_custom!.end.add(const Duration(days: 1))),
    };
  }

  List<Payment> get _filtered {
    final q = _query.toLowerCase();
    return store.payments.where((p) {
      if (q.isNotEmpty && !p.customerName.toLowerCase().contains(q) && !p.invoiceNumber.contains(q)) return false;
      if (_statuses.isNotEmpty && !_statuses.contains(p.status)) return false;
      if (_types.isNotEmpty) {
        final kind = store.invoiceById(p.invoiceId)?.kind ?? DocKind.invoice;
        if (!_types.contains(kind)) return false;
      }
      return _inDate(p.date);
    }).toList();
  }

  // ------------------------------------------------------------ filter sheets

  Future<void> _statusSheet() async {
    var temp = {..._statuses};
    final applied = await showBpSheet<bool>(
      context,
      title: 'Select Payment Status',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            SelectChip(label: 'All', selected: temp.isEmpty, onTap: () => setSheet(() => temp = {})),
            for (final s in PaymentStatus.values)
              SelectChip(
                label: StatusStyle.payment(s).label,
                selected: temp.contains(s),
                onTap: () => setSheet(() => temp.contains(s) ? temp.remove(s) : temp.add(s)),
              ),
          ]),
          const SizedBox(height: 20),
          _sheetButtons(ctx),
        ]),
      ),
    );
    if (applied == true) setState(() => _statuses = temp);
  }

  Future<void> _typeSheet() async {
    var temp = {..._types};
    final applied = await showBpSheet<bool>(
      context,
      title: 'Payment Type',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            SelectChip(label: 'All', selected: temp.isEmpty, onTap: () => setSheet(() => temp = {})),
            for (final (k, label) in [(DocKind.invoice, 'Invoice'), (DocKind.paymentLink, 'Payment Link')])
              SelectChip(label: label, selected: temp.contains(k), onTap: () => setSheet(() => temp.contains(k) ? temp.remove(k) : temp.add(k))),
          ]),
          const SizedBox(height: 20),
          _sheetButtons(ctx),
        ]),
      ),
    );
    if (applied == true) setState(() => _types = temp);
  }

  Future<void> _dateSheet() async {
    var preset = _date;
    DateTimeRange? range = _custom;
    final applied = await showBpSheet<bool>(
      context,
      title: 'Filter by Date',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in DatePreset.values) SelectChip(label: _presetLabels[d]!, selected: preset == d, onTap: () => setSheet(() => preset = d)),
            ]),
            const SizedBox(height: 16),
            if (preset == DatePreset.custom)
              DateRangePickerBody(
                initial: range,
                onCancel: () => Navigator.pop(ctx, false),
                onApply: (r) {
                  range = r;
                  Navigator.pop(ctx, true);
                },
              )
            else
              _sheetButtons(ctx),
          ]),
        ),
      ),
    );
    if (applied == true) {
      setState(() {
        _date = preset;
        _custom = range;
      });
    }
  }

  Widget _sheetButtons(BuildContext ctx) => Row(children: [
        Expanded(child: CustomButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false))),
        const SizedBox(width: 10),
        Expanded(child: CustomButton(text: 'Apply', onPressed: () => Navigator.pop(ctx, true))),
      ]);

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.payments;
        final list = _filtered;
        final total = list.where((x) => x.paidByCustomer).fold<double>(0, (s, x) => s + x.amount);

        return Column(children: [
          TabHeader(title: 'All payments'),
          Expanded(
            child: TabPanel(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
                SearchField(
                  hint: 'Search',
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  trailing: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.cancel_outlined, size: 18, color: p.textMuted),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        )
                      : IconButton(
                          tooltip: 'Filters',
                          icon: Icon(Icons.tune, size: 19, color: _showFilters ? context.p.brand : p.textSecondary),
                          onPressed: () => setState(() => _showFilters = !_showFilters),
                        ),
                ),
                if (_showFilters || _statuses.isNotEmpty || _types.isNotEmpty || _date != DatePreset.allTime) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      _filterChip(
                        icon: Icons.filter_list,
                        label: _statuses.isEmpty ? 'Status' : 'Status (${_statuses.length})',
                        active: _statuses.isNotEmpty,
                        onTap: _statusSheet,
                        onClear: () => setState(() => _statuses = {}),
                      ),
                      _filterChip(
                        icon: Icons.category_outlined,
                        label: _types.isEmpty ? 'Type' : 'Type (${_types.length})',
                        active: _types.isNotEmpty,
                        onTap: _typeSheet,
                        onClear: () => setState(() => _types = {}),
                      ),
                      _filterChip(
                        icon: Icons.calendar_today_outlined,
                        label: _date == DatePreset.allTime ? 'Date' : _presetLabels[_date]!,
                        active: _date != DatePreset.allTime,
                        onTap: _dateSheet,
                        onClear: () => setState(() => _date = DatePreset.allTime),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                if (all.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(icon: Icons.point_of_sale_outlined, title: 'No payment yet', message: 'Payments from your customers will show up here.'),
                  )
                else if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching transactions',
                      message: 'Try a different filter, or come back after your new transaction lands.',
                    ),
                  )
                else ...[
                  Row(children: [
                    Expanded(child: Text('${list.length} Payment${list.length == 1 ? '' : 's'}', style: tx(context, 12.5, color: p.textSecondary))),
                    MoneyText(total, size: 15),
                  ]),
                  const SizedBox(height: 10),
                  ..._grouped(list),
                ],
              ]),
            ),
          ),
        ]);
      },
    );
  }

  List<Widget> _grouped(List<Payment> list) {
    final out = <Widget>[];
    String? current;
    for (final pay in list) {
      final key = '${Fmt.monthShort(pay.date.month)} ${pay.date.year}';
      if (key != current) {
        current = key;
        out.add(Padding(padding: const EdgeInsets.only(top: 4, bottom: 8), child: Text(key, style: tx(context, 12, weight: FontWeight.w700, color: context.p.textMuted))));
      }
      out.add(RecordTile(
        leading: const LeadingIcon(Icons.receipt_outlined),
        title: pay.customerName,
        subtitle: '${pay.sourceLabel} · ${Fmt.relativeDay(pay.date)}',
        amount: pay.amount,
        status: StatusStyle.payment(pay.status),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailsScreen(payment: pay))),
      ));
    }
    return out;
  }

  Widget _filterChip({required IconData icon, required String label, required bool active, required VoidCallback onTap, required VoidCallback onClear}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SelectChip(
        icon: icon,
        label: label,
        selected: active,
        onTap: onTap,
        trailing: active ? InkWell(onTap: onClear, child: Icon(Icons.close, size: 14, color: context.p.brand)) : null,
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/api/mappers.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/calendar_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../home/presentation/widgets/revenue_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final store = BizStore.instance;
  int _period = 0; // 7, 30, 90, custom
  DateTimeRange? _custom;

  /// Live mode: `GET /api/v1/admin/dashboard` stats (null in demo mode).
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    if (LiveSession.enabled) {
      LiveSession.instance.business.dashboard().then((d) {
        final stats = d['stats'];
        if (mounted && stats is Map<String, dynamic>) setState(() => _overview = stats);
      }).catchError((_) {});
    }
  }

  Widget _overviewCard(BuildContext context) {
    final s = _overview!;
    num n(String k) => ApiMappers.num0(s[k]);
    final growth = n('revenue_growth');
    return BpCard(
      color: context.p.cardAlt,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Account overview', style: tx(context, 14, weight: FontWeight.w800)),
        const SizedBox(height: 10),
        InfoRow(label: 'Revenue this month', value: '${Fmt.money(n('revenue_this_month'))}${growth == 0 ? '' : '  (${growth > 0 ? '+' : ''}${growth.toStringAsFixed(1)}%)'}'),
        const SizedBox(height: 8),
        InfoRow(label: 'Total revenue', value: Fmt.money(n('total_revenue'))),
        const SizedBox(height: 8),
        InfoRow(label: 'Unpaid invoices', value: '${n('unpaid_invoices_count').toInt()}'),
        const SizedBox(height: 8),
        InfoRow(label: 'Active projects', value: '${n('active_projects').toInt()}'),
        const SizedBox(height: 8),
        InfoRow(label: 'Salaries this month', value: Fmt.money(n('salaries_this_month'))),
        if (n('safe_haven_balance') != 0) ...[
          const SizedBox(height: 8),
          InfoRow(label: 'Collection account balance', value: Fmt.money(n('safe_haven_balance'))),
        ],
      ]),
    );
  }

  (DateTime, DateTime?, int) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      0 => (today.subtract(const Duration(days: 6)), null, 7),
      1 => (today.subtract(const Duration(days: 29)), null, 30),
      2 => (today.subtract(const Duration(days: 89)), null, 90),
      _ => (_custom!.start, _custom!.end.add(const Duration(days: 1)), _custom!.duration.inDays + 1),
    };
  }

  Future<void> _download() async {
    var format = 'PDF';
    final go = await showBpSheet<bool>(
      context,
      title: 'Download Sales Report',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Format', style: tx(ctx, 12.5, weight: FontWeight.w600, color: ctx.p.textSecondary)),
          const SizedBox(height: 8),
          SegmentedPills(options: const ['PDF', 'CSV'], index: format == 'PDF' ? 0 : 1, onChanged: (i) => setSheet(() => format = i == 0 ? 'PDF' : 'CSV')),
          const SizedBox(height: 18),
          CustomButton(text: 'Download', icon: const Icon(Icons.download_outlined), onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    // Writing the file needs `path_provider` + `pdf`/`csv` packages.
    if (go == true && mounted) showToast(context, '$format export is coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final p = context.p;
    final (from, to, days) = _range;
    final collected = store.collected(from, to);
    final invoiced = store.invoicedIn(from, to);
    final settled = store.settled(from, to);
    final waiting = store.onItsWay(from, to);
    final rate = invoiced == 0 ? 0 : (collected / invoiced * 100).clamp(0, 100).round();
    final counts = store.paymentCounts(from, to);
    final success = counts[PaymentStatus.paid]! + counts[PaymentStatus.partlyPaid]! + counts[PaymentStatus.refunded]!;
    final pending = counts[PaymentStatus.pending]!;
    final failed = counts[PaymentStatus.failed]!;
    final inv = store.invoiceCounts(from, to);
    final invTotal = inv.values.fold<int>(0, (s, v) => s + v);
    final orders = store.ordersIn(from, to);
    final chartDays = days.clamp(1, 30);
    final chartStart = (to ?? DateTime.now()).subtract(Duration(days: chartDays - (to == null ? 1 : 0)));
    final dates = List.generate(chartDays, (i) => DateTime(chartStart.year, chartStart.month, chartStart.day).add(Duration(days: i)));
    final values = dates.map((d) => store.collected(d, d.add(const Duration(days: 1)))).toList();

    Widget card(String title, List<Widget> children, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BpCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Expanded(child: Text(title, style: tx(context, 13.5, weight: FontWeight.w800))), ?trailing]),
              const SizedBox(height: 10),
              ...children,
            ]),
          ),
        );

    Widget perf(String label, int count, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: Text(label, style: tx(context, 12, color: p.textSecondary))), Text('$count', style: tx(context, 12, weight: FontWeight.w700))]),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: invTotal == 0 ? 0 : count / invTotal,
                minHeight: 6,
                color: color,
                backgroundColor: p.border,
              ),
            ),
          ]),
        );

    final customLabel = _custom == null ? 'Custom' : '${Fmt.dateNumeric(_custom!.start)} – ${Fmt.dateNumeric(_custom!.end)}';

    return InnerScaffold(
      title: 'Reports',
      actions: [
        TextButton.icon(
          onPressed: _download,
          icon: Icon(Icons.download_outlined, size: 17, color: p.brand),
          label: Text('Download', style: tx(context, 12.5, weight: FontWeight.w700, color: p.brand)),
        ),
      ],
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_overview != null) ...[_overviewCard(context), const SizedBox(height: 16)],
        SizedBox(
          height: 34,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final (i, l) in [(0, '7 Days'), (1, '30 Days'), (2, '90 Days')])
              Padding(padding: const EdgeInsets.only(right: 8), child: SelectChip(label: l, selected: _period == i, onTap: () => setState(() => _period = i))),
            SelectChip(
              label: customLabel,
              icon: Icons.calendar_today_outlined,
              selected: _period == 3,
              onTap: () async {
                final r = await showDateRangeSheet(context, initial: _custom, title: 'Customs');
                if (r != null) {
                  setState(() {
                    _custom = r;
                    _period = 3;
                  });
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: 14),
        card('Revenue Summary', [
          RevenueChart(values: values, days: dates),
          const SizedBox(height: 10),
          InfoRow(label: 'Outstanding receivables', value: Fmt.money(store.outstanding + store.overdue)),
          InfoRow(label: 'Collected', value: Fmt.money(collected), bold: true),
        ], trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          MoneyText(collected, size: 14),
          Text(_period == 3 ? '$days days' : 'Last $days days', style: tx(context, 10.5, color: p.textMuted)),
        ])),
        card('Financial Summary', [
          InfoRow(label: 'Invoiced', value: Fmt.money(invoiced)),
          InfoRow(label: 'Paid by customer', value: Fmt.money(collected)),
          InfoRow(label: 'Settled to your account', value: Fmt.money(settled)),
          InfoRow(label: 'Waiting to settle', value: Fmt.money(waiting)),
          InfoRow(label: 'Collection rate', value: '$rate%', bold: true),
        ]),
        card('Payment Statistics', [
          Center(child: _Gauge(success: success, pending: pending, failed: failed)),
          const SizedBox(height: 8),
          for (final (l, v, c) in [('Successful', success, AppColors.primaryLight), ('Pending', pending, AppColors.accent), ('Failed', failed, AppColors.error)])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(l, style: tx(context, 12, color: p.textSecondary))),
                Text('$v', style: tx(context, 12, weight: FontWeight.w700)),
              ]),
            ),
        ]),
        card('Invoice Performance', [
          perf('Paid', inv[InvoiceStatus.paid]!, AppColors.primaryLight),
          perf('Partly Paid', inv[InvoiceStatus.partlyPaid]!, const Color(0xFF6BBF9B)),
          perf('Unpaid', inv[InvoiceStatus.unpaid]!, AppColors.accent),
          perf('Overdue', inv[InvoiceStatus.overdue]!, AppColors.error),
        ]),
        card('Customer Statistics', [
          InfoRow(label: 'Total Customers', value: '${store.customers.length}'),
          InfoRow(label: 'Owing you', value: '${store.customers.where((c) => store.owedBy(c) > 0).length}'),
        ]),
        card('Sales Performance', [
          InfoRow(label: 'Store Orders', value: '${orders.length}'),
          InfoRow(label: 'Order value', value: Fmt.money(orders.where((o) => o.status != OrderStatus.cancelled).fold<double>(0, (s, o) => s + o.total))),
        ]),
      ]),
    );
  }
}

/// Semicircle split into successful / pending / failed, total in the middle.
class _Gauge extends StatelessWidget {
  final int success;
  final int pending;
  final int failed;
  const _Gauge({required this.success, required this.pending, required this.failed});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final total = success + pending + failed;
    return SizedBox(
      width: 220,
      height: 124,
      child: CustomPaint(
        painter: _GaugePainter(values: [success, pending, failed], colors: const [AppColors.primaryLight, AppColors.accent, AppColors.error], track: p.border),
        child: Align(
          alignment: const Alignment(0, 0.7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Total Count', style: tx(context, 11, color: p.textMuted)),
            Text(Fmt.thousands(total), style: tx(context, 22, weight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  final Color track;
  _GaugePainter({required this.values, required this.colors, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height - 4), radius: size.width / 2 - stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, math.pi, math.pi, false, paint..color = track);
    final total = values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return;
    var start = math.pi;
    for (var i = 0; i < values.length; i++) {
      final sweep = math.pi * values[i] / total;
      if (sweep > 0) canvas.drawArc(rect, start, sweep, false, paint..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.values.toString() != values.toString() || old.track != track;
}

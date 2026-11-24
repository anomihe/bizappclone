import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/format.dart';
import 'custom_button.dart';
import 'ui_kit.dart';

/// "Choose Date" sheet with the custom month grid from the designs.
Future<DateTime?> showDatePickerSheet(BuildContext context, {DateTime? initial, String title = 'Choose Date', DateTime? firstDate}) {
  return showBpSheet<DateTime>(
    context,
    title: title,
    builder: (_) => _SingleDatePicker(initial: initial ?? DateTime.now(), firstDate: firstDate),
  );
}

/// "Custom" date-range sheet with From / To boxes above the calendar.
Future<DateTimeRange?> showDateRangeSheet(BuildContext context, {DateTimeRange? initial, String title = 'Custom'}) {
  return showBpSheet<DateTimeRange>(
    context,
    title: title,
    builder: (_) => DateRangePickerBody(initial: initial, onApply: (r) => Navigator.pop(context, r)),
  );
}

class _SingleDatePicker extends StatefulWidget {
  final DateTime initial;
  final DateTime? firstDate;
  const _SingleDatePicker({required this.initial, this.firstDate});

  @override
  State<_SingleDatePicker> createState() => _SingleDatePickerState();
}

class _SingleDatePickerState extends State<_SingleDatePicker> {
  late DateTime _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(Fmt.dayHeader(_selected), style: tx(context, 18, weight: FontWeight.w800)),
      const SizedBox(height: 10),
      MonthCalendar(
        start: _selected,
        firstDate: widget.firstDate,
        onTap: (d) => setState(() => _selected = d),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: CustomButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context))),
        const SizedBox(width: 10),
        Expanded(child: CustomButton(text: 'Apply', onPressed: () => Navigator.pop(context, _selected))),
      ]),
    ]);
  }
}

/// Range picker body, reused by the dashboard "Custom" sheet and the
/// payments "Filter by Date" sheet.
class DateRangePickerBody extends StatefulWidget {
  final DateTimeRange? initial;
  final ValueChanged<DateTimeRange> onApply;
  final VoidCallback? onCancel;
  const DateRangePickerBody({super.key, this.initial, required this.onApply, this.onCancel});

  @override
  State<DateRangePickerBody> createState() => _DateRangePickerBodyState();
}

class _DateRangePickerBodyState extends State<DateRangePickerBody> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initial?.start;
    _to = widget.initial?.end;
  }

  void _tap(DateTime d) {
    setState(() {
      if (_from == null || _to != null) {
        _from = d;
        _to = null;
      } else if (d.isBefore(_from!)) {
        _to = _from;
        _from = d;
      } else {
        _to = d;
      }
    });
  }

  Widget _box(String label, DateTime? d) {
    final p = context.p;
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: tx(context, 12, color: p.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
          child: Row(children: [
            Expanded(child: Text(d == null ? 'dd/mm/yyyy' : Fmt.dateNumeric(d), style: tx(context, 12.5, color: d == null ? p.textMuted : p.text))),
            Icon(Icons.calendar_today_outlined, size: 15, color: p.textMuted),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [_box('From', _from), const SizedBox(width: 10), _box('To', _to)]),
      const SizedBox(height: 14),
      Text(Fmt.dayHeader(_to ?? _from ?? DateTime.now()), style: tx(context, 17, weight: FontWeight.w800)),
      const SizedBox(height: 8),
      MonthCalendar(start: _from ?? DateTime.now(), rangeStart: _from, rangeEnd: _to, onTap: _tap),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: CustomButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: widget.onCancel ?? () => Navigator.pop(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomButton(
            text: 'Apply',
            onPressed: _from == null ? null : () => widget.onApply(DateTimeRange(start: _from!, end: _to ?? _from!)),
          ),
        ),
      ]),
    ]);
  }
}

class MonthCalendar extends StatefulWidget {
  final DateTime start;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onTap;
  const MonthCalendar({super.key, required this.start, required this.onTap, this.rangeStart, this.rangeEnd, this.firstDate});

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime(widget.start.year, widget.start.month);
  DateTime? _single;

  bool _same(DateTime? a, DateTime b) => a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday - 1; // Monday first
    final isRange = widget.rangeStart != null || widget.rangeEnd != null;
    final selected = isRange ? null : (_single ?? widget.start);

    Widget cell(int day) {
      final d = DateTime(_month.year, _month.month, day);
      final disabled = widget.firstDate != null && d.isBefore(DateTime(widget.firstDate!.year, widget.firstDate!.month, widget.firstDate!.day));
      final isEdge = _same(widget.rangeStart, d) || _same(widget.rangeEnd, d) || _same(selected, d);
      final inRange = widget.rangeStart != null && widget.rangeEnd != null && d.isAfter(widget.rangeStart!) && d.isBefore(widget.rangeEnd!);
      return GestureDetector(
        onTap: disabled
            ? null
            : () {
                setState(() => _single = d);
                widget.onTap(d);
              },
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEdge ? AppColors.primary : (inRange ? p.primarySoft : null),
            shape: BoxShape.circle,
          ),
          child: Text('$day',
              style: tx(context, 13,
                  weight: isEdge ? FontWeight.w800 : FontWeight.w500,
                  color: isEdge ? Colors.white : (disabled ? p.textMuted.withValues(alpha: 0.5) : p.text))),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Text('${Fmt.monthFull(_month.month)} ${_month.year}', style: tx(context, 13, weight: FontWeight.w700)),
        Icon(Icons.arrow_drop_down, color: p.textSecondary),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ]),
      Row(children: [
        for (var w = 1; w <= 7; w++)
          Expanded(child: Center(child: Text(Fmt.weekday(w), style: tx(context, 11.5, weight: FontWeight.w700, color: p.textSecondary)))),
      ]),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.15,
        children: [
          for (var i = 0; i < offset; i++) const SizedBox(),
          for (var d = 1; d <= daysInMonth; d++) cell(d),
        ],
      ),
    ]);
  }
}

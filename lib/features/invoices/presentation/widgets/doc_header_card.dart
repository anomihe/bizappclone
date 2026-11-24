import 'package:flutter/material.dart';
import '../../../../core/data/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Green header card on invoice / quotation / credit-note / refund screens:
/// a label + name strip on top and a white panel with the amount.
class DocHeaderCard extends StatelessWidget {
  final String label;
  final String name;
  final num amount;
  final String? amountCaption;
  final StatusStyle? status;
  final String? subline;
  final Color? sublineColor;
  final List<(String, num, Color?)> figures;
  final String? badge;
  final List<Widget> extra;

  const DocHeaderCard({
    super.key,
    required this.label,
    required this.name,
    required this.amount,
    this.amountCaption,
    this.status,
    this.subline,
    this.sublineColor,
    this.figures = const [],
    this.badge,
    this.extra = const [],
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: tx(context, 10.5, color: Colors.white70)),
                Text(name, style: tx(context, 14, weight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.link, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(badge!, style: tx(context, 10.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
          ]),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(11)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (amountCaption != null) Text(amountCaption!, style: tx(context, 11.5, color: p.textSecondary)),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: MoneyText(amount, size: 24)),
              if (status != null) StatusPill(status!),
            ]),
            if (subline != null) ...[
              const SizedBox(height: 2),
              Text(subline!, style: tx(context, 11.5, weight: FontWeight.w600, color: sublineColor ?? p.textMuted)),
            ],
            if (figures.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                for (final f in figures)
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.$1, style: tx(context, 11, color: p.textMuted)),
                      MoneyText(f.$2, size: 13.5, color: f.$3),
                    ]),
                  ),
              ]),
            ],
            ...extra,
          ]),
        ),
      ]),
    );
  }
}

/// Items list used under "ITEMS" on detail screens.
class ItemsList extends StatelessWidget {
  final List<LineItem> items;
  const ItemsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(children: [
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
            MoneyText(it.total, size: 13),
          ]),
        ),
    ]);
  }
}

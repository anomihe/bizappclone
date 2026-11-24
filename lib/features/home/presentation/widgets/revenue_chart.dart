import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Bar chart with green→gold gradient bars, as in "Revenue Trend".
class RevenueChart extends StatelessWidget {
  final List<double> values;
  final List<DateTime> days;
  const RevenueChart({super.key, required this.values, required this.days});

  static String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}m';
    if (v >= 1000) return '${(v / 1000).round()}k';
    return v.round().toString();
  }

  /// Round the axis max up to a friendly number.
  static double _niceMax(double v) {
    if (v <= 0) return 150000;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final n = (v / mag).ceil();
    return (n <= 2 ? 2 : (n <= 5 ? 5 : 10)) * mag;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final maxV = _niceMax(values.fold(0.0, math.max));
    final ticks = [maxV, maxV * 2 / 3, maxV / 3, 0.0];
    final labelEvery = values.length <= 7 ? 1 : (values.length / 6).ceil();

    return SizedBox(
      height: 170,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Y axis
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (final t in ticks) Text(_short(t), style: tx(context, 9.5, color: p.textMuted))],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(children: [
            Expanded(
              child: Stack(children: [
                // Grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [for (var i = 0; i < 4; i++) Container(height: 1, color: p.border.withValues(alpha: 0.6))],
                ),
                // Fill the whole plot area so bar heights are measured from the 0 line.
                Positioned.fill(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Tooltip(
                        message: '${Fmt.date(days[i])}\n${Fmt.money(values[i])}',
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: values.length > 10 ? 1 : 5),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: values[i] / maxV),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, f, _) => FractionallySizedBox(
                              heightFactor: f.clamp(0.0, 1.0) == 0 ? 0.01 : f.clamp(0.0, 1.0),
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [AppColors.accent, AppColors.primaryLight],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ])),
              ]),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 14,
              child: Row(children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: i % labelEvery == 0
                        ? Text(
                            values.length <= 7 ? Fmt.weekday(days[i].weekday) : '${days[i].day}',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: tx(context, 9.5, color: p.textMuted),
                          )
                        : const SizedBox(),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

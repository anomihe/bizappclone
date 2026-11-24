import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';

const refundReasons = ['Customer Returned Item', 'Paid Twice', 'Wrong Amount', 'Others'];

/// Refundable balance card + amount + reason, shared by
/// "Issue Credit Note" and "Request a Refund".
class RefundForm extends StatelessWidget {
  final double refundable;
  final double? creditIssued;
  final TextEditingController amount;
  final TextEditingController reason;
  final VoidCallback onChanged;

  const RefundForm({super.key, required this.refundable, this.creditIssued, required this.amount, required this.reason, required this.onChanged});

  static String? error(TextEditingController amount, double refundable) {
    final v = double.tryParse(amount.text) ?? 0;
    if (amount.text.isEmpty) return null;
    if (v <= 0) return 'Enter an amount';
    if (v > refundable) return 'You can refund at most ${Fmt.money(refundable)}';
    return null;
  }

  static bool valid(TextEditingController amount, TextEditingController reason, double refundable) {
    final v = double.tryParse(amount.text) ?? 0;
    return v > 0 && v <= refundable && reason.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Refundable Balance', style: tx(context, 11.5, color: p.textSecondary)),
          MoneyText(refundable, size: 22),
          if (creditIssued != null && creditIssued! > 0)
            Text('Credit Notes Issued: ${Fmt.money(creditIssued!)}', style: tx(context, 11.5, color: p.textSecondary)),
        ]),
      ),
      const SizedBox(height: 18),
      CustomTextField(
        label: 'Amount to Refund (₦)',
        hint: '0',
        prefixText: '₦ ',
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        errorText: error(amount, refundable),
        onChanged: (_) => onChanged(),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: SelectChip(
          label: 'Refund Full Amount',
          selected: amount.text == refundable.toStringAsFixed(0),
          onTap: () {
            amount.text = refundable.toStringAsFixed(0);
            onChanged();
          },
        ),
      ),
      const SizedBox(height: 14),
      CustomTextField(label: 'Reason', hint: 'e.g Returned order', controller: reason, onChanged: (_) => onChanged()),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final r in refundReasons)
          SelectChip(
            label: r,
            selected: reason.text == r,
            onTap: () {
              reason.text = r == 'Others' ? '' : r;
              onChanged();
            },
          ),
      ]),
      const SizedBox(height: 24),
      Text(
        'An admin approves the request first. The refund status changes to Refunded after Billway confirms.',
        textAlign: TextAlign.center,
        style: tx(context, 11, color: p.textMuted, height: 1.4),
      ),
    ]);
  }
}

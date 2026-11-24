import 'package:flutter/material.dart';
import '../theme/palette.dart';
import 'ui_kit.dart';

/// Dropdown-looking field that opens a bottom sheet of options.
class SelectField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const SelectField({super.key, required this.label, required this.hint, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
      const SizedBox(height: 6),
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final picked = await showBpSheet<String>(
            context,
            title: label,
            builder: (ctx) => ListView(
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(o, style: tx(ctx, 14, weight: FontWeight.w600)),
                    trailing: o == value ? Icon(Icons.check_circle, color: context.p.brand, size: 20) : null,
                    onTap: () => Navigator.pop(ctx, o),
                  ),
              ],
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border, width: 1.2)),
          child: Row(children: [
            Expanded(child: Text(value ?? hint, style: tx(context, 14, color: value == null ? p.textMuted : p.text))),
            Icon(Icons.keyboard_arrow_down, color: p.textSecondary),
          ]),
        ),
      ),
    ]);
  }
}

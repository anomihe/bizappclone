import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import 'ui_kit.dart';

class CountryInfo {
  final String name;
  final String flag;
  final String dialCode;
  final String currency;
  const CountryInfo({required this.name, required this.flag, required this.dialCode, required this.currency});

  static const all = [
    CountryInfo(name: 'Nigeria', flag: '🇳🇬', dialCode: '+234', currency: 'NGN'),
    CountryInfo(name: 'Ghana', flag: '🇬🇭', dialCode: '+233', currency: 'GHS'),
    CountryInfo(name: 'Kenya', flag: '🇰🇪', dialCode: '+254', currency: 'KES'),
    CountryInfo(name: 'South Africa', flag: '🇿🇦', dialCode: '+27', currency: 'ZAR'),
    CountryInfo(name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', currency: 'GBP'),
    CountryInfo(name: 'United States', flag: '🇺🇸', dialCode: '+1', currency: 'USD'),
    CountryInfo(name: 'Portugal', flag: '🇵🇹', dialCode: '+351', currency: 'EUR'),
    CountryInfo(name: 'Paraguay', flag: '🇵🇾', dialCode: '+595', currency: 'PYG'),
    CountryInfo(name: 'Qatar', flag: '🇶🇦', dialCode: '+974', currency: 'QAR'),
    CountryInfo(name: 'Anguilla', flag: '🇦🇮', dialCode: '+1264', currency: 'XCD'),
  ];
}

/// "Select Country" sheet with search.
Future<CountryInfo?> showCountrySheet(BuildContext context) {
  return showBpSheet<CountryInfo>(context, title: 'Select Country', builder: (ctx) => const _CountryList());
}

class _CountryList extends StatefulWidget {
  const _CountryList();
  @override
  State<_CountryList> createState() => _CountryListState();
}

class _CountryListState extends State<_CountryList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final list = CountryInfo.all
        .where((c) => c.name.toLowerCase().contains(_q.toLowerCase()) || c.dialCode.contains(_q))
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(children: [
        SearchField(hint: 'Search', onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                title: Text(c.name, style: tx(context, 14, weight: FontWeight.w600)),
                subtitle: Text(c.dialCode, style: tx(context, 12, color: p.textMuted)),
                onTap: () => Navigator.pop(context, c),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Phone input with the flag / dial-code button on the left.
class PhoneField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final CountryInfo country;
  final ValueChanged<CountryInfo> onCountryChanged;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const PhoneField({
    super.key,
    this.label = 'Phone Number',
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final hasError = errorText != null;
    OutlineInputBorder b(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: 1.2));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        onChanged: onChanged,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(14)],
        style: tx(context, 14),
        decoration: InputDecoration(
          hintText: '8035550142',
          hintStyle: tx(context, 13.5, color: p.textMuted),
          isDense: true,
          filled: true,
          fillColor: p.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          enabledBorder: b(hasError ? AppColors.error : p.border),
          focusedBorder: b(hasError ? AppColors.error : p.brand),
          prefixIcon: InkWell(
            onTap: () async {
              final c = await showCountrySheet(context);
              if (c != null) onCountryChanged(c);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(country.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(country.dialCode, style: tx(context, 13.5, weight: FontWeight.w600)),
                Icon(Icons.arrow_drop_down, color: p.textSecondary),
                Container(width: 1, height: 22, color: p.border),
              ]),
            ),
          ),
        ),
      ),
      if (hasError) ...[
        const SizedBox(height: 6),
        Text(errorText!, style: tx(context, 11.5, color: AppColors.error)),
      ],
    ]);
  }
}

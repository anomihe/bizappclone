import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class CountryInfo {
  final String name;
  final String flag;
  final String dialCode;
  final String currency;

  const CountryInfo({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.currency,
  });
}

class CountryPickerSheet extends StatefulWidget {
  final Function(CountryInfo) onSelect;

  const CountryPickerSheet({super.key, required this.onSelect});

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final List<CountryInfo> _allCountries = const [
    CountryInfo(name: 'Nigeria', flag: '🇳🇬', dialCode: '+234', currency: 'NGN'),
    CountryInfo(name: 'United States', flag: '🇺🇸', dialCode: '+1', currency: 'USD'),
    CountryInfo(name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', currency: 'GBP'),
    CountryInfo(name: 'Ghana', flag: '🇬🇭', dialCode: '+233', currency: 'GHS'),
    CountryInfo(name: 'Kenya', flag: '🇰🇪', dialCode: '+254', currency: 'KES'),
    CountryInfo(name: 'South Africa', flag: '🇿🇦', dialCode: '+27', currency: 'ZAR'),
    CountryInfo(name: 'Canada', flag: '🇨🇦', dialCode: '+1', currency: 'CAD'),
    CountryInfo(name: 'European Union', flag: '🇪🇺', dialCode: '+49', currency: 'EUR'),
  ];

  late List<CountryInfo> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _filteredCountries = _allCountries;
  }

  void _onSearch(String query) {
    setState(() {
      _filteredCountries = _allCountries
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.dialCode.contains(query) ||
              c.currency.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            'Select Country / Currency',
            style: GoogleFonts.figtree(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Search Input
          TextField(
            onChanged: _onSearch,
            style: GoogleFonts.figtree(
              fontSize: 14,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search country or currency...',
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Country List
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCountries.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
              ),
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Text(country.flag, style: const TextStyle(fontSize: 26)),
                  title: Text(
                    country.name,
                    style: GoogleFonts.figtree(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceLight : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${country.dialCode} • ${country.currency}',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

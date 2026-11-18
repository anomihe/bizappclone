import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'registration_success_screen.dart';

class WorkspaceSetupScreen extends StatefulWidget {
  final String defaultCurrency;

  const WorkspaceSetupScreen({super.key, this.defaultCurrency = 'NGN'});

  @override
  State<WorkspaceSetupScreen> createState() => _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends State<WorkspaceSetupScreen> {
  final _businessNameController = TextEditingController(text: 'Acme Solutions');
  final _slugController = TextEditingController(text: 'acme-solutions');

  String _selectedIndustry = 'Technology & Software';
  late String _selectedCurrency;
  String _selectedTeamSize = '1–5 (Starter)';
  bool _isLoading = false;

  final List<String> _industries = const [
    'Technology & Software',
    'Retail & E-Commerce',
    'Professional & Legal Services',
    'Creative, Marketing & Media',
    'Real Estate & Construction',
    'Healthcare & Pharmaceuticals',
    'Education & Training',
    'Logistics & Transportation',
  ];

  final List<String> _currencies = const ['NGN', 'USD', 'GBP', 'EUR', 'GHS', 'KES'];
  final List<String> _teamSizes = const ['1–5 (Starter)', '6–20', '21–50', '50+'];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.defaultCurrency;
  }

  void _onNameChanged(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    setState(() {
      _slugController.text = slug;
    });
  }

  void _onComplete() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationSuccessScreen(
            businessName: _businessNameController.text.trim(),
            slug: _slugController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: BizpaddiLogo(size: 26),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              Text(
                'Tell us about your business',
                style: GoogleFonts.figtree(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Set up your organization workspace and storefront URL.',
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // Business Name
              CustomTextField(
                label: 'Business / Company Name',
                hint: 'e.g. Acme Solutions Ltd',
                controller: _businessNameController,
                onChanged: _onNameChanged,
                prefixIcon: Icon(
                  Icons.business_outlined,
                  size: 20,
                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),

              const SizedBox(height: 18),

              // Storefront URL Preview
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digital Storefront URL Slug',
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.border : AppColors.lightBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'bizpaddi.com/store/',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _slugController.text,
                            style: GoogleFonts.figtree(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Industry Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Industry Sector',
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.border : AppColors.lightBorder,
                        width: 1.2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedIndustry,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.surface : Colors.white,
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        ),
                        items: _industries.map((ind) {
                          return DropdownMenuItem<String>(
                            value: ind,
                            child: Text(ind),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedIndustry = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Default Currency Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Currency',
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _currencies.map((curr) {
                      final isSelected = curr == _selectedCurrency;
                      return ChoiceChip(
                        label: Text(curr),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark ? AppColors.surface : Colors.white,
                        labelStyle: GoogleFonts.figtree(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.border : AppColors.lightBorder),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCurrency = curr;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Team Size Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Size',
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _teamSizes.map((size) {
                      final isSelected = size == _selectedTeamSize;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark ? AppColors.surface : Colors.white,
                        labelStyle: GoogleFonts.figtree(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.border : AppColors.lightBorder),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTeamSize = size;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Submit Button
              CustomButton(
                text: 'Complete Setup',
                isLoading: _isLoading,
                onPressed: _onComplete,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/data/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';
import 'registration_success_screen.dart';

/// "Choose how to start" — only the 7-day trial exists in the design.
class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return AuthScaffold(
      showClose: false,
      title: 'Choose how to start',
      subtitle: 'No card needed for your trial.',
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Plans from ₦8,000.00 a month.', style: tx(context, 12, color: p.textSecondary)),
        Text('See all plans after your trial starts.', style: tx(context, 12, color: p.textSecondary)),
        const SizedBox(height: 12),
        CustomButton(text: 'Start My Free Trial', variant: ButtonVariant.accent, isLoading: _loading, onPressed: _start),
      ]),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text('7-day free trial', style: tx(context, 15, weight: FontWeight.w800))),
              const SizedBox(width: 8),
              const StatusPill(StatusStyle.current),
            ]),
            const SizedBox(height: 6),
            Text('No payment needed. Try invoices, pay links and receipts with your own customers.',
                style: tx(context, 12.5, color: p.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            for (final f in const [
              'Invoices, quotations and quick payment links',
              'Push alert the moment a customer pays',
              'Invite your staff with their own roles',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.check, size: 16, color: context.p.brand),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: tx(context, 12.5, weight: FontWeight.w600))),
                ]),
              ),
          ]),
        ),
      ],
    );
  }
}

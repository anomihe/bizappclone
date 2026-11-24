import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';

/// "You're all set".
class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ContentWidth(maxWidth: Breakpoints.form, child: FillScroll(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(children: [
            const Spacer(flex: 3),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2.5)),
              child: Icon(Icons.done_all, color: context.p.brand, size: 30),
            ),
            const SizedBox(height: 18),
            Text("You're all set", style: tx(context, 20, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Your 7-day free trial has started. Send your first invoice in under 10 minutes.',
                textAlign: TextAlign.center, style: tx(context, 13, color: p.textSecondary, height: 1.45)),
            const Spacer(flex: 4),
            CustomButton(
              text: 'Create Your First Invoice',
              variant: ButtonVariant.accent,
              onPressed: () => MainNavigationScreen.go(context, openNewInvoice: true),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => MainNavigationScreen.go(context),
              child: Text('Go to dashboard', style: tx(context, 13, weight: FontWeight.w700, color: context.p.brand)),
            ),
          ]),
        )),
      ),
    );
  }
}

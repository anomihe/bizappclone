import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'choose_plan_screen.dart';

/// "Log in faster" — offer fingerprint / Face ID after sign-up.
/// Real biometric enrolment needs the `local_auth` plugin; this records the choice.
class BiometricsScreen extends StatelessWidget {
  const BiometricsScreen({super.key});

  void _next(BuildContext context, bool enable) {
    BizStore.instance.setBiometrics(enable);
    if (enable) showToast(context, 'Biometric login enabled');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChoosePlanScreen()));
  }

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
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.fingerprint, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            Text('Log in faster', style: tx(context, 20, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Use your fingerprint or Face ID instead of typing your password. You can always use your password.',
              textAlign: TextAlign.center,
              style: tx(context, 13, color: p.textSecondary, height: 1.45),
            ),
            const Spacer(flex: 4),
            CustomButton(text: 'Enable Biometrics/Face ID', onPressed: () => _next(context, true)),
            const SizedBox(height: 10),
            CustomButton(text: 'Not Now', variant: ButtonVariant.soft, onPressed: () => _next(context, false)),
          ]),
        )),
      ),
    );
  }
}

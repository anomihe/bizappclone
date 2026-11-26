import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/utils/biometrics.dart';
import 'registration_success_screen.dart';

/// "Log in faster" — offer fingerprint / Face ID after sign-up.
/// Uses the real OS prompt (local_auth).
class BiometricsScreen extends StatelessWidget {
  const BiometricsScreen({super.key});

  /// Real OS prompt, saved on this device. New businesses are pay-as-you-go
  /// (no trial to choose), so go straight to the welcome screen.
  Future<void> _next(BuildContext context, bool enable) async {
    final on = enable && await Biometrics.setEnabled(true);
    BizStore.instance.setBiometrics(on);
    if (!context.mounted) return;
    if (enable) showToast(context, on ? 'Biometric login enabled' : 'Fingerprint / Face ID wasn’t confirmed. You can turn it on later in Security.');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()));
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

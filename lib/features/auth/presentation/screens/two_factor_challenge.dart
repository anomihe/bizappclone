import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'otp_verification_screen.dart';

/// Second login step for accounts with two-factor login: the 6-digit code
/// from the authenticator app, or a one-time recovery code.
Future<void> openTwoFactorChallenge(BuildContext context, String challengeToken, {required void Function(BuildContext) onSignedIn}) {
  Future<String?> submit(String code) async {
    try {
      await LiveSession.instance.completeTwoFactor(challengeToken, code);
      return null;
    } on ApiException catch (e) {
      return e.errorFor('code') ?? e.message;
    }
  }

  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OtpVerificationScreen(
        title: 'Two-step verification',
        subtitle: 'Open your authenticator app and enter the 6-digit code for Bizpaddi.',
        canResend: false,
        onSubmit: submit,
        onVerified: onSignedIn,
        extra: Builder(
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () => _recoverySheet(ctx, submit, onSignedIn),
              child: Text('Use a recovery code instead', style: tx(ctx, 12.5, weight: FontWeight.w700, color: ctx.p.brand)),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _recoverySheet(BuildContext context, Future<String?> Function(String) submit, void Function(BuildContext) onSignedIn) {
  final code = TextEditingController();
  String? error;
  var busy = false;
  return showBpSheet(
    context,
    showHandle: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Recovery code', style: tx(sheet, 16, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Enter one of the recovery codes you saved when you turned on two-step verification. Each code works once.',
            style: tx(sheet, 12.5, color: sheet.p.textSecondary, height: 1.4)),
        const SizedBox(height: 14),
        CustomTextField(label: 'Recovery code', hint: 'e.g. ABCD-1234', controller: code, errorText: error, onChanged: (_) => setSheet(() => error = null)),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Continue',
          isLoading: busy,
          onPressed: () async {
            if (code.text.trim().isEmpty) return;
            setSheet(() => busy = true);
            final e = await submit(code.text);
            if (!sheet.mounted) return;
            setSheet(() {
              busy = false;
              error = e;
            });
            if (e == null) {
              Navigator.pop(sheet);
              if (context.mounted) onSignedIn(context);
            }
          },
        ),
      ]),
    ),
  );
}

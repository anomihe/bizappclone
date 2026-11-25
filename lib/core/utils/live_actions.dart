import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/billing/billing_screen.dart';
import '../api/api_client.dart';
import '../theme/palette.dart';
import '../widgets/custom_button.dart';
import '../widgets/ui_kit.dart';

/// Runs a backend action from a screen: shows [done] on success, the
/// server's message on failure, and offers Wallet & Billing when the action
/// needs a top-up or a plan (HTTP 402). Returns true on success.
Future<bool> runLiveAction(BuildContext context, Future<void> Function() action, {String? done}) async {
  try {
    await action();
    if (done != null && context.mounted) showToast(context, done);
    return true;
  } on ApiException catch (e) {
    if (!context.mounted) return false;
    if (e.needsBilling) {
      await showBillingRequiredSheet(context, e.message);
    } else {
      showToast(context, e.message);
    }
    return false;
  }
}

Future<void> showBillingRequiredSheet(BuildContext context, String message) => showBpSheet(
      context,
      showHandle: true,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.account_balance_wallet_outlined, size: 40, color: ctx.p.brand),
        const SizedBox(height: 12),
        Text('Top up to continue', textAlign: TextAlign.center, style: tx(ctx, 16, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: tx(ctx, 12.5, color: ctx.p.textSecondary, height: 1.4)),
        const SizedBox(height: 18),
        CustomButton(
          text: 'Open Wallet & Billing',
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()));
          },
        ),
      ]),
    );

/// Downloads a PDF with [load] and opens the share sheet (save, WhatsApp, email…).
Future<void> sharePdf(BuildContext context, Future<List<int>> Function() load, String filename) async {
  showToast(context, 'Preparing PDF…');
  List<int> bytes;
  try {
    bytes = await load();
  } on ApiException catch (e) {
    if (context.mounted) showToast(context, e.message);
    return;
  }
  if (!context.mounted) return;
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: 'application/pdf', name: filename)],
    fileNameOverrides: [filename],
    sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}

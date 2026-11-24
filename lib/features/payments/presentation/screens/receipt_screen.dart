import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../invoices/presentation/widgets/invoice_sheets.dart';

class ReceiptScreen extends StatelessWidget {
  final Payment payment;
  const ReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final store = BizStore.instance;
    final invoice = store.invoiceById(payment.invoiceId);
    final business = store.account.businessName;

    return InnerScaffold(
      title: 'Receipt',
      actions: const [CircleIconButton(icon: Icons.headset_mic_outlined, tooltip: 'Support')],
      bottom: CustomButton(
        text: 'Share Receipt',
        variant: ButtonVariant.outline,
        icon: const Icon(Icons.ios_share),
        onPressed: () => showShareSheet(
          context,
          title: 'Share Receipt',
          heading: '$business · ${payment.receiptNo}',
          link: 'bizpaddi.com/r/${payment.receiptNo.toLowerCase()}',
          amount: payment.amount,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const BizpaddiLogo(size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(business, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 14, weight: FontWeight.w800, color: Colors.white)),
                Text('Payment Receipt', style: tx(context, 11.5, color: Colors.white70)),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Column(children: [
              const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 34),
              const SizedBox(height: 8),
              Text('Amount paid', style: tx(context, 12, color: p.textSecondary)),
              MoneyText(payment.amount, size: 26),
              Text(Fmt.dateTime(payment.date), style: tx(context, 11.5, color: p.textMuted)),
              const SizedBox(height: 10),
              InfoRow(
                label: 'Receipt No.',
                valueWidget: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: payment.receiptNo));
                    showToast(context, 'Receipt number copied');
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(payment.receiptNo, overflow: TextOverflow.ellipsis, style: tx(context, 13, weight: FontWeight.w700))),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: context.p.brand),
                  ]),
                ),
              ),
              InfoRow(label: 'Received from', value: payment.customerName),
              InfoRow(label: 'Invoice', value: payment.invoiceNumber),
              InfoRow(label: 'Method', value: payment.method),
              if (invoice != null) ...[
                InfoRow(label: 'Invoice total', value: Fmt.money(invoice.total)),
                InfoRow(label: 'Balance still owed', value: Fmt.money(invoice.balance)),
              ],
              const SizedBox(height: 14),
              Text('Thank you for your business.', style: tx(context, 11.5, color: p.textSecondary)),
              Text('Powered by Bizpaddi', style: tx(context, 11, color: p.textMuted)),
              const SizedBox(height: 14),
            ]),
          ),
          SizedBox(height: 14, width: double.infinity, child: CustomPaint(painter: _ZigZagPainter(color: p.cardAlt))),
        ]),
      ),
    );
  }
}

/// Torn-paper edge at the bottom of the receipt.
class _ZigZagPainter extends CustomPainter {
  final Color color;
  _ZigZagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, 0);
    const w = 10.0;
    for (double x = 0; x < size.width; x += w) {
      path.lineTo(x + w / 2, size.height);
      path.lineTo(x + w, 0);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ZigZagPainter old) => old.color != color;
}

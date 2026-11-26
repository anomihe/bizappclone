import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../invoices/presentation/screens/invoice_details_screen.dart';
import '../../../orders/presentation/screens/order_details_screen.dart';
import '../../../support/presentation/screens/help_support_screen.dart';
import 'receipt_screen.dart';

/// Payment details for invoice, payment-link and storefront-order payments.
class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;
  const PaymentDetailsScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final store = BizStore.instance;
    final pay = payment;
    final invoice = pay.isOrder ? null : store.invoiceById(pay.invoiceId);
    final order = store.orderById(pay.orderId);
    final canReceipt = pay.status == PaymentStatus.paid || pay.status == PaymentStatus.partlyPaid || pay.status == PaymentStatus.refunded;

    void receipt() => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: pay)));

    final Widget? bottom = canReceipt
        ? CustomButton(text: 'View Receipt', variant: ButtonVariant.accent, icon: const Icon(Icons.receipt_outlined), onPressed: receipt)
        : null;

    return InnerScaffold(
      title: 'Payments Details',
      subtitle: '${pay.isOrder ? 'Placed by' : 'Received from'} ${pay.customerName}',
      titleTrailing: StatusPill(StatusStyle.payment(pay.status)),
      actions: [
        CircleIconButton(
          icon: Icons.headset_mic_outlined,
          tooltip: 'Support',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
        ),
      ],
      bottom: bottom,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BpCard(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(children: [
            Text('Your Customer Paid', style: tx(context, 12, color: p.textSecondary)),
            const SizedBox(height: 4),
            MoneyText(pay.amount, size: 28, color: p.brand),
            const SizedBox(height: 4),
            Text(Fmt.dateTime(pay.date), style: tx(context, 11.5, color: p.textMuted)),
          ]),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Details'),
        BpCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            if (pay.isOrder)
              InfoRow(
                label: 'Order No.',
                value: 'Order ${pay.orderNumber}',
                valueColor: p.brand,
                onTap: order == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order))),
              )
            else
              InfoRow(
                label: invoice?.kind == DocKind.paymentLink ? 'Payment link' : 'Invoice',
                value: invoice?.kind == DocKind.paymentLink ? invoice!.linkNumber : pay.invoiceNumber,
                valueColor: p.brand,
                onTap: invoice == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: invoice))),
              ),
            InfoRow(label: 'Customer', value: pay.customerName),
            InfoRow(label: 'Method', value: pay.method),
            InfoRow(label: 'Provider', value: pay.provider),
            InfoRow(label: 'Provider Charge', value: Fmt.money(pay.providerCharge)),
            InfoRow(label: 'Bizpaddi Service Charge', value: Fmt.money(pay.serviceCharge)),
            InfoRow(
              label: 'Reference',
              valueWidget: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: pay.reference));
                  showToast(context, 'Reference copied');
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Text(pay.reference, overflow: TextOverflow.ellipsis, style: tx(context, 13, weight: FontWeight.w700))),
                  const SizedBox(width: 4),
                  Icon(Icons.copy, size: 14, color: p.brand),
                ]),
              ),
            ),
            InfoRow(label: 'You receive', value: Fmt.money(pay.youReceive), bold: true),
            InfoRow(label: 'Paid by customer', valueWidget: StatusPill(pay.paidByCustomer ? StatusStyle.paid : StatusStyle.notYet)),
            InfoRow(label: 'Settled to your account', valueWidget: StatusPill(pay.settled ? StatusStyle.settled : StatusStyle.waiting)),
          ]),
        ),
        if (pay.status == PaymentStatus.failed) ...[
          const SizedBox(height: 14),
          const InfoBanner('This payment did not go through. No money left your customer’s account.'),
        ],
      ]),
    );
  }
}

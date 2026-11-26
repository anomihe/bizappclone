import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/ui_kit.dart';

const _faqs = [
  ('How to get paid faster?', 'Share the pay link on WhatsApp as soon as you issue an invoice. Bizpaddi confirms the transfer, usually within a minute, and you get a push alert.'),
  ('Sending your first invoice?', 'Tap Create New → Invoice, choose a customer, add what they bought and tap Preview. Issue it and share the pay link.'),
  ('Customer paid you in cash?', 'Open the invoice and tap Mark as paid. The full balance is recorded as received.'),
  ('When do I get my money?', 'Paid by customer is not the same as settled. Settlement to your bank takes 1–2 business days.'),
];

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _open = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final name = BizStore.instance.account.ownerFirstName;
    return InnerScaffold(
      title: '',
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Hey $name', style: tx(context, 13, color: p.textSecondary)),
        Text('How can we help you?', style: tx(context, 20, weight: FontWeight.w800)),
        const SizedBox(height: 16),
        // There's no support-chat API for business owners yet.
        const InfoBanner('For anything the answers below don’t cover, contact Bizpaddi support from your dashboard at app.bizpaddi.com.',
            icon: Icons.support_agent),
        const SizedBox(height: 20),
        Text('Frequently Asked Questions', style: tx(context, 13.5, weight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (var i = 0; i < _faqs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BpCard(
              onTap: () => setState(() => _open = _open == i ? null : i),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_faqs[i].$1, style: tx(context, 13, weight: FontWeight.w700, color: p.brand))),
                  AnimatedRotation(
                    turns: _open == i ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down, color: p.textSecondary),
                  ),
                ]),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _open == i ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_faqs[i].$2, style: tx(context, 12, color: p.textSecondary, height: 1.45)),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

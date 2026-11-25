import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/ui_kit.dart';

const _faqs = [
  ('How to get paid faster?', 'Share the pay link on WhatsApp as soon as you issue an invoice. Bizpaddi confirms the transfer, usually within a minute, and you get a push alert.'),
  ('Sending your first invoice?', 'Tap Create New → Invoice, choose a customer, add what they bought and tap Preview. Issue it and share the pay link.'),
  ('How refunds work?', 'Open the paid invoice and choose Issue credit note → Request a Refund. An admin approves it, then Billway sends the money back to your customer.'),
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
        // There's no support-chat API yet; don't show a chat that goes nowhere.
        if (LiveSession.enabled)
          const InfoBanner('For anything the answers below don’t cover, contact Bizpaddi support from your dashboard at app.bizpaddi.com.',
              icon: Icons.support_agent)
        else
        BpCard(
          color: p.primarySoft,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
          child: Row(children: [
            LeadingIcon(Icons.support_agent, color: p.brand, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chat with Support', style: tx(context, 13.5, weight: FontWeight.w700)),
                Text('Replies in about 5 minutes', style: tx(context, 11.5, color: p.textMuted)),
              ]),
            ),
            Icon(Icons.chevron_right, color: p.textMuted),
          ]),
        ),
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

class _Message {
  final String text;
  final bool fromMe;
  final DateTime time;
  _Message(this.text, this.fromMe) : time = DateTime.now();
}

/// "Customer Support" chat. Messages stay on the device until a support
/// backend (e.g. Intercom / Freshchat) is connected.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<_Message> _messages = [_Message('Hi ${BizStore.instance.account.ownerFirstName}! What do you need?', false)];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text, true));
      _input.clear();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _messages.add(_Message('Thanks — an agent will reply here shortly.', false)));
      _jump();
    });
    _jump();
  }

  void _jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InnerScaffold(
      title: 'Customer Support',
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      bottom: Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(hintText: 'How can we help you?', isDense: true, fillColor: p.cardAlt),
          ),
        ),
        const SizedBox(width: 8),
        CircleIconButton(icon: Icons.send, background: p.primarySoft, color: p.brand, size: 44, tooltip: 'Send', onTap: _send),
      ]),
      body: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final m = _messages[i];
          return Align(
            alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: m.fromMe ? p.primarySoft : p.cardAlt,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(m.fromMe ? 12 : 2),
                  bottomRight: Radius.circular(m.fromMe ? 2 : 12),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(m.text, style: tx(context, 13, height: 1.4)),
                const SizedBox(height: 2),
                Text(Fmt.time(m.time), style: tx(context, 10, color: p.textMuted)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

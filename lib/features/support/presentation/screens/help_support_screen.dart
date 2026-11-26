import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/utils/pick_file.dart';
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
        // Owners chat with Bizpaddi support; staff go through their business owner.
        if (LiveSession.instance.role == AccountRole.owner)
          BpCard(
            color: p.primarySoft,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
            child: Row(children: [
              LeadingIcon(Icons.support_agent, color: p.brand, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Chat with Support', style: tx(context, 13.5, weight: FontWeight.w700)),
                  Text('The Bizpaddi team replies here', style: tx(context, 11.5, color: p.textMuted)),
                ]),
              ),
              Icon(Icons.chevron_right, color: p.textMuted),
            ]),
          )
        else
          const InfoBanner('For anything the answers below don’t cover, ask the business owner who invited you.', icon: Icons.support_agent),
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
  final String? attachmentUrl;
  final String? attachmentName;
  const _Message(this.text, this.fromMe, this.time, {this.attachmentUrl, this.attachmentName});

  factory _Message.fromJson(Map<String, dynamic> j) => _Message(
        '${j['message'] ?? ''}',
        j['sender_type'] != 'support',
        DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal() ?? DateTime.now(),
        attachmentUrl: j['attachment_url'] as String?,
        attachmentName: j['attachment_name'] as String?,
      );
}

/// Owner ↔ Bizpaddi support chat (`/admin/support/messages`). Bizpaddi staff
/// answer from the back office; new replies are picked up while it's open.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<_Message>? _messages;
  String? _error;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final list = await LiveSession.instance.supportMessages();
      if (!mounted) return;
      final before = _messages?.length ?? 0;
      setState(() {
        _messages = [for (final j in list) _Message.fromJson(j)];
        _error = null;
      });
      if (_messages!.length != before) _jump();
    } on ApiException catch (e) {
      if (mounted && !quiet) setState(() => _error = e.message);
    }
  }

  Future<void> _send({PickedFile? file}) async {
    final text = _input.text.trim();
    if (text.isEmpty && file == null) return;
    setState(() => _sending = true);
    final ok = await runLiveAction(context, () async {
      final j = await LiveSession.instance.sendSupportMessage(text, bytes: file?.bytes, filename: file?.name);
      _messages = [...?_messages, _Message.fromJson(j)];
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _input.clear();
    });
    if (ok) _jump();
  }

  Future<void> _attach() async {
    final f = await pickUploadFile(context, title: 'Attach', allowPdf: true);
    if (f != null && mounted) await _send(file: f);
  }

  void _jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final messages = _messages;
    Widget body;
    if (messages == null && _error != null) {
      body = Center(
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Couldn’t load the chat',
          message: _error!,
          action: TextButton(onPressed: _load, child: const Text('Try again')),
        ),
      );
    } else if (messages == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (messages.isEmpty) {
      body = const Center(
        child: EmptyState(icon: Icons.support_agent, title: 'How can we help?', message: 'Send a message and the Bizpaddi team will reply here.'),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final m = messages[i];
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
                  if (m.text.isNotEmpty) Text(m.text, style: tx(context, 13, height: 1.4)),
                  if (m.attachmentUrl != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.attach_file, size: 14, color: p.brand),
                      Flexible(child: Text(m.attachmentName ?? 'Attachment', overflow: TextOverflow.ellipsis, style: tx(context, 12, weight: FontWeight.w600, color: p.brand))),
                    ]),
                  const SizedBox(height: 2),
                  Text('${m.fromMe ? 'You' : 'Bizpaddi'} · ${Fmt.time(m.time)}', style: tx(context, 10, color: p.textMuted)),
                ]),
              ),
            );
          },
        ),
      );
    }

    return InnerScaffold(
      title: 'Customer Support',
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      bottom: Row(children: [
        CircleIconButton(icon: Icons.attach_file, size: 44, tooltip: 'Attach', onTap: _sending ? null : _attach),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _input,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(hintText: 'How can we help you?', isDense: true, fillColor: p.cardAlt),
          ),
        ),
        const SizedBox(width: 8),
        _sending
            ? const SizedBox(width: 44, height: 44, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
            : CircleIconButton(icon: Icons.send, background: p.primarySoft, color: p.brand, size: 44, tooltip: 'Send', onTap: _send),
      ]),
      body: body,
    );
  }
}

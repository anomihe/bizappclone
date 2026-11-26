import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/resources.dart';
import '../../core/data/biz_store.dart' show LiveLinks;
import '../../core/theme/palette.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/ui_kit.dart';
import '../more/presentation/screens/appearance_screen.dart';
import '../more/presentation/screens/settings_screen.dart';
import '../workspace/workspace_screens.dart' show ChangePasswordScreen;
import 'portal_kit.dart';
import 'portal_projects.dart';
import 'staff_app.dart' show PortalDocumentScreen;

/// Customer (client) app: their invoices and quotes, projects with the team
/// chat, support tickets and messages.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) => const PortalShell(tabs: [
        (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', page: CustomerHomeTab()),
        (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Invoices', page: CustomerInvoicesTab()),
        (icon: Icons.work_outline, selectedIcon: Icons.work, label: 'Projects', page: CustomerProjectsTab()),
        (icon: Icons.support_agent_outlined, selectedIcon: Icons.support_agent, label: 'Support', page: CustomerSupportTab()),
        (icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'More', page: CustomerMoreTab()),
      ]);
}

/// Unpaid = anything not paid / cancelled / draft.
bool _owing(Map<String, dynamic> i) => !const ['paid', 'cancelled', 'draft'].contains(pStr(i['status']));

/// The customer-portal pay page (the same link the invoice email has).
String? payUrl(Object id) => LiveLinks.host == null ? null : 'https://${LiveLinks.host}/dashboard/client/invoices/$id/pay';

// ===================================================================== home

class CustomerHomeTab extends StatelessWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalTabPage(
      title: 'Hi ${portalMe.firstName}',
      child: AsyncView<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>(
        load: () async => (await PortalData.invoices(), await PortalData.projects()),
        builder: (context, data, _) {
          final p = context.p;
          final (invoices, projects) = data;
          final owing = invoices.where(_owing).toList();
          final total = owing.fold<double>(0, (s, i) => s + pNum(i['total_amount']));
          final active = projects.where((x) => !const ['completed', 'cancelled'].contains(pStr(x['status']))).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              color: p.primarySoft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(owing.isEmpty ? 'You’re all paid up' : 'You owe', style: tx(context, 12.5, color: p.textSecondary)),
                const SizedBox(height: 4),
                MoneyText(total, size: 26),
                Text('${owing.length} unpaid invoice${owing.length == 1 ? '' : 's'}', style: tx(context, 11.5, color: p.textMuted)),
                if (owing.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CustomButton(text: 'See Invoices', variant: ButtonVariant.accent, onPressed: () => PortalShell.switchTab(context, 1)),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            statGrid([
              StatTile(label: 'Active projects', value: '${active.length}', icon: Icons.work_outline, onTap: () => PortalShell.switchTab(context, 2)),
              StatTile(label: 'Invoices', value: '${invoices.length}', icon: Icons.receipt_long_outlined, onTap: () => PortalShell.switchTab(context, 1)),
            ]),
            const SizedBox(height: 14),
            const SectionLabel('Unpaid invoices'),
            if (owing.isEmpty)
              const EmptyState(icon: Icons.check_circle_outline, title: 'Nothing to pay')
            else
              for (final i in owing.take(5)) _InvoiceTile(invoice: i),
            if (active.isNotEmpty) ...[
              const SizedBox(height: 14),
              const SectionLabel('Your projects'),
              for (final pr in active.take(3)) ProjectTile(project: pr, onTap: () => pOpen(context, PortalProjectScreen(projectId: pr['id'], name: pName(pr)))),
            ],
          ]);
        },
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final bool quote;
  const _InvoiceTile({required this.invoice, this.quote = false});

  @override
  Widget build(BuildContext context) {
    final due = pDate(invoice[quote ? 'valid_until' : 'due_date']);
    final late = !quote && due != null && due.isBefore(DateTime.now()) && _owing(invoice);
    return RecordTile(
      leading: LeadingIcon(quote ? Icons.request_quote_outlined : Icons.receipt_long_outlined),
      title: pStr(invoice[quote ? 'quote_number' : 'invoice_number']),
      subtitle: due == null ? pDay(invoice['issue_date']) : '${quote ? 'Valid until' : (late ? 'Overdue since' : 'Due')} ${Fmt.date(due)}',
      amount: pNum(invoice['total_amount']),
      status: genericStatus(late ? 'overdue' : pStr(invoice['status'])),
      onTap: () => pOpen(context, quote ? PortalDocumentScreen(id: invoice['id'], quote: true) : CustomerInvoiceScreen(id: invoice['id'])),
    );
  }
}

// ===================================================================== invoices & quotes

class CustomerInvoicesTab extends StatefulWidget {
  const CustomerInvoicesTab({super.key});

  @override
  State<CustomerInvoicesTab> createState() => _CustomerInvoicesTabState();
}

class _CustomerInvoicesTabState extends State<CustomerInvoicesTab> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final quotes = _tab == 1;
    return PortalTabPage(
      title: quotes ? 'Quotations' : 'Invoices',
      headerBottom: SegmentedPills(options: const ['Invoices', 'Quotations'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
      child: AsyncView<List<Map<String, dynamic>>>(
        key: ValueKey(_tab),
        load: quotes ? PortalData.quotes : PortalData.invoices,
        isEmpty: (d) => d.isEmpty,
        empty: EmptyState(icon: Icons.receipt_long_outlined, title: quotes ? 'No quotations yet' : 'No invoices yet', message: 'They show here when the business sends one.'),
        builder: (context, docs, _) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final d in docs) _InvoiceTile(invoice: d, quote: quotes),
        ]),
      ),
    );
  }
}

/// Invoice with "Pay now": payment happens on the customer-portal page (bank transfer to the invoice's account).
class CustomerInvoiceScreen extends StatelessWidget {
  final Object id;
  const CustomerInvoiceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return PortalDocumentScreen(
      id: id,
      actions: (context, d) {
        final url = payUrl(id);
        if (!_owing(d)) return [const InfoBanner('This invoice is paid. Thank you!', icon: Icons.check_circle_outline)];
        return [
          CustomButton(
            text: 'Pay Now',
            variant: ButtonVariant.accent,
            icon: const Icon(Icons.payments_outlined),
            onPressed: url == null ? null : () => openLink(context, url),
          ),
          const SizedBox(height: 8),
          if (url != null)
            CustomButton(
              text: 'Copy Pay Link',
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.link),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                showToast(context, 'Pay link copied');
              },
            ),
          const SizedBox(height: 8),
          Text('You’ll pay on a secure Bizpaddi page. Sign in there with the same email and password.',
              textAlign: TextAlign.center, style: tx(context, 11.5, color: context.p.textMuted)),
        ];
      },
    );
  }
}

// ===================================================================== projects

class CustomerProjectsTab extends StatelessWidget {
  const CustomerProjectsTab({super.key});

  @override
  Widget build(BuildContext context) => const PortalTabPage(title: 'Projects', child: PortalProjectsList());
}

// ===================================================================== support

class CustomerSupportTab extends StatefulWidget {
  const CustomerSupportTab({super.key});

  @override
  State<CustomerSupportTab> createState() => _CustomerSupportTabState();
}

class _CustomerSupportTabState extends State<CustomerSupportTab> {
  final _key = GlobalKey<AsyncViewState<List<Map<String, dynamic>>>>();

  @override
  Widget build(BuildContext context) {
    return PortalTabPage(
      title: 'Support',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        ActionTile(icon: Icons.forum_outlined, title: 'Messages', subtitle: 'Chat with the business', onTap: () => pOpen(context, const SupportChatsScreen())),
        ActionTile(
          icon: Icons.add_circle_outline,
          title: 'Open a support ticket',
          subtitle: 'For problems that need follow-up',
          onTap: () async {
            if (await pOpen2<bool>(context, const NewTicketScreen()) == true) _key.currentState?.reload();
          },
        ),
        const SizedBox(height: 8),
        const SectionLabel('Your tickets'),
        SizedBox(
          height: 420,
          child: AsyncView<List<Map<String, dynamic>>>(
            key: _key,
            load: PortalData.tickets,
            isEmpty: (d) => d.isEmpty,
            empty: const EmptyState(icon: Icons.confirmation_number_outlined, title: 'No tickets', message: 'Open one if something isn’t right.'),
            builder: (context, tickets, _) => ListView(children: [
              for (final t in tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BpCard(
                    onTap: () => pOpen(context, TicketScreen(id: t['id'], subject: pStr(t['subject']))),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pStr(t['subject']), style: tx(context, 13.5, weight: FontWeight.w700)),
                          Text('${pStr(t['ticket_id'])} · ${pDay(t['created_at'])}', style: tx(context, 11.5, color: context.p.textMuted)),
                        ]),
                      ),
                      StatusPill(genericStatus(pStr(t['status']))),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _priority = 'medium';
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _valid => _subject.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  Future<void> _send() async {
    setState(() => _busy = true);
    final ok = await portalAction(context, () => PortalData.openTicket(_subject.text.trim(), _message.text.trim(), _priority), done: 'Ticket opened. We’ll get back to you.');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'New Ticket',
      bottom: CustomButton(text: 'Open Ticket', isLoading: _busy, onPressed: _valid && !_busy ? _send : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Subject', hint: 'e.g. I paid but it still shows unpaid', controller: _subject, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(label: 'What happened?', hint: 'Give as much detail as you can', controller: _message, maxLines: 5, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        const SectionLabel('How urgent is it?'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in const ['low', 'medium', 'high', 'urgent']) SelectChip(label: pLabel(p), selected: _priority == p, onTap: () => setState(() => _priority = p)),
        ]),
      ]),
    );
  }
}

class TicketScreen extends StatelessWidget {
  final Object id;
  final String subject;
  const TicketScreen({super.key, required this.id, required this.subject});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: subject,
        scroll: false,
        body: AsyncView<Map<String, dynamic>>(
          load: () => PortalData.ticket(id),
          builder: (context, t, _) => ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              child: Column(children: [
                InfoRow(label: 'Ticket', value: pStr(t['ticket_id'])),
                InfoRow(label: 'Status', valueWidget: StatusPill(genericStatus(pStr(t['status'])))),
                InfoRow(label: 'Priority', value: pLabel(pStr(t['priority']))),
                InfoRow(label: 'Opened', value: pDay(t['created_at'])),
              ]),
            ),
            if (pStr(t['message']).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(pStr(t['message']), style: tx(context, 13, height: 1.45)),
            ],
            const SizedBox(height: 16),
            const InfoBanner('The business will follow up on this ticket. For a quick chat, use Messages.', icon: Icons.forum_outlined),
          ]),
        ),
      );
}

// ===================================================================== more

class CustomerMoreTab extends StatelessWidget {
  const CustomerMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalTabPage(
      title: 'More',
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        const PortalProfileCard(),
        const SizedBox(height: 16),
        const SectionLabel('Business'),
        ActionTile(icon: Icons.design_services_outlined, title: 'Services', subtitle: 'What you can order', onTap: () => pOpen(context, const ServicesScreen())),
        ActionTile(icon: Icons.contact_support_outlined, title: 'Contact support', subtitle: 'Email, phone, WhatsApp', onTap: () => pOpen(context, const ContactSupportScreen())),
        ActionTile(icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () => pOpen(context, const LegalPageScreen(slug: 'terms', title: 'Terms & Conditions'))),
        ActionTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => pOpen(context, const LegalPageScreen(slug: 'privacy', title: 'Privacy Policy'))),
        const SizedBox(height: 8),
        const SectionLabel('Account'),
        ActionTile(icon: Icons.password, title: 'Change password', onTap: () => pOpen(context, const ChangePasswordScreen())),
        ActionTile(icon: Icons.fingerprint, title: 'Security', subtitle: 'Fingerprint / Face ID', onTap: () => pOpen(context, const SecurityScreen())),
        ActionTile(icon: Icons.contrast, title: 'Appearance', onTap: () => pOpen(context, const AppearanceScreen())),
        ActionTile(icon: Icons.logout, title: 'Log out', onTap: () => portalLogout(context)),
        ActionTile(icon: Icons.delete_forever_outlined, title: 'Delete my account', danger: true, onTap: () => portalDeleteAccount(context)),
      ]),
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Services',
        scroll: false,
        body: AsyncView<List<Map<String, dynamic>>>(
          load: PortalData.serviceCategories,
          isEmpty: (d) => d.every((c) => pList(c['services']).isEmpty),
          empty: const EmptyState(icon: Icons.design_services_outlined, title: 'No services listed yet'),
          builder: (context, cats, _) => ListView(padding: const EdgeInsets.all(16), children: [
            for (final c in cats)
              if (pList(c['services']).isNotEmpty) ...[
                SectionLabel(pName(c)),
                for (final s in pList(c['services']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BpCard(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(pName(s), style: tx(context, 13.5, weight: FontWeight.w700)),
                            if (pStr(s['description']).isNotEmpty) Text(pStr(s['description']), style: tx(context, 11.5, color: context.p.textMuted)),
                          ]),
                        ),
                        if (pNum(s['base_price'] ?? s['price']) > 0) MoneyText(pNum(s['base_price'] ?? s['price']), size: 13.5),
                      ]),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            Text('To order, send a message from Support and the business will send you a quotation.', style: tx(context, 11.5, color: context.p.textMuted)),
          ]),
        ),
      );
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Contact support',
        scroll: false,
        body: AsyncView<Map<String, dynamic>>(
          load: PortalData.supportSettings,
          builder: (context, s, _) {
            final email = pStr(s['support_email']);
            final phone = pStr(s['support_phone']);
            final wa = pStr(s['support_whatsapp']).replaceAll(RegExp(r'[^0-9]'), '');
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (email.isNotEmpty) ActionTile(icon: Icons.mail_outline, title: 'Email', subtitle: email, onTap: () => openLink(context, 'mailto:$email')),
              if (phone.isNotEmpty) ActionTile(icon: Icons.call_outlined, title: 'Call', subtitle: phone, onTap: () => openLink(context, 'tel:$phone')),
              if (wa.isNotEmpty) ActionTile(icon: Icons.chat_outlined, title: 'WhatsApp', subtitle: pStr(s['support_whatsapp']), onTap: () => openLink(context, 'https://wa.me/$wa')),
              ActionTile(icon: Icons.forum_outlined, title: 'Message in the app', subtitle: 'Chat with the business', onTap: () => pOpen(context, const SupportChatsScreen())),
            ]);
          },
        ),
      );
}

class LegalPageScreen extends StatelessWidget {
  final String slug;
  final String title;
  const LegalPageScreen({super.key, required this.slug, required this.title});

  /// The page body is HTML; show it as readable text.
  static String plain(String html) => html
      .replaceAll(RegExp(r'<(br|/p|/h[1-6]|/li)\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: title,
        scroll: false,
        body: AsyncView<Map<String, dynamic>>(
          load: () => PortalData.legalPage(slug),
          builder: (context, page, _) => ListView(padding: const EdgeInsets.all(16), children: [
            if (pDate(page['updated_at']) != null) Text('Updated ${pDay(page['updated_at'])}', style: tx(context, 11.5, color: context.p.textMuted)),
            const SizedBox(height: 8),
            SelectableText(plain(pStr(page['content'])), style: tx(context, 13, height: 1.5)),
          ]),
        ),
      );
}


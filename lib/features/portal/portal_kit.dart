import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/api/live_session.dart';
import '../../core/api/mappers.dart';
import '../../core/api/resources.dart';
import '../../core/data/biz_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/format.dart';
import '../../core/utils/pick_file.dart';
import '../../core/widgets/bizpaddi_logo.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/widgets/ui_kit.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../auth/presentation/screens/welcome_back_screen.dart';

// ===================================================================== helpers

String pStr(dynamic v) => ApiMappers.str(v);
double pNum(dynamic v) => ApiMappers.num0(v);
DateTime? pDate(dynamic v) => ApiMappers.date(v);
String pDay(dynamic v) => pDate(v) == null ? '—' : Fmt.date(pDate(v)!);
String pName(dynamic v) => ResourceRepository.nameOf(v);
List<Map<String, dynamic>> pList(dynamic v) => ApiClient.parsePage(v).$1;
Map<String, dynamic> pMap(dynamic v) => v is Map<String, dynamic> ? v : const {};

/// "in_progress" → "In progress".
String pLabel(String raw) => raw.isEmpty ? '—' : (raw[0].toUpperCase() + raw.substring(1)).replaceAll('_', ' ');

void pOpen(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

/// The signed-in staff / customer profile (a blank one until it has loaded).
PortalAccount get portalMe =>
    LiveSession.instance.portalAccount.value ??
    PortalAccount(id: null, name: '', email: '', role: LiveSession.instance.role);

/// Opens a link in the browser (pay page, email, phone, WhatsApp).
Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.parse(url.startsWith('http') || url.contains(':') ? url : 'https://$url');
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  if (context.mounted) showToast(context, 'Couldn’t open $url');
}

/// Runs a backend call from a button; shows the result or the server message.
Future<bool> portalAction(BuildContext context, Future<void> Function() action, {String? done}) async {
  try {
    await action();
    if (done != null && context.mounted) showToast(context, done);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showToast(context, e.message);
    return false;
  }
}

// ===================================================================== loader

/// Loads [load] once (and on pull-to-refresh), with loading, error and empty states.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  const AsyncView({super.key, required this.load, required this.builder, this.isEmpty, this.empty});

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = await widget.load();
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) {
      if (_loading) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Couldn’t load this',
        message: _error,
        action: CustomButton(text: 'Try Again', width: 160, onPressed: reload),
      );
    }
    if (widget.isEmpty?.call(d) == true && widget.empty != null) {
      return RefreshIndicator(onRefresh: reload, child: ListView(children: [widget.empty!]));
    }
    // Transparent Material so list rows (ListTile, CheckboxListTile) ink on the white panel.
    return RefreshIndicator(
      onRefresh: reload,
      child: Material(type: MaterialType.transparency, child: widget.builder(context, d, reload)),
    );
  }
}

// ===================================================================== shell

typedef PortalTab = ({IconData icon, IconData selectedIcon, String label, Widget page});

/// Bottom bar (phones) / side rail (tablets) shell for the staff and customer apps.
class PortalShell extends StatefulWidget {
  final List<PortalTab> tabs;
  const PortalShell({super.key, required this.tabs});

  static void switchTab(BuildContext context, int index) => context.findAncestorStateOfType<_PortalShellState>()?._select(index);

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    LiveSession.instance.sessionExpired.addListener(_onExpired);
  }

  @override
  void dispose() {
    LiveSession.instance.sessionExpired.removeListener(_onExpired);
    super.dispose();
  }

  void _onExpired() {
    if (!LiveSession.instance.sessionExpired.value || !mounted) return;
    showToast(context, 'Your session ended. Please log in again.');
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final tabs = IndexedStack(index: _index, children: [for (final t in widget.tabs) t.page]);

    if (context.isExpanded) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Row(children: [
          SafeArea(
            right: false,
            child: Container(
              decoration: BoxDecoration(color: p.card, border: Border(right: BorderSide(color: p.border))),
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: _select,
                        labelType: NavigationRailLabelType.all,
                        groupAlignment: -0.85,
                        leading: context.isShort ? null : const Padding(padding: EdgeInsets.only(top: 8, bottom: 16), child: BizpaddiLogo(size: 30)),
                        trailing: const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: ThemeToggleButton()),
                        destinations: [
                          for (final t in widget.tabs) NavigationRailDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: Text(t.label)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: tabs),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: tabs,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.border))),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < widget.tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => _select(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: i == _index ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                            child: Icon(i == _index ? widget.tabs[i].selectedIcon : widget.tabs[i].icon, size: 20, color: i == _index ? Colors.white : p.textMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(widget.tabs[i].label,
                              style: tx(context, 10.5, weight: i == _index ? FontWeight.w700 : FontWeight.w500, color: i == _index ? p.brand : p.textMuted)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab page: gradient header + rounded panel holding [child] (usually a list).
class PortalTabPage extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? headerBottom;
  final Widget child;
  final Widget? fab;
  const PortalTabPage({super.key, required this.title, required this.child, this.trailing, this.headerBottom, this.fab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: fab,
      body: Column(children: [
        TabHeader(title: title, trailing: trailing ?? const ThemeToggleButton(), bottom: headerBottom),
        Expanded(child: TabPanel(child: child)),
      ]),
    );
  }
}

/// Small figure tile for dashboards.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return BpCard(
      onTap: onTap,
      child: Row(children: [
        LeadingIcon(icon, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: tx(context, 17, weight: FontWeight.w800)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 11.5, color: p.textMuted)),
          ]),
        ),
      ]),
    );
  }
}

/// Two-per-row grid of [StatTile]s.
Widget statGrid(List<Widget> tiles) => LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(spacing: 10, runSpacing: 10, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
      },
    );

// ===================================================================== account

/// Profile card at the top of the staff / customer "More" tab.
class PortalProfileCard extends StatelessWidget {
  const PortalProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PortalAccount?>(
      valueListenable: LiveSession.instance.portalAccount,
      builder: (context, _, _) {
        final me = portalMe;
        final p = context.p;
        final sub = me.role == AccountRole.staff
            ? [if (me.jobRole.isNotEmpty) pLabel(me.jobRole), if (me.department.isNotEmpty) me.department].join(' · ')
            : (me.companyName.isNotEmpty ? me.companyName : 'Customer');
        return BpCard(
          onTap: () => pOpen(context, const PortalProfileScreen()),
          child: Row(children: [
            if (me.avatarUrl != null)
              ClipOval(child: Image.network(me.avatarUrl!, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, _, _) => InitialsAvatar(me.name, size: 44)))
            else
              InitialsAvatar(me.name.isEmpty ? '?' : me.name, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(me.name, style: tx(context, 14, weight: FontWeight.w800)),
                Text(sub.isEmpty ? me.email : sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 11.5, color: p.textMuted)),
              ]),
            ),
            Icon(Icons.chevron_right, color: p.textMuted),
          ]),
        );
      },
    );
  }
}

/// Name, phone (staff) or company (customer), photo.
class PortalProfileScreen extends StatefulWidget {
  const PortalProfileScreen({super.key});

  @override
  State<PortalProfileScreen> createState() => _PortalProfileScreenState();
}

class _PortalProfileScreenState extends State<PortalProfileScreen> {
  final me = portalMe;
  late final _name = TextEditingController(text: me.name);
  late final _second = TextEditingController(text: me.role == AccountRole.staff ? me.phone : me.companyName);
  bool _saving = false;
  List<int>? _photo;

  @override
  void dispose() {
    _name.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final f = await pickUploadFile(context, title: 'Profile photo', maxBytes: 5 * 1024 * 1024);
    if (f == null || !mounted) return;
    setState(() => _photo = f.bytes);
    await portalAction(context, () => LiveSession.instance.uploadAvatar(f.bytes, f.name), done: 'Photo updated');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await portalAction(context, () => LiveSession.instance.updateProfile(name: _name.text.trim(), phone: _second.text.trim()));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showToast(context, 'Profile saved');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = me.role == AccountRole.staff;
    return InnerScaffold(
      title: 'My Profile',
      bottom: CustomButton(text: 'Save', isLoading: _saving, onPressed: _name.text.trim().isEmpty || _saving ? null : _save),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: InkWell(
            onTap: _pickPhoto,
            customBorder: const CircleBorder(),
            child: Stack(children: [
              if (_photo != null)
                ClipOval(child: Image.memory(Uint8List.fromList(_photo!), width: 84, height: 84, fit: BoxFit.cover))
              else if (me.avatarUrl != null)
                ClipOval(child: Image.network(me.avatarUrl!, width: 84, height: 84, fit: BoxFit.cover, errorBuilder: (_, _, _) => InitialsAvatar(me.name, size: 84)))
              else
                InitialsAvatar(me.name.isEmpty ? '?' : me.name, size: 84),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: const Icon(Icons.photo_camera, size: 15, color: Colors.white)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        CustomTextField(label: 'Full name', hint: 'Your name', controller: _name, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(
          label: staff ? 'Phone' : 'Company (optional)',
          hint: staff ? '0803 000 0000' : 'Your company name',
          controller: _second,
          keyboardType: staff ? TextInputType.phone : TextInputType.text,
        ),
        const SizedBox(height: 14),
        InfoRow(label: 'Email', value: me.email.isEmpty ? '—' : me.email),
        if (staff && me.jobRole.isNotEmpty) InfoRow(label: 'Role', value: pLabel(me.jobRole)),
        if (staff && me.department.isNotEmpty) InfoRow(label: 'Department', value: me.department),
      ]),
    );
  }
}

/// Log out with a confirm sheet; back to "Welcome back".
Future<void> portalLogout(BuildContext context) async {
  final ok = await showConfirmSheet(context, title: 'Log out?', message: 'You can log back in any time with your email and password.', confirmLabel: 'Log Out', cancelLabel: 'Cancel');
  if (!ok || !context.mounted) return;
  await LiveSession.instance.logout();
  if (!context.mounted) return;
  BizStore.instance.logOut();
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeBackScreen()), (_) => false);
}

Future<void> portalDeleteAccount(BuildContext context) async {
  final ok = await showConfirmSheet(
    context,
    title: 'Delete your account?',
    message: 'Your login is removed and you’re signed out. This can’t be undone from the app.',
    confirmLabel: 'Delete Account',
    cancelLabel: 'Keep Account',
  );
  if (!ok || !context.mounted) return;
  if (!await portalAction(context, LiveSession.instance.deleteAccount)) return;
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
}

// ===================================================================== support chats (staff + customers)

/// Support conversations with the business (`/team/chats`, `/client/chats`).
class SupportChatsScreen extends StatelessWidget {
  const SupportChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<AsyncViewState<List<Map<String, dynamic>>>>();
    return InnerScaffold(
      title: 'Messages',
      subtitle: 'Talk to the business',
      scroll: false,
      bottom: CustomButton(
        text: 'New Message',
        icon: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const NewSupportChatScreen()));
          if (created == true) key.currentState?.reload();
        },
      ),
      body: AsyncView<List<Map<String, dynamic>>>(
        key: key,
        load: PortalData.chats,
        isEmpty: (d) => d.isEmpty,
        empty: const EmptyState(icon: Icons.forum_outlined, title: 'No messages yet', message: 'Start a conversation and the team will reply here.'),
        builder: (context, chats, reload) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final c in chats)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BpCard(
                onTap: () async {
                  await pOpen2(context, SupportChatThreadScreen(chatId: c['id'], subject: pStr(c['subject'])));
                  reload();
                },
                child: Row(children: [
                  LeadingIcon(c['is_closed'] == true ? Icons.lock_outline : Icons.forum_outlined, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pStr(c['subject']).isEmpty ? 'Conversation' : pStr(c['subject']), style: tx(context, 13.5, weight: FontWeight.w700)),
                      Text('${c['is_closed'] == true ? 'Closed' : 'Open'} · ${pDate(c['updated_at']) == null ? '' : Fmt.relativeDay(pDate(c['updated_at'])!)}',
                          style: tx(context, 11.5, color: context.p.textMuted)),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: context.p.textMuted),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

Future<T?> pOpen2<T>(BuildContext context, Widget page) => Navigator.push<T>(context, MaterialPageRoute(builder: (_) => page));

class NewSupportChatScreen extends StatefulWidget {
  const NewSupportChatScreen({super.key});

  @override
  State<NewSupportChatScreen> createState() => _NewSupportChatScreenState();
}

class _NewSupportChatScreenState extends State<NewSupportChatScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final ok = await portalAction(context, () => PortalData.startChat(_subject.text.trim(), _message.text.trim()), done: 'Message sent');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'New Message',
      bottom: CustomButton(text: 'Send', isLoading: _busy, onPressed: _message.text.trim().isEmpty || _busy ? null : _send),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Subject (optional)', hint: 'e.g. Question about my invoice', controller: _subject),
        const SizedBox(height: 14),
        CustomTextField(label: 'Message', hint: 'How can we help?', controller: _message, maxLines: 5, onChanged: (_) => setState(() {})),
      ]),
    );
  }
}

class SupportChatThreadScreen extends StatefulWidget {
  final Object chatId;
  final String subject;
  const SupportChatThreadScreen({super.key, required this.chatId, required this.subject});

  @override
  State<SupportChatThreadScreen> createState() => _SupportChatThreadScreenState();
}

class _SupportChatThreadScreenState extends State<SupportChatThreadScreen> {
  final _input = TextEditingController();
  Map<String, dynamic>? _chat;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await PortalData.chat(widget.chatId);
      if (mounted) setState(() => _chat = c);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  bool get _closed => _chat?['is_closed'] == true;

  Future<void> _send({PickedFile? file}) async {
    final text = _input.text.trim();
    if (text.isEmpty && file == null) return;
    setState(() => _sending = true);
    final ok = await portalAction(context, () => PortalData.sendChatMessage(widget.chatId, text, bytes: file?.bytes, filename: file?.name));
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _input.clear();
      _load();
    }
  }

  Future<void> _menu() async {
    final choice = await showBpSheet<String>(
      context,
      showHandle: true,
      builder: (s) => Column(mainAxisSize: MainAxisSize.min, children: [
        if (!_closed) ActionTile(icon: Icons.lock_outline, title: 'Close conversation', onTap: () => Navigator.pop(s, 'close')),
        ActionTile(icon: Icons.delete_outline, title: 'Delete conversation', danger: true, onTap: () => Navigator.pop(s, 'delete')),
      ]),
    );
    if (!mounted || choice == null) return;
    if (choice == 'close') {
      if (await portalAction(context, () => PortalData.closeChat(widget.chatId), done: 'Conversation closed')) _load();
    } else if (await portalAction(context, () => PortalData.deleteChat(widget.chatId), done: 'Conversation deleted') && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final msgs = pList(_chat?['messages']);
    return InnerScaffold(
      title: widget.subject.isEmpty ? 'Conversation' : widget.subject,
      subtitle: _closed ? 'Closed' : null,
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      actions: [CircleIconButton(icon: Icons.more_horiz, tooltip: 'Conversation options', onTap: _menu)],
      bottom: _closed
          ? const InfoBanner('This conversation is closed. Start a new message to talk again.', icon: Icons.lock_outline)
          : Row(children: [
              CircleIconButton(
                icon: Icons.attach_file,
                tooltip: 'Attach a photo',
                onTap: () async {
                  final f = await pickUploadFile(context, title: 'Attach');
                  if (f != null) _send(file: f);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _input,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(hintText: 'Type a message', isDense: true, fillColor: p.cardAlt),
                ),
              ),
              const SizedBox(width: 8),
              CircleIconButton(icon: Icons.send, background: p.primarySoft, color: p.brand, size: 44, tooltip: 'Send', onTap: _sending ? () {} : () => _send()),
            ]),
      body: _chat == null
          ? (_error != null
              ? EmptyState(icon: Icons.cloud_off, title: 'Couldn’t load this', message: _error)
              : const Center(child: CircularProgressIndicator()))
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final m in msgs) _bubble(context, m),
            ]),
    );
  }

  Widget _bubble(BuildContext context, Map<String, dynamic> m) {
    final p = context.p;
    final mine = pStr(m['sender_type']) == 'user';
    final file = pStr(m['attachment_name']);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: mine ? p.primarySoft : p.cardAlt, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (pStr(m['message']).isNotEmpty) Text(pStr(m['message']), style: tx(context, 13, height: 1.4)),
          if (file.isNotEmpty)
            InkWell(
              onTap: pStr(m['attachment_path']).isEmpty || LiveLinks.host == null ? null : () => openLink(context, '${LiveLinks.host}/storage/${pStr(m['attachment_path'])}'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.attachment, size: 15, color: p.brand),
                const SizedBox(width: 4),
                Flexible(child: Text(file, overflow: TextOverflow.ellipsis, style: tx(context, 12, color: p.brand))),
              ]),
            ),
          const SizedBox(height: 2),
          Text(pDate(m['created_at']) == null ? '' : Fmt.time(pDate(m['created_at'])!), style: tx(context, 10, color: p.textMuted)),
        ]),
      ),
    );
  }
}

// ===================================================================== data

/// Staff / customer data, straight from the backend (`/api/v1/team/*`, `/api/v1/client/*`).
class PortalData {
  PortalData._();

  static bool get _staff => LiveSession.instance.role == AccountRole.staff;
  static LiveSession get _s => LiveSession.instance;

  // ---- support chats (both portals)
  static Future<List<Map<String, dynamic>>> chats() => _staff ? _s.team.chats() : _s.client.chats();
  static Future<Map<String, dynamic>> chat(Object id) => _staff ? _s.team.chat(id) : _s.client.chat(id);
  static Future<void> startChat(String subject, String message) async =>
      _staff ? await _s.team.startChat(subject, message) : await _s.client.startChat(subject, message);
  static Future<void> sendChatMessage(Object id, String message, {List<int>? bytes, String? filename}) async => _staff
      ? await _s.team.sendChatMessage(id, message, bytes: bytes, filename: filename)
      : await _s.client.sendChatMessage(id, message, bytes: bytes, filename: filename);
  static Future<void> closeChat(Object id) => _staff ? _s.team.closeChat(id) : _s.client.closeChat(id);
  static Future<void> deleteChat(Object id) => _staff ? _s.team.deleteChat(id) : _s.client.deleteChat(id);

  // ---- projects (both portals)
  static Future<List<Map<String, dynamic>>> projects() => _staff ? _s.team.projects() : _s.client.projects();
  static Future<Map<String, dynamic>> project(Object id) => _staff ? _s.team.project(id) : _s.client.project(id);

  // ---- staff
  static Future<Map<String, dynamic>> teamDashboard() => _s.team.dashboard();
  static Future<Map<String, dynamic>> pmDashboard() => _s.team.pmDashboard();

  /// `{todo: [...], in_progress: [...], review: [...], done: [...]}`
  static Future<Map<String, dynamic>> kanban() => _s.team.kanban();
  static Future<Map<String, dynamic>> task(Object id) => _s.team.task(id);
  static Future<void> setTaskStatus(Object id, String status) => _s.team.setTaskStatus(id, status);
  static Future<List<Map<String, dynamic>>> myTasks() => _s.team.tasks();

  static Future<Map<String, dynamic>> attendance() => _s.team.attendance();
  static Future<void> clockIn() async => _s.team.clockIn();
  static Future<void> clockOut() async => _s.team.clockOut();

  static Future<Map<String, dynamic>> workLogs() => _s.team.workLogs();
  static Future<void> startSession(Map<String, dynamic> body) async => _s.team.startSession(body);
  static Future<void> endSession(Object id, Map<String, dynamic> body) async => _s.team.endSession(id, body);

  static Future<List<Map<String, dynamic>>> reports() => _s.team.reports();
  static Future<void> submitReport(Map<String, dynamic> body) async => _s.team.submitReport(body);

  static Future<Map<String, dynamic>> wallet() => _s.team.wallet();
  static Future<List<Map<String, dynamic>>> walletTransactions() => _s.team.walletTransactions();
  static Future<List<Map<String, dynamic>>> earnings() => _s.team.earnings();
  static Future<List<Map<String, dynamic>>> bankAccounts() => _s.team.bankAccounts();
  static Future<List<Map<String, dynamic>>> banks() => _s.team.banks();

  /// [bankName] is only shown in the app; the backend looks the bank up from its code.
  static Future<void> saveBankAccount(Object? id, String bankCode, String bankName, String number) async =>
      id == null ? await _s.team.addBankAccount(bankCode, number) : await _s.team.updateBankAccount(id, bankCode, number);
  static Future<void> removeBankAccount(Object id) => _s.team.removeBankAccount(id);

  static Future<Map<String, dynamic>> performance() => _s.team.performance();

  // ---- project manager
  static Future<List<Map<String, dynamic>>> pmProjects() => _s.team.pmProjects();
  static Future<Map<String, dynamic>> pmProject(Object id) => _s.team.pmProject(id);
  static Future<List<Map<String, dynamic>>> pmTeamMembers() => _s.team.pmTeamMembers();
  static Future<void> pmSaveTask(Object? id, Map<String, dynamic> body) async =>
      id == null ? await _s.team.pmCreateTask(body) : await _s.team.pmUpdateTask(id, body);
  static Future<void> pmDeleteTask(Object id) => _s.team.pmDeleteTask(id);
  static Future<void> pmSaveMilestone(Object? id, Map<String, dynamic> body) async =>
      id == null ? await _s.team.pmCreateMilestone(body) : await _s.team.pmUpdateMilestone(id, body);
  static Future<void> pmDeleteMilestone(Object id) => _s.team.pmDeleteMilestone(id);
  static Future<List<Map<String, dynamic>>> pmWorkLogs() => _s.team.pmWorkLogs();
  static Future<List<Map<String, dynamic>>> pmClients() => _s.team.clients();
  static Future<List<Map<String, dynamic>>> pmInvoices() => _s.team.invoices();
  static Future<List<Map<String, dynamic>>> pmQuotes() => _s.team.quotes();
  static Future<List<Map<String, dynamic>>> pmServices() => _s.team.services();

  // ---- customer (invoice / quote detail also serves project-manager staff)
  static Future<List<Map<String, dynamic>>> invoices() => _s.client.invoices();
  static Future<Map<String, dynamic>> invoice(Object id) => _staff ? _s.team.invoice(id) : _s.client.invoice(id);
  static Future<List<Map<String, dynamic>>> quotes() => _s.client.quotes();
  static Future<Map<String, dynamic>> quote(Object id) => _staff ? _s.team.quote(id) : _s.client.quote(id);
  static Future<List<Map<String, dynamic>>> tickets() => _s.client.tickets();
  static Future<Map<String, dynamic>> ticket(Object id) => _s.client.ticket(id);
  static Future<void> openTicket(String subject, String message, String priority) async => _s.client.openTicket(subject, message, priority);
  static Future<List<Map<String, dynamic>>> serviceCategories() => _s.client.serviceCategories();
  static Future<Map<String, dynamic>> supportSettings() => _s.client.supportSettings();
  static Future<Map<String, dynamic>> legalPage(String slug) => _s.client.legalPage(slug);
}

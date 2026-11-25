import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/api/live_session.dart';
import '../../core/api/mappers.dart';
import '../../core/api/resources.dart';
import '../../core/data/biz_store.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/password_rules.dart';
import '../../core/widgets/ui_kit.dart';
import 'resource_screens.dart';
import 'resource_specs.dart';

String _err(Object e) => e is ApiException ? e.message : 'Something went wrong. Please try again.';
void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

// ================================================================= projects

/// Projects list whose rows open [projectDetails].
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) => ResourceListScreen(spec: Specs.projects, detailBuilder: (s, item) => projectDetails(item));
}

/// Project view: details + tasks, milestones and the two chats.
Widget projectDetails(Map<String, dynamic> project) => ResourceDetailScreen(
      spec: Specs.projects,
      item: project,
      extra: (context, item) {
        final id = item['id'];
        final name = Specs.projects.titleOf(item);
        return [
          const SizedBox(height: 18),
          const SectionLabel('Work'),
          ActionTile(icon: Icons.task_alt, title: 'Tasks', subtitle: 'Jobs to be done and who does them', onTap: () => _open(context, ResourceListScreen(spec: Specs.tasks, query: {'project_id': id}, subtitle: name))),
          ActionTile(icon: Icons.flag_outlined, title: 'Milestones', subtitle: 'Checkpoints and due dates', onTap: () => _open(context, ResourceListScreen(spec: Specs.milestones, query: {'project_id': id}, subtitle: name))),
          const SizedBox(height: 8),
          const SectionLabel('Chat'),
          ActionTile(icon: Icons.forum_outlined, title: 'Team chat', subtitle: 'Only you and your staff', onTap: () => _open(context, ProjectChatScreen(projectId: id, projectName: name, type: ChatType.team))),
          ActionTile(icon: Icons.support_agent, title: 'Customer chat', subtitle: 'Talk with ${ResourceRepository.nameOf(item['client']).isEmpty ? 'the customer' : ResourceRepository.nameOf(item['client'])}', onTap: () => _open(context, ProjectChatScreen(projectId: id, projectName: name, type: ChatType.client))),
        ];
      },
    );

// ===================================================================== chat

enum ChatType {
  team('internal_team', 'Team chat'),
  client('client_team', 'Customer chat');

  final String api;
  final String label;
  const ChatType(this.api, this.label);
}

class ChatMessage {
  final Object id;
  String content;
  final String senderName;
  final bool mine;
  final DateTime sentAt;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool attachmentIsImage;

  ChatMessage({required this.id, required this.content, required this.senderName, required this.mine, required this.sentAt, this.attachmentUrl, this.attachmentName, this.attachmentIsImage = false});

  bool get editable => mine && DateTime.now().difference(sentAt).inMinutes < 5;

  factory ChatMessage.fromJson(Map<String, dynamic> j, {int? myId}) {
    final media = (j['media'] as List? ?? const []).whereType<Map>().firstOrNull;
    final senderType = ApiMappers.str(j['sender_type']).toLowerCase();
    final mime = ApiMappers.str(media?['mime_type']);
    return ChatMessage(
      id: j['id'],
      content: ApiMappers.str(j['content']),
      senderName: ResourceRepository.nameOf(j['sender']),
      mine: myId != null && ApiMappers.intOrNull(j['sender_id']) == myId && (senderType.isEmpty || senderType.contains('admin')),
      sentAt: ApiMappers.date(j['created_at']) ?? DateTime.now(),
      attachmentUrl: media == null ? null : ApiMappers.str(media['original_url'] ?? media['url']),
      attachmentName: media == null ? null : ApiMappers.str(media['file_name'] ?? media['name']),
      attachmentIsImage: mime.startsWith('image/'),
    );
  }
}

/// Chat API (live) or an in-memory conversation (demo).
class ProjectChatRepository {
  static ProjectChatRepository instance = ProjectChatRepository();
  final _demo = <String, List<ChatMessage>>{};
  final _demoStatus = <String, String>{};
  var _seq = 1;

  bool get _live => LiveSession.enabled;
  int? get _myId => BizStore.instance.account.userId;

  List<ChatMessage> _demoFor(Object project, ChatType t) => _demo.putIfAbsent('$project/${t.api}', () => [
        ChatMessage(id: _seq++, content: t == ChatType.team ? 'Fabric is in. Starting the cutting today.' : 'Hello! Please can we move the fitting to Saturday?', senderName: t == ChatType.team ? 'Amaka Eze' : 'Ada Obi', mine: false, sentAt: DateTime.now().subtract(const Duration(hours: 3))),
      ]);

  /// Messages oldest → newest, and the conversation status.
  Future<(List<ChatMessage>, String)> load(Object project, ChatType t) async {
    if (!_live) return (List.of(_demoFor(project, t)), _demoStatus['$project/${t.api}'] ?? 'active');
    final data = await LiveSession.instance.business.projectChat(project, t.api);
    final conv = data['conversation'] is Map ? data['conversation'] as Map : const {};
    final raw = ApiClient.parsePage(data['messages']).$1;
    final msgs = raw.map((j) => ChatMessage.fromJson(j, myId: _myId)).toList().reversed.toList();
    // Mark the newest messages from others as read (best effort).
    final me = '$_myId';
    for (final j in raw.take(10)) {
      final reads = (j['reads'] as List? ?? const []).whereType<Map>();
      final fromMe = '${j['sender_id']}' == me && ApiMappers.str(j['sender_type']).toLowerCase().contains('admin');
      if (!fromMe && !reads.any((r) => '${r['user_id']}' == me)) {
        LiveSession.instance.business.markProjectMessageRead(j['id']).catchError((_) {});
      }
    }
    return (msgs, ApiMappers.str(conv['status']).isEmpty ? 'active' : ApiMappers.str(conv['status']));
  }

  Future<ChatMessage> send(Object project, ChatType t, String content, {List<int>? bytes, String? filename}) async {
    if (!_live) {
      final m = ChatMessage(id: _seq++, content: content, senderName: BizStore.instance.account.ownerFullName, mine: true, sentAt: DateTime.now(), attachmentName: filename, attachmentIsImage: bytes != null);
      _demoFor(project, t).add(m);
      return m;
    }
    final j = await LiveSession.instance.business.sendProjectMessage(project, t.api, content, bytes: bytes, filename: filename);
    return ChatMessage.fromJson(j, myId: _myId);
  }

  Future<void> edit(Object project, ChatType t, ChatMessage m, String content) async {
    if (_live) await LiveSession.instance.business.editProjectMessage(m.id, content);
    m.content = content;
  }

  Future<void> delete(Object project, ChatType t, ChatMessage m) async {
    if (_live) {
      await LiveSession.instance.business.deleteProjectMessage(m.id);
    } else {
      _demoFor(project, t).remove(m);
    }
  }

  Future<void> setStatus(Object project, ChatType t, String status) async {
    if (_live) {
      await LiveSession.instance.business.setChatStatus(project, t.api, status);
    } else {
      _demoStatus['$project/${t.api}'] = status;
    }
  }
}

class ProjectChatScreen extends StatefulWidget {
  final Object projectId;
  final String projectName;
  final ChatType type;
  const ProjectChatScreen({super.key, required this.projectId, required this.projectName, required this.type});

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage>? _messages;
  String _status = 'active';
  String? _error;
  bool _sending = false;
  ({List<int> bytes, String name})? _attachment;

  ProjectChatRepository get _repo => ProjectChatRepository.instance;
  bool get _open => _status == 'active';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (msgs, status) = await _repo.load(widget.projectId, widget.type);
      if (!mounted) return;
      setState(() => (_messages = msgs, _status = status, _error = null));
      _toBottom();
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  Future<void> _pick() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (mounted) setState(() => _attachment = (bytes: bytes, name: f.name));
    } catch (_) {
      if (mounted) showToast(context, 'Couldn’t open your photos.');
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && _attachment == null) return;
    setState(() => _sending = true);
    try {
      final att = _attachment;
      // The API requires text, so a photo on its own gets a short caption.
      final m = await _repo.send(widget.projectId, widget.type, text.isEmpty ? '📎 ${att!.name}' : text, bytes: att?.bytes, filename: att?.name);
      if (!mounted) return;
      _input.clear();
      setState(() => (_messages = [...?_messages, m], _attachment = null));
      _toBottom();
    } catch (e) {
      if (mounted) showToast(context, _err(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _messageActions(ChatMessage m) async {
    final action = await showBpSheet<String>(
      context,
      title: 'Message',
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        if (m.editable) ActionTile(icon: Icons.edit_outlined, title: 'Edit', subtitle: 'Within 5 minutes of sending', onTap: () => Navigator.pop(ctx, 'edit')),
        ActionTile(icon: Icons.delete_outline, title: 'Delete for everyone', danger: true, onTap: () => Navigator.pop(ctx, 'delete')),
      ]),
    );
    if (!mounted || action == null) return;
    try {
      if (action == 'delete') {
        await _repo.delete(widget.projectId, widget.type, m);
        setState(() => _messages?.remove(m));
      } else {
        final c = TextEditingController(text: m.content);
        final text = await showBpSheet<String>(
          context,
          title: 'Edit message',
          builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
            CustomTextField(controller: c, maxLines: 4, autofocus: true),
            const SizedBox(height: 14),
            CustomButton(text: 'Save', onPressed: () => Navigator.pop(ctx, c.text.trim())),
          ]),
        );
        if (text == null || text.isEmpty || !mounted) return;
        await _repo.edit(widget.projectId, widget.type, m, text);
        setState(() {});
      }
    } catch (e) {
      if (mounted) showToast(context, _err(e));
    }
  }

  Future<void> _conversationMenu() async {
    final next = await showBpSheet<String>(
      context,
      title: 'Conversation',
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        if (_status != 'active') ActionTile(icon: Icons.play_circle_outline, title: 'Re-open chat', subtitle: 'Everyone can send messages again', onTap: () => Navigator.pop(ctx, 'active')),
        if (_status == 'active') ActionTile(icon: Icons.pause_circle_outline, title: 'Pause chat', subtitle: 'No one can send messages until you re-open it', onTap: () => Navigator.pop(ctx, 'suspended')),
        if (_status != 'terminated') ActionTile(icon: Icons.block, title: 'Close chat', subtitle: 'End this conversation', danger: true, onTap: () => Navigator.pop(ctx, 'terminated')),
      ]),
    );
    if (next == null || !mounted) return;
    try {
      await _repo.setStatus(widget.projectId, widget.type, next);
      if (!mounted) return;
      setState(() => _status = next);
      showToast(context, switch (next) { 'active' => 'Chat re-opened', 'suspended' => 'Chat paused', _ => 'Chat closed' });
    } catch (e) {
      if (mounted) showToast(context, _err(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final msgs = _messages;

    final Widget list;
    if (_error != null && msgs == null) {
      list = ListView(children: [EmptyState(icon: Icons.cloud_off_outlined, title: 'Couldn’t load the chat', message: _error, action: CustomButton(text: 'Try again', width: 160, height: 44, onPressed: _load))]);
    } else if (msgs == null) {
      list = const Center(child: CircularProgressIndicator());
    } else if (msgs.isEmpty) {
      list = ListView(children: [EmptyState(icon: Icons.forum_outlined, title: 'No messages yet', message: widget.type == ChatType.team ? 'Talk with your staff about this project.' : 'Messages here are seen by your customer.')]);
    } else {
      list = ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: msgs.length,
        itemBuilder: (context, i) => _Bubble(m: msgs[i], onLongPress: () => _messageActions(msgs[i])),
      );
    }

    return InnerScaffold(
      title: widget.type.label,
      subtitle: widget.projectName,
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      actions: [CircleIconButton(icon: Icons.more_horiz, tooltip: 'Conversation options', onTap: _conversationMenu)],
      bottom: _open
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              if (_attachment != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(Icons.image_outlined, size: 18, color: p.brand),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_attachment!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 12.5))),
                    InkWell(onTap: () => setState(() => _attachment = null), child: Icon(Icons.close, size: 18, color: p.textMuted)),
                  ]),
                ),
              Row(children: [
                CircleIconButton(icon: Icons.attach_file, tooltip: 'Attach photo', onTap: _sending ? null : _pick),
                const SizedBox(width: 8),
                Expanded(child: CustomTextField(hint: 'Type a message', controller: _input, onChanged: (_) => setState(() {}))),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.send,
                  tooltip: 'Send',
                  size: 44,
                  background: p.brand,
                  color: Colors.white,
                  onTap: _sending || (_input.text.trim().isEmpty && _attachment == null) ? null : _send,
                ),
              ]),
            ])
          : InfoBanner(_status == 'suspended' ? 'This chat is paused. Re-open it from ⋯ to send messages.' : 'This chat is closed.', icon: Icons.lock_outline),
      body: RefreshIndicator(onRefresh: _load, child: list),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  final VoidCallback onLongPress;
  const _Bubble({required this.m, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final bg = m.mine ? p.brand : p.cardAlt;
    final fg = m.mine ? Colors.white : p.text;
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!m.mine && m.senderName.isNotEmpty) Text(m.senderName, style: tx(context, 11, weight: FontWeight.w700, color: p.brand)),
            if (m.attachmentUrl != null && m.attachmentUrl!.isNotEmpty && m.attachmentIsImage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(m.attachmentUrl!, height: 160, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: fg)),
                ),
              )
            else if (m.attachmentName != null && m.attachmentName!.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.attach_file, size: 14, color: fg), Flexible(child: Text(m.attachmentName!, style: tx(context, 12, color: fg)))]),
            Text(m.content, style: tx(context, 13.5, color: fg, height: 1.35)),
            const SizedBox(height: 2),
            Text(Fmt.time(m.sentAt), style: tx(context, 10, color: m.mine ? Colors.white70 : p.textMuted)),
          ]),
        ),
      ),
    );
  }
}

// ================================================================== tickets

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) => ResourceListScreen(
        spec: Specs.tickets,
        detailBuilder: (s, item) => ResourceDetailScreen(spec: s, item: item, extra: _ticketConversation),
      );

  static List<Widget> _ticketConversation(BuildContext context, Map<String, dynamic> item) {
    final p = context.p;
    final msgs = (item['messages'] as List? ?? const []).whereType<Map>().toList();
    if (msgs.isEmpty) return const [];
    return [
      const SizedBox(height: 18),
      const SectionLabel('Conversation'),
      for (final m in msgs)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BpCard(
            color: p.cardAlt,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ApiMappers.str(m['message'] ?? m['content'] ?? m['body']), style: tx(context, 13.5, height: 1.4)),
              if (ApiMappers.date(m['created_at']) != null) ...[
                const SizedBox(height: 4),
                Text(Fmt.dateTime(ApiMappers.date(m['created_at'])!), style: tx(context, 11, color: p.textMuted)),
              ],
            ]),
          ),
        ),
      Text('Reply to the customer from bizpaddi.com — replies aren’t in the app API yet.', style: tx(context, 11.5, color: p.textMuted)),
    ];
  }
}

// ============================================================ balance sheet

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  static Map<String, dynamic> get _demo => {
        'assets': {'total': 2450000, 'accounts': [{'name': 'Cash at bank', 'current_balance': 1850000}, {'name': 'Money owed by customers', 'current_balance': 400000}, {'name': 'Stock', 'current_balance': 200000}]},
        'liabilities': {'total': 350000, 'accounts': [{'name': 'Supplier bills', 'current_balance': 350000}]},
        'equity': {'total': 2100000, 'accounts': [{'name': 'Owner’s capital', 'current_balance': 1500000}, {'name': 'Retained profit', 'current_balance': 600000}]},
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = LiveSession.enabled ? await LiveSession.instance.business.balanceSheet() : _demo;
      if (mounted) setState(() => (_data = d, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final d = _data;
    num total(String k) => ApiMappers.num0((d?[k] as Map?)?['total']);

    Widget section(String key, String title, Color color) {
      final accounts = ((d?[key] as Map?)?['accounts'] as List? ?? const []).whereType<Map>().toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: BpCard(
          color: p.cardAlt,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: tx(context, 14, weight: FontWeight.w800))),
              MoneyText(total(key), size: 14),
            ]),
            if (accounts.isEmpty) ...[
              const SizedBox(height: 8),
              Text('No accounts yet', style: tx(context, 12, color: p.textMuted)),
            ],
            for (final a in accounts) ...[
              const SizedBox(height: 10),
              InfoRow(label: ApiMappers.str(a['name']).isEmpty ? ApiMappers.str(a['code']) : ApiMappers.str(a['name']), value: Fmt.money(ApiMappers.num0(a['current_balance']))),
            ],
          ]),
        ),
      );
    }

    final balanced = d != null && (total('assets') - total('liabilities') - total('equity')).abs() < 1;

    return InnerScaffold(
      title: 'Balance Sheet',
      subtitle: 'What the business owns and owes, today',
      body: _error != null && d == null
          ? EmptyState(icon: Icons.cloud_off_outlined, title: 'Couldn’t load the balance sheet', message: _error, action: CustomButton(text: 'Try again', width: 160, height: 44, onPressed: _load))
          : d == null
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  section('assets', 'Assets — what you own', const Color(0xFF0E8A5F)),
                  section('liabilities', 'Liabilities — what you owe', const Color(0xFFDC2626)),
                  section('equity', 'Equity — owner’s share', const Color(0xFF2563EB)),
                  InfoBanner(
                    balanced ? 'Assets = Liabilities + Equity. Your books balance.' : 'Assets don’t equal Liabilities + Equity yet. Ask your accountant to review.',
                    icon: balanced ? Icons.check_circle_outline : Icons.info_outline,
                  ),
                ]),
    );
  }
}

// ================================================================== profile

/// Owner's own profile: photo, name, phone (email can't be changed).
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _store = BizStore.instance;
  late final _name = TextEditingController(text: _store.account.ownerFullName);
  late final _phone = TextEditingController(text: _store.account.businessPhone);
  bool _saving = false;
  bool _uploading = false;
  Uint8List? _localPhoto;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showBpSheet<ImageSource>(
      context,
      title: 'Profile photo',
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        ActionTile(icon: Icons.photo_camera_outlined, title: 'Take a photo', onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ActionTile(icon: Icons.photo_library_outlined, title: 'Choose from gallery', onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ]),
    );
    if (source == null) return;
    try {
      final f = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1024);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() => (_uploading = true, _localPhoto = bytes));
      if (LiveSession.enabled) await LiveSession.instance.uploadAvatar(bytes, f.name);
      if (mounted) showToast(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) showToast(context, _err(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final phone = _phone.text.trim();
      if (LiveSession.enabled) {
        await LiveSession.instance.updateProfile(name: name, phone: phone);
      } else {
        _store.account
          ..ownerFullName = name
          ..ownerFirstName = name.split(' ').first
          ..businessPhone = phone;
        _store.refresh();
      }
      if (!mounted) return;
      showToast(context, 'Profile updated');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, _err(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final a = _store.account;
    final ImageProvider? photo = _localPhoto != null
        ? MemoryImage(_localPhoto!)
        : (a.avatarUrl != null && a.avatarUrl!.isNotEmpty ? NetworkImage(a.avatarUrl!) : null);

    return InnerScaffold(
      title: 'My Profile',
      subtitle: 'How you appear to your team and customers',
      bottom: CustomButton(text: 'Save', isLoading: _saving, onPressed: _saving || _name.text.trim().isEmpty ? null : _save),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _uploading ? null : _pickPhoto,
            child: Stack(children: [
              photo == null
                  ? InitialsAvatar(a.ownerFullName, size: 84)
                  : CircleAvatar(radius: 42, backgroundColor: p.primarySoft, backgroundImage: photo, onBackgroundImageError: (_, _) {}),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: p.brand, shape: BoxShape.circle, border: Border.all(color: p.card, width: 2)),
                  child: _uploading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(label: 'Full name', hint: 'Enter your name', controller: _name, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(label: 'Phone number', hint: 'e.g. 0803 123 4567', controller: _phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        CustomTextField(label: 'Email', controller: TextEditingController(text: a.email), readOnly: true),
        const SizedBox(height: 6),
        Text('Your email is your login and can’t be changed here.', style: tx(context, 11.5, color: p.textMuted)),
      ]),
    );
  }
}


// ========================================================== change password

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _mismatch => _confirm.text.isNotEmpty && _confirm.text != _new.text;
  bool get _valid => _current.text.isNotEmpty && PasswordRules.isValid(_new.text) && _confirm.text == _new.text;

  Future<void> _save() async {
    setState(() => (_saving = true, _currentError = null));
    try {
      if (LiveSession.enabled) {
        await LiveSession.instance.changePassword(current: _current.text, password: _new.text);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted) return;
      showToast(context, 'Password changed');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => (_saving = false, _currentError = e.errorFor('current_password')));
      if (_currentError == null) showToast(context, e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, _err(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void refresh(_) => setState(() {});
    return InnerScaffold(
      title: 'Change Password',
      bottom: CustomButton(text: 'Change Password', isLoading: _saving, onPressed: _valid && !_saving ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Current password', hint: 'Enter current password', controller: _current, isPassword: true, errorText: _currentError, onChanged: refresh),
        const SizedBox(height: 14),
        CustomTextField(label: 'New password', hint: 'Enter new password', controller: _new, isPassword: true, onChanged: refresh),
        const SizedBox(height: 14),
        CustomTextField(label: 'Confirm new password', hint: 'Enter new password again', controller: _confirm, isPassword: true, errorText: _mismatch ? 'Passwords do not match' : null, onChanged: refresh),
        const SizedBox(height: 10),
        PasswordRulesView(password: _new.text),
      ]),
    );
  }
}

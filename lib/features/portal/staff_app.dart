import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/live_session.dart';
import '../../core/api/resources.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/ui_kit.dart';
import '../more/presentation/screens/appearance_screen.dart';
import '../more/presentation/screens/settings_screen.dart';
import '../support/presentation/screens/help_support_screen.dart';
import '../workspace/workspace_screens.dart' show ChangePasswordScreen;
import '../store/presentation/widgets/store_widgets.dart' show ToggleRow;
import 'portal_kit.dart';
import 'portal_projects.dart';

/// Staff (team member) app: tasks, attendance, work sessions, pay.
/// Project managers also get the management tools in More.
class StaffShell extends StatelessWidget {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) => const PortalShell(tabs: [
        (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', page: StaffHomeTab()),
        (icon: Icons.task_alt_outlined, selectedIcon: Icons.task_alt, label: 'Tasks', page: StaffTasksTab()),
        (icon: Icons.schedule_outlined, selectedIcon: Icons.schedule, label: 'Work', page: StaffWorkTab()),
        (icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet, label: 'Pay', page: StaffPayTab()),
        (icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'More', page: StaffMoreTab()),
      ]);
}

const _statuses = [('todo', 'To do'), ('in_progress', 'In progress'), ('review', 'Review'), ('done', 'Done')];

String _hm(dynamic v) {
  final s = pStr(v);
  if (s.isEmpty) return '—';
  final d = pDate(s);
  if (d != null && s.contains('T')) return Fmt.time(d);
  return s.length >= 5 ? s.substring(0, 5) : s;
}

// ===================================================================== home

class StaffHomeTab extends StatefulWidget {
  const StaffHomeTab({super.key});

  @override
  State<StaffHomeTab> createState() => _StaffHomeTabState();
}

class _StaffHomeTabState extends State<StaffHomeTab> {
  final _key = GlobalKey<AsyncViewState<Map<String, dynamic>>>();

  Future<void> _clock(bool inNow) async {
    final ok = await portalAction(context, inNow ? PortalData.clockIn : PortalData.clockOut, done: inNow ? 'Clocked in. Have a good day!' : 'Clocked out. See you tomorrow!');
    if (ok) _key.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = portalMe;
    return PortalTabPage(
      title: 'Hi ${me.firstName}',
      child: AsyncView<Map<String, dynamic>>(
        key: _key,
        load: PortalData.teamDashboard,
        builder: (context, d, reload) {
          final p = context.p;
          final stats = pMap(d['stats']);
          final today = d['attendance_today'] is Map ? d['attendance_today'] as Map : null;
          final clockedIn = today != null && today['clock_out'] == null;
          final recent = pList(d['recent_tasks']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              color: p.primarySoft,
              child: Row(children: [
                LeadingIcon(Icons.access_time, color: p.brand, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(today == null ? 'Not clocked in today' : (clockedIn ? 'Clocked in at ${_hm(today['clock_in'])}' : 'Done for today'),
                        style: tx(context, 13.5, weight: FontWeight.w800)),
                    Text(today == null ? 'Clock in when you start work.' : (clockedIn ? 'Remember to clock out when you finish.' : '${_hm(today['clock_in'])} – ${_hm(today['clock_out'])}'),
                        style: tx(context, 11.5, color: p.textSecondary)),
                  ]),
                ),
                if (today == null || clockedIn)
                  CustomButton(text: clockedIn ? 'Clock Out' : 'Clock In', width: 110, height: 38, variant: clockedIn ? ButtonVariant.outline : ButtonVariant.accent, onPressed: () => _clock(!clockedIn)),
              ]),
            ),
            const SizedBox(height: 14),
            statGrid([
              StatTile(label: 'To do', value: '${stats['pending_tasks'] ?? 0}', icon: Icons.pending_actions, onTap: () => PortalShell.switchTab(context, 1)),
              StatTile(label: 'In review', value: '${stats['in_review_tasks'] ?? 0}', icon: Icons.rate_review_outlined, onTap: () => PortalShell.switchTab(context, 1)),
              StatTile(label: 'Done', value: '${stats['completed_tasks'] ?? 0}', icon: Icons.task_alt),
              StatTile(label: 'All tasks', value: '${stats['total_tasks'] ?? 0}', icon: Icons.list_alt),
            ]),
            if (me.isProjectManager) ...[
              const SizedBox(height: 14),
              ActionTile(icon: Icons.dashboard_customize_outlined, title: 'Projects I manage', subtitle: 'Tasks, milestones and the team', onTap: () => pOpen(context, const PmProjectsScreen())),
            ],
            const SizedBox(height: 14),
            const SectionLabel('Up next'),
            if (recent.isEmpty)
              const EmptyState(icon: Icons.celebration_outlined, title: 'Nothing waiting', message: 'New tasks assigned to you show here.')
            else
              for (final t in recent) TaskTile(task: t, onChanged: reload),
          ]);
        },
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  final Future<void> Function()? onChanged;
  const TaskTile({super.key, required this.task, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final due = pDate(task['due_date']);
    final late = due != null && due.isBefore(DateTime.now()) && pStr(task['status']) != 'done';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BpCard(
        onTap: () async {
          await pOpen2(context, StaffTaskScreen(taskId: task['id'], title: pStr(task['title'])));
          await onChanged?.call();
        },
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pStr(task['title']), style: tx(context, 13.5, weight: FontWeight.w700)),
              Text(
                [pName(task['project']), if (due != null) 'Due ${Fmt.date(due)}'].where((s) => s.isNotEmpty).join(' · '),
                style: tx(context, 11.5, color: late ? p.error : p.textMuted),
              ),
            ]),
          ),
          StatusPill(genericStatus(pStr(task['status']).isEmpty ? pStr(task['priority']) : pStr(task['status']))),
        ]),
      ),
    );
  }
}

// ===================================================================== tasks

class StaffTasksTab extends StatefulWidget {
  const StaffTasksTab({super.key});

  @override
  State<StaffTasksTab> createState() => _StaffTasksTabState();
}

class _StaffTasksTabState extends State<StaffTasksTab> {
  int _col = 0;

  @override
  Widget build(BuildContext context) {
    return PortalTabPage(
      title: 'My Tasks',
      headerBottom: SegmentedPills(options: [for (final s in _statuses) s.$2], index: _col, onChanged: (i) => setState(() => _col = i)),
      child: AsyncView<Map<String, dynamic>>(
        load: PortalData.kanban,
        builder: (context, board, reload) {
          final tasks = pList(board[_statuses[_col].$1]);
          if (tasks.isEmpty) {
            return ListView(children: [EmptyState(icon: Icons.inbox_outlined, title: 'No tasks in ${_statuses[_col].$2}')]);
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final t in tasks) TaskTile(task: {...t, 'status': _statuses[_col].$1}, onChanged: reload),
          ]);
        },
      ),
    );
  }
}

class StaffTaskScreen extends StatelessWidget {
  final Object taskId;
  final String title;
  const StaffTaskScreen({super.key, required this.taskId, required this.title});

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: title,
      scroll: false,
      body: AsyncView<Map<String, dynamic>>(
        load: () => PortalData.task(taskId),
        builder: (context, t, reload) {
          final status = pStr(t['status']);
          final comments = pList(t['comments']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              child: Column(children: [
                InfoRow(label: 'Project', value: pName(t['project']).isEmpty ? '—' : pName(t['project'])),
                if (pName(t['milestone']).isNotEmpty) InfoRow(label: 'Milestone', value: pName(t['milestone'])),
                InfoRow(label: 'Priority', valueWidget: StatusPill(genericStatus(pStr(t['priority'])))),
                if (pDate(t['due_date']) != null) InfoRow(label: 'Due', value: pDay(t['due_date'])),
                if (pName(t['assigned_by']).isNotEmpty) InfoRow(label: 'Assigned by', value: pName(t['assigned_by'])),
              ]),
            ),
            if (pStr(t['description']).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(pStr(t['description']), style: tx(context, 12.5, color: context.p.textSecondary, height: 1.45)),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Status'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _statuses)
                SelectChip(
                  label: s.$2,
                  selected: status == s.$1,
                  onTap: status == s.$1
                      ? () {}
                      : () async {
                          if (await portalAction(context, () => PortalData.setTaskStatus(taskId, s.$1), done: 'Moved to ${s.$2}')) reload();
                        },
                ),
            ]),
            const SizedBox(height: 6),
            Text('Only a project manager can mark a task Done.', style: tx(context, 11, color: context.p.textMuted)),
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionLabel('Comments'),
              for (final c in comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BpCard(child: Text(pStr(c['body']).isEmpty ? pStr(c['content']) : pStr(c['body']), style: tx(context, 12.5))),
                ),
            ],
          ]);
        },
      ),
    );
  }
}

// ===================================================================== work

class StaffWorkTab extends StatefulWidget {
  const StaffWorkTab({super.key});

  @override
  State<StaffWorkTab> createState() => _StaffWorkTabState();
}

class _StaffWorkTabState extends State<StaffWorkTab> {
  final _key = GlobalKey<AsyncViewState<(Map<String, dynamic>, Map<String, dynamic>)>>();

  Future<(Map<String, dynamic>, Map<String, dynamic>)> _load() async => (await PortalData.workLogs(), await PortalData.attendance());

  @override
  Widget build(BuildContext context) {
    return PortalTabPage(
      title: 'Work',
      child: AsyncView<(Map<String, dynamic>, Map<String, dynamic>)>(
        key: _key,
        load: _load,
        builder: (context, data, reload) {
          final p = context.p;
          final (logs, att) = data;
          final active = logs['active_session'] is Map ? logs['active_session'] as Map<String, dynamic> : null;
          final history = pList(logs['history']);
          final records = pList(att['records']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              color: p.primarySoft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(active == null ? 'No work session running' : 'Session running since ${_hm(active['start_time'])}', style: tx(context, 13.5, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  active == null ? 'Start a session to plan what you’ll work on.' : 'Planned: ${pStr(active['planned_tasks']).isEmpty ? '—' : pStr(active['planned_tasks'])}',
                  style: tx(context, 11.5, color: p.textSecondary),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: active == null ? 'Start Work Session' : 'End Session',
                  variant: active == null ? ButtonVariant.accent : ButtonVariant.outline,
                  onPressed: () async {
                    final done = await pOpen2<bool>(context, active == null ? const StartSessionScreen() : EndSessionScreen(sessionId: active['id']));
                    if (done == true) reload();
                  },
                ),
              ]),
            ),
            const SizedBox(height: 10),
            ActionTile(icon: Icons.edit_note, title: 'Daily reports', subtitle: 'What you did today', onTap: () => pOpen(context, const DailyReportsScreen())),
            const SizedBox(height: 8),
            const SectionLabel('Attendance'),
            if (records.isEmpty)
              const EmptyState(icon: Icons.event_available_outlined, title: 'No attendance yet')
            else
              for (final r in records.take(14))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event_available, color: p.brand),
                  title: Text(pDay(r['date']), style: tx(context, 13, weight: FontWeight.w600)),
                  trailing: Text('${_hm(r['clock_in'])} – ${_hm(r['clock_out'])}', style: tx(context, 12.5, color: p.textSecondary)),
                ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 8),
              const SectionLabel('Past sessions'),
              for (final h in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BpCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${pDay(h['start_time'])} · ${_hm(h['start_time'])} – ${_hm(h['end_time'])}', style: tx(context, 12.5, weight: FontWeight.w700)),
                      if (pStr(h['actual_tasks']).isNotEmpty) Text(pStr(h['actual_tasks']), style: tx(context, 12, color: p.textSecondary)),
                    ]),
                  ),
                ),
            ],
          ]);
        },
      ),
    );
  }
}

/// Check-in: what you plan to work on. Project managers set a session goal instead.
class StartSessionScreen extends StatefulWidget {
  const StartSessionScreen({super.key});

  @override
  State<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends State<StartSessionScreen> {
  final _goal = TextEditingController();
  final _resources = TextEditingController();
  final _projects = <Object>{};
  final _tasks = <String>{};
  bool _busy = false;
  final _pm = portalMe.isProjectManager;

  @override
  void dispose() {
    _goal.dispose();
    _resources.dispose();
    super.dispose();
  }

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _load() async => (await PortalData.projects(), await PortalData.myTasks());

  bool get _valid => _projects.isNotEmpty && (_pm ? _goal.text.trim().isNotEmpty : _tasks.isNotEmpty);

  Future<void> _start() async {
    setState(() => _busy = true);
    final body = _pm
        ? {'planned_projects': _projects.toList(), 'session_goal': _goal.text.trim(), 'no_assignments_planned': true}
        : {'planned_projects': _projects.toList(), 'planned_tasks': _tasks.toList(), 'resources_needed': _resources.text.trim()};
    final ok = await portalAction(context, () => PortalData.startSession(body), done: 'Session started');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'Start Work Session',
      scroll: false,
      bottom: CustomButton(text: 'Start Session', isLoading: _busy, onPressed: _valid && !_busy ? _start : null),
      body: AsyncView<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>(
        load: _load,
        builder: (context, data, _) {
          final (projects, tasks) = data;
          final open = tasks.where((t) => pStr(t['status']) != 'done').toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            const SectionLabel('Projects for this session'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final pr in projects)
                SelectChip(
                  label: pName(pr),
                  selected: _projects.contains(pr['id']),
                  onTap: () => setState(() => _projects.contains(pr['id']) ? _projects.remove(pr['id']) : _projects.add(pr['id'])),
                ),
            ]),
            if (projects.isEmpty) Text('You aren’t on any project yet.', style: tx(context, 12, color: context.p.textMuted)),
            const SizedBox(height: 16),
            if (_pm)
              CustomTextField(label: 'Session goal', hint: 'What should the team achieve?', controller: _goal, maxLines: 3, onChanged: (_) => setState(() {}))
            else ...[
              const SectionLabel('Tasks you’ll work on'),
              for (final t in open)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _tasks.contains(pStr(t['title'])),
                  title: Text(pStr(t['title']), style: tx(context, 13)),
                  subtitle: Text(pName(t['project']), style: tx(context, 11.5, color: context.p.textMuted)),
                  onChanged: (v) => setState(() => v == true ? _tasks.add(pStr(t['title'])) : _tasks.remove(pStr(t['title']))),
                ),
              if (open.isEmpty) Text('No open tasks.', style: tx(context, 12, color: context.p.textMuted)),
              const SizedBox(height: 12),
              CustomTextField(label: 'Anything you need? (optional)', hint: 'Tools, materials, help', controller: _resources),
            ],
          ]);
        },
      ),
    );
  }
}

/// Check-out: what got done. Project managers report issues instead.
class EndSessionScreen extends StatefulWidget {
  final Object sessionId;
  const EndSessionScreen({super.key, required this.sessionId});

  @override
  State<EndSessionScreen> createState() => _EndSessionScreenState();
}

class _EndSessionScreenState extends State<EndSessionScreen> {
  final _done = TextEditingController();
  final _challenges = TextEditingController();
  final _mgmt = TextEditingController();
  bool _needsMgmt = false;
  bool _busy = false;
  final _pm = portalMe.isProjectManager;

  @override
  void dispose() {
    _done.dispose();
    _challenges.dispose();
    _mgmt.dispose();
    super.dispose();
  }

  bool get _valid => _done.text.trim().isNotEmpty && (!_pm || !_needsMgmt || _mgmt.text.trim().isNotEmpty);

  Future<void> _end() async {
    setState(() => _busy = true);
    final body = _pm
        ? {'key_issues': _done.text.trim(), 'requires_mgmt_attention': _needsMgmt, if (_needsMgmt) 'mgmt_attention_details': _mgmt.text.trim()}
        : {'actual_tasks': _done.text.trim(), if (_challenges.text.trim().isNotEmpty) 'challenges': _challenges.text.trim()};
    final ok = await portalAction(context, () => PortalData.endSession(widget.sessionId, body), done: 'Session ended. Good work!');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'End Session',
      bottom: CustomButton(text: 'End Session', isLoading: _busy, onPressed: _valid && !_busy ? _end : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(
          label: _pm ? 'Key issues this session' : 'What did you get done?',
          hint: _pm ? 'Blockers, risks, decisions' : 'e.g. Cut lace for 4 gowns',
          controller: _done,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        if (_pm) ...[
          ToggleRow(title: 'Needs management attention', value: _needsMgmt, onChanged: (v) => setState(() => _needsMgmt = v)),
          if (_needsMgmt) CustomTextField(label: 'What should management know?', hint: 'Details', controller: _mgmt, maxLines: 3, onChanged: (_) => setState(() {})),
        ] else
          CustomTextField(label: 'Challenges (optional)', hint: 'Anything that slowed you down', controller: _challenges, maxLines: 3),
      ]),
    );
  }
}

class DailyReportsScreen extends StatelessWidget {
  const DailyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<AsyncViewState<List<Map<String, dynamic>>>>();
    return InnerScaffold(
      title: 'Daily Reports',
      scroll: false,
      bottom: CustomButton(
        text: 'Write Today’s Report',
        icon: const Icon(Icons.add),
        onPressed: () async {
          if (await pOpen2<bool>(context, const NewReportScreen()) == true) key.currentState?.reload();
        },
      ),
      body: AsyncView<List<Map<String, dynamic>>>(
        key: key,
        load: PortalData.reports,
        isEmpty: (d) => d.isEmpty,
        empty: const EmptyState(icon: Icons.edit_note, title: 'No reports yet', message: 'Write a short report at the end of each day.'),
        builder: (context, reports, _) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final r in reports)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BpCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(pDay(r['created_at']), style: tx(context, 12.5, weight: FontWeight.w800))),
                    if (r['hours_worked'] != null) Text('${pNum(r['hours_worked']).toStringAsFixed(1)} h', style: tx(context, 12, color: context.p.textMuted)),
                  ]),
                  const SizedBox(height: 4),
                  Text(pStr(r['tasks_completed']), style: tx(context, 12.5)),
                  if (pStr(r['tasks_planned']).isNotEmpty) Text('Next: ${pStr(r['tasks_planned'])}', style: tx(context, 12, color: context.p.textSecondary)),
                  if (pStr(r['challenges']).isNotEmpty) Text('Challenges: ${pStr(r['challenges'])}', style: tx(context, 12, color: context.p.textSecondary)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({super.key});

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final _done = TextEditingController();
  final _next = TextEditingController();
  final _challenges = TextEditingController();
  final _hours = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_done, _next, _challenges, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _h => double.tryParse(_hours.text.trim());
  bool get _valid => _done.text.trim().isNotEmpty && (_hours.text.trim().isEmpty || (_h != null && _h! >= 0 && _h! <= 24));

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok = await portalAction(
      context,
      () => PortalData.submitReport({
        'tasks_completed': _done.text.trim(),
        if (_next.text.trim().isNotEmpty) 'tasks_planned': _next.text.trim(),
        if (_challenges.text.trim().isNotEmpty) 'challenges': _challenges.text.trim(),
        'hours_worked': ?_h,
      }),
      done: 'Report submitted',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'Daily Report',
      bottom: CustomButton(text: 'Submit Report', isLoading: _busy, onPressed: _valid && !_busy ? _submit : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'What did you finish today?', hint: 'Tasks completed', controller: _done, maxLines: 4, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(label: 'What’s next? (optional)', hint: 'Plan for tomorrow', controller: _next, maxLines: 3),
        const SizedBox(height: 14),
        CustomTextField(label: 'Challenges (optional)', hint: 'Anything in the way', controller: _challenges, maxLines: 3),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Hours worked (optional)',
          hint: 'e.g. 7.5',
          controller: _hours,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _hours.text.trim().isNotEmpty && !_valid ? 'Enter 0 to 24 hours' : null,
          onChanged: (_) => setState(() {}),
        ),
      ]),
    );
  }
}

// ===================================================================== pay

class StaffPayTab extends StatelessWidget {
  const StaffPayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalTabPage(
      title: 'Pay',
      child: AsyncView<(Map<String, dynamic>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)>(
        load: () async => (await PortalData.wallet(), await PortalData.earnings(), await PortalData.bankAccounts()),
        builder: (context, data, reload) {
          final p = context.p;
          final (wallet, earnings, banks) = data;
          final va = wallet['virtual_account'] is Map ? wallet['virtual_account'] as Map : null;
          final bank = banks.firstOrNull;
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Wallet balance', style: tx(context, 12.5, color: p.textSecondary)),
                const SizedBox(height: 4),
                MoneyText(pNum(wallet['balance']), size: 26),
                if (va != null) ...[
                  const SizedBox(height: 10),
                  InfoRow(
                    label: pStr(va['bank_name']),
                    value: pStr(va['account_number']),
                    bold: true,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: pStr(va['account_number'])));
                      showToast(context, 'Account number copied');
                    },
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: () => pOpen(context, const WalletActivityScreen()), child: const Text('Wallet activity')),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Salary account'),
            BpCard(
              onTap: () async {
                if (await pOpen2<bool>(context, BankAccountScreen(existing: bank)) == true) reload();
              },
              child: Row(children: [
                const LeadingIcon(Icons.account_balance_outlined, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: bank == null
                      ? Text('Add the account your salary is paid into', style: tx(context, 13, weight: FontWeight.w700))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pStr(bank['account_name']), style: tx(context, 13, weight: FontWeight.w700)),
                          Text('${pStr(bank['bank_name'])} · ${pStr(bank['account_number'])}', style: tx(context, 11.5, color: p.textMuted)),
                        ]),
                ),
                Icon(bank == null ? Icons.add : Icons.chevron_right, color: p.textMuted),
              ]),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Earnings'),
            if (earnings.isEmpty)
              const EmptyState(icon: Icons.payments_outlined, title: 'No payments yet', message: 'Salary payments show here.')
            else
              for (final e in earnings)
                RecordTile(
                  leading: const LeadingIcon(Icons.payments_outlined),
                  title: pStr(e['description']).isEmpty ? 'Salary' : pStr(e['description']),
                  subtitle: [pDay(e['payment_date'] ?? e['created_at']), pStr(e['reference'])].where((s) => s.isNotEmpty && s != '—').join(' · '),
                  amount: pNum(e['amount']),
                  status: genericStatus(pStr(e['status'])),
                ),
          ]);
        },
      ),
    );
  }
}

class WalletActivityScreen extends StatelessWidget {
  const WalletActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Wallet activity',
        scroll: false,
        body: AsyncView<List<Map<String, dynamic>>>(
          load: PortalData.walletTransactions,
          isEmpty: (d) => d.isEmpty,
          empty: const EmptyState(icon: Icons.receipt_long_outlined, title: 'No activity yet'),
          builder: (context, txns, _) => ListView(padding: const EdgeInsets.all(16), children: [
            for (final t in txns)
              RecordTile(
                leading: LeadingIcon(pStr(t['type']) == 'debit' ? Icons.north_east : Icons.south_west),
                title: pStr(t['description']).isEmpty ? pLabel(pStr(t['type'])) : pStr(t['description']),
                subtitle: pDay(t['created_at']),
                amount: pNum(t['amount']),
                status: pStr(t['status']).isEmpty ? null : genericStatus(pStr(t['status'])),
              ),
          ]),
        ),
      );
}

/// Add or change the one salary account (verified by name enquiry on the backend).
class BankAccountScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const BankAccountScreen({super.key, this.existing});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  late final _number = TextEditingController(text: pStr(widget.existing?['account_number']));
  late String? _code = widget.existing == null ? null : pStr(widget.existing!['bank_code']);
  String _bankName = '';
  bool _busy = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  bool get _valid => _code != null && RegExp(r'^\d{10}$').hasMatch(_number.text.trim());

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await portalAction(context, () => PortalData.saveBankAccount(widget.existing?['id'], _code!, _bankName, _number.text.trim()), done: 'Account verified and saved');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _remove() async {
    final ok = await showConfirmSheet(context, title: 'Remove this account?', message: 'Salary can’t be paid until you add another one.', confirmLabel: 'Remove');
    if (!ok || !mounted) return;
    if (await portalAction(context, () => PortalData.removeBankAccount(widget.existing!['id']), done: 'Account removed') && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: widget.existing == null ? 'Add Salary Account' : 'Salary Account',
      actions: [if (widget.existing != null) CircleIconButton(icon: Icons.delete_outline, color: context.p.error, tooltip: 'Remove account', onTap: _remove)],
      bottom: CustomButton(text: 'Verify & Save', isLoading: _busy, onPressed: _valid && !_busy ? _save : null),
      scroll: false,
      body: AsyncView<List<Map<String, dynamic>>>(
        load: PortalData.banks,
        builder: (context, banks, _) {
          if (_code != null && _bankName.isEmpty) _bankName = pStr(banks.where((b) => pStr(b['code']) == _code).firstOrNull?['name']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text('Bank', style: tx(context, 12.5, weight: FontWeight.w600, color: context.p.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: banks.any((b) => pStr(b['code']) == _code) ? _code : null,
              isExpanded: true,
              hint: const Text('Select bank'),
              items: [for (final b in banks) DropdownMenuItem(value: pStr(b['code']), child: Text(pStr(b['name'])))],
              onChanged: (v) => setState(() {
                _code = v;
                _bankName = pStr(banks.firstWhere((b) => pStr(b['code']) == v)['name']);
              }),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Account number',
              hint: '10 digits',
              controller: _number,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Text('We check the account name with the bank before saving. You can have one salary account.', style: tx(context, 11.5, color: context.p.textMuted)),
          ]);
        },
      ),
    );
  }
}

// ===================================================================== more

class StaffMoreTab extends StatelessWidget {
  const StaffMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pm = portalMe.isProjectManager;
    return PortalTabPage(
      title: 'More',
      child: ValueListenableBuilder(
        valueListenable: LiveSession.instance.portalAccount,
        builder: (context, _, _) => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          const PortalProfileCard(),
          const SizedBox(height: 16),
          const SectionLabel('Work'),
          ActionTile(icon: Icons.work_outline, title: 'My projects', subtitle: 'Details and project chats', onTap: () => pOpen(context, const _ProjectsScreen())),
          ActionTile(icon: Icons.forum_outlined, title: 'Messages', subtitle: 'Talk to the business', onTap: () => pOpen(context, const SupportChatsScreen())),
          ActionTile(icon: Icons.insights_outlined, title: 'Performance', subtitle: 'Your monthly score', onTap: () => pOpen(context, const PerformanceScreen())),
          if (pm) ...[
            const SizedBox(height: 8),
            const SectionLabel('Project manager'),
            ActionTile(icon: Icons.dashboard_customize_outlined, title: 'Projects I manage', subtitle: 'Assign tasks, set milestones', onTap: () => pOpen(context, const PmProjectsScreen())),
            ActionTile(icon: Icons.history_toggle_off, title: 'Team work sessions', subtitle: 'Check-ins and check-outs', onTap: () => pOpen(context, const PmWorkLogsScreen())),
            ActionTile(icon: Icons.people_outline, title: 'Customers', subtitle: 'On your projects', onTap: () => pOpen(context, const PmListScreen(kind: PmList.clients))),
            ActionTile(icon: Icons.receipt_long_outlined, title: 'Invoices', subtitle: 'Ones you created', onTap: () => pOpen(context, const PmListScreen(kind: PmList.invoices))),
            ActionTile(icon: Icons.request_quote_outlined, title: 'Quotations', subtitle: 'Ones you created', onTap: () => pOpen(context, const PmListScreen(kind: PmList.quotes))),
            ActionTile(icon: Icons.design_services_outlined, title: 'Services', subtitle: 'What the business sells', onTap: () => pOpen(context, const PmListScreen(kind: PmList.services))),
          ],
          const SizedBox(height: 8),
          const SectionLabel('Account'),
          ActionTile(icon: Icons.password, title: 'Change password', onTap: () => pOpen(context, const ChangePasswordScreen())),
          ActionTile(icon: Icons.fingerprint, title: 'Security', subtitle: 'Fingerprint / Face ID', onTap: () => pOpen(context, const SecurityScreen())),
          ActionTile(icon: Icons.contrast, title: 'Appearance', onTap: () => pOpen(context, const AppearanceScreen())),
          ActionTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () => pOpen(context, const HelpSupportScreen())),
          ActionTile(icon: Icons.logout, title: 'Log out', onTap: () => portalLogout(context)),
          ActionTile(icon: Icons.delete_forever_outlined, title: 'Delete my account', danger: true, onTap: () => portalDeleteAccount(context)),
        ]),
      ),
    );
  }
}

class _ProjectsScreen extends StatelessWidget {
  const _ProjectsScreen();

  @override
  Widget build(BuildContext context) => const InnerScaffold(title: 'My projects', scroll: false, body: PortalProjectsList());
}

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Performance',
        scroll: false,
        body: AsyncView<Map<String, dynamic>>(
          load: PortalData.performance,
          builder: (context, d, _) {
            final reviews = pList(d['performance_reviews']);
            final kpis = pList(d['kpis']);
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (reviews.isEmpty) const EmptyState(icon: Icons.insights_outlined, title: 'No reviews yet', message: 'Your monthly score shows here.'),
              for (final r in reviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BpCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            '${_months[((ApiNum.toInt(r['month']) ?? 1) - 1).clamp(0, 11)]} ${pStr(r['year'])}',
                            style: tx(context, 14, weight: FontWeight.w800),
                          ),
                        ),
                        Text('${pNum(r['score']).toStringAsFixed(0)} pts', style: tx(context, 16, weight: FontWeight.w800, color: context.p.brand)),
                      ]),
                      const SizedBox(height: 6),
                      InfoRow(label: 'Tasks completed', value: pStr(r['tasks_completed'])),
                      InfoRow(label: 'Early / late', value: '${pStr(r['tasks_early'])} / ${pStr(r['tasks_late'])}'),
                      InfoRow(label: 'Bonus / penalty points', value: '${pStr(r['bonus_points'])} / ${pStr(r['penalty_points'])}'),
                    ]),
                  ),
                ),
              if (kpis.isNotEmpty) ...[
                const SectionLabel('Targets'),
                for (final k in kpis) InfoRow(label: pStr(k['name']), value: '${pStr(k['target'])}${pStr(k['unit'])}'),
              ],
            ]);
          },
        ),
      );
}

/// Tiny int reader for JSON numbers / strings.
class ApiNum {
  static int? toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
}

// ===================================================================== project manager

class PmProjectsScreen extends StatelessWidget {
  const PmProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Projects I manage',
        scroll: false,
        body: AsyncView<(Map<String, dynamic>, List<Map<String, dynamic>>)>(
          load: () async => (await PortalData.pmDashboard(), await PortalData.pmProjects()),
          builder: (context, data, _) {
            final (stats, projects) = data;
            return ListView(padding: const EdgeInsets.all(16), children: [
              statGrid([
                StatTile(label: 'Projects', value: '${stats['total_projects'] ?? 0}', icon: Icons.work_outline),
                StatTile(label: 'In progress', value: '${stats['active_projects'] ?? 0}', icon: Icons.play_circle_outline),
                StatTile(label: 'Open tasks', value: '${stats['pending_tasks'] ?? 0}', icon: Icons.pending_actions),
                StatTile(label: 'Done tasks', value: '${stats['completed_tasks'] ?? 0}', icon: Icons.task_alt),
              ]),
              const SizedBox(height: 14),
              for (final p in projects) ProjectTile(project: p, onTap: () => pOpen(context, PmProjectScreen(projectId: p['id'], name: pName(p)))),
              if (projects.isEmpty) const EmptyState(icon: Icons.work_outline, title: 'You don’t manage a project yet'),
            ]);
          },
        ),
      );
}

/// Manage one project: tasks (assign, edit, delete) and milestones.
class PmProjectScreen extends StatefulWidget {
  final Object projectId;
  final String name;
  const PmProjectScreen({super.key, required this.projectId, required this.name});

  @override
  State<PmProjectScreen> createState() => _PmProjectScreenState();
}

class _PmProjectScreenState extends State<PmProjectScreen> {
  final _key = GlobalKey<AsyncViewState<Map<String, dynamic>>>();

  Future<void> _task([Map<String, dynamic>? t]) async {
    if (await pOpen2<bool>(context, PmTaskForm(projectId: widget.projectId, task: t)) == true) _key.currentState?.reload();
  }

  Future<void> _milestone([Map<String, dynamic>? m]) async {
    if (await pOpen2<bool>(context, PmMilestoneForm(projectId: widget.projectId, milestone: m)) == true) _key.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: widget.name,
      scroll: false,
      bottom: CustomButton(text: 'New Task', icon: const Icon(Icons.add), onPressed: () => _task()),
      body: AsyncView<Map<String, dynamic>>(
        key: _key,
        load: () => PortalData.pmProject(widget.projectId),
        builder: (context, pr, _) {
          final tasks = pList(pr['tasks']);
          final ms = pList(pr['milestones']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            ActionTile(
              icon: Icons.forum_outlined,
              title: 'Project chats',
              subtitle: 'Team and customer conversations',
              onTap: () => pOpen(context, PortalProjectScreen(projectId: widget.projectId, name: widget.name)),
            ),
            const SizedBox(height: 8),
            SectionLabel('Tasks (${tasks.length})'),
            for (final t in tasks)
              BpCard(
                onTap: () => _task(t),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pStr(t['title']), style: tx(context, 13, weight: FontWeight.w700)),
                      Text([pName(t['assignee']), pLabel(pStr(t['priority']))].where((s) => s.isNotEmpty && s != '—').join(' · '),
                          style: tx(context, 11.5, color: context.p.textMuted)),
                    ]),
                  ),
                  StatusPill(genericStatus(pStr(t['status']))),
                ]),
              ),
            if (tasks.isEmpty) const EmptyState(icon: Icons.task_alt, title: 'No tasks yet'),
            const SizedBox(height: 14),
            SectionLabel('Milestones (${ms.length})', trailing: TextButton(onPressed: () => _milestone(), child: const Text('Add'))),
            for (final m in ms)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _milestone(m),
                leading: Icon(pStr(m['status']) == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked, color: context.p.brand),
                title: Text(pStr(m['title']).isEmpty ? pStr(m['name']) : pStr(m['title']), style: tx(context, 13, weight: FontWeight.w600)),
                subtitle: pDate(m['due_date']) == null ? null : Text('Due ${pDay(m['due_date'])}'),
              ),
          ]);
        },
      ),
    );
  }
}

class PmTaskForm extends StatefulWidget {
  final Object projectId;
  final Map<String, dynamic>? task;
  const PmTaskForm({super.key, required this.projectId, this.task});

  @override
  State<PmTaskForm> createState() => _PmTaskFormState();
}

class _PmTaskFormState extends State<PmTaskForm> {
  late final _title = TextEditingController(text: pStr(widget.task?['title']));
  late final _desc = TextEditingController(text: pStr(widget.task?['description']));
  late Object? _assignee = widget.task?['assigned_to'] ?? (widget.task?['assignee'] is Map ? (widget.task!['assignee'] as Map)['id'] : null);
  late String _priority = const ['low', 'medium', 'high'].contains(pStr(widget.task?['priority'])) ? pStr(widget.task?['priority']) : 'medium';
  late String _status = pStr(widget.task?['status']).isEmpty ? 'todo' : pStr(widget.task?['status']);
  late DateTime? _due = pDate(widget.task?['due_date']);
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _editing => widget.task != null;
  bool get _valid => _title.text.trim().isNotEmpty && _assignee != null;

  String _ymd(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _save() async {
    setState(() => _busy = true);
    final body = {
      if (!_editing) 'project_id': widget.projectId,
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'assigned_to': _assignee,
      'priority': _priority,
      'due_date': _due == null ? null : _ymd(_due!),
      if (_editing) 'status': _status,
    };
    final ok = await portalAction(context, () => PortalData.pmSaveTask(widget.task?['id'], body), done: _editing ? 'Task updated' : 'Task assigned');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showConfirmSheet(context, title: 'Delete this task?', message: 'It’s removed for everyone.', confirmLabel: 'Delete');
    if (!ok || !mounted) return;
    if (await portalAction(context, () => PortalData.pmDeleteTask(widget.task!['id']), done: 'Task deleted') && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: _editing ? 'Edit Task' : 'New Task',
      scroll: false,
      actions: [if (_editing) CircleIconButton(icon: Icons.delete_outline, color: context.p.error, tooltip: 'Delete task', onTap: _delete)],
      bottom: CustomButton(text: _editing ? 'Save Task' : 'Assign Task', isLoading: _busy, onPressed: _valid && !_busy ? _save : null),
      body: AsyncView<List<Map<String, dynamic>>>(
        load: PortalData.pmTeamMembers,
        builder: (context, members, _) => ListView(padding: const EdgeInsets.all(16), children: [
          CustomTextField(label: 'Title', hint: 'What needs doing?', controller: _title, onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          CustomTextField(label: 'Details (optional)', hint: 'Instructions', controller: _desc, maxLines: 3),
          const SizedBox(height: 14),
          Text('Assign to', style: tx(context, 12.5, weight: FontWeight.w600, color: context.p.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Object>(
            initialValue: members.any((m) => m['id'] == _assignee) ? _assignee : null,
            isExpanded: true,
            hint: const Text('Choose a team member'),
            items: [for (final m in members) DropdownMenuItem(value: m['id'], child: Text(pName(m)))],
            onChanged: (v) => setState(() => _assignee = v),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Priority'),
          Wrap(spacing: 8, children: [
            for (final p in const ['low', 'medium', 'high']) SelectChip(label: pLabel(p), selected: _priority == p, onTap: () => setState(() => _priority = p)),
          ]),
          if (_editing) ...[
            const SizedBox(height: 14),
            const SectionLabel('Status'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _statuses) SelectChip(label: s.$2, selected: _status == s.$1, onTap: () => setState(() => _status = s.$1)),
            ]),
          ],
          const SizedBox(height: 14),
          ActionTile(
            icon: Icons.event_outlined,
            title: _due == null ? 'Add a due date' : 'Due ${Fmt.date(_due!)}',
            onTap: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: _due ?? DateTime.now());
              if (d != null) setState(() => _due = d);
            },
          ),
        ]),
      ),
    );
  }
}

class PmMilestoneForm extends StatefulWidget {
  final Object projectId;
  final Map<String, dynamic>? milestone;
  const PmMilestoneForm({super.key, required this.projectId, this.milestone});

  @override
  State<PmMilestoneForm> createState() => _PmMilestoneFormState();
}

class _PmMilestoneFormState extends State<PmMilestoneForm> {
  late final _title = TextEditingController(text: pStr(widget.milestone?['title']).isEmpty ? pStr(widget.milestone?['name']) : pStr(widget.milestone?['title']));
  late final _desc = TextEditingController(text: pStr(widget.milestone?['description']));
  late bool _done = pStr(widget.milestone?['status']) == 'completed';
  late DateTime? _due = pDate(widget.milestone?['due_date']);
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _editing => widget.milestone != null;

  Future<void> _save() async {
    setState(() => _busy = true);
    final body = {
      if (!_editing) 'project_id': widget.projectId,
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'status': _done ? 'completed' : 'pending',
      'due_date': _due?.toIso8601String().substring(0, 10),
    };
    final ok = await portalAction(context, () => PortalData.pmSaveMilestone(widget.milestone?['id'], body), done: 'Milestone saved');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showConfirmSheet(context, title: 'Delete this milestone?', message: 'Tasks stay on the project.', confirmLabel: 'Delete');
    if (!ok || !mounted) return;
    if (await portalAction(context, () => PortalData.pmDeleteMilestone(widget.milestone!['id']), done: 'Milestone deleted') && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: _editing ? 'Edit Milestone' : 'New Milestone',
      actions: [if (_editing) CircleIconButton(icon: Icons.delete_outline, color: context.p.error, tooltip: 'Delete milestone', onTap: _delete)],
      bottom: CustomButton(text: 'Save Milestone', isLoading: _busy, onPressed: _title.text.trim().isEmpty || _busy ? null : _save),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Title', hint: 'e.g. First fitting', controller: _title, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(label: 'Description (optional)', hint: 'What marks it done', controller: _desc, maxLines: 3),
        const SizedBox(height: 10),
        ToggleRow(title: 'Completed', value: _done, onChanged: (v) => setState(() => _done = v)),
        ActionTile(
          icon: Icons.event_outlined,
          title: _due == null ? 'Add a due date' : 'Due ${Fmt.date(_due!)}',
          onTap: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: _due ?? DateTime.now());
            if (d != null) setState(() => _due = d);
          },
        ),
      ]),
    );
  }
}

class PmWorkLogsScreen extends StatelessWidget {
  const PmWorkLogsScreen({super.key});

  @override
  Widget build(BuildContext context) => InnerScaffold(
        title: 'Team work sessions',
        scroll: false,
        body: AsyncView<List<Map<String, dynamic>>>(
          load: PortalData.pmWorkLogs,
          isEmpty: (d) => d.isEmpty,
          empty: const EmptyState(icon: Icons.history_toggle_off, title: 'No sessions yet'),
          builder: (context, logs, _) => ListView(padding: const EdgeInsets.all(16), children: [
            for (final l in logs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BpCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(pName(l['user']).isEmpty ? 'Team member' : pName(l['user']), style: tx(context, 13, weight: FontWeight.w700))),
                      StatusPill(genericStatus(pStr(l['status']))),
                    ]),
                    Text('${pDay(l['start_time'])} · ${_hm(l['start_time'])} – ${_hm(l['end_time'])}', style: tx(context, 11.5, color: context.p.textMuted)),
                    if (pStr(l['planned_tasks']).isNotEmpty) Text('Planned: ${pStr(l['planned_tasks'])}', style: tx(context, 12)),
                    if (pStr(l['actual_tasks']).isNotEmpty) Text('Done: ${pStr(l['actual_tasks'])}', style: tx(context, 12)),
                    if (pStr(l['challenges']).isNotEmpty) Text('Challenges: ${pStr(l['challenges'])}', style: tx(context, 12, color: context.p.textSecondary)),
                  ]),
                ),
              ),
          ]),
        ),
      );
}

enum PmList { clients, invoices, quotes, services }

/// Read-only lists for project managers.
class PmListScreen extends StatelessWidget {
  final PmList kind;
  const PmListScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final (title, load) = switch (kind) {
      PmList.clients => ('Customers', PortalData.pmClients),
      PmList.invoices => ('Invoices', PortalData.pmInvoices),
      PmList.quotes => ('Quotations', PortalData.pmQuotes),
      PmList.services => ('Services', PortalData.pmServices),
    };
    return InnerScaffold(
      title: title,
      scroll: false,
      body: AsyncView<List<Map<String, dynamic>>>(
        load: load,
        isEmpty: (d) => d.isEmpty,
        empty: EmptyState(icon: Icons.inbox_outlined, title: 'No ${title.toLowerCase()} yet'),
        builder: (context, items, _) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final i in items)
            switch (kind) {
              PmList.clients => RecordTile(
                  leading: InitialsAvatar(pName(i), size: 36),
                  title: pName(i),
                  subtitle: [pStr(i['email']), pStr(i['phone'])].where((s) => s.isNotEmpty).join(' · '),
                  amount: 0,
                ),
              PmList.invoices || PmList.quotes => RecordTile(
                  leading: const LeadingIcon(Icons.receipt_long_outlined),
                  title: pStr(i[kind == PmList.invoices ? 'invoice_number' : 'quote_number']),
                  subtitle: '${pStr(i['client_name']).isEmpty ? pName(i['client']) : pStr(i['client_name'])} · ${pDay(i['issue_date'])}',
                  amount: pNum(i['total_amount']),
                  status: genericStatus(pStr(i['status'])),
                  onTap: () => pOpen(context, PortalDocumentScreen(id: i['id'], quote: kind == PmList.quotes)),
                ),
              PmList.services => RecordTile(
                  leading: const LeadingIcon(Icons.design_services_outlined),
                  title: pName(i),
                  subtitle: pName(i['category']),
                  amount: pNum(i['base_price'] ?? i['price']),
                ),
            },
        ]),
      ),
    );
  }
}

/// Invoice or quotation with its items (staff PMs and customers).
class PortalDocumentScreen extends StatelessWidget {
  final Object id;
  final bool quote;
  final List<Widget> Function(BuildContext context, Map<String, dynamic> doc)? actions;
  const PortalDocumentScreen({super.key, required this.id, this.quote = false, this.actions});

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: quote ? 'Quotation' : 'Invoice',
      scroll: false,
      body: AsyncView<Map<String, dynamic>>(
        load: () => quote ? PortalData.quote(id) : PortalData.invoice(id),
        builder: (context, d, _) {
          final p = context.p;
          final items = pList(d['items']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(pStr(d[quote ? 'quote_number' : 'invoice_number']), style: tx(context, 15, weight: FontWeight.w800))),
                  StatusPill(genericStatus(pStr(d['status']))),
                ]),
                const SizedBox(height: 8),
                MoneyText(pNum(d['total_amount']), size: 24),
                const SizedBox(height: 6),
                Text(
                  quote ? 'Issued ${pDay(d['issue_date'])} · Valid until ${pDay(d['valid_until'])}' : 'Issued ${pDay(d['issue_date'])} · Due ${pDay(d['due_date'])}',
                  style: tx(context, 11.5, color: p.textMuted),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Items'),
            for (final it in items)
              InfoRow(
                label: '${pStr(it['title']).isEmpty ? pStr(it['description']) : pStr(it['title'])} × ${pNum(it['quantity']).toStringAsFixed(pNum(it['quantity']) % 1 == 0 ? 0 : 2)}',
                value: Fmt.money(pNum(it['total']) > 0 ? pNum(it['total']) : pNum(it['quantity']) * pNum(it['unit_price'])),
              ),
            if (items.isEmpty) Text('No items listed.', style: tx(context, 12, color: p.textMuted)),
            if (pNum(d['discount_amount']) > 0) InfoRow(label: 'Discount', value: '-${Fmt.money(pNum(d['discount_amount']))}'),
            if (pNum(d['tax_amount']) > 0) InfoRow(label: 'Tax', value: Fmt.money(pNum(d['tax_amount']))),
            InfoRow(label: 'Total', value: Fmt.money(pNum(d['total_amount'])), bold: true),
            if (pStr(d['notes']).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(pStr(d['notes']), style: tx(context, 12, color: p.textSecondary)),
            ],
            if (actions != null) ...[const SizedBox(height: 16), ...actions!(context, d)],
          ]);
        },
      ),
    );
  }
}

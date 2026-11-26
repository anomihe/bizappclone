import 'package:flutter/material.dart';
import '../../core/api/live_session.dart';
import '../../core/api/resources.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/ui_kit.dart';
import '../workspace/workspace_screens.dart';
import 'portal_kit.dart';

/// Projects the staff member works on, or the customer's projects.
class PortalProjectsList extends StatelessWidget {
  const PortalProjectsList({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Map<String, dynamic>>>(
      load: PortalData.projects,
      isEmpty: (d) => d.isEmpty,
      empty: const EmptyState(icon: Icons.work_outline, title: 'No projects yet', message: 'Projects you’re part of show here.'),
      builder: (context, projects, _) => ListView(padding: const EdgeInsets.all(16), children: [
        for (final p in projects) ProjectTile(project: p, onTap: () => pOpen(context, PortalProjectScreen(projectId: p['id'], name: pName(p)))),
      ]),
    );
  }
}

class ProjectTile extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;
  const ProjectTile({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final who = LiveSession.instance.role == AccountRole.customer ? pName(project['manager']) : pName(project['client']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BpCard(
        onTap: onTap,
        child: Row(children: [
          const LeadingIcon(Icons.work_outline, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pName(project), style: tx(context, 13.5, weight: FontWeight.w700)),
              if (who.isNotEmpty) Text(who, style: tx(context, 11.5, color: p.textMuted)),
            ]),
          ),
          StatusPill(genericStatus(pStr(project['status']))),
        ]),
      ),
    );
  }
}

/// Project details: dates, milestones, tasks and the chats this person may use.
class PortalProjectScreen extends StatelessWidget {
  final Object projectId;
  final String name;
  const PortalProjectScreen({super.key, required this.projectId, required this.name});

  @override
  Widget build(BuildContext context) {
    final customer = LiveSession.instance.role == AccountRole.customer;
    return InnerScaffold(
      title: name,
      scroll: false,
      body: AsyncView<Map<String, dynamic>>(
        load: () => PortalData.project(projectId),
        builder: (context, pr, _) {
          final milestones = pList(pr['milestones']);
          final tasks = pList(pr['tasks']);
          return ListView(padding: const EdgeInsets.all(16), children: [
            BpCard(
              child: Column(children: [
                InfoRow(label: 'Status', valueWidget: StatusPill(genericStatus(pStr(pr['status'])))),
                if (pName(pr['client']).isNotEmpty && !customer) InfoRow(label: 'Customer', value: pName(pr['client'])),
                if (pName(pr['manager']).isNotEmpty) InfoRow(label: 'Project manager', value: pName(pr['manager'])),
                if (pDate(pr['start_date']) != null) InfoRow(label: 'Starts', value: pDay(pr['start_date'])),
                if (pDate(pr['end_date']) != null) InfoRow(label: 'Due', value: pDay(pr['end_date'])),
              ]),
            ),
            if (pStr(pr['description']).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(pStr(pr['description']), style: tx(context, 12.5, color: context.p.textSecondary, height: 1.45)),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Chat'),
            if (!customer)
              ActionTile(
                icon: Icons.forum_outlined,
                title: 'Team chat',
                subtitle: 'Only the team',
                onTap: () => pOpen(context, ProjectChatScreen(projectId: projectId, projectName: name, type: ChatType.team)),
              ),
            ActionTile(
              icon: Icons.support_agent,
              title: customer ? 'Chat with the team' : 'Customer chat',
              subtitle: customer ? 'Ask about progress, send photos' : 'Talk with ${pName(pr['client']).isEmpty ? 'the customer' : pName(pr['client'])}',
              onTap: () => pOpen(context, ProjectChatScreen(projectId: projectId, projectName: name, type: ChatType.client)),
            ),
            if (milestones.isNotEmpty) ...[
              const SizedBox(height: 8),
              const SectionLabel('Milestones'),
              for (final m in milestones)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(pStr(m['status']) == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked, color: context.p.brand),
                  title: Text(pStr(m['title']).isEmpty ? pStr(m['name']) : pStr(m['title']), style: tx(context, 13, weight: FontWeight.w600)),
                  subtitle: pDate(m['due_date']) == null ? null : Text('Due ${pDay(m['due_date'])}', style: tx(context, 11.5, color: context.p.textMuted)),
                ),
            ],
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              SectionLabel(customer ? 'Recent work' : 'Tasks'),
              for (final t in tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(pStr(t['title']), style: tx(context, 13, weight: FontWeight.w600)),
                  subtitle: pName(t['assignee']).isEmpty ? null : Text(pName(t['assignee']), style: tx(context, 11.5, color: context.p.textMuted)),
                  trailing: StatusPill(genericStatus(pStr(t['status']))),
                ),
            ],
          ]);
        },
      ),
    );
  }
}

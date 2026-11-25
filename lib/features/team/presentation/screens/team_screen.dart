import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../store/presentation/widgets/store_widgets.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final owner = store.owner;
        final admins = store.staff.where((s) => s.role == StaffRole.administrator).toList();
        final employees = store.staff.where((s) => s.role != StaffRole.administrator && s.role != StaffRole.owner).toList();

        Widget tile(StaffMember m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BpCard(
                onTap: m.role == StaffRole.owner ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffMemberScreen(member: m))),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(children: [
                  InitialsAvatar(m.name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 13.5, weight: FontWeight.w700)),
                      Text(
                        m.role == StaffRole.owner ? 'You' : '${roleLabel(m.role)} · ${m.status == StaffStatus.invited ? 'Invite sent' : Fmt.ago(m.lastActive)}',
                        style: tx(context, 11.5, color: p.textMuted),
                      ),
                    ]),
                  ),
                  StatusPill(m.role == StaffRole.owner ? BizStatus.owner : BizStatus.staff(m.status)),
                  if (m.role != StaffRole.owner) Icon(Icons.chevron_right, color: p.textMuted),
                ]),
              ),
            );

        return InnerScaffold(
          title: 'Team',
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteStaffScreen())),
              icon: Icon(Icons.person_add_alt_outlined, size: 17, color: p.brand),
              label: Text('Invite Staff', style: tx(context, 12.5, weight: FontWeight.w700, color: p.brand)),
            ),
          ],
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (owner != null) tile(owner),
            const SizedBox(height: 8),
            if (admins.isNotEmpty) ...[const SectionLabel('Administrators'), ...admins.map(tile), const SizedBox(height: 8)],
            const SectionLabel('Employees'),
            if (employees.isEmpty)
              const EmptyState(icon: Icons.groups_outlined, title: 'No staff yet', message: 'Invite staff and choose what each person can use.')
            else
              ...employees.map(tile),
          ]),
        );
      },
    );
  }
}

class _PermissionToggles extends StatelessWidget {
  final Set<Permission> value;
  final ValueChanged<Set<Permission>>? onChanged;
  const _PermissionToggles({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BpCard(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      child: Column(children: [
        for (final perm in Permission.values)
          ToggleRow(
            title: permissionLabels[perm]!,
            value: value.contains(perm),
            onChanged: onChanged == null ? null : (on) => onChanged!(on ? ({...value, perm}) : ({...value}..remove(perm))),
          ),
      ]),
    );
  }
}

Future<StaffRole?> _pickRole(BuildContext context, StaffRole current) => showBpSheet<StaffRole>(
      context,
      title: 'Select New Role',
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        for (final r in [StaffRole.administrator, StaffRole.manager, StaffRole.cashier, StaffRole.accountant])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BpCard(
              onTap: () => Navigator.pop(ctx, r),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Expanded(child: Text(roleLabel(r), style: tx(ctx, 13.5, weight: FontWeight.w600))),
                if (r == current) Icon(Icons.check_circle, size: 20, color: ctx.p.brand),
              ]),
            ),
          ),
      ]),
    );

class StaffMemberScreen extends StatelessWidget {
  final StaffMember member;
  const StaffMemberScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final m = member;
        final active = m.status != StaffStatus.deactivated;

        Future<void> remove() async {
          final ok = await showConfirmSheet(
            context,
            title: 'Remove ${m.name}?',
            message: 'They are logged out of every device straight away. Their invoices and history stay on the account.',
            confirmLabel: 'Remove',
            cancelLabel: 'Cancel',
          );
          if (ok && context.mounted) {
            store.removeStaff(m);
            Navigator.pop(context);
            showToast(context, '${m.name} removed from team');
          }
        }

        return InnerScaffold(
          title: 'Staff Member',
          titleTrailing: StatusPill(BizStatus.staff(m.status)),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            CustomButton(
              text: active ? 'Deactivate Access' : 'Reactivate Access',
              variant: active ? ButtonVariant.outline : ButtonVariant.primary,
              onPressed: () {
                m.status = active ? StaffStatus.deactivated : StaffStatus.active;
                store.updateStaff(m);
                showToast(context, active ? 'Access paused — they can’t sign in' : 'Access restored');
              },
            ),
            const SizedBox(height: 10),
            Material(
              color: p.errorSoft,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: remove,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 48,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.person_remove_outlined, size: 18, color: p.error),
                    const SizedBox(width: 6),
                    Text('Remove from Team', style: tx(context, 14, weight: FontWeight.w700, color: p.error)),
                  ]),
                ),
              ),
            ),
          ]),
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: InitialsAvatar(m.name, size: 64)),
            const SizedBox(height: 8),
            Text(m.name, textAlign: TextAlign.center, style: tx(context, 16, weight: FontWeight.w800)),
            Text([m.phone, m.email].where((s) => s.isNotEmpty).join(' · '), textAlign: TextAlign.center, style: tx(context, 12, color: p.textMuted)),
            Text(roleLabel(m.role).toUpperCase(), textAlign: TextAlign.center, style: tx(context, 11, weight: FontWeight.w700, color: p.textSecondary).copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 16),
            const SectionLabel('Role'),
            BpCard(
              onTap: !active
                  ? null
                  : () async {
                      final r = await _pickRole(context, m.role);
                      if (r != null && r != m.role) {
                        m
                          ..role = r
                          ..permissions = defaultPermissions(r);
                        store.updateStaff(m);
                      }
                    },
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Expanded(child: Text(roleLabel(m.role), style: tx(context, 13.5, weight: FontWeight.w600, color: active ? p.text : p.textMuted))),
                Icon(Icons.swap_vert, size: 18, color: p.textMuted),
              ]),
            ),
            const SizedBox(height: 16),
            if (m.isAdmin) ...[
              const SectionLabel('Access'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: p.brand),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Administrators can use every module except wallet and billing.', style: tx(context, 12, color: p.textSecondary))),
                ]),
              ),
            ] else ...[
              const SectionLabel('Can use'),
              _PermissionToggles(
                value: m.permissions,
                onChanged: !active
                    ? null
                    : (v) {
                        m.permissions = v;
                        store.updateStaff(m);
                      },
              ),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Activity Summary'),
            BpCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: [
                InfoRow(label: 'Invoices created', value: '${m.invoicesCreated}'),
                InfoRow(label: 'Payments handled', value: '${m.paymentsHandled}'),
                InfoRow(label: 'Last active', value: m.status == StaffStatus.invited ? 'Not joined yet' : Fmt.ago(m.lastActive)),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Removing someone ends their sessions on all devices and keeps their history.', textAlign: TextAlign.center, style: tx(context, 11, color: p.textMuted)),
          ]),
        );
      },
    );
  }
}

class InviteStaffScreen extends StatefulWidget {
  const InviteStaffScreen({super.key});

  @override
  State<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends State<InviteStaffScreen> {
  final _contact = TextEditingController();
  StaffRole _role = StaffRole.manager;
  Set<Permission> _perms = defaultPermissions(StaffRole.manager);
  bool _loading = false;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  bool get _valid {
    final v = _contact.text.trim();
    return Fmt.isEmail(v) || v.replaceAll(RegExp(r'\D'), '').length >= 10;
  }


  /// The API needs a password for new staff; show the generated one once so
  /// the owner can pass it on.
  Future<void> _showTempPassword(String email, String password) => showBpSheet(
        context,
        showHandle: true,
        builder: (ctx) {
          final p = ctx.p;
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(Icons.key_outlined, size: 36, color: p.brand),
            const SizedBox(height: 10),
            Text('Staff login created', textAlign: TextAlign.center, style: tx(ctx, 16, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Share this temporary password with $email. It is shown only once; they can change it after logging in.',
                textAlign: TextAlign.center, style: tx(ctx, 12.5, color: p.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
              child: SelectableText(password, textAlign: TextAlign.center, style: tx(ctx, 18, weight: FontWeight.w800)),
            ),
            const SizedBox(height: 14),
            CustomButton(
              text: 'Copy Password',
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: password));
                showToast(ctx, 'Password copied');
              },
            ),
            const SizedBox(height: 10),
            CustomButton(text: 'Done', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          ]);
        },
      );
  Future<void> _send() async {
    setState(() => _loading = true);
    if (LiveSession.enabled) {
      final contact = _contact.text.trim();
      if (!Fmt.isEmail(contact)) {
        setState(() => _loading = false);
        showToast(context, 'Enter the staff member’s email — Bizpaddi creates their login with it');
        return;
      }
      try {
        final m = StaffMember(
          id: 'new-${DateTime.now().microsecondsSinceEpoch}',
          name: contact.split('@').first,
          email: contact,
          role: _role,
          permissions: _perms,
          lastActive: DateTime.now(),
        );
        final password = await LiveSession.instance.inviteStaff(m);
        if (!mounted) return;
        await _showTempPassword(contact, password);
        if (mounted) Navigator.pop(context);
      } on ApiException catch (e) {
        if (mounted) showToast(context, e.message);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    BizStore.instance.inviteStaff(contact: _contact.text.trim(), role: _role, permissions: _perms);
    showToast(context, 'Invite sent');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InnerScaffold(
      title: 'Invite staff',
      bottom: CustomButton(text: 'Send Invite', isLoading: _loading, onPressed: _valid && _perms.isNotEmpty ? _send : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Phone Number or Email', hint: 'Enter phone or email', controller: _contact, keyboardType: TextInputType.emailAddress, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        Text('Role', style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final r in [StaffRole.manager, StaffRole.cashier, StaffRole.accountant])
            SelectChip(
              label: roleLabel(r),
              selected: _role == r,
              onTap: () => setState(() {
                _role = r;
                _perms = defaultPermissions(r);
              }),
            ),
        ]),
        const SizedBox(height: 16),
        Text('What can they use?', style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
        const SizedBox(height: 8),
        _PermissionToggles(value: _perms, onChanged: (v) => setState(() => _perms = v)),
      ]),
    );
  }
}

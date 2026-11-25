import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/ui_kit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final store = BizStore.instance;

  @override
  void dispose() {
    // Opening the list counts as reading it.
    store.markAllRead();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final list = store.notifications;
    return InnerScaffold(
      title: 'Notifications',
      scroll: false,
      bodyPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      body: list.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'No notifications',
                message: 'Come back later we got something cooking.',
              ),
            )
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return Opacity(
                  opacity: n.read ? 0.55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BpCard(
                      onTap: n.read ? null : () => setState(() => store.markRead(n)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        LeadingIcon(
                          switch (n.type) {
                            NotificationType.payment => Icons.payments_outlined,
                            NotificationType.invoice => Icons.receipt_long_outlined,
                            NotificationType.system => Icons.campaign_outlined,
                          },
                          color: n.type == NotificationType.payment ? AppColors.primary : p.textSecondary,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n.title, style: tx(context, 13.5, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(n.body, style: tx(context, 12, color: p.textSecondary)),
                          ]),
                        ),
                        Text(Fmt.ago(n.time), style: tx(context, 11, color: p.textMuted)),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/theme_toggle.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/presentation/screens/welcome_back_screen.dart';
import '../../../business/presentation/screens/business_profile_screen.dart';
import '../../../invoices/presentation/screens/invoices_tab.dart';
import '../../../invoices/presentation/screens/payment_link_details_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../store/presentation/screens/store_screen.dart';
import '../../../support/presentation/screens/about_screen.dart';
import '../../../support/presentation/screens/help_support_screen.dart';
import '../../../team/presentation/screens/team_screen.dart';
import 'coming_soon_screen.dart';
import 'settings_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showBpSheet<bool>(
      context,
      showHandle: true,
      builder: (ctx) {
        final p = ctx.p;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle), child: Icon(Icons.logout, color: p.brand)),
          const SizedBox(height: 12),
          Text('Log out?', style: tx(ctx, 16, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Are you sure you want to log out of your Bizpaddi account?', textAlign: TextAlign.center, style: tx(ctx, 12.5, color: p.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: CustomButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 10),
            Expanded(child: CustomButton(text: 'Log Out', variant: ButtonVariant.accent, onPressed: () => Navigator.pop(ctx, true))),
          ]),
        ]);
      },
    );
    if (ok != true || !context.mounted) return;
    BizStore.instance.logOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeBackScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final owner = store.owner;
        final newOrders = store.newOrderCount;

        Widget section(String title, List<Widget> tiles) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionLabel(title), ...tiles]),
            );

        Widget badge(String text) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(6)),
              child: Text(text, style: tx(context, 10.5, weight: FontWeight.w700, color: p.readable(const Color(0xFFB07400)))),
            );

        return Column(children: [
          const TabHeader(title: 'More', trailing: ThemeToggleButton()),
          Expanded(
            child: TabPanel(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
                // Business card → Business Profile
                BpCard(
                  onTap: () => open(const BusinessProfileScreen()),
                  borderColor: p.border,
                  child: Row(children: [
                    InitialsAvatar(store.account.businessName, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.account.businessName, style: tx(context, 14, weight: FontWeight.w800)),
                        Text('Owner · ${owner?.email.isNotEmpty == true ? owner!.email : store.account.email}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 11.5, color: p.textMuted)),
                      ]),
                    ),
                    Icon(Icons.chevron_right, color: p.textMuted),
                  ]),
                ),
                const SizedBox(height: 16),
                section('Sales', [
                  ActionTile(icon: Icons.request_quote_outlined, title: 'Quotations', subtitle: 'Create and track quotes', onTap: () => open(const QuotationsScreen())),
                  ActionTile(icon: Icons.link, title: 'Payment links', subtitle: 'Links to get paid', onTap: () => open(const PaymentLinksScreen())),
                ]),
                section('Store', [
                  ActionTile(icon: Icons.storefront_outlined, title: 'Store Front & Products', subtitle: 'Your online shop', onTap: () => open(const StoreScreen())),
                  ActionTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Orders',
                    subtitle: 'Track and fulfil orders',
                    trailing: newOrders > 0 ? badge('$newOrders New Order${newOrders == 1 ? '' : 's'}') : null,
                    onTap: () => open(const OrdersScreen()),
                  ),
                ]),
                section('Manage', [
                  ActionTile(icon: Icons.groups_outlined, title: 'Team', subtitle: 'Invite staff and set roles', onTap: () => open(const TeamScreen())),
                  ActionTile(icon: Icons.insights_outlined, title: 'Reports', subtitle: 'Revenue and payment insights', onTap: () => open(const ReportsScreen())),
                  ActionTile(icon: Icons.account_balance_wallet_outlined, title: 'Wallet & Billings', subtitle: 'Balance and subscription', onTap: () => open(const ComingSoonScreen(title: 'Wallet & Billings'))),
                ]),
                section('Account', [
                  ActionTile(
                    icon: Icons.storefront,
                    title: 'Business Profile',
                    subtitle: 'Name, logo, contact details',
                    trailing: switch (store.profile.verification) {
                      VerificationStatus.inReview => badge('In Review'),
                      VerificationStatus.incomplete => badge('Incomplete'),
                      VerificationStatus.verified => null,
                    },
                    onTap: () => open(const BusinessProfileScreen()),
                  ),
                  ActionTile(icon: Icons.shield_outlined, title: 'Security', subtitle: 'Password, biometrics, sessions', onTap: () => open(const SecurityScreen())),
                  ActionTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Appearance and notifications', onTap: () => open(const SettingsScreen())),
                ]),
                section('Support', [
                  ActionTile(icon: Icons.headset_mic_outlined, title: 'Help and Support', subtitle: 'Got Questions, Chat with us', onTap: () => open(const HelpSupportScreen())),
                  ActionTile(icon: Icons.info_outline, title: 'About Us', subtitle: 'Privacy policy, terms', onTap: () => open(const AboutScreen())),
                ]),
                const SizedBox(height: 4),
                Material(
                  color: p.errorSoft,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _logout(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.logout, size: 18, color: p.error),
                        const SizedBox(width: 8),
                        Text('Log Out', style: tx(context, 14, weight: FontWeight.w700, color: p.error)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}

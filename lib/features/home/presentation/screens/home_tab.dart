import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/api/mappers.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/calendar_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/theme_toggle.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../billing/billing_screen.dart';
import '../../../business/presentation/screens/business_profile_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../payments/presentation/screens/payment_details_screen.dart';
import '../../../invoices/presentation/widgets/invoice_sheets.dart';
import '../widgets/revenue_chart.dart';
import 'main_navigation_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final store = BizStore.instance;
  int _period = 0; // 0: 7d, 1: 30d, 2: 90d, 3: custom
  DateTimeRange? _custom;
  int _trend = 0; // 0: 7 days, 1: 30 days
  bool _firstInvoiceDismissed = false;

  (DateTime, DateTime?) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      0 => (today.subtract(const Duration(days: 6)), null),
      1 => (today.subtract(const Duration(days: 29)), null),
      2 => (today.subtract(const Duration(days: 89)), null),
      _ => (_custom!.start, _custom!.end.add(const Duration(days: 1))),
    };
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _pickCustom() async {
    final r = await showDateRangeSheet(context, initial: _custom, title: 'Custom');
    if (r != null) {
      setState(() {
        _custom = r;
        _period = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        backgroundColor: context.p.bg,
        floatingActionButton: const CreateNewFab(),
        // Figma: the cream → mint gradient sits behind the whole dashboard and
        // stays put while the white cards scroll over it.
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: context.p.screenGradient),
          child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(
            child: ContentWidth(
              maxWidth: Breakpoints.dashboard,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                child: LayoutBuilder(builder: (context, c) => _body(c.maxWidth)),
              ),
            ),
          ),
        ]),
        ),
      ),
    );
  }

  /// Phone: one column, as designed. ≥600: KPIs in one row of four.
  /// ≥900: money on the left, trend + activity on the right.
  Widget _body(double width) {
    const gap = SizedBox(height: 12);
    final top = <Widget>[
      _banner(),
      if (store.invoices.isEmpty && !_firstInvoiceDismissed) _firstInvoiceCard(),
      _walletCard(),
      gap,
      _periodChips(),
      gap,
    ];
    final money = <Widget>[_collectedCard(), gap, _kpiGrid(wide: width >= 600 && width < 900), gap, _settledCard()];
    final activity = <Widget>[
      _trendCard(),
      if (store.overdueCount > 0 || store.ordersToFulfil > 0) ...[gap, _attentionCard()],
      const SizedBox(height: 16),
      _recent(),
    ];

    if (width >= 900) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ...top,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: money)),
          const SizedBox(width: 16),
          Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: activity)),
        ]),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...top, ...money, gap, ...activity]);
  }

  // ------------------------------------------------------------ sections

  Widget _header() {
    final p = context.p;
    final a = store.account;
    return Container(
      // Transparent: the screen gradient shows through.
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: Breakpoints.dashboard,
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(children: [
            InitialsAvatar(a.ownerFullName, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$_greeting, ${a.ownerFirstName}', style: tx(context, 11.5, color: p.textSecondary)),
                Text(a.businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 16, weight: FontWeight.w800)),
              ]),
            ),
            // On wide layouts the toggle lives in the side rail instead.
            if (!context.isExpanded) ...[const ThemeToggleButton(), const SizedBox(width: 8)],
            Stack(clipBehavior: Clip.none, children: [
              CircleIconButton(
                icon: Icons.notifications_none,
                background: AppColors.primary,
                color: Colors.white,
                tooltip: 'Notifications',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (store.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(width: 9, height: 9, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
                ),
            ]),
          ]),
        ),
        ),
      ),
    );
  }

  Widget _banner() {
    if (store.bannerDismissed) return const SizedBox.shrink();
    final a = store.account;
    final (String title, String body, String action, bool danger) = switch (a.plan) {
      PlanStatus.trial when a.verified => ('Free trial: ${a.trialDaysLeft} days left', "Try everything. Upgrade when you're ready.", 'View Plan', false),
      PlanStatus.trial || PlanStatus.active when !a.verified => ('Verify your business', 'Verify your business to unlock payouts and remove limits.', 'Verify Now', false),
      PlanStatus.endingSoon => ('Your plan ends in 3 days', 'Renew now to keep creating invoices.', 'Renew Now', false),
      PlanStatus.grace => ('Grace period: 3 days left', "You can still edit and share invoices, but you can't create new ones.", 'Renew Now', false),
      PlanStatus.expired => ('Your plan has ended', "You can view and share old invoices, but you can't create new ones.", 'Renew Now', true),
      _ => ('', '', '', false),
    };
    if (title.isEmpty) return const SizedBox.shrink();
    // iOS can't point to paying outside the App Store; the billing screen is read-only there.
    final actionLabel = action == 'Renew Now' && !BillingScreen.canPay ? 'View Plan' : action;
    final p = context.p;
    final c = danger ? AppColors.error : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: danger ? p.errorSoft : p.accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tx(context, 13, weight: FontWeight.w800, color: danger ? AppColors.error : null)),
              const SizedBox(height: 2),
              Text(body, style: tx(context, 11.5, color: p.textSecondary, height: 1.35)),
            ]),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => action == 'Verify Now' ? const BusinessProfileScreen() : const BillingScreen())),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF111916),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionLabel, style: tx(context, 11.5, weight: FontWeight.w700, color: const Color(0xFF111916))),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, size: 16, color: danger ? AppColors.error : p.textSecondary),
            onPressed: store.dismissBanner,
          ),
        ]),
      ),
    );
  }

  Widget _firstInvoiceCard() {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BpCard(
        color: p.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Create your first invoice', style: tx(context, 14, weight: FontWeight.w800))),
            InkWell(onTap: () => setState(() => _firstInvoiceDismissed = true), child: Icon(Icons.close, size: 18, color: p.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Text('It takes under a minute. Add a customer, add what they bought, then share the pay link on WhatsApp.',
              style: tx(context, 12, color: p.textSecondary, height: 1.4)),
          const SizedBox(height: 12),
          CustomButton(text: 'Create Invoice', height: 42, onPressed: () => CreateActions.newInvoice(context)),
        ]),
      ),
    );
  }

  Widget _walletCard() {
    final p = context.p;
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: LiveSession.instance.billing,
      builder: (context, billing, _) {
        final balance = ApiMappers.num0(billing?['wallet_balance']);
        final payg = ApiMappers.str(billing?['billing_model']) != 'subscription';
        final sub = billing?['subscription'] is Map ? billing!['subscription'] as Map : null;
        final planName = ApiMappers.str((sub?['plan'] as Map?)?['name']);
        final modeLabel = payg ? 'Pay as you go' : (planName.isEmpty ? 'Subscription' : planName);

        return BpCard(
          color: p.card,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen())),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            LeadingIcon(Icons.account_balance_wallet_outlined, color: p.brand, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Operating Wallet · $modeLabel', style: tx(context, 11.5, color: p.textSecondary)),
                const SizedBox(height: 2),
                MoneyText(balance, size: 20),
              ]),
            ),
            if (BillingScreen.canPay)
              FilledButton.icon(
                onPressed: () => BillingScreen.topUp(context),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Top Up', style: tx(context, 12.5, weight: FontWeight.w700, color: Colors.white)),
                style: FilledButton.styleFrom(
                  backgroundColor: p.brand,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              Icon(Icons.chevron_right, color: p.textSecondary),
          ]),
        );
      },
    );
  }

  Widget _periodChips() {
    final customLabel = _custom == null
        ? 'Custom'
        : '${Fmt.dateNumeric(_custom!.start)} – ${Fmt.dateNumeric(_custom!.end)}';
    return SizedBox(
      height: 34,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final (i, label) in [(0, '7 Days'), (1, '30 Days'), (2, '90 Days')])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SelectChip(label: label, selected: _period == i, onTap: () => setState(() => _period = i)),
          ),
        SelectChip(label: customLabel, icon: Icons.calendar_today_outlined, selected: _period == 3, onTap: _pickCustom),
      ]),
    );
  }

  Widget _collectedCard() {
    final (from, to) = _range;
    final total = store.collected(from, to);
    final today = store.todaysCollected();
    return Container(
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Text('Collected · Paid by Customer', style: tx(context, 12, weight: FontWeight.w600, color: Colors.white)),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.p.card, borderRadius: BorderRadius.circular(11)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MoneyText(total, size: 26),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              TextSpan(text: "Today's collections ", style: tx(context, 11.5, color: context.p.textSecondary)),
              TextSpan(text: '+${Fmt.money(today)}', style: tx(context, 11.5, weight: FontWeight.w700, color: context.p.brand)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _kpiGrid({bool wide = false}) {
    Widget kpi(IconData icon, Color color, String label, Widget value, VoidCallback onTap) => Expanded(
          child: BpCard(
            color: context.p.card,
            onTap: onTap,
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.p.border)),
                  child: Icon(Icons.north_east, size: 13, color: context.p.textSecondary),
                ),
              ]),
              const SizedBox(height: 10),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 11.5, color: context.p.textSecondary)),
              const SizedBox(height: 2),
              value,
            ]),
          ),
        );

    final items = [
      kpi(Icons.account_balance_wallet_outlined, AppColors.primaryLight, 'Outstanding', MoneyText(store.outstanding, size: 15),
          () => MainNavigationScreen.switchTab(context, 2)),
      kpi(Icons.error_outline, AppColors.error, 'Overdue', MoneyText(store.overdue, size: 15), () => MainNavigationScreen.switchTab(context, 2)),
      kpi(Icons.hourglass_bottom, AppColors.accent, 'Pending Payments', MoneyText(store.pendingPayments, size: 15),
          () => MainNavigationScreen.switchTab(context, 1)),
      kpi(Icons.people_alt_outlined, AppColors.info, 'Total Customers',
          Text('${store.customers.length}', style: tx(context, 15, weight: FontWeight.w800)), () => MainNavigationScreen.switchTab(context, 3)),
    ];
    const gap = SizedBox(width: 10);
    // Four across on tablets in portrait; 2 x 2 everywhere else.
    if (wide) return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [items[0], gap, items[1], gap, items[2], gap, items[3]]));
    return Column(children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [items[0], gap, items[1]])),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [items[2], gap, items[3]])),
    ]);
  }

  Widget _settledCard() {
    final p = context.p;
    final (from, to) = _range;
    final settled = store.settled(from, to);
    final onWay = store.onItsWay(from, to);
    return BpCard(
      color: p.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settled to your Account', style: tx(context, 12, color: p.textSecondary)),
        const SizedBox(height: 4),
        MoneyText(settled, size: 18),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: p.infoSoft, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: context.p.info),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                onWay > 0
                    ? '${Fmt.money(onWay)} on its way'
                    : 'Paid by customer is not the same as settled. Settlement takes 1–2 business days.',
                style: tx(context, 11, color: context.p.info, weight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _trendCard() {
    final p = context.p;
    final days = _trend == 0 ? 7 : 30;
    final values = store.dailyCollected(days);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final dates = List.generate(days, (i) => start.add(Duration(days: i)));
    return BpCard(
      color: p.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Revenue Trend', style: tx(context, 14, weight: FontWeight.w800))),
          SegmentedPills(options: const ['7 Days', '30 Days'], index: _trend, expand: false, fontSize: 11, onChanged: (i) => setState(() => _trend = i)),
        ]),
        const SizedBox(height: 14),
        RevenueChart(values: values, days: dates),
      ]),
    );
  }

  Widget _attentionCard() {
    final p = context.p;
    final overdue = store.invoices.where((i) => i.status == InvoiceStatus.overdue).toList();
    return Container(
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withValues(alpha: 0.5))),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Needs Your Attention', style: tx(context, 13, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (overdue.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: p.errorSoft, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.error_outline, size: 16, color: p.error),
              const SizedBox(width: 6),
              Expanded(child: Text('${overdue.length} Overdue invoice${overdue.length == 1 ? '' : 's'}', style: tx(context, 12, weight: FontWeight.w700, color: p.error))),
              InkWell(
                onTap: () => showSendReminderSheet(context, overdue.first),
                child: Row(children: [
                  Text('Send Reminder', style: tx(context, 11.5, weight: FontWeight.w700, color: p.textSecondary)),
                  Icon(Icons.chevron_right, size: 16, color: p.textSecondary),
                ]),
              ),
            ]),
          ),
        if (overdue.isNotEmpty && store.ordersToFulfil > 0) const SizedBox(height: 6),
        if (store.ordersToFulfil > 0)
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: p.infoSoft, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.shopping_bag_outlined, size: 16, color: p.info),
                const SizedBox(width: 6),
                Expanded(child: Text('New orders to fulfil', style: tx(context, 12, weight: FontWeight.w700, color: p.info))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: p.info, borderRadius: BorderRadius.circular(10)),
                  child: Text('${store.ordersToFulfil}', style: tx(context, 11, weight: FontWeight.w800, color: p.isDark ? AppColors.background : Colors.white)),
                ),
                Icon(Icons.chevron_right, size: 16, color: p.info),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _recent() {
    final p = context.p;
    final list = store.payments.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Recent Transactions', style: tx(context, 14, weight: FontWeight.w800))),
        TextButton(
          onPressed: () => MainNavigationScreen.switchTab(context, 1),
          child: Text('View All', style: tx(context, 12, weight: FontWeight.w700, color: context.p.brand)),
        ),
      ]),
      if (list.isEmpty)
        BpCard(color: p.card, child: const Center(child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No Payments Yet')))
      else
        for (final pay in list)
          RecordTile(
            color: p.card,
            leading: const LeadingIcon(Icons.receipt_outlined),
            title: pay.customerName,
            subtitle: '${pay.sourceLabel} · ${Fmt.relativeDay(pay.date)}',
            amount: pay.amount,
            status: StatusStyle.payment(pay.status),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailsScreen(payment: pay))),
          ),
    ]);
  }
}

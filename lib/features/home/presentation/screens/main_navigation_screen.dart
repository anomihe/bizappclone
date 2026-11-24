import 'package:flutter/material.dart';
import '../../../../core/data/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/theme_toggle.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../customers/presentation/screens/customer_form_screen.dart';
import '../../../customers/presentation/screens/customers_tab.dart';
import '../../../invoices/presentation/screens/create_document_screen.dart';
import '../../../invoices/presentation/screens/create_payment_link_screen.dart';
import '../../../invoices/presentation/screens/invoices_tab.dart';
import '../../../more/presentation/screens/more_tab.dart';
import '../../../payments/presentation/screens/payments_tab.dart';
import '../../../store/presentation/screens/product_form_screen.dart';
import 'home_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTab;
  final bool openNewInvoice;

  const MainNavigationScreen({super.key, this.initialTab = 0, this.openNewInvoice = false});

  /// Replace the whole stack with the signed-in shell.
  static void go(BuildContext context, {int tab = 0, bool openNewInvoice = false}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigationScreen(initialTab: tab, openNewInvoice: openNewInvoice)),
      (_) => false,
    );
  }

  /// Switch tabs from anywhere inside the shell (e.g. "View All").
  static void switchTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_MainNavigationScreenState>()?._select(index);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _index = widget.initialTab;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.payments_outlined, Icons.payments, 'Payments'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Invoices'),
    (Icons.people_outline, Icons.people, 'Customers'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.openNewInvoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) CreateActions.newInvoice(context);
      });
    }
  }

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final tabs = IndexedStack(
      index: _index,
      children: const [HomeTab(), PaymentsTab(), InvoicesTab(), CustomersTab(), MoreTab()],
    );

    // Tablets, desktop and phones in landscape: side rail instead of bottom bar.
    if (context.isExpanded) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Row(children: [
          SafeArea(
            right: false,
            child: Container(
              decoration: BoxDecoration(color: p.card, border: Border(right: BorderSide(color: p.border))),
              // Scrolls if the window is too short for every destination (phone landscape).
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
                        leading: context.isShort
                            ? null
                            : const Padding(padding: EdgeInsets.only(top: 8, bottom: 16), child: BizpaddiLogo(size: 30)),
                        trailing: const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: ThemeToggleButton()),
                        destinations: [
                          for (final item in _items)
                            NavigationRailDestination(icon: Icon(item.$1), selectedIcon: Icon(item.$2), label: Text(item.$3)),
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
          // 66px from the design as a minimum; grows with the user's font size.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            // IntrinsicHeight bounds the stretch to the tallest item; without it
            // the bar would grow to the full screen height.
            child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _select(i),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: i == _index ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(i == _index ? _items[i].$2 : _items[i].$1,
                            size: 20, color: i == _index ? Colors.white : p.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(_items[i].$3,
                          style: tx(context, 10.5,
                              weight: i == _index ? FontWeight.w700 : FontWeight.w500,
                              color: i == _index ? p.brand : p.textMuted)),
                    ])),
                  ),
                ),
            ])),
          ),
        ),
      ),
    );
  }
}

/// Entry points shared by the FAB menu, dashboard cards and customer pages.
class CreateActions {
  static Future<void> newInvoice(BuildContext context, {Customer? customer}) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateDocumentScreen.invoice(customer: customer)),
      );

  static Future<void> newQuotation(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDocumentScreen.quotation()));

  static Future<void> newPaymentLink(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePaymentLinkScreen()));

  static Future<void> newCustomer(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
}

/// Gold "+ Create New" button that expands into the action menu.
class CreateNewFab extends StatelessWidget {
  const CreateNewFab({super.key});

  Future<void> _open(BuildContext context) async {
    final choice = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, _, _) => const _CreateMenu(),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'invoice':
        CreateActions.newInvoice(context);
      case 'quotation':
        CreateActions.newQuotation(context);
      case 'link':
        CreateActions.newPaymentLink(context);
      case 'customer':
        CreateActions.newCustomer(context);
      case 'product':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: () => _open(context),
      backgroundColor: AppColors.accent,
      foregroundColor: const Color(0xFF111916),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.add, size: 20),
      label: Text('Create New', style: tx(context, 13, weight: FontWeight.w700, color: const Color(0xFF111916))),
    );
  }
}

class _CreateMenu extends StatelessWidget {
  const _CreateMenu();

  static const _options = [
    ('invoice', Icons.receipt_long_outlined, 'Invoice'),
    ('quotation', Icons.request_quote_outlined, 'Quotation'),
    ('link', Icons.link, 'Payment Link'),
    ('customer', Icons.person_add_alt_outlined, 'New Customer'),
    ('product', Icons.inventory_2_outlined, 'New Product'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 78),
          child: Material(
            type: MaterialType.transparency,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final o in _options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: p.card,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context, o.$1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(o.$2, size: 17, color: context.p.brand),
                          const SizedBox(width: 8),
                          Text(o.$3, style: tx(context, 13, weight: FontWeight.w700, color: context.p.brand)),
                        ]),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              FloatingActionButton.small(
                heroTag: null,
                onPressed: () => Navigator.pop(context),
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF111916),
                shape: const CircleBorder(),
                child: const Icon(Icons.close),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

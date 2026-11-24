import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'package:bizpaddi/core/theme/theme_controller.dart';
import 'package:bizpaddi/core/widgets/theme_toggle.dart';
import 'package:bizpaddi/features/more/presentation/screens/appearance_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bizpaddi/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/invoice_details_screen.dart';
import 'package:bizpaddi/features/business/presentation/screens/bank_settlement_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/payment_link_details_screen.dart';
import 'package:bizpaddi/features/orders/presentation/screens/order_details_screen.dart';
import 'package:bizpaddi/features/store/presentation/screens/store_screen.dart';
import 'package:bizpaddi/features/team/presentation/screens/team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _settle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final store = BizStore.instance;
  setUp(store.loadDemoWorkspace);

  testWidgets('create and issue an invoice from the FAB menu', (tester) async {
    final before = store.invoices.length;
    await _pumpApp(tester, const MainNavigationScreen());

    await tester.tap(find.text('Create New'));
    await _settle(tester, 500);
    await tester.tap(find.text('Invoice'));
    await _settle(tester);
    expect(find.text('New Invoice'), findsOneWidget);

    // Customer
    await tester.tap(find.text('Choose or Add a customer'));
    await _settle(tester);
    await tester.tap(find.text('Kola Damola').last);
    await _settle(tester);
    expect(find.text('Kola Damola'), findsOneWidget);

    // Line item
    await tester.tap(find.text('Add item'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'E.g Ankara Fabric (6 yards)'), 'Ankara Fabric');
    await tester.enterText(find.widgetWithText(TextFormField, '0.00'), '5500');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add).last); // quantity +1 -> 2
    await tester.pump();
    expect(find.text('₦11,000.00', findRichText: true), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add item').last);
    await _settle(tester);
    expect(find.text('Ankara Fabric'), findsOneWidget);

    // Preview -> Issue
    await tester.tap(find.text('Preview'));
    await _settle(tester);
    expect(find.text('This is what your customer sees'), findsOneWidget);
    await tester.tap(find.text('Issue Invoice'));
    await _settle(tester, 2000);

    expect(store.invoices.length, before + 1);
    final created = store.invoices.first;
    expect(created.status, InvoiceStatus.unpaid);
    expect(created.total, 11000);
    expect(find.byType(InvoiceDetailsScreen), findsOneWidget);
    expect(find.text('Share Pay link'), findsOneWidget); // auto-opened share sheet
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP shows error for 000000 and succeeds otherwise', (tester) async {
    var verified = false;
    await _pumpApp(
      tester,
      OtpVerificationScreen(title: 'Verify your phone', subtitle: 'code sent', onVerified: (_) => verified = true),
    );
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);
    expect(find.text('Incorrect code entered'), findsOneWidget);
    expect(find.text('Resend Code'), findsOneWidget);
    expect(verified, isFalse);

    await tester.enterText(find.byType(TextField), '482913');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);
    expect(verified, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('void an unpaid invoice', (tester) async {
    final inv = store.invoices.firstWhere((i) => i.status == InvoiceStatus.unpaid && i.kind == DocKind.invoice);
    await _pumpApp(tester, InvoiceDetailsScreen(invoice: inv));
    await tester.scrollUntilVisible(find.text('Void invoice'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Void invoice'));
    await _settle(tester);
    expect(find.text('Void invoice ${inv.number}?'), findsOneWidget);
    await tester.tap(find.text('Void Invoice'));
    await _settle(tester);
    expect(inv.status, InvoiceStatus.voided);
    expect(find.text('Void'), findsOneWidget);
  });

  testWidgets('payments status filter narrows the list', (tester) async {
    await _pumpApp(tester, const MainNavigationScreen(initialTab: 1));
    await tester.tap(find.byTooltip('Filters'));
    await tester.pump();
    await tester.tap(find.text('Status'));
    await _settle(tester);
    await tester.tap(find.text('Failed').last);
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await _settle(tester);
    final failed = store.payments.where((p) => p.status == PaymentStatus.failed).length;
    expect(find.text('$failed Payment${failed == 1 ? '' : 's'}'), findsOneWidget);
    expect(find.text('Status (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('theme', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ThemeController.instance.setThemeMode(ThemeMode.light);
    });

    Future<void> pumpThemedApp(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: home,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
    }

    Brightness brightnessOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

    testWidgets('header toggle flips light <-> dark', (tester) async {
      await pumpThemedApp(tester, const MainNavigationScreen());
      expect(brightnessOf(tester), Brightness.light);

      await tester.tap(find.byType(ThemeToggleButton).first);
      await _settle(tester, 600);
      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      expect(brightnessOf(tester), Brightness.dark);

      await tester.tap(find.byType(ThemeToggleButton).first);
      await _settle(tester, 600);
      expect(brightnessOf(tester), Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('appearance choice is saved and restored on next launch', (tester) async {
      await pumpThemedApp(tester, const AppearanceScreen());
      await tester.tap(find.text('Dark'));
      await _settle(tester, 600);
      expect(brightnessOf(tester), Brightness.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      // Simulate a relaunch: reset in memory, then load from storage.
      await ThemeController.instance.setThemeMode(ThemeMode.system);
      await prefs.setString('theme_mode', 'dark');
      await ThemeController.instance.load();
      expect(ThemeController.instance.themeMode, ThemeMode.dark);

      await tester.tap(find.text('System default'));
      await _settle(tester, 600);
      expect(ThemeController.instance.themeMode, ThemeMode.system);
    });
  });

  testWidgets('wide screens use a navigation rail, phones a bottom bar', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const MainNavigationScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Customers'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Search customer or number'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NavigationRail), findsNothing);
    // Tab selection survives the layout switch.
    expect(find.text('Search customer or number'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard custom date range applies', (tester) async {
    await _pumpApp(tester, const MainNavigationScreen());
    await tester.ensureVisible(find.text('Custom'));
    await tester.pump();
    await tester.tap(find.text('Custom'));
    await _settle(tester);
    await tester.tap(find.text('1').first);
    await tester.tap(find.text('10').first);
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await _settle(tester);
    expect(find.textContaining(' – '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('store, orders, team, links', () {
    testWidgets('add a product from the store', (tester) async {
      final before = store.products.length;
      await _pumpApp(tester, const StoreScreen());
      await tester.tap(find.byTooltip('Add product'));
      await _settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter product name'), 'Silk Scarf');
      await tester.enterText(find.widgetWithText(TextFormField, '0').first, '4500');
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Add Product'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Add Product'));
      await _settle(tester);
      expect(store.products.length, before + 1);
      expect(store.products.first.name, 'Silk Scarf');
      expect(store.products.first.price, 4500);
      expect(find.text('Silk Scarf'), findsOneWidget); // back on the list
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancel a pending order with a reason', (tester) async {
      final order = store.orders.firstWhere((o) => o.status == OrderStatus.pending);
      await _pumpApp(tester, OrderDetailsScreen(order: order));
      await tester.tap(find.text('Cancel Order'));
      await _settle(tester);
      expect(find.text('Cancel this order?'), findsOneWidget);
      await tester.tap(find.text('Out of Stock'));
      await tester.pump();
      await tester.tap(find.text('Cancel Order').last);
      await _settle(tester);
      expect(order.status, OrderStatus.cancelled);
      expect(order.cancelReason, 'Out of Stock');
      expect(find.text('Cancelled: Out of Stock'), findsOneWidget);
    });

    testWidgets('invite a staff member as cashier', (tester) async {
      final before = store.staff.length;
      await _pumpApp(tester, const InviteStaffScreen());
      await tester.enterText(find.byType(TextFormField).first, 'ngozi@mail.com');
      await tester.tap(find.text('Cashier'));
      await tester.pump();
      await tester.tap(find.text('Send Invite'));
      await _settle(tester);
      expect(store.staff.length, before + 1);
      final m = store.staff.last;
      expect(m.role, StaffRole.cashier);
      expect(m.status, StaffStatus.invited);
      expect(m.permissions, defaultPermissions(StaffRole.cashier));
    });

    testWidgets('disable an active payment link', (tester) async {
      final link = store.paymentLinks.firstWhere((l) => BizStatus.link(l).label == 'Active');
      await _pumpApp(tester, PaymentLinkDetailsScreen(link: link));
      await tester.scrollUntilVisible(find.text('Disable Payment Link'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Disable Payment Link'));
      await _settle(tester);
      await tester.tap(find.text('Disable Link'));
      await _settle(tester);
      expect(BizStatus.link(link).label, 'Disabled');
      expect(find.text('Disable Payment Link'), findsNothing);
    });

    testWidgets('bank change needs password then OTP', (tester) async {
      await _pumpApp(tester, const BankSettlementScreen());
      await tester.tap(find.text('Change Bank Details'));
      await _settle(tester);
      await tester.tap(find.text('Use Password'));
      await _settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter Password'), '123');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await _settle(tester);
      expect(find.text('Wrong password. Try again'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter Password'), 'secret123');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await _settle(tester);
      expect(find.text('Verify your phone'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });

  test('quotation VAT, validity and expiry', () {
    final q = store.newQuotationDraft()
      ..items = [LineItem(name: 'Gown', unitPrice: 10000, qty: 2)]
      ..discount = 2000
      ..addVat = true
      ..validityDays = 14;
    expect(q.total, closeTo(18000 * 1.075, 0.001));
    store.saveQuotation(q, send: true);
    expect(q.status, QuotationStatus.sent);
    expect(q.validTill!.difference(DateTime.now()).inHours, inInclusiveRange(14 * 24 - 1, 14 * 24));
    q.validTill = DateTime.now().subtract(const Duration(days: 1));
    expect(q.status, QuotationStatus.expired);
    final invoice = store.invoiceFromQuotation(q);
    expect(invoice.items.any((i) => i.name == 'VAT (7.5%)'), isTrue);
    expect(invoice.total, closeTo(q.total, 0.001));
  });
}

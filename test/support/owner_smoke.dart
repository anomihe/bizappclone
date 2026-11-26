import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'sample_workspace.dart';
import 'package:bizpaddi/features/auth/presentation/screens/biometrics_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/choose_plan_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/login_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/register_screen.dart';
import 'package:bizpaddi/features/billing/billing_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/registration_success_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/welcome_back_screen.dart';
import 'package:bizpaddi/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:bizpaddi/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:bizpaddi/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/create_document_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/create_payment_link_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/credit_note_screens.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/document_preview_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/invoice_details_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/invoices_tab.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/payment_link_details_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/quotation_details_screen.dart';
import 'package:bizpaddi/features/invoices/presentation/screens/refund_screens.dart';
import 'package:bizpaddi/features/more/presentation/screens/appearance_screen.dart';
import 'package:bizpaddi/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bizpaddi/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bizpaddi/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:bizpaddi/features/payments/presentation/screens/payment_details_screen.dart';
import 'package:bizpaddi/features/payments/presentation/screens/receipt_screen.dart';
import 'package:bizpaddi/features/workspace/resource_screens.dart';
import 'package:bizpaddi/features/workspace/resource_specs.dart';
import 'package:bizpaddi/features/workspace/workspace_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizpaddi/features/business/presentation/screens/bank_settlement_screen.dart';
import 'package:bizpaddi/features/business/presentation/screens/business_profile_screen.dart';
import 'package:bizpaddi/features/business/presentation/screens/edit_business_profile_screen.dart';
import 'package:bizpaddi/features/more/presentation/screens/settings_screen.dart';
import 'package:bizpaddi/features/orders/presentation/screens/order_details_screen.dart';
import 'package:bizpaddi/features/orders/presentation/screens/orders_screen.dart';
import 'package:bizpaddi/features/reports/presentation/screens/reports_screen.dart';
import 'package:bizpaddi/features/store/presentation/screens/categories_screen.dart';
import 'package:bizpaddi/features/store/presentation/screens/custom_domain_screen.dart';
import 'package:bizpaddi/features/store/presentation/screens/edit_storefront_screen.dart';
import 'package:bizpaddi/features/store/presentation/screens/product_form_screen.dart';
import 'package:bizpaddi/features/store/presentation/screens/store_screen.dart';
import 'package:bizpaddi/features/support/presentation/screens/about_screen.dart';
import 'package:bizpaddi/features/support/presentation/screens/help_support_screen.dart';
import 'package:bizpaddi/features/team/presentation/screens/team_screen.dart';

/// Renders every screen at phone size in light and dark mode and fails on
/// any layout/build exception (overflows, unbounded constraints, nulls).
/// Business-owner screens; [themes] picks light (false) and/or dark (true).
/// Split across two test files so each test process stays within memory.
void ownerSmokeTests(List<bool> themes) {
  final store = BizStore.instance;
  store.loadSampleWorkspace();

  Invoice byStatus(InvoiceStatus s, {DocKind kind = DocKind.invoice}) =>
      store.invoices.firstWhere((i) => i.status == s && i.kind == kind);

  // The seeded paid invoice that also has a credit note and refund.
  final paid = store.invoices.firstWhere((i) => i.status == InvoiceStatus.paid && i.creditNotes.isNotEmpty);
  final screens = <String, Widget Function()>{
    'onboarding': () => const OnboardingScreen(),
    'welcome': () => const WelcomeScreen(),
    'appearance': () => const AppearanceScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'otp': () => OtpVerificationScreen(title: 'Verify your email', subtitle: 'We sent a code', onSubmit: (_) async => null, onVerified: (_) {}),
    'biometrics': () => const BiometricsScreen(),
    'choose plan': () => const ChoosePlanScreen(),
    'all set': () => const RegistrationSuccessScreen(),
    'welcome back': () => const WelcomeBackScreen(),
    'forgot password': () => const ForgotPasswordScreen(),
    'set new password': () => const ResetPasswordScreen(email: 'ada@shop.ng'),
    'password updated': () => const PasswordUpdatedScreen(),
    'shell / home': () => const MainNavigationScreen(),
    'payments tab': () => const MainNavigationScreen(initialTab: 1),
    'invoices tab': () => const MainNavigationScreen(initialTab: 2),
    'customers tab': () => const MainNavigationScreen(initialTab: 3),
    'more tab': () => const MainNavigationScreen(initialTab: 4),
    'notifications': () => const NotificationsScreen(),
    'payment details (paid)': () => PaymentDetailsScreen(payment: paid.payments.first),
    'payment details (failed)': () => PaymentDetailsScreen(payment: store.payments.firstWhere((p) => p.status == PaymentStatus.failed)),
    'receipt': () => ReceiptScreen(payment: paid.payments.first),
    'new invoice': () => CreateDocumentScreen.invoice(),
    'new quotation': () => CreateDocumentScreen.quotation(),
    'edit draft': () => CreateDocumentScreen.invoice(draft: byStatus(InvoiceStatus.draft)),
    'invoice preview': () => DocumentPreviewScreen.invoice(paid),
    'quotation preview': () => DocumentPreviewScreen.quotation(store.quotations.first),
    'invoice draft': () => InvoiceDetailsScreen(invoice: byStatus(InvoiceStatus.draft)),
    'invoice unpaid': () => InvoiceDetailsScreen(invoice: byStatus(InvoiceStatus.unpaid)),
    'invoice part paid': () => InvoiceDetailsScreen(invoice: byStatus(InvoiceStatus.partlyPaid)),
    'invoice overdue': () => InvoiceDetailsScreen(invoice: byStatus(InvoiceStatus.overdue)),
    'invoice paid': () => InvoiceDetailsScreen(invoice: paid),
    'new payment link': () => const CreatePaymentLinkScreen(),
    'payment links list': () => const PaymentLinksScreen(),
    'link active': () => PaymentLinkDetailsScreen(link: store.paymentLinks.firstWhere((l) => BizStatus.link(l).label == 'Active')),
    'link paid': () => PaymentLinkDetailsScreen(link: store.paymentLinks.firstWhere((l) => BizStatus.link(l).label == 'Paid')),
    'link expired': () => PaymentLinkDetailsScreen(link: store.paymentLinks.firstWhere((l) => BizStatus.link(l).label == 'Expired')),
    'issue credit note': () => IssueCreditNoteScreen(invoice: paid),
    'credit note preview': () => CreditNotePreviewScreen(invoice: paid, amount: 1000, reason: 'Cancelled Order'),
    'credit note': () => CreditNoteScreen(invoice: paid, note: paid.creditNotes.first),
    'request refund': () => RequestRefundScreen(invoice: paid),
    'refund status': () => RefundStatusScreen(invoice: paid, refund: paid.refunds.first),
    'quotation': () => QuotationDetailsScreen(quotation: store.quotations.first),
    'quotations list': () => const QuotationsScreen(),
    'customer details': () => CustomerDetailsScreen(customer: store.customers.first),
    'new customer': () => const CustomerFormScreen(),
    'edit customer': () => CustomerFormScreen(customer: store.customers.first),
    // Store, orders, team, reports, business, support, settings.
    'store products': () => const StoreScreen(),
    'storefront tab': () => const StoreScreen(initialTab: 1),
    'add product': () => const ProductFormScreen(),
    'edit product': () => ProductFormScreen(product: store.products.first),
    'categories': () => const CategoriesScreen(),
    'custom domain': () => const CustomDomainScreen(),
    'edit storefront': () => const EditStorefrontScreen(),
    'orders': () => const OrdersScreen(),
    'order pending': () => OrderDetailsScreen(order: store.orders.firstWhere((o) => o.status == OrderStatus.pending)),
    'order paid': () => OrderDetailsScreen(order: store.orders.firstWhere((o) => o.status == OrderStatus.processing)),
    'order payment': () => PaymentDetailsScreen(payment: store.payments.firstWhere((p) => p.isOrder)),
    'team': () => const TeamScreen(),
    'staff admin': () => StaffMemberScreen(member: store.staff.firstWhere((s) => s.role == StaffRole.administrator)),
    'staff deactivated': () => StaffMemberScreen(member: store.staff.firstWhere((s) => s.status == StaffStatus.deactivated)),
    'invite staff': () => const InviteStaffScreen(),
    'reports': () => const ReportsScreen(),
    'business profile': () => const BusinessProfileScreen(),
    'edit business profile': () => const EditBusinessProfileScreen(),
    'bank settlement': () => const BankSettlementScreen(),
    'bank details': () => const BankDetailsScreen(),
    'help': () => const HelpSupportScreen(),
    'support chat': () => const SupportChatScreen(),
    'about': () => const AboutScreen(),
    'privacy': () => const LegalScreen(doc: LegalDoc.privacy),
    'settings': () => const SettingsScreen(),
    'security': () => const SecurityScreen(),
    'quotation expired': () => QuotationDetailsScreen(quotation: store.quotations.firstWhere((q) => q.status == QuotationStatus.expired)),
    'quotation accepted': () => QuotationDetailsScreen(quotation: store.quotations.firstWhere((q) => q.status == QuotationStatus.accepted)),
    'leads list': () => ResourceListScreen(spec: Specs.leads),
    'project form': () => ResourceFormScreen(spec: Specs.projects),
    'contract details': () => ResourceDetailScreen(spec: Specs.contracts, item: const {'id': 1, 'title': 'Supply agreement', 'status': 'active', 'value': '500000.00', 'client': {'name': 'Mama Chidi Stores'}}),
    'project details': () => projectDetails(const {'id': 3, 'name': 'Obi wedding outfits', 'status': 'active', 'client': {'name': 'Mama Chidi Stores'}, 'budget': '850000.00'}),
    'project chat': () => const ProjectChatScreen(projectId: 1, projectName: 'Obi wedding outfits', type: ChatType.team),
    'balance sheet': () => const BalanceSheetScreen(),
    'my profile': () => const MyProfileScreen(),
    'change password': () => const ChangePasswordScreen(),
    'wallet & billing': () => const BillingScreen(),
    'sign-up email': () => const SignupEmailScreen(),
    'sign-up details': () => const SignupDetailsScreen(email: 'tola@shop.ng', code: '654321'),
  };

  // Logical sizes covering the layouts we support.
  const sizes = <String, (Size, double)>{
    'phone': (Size(390, 844), 1.0),
    'small phone': (Size(320, 640), 1.0),
    'phone landscape': (Size(844, 390), 1.0),
    'tablet': (Size(820, 1180), 1.0),
    'desktop': (Size(1440, 900), 1.0),
    'phone large text': (Size(390, 844), 1.3),
  };

  for (final dark in themes) {
    for (final size in sizes.entries) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders (${dark ? 'dark' : 'light'}, ${size.key})', (tester) async {
        final (logical, textScale) = size.value;
        tester.view.physicalSize = logical * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: entry.value(),
        ));
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        // Layout sanity: navigation chrome must never squeeze out the tab content.
        if (find.byType(MainNavigationScreen).evaluate().isNotEmpty) {
          final content = tester.getSize(find.byType(IndexedStack).first);
          expect(content.height, greaterThan(logical.height * 0.6), reason: 'tab content collapsed');
        }
        // Let any delayed timers (OTP countdown etc.) be disposed cleanly.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }
    }
  }
}

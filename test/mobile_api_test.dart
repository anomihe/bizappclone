import 'dart:convert';
import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/mappers.dart';
import 'package:bizpaddi/core/api/repositories.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'package:bizpaddi/features/auth/presentation/screens/register_screen.dart';
import 'package:bizpaddi/features/billing/billing_screen.dart';
import 'package:bizpaddi/features/more/presentation/screens/two_factor_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_backend.dart';

/// Routes added on the backend's feature/mobile-api branch: sign-up, 2FA,
/// invoice/quote actions, store, orders, storefront, KYC, billing, push.
void main() {
  late FakeBackend backend;
  final store = BizStore.instance;

  LiveSession session() => LiveSession.instance = LiveSession(
        api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client),
        tokens: MemoryTokenStore(),
        store: store,
      );

  Future<void> signIn() async {
    LiveSession.debugEnabledOverride = true;
    await session().login('ada@shop.ng', 'secret123');
    backend.requests.clear();
  }

  setUp(() => backend = FakeBackend());
  tearDown(() => LiveSession.debugEnabledOverride = false);

  group('auth', () {
    test('2FA login: stops at the challenge, then signs in with the code', () async {
      backend.twoFactor = true;
      final s = session();
      await expectLater(s.login('ada@shop.ng', 'secret123'), throwsA(isA<TwoFactorRequired>().having((t) => t.challengeToken, 'token', 'ch-1')));
      expect(s.api.token, isNull, reason: 'no token before the second step');

      await expectLater(s.completeTwoFactor('ch-1', '000000'), throwsA(isA<ApiException>().having((e) => e.errorFor('code'), 'code', isNotNull)));
      await s.completeTwoFactor('ch-1', '123456');
      expect(s.api.token, '2|tfa');
      expect(store.customers, isNotEmpty, reason: 'workspace loaded');
    });

    test('sign-up: email code, then details, then signed in', () async {
      final s = session();
      await expectLater(s.sendSignupCode('taken@shop.ng'), throwsA(isA<ApiException>().having((e) => e.errorFor('email'), 'email', contains('already exists'))));
      await s.sendSignupCode('new@shop.ng', companyName: 'Tola Foods');
      await expectLater(s.verifySignupCode('new@shop.ng', '111111'), throwsA(isA<ApiException>()));
      await s.verifySignupCode('new@shop.ng', '654321');

      await s.register(
        companyName: 'Tola Foods',
        firstName: 'Tola',
        lastName: 'Ade',
        email: 'new@shop.ng',
        dialCode: '+234',
        phone: '8030000000',
        password: 'Strong#123',
        otp: '654321',
      );
      final reg = backend.requests.firstWhere((r) => r.url.path == '/api/v1/auth/register');
      expect(jsonDecode(reg.body), allOf(containsPair('password_confirmation', 'Strong#123'), containsPair('agree_terms', true), containsPair('otp_code', '654321')));
      expect(s.api.token, '3|new');
      expect(store.account.businessName, 'Tola Foods');
    });
  });

  group('invoices & quotes', () {
    setUp(signIn);

    test('invoice body uses the web fields; server works out totals', () {
      final inv = Invoice(
        id: 'x',
        number: '#1',
        customer: store.customers.first,
        items: [LineItem(name: 'Ankara', unitPrice: 6500, qty: 2)],
        createdAt: DateTime(2026, 11, 24),
        dueDate: DateTime(2026, 11, 20), // before the issue date: clamped
        status: InvoiceStatus.paid,
      );
      final b = ApiMappers.invoiceBody(inv);
      expect(b['items'], [{'title': 'Ankara', 'description': 'Ankara', 'quantity': 2, 'unit_price': 6500.0}]);
      expect(b.containsKey('total_amount'), isFalse);
      expect(b.containsKey('status'), isFalse, reason: 'paid only comes from mark-paid');
      expect(b['due_date'], '2026-11-24');
    });

    test('email, mark paid and PDF', () async {
      final inv = store.invoices.firstWhere((i) => i.serverId == 21);
      final s = LiveSession.instance;
      await s.emailInvoice(inv);
      expect(backend.requests.last.url.path, '/api/v1/admin/accounting/invoices/21/send');

      await s.markInvoicePaid(inv);
      expect(inv.status, InvoiceStatus.paid);
      expect(inv.paid, inv.total);

      final pdf = await s.invoicePdf(inv);
      expect(utf8.decode(pdf), startsWith('%PDF'));
    });

    test('accepting a quote calls approve; converting adds the invoice', () async {
      final q = store.quotations.first..status = QuotationStatus.sent;
      store.acceptQuotation(q);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(backend.requests.map((r) => r.url.path), contains('/api/v1/admin/accounting/quotes/5/approve'));
      final put = backend.requests.firstWhere((r) => r.method == 'PUT');
      expect(jsonDecode(put.body).containsKey('status'), isFalse);

      final inv = await LiveSession.instance.convertQuotation(q);
      expect(inv.number, 'INV-0088');
      expect(store.invoices.first, same(inv));
    });

    test('a 402 from the API is flagged as needing billing', () async {
      backend
        ..chargeInvoices = true
        ..wallet = 0;
      try {
        await LiveSession.instance.business.createInvoice({'client_id': 11});
        fail('expected 402');
      } on ApiException catch (e) {
        expect(e.needsBilling, isTrue);
        expect(e.message, contains('Insufficient'));
      }
    });
  });

  group('store, orders, storefront, KYC, billing', () {
    setUp(signIn);

    test('workspace load brings in products, categories, orders, storefront, KYC, plan', () {
      expect(store.products.map((p) => p.name), ['Ankara fabric', 'Gele']);
      final ankara = store.products.first;
      expect(ankara.discount, 500);
      expect(ankara.imageUrl, 'https://x.test/storage/store/products/a.jpg');
      expect(store.categoryById(ankara.categoryId)?.name, 'Fabrics');
      expect(store.products.last.categoryId, isNull, reason: '"General" is no category');
      expect(store.products.last.showOnStorefront, isFalse);

      expect(store.orders.single.status, OrderStatus.processing, reason: 'paid shows as Paid/processing');
      expect(store.orders.single.payments.single.amount, 12000);

      expect(store.storefront.name, 'Ada Fabrics');
      expect(store.storefront.link, 'app.bizpaddi.com/store/ada-fabrics');
      expect(store.storefront.phone, '8035550142');

      expect(store.profile.documents['CAC Certificate'], 'cac.pdf');
      expect(store.profile.documents['Utility Bill'], isNull);
      expect(store.account.verified, isFalse, reason: 'KYC not complete');
      expect(LiveSession.instance.billing.value?['wallet_balance'], 3250);
    });

    test('product save is multipart with the photo; delete', () async {
      final s = LiveSession.instance;
      final p = store.newProductDraft()
        ..name = 'Aso oke'
        ..price = 15000
        ..discount = 1000
        ..quantity = 3
        ..categoryId = store.categories.first.id;
      await s.saveProduct(p, image: [1, 2, 3], filename: 'aso.jpg');
      final req = backend.requests.last;
      expect(req.headers['content-type'], startsWith('multipart/form-data'));
      final body = utf8.decode(req.bodyBytes, allowMalformed: true);
      expect(body, contains('name="sale_price"\r\n\r\n14000.00'));
      expect(body, contains('name="category"\r\n\r\nFabrics'));
      expect(p.serverId, isNotNull);
      expect(p.imageUrl, contains('new.jpg'));
      expect(store.products.first, same(p));

      await s.deleteProduct(p);
      expect(backend.requests.last.method, 'DELETE');
      expect(store.products.contains(p), isFalse);
    });

    test('order status, storefront save, KYC upload', () async {
      final s = LiveSession.instance;
      final o = store.orders.single;
      await s.setOrderStatus(o, 'completed');
      expect(o.status, OrderStatus.completed);
      expect(jsonDecode(backend.requests.last.body), containsPair('status', 'completed'));

      store.storefront
        ..name = 'Ada Fabrics Ltd'
        ..tagline = 'Fresh fabrics';
      await s.saveStorefront(banner: [1, 2], filename: 'b.jpg');
      expect(store.storefront.bannerUrl, contains('b.jpg'));
      expect(store.storefront.tagline, 'Fresh fabrics');

      await s.uploadKyc('Utility Bill', [1, 2, 3], 'bill.jpg');
      expect(utf8.decode(backend.requests.firstWhere((r) => r.url.path == '/api/v1/admin/kyc' && r.method == 'POST').bodyBytes, allowMalformed: true),
          contains('name="document_type"\r\n\r\nutility_bill'));
      expect(store.profile.documentStatus['Utility Bill'], 'pending');
    });

    test('push token is registered and removed on logout', () async {
      final s = LiveSession.instance;
      await s.registerPushToken('fcm-1');
      expect(backend.requests.last.url.path, '/api/v1/admin/device-tokens');
      await s.logout();
      final del = backend.requests.firstWhere((r) => r.method == 'DELETE' && r.url.path == '/api/v1/admin/device-tokens');
      expect(jsonDecode(del.body), {'token': 'fcm-1'});
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(signIn);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('live sign-up starts with the email step', (tester) async {
      await pump(tester, const RegisterScreen());
      expect(find.text('Get started with Bizpaddi'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'taken@shop.ng');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Continue & Send Code'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.textContaining('already exists'), findsOneWidget);
    });

    testWidgets('billing shows the wallet and top-up', (tester) async {
      await pump(tester, const BillingScreen());
      expect(find.text('Operating wallet'), findsOneWidget);
      expect(find.text('Top Up Wallet'), findsOneWidget, reason: 'tests run as Android');
      expect(find.text('Wallet top-up'), findsOneWidget);
    });

    testWidgets('2FA setup shows the key and turns on with a code', (tester) async {
      await pump(tester, const TwoFactorSettingsScreen());
      expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Turn On'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('ABCD-1234'), findsOneWidget);
    });
  });
}

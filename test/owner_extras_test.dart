import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_backend.dart';

/// Payment links, credit notes & refunds, business profile, payout account,
/// notification settings, sessions and the owner support chat — each wired
/// to its `/api/v1/admin/*` route.
void main() {
  late FakeBackend backend;
  final store = BizStore.instance;

  Future<LiveSession> signIn() async {
    final s = LiveSession.instance = LiveSession(
      api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client),
      tokens: MemoryTokenStore(),
      store: store,
    );
    await s.login('ada@shop.ng', 'secret123');
    backend.requests.clear();
    return s;
  }

  setUp(() => backend = FakeBackend());

  test('sign-in loads payment links, business profile and notification settings', () async {
    await signIn();
    final link = store.paymentLinks.single;
    expect(link.purpose, 'Gucci Bags');
    expect(link.total, 25000);
    expect(link.payLink, 'app.bizpaddi.com/pay/gucci-bags-a1b2'); // shown without the scheme
    expect(store.profile.name, 'Ada Fabrics');
    expect(store.profile.type, 'Fashion');
    expect(store.profile.address, '12 Allen Ave, Ikeja');
    expect(store.notificationPrefs['Tips and product news'], isFalse);
  });

  test('payment link: create, change expiry, disable', () async {
    final s = await signIn();
    final draft = store.newInvoiceDraft(kind: DocKind.paymentLink)
      ..items = [LineItem(name: 'Ankara deposit', unitPrice: 15000, qty: 1)]
      ..customerPhone = '08031112222';
    final link = await s.createPaymentLink(draft);
    expect(link.serverId, isNotNull);
    expect(link.linkUrl, startsWith('https://app.bizpaddi.com/pay/'));
    expect(store.paymentLinks.first, same(link));
    expect(backend.paymentLinks.first['customer_phone'], '08031112222');

    await s.setPaymentLinkExpiry(link, DateTime.utc(2026, 12, 31));
    expect(backend.paymentLinks.first['expires_at'], startsWith('2026-12-31'));

    await s.disablePaymentLink(link);
    expect(link.status, InvoiceStatus.cancelled);
  });

  test('credit note and refund: issued on the backend, capped at what was paid', () async {
    final s = await signIn();
    final inv = store.invoices.firstWhere((i) => i.serverId != null && i.kind == DocKind.invoice);
    final note = await s.issueCreditNote(inv, 2000, 'Cancelled order');
    expect(note.number, 'CN-0001');
    expect(inv.creditNotes, contains(note));

    final refund = await s.requestRefund(inv, 5000, 'Returned item');
    expect(refund.stage, RefundStage.requested);
    expect(inv.refunds, contains(refund));

    await expectLater(s.requestRefund(inv, 999999, 'Too much'), throwsA(isA<ApiException>().having((e) => e.errorFor('amount'), 'amount', isNotNull)));
  });

  test('business profile: save details and upload a logo', () async {
    final s = await signIn();
    store.profile
      ..name = 'Ada Fabrics & Co'
      ..address = '5 Broad St, Lagos';
    await s.saveBusinessProfile();
    expect(backend.business['name'], 'Ada Fabrics & Co');
    expect(store.account.businessName, 'Ada Fabrics & Co');

    await s.uploadBusinessLogo([1, 2, 3], 'logo.png');
    expect(store.profile.logoUrl, 'https://x.test/storage/logos/logo.png');
    expect(store.storefront.hasLogo, isTrue);
  });

  test('payout account: bank list, name check, password + emailed code', () async {
    final s = await signIn();
    final banks = await s.settlementBanks();
    expect(banks.map((b) => b['code']), contains('058'));
    expect(await s.resolveBankAccount('058', '0123456789'), 'ADA FABRICS LTD');
    await expectLater(s.resolveBankAccount('058', '0000000000'), throwsA(isA<ApiException>()));

    expect(await s.sendSettlementCode(), 'a***@shop.ng');
    await expectLater(s.saveSettlementAccount(bankCode: '058', number: '0123456789', password: 'wrong', otp: '246810'),
        throwsA(isA<ApiException>().having((e) => e.errorFor('password'), 'password', isNotNull)));
    await expectLater(s.saveSettlementAccount(bankCode: '058', number: '0123456789', password: 'secret123', otp: '000000'),
        throwsA(isA<ApiException>().having((e) => e.errorFor('otp'), 'otp', isNotNull)));
    await s.saveSettlementAccount(bankCode: '058', number: '0123456789', password: 'secret123', otp: '246810');

    expect(store.profile.bank?.bank, 'GTBank');
    expect(store.profile.bank?.name, 'ADA FABRICS LTD');
    expect(store.profile.bankHistory.single.title, 'Payout account added');
  });

  test('notification toggle is saved; sessions on other devices are revoked', () async {
    final s = await signIn();
    await s.setNotificationPref('Tips and product news', true);
    expect(backend.notificationPrefs['product_updates'], isTrue);
    expect(store.notificationPrefs['Tips and product news'], isTrue);

    expect(await s.logoutOtherDevices(), 2);
    expect(await s.logoutOtherDevices(), 0);
  });

  test('ticket reply goes to the customer and moves the ticket to in progress', () async {
    final s = await signIn();
    final m = await s.business.replyToTicket(8, 'We have confirmed your transfer.');
    expect(m['is_admin'], isTrue);
    final ticket = backend.resources['tickets']!.single;
    expect((ticket['messages'] as List).last['message'], 'We have confirmed your transfer.');
    expect(ticket['status'], 'in_progress');
  });

  test('support chat: reads the thread and sends a message', () async {
    final s = await signIn();
    final thread = await s.supportMessages();
    expect(thread.single['sender_type'], 'support');
    final sent = await s.sendSupportMessage('My payout is late');
    expect(sent['sender_type'], 'owner');
    expect(backend.supportMessages.last['message'], 'My payout is late');
    await expectLater(s.sendSupportMessage('  '), throwsA(isA<ApiException>()));
  });
}

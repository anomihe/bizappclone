import 'dart:convert';
import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/mappers.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support/fake_backend.dart';

void main() {
  group('ApiClient', () {
    test('unwraps the envelope and sends the bearer token', () async {
      final seen = <http.BaseRequest>[];
      final api = ApiClient(baseUrl: 'https://x.test/', httpClient: MockClient((r) async {
        seen.add(r);
        return ok({'hello': 'world'});
      }))
        ..token = 'tok';
      expect(await api.get('/v1/admin/profile'), {'hello': 'world'});
      expect(seen.single.url.toString(), 'https://x.test/api/v1/admin/profile');
      expect(seen.single.headers['Authorization'], 'Bearer tok');
      expect(seen.single.headers['Accept'], 'application/json');
    });

    test('422 surfaces the first validation message and field errors', () async {
      final api = ApiClient(baseUrl: 'https://x.test', httpClient: MockClient((_) async => http.Response(
            jsonEncode({'message': 'The given data was invalid.', 'errors': {'email': ['The email has already been taken.']}}),
            422,
          )));
      final e = await api.post('/v1/admin/clients', {}).then<ApiException?>((_) => null, onError: (e) => e as ApiException);
      expect(e!.message, 'The email has already been taken.');
      expect(e.errorFor('email'), 'The email has already been taken.');
    });

    test('401 triggers onUnauthorized', () async {
      var called = false;
      final api = ApiClient(baseUrl: 'https://x.test', httpClient: MockClient((_) async => http.Response('{"message":"Unauthenticated."}', 401)))
        ..onUnauthorized = () => called = true;
      await expectLater(api.get('/v1/admin/profile'), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', true)));
      expect(called, isTrue);
    });

    test('server errors get a friendly message', () async {
      final api = ApiClient(baseUrl: 'https://x.test', httpClient: MockClient((_) async => http.Response('<html>Server Error</html>', 500)));
      await expectLater(api.get('/v1/x'), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('trouble'))));
    });

    test('getAllPages follows last_page', () async {
      final b = FakeBackend();
      final api = ApiClient(baseUrl: 'https://x.test', httpClient: b.client)..token = 't';
      final all = await api.getAllPages('/v1/admin/accounting/invoices');
      expect(all.map((e) => e['id']), [21, 22]);
    });
  });

  group('ApiMappers', () {
    test('invoice: decimal strings, status, due date, customer link', () {
      final c = ApiMappers.customer({'id': 11, 'name': 'Mama Chidi', 'phone': '+2348055550110', 'email': 'c@x.ng'});
      expect((c.dialCode, c.phone), ('+234', '8055550110'));
      final i = ApiMappers.invoice(
        {'id': 21, 'invoice_number': 'INV-0021', 'client_id': 11, 'total_amount': '37000.00', 'status': 'sent', 'due_date': '2000-01-01T00:00:00Z'},
        findCustomer: (id) => id == 11 ? c : null,
      );
      expect(i.total, 37000);
      expect(i.customer, same(c));
      expect(i.status, InvoiceStatus.overdue); // sent + past due
      expect(ApiMappers.invoiceStatusOut(InvoiceStatus.voided), 'cancelled');
    });

    test('paid invoice without transaction records a payment', () {
      final i = ApiMappers.invoice({'id': 1, 'total_amount': '10000.00', 'status': 'paid'}, findCustomer: (_) => null);
      expect(i.status, InvoiceStatus.paid);
      expect(i.paid, 10000);
    });

    test('only incoming transactions count as payments', () {
      expect(ApiMappers.isIncoming({'payable_type': r'Modules\Accounting\Models\Invoice'}), isTrue);
      expect(ApiMappers.isIncoming({'payable_type': r'Modules\Admin\Models\SalaryDisbursement', 'type': 'debit'}), isFalse);
      expect(ApiMappers.paymentStatus('successful'), PaymentStatus.paid);
    });

    test('quote statuses and VAT', () {
      final q = ApiMappers.quotation({'id': 5, 'status': 'approved', 'tax_amount': '375.00', 'total_amount': '5375.00'}, findCustomer: (_) => null);
      expect(q.status, QuotationStatus.accepted);
      expect(q.addVat, isTrue);
      expect(q.total, 5375);
      expect(ApiMappers.quoteStatusOut(QuotationStatus.accepted), 'approved');
    });

    test('staff keeps unknown backend roles when saving', () {
      final m = ApiMappers.staff({'id': 3, 'name': 'Segun', 'email': 's@x.ng', 'role': 'bdm', 'status': 'active'});
      expect(m.role, StaffRole.manager);
      expect(ApiMappers.staffBody(m)['role'], 'bdm');
      expect(ApiMappers.staff({'id': 4, 'role': 'accountant', 'status': 'inactive'}).status, StaffStatus.deactivated);
    });

    test('request bodies use backend field names', () {
      final c = Customer(id: 'x', name: 'Ada', dialCode: '+234', phone: '0803 555 0142', email: 'a@x.ng');
      final body = ApiMappers.customerBody(c, password: 'pw');
      expect(body['phone'], '+2348035550142');
      expect(body['password'], 'pw');
      expect(ApiMappers.customerBody(c).containsKey('password'), isFalse);
    });
  });

  group('LiveSession', () {
    late FakeBackend backend;
    late LiveSession session;
    late MemoryTokenStore tokens;
    final store = BizStore.instance;

    setUp(() {
      backend = FakeBackend();
      tokens = MemoryTokenStore();
      session = LiveSession(api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client), tokens: tokens, store: store);
    });

    test('login loads the workspace from the API', () async {
      await session.login('ada@shop.ng', 'secret123');
      expect(tokens.token, '1|abc');
      expect(tokens.email, 'ada@shop.ng');
      expect(store.account.ownerFullName, 'Ada Obi');
      expect(store.customers.map((c) => c.name), ['Mama Chidi Stores']);
      expect(store.invoices.map((i) => i.number), ['INV-0021', 'INV-0022']);
      // Billway payment attached to its invoice; the salary debit is ignored.
      final inv21 = store.invoices.firstWhere((i) => i.serverId == 21);
      expect(inv21.paid, 20000);
      expect(store.payments.any((p) => p.amount == 50000), isFalse);
      expect(store.quotations.single.status, QuotationStatus.accepted);
      expect(store.staff.map((s) => s.name), ['Segun Ajayi', 'Kola Damola']);
      expect(store.unreadCount, 1);
      expect(store.products.map((p) => p.name), ['Ankara fabric', 'Gele'], reason: 'products come from the API, no demo data mixed in');
      expect(store.remote, same(session));
    });

    test('staff accounts open the staff app instead of the business workspace', () async {
      backend.loginType = 'team';
      await session.login('s@x.ng', 'secret123');
      expect(session.role, AccountRole.staff);
      expect(session.portalAccount.value?.name, 'Amaka Eze');
      expect(tokens.role, 'team');
    });

    test('wrong password shows the server message', () async {
      await expectLater(session.login('ada@shop.ng', 'nope'), throwsA(isA<ApiException>().having((e) => e.message, 'm', 'Invalid credentials.')));
    });

    test('opening an invoice loads its line items', () async {
      await session.login('ada@shop.ng', 'secret123');
      final inv = store.invoices.firstWhere((i) => i.serverId == 21);
      expect(inv.items, isEmpty);
      await session.refreshInvoice(inv);
      expect(inv.items.map((e) => e.name), ['Ankara', 'Gown']);
      expect(inv.total, 37000);
    });

    test('store changes are pushed to the API', () async {
      await session.login('ada@shop.ng', 'secret123');
      final c = store.addCustomer(name: 'Tunde', dialCode: '+234', phone: '08095550177', email: 'tunde@mail.com');
      final draft = store.newInvoiceDraft()
        ..customer = c
        ..items = [LineItem(name: 'Gown', unitPrice: 5000, qty: 2)];
      await Future<void>.delayed(Duration.zero);
      store.saveInvoice(draft, issue: true);
      await pumpEventQueue();

      final created = backend.requests.firstWhere((r) => r.method == 'POST' && r.url.path.endsWith('/clients'));
      final cBody = jsonDecode(created.body) as Map;
      expect(cBody['email'], 'tunde@mail.com');
      expect((cBody['password'] as String).length, greaterThanOrEqualTo(8), reason: 'API requires a client password');
      expect(c.serverId, 99);

      final inv = jsonDecode(backend.requests.lastWhere((r) => r.url.path.endsWith('/accounting/invoices') && r.method == 'POST').body) as Map;
      expect(inv['status'], 'sent');
      expect(inv.containsKey('total_amount'), isFalse, reason: 'the server works out totals from the items');
      expect((inv['items'] as List).single, {'title': 'Gown', 'description': 'Gown', 'quantity': 2, 'unit_price': 5000.0});
      expect(draft.serverId, 30);
      expect(draft.number, 'INV-0030');
    });

    test('invite staff returns a temporary password', () async {
      await session.login('ada@shop.ng', 'secret123');
      final m = StaffMember(id: 'n', name: 'ngozi', email: 'ngozi@mail.com', role: StaffRole.cashier, lastActive: DateTime.now());
      final pw = await session.inviteStaff(m);
      final body = jsonDecode(backend.requests.last.body) as Map;
      expect(body['password'], pw);
      expect(body['role'], 'cashier');
      expect(m.serverId, 77);
    });

    test('expired token clears the session', () async {
      await session.login('ada@shop.ng', 'secret123');
      backend.expireToken = true;
      await expectLater(session.resume(), throwsA(isA<ApiException>()));
      expect(session.sessionExpired.value, isTrue);
      expect(tokens.token, isNull);
      expect(tokens.email, 'ada@shop.ng', reason: 'email kept for Welcome back');
    });

    test('logout revokes the token', () async {
      await session.login('ada@shop.ng', 'secret123');
      await session.logout();
      expect(backend.requests.last.url.path, '/api/v1/admin/logout');
      expect(tokens.token, isNull);
      expect(store.remote, isNull);
    });
  });
}

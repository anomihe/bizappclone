import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Responses shaped like the Laravel controllers in bizpaddi-platform
/// (envelope {success, message, data}; paginator; decimals as strings).
http.Response ok(Object? data, [int code = 200]) =>
    http.Response(jsonEncode({'success': true, 'message': 'OK', 'data': data}), code, headers: {'content-type': 'application/json'});
Map<String, dynamic> page(List<Map<String, dynamic>> items, {int last = 1, int current = 1}) =>
    {'current_page': current, 'last_page': last, 'data': items};

class FakeBackend {
  final requests = <http.Request>[];
  String loginType = 'admin';
  bool expireToken = false;

  String chatStatus = 'active';
  final chatMessages = <Map<String, dynamic>>[
    {'id': 400, 'content': 'Fabric is in.', 'sender_id': 3, 'sender_type': r'App\Models\User', 'sender': {'name': 'Segun Ajayi'}, 'created_at': '2026-11-22T09:00:00.000000Z', 'reads': [], 'media': []},
  ];

  /// In-memory tables for the generic `/api/v1/admin/*` resources.
  final resources = <String, List<Map<String, dynamic>>>{
    'leads': [
      {'id': 1, 'name': 'Bisi Adeyemi', 'company': 'Bisi Bakes', 'status': 'new', 'source': 'Instagram'},
    ],
    'contacts': [],
    'campaigns': [],
    'tickets': [
      {'id': 8, 'subject': 'Paid but still unpaid', 'status': 'open', 'priority': 'high', 'client': {'name': 'Mama Chidi Stores'}, 'messages': [{'message': 'I transferred yesterday.', 'created_at': '2026-11-22T09:00:00.000000Z'}]},
    ],
    'departments': [],
    'accounting/service-orders': [],
    'accounting/salaries': [],
    'accounting/currencies': [
      {'id': 1, 'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦', 'exchange_rate': '1.00'},
    ],
    'contracts/manage': [],
    'contracts/templates': [],
    'pm/projects': [
      {'id': 3, 'name': 'Obi wedding outfits', 'client_id': 11, 'client': {'name': 'Mama Chidi Stores'}, 'manager_id': 3, 'status': 'active', 'budget': '850000.00'},
    ],
    'pm/milestones': [],
    'pm/tasks': [
      {'id': 31, 'project_id': 3, 'title': 'Cut fabric', 'status': 'todo', 'priority': 'high'},
      {'id': 32, 'project_id': 4, 'title': 'Other project task', 'status': 'todo'},
    ],
    'pm/work-logs': [],
  };

  static http.Response validation(Map<String, List<String>> errors) => http.Response(
      jsonEncode({'success': false, 'message': 'The given data was invalid.', 'errors': errors}), 422,
      headers: {'content-type': 'application/json'});

  late final client = MockClient((req) async {
    requests.add(req);
    final path = req.url.path;
    if (expireToken && path != '/api/v1/auth/login') {
      return http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401);
    }
    final mobile = _mobileRoutes(req, path);
    if (mobile != null) return mobile;
    switch ((req.method, path)) {
      case ('POST', '/api/v1/auth/login'):
        final b = jsonDecode(req.body) as Map;
        if (b['password'] != 'secret123') {
          return http.Response(jsonEncode({'success': false, 'message': 'Invalid credentials.'}), 401);
        }
        if (twoFactor) return ok({'requires_2fa': true, 'challenge_token': 'ch-1', 'type': 'admin'});
        return ok({'token': '1|abc', 'user': {'id': 7, 'name': 'Ada Obi', 'email': b['email'], 'type': loginType}});
      case ('POST', '/api/v1/auth/forgot-password'):
        return http.Response(jsonEncode({'success': true, 'message': 'Password reset link sent to your email.'}), 200);
      case ('GET', '/api/v1/admin/profile'):
        return ok({'id': 7, 'name': 'Ada Obi', 'email': 'ada@shop.ng', 'role': 'owner', 'phone': '+2348035550142', 'avatar': ''});
      case ('GET', '/api/v1/admin/clients'):
        return ok(page([
          {'id': 11, 'name': 'Mama Chidi Stores', 'email': 'chidi@mail.com', 'phone': '08055550110', 'description': 'Prefers WhatsApp'},
        ]));
      case ('POST', '/api/v1/admin/clients'):
        return ok({'id': 99, ...jsonDecode(req.body) as Map<String, dynamic>}, 201);
      case ('GET', '/api/v1/admin/accounting/invoices'):
        final p = int.parse(req.url.queryParameters['page'] ?? '1');
        return ok(page(p == 1
            ? [
                {'id': 21, 'invoice_number': 'INV-0021', 'client_id': 11, 'client_name': 'Mama Chidi Stores', 'total_amount': '37000.00', 'discount_amount': '0.00', 'tax_amount': '0.00', 'status': 'sent', 'due_date': '2099-01-10T00:00:00.000000Z', 'issue_date': '2026-11-20T00:00:00.000000Z'},
              ]
            : [
                {'id': 22, 'invoice_number': 'INV-0022', 'client_id': 11, 'total_amount': '10000.00', 'status': 'paid', 'paid_at': '2026-11-21T10:00:00.000000Z', 'issue_date': '2026-11-19T00:00:00.000000Z'},
              ], last: 2, current: p));
      case ('GET', '/api/v1/admin/accounting/invoices/21'):
        return ok({'id': 21, 'total_amount': '37000.00', 'items': [
          {'title': 'Ankara', 'quantity': '4.00', 'unit_price': '6500.00', 'total': '26000.00'},
          {'title': 'Gown', 'quantity': '1.00', 'unit_price': '11000.00', 'total': '11000.00'},
        ]});
      case ('POST', '/api/v1/admin/accounting/invoices'):
        return ok({'id': 30, 'invoice_number': 'INV-0030', ...jsonDecode(req.body) as Map<String, dynamic>}, 201);
      case ('GET', '/api/v1/admin/accounting/quotes'):
        return ok(page([
          {'id': 5, 'quote_number': 'QT-005', 'client_id': 11, 'total_amount': '5375.00', 'tax_amount': '375.00', 'status': 'approved', 'issue_date': '2026-11-01T00:00:00.000000Z', 'valid_until': '2026-11-15T00:00:00.000000Z'},
        ]));
      case ('GET', '/api/v1/admin/accounting/transactions'):
        return ok(page([
          {'id': 41, 'payable_type': r'Modules\Accounting\Models\Invoice', 'payable_id': 21, 'amount': '20000.00', 'status': 'successful', 'provider': 'billway', 'reference': 'BW-1', 'paid_at': '2026-11-22T09:00:00.000000Z'},
          {'id': 42, 'payable_type': r'Modules\Admin\Models\SalaryDisbursement', 'payable_id': 1, 'amount': '50000.00', 'status': 'successful', 'type': 'debit'},
        ]));
      case ('GET', '/api/v1/admin/team-members'):
        return ok(page([
          {'id': 3, 'name': 'Segun Ajayi', 'email': 'segun@mail.com', 'role': 'bdm', 'status': 'active'},
          {'id': 4, 'name': 'Kola Damola', 'email': 'kola@mail.com', 'role': 'accountant', 'status': 'inactive'},
        ]));
      case ('POST', '/api/v1/admin/team-members'):
        return ok({'id': 77, ...jsonDecode(req.body) as Map<String, dynamic>}, 201);
      case ('GET', '/api/v1/admin/notifications'):
        return ok(page([
          {'id': 'n-1', 'type': r'App\Notifications\PaymentReceived', 'data': {'title': 'Payment received', 'body': '₦20,000 from Mama Chidi'}, 'read_at': null, 'created_at': '2026-11-22T09:00:00.000000Z'},
        ]));
      case ('POST', '/api/v1/admin/notifications/read-all'):
      case ('POST', '/api/v1/admin/logout'):
      case ('DELETE', '/api/v1/admin/profile'):
        return ok([]);
      case ('POST', '/api/v1/auth/reset-password'):
        final b = jsonDecode(req.body) as Map;
        if (b['token'] != 'tok-123') return validation({'email': ['This password reset token is invalid.']});
        return ok([]);
      case ('POST', '/api/v1/admin/profile'):
        return ok({'id': 7, ...jsonDecode(req.body) as Map<String, dynamic>, 'email': 'ada@shop.ng'});
      case ('POST', '/api/v1/admin/profile/picture'):
        return ok({'avatar': 'https://x.test/storage/avatar.jpg'});
      case ('POST', '/api/v1/admin/change-password'):
        final b = jsonDecode(req.body) as Map;
        if (b['current_password'] != 'secret123') return validation({'current_password': ['The current password is incorrect.']});
        return ok([]);
      case ('GET', '/api/v1/admin/dashboard'):
        return ok({'stats': {'revenue_this_month': 120000.0, 'revenue_growth': 12.5, 'total_revenue': 900000.0, 'unpaid_invoices_count': 3, 'active_projects': 2, 'salaries_this_month': 50000.0, 'safe_haven_balance': 0}});
      case ('GET', '/api/v1/admin/accounting/balance-sheet'):
        return ok({
          'assets': {'total': 500000, 'accounts': [{'name': 'Cash at bank', 'current_balance': '500000.00'}]},
          'liabilities': {'total': 100000, 'accounts': [{'name': 'Supplier bills', 'current_balance': '100000.00'}]},
          'equity': {'total': 400000, 'accounts': [{'name': 'Owner capital', 'current_balance': '400000.00'}]},
        });
    }

    // Project chat
    final chat = RegExp(r'^/api/v1/admin/pm/projects/(\d+)/chat(/status)?$').firstMatch(path);
    if (chat != null) {
      if (chat.group(2) != null) return ok({'status': (jsonDecode(req.body) as Map)['status']});
      if (req.method == 'GET') {
        return ok({'conversation': {'id': 1, 'status': chatStatus}, 'messages': page(List.of(chatMessages.reversed))});
      }
      final multipart = req.headers['content-type']?.startsWith('multipart/') ?? false;
      final content = multipart ? RegExp(r'name="content"\r\n\r\n([^\r]*)').firstMatch(utf8.decode(req.bodyBytes, allowMalformed: true))?.group(1) ?? '' : (jsonDecode(req.body) as Map)['content'];
      final m = {'id': 500 + chatMessages.length, 'content': content, 'sender_id': 7, 'sender_type': r'App\Models\Admin', 'sender': {'name': 'Ada Obi'}, 'created_at': DateTime.now().toIso8601String(), 'media': []};
      chatMessages.add(m);
      return ok(m, 201);
    }
    if (path.startsWith('/api/v1/admin/pm/projects/chat/messages/')) return ok([]);

    // Generic admin resources (leads, contacts, projects, tasks, …)
    final res = RegExp(r'^/api/v1/admin/((?:pm|accounting|contracts)/[a-z-]+|[a-z-]+)(?:/(\d+))?(/status)?$').firstMatch(path);
    if (res != null && resources.containsKey(res.group(1))) {
      final list = resources[res.group(1)]!;
      final id = res.group(2);
      Map<String, dynamic>? find() => list.where((m) => '${m['id']}' == id).firstOrNull;
      switch (req.method) {
        case 'GET' when id == null:
          final q = Map.of(req.url.queryParameters)..remove('page');
          return ok(page([for (final m in list) if (q.entries.every((e) => '${m[e.key]}' == e.value)) m]));
        case 'GET':
          return find() == null ? http.Response(jsonEncode({'success': false, 'message': 'Not found.'}), 404) : ok(find());
        case 'POST':
          final b = jsonDecode(req.body) as Map<String, dynamic>;
          if (res.group(1) == 'leads' && (b['name'] ?? '').toString().isEmpty) return validation({'name': ['The name field is required.']});
          final m = {...b, 'id': 900 + list.length};
          list.insert(0, m);
          return ok(m, 201);
        case 'PUT':
          find()?.addAll(jsonDecode(req.body) as Map<String, dynamic>);
          return ok(find());
        case 'PATCH':
          find()?['status'] = (jsonDecode(req.body) as Map)['status'];
          return ok(find());
        case 'DELETE':
          list.removeWhere((m) => '${m['id']}' == id);
          return ok([]);
      }
    }
    if (req.method == 'DELETE' || (req.method == 'PATCH' && path.endsWith('/read'))) return ok([]);
    return http.Response(jsonEncode({'success': false, 'message': 'No route ${req.method} $path'}), 404);
  });

  // ---------------------------------------------------------------- feature/mobile-api routes

  /// When true, login stops at the 2FA step (code 123456 passes).
  bool twoFactor = false;
  bool twoFactorEnabled = false;

  /// Wallet balance; invoice creation needs ₦50 when [chargeInvoices] is on.
  double wallet = 3250;
  bool chargeInvoices = false;

  final products = <Map<String, dynamic>>[
    {'id': 61, 'name': 'Ankara fabric', 'slug': 'ankara-fabric-123', 'category': 'Fabrics', 'price': '6500.00', 'sale_price': '6000.00', 'stock_quantity': 4, 'is_active': true, 'image_url': '/storage/store/products/a.jpg', 'image_full_url': 'https://x.test/storage/store/products/a.jpg'},
    {'id': 62, 'name': 'Gele', 'slug': 'gele-456', 'category': 'General', 'price': '3000.00', 'sale_price': null, 'stock_quantity': 0, 'is_active': false},
  ];
  final orders = <Map<String, dynamic>>[
    {'id': 71, 'order_number': 'ORD-1011', 'customer_name': 'Funke A.', 'customer_email': 'funke@mail.com', 'customer_phone': '08030000000', 'shipping_address': '12 Allen Ave', 'total_amount': '12000.00', 'status': 'paid', 'paid_at': '2026-11-23T10:00:00.000000Z', 'payment_method': 'bank_transfer', 'created_at': '2026-11-23T09:00:00.000000Z', 'items': [{'product_name': 'Ankara fabric', 'unit_price': '6000.00', 'quantity': 2}]},
  ];
  Map<String, dynamic> storefront = {'store_name': 'Ada Fabrics', 'store_tagline': '', 'store_description': 'Fabrics', 'store_phone': '+234 8035550142', 'store_email': 'ada@shop.ng', 'store_banner': null, 'currency': 'NGN', 'slug': 'ada-fabrics', 'url': 'https://app.bizpaddi.com/store/ada-fabrics', 'custom_domain': null, 'has_custom_domain_plan': false, 'expected_cname': 'stores.bizpaddi.com', 'domain_status': null};
  final kycDocs = <String, Map<String, dynamic>>{
    'cac_certificate': {'document_type': 'cac_certificate', 'status': 'verified', 'file_name': 'cac.pdf'},
  };

  static String _field(http.Request req, String name) =>
      RegExp('name="$name"\r\n\r\n([^\r]*)').firstMatch(utf8.decode(req.bodyBytes, allowMalformed: true))?.group(1) ?? '';
  static bool _hasFile(http.Request req, String name) => utf8.decode(req.bodyBytes, allowMalformed: true).contains('name="$name"; filename=');

  Map<String, dynamic> _kyc() {
    const types = ['cac_certificate', 'director_id', 'utility_bill', 'tax_clearance'];
    final docs = [for (final t in types) kycDocs[t] ?? {'document_type': t, 'status': 'missing'}];
    final all = docs.every((d) => d['status'] == 'verified');
    return {'status': all ? 'verified' : (docs.any((d) => d['status'] == 'missing') ? 'incomplete' : 'in_review'), 'documents': docs};
  }

  http.Response? _mobileRoutes(http.Request req, String path) {
    Map<String, dynamic> body() => req.body.isEmpty ? {} : jsonDecode(req.body) as Map<String, dynamic>;
    final m = req.method;

    // Auth: 2FA + sign-up
    if (m == 'POST' && path == '/api/v1/auth/2fa-challenge') {
      final b = body();
      if (b['challenge_token'] != 'ch-1' || (b['code'] != '123456' && b['code'] != 'ABCD-1234')) {
        return validation({'code': ['Invalid authentication code or recovery key.']});
      }
      return ok({'token': '2|tfa', 'user': {'id': 7, 'name': 'Ada Obi', 'email': 'ada@shop.ng', 'type': 'admin'}});
    }
    if (m == 'POST' && path == '/api/v1/auth/register/send-otp') {
      if (body()['email'] == 'taken@shop.ng') return validation({'email': ['An account with this email address already exists. Please sign in instead.']});
      return ok({'expires_in': 900, 'resend_in': 60});
    }
    if (m == 'POST' && path == '/api/v1/auth/register/verify-otp') {
      return body()['otp_code'] == '654321' ? ok(null) : validation({'otp_code': ['Invalid or expired verification code.']});
    }
    if (m == 'POST' && path == '/api/v1/auth/register') {
      final b = body();
      if (b['otp_code'] != '654321') return validation({'otp_code': ['Invalid or expired verification code.']});
      return ok({'token': '3|new', 'user': {'id': 8, 'name': '${b['first_name']} ${b['last_name']}', 'email': b['email'], 'type': 'admin'}, 'tenant': {'id': 2, 'name': b['company_name']}, 'needs_plan_activation': false}, 201);
    }

    // Invoices & quotes
    final put = RegExp(r'^/api/v1/admin/accounting/(invoices|quotes)/(\d+)$').firstMatch(path);
    if (put != null && m == 'PUT') return ok({...body(), 'id': int.parse(put.group(2)!)});
    final doc =RegExp(r'^/api/v1/admin/accounting/(invoices|quotes)/(\d+)/(send|mark-paid|pdf|approve|convert)$').firstMatch(path);
    if (doc != null) {
      final id = int.parse(doc.group(2)!);
      return switch (doc.group(3)) {
        'pdf' => http.Response.bytes([37, 80, 68, 70, 45, 49], 200, headers: {'content-type': 'application/pdf'}),
        'send' => ok({'id': id, 'status': 'sent', 'invoice_number': 'INV-00$id', 'quote_number': 'QT-00$id', 'total_amount': '37000.00'}),
        'mark-paid' => ok({'id': id, 'status': 'paid', 'invoice_number': 'INV-00$id', 'total_amount': '37000.00', 'paid_at': '2026-11-24T10:00:00.000000Z'}),
        'approve' => ok({'id': id, 'status': 'approved'}),
        _ => ok({'id': 88, 'invoice_number': 'INV-0088', 'client_id': 11, 'status': 'draft', 'total_amount': '5375.00', 'issue_date': '2026-11-24', 'items': [{'title': 'Ankara', 'quantity': '1.00', 'unit_price': '5000.00'}]}, 201),
      };
    }
    if (m == 'POST' && path == '/api/v1/admin/accounting/invoices' && chargeInvoices && wallet < 50) {
      return http.Response.bytes(utf8.encode(jsonEncode({'success': false, 'message': 'Insufficient Operating Wallet balance (₦0.00).', 'code': 'billing_required'})), 402, headers: {'content-type': 'application/json'});
    }

    // Store
    if (path == '/api/v1/admin/store/products' && m == 'GET') return ok(page(products));
    final prod = RegExp(r'^/api/v1/admin/store/products(?:/(\d+))?$').firstMatch(path);
    if (prod != null && m == 'POST') {
      final id = prod.group(1);
      final fields = {
        for (final f in ['name', 'category', 'price', 'sale_price', 'stock_quantity', 'description', 'is_active']) f: _field(req, f),
      };
      if (fields['name']!.isEmpty) return validation({'name': ['The name field is required.']});
      final existing = id == null ? null : products.where((p) => '${p['id']}' == id).firstOrNull;
      final p = existing ?? {'id': 600 + products.length, 'slug': 'new-1'};
      p.addAll({
        ...fields,
        'sale_price': fields['sale_price']!.isEmpty ? null : fields['sale_price'],
        'is_active': fields['is_active'] == '1',
        if (_hasFile(req, 'image')) 'image_full_url': 'https://x.test/storage/store/products/new.jpg',
        if (_field(req, 'remove_image') == '1') 'image_full_url': null,
      });
      if (existing == null) products.insert(0, p);
      return ok(p, existing == null ? 201 : 200);
    }
    if (prod != null && m == 'DELETE') {
      products.removeWhere((p) => '${p['id']}' == prod.group(1));
      return ok([]);
    }
    if (path == '/api/v1/admin/store/orders' && m == 'GET') return ok(page(orders));
    final ord = RegExp(r'^/api/v1/admin/store/orders/(\d+)/status$').firstMatch(path);
    if (ord != null && m == 'PATCH') {
      final o = orders.firstWhere((o) => '${o['id']}' == ord.group(1));
      o['status'] = body()['status'];
      return ok(o);
    }
    if (path == '/api/v1/admin/storefront') {
      if (m == 'GET') return ok(storefront);
      storefront = {
        ...storefront,
        'store_name': _field(req, 'store_name'),
        'store_tagline': _field(req, 'store_tagline'),
        'store_description': _field(req, 'store_description'),
        'store_phone': _field(req, 'store_phone'),
        'store_email': _field(req, 'store_email'),
        if (_hasFile(req, 'store_banner')) 'store_banner': 'https://x.test/storage/store/banners/b.jpg',
      };
      return ok(storefront);
    }

    // KYC
    if (path == '/api/v1/admin/kyc') {
      if (m == 'GET') return ok(_kyc());
      final type = _field(req, 'document_type');
      kycDocs[type] = {'document_type': type, 'status': 'pending', 'file_name': 'upload.jpg'};
      return ok(kycDocs[type], 201);
    }

    // Billing
    if (path == '/api/v1/admin/billing' && m == 'GET') {
      return ok({
        'billing_model': 'payg',
        'wallet_balance': wallet,
        'currency': 'NGN',
        'has_access': true,
        'on_trial': false,
        'subscription': null,
        'plans': [{'id': 1, 'name': 'Starter', 'price': 8000, 'billing_interval': 'monthly', 'features': ['Unlimited invoices']}],
        'wallet_transactions': [{'id': 1, 'type': 'credit', 'amount': 5000, 'description': 'Wallet top-up', 'created_at': '2026-11-22T09:00:00.000000Z'}],
        'rates': [{'name': 'Invoice', 'fee': 50}],
      });
    }
    if (m == 'POST' && (path == '/api/v1/admin/billing/topup' || path == '/api/v1/admin/billing/checkout')) {
      return ok({'reference': 'BP_WLT_1', 'amount': body()['amount'] ?? 8000, 'bank_name': 'Wema Bank', 'account_number': '9900112233', 'account_name': 'Bizpaddi / Ada Fabrics'}, 201);
    }
    if (m == 'GET' && path == '/api/v1/admin/billing/status') return ok({'reference': req.url.queryParameters['reference'], 'status': 'pending'});

    // Push tokens & 2FA settings
    if (path == '/api/v1/admin/device-tokens') return ok([], m == 'POST' ? 201 : 200);
    if (path == '/api/v1/admin/2fa' && m == 'GET') {
      return ok(twoFactorEnabled ? {'enabled': true} : {'enabled': false, 'secret': 'JBSWY3DPEHPK3PXP', 'otpauth_url': 'otpauth://totp/Bizpaddi:ada@shop.ng?secret=JBSWY3DPEHPK3PXP&issuer=Bizpaddi'});
    }
    if (path == '/api/v1/admin/2fa/confirm') {
      if (body()['code'] != '123456') return validation({'code': ['Invalid 6-digit code.']});
      twoFactorEnabled = true;
      return ok({'enabled': true, 'recovery_codes': ['ABCD-1234', 'EFGH-5678']});
    }
    if (path == '/api/v1/admin/2fa/disable') {
      if (body()['password'] != 'secret123') return validation({'password': ['Incorrect password.']});
      twoFactorEnabled = false;
      return ok({'enabled': false});
    }
    return null;
  }
}


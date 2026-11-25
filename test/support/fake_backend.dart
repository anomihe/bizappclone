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
    switch ((req.method, path)) {
      case ('POST', '/api/v1/auth/login'):
        final b = jsonDecode(req.body) as Map;
        if (b['password'] != 'secret123') {
          return http.Response(jsonEncode({'success': false, 'message': 'Invalid credentials.'}), 401);
        }
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
}


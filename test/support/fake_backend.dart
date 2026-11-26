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
    final chat = RegExp(r'^/api/v1/(?:admin/pm|team|client)/projects/(\d+)/chat(/status)?$').firstMatch(path);
    if (chat != null) {
      if (chat.group(2) != null) return ok({'status': (jsonDecode(req.body) as Map)['status']});
      if (req.method == 'GET') {
        return ok({'conversation': {'id': 1, 'status': chatStatus}, 'messages': page(List.of(chatMessages.reversed))});
      }
      final multipart = req.headers['content-type']?.startsWith('multipart/') ?? false;
      final content = multipart ? RegExp(r'name="content"\r\n\r\n([^\r]*)').firstMatch(utf8.decode(req.bodyBytes, allowMalformed: true))?.group(1) ?? '' : (jsonDecode(req.body) as Map)['content'];
      // The sender is whoever calls: owner (admin), staff (team) or customer (client).
      final (sid, stype) = path.contains('/client/')
          ? (11, r'Modules\Clients\Models\Client')
          : (path.contains('/team/') ? (5, r'App\Models\User') : (7, r'App\Models\Admin'));
      final m = {'id': 500 + chatMessages.length, 'content': content, 'sender_id': sid, 'sender_type': stype, 'sender': {'name': 'Me'}, 'created_at': DateTime.now().toIso8601String(), 'media': []};
      chatMessages.add(m);
      return ok(m, 201);
    }
    if (RegExp(r'^/api/v1/(admin/pm|team|client)/projects/chat/messages/').hasMatch(path)) return ok([]);

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

  // ---------------------------------------------------------------- staff & customer portals

  /// Staff job role returned by /team/profile (`pm` = project manager).
  String staffRole = 'bdm';
  Map<String, dynamic>? attendanceToday;
  Map<String, dynamic>? activeSession;
  final staffBanks = <Map<String, dynamic>>[];
  final tickets = <Map<String, dynamic>>[];
  final forgotGuards = <String>[];

  http.Response? _portalRoutes(http.Request req, String path) {
    Map<String, dynamic> body() => req.body.isEmpty ? {} : jsonDecode(req.body) as Map<String, dynamic>;
    final m = req.method;
    http.Response err(String msg, int code) => http.Response.bytes(utf8.encode(jsonEncode({'success': false, 'message': msg})), code, headers: {'content-type': 'application/json'});

    if (m == 'POST' && path == '/api/v1/auth/forgot-password') {
      final guard = '${body()['guard']}';
      forgotGuards.add(guard);
      // This email only exists as a staff account.
      final staffOnly = '${body()['email']}' == 'amaka@shop.ng';
      return guard == 'team' || (!staffOnly && guard == 'admin') ? ok(null) : http.Response(jsonEncode({'success': false, 'message': 'Unable to send reset link.'}), 400);
    }

    // ---- staff
    if (path.startsWith('/api/v1/team/')) {
      final p = path.substring('/api/v1/team'.length);
      switch ((m, p)) {
        case ('GET', '/profile'):
          return ok({'id': 5, 'name': 'Amaka Eze', 'email': 'amaka@shop.ng', 'role': staffRole, 'department': {'name': 'Production'}, 'phone': '0803', 'status': 'active', 'avatar': ''});
        case ('POST', '/logout'):
          return ok([]);
        case ('GET', '/dashboard'):
          return ok({
            'stats': {'pending_tasks': 2, 'completed_tasks': 1, 'total_tasks': 4, 'in_review_tasks': 1},
            'recent_tasks': [
              {'id': 31, 'title': 'Cut fabric', 'status': 'in_progress', 'priority': 'high', 'due_date': '2099-01-01', 'project': {'id': 3, 'title': 'Obi wedding'}},
            ],
            'attendance_today': attendanceToday == null ? null : {'clock_in': attendanceToday!['clock_in'], 'clock_out': attendanceToday!['clock_out'], 'status': 'clocked_in'},
          });
        case ('GET', '/kanban'):
          return ok({
            'todo': [{'id': 32, 'title': 'Sew gowns', 'priority': 'medium', 'project': {'id': 3, 'name': 'Obi wedding'}}],
            'in_progress': [{'id': 31, 'title': 'Cut fabric', 'priority': 'high', 'project': {'id': 3, 'name': 'Obi wedding'}}],
            'review': [],
            'done': [],
          });
        case ('GET', '/tasks'):
          return ok(page([{'id': 31, 'title': 'Cut fabric', 'status': 'in_progress', 'project': {'id': 3, 'name': 'Obi wedding'}}]));
        case ('GET', '/attendance'):
          return ok({'today': attendanceToday, 'records': page([?attendanceToday])});
        case ('POST', '/attendance/clock-in'):
          if (attendanceToday != null) return err('You have already clocked in today.', 400);
          attendanceToday = {'id': 1, 'date': '2026-11-25', 'clock_in': '08:01:00', 'clock_out': null};
          return ok(attendanceToday, 201);
        case ('POST', '/attendance/clock-out'):
          attendanceToday?['clock_out'] = '17:00:00';
          return ok(attendanceToday);
        case ('GET', '/work-logs'):
          return ok({'active_session': activeSession, 'history': page([])});
        case ('POST', '/work-logs/check-in'):
          final b = body();
          if (b['planned_projects'] is! List || (b['planned_tasks'] is! List && b['session_goal'] == null)) {
            return validation({'planned_tasks': ['The planned tasks field is required.']});
          }
          activeSession = {'id': 70, 'status': 'in_progress', 'start_time': '2026-11-25T09:00:00Z', 'planned_tasks': (b['planned_tasks'] as List?)?.join(', ')};
          return ok(activeSession, 201);
        case ('GET', '/projects'):
          return ok(page([{'id': 3, 'name': 'Obi wedding', 'status': 'in_progress', 'client': {'name': 'Mama Chidi'}}]));
        case ('GET', '/wallet'):
          return ok({'balance': '45000.00', 'virtual_account': {'bank_name': 'Wema Bank', 'account_number': '9912345678'}});
        case ('GET', '/earnings'):
          return ok(page([{'id': 1, 'amount': '45000.00', 'status': 'successful', 'description': 'November salary', 'payment_date': '2026-11-22'}]));
        case ('GET', '/bank-accounts'):
          return ok(staffBanks);
        case ('GET', '/bank-accounts/banks'):
          return ok([{'name': 'GTBank', 'code': '058'}]);
        case ('POST', '/bank-accounts'):
          final b = body();
          if (!RegExp(r'^\d{10}$').hasMatch('${b['account_number']}')) return validation({'account_number': ['The account number must be 10 digits.']});
          final a = {'id': 1, ...b, 'account_name': 'AMAKA EZE', 'bank_name': 'GTBank', 'is_primary': true};
          staffBanks.add(a);
          return ok(a, 201);
        case ('POST', '/reports'):
          return ok({'id': 1, ...body()}, 201);
        case ('GET', '/pm/dashboard'):
          return staffRole == 'pm' ? ok({'total_projects': 1, 'active_projects': 1, 'pending_tasks': 2, 'completed_tasks': 0}) : err('Unauthorized access.', 403);
      }
      final status = RegExp(r'^/tasks/(\d+)/status$').firstMatch(p);
      if (status != null && m == 'PATCH') {
        if (body()['status'] == 'done' && staffRole != 'pm') return err('Only Project Managers can mark tasks as Completed.', 403);
        return ok({'id': int.parse(status.group(1)!), 'status': body()['status']});
      }
      final out = RegExp(r'^/work-logs/(\d+)/check-out$').firstMatch(p);
      if (out != null && m == 'PUT') {
        if ((body()['actual_tasks'] ?? '').toString().isEmpty && body()['key_issues'] == null) return validation({'actual_tasks': ['The actual tasks field is required.']});
        activeSession = null;
        return ok({'id': 70, 'status': 'completed'});
      }
    }

    // ---- customer
    if (path.startsWith('/api/v1/client/')) {
      final p = path.substring('/api/v1/client'.length);
      switch ((m, p)) {
        case ('GET', '/profile'):
          return ok({'id': 11, 'name': 'Chidi Okafor', 'email': 'chidi@mail.com', 'company_name': 'Mama Chidi Stores', 'avatar': ''});
        case ('POST', '/logout'):
          return ok([]);
        case ('GET', '/invoices'):
          return ok(page([
            {'id': 21, 'invoice_number': 'INV-0021', 'status': 'sent', 'total_amount': '37000.00', 'due_date': '2099-01-10', 'issue_date': '2026-11-20'},
            {'id': 22, 'invoice_number': 'INV-0022', 'status': 'paid', 'total_amount': '10000.00', 'issue_date': '2026-11-01'},
          ]));
        case ('GET', '/invoices/21'):
          return ok({'id': 21, 'invoice_number': 'INV-0021', 'status': 'sent', 'total_amount': '37000.00', 'items': [{'title': 'Ankara', 'quantity': '4.00', 'unit_price': '6500.00', 'total': '26000.00'}]});
        case ('GET', '/quotes'):
          return ok(page([]));
        case ('GET', '/projects'):
          return ok(page([{'id': 3, 'name': 'Obi wedding', 'status': 'in_progress', 'manager': {'name': 'Segun Ajayi'}}]));
        case ('GET', '/tickets'):
          return ok(page(tickets));
        case ('POST', '/tickets'):
          final b = body();
          if (!const ['low', 'medium', 'high', 'urgent'].contains(b['priority'])) return validation({'priority': ['The selected priority is invalid.']});
          final t = {'id': 40 + tickets.length, 'ticket_id': 'TKT-1', 'status': 'open', ...b};
          tickets.add(t);
          return ok(t, 201);
        case ('GET', '/support-settings'):
          return ok({'support_email': 'help@bizpaddi.com', 'support_phone': '', 'support_whatsapp': '+234 803 000 0000'});
        case ('POST', '/update-device-token'):
          return ok([]);
      }
    }
    return null;
  }

  http.Response? _mobileRoutes(http.Request req, String path) {
    final portal = _portalRoutes(req, path);
    if (portal != null) return portal;
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
    return _newMobileRoutes(req, path, body);
  }

  // ---------------------------------------------------------------- payment links, credit/refunds, business, payouts, support

  final paymentLinks = <Map<String, dynamic>>[
    {'id': 51, 'number': 'PL-0001', 'slug': 'gucci-bags-a1b2', 'purpose': 'Gucci Bags', 'amount': '25000.00', 'amount_paid': '0.00', 'client_id': null, 'customer_name': null, 'customer_phone': '', 'allow_part_payment': false, 'status': 'active', 'effective_status': 'active', 'expires_at': null, 'url': 'https://app.bizpaddi.com/pay/gucci-bags-a1b2', 'created_at': '2026-11-23T09:00:00.000000Z', 'payments': []},
  ];
  final creditNotes = <Map<String, dynamic>>[];
  final refunds = <Map<String, dynamic>>[];
  Map<String, dynamic> business = {'name': 'Ada Fabrics', 'type': 'Fashion', 'registration_number': 'RC123456', 'phone': '+234 8035550142', 'email': 'ada@shop.ng', 'address': '12 Allen Ave, Ikeja', 'currency': 'NGN', 'logo_url': null};
  Map<String, dynamic>? payoutAccount;
  final payoutHistory = <Map<String, dynamic>>[];
  String? settlementOtp;
  Map<String, bool> notificationPrefs = {'payments': true, 'invoices': true, 'orders': true, 'refunds': true, 'product_updates': false};
  int otherSessions = 2;
  final supportMessages = <Map<String, dynamic>>[
    {'id': 1, 'sender_type': 'support', 'message': 'Hi Ada, how can we help?', 'attachment_url': null, 'created_at': '2026-11-22T09:00:00.000000Z'},
  ];

  http.Response? _newMobileRoutes(http.Request req, String path, Map<String, dynamic> Function() body) {
    final m = req.method;
    const admin = '/api/v1/admin';
    http.Response notFound() => http.Response(jsonEncode({'success': false, 'message': 'Not found.'}), 404);

    // Payment links
    if (path == '$admin/payment-links') {
      if (m == 'GET') return ok(page(paymentLinks));
      final b = body();
      if ((b['purpose'] ?? '').toString().trim().isEmpty) return validation({'purpose': ['The purpose field is required.']});
      final id = 52 + paymentLinks.length;
      final l = <String, dynamic>{
        ...b,
        'id': id,
        'number': 'PL-${id.toString().padLeft(4, '0')}',
        'slug': 'link-$id',
        'amount': '${b['amount']}',
        'amount_paid': '0.00',
        'status': 'active',
        'effective_status': 'active',
        'url': 'https://app.bizpaddi.com/pay/link-$id',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'payments': [],
      };
      paymentLinks.insert(0, l);
      return ok(l, 201);
    }
    final pl = RegExp(r'^/api/v1/admin/payment-links/(\d+)(?:/(disable|enable))?$').firstMatch(path);
    if (pl != null) {
      final l = paymentLinks.where((x) => '${x['id']}' == pl.group(1)).firstOrNull;
      if (l == null) return notFound();
      switch (pl.group(2)) {
        case 'disable':
          l['status'] = l['effective_status'] = 'disabled';
        case 'enable':
          l['status'] = l['effective_status'] = 'active';
        default:
          if (m == 'PATCH') l.addAll(body());
      }
      return ok(l);
    }

    // Credit notes & refunds
    double refundable(int invoiceId) {
      final used = [...creditNotes, ...refunds.where((r) => r['stage'] != 'cancelled')]
          .where((x) => x['invoice_id'] == invoiceId)
          .fold<double>(0, (s, x) => s + double.parse('${x['amount']}'));
      return 37000 - used;
    }

    if (path == '$admin/accounting/credit-notes' && m == 'GET') {
      final id = int.tryParse(req.url.queryParameters['invoice_id'] ?? '');
      return ok([for (final c in creditNotes) if (id == null || c['invoice_id'] == id) c]);
    }
    if (path == '$admin/accounting/refunds' && m == 'GET') {
      final id = int.tryParse(req.url.queryParameters['invoice_id'] ?? '');
      return ok([for (final r in refunds) if (id == null || r['invoice_id'] == id) r]);
    }
    final cr = RegExp(r'^/api/v1/admin/accounting/invoices/(\d+)/(credit-notes|refunds)$').firstMatch(path);
    if (cr != null && m == 'POST') {
      final invoiceId = int.parse(cr.group(1)!);
      final b = body();
      final amount = (b['amount'] as num).toDouble();
      if (amount > refundable(invoiceId)) return validation({'amount': ['The amount is more than what can still be refunded on this invoice.']});
      final isNote = cr.group(2) == 'credit-notes';
      final list = isNote ? creditNotes : refunds;
      final row = {
        'id': 700 + creditNotes.length + refunds.length,
        'invoice_id': invoiceId,
        'amount': amount.toStringAsFixed(2),
        'reason': b['reason'],
        if (isNote) 'number': 'CN-${(creditNotes.length + 1).toString().padLeft(4, '0')}' else 'stage': 'requested',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      list.add(row);
      return ok(row, 201);
    }
    final cancel = RegExp(r'^/api/v1/admin/accounting/refunds/(\d+)/cancel$').firstMatch(path);
    if (cancel != null) {
      final r = refunds.where((x) => '${x['id']}' == cancel.group(1)).firstOrNull;
      if (r == null) return notFound();
      r['stage'] = 'cancelled';
      return ok(r);
    }

    // Business profile & logo
    if (path == '$admin/business') {
      if (m == 'GET') return ok(business);
      final b = body();
      if ('${b['name'] ?? ''}'.trim().isEmpty) return validation({'name': ['The name field is required.']});
      business = {...business, ...b};
      return ok(business);
    }
    if (path == '$admin/business/logo' && m == 'POST') {
      if (!_hasFile(req, 'logo')) return validation({'logo': ['The logo field is required.']});
      business['logo_url'] = 'https://x.test/storage/logos/logo.png';
      return ok({'logo_url': business['logo_url']});
    }

    // Payout (settlement) account
    if (path == '$admin/banks' && m == 'GET') {
      return ok([
        {'name': 'Access Bank', 'code': '044'},
        {'name': 'GTBank', 'code': '058'},
      ]);
    }
    if (path == '$admin/settlement-account/resolve') {
      final b = body();
      if (b['account_number'] == '0000000000') return validation({'account_number': ['We couldn’t find that account.']});
      return ok({'account_name': 'ADA FABRICS LTD'});
    }
    if (path == '$admin/settlement-account/send-otp') {
      settlementOtp = '246810';
      return ok({'expires_in': 600, 'sent_to': 'a***@shop.ng'});
    }
    if (path == '$admin/settlement-account') {
      if (m == 'GET') return ok({'account': payoutAccount, 'history': payoutHistory});
      final b = body();
      if (b['password'] != 'secret123') return validation({'password': ['Your password is incorrect.']});
      if (settlementOtp == null || b['otp'] != settlementOtp) return validation({'otp': ['The code is wrong or has expired.']});
      settlementOtp = null;
      final bank = b['bank_code'] == '058' ? 'GTBank' : 'Access Bank';
      final number = '${b['account_number']}';
      payoutAccount = {'bank_code': b['bank_code'], 'bank_name': bank, 'account_number_masked': '******${number.substring(6)}', 'account_name': 'ADA FABRICS LTD'};
      payoutHistory.insert(0, {'title': payoutHistory.isEmpty ? 'Payout account added' : 'Payout account changed', 'detail': '$bank · ******${number.substring(6)}', 'created_at': DateTime.now().toUtc().toIso8601String()});
      return ok({'account': payoutAccount, 'history': payoutHistory});
    }

    // Notification preferences & sessions
    if (path == '$admin/notification-preferences') {
      if (m == 'PUT') notificationPrefs = {...notificationPrefs, ...body().map((k, v) => MapEntry(k, v == true))};
      return ok(notificationPrefs);
    }
    if (path == '$admin/sessions/logout-others' && m == 'POST') {
      final n = otherSessions;
      otherSessions = 0;
      return ok({'revoked': n});
    }

    // Replies to customer tickets
    final reply = RegExp(r'^/api/v1/admin/tickets/(\d+)/replies$').firstMatch(path);
    if (reply != null && m == 'POST') {
      final t = resources['tickets']!.where((x) => '${x['id']}' == reply.group(1)).firstOrNull;
      if (t == null) return notFound();
      final text = '${body()['message'] ?? ''}';
      if (text.trim().isEmpty) return validation({'message': ['The message field is required.']});
      final msg = {'id': 990, 'message': text, 'is_admin': true, 'created_at': DateTime.now().toUtc().toIso8601String()};
      (t['messages'] as List).add(msg);
      if (t['status'] == 'open') t['status'] = 'in_progress';
      return ok(msg, 201);
    }

    // Owner ↔ Bizpaddi support chat
    if (path == '$admin/support/messages') {
      if (m == 'GET') return ok(supportMessages);
      final multipart = req.headers['content-type']?.startsWith('multipart/') ?? false;
      final text = multipart ? _field(req, 'message') : '${body()['message'] ?? ''}';
      final file = multipart && _hasFile(req, 'attachment');
      if (text.trim().isEmpty && !file) return validation({'message': ['Type a message or attach a file.']});
      final msg = {
        'id': supportMessages.length + 1,
        'sender_type': 'owner',
        'message': text,
        'attachment_url': file ? 'https://x.test/storage/support-attachments/a.jpg' : null,
        'attachment_name': file ? 'photo.jpg' : null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      supportMessages.add(msg);
      return ok(msg, 201);
    }
    return null;
  }
}


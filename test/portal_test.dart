import 'dart:convert';
import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'package:bizpaddi/features/portal/customer_app.dart';
import 'package:bizpaddi/features/portal/portal_kit.dart';
import 'package:bizpaddi/features/portal/staff_app.dart';
import 'package:bizpaddi/features/workspace/workspace_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/sample_workspace.dart';
import 'support/fake_backend.dart';

/// One app, three portals: staff (`/api/v1/team/*`) and customers
/// (`/api/v1/client/*`) next to business owners.
void main() {
  late FakeBackend backend;
  late MemoryTokenStore tokens;

  LiveSession session() {
    tokens = MemoryTokenStore();
    return LiveSession.instance = LiveSession(
      api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client),
      tokens: tokens,
      store: BizStore.instance,
    );
  }

  Future<void> signInAs(String type) async {
    backend.loginType = type;
    await session().login('someone@shop.ng', 'secret123');
    backend.requests.clear();
  }

  setUp(() => backend = FakeBackend());

  group('sign-in by role', () {
    test('staff login opens the staff app and remembers the role', () async {
      await signInAs('team');
      final s = LiveSession.instance;
      expect(s.role, AccountRole.staff);
      expect(s.portalAccount.value?.name, 'Amaka Eze');
      expect(s.portalAccount.value?.department, 'Production');
      expect(s.portalAccount.value?.isProjectManager, isFalse);
      expect(tokens.role, 'team');

      // App restart: the saved role decides which API to load.
      final again = LiveSession(api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client), tokens: tokens, store: BizStore.instance);
      await again.resume();
      expect(again.role, AccountRole.staff);
      expect(backend.requests.last.url.path, '/api/v1/team/profile');
    });

    test('customer login opens the customer app', () async {
      await signInAs('client');
      expect(LiveSession.instance.role, AccountRole.customer);
      expect(LiveSession.instance.portalAccount.value?.companyName, 'Mama Chidi Stores');
      expect(tokens.role, 'client');
    });

    test('owners still get the business workspace', () async {
      await signInAs('admin');
      expect(LiveSession.instance.role, AccountRole.owner);
      expect(LiveSession.instance.portalAccount.value, isNull);
      expect(BizStore.instance.customers, isNotEmpty);
    });

    test('logout uses the staff route', () async {
      await signInAs('team');
      await LiveSession.instance.logout();
      expect(backend.requests.last.url.path, '/api/v1/team/logout');
      expect(LiveSession.instance.api.token, isNull);
    });

    test('forgot password tries each account type until one matches', () async {
      session();
      await LiveSession.instance.sendResetLink('amaka@shop.ng');
      expect(backend.forgotGuards, ['admin', 'team']);
    });
  });

  group('staff API', () {
    setUp(() => signInAs('team'));

    test('clock in, then clocking in again shows the server message', () async {
      await PortalData.clockIn();
      expect(backend.requests.last.url.path, '/api/v1/team/attendance/clock-in');
      await expectLater(PortalData.clockIn(), throwsA(isA<ApiException>().having((e) => e.message, 'm', 'You have already clocked in today.')));
      await PortalData.clockOut();
      expect(backend.attendanceToday?['clock_out'], isNotNull);
    });

    test('only project managers can mark a task done', () async {
      await PortalData.setTaskStatus(31, 'review');
      expect(jsonDecode(backend.requests.last.body), {'status': 'review'});
      await expectLater(PortalData.setTaskStatus(31, 'done'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 403)));
    });

    test('work session check-in and check-out send the fields the API validates', () async {
      await PortalData.startSession({'planned_projects': [3], 'planned_tasks': ['Cut fabric'], 'resources_needed': ''});
      final b = jsonDecode(backend.requests.last.body) as Map;
      expect(b['planned_tasks'], ['Cut fabric']);
      final logs = await PortalData.workLogs();
      expect((logs['active_session'] as Map)['id'], 70);
      await PortalData.endSession(70, {'actual_tasks': 'Cut 4 gowns'});
      expect(backend.requests.last.url.path, '/api/v1/team/work-logs/70/check-out');
      expect(backend.activeSession, isNull);
    });

    test('salary account is verified on the server', () async {
      await expectLater(PortalData.saveBankAccount(null, '058', 'GTBank', '123'), throwsA(isA<ApiException>()));
      await PortalData.saveBankAccount(null, '058', 'GTBank', '0123456789');
      expect((await LiveSession.instance.team.bankAccounts()).single['account_name'], 'AMAKA EZE');
    });

    test('project chat uses the staff route and recognises my messages', () async {
      final chat = ProjectChatRepository.instance;
      final (msgs, _) = await chat.load(3, ChatType.team);
      expect(backend.requests.first.url.path, '/api/v1/team/projects/3/chat');
      expect(msgs.single.mine, isFalse);
      final sent = await chat.send(3, ChatType.team, 'On it');
      expect(sent.mine, isTrue, reason: r'sender App\Models\User with my id');
      expect(chat.canChangeStatus, isTrue);
    });

    test('PM-only routes are refused for other staff', () async {
      await expectLater(PortalData.pmDashboard(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 403)));
    });
  });

  group('customer API', () {
    setUp(() => signInAs('client'));

    test('tickets need a valid priority', () async {
      await PortalData.openTicket('Paid but unpaid', 'I sent it yesterday', 'high');
      expect(jsonDecode(backend.requests.last.body), {'subject': 'Paid but unpaid', 'message': 'I sent it yesterday', 'priority': 'high'});
      expect((await PortalData.tickets()).single['subject'], 'Paid but unpaid');
    });

    test('project chat uses the customer route; no status changes', () async {
      final chat = ProjectChatRepository.instance;
      await chat.load(3, ChatType.client);
      expect(backend.requests.first.url.path, '/api/v1/client/projects/3/chat');
      expect(backend.requests.first.url.queryParameters['type'], 'client_team');
      final sent = await chat.send(3, ChatType.client, 'Saturday works');
      expect(sent.mine, isTrue);
      expect(chat.canChangeStatus, isFalse);
    });

    test('pay link goes to the customer-portal pay page', () {
      expect(payUrl(21), 'https://x.test/dashboard/client/invoices/21/pay');
    });
  });

  group('screens (live)', () {
    Future<void> pump(WidgetTester tester, String type, Widget home) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => signInAs(type));
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('staff home: clock in from the attendance card', (tester) async {
      await pump(tester, 'team', const StaffShell());
      expect(find.text('Hi Amaka'), findsOneWidget);
      expect(find.text('Not clocked in today'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Clock In'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Clocked in at 08:01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff tasks tab shows the kanban column', (tester) async {
      await pump(tester, 'team', const StaffShell());
      await tester.tap(find.text('Tasks').last);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Sew gowns'), findsOneWidget);
      await tester.tap(find.text('In progress'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Cut fabric'), findsWidgets);
    });

    testWidgets('customer home shows what is owed', (tester) async {
      await pump(tester, 'client', const CustomerShell());
      expect(find.text('Hi Chidi'), findsOneWidget);
      expect(find.text('You owe'), findsOneWidget);
      expect(find.text('1 unpaid invoice'), findsOneWidget);
      expect(find.text('INV-0021'), findsOneWidget);
    });

    testWidgets('customer invoice offers Pay Now', (tester) async {
      await pump(tester, 'client', const CustomerInvoiceScreen(id: 21));
      expect(find.text('Pay Now'), findsOneWidget);
      expect(find.text('Copy Pay Link'), findsOneWidget);
      expect(find.textContaining('Ankara'), findsOneWidget);
    });
  });

  group('screens (demo)', () {
    for (final (role, shell) in [(AccountRole.staff, const StaffShell() as Widget), (AccountRole.customer, const CustomerShell())]) {
      testWidgets('${role.name} app renders every tab on sample data', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        addTearDown(() => LiveSession.instance.useTestAccount(AccountRole.owner));
        LiveSession.instance.useTestAccount(role);
        await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: shell));
        await tester.pump(const Duration(milliseconds: 200));
        for (final tab in role == AccountRole.staff ? ['Tasks', 'Work', 'Pay', 'More', 'Home'] : ['Invoices', 'Projects', 'Support', 'More', 'Home']) {
          await tester.tap(find.text(tab).last);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull, reason: tab);
        }
      });
    }
  });
}

import 'dart:convert';
import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/resources.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'package:bizpaddi/features/workspace/resource_screens.dart';
import 'package:bizpaddi/features/workspace/resource_specs.dart';
import 'package:bizpaddi/features/workspace/workspace_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_backend.dart';

/// Remaining `/api/v1/admin/*` endpoints: generic resources, project chat,
/// balance sheet, profile, password, deletes.
void main() {
  late FakeBackend backend;

  Future<void> signIn() async {
    LiveSession.instance = LiveSession(
      api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client),
      tokens: MemoryTokenStore(),
      store: BizStore.instance,
    );
    await LiveSession.instance.login('ada@shop.ng', 'secret123');
    backend.requests.clear();
  }

  setUp(() => backend = FakeBackend());

  group('API', () {
    setUp(signIn);
    final repo = ResourceRepository.instance;

    test('resource list, create, update, status, delete hit the admin routes', () async {
      final leads = await repo.list(Specs.leads);
      expect(leads.single['name'], 'Bisi Adeyemi');

      final created = await repo.create(Specs.leads, {'name': 'Tola', 'status': 'new'});
      expect(created['id'], isNotNull);
      await repo.update(Specs.leads, created['id'], {'status': 'qualified'});
      expect(backend.requests.last.method, 'PUT');
      expect(backend.requests.last.url.path, '/api/v1/admin/leads/${created['id']}');

      await repo.setStatus(Specs.projects, 3, 'completed');
      expect(backend.requests.last.method, 'PATCH');
      expect(backend.requests.last.url.path, '/api/v1/admin/pm/projects/3/status');
      expect(jsonDecode(backend.requests.last.body), {'status': 'completed'});

      await repo.delete(Specs.leads, created['id']);
      expect(backend.requests.last.method, 'DELETE');
    });

    test('tasks are filtered by project', () async {
      final tasks = await repo.list(Specs.tasks, query: {'project_id': 3});
      expect(tasks.map((t) => t['title']), ['Cut fabric']);
      expect(backend.requests.last.url.queryParameters['project_id'], '3');
    });

    test('services use the service-orders route', () async {
      await repo.create(Specs.services, {'name': 'Tailoring', 'base_price': 15000});
      expect(backend.requests.last.url.path, '/api/v1/admin/accounting/service-orders');
    });

    test('validation errors come back per field', () async {
      try {
        await repo.create(Specs.leads, {'name': ''});
        fail('expected 422');
      } on ApiException catch (e) {
        expect(e.statusCode, 422);
        expect(e.errorFor('name'), 'The name field is required.');
      }
    });

    test('project chat: load, send, status, edit, delete', () async {
      final chat = ProjectChatRepository.instance;
      final (msgs, status) = await chat.load(3, ChatType.client);
      expect(status, 'active');
      expect(msgs.single.content, 'Fabric is in.');
      expect(msgs.single.mine, isFalse);
      expect(backend.requests.first.url.queryParameters['type'], 'client_team');
      // Unread message from someone else gets marked read (in the background).
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.any((r) => r.url.path == '/api/v1/admin/pm/projects/chat/messages/400/read'), isTrue);

      final sent = await chat.send(3, ChatType.client, 'Saturday works');
      expect(sent.mine, isTrue, reason: 'sender_id matches the profile id');
      expect(sent.editable, isTrue);

      final photo = await chat.send(3, ChatType.team, 'Look', bytes: [1, 2, 3], filename: 'a.jpg');
      expect(photo.content, 'Look');
      expect(backend.requests.last.headers['content-type'], startsWith('multipart/form-data'));

      await chat.edit(3, ChatType.client, sent, 'Sunday works');
      expect(backend.requests.last.method, 'PUT');
      await chat.delete(3, ChatType.client, sent);
      expect(backend.requests.last.method, 'DELETE');

      await chat.setStatus(3, ChatType.client, 'suspended');
      expect(backend.requests.last.url.path, '/api/v1/admin/pm/projects/3/chat/status');
      expect(jsonDecode(backend.requests.last.body), {'type': 'client_team', 'status': 'suspended'});
    });

    test('profile, avatar, password, reset, delete account', () async {
      final s = LiveSession.instance;
      await s.updateProfile(name: 'Ada N. Obi', phone: '+2348030000000');
      expect(BizStore.instance.account.ownerFullName, 'Ada N. Obi');

      await s.uploadAvatar([1, 2, 3], 'me.jpg');
      expect(backend.requests.last.url.path, '/api/v1/admin/profile/picture');
      expect(BizStore.instance.account.avatarUrl, 'https://x.test/storage/avatar.jpg');

      await expectLater(s.changePassword(current: 'nope', password: 'NewPass#123'), throwsA(isA<ApiException>().having((e) => e.errorFor('current_password'), 'field', isNotNull)));
      await s.changePassword(current: 'secret123', password: 'NewPass#123');
      expect(jsonDecode(backend.requests.last.body)['new_password_confirmation'], 'NewPass#123');

      await expectLater(s.resetPassword(token: 'bad', email: 'ada@shop.ng', password: 'NewPass#123'), throwsA(isA<ApiException>()));
      await s.resetPassword(token: 'tok-123', email: 'ada@shop.ng', password: 'NewPass#123');

      await s.deleteAccount();
      expect(backend.requests.last.method, 'DELETE');
      expect(backend.requests.last.url.path, '/api/v1/admin/profile');
      expect(s.api.token, isNull);
    });

    test('store deletes and single read sync to the API', () async {
      final store = BizStore.instance;
      store.markRead(store.notifications.first);
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.last.method, 'PATCH');
      expect(backend.requests.last.url.path, '/api/v1/admin/notifications/n-1/read');

      store.deleteCustomer(store.customers.first);
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.last.url.path, '/api/v1/admin/clients/11');

      store.deleteQuotation(store.quotations.first);
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.last.url.path, '/api/v1/admin/accounting/quotes/5');
    });

    test('balance sheet', () async {
      final b = await LiveSession.instance.business.balanceSheet();
      expect((b['assets'] as Map)['total'], 500000);
    });
  });

  group('screens (live)', () {
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

    testWidgets('leads list loads and a new lead is saved', (tester) async {
      await pump(tester, ResourceListScreen(spec: Specs.leads));
      expect(find.text('Bisi Adeyemi'), findsOneWidget);

      await tester.tap(find.text('New Lead'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter name'), 'Tola Ade');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Save Lead'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('Tola Ade'), findsOneWidget);
      final post = backend.requests.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(post.body), containsPair('name', 'Tola Ade'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('project details opens tasks scoped to the project', (tester) async {
      await pump(tester, const ProjectsScreen());
      await tester.tap(find.text('Obi wedding outfits'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('Team chat'), findsOneWidget);
      await tester.ensureVisible(find.text('Tasks'));
      await tester.tap(find.text('Tasks'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('Cut fabric'), findsOneWidget);
      expect(find.text('Other project task'), findsNothing);
      expect(find.text('New Task'), findsOneWidget);
    });

    testWidgets('ticket shows the customer conversation', (tester) async {
      await pump(tester, const TicketsScreen());
      expect(find.text('New Ticket'), findsNothing, reason: 'customers open tickets');
      await tester.tap(find.text('Paid but still unpaid'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('I transferred yesterday.'), findsOneWidget);
    });

    testWidgets('balance sheet renders the three sections', (tester) async {
      await pump(tester, const BalanceSheetScreen());
      expect(find.text('Cash at bank'), findsOneWidget);
      expect(find.textContaining('Your books balance'), findsOneWidget);
    });

    testWidgets('project chat sends a message', (tester) async {
      await pump(tester, const ProjectChatScreen(projectId: 3, projectName: 'Obi wedding', type: ChatType.team));
      expect(find.text('Fabric is in.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Type a message'), 'On it');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Send'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('On it'), findsOneWidget);
    });

    testWidgets('change password shows the server error on the field', (tester) async {
      await pump(tester, const ChangePasswordScreen());
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter current password'), 'wrong');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter new password'), 'NewPass#123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter new password again'), 'NewPass#123');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Change Password').last);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('The current password is incorrect.'), findsOneWidget);
    });
  });

  group('screens (from the backend)', () {
    testWidgets('every workspace list loads from the API', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(signIn);
      // The fake backend has rows for these; the rest show their empty state.
      const withRows = {'leads', 'tickets', 'currencies', 'projects', 'tasks'};
      for (final spec in [Specs.leads, Specs.contacts, Specs.campaigns, Specs.tickets, Specs.services, Specs.salaries, Specs.departments, Specs.currencies, Specs.contracts, Specs.contractTemplates, Specs.projects, Specs.tasks, Specs.workLogs]) {
        await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: ResourceListScreen(key: ValueKey(spec.id), spec: spec)));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 200));
        if (withRows.contains(spec.id)) expect(find.byType(ResourceTile), findsWidgets, reason: spec.id);
        expect(tester.takeException(), isNull, reason: spec.id);
      }
    });
  });
}

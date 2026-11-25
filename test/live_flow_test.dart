import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'package:bizpaddi/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bizpaddi/features/auth/presentation/screens/login_screen.dart';
import 'package:bizpaddi/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_backend.dart';

/// UI flows in live mode against the fake Laravel backend.
void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    LiveSession.debugEnabledOverride = true;
    LiveSession.instance = LiveSession(
      api: ApiClient(baseUrl: 'https://x.test', httpClient: backend.client),
      tokens: MemoryTokenStore(),
      store: BizStore.instance,
    );
  });
  tearDown(() => LiveSession.debugEnabledOverride = null);

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('log in with email and password lands on Home with API data', (tester) async {
    await pumpApp(tester, const LoginScreen());
    expect(find.text('Email'), findsOneWidget, reason: 'live mode logs in by email');

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'ada@shop.ng');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter Password'), 'secret123');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Log in').last);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await settle(tester);

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Ada Obi'), findsWidgets); // business name from the profile
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong password shows the server error on the form', (tester) async {
    await pumpApp(tester, const LoginScreen());
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'ada@shop.ng');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter Password'), 'wrong-pass');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Log in').last);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await settle(tester);
    expect(find.text('Invalid credentials.'), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
  });

  testWidgets('forgot password sends a reset link', (tester) async {
    await pumpApp(tester, const ForgotPasswordScreen());
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'ada@shop.ng');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Reset Password').last);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await settle(tester);
    expect(find.text('Check your email'), findsOneWidget);
    final req = backend.requests.single;
    expect(req.url.path, '/api/v1/auth/forgot-password');
    expect(req.body, contains('"guard":"admin"'));
  });
}

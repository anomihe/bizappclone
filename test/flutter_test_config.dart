import 'dart:async';
import 'package:bizpaddi/core/api/api_client.dart';
import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/api/token_store.dart';
import 'package:bizpaddi/core/data/biz_store.dart';
import 'support/fake_backend.dart';

/// Runs before every test file. The app always talks to the backend, so every
/// test talks to an in-memory fake of it (never the real server). Tests that
/// need their own fake replace LiveSession.instance.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LiveSession.instance = LiveSession(
    api: ApiClient(baseUrl: 'https://x.test', httpClient: FakeBackend().client),
    tokens: MemoryTokenStore(),
    store: BizStore.instance,
  );
  await testMain();
}

import 'dart:async';
import 'package:bizpaddi/core/api/live_session.dart';

/// Runs before every test file. The app defaults to the live backend, so tests
/// run on the demo data unless a test switches live mode on (with a fake backend).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LiveSession.debugEnabledOverride = false;
  await testMain();
}

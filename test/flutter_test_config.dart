import 'dart:async';

import 'package:civic_voice/services/api_client.dart';

/// Runs before every test in this directory — Flutter's test runner picks
/// this file up automatically, no import needed anywhere. Guarantees no
/// widget test can ever make a live call against the real dev backend/
/// WittyFlow, regardless of which directory/service a test happens to
/// exercise. Before this existed, that guard only lived in a handful of
/// test files' own `setUp` (copy-pasted per file, easy to forget) — which
/// is exactly how a System Settings save test ended up silently depending
/// on the real backend being reachable.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ApiClient.baseUrl = 'http://127.0.0.1:1';
  await testMain();
}

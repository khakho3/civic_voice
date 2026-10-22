import 'dart:async';

import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _activity(String id, String title) => {
  'id': id,
  'title': title,
  'description': 'Authorized audit fixture.',
  'severity': 'INFO',
  'category': 'SYSTEM_UPDATE',
  'tag': 'Administration',
  'createdAt': '2026-10-18T12:00:00.000Z',
};

const Map<String, dynamic> _validHealth = <String, dynamic>{
  'apiOnline': true,
  'databaseOnline': true,
  'dbLatencyMs': 12,
  'uptimeSeconds': 3600,
  'checkedAt': '2026-10-18T12:00:00.000Z',
};

Map<String, dynamic> _health({
  required int latency,
  String checkedAt = '2026-10-18T12:00:00.000Z',
}) => <String, dynamic>{
  'apiOnline': true,
  'databaseOnline': true,
  'dbLatencyMs': latency,
  'uptimeSeconds': 3600,
  'checkedAt': checkedAt,
};

AdminSystemActivityDirectory _directory({
  required Future<List<Map<String, dynamic>>> Function(String) fetch,
  Future<Map<String, dynamic>> Function(String)? healthFetch,
  bool isSuperAdmin = false,
}) =>
    AdminSystemActivityDirectory.forTesting(
      firebaseAvailable: () => true,
      tokenProvider: () async => 'test-token',
      activityFetcher: fetch,
      healthFetcher: healthFetch ?? (_) async => _validHealth,
      isSuperAdmin: () => isSuperAdmin,
    );

Future<void> _settle() async {
  await Future<void>.microtask(() {});
  await Future<void>.microtask(() {});
}

void main() {
  test('an older successful refresh cannot replace a newer snapshot', () async {
    final olderResponse = Completer<List<Map<String, dynamic>>>();
    final newerResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      fetch: (_) => requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerResponse.complete([_activity('newer', 'Newer audit event')]);
    await newer;
    olderResponse.complete([_activity('older', 'Older audit event')]);
    await older;

    expect(directory.items.value.single.id, 'newer');
    expect(directory.state.value, AdminSystemActivityDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, isNull);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('an older failed refresh cannot replace a newer successful result', () async {
    final olderResponse = Completer<List<Map<String, dynamic>>>();
    final newerResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      fetch: (_) => requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerResponse.complete([_activity('newer', 'Newer audit event')]);
    await newer;
    olderResponse.completeError(StateError('older request failed'));
    await expectLater(older, throwsStateError);

    expect(directory.items.value.single.id, 'newer');
    expect(directory.state.value, AdminSystemActivityDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, isNull);
  });

  test('an older successful refresh cannot clear a newer failure', () async {
    final olderResponse = Completer<List<Map<String, dynamic>>>();
    final newerResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      fetch: (_) => requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerResponse.completeError(StateError('newer request failed'));
    await expectLater(newer, throwsStateError);
    olderResponse.complete([_activity('older', 'Older audit event')]);
    await older;

    expect(directory.items.value, isEmpty);
    expect(directory.state.value, AdminSystemActivityDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, contains('newer request failed'));
    expect(directory.hasLiveSnapshot, isFalse);
  });

  test('a newer confirmed empty response remains authoritative', () async {
    final olderResponse = Completer<List<Map<String, dynamic>>>();
    final newerResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      fetch: (_) => requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerResponse.complete(const []);
    await newer;
    olderResponse.complete([_activity('older', 'Older audit event')]);
    await older;

    expect(directory.items.value, isEmpty);
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminSystemActivityDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
  });

  test('a failed latest refresh retains the previous confirmed snapshot as stale',
      () async {
    final failedResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      fetch: (_) => requests++ == 0
          ? Future.value([_activity('confirmed', 'Confirmed audit event')])
          : failedResponse.future,
    );
    await directory.refresh();

    final latest = directory.refresh();
    await _settle();
    expect(directory.loading.value, isTrue);
    failedResponse.completeError(StateError('latest request failed'));
    await expectLater(latest, throwsStateError);

    expect(directory.items.value.single.id, 'confirmed');
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminSystemActivityDirectoryState.failed);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, contains('latest request failed'));
  });

  test('only the current refresh may publish verified health provenance', () async {
    final olderActivity = Completer<List<Map<String, dynamic>>>();
    final newerActivity = Completer<List<Map<String, dynamic>>>();
    final olderHealth = Completer<Map<String, dynamic>>();
    final newerHealth = Completer<Map<String, dynamic>>();
    var activityRequests = 0;
    var healthRequests = 0;
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) => activityRequests++ == 0
          ? olderActivity.future
          : newerActivity.future,
      healthFetch: (_) => healthRequests++ == 0
          ? olderHealth.future
          : newerHealth.future,
    );

    final older = directory.refresh();
    await _settle();
    olderActivity.complete([_activity('older', 'Older audit event')]);
    await _settle();

    final newer = directory.refresh();
    await _settle();
    newerActivity.complete([_activity('newer', 'Newer audit event')]);
    await _settle();
    newerHealth.complete(_validHealth);
    await newer;
    olderHealth.complete({
      'apiOnline': true,
      'databaseOnline': true,
      'dbLatencyMs': 12,
      'uptimeSeconds': 3600,
    });
    await older;

    expect(directory.items.value.single.id, 'newer');
    expect(directory.hasLiveHealthSnapshot, isTrue);
    expect(directory.health.value?.checkedAt, isNotNull);
    expect(directory.state.value, AdminSystemActivityDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
  });

  test('an older health-only success cannot replace a newer health snapshot',
      () async {
    final olderResponse = Completer<Map<String, dynamic>>();
    final newerResponse = Completer<Map<String, dynamic>>();
    var requests = 0;
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) async => const [],
      healthFetch: (_) =>
          requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refreshHealth();
    await _settle();
    final newer = directory.refreshHealth();
    await _settle();
    newerResponse.complete(_health(latency: 24));
    await newer;
    olderResponse.complete(_health(latency: 12));
    await older;

    expect(directory.health.value?.dbLatencyMs, 24);
    expect(directory.hasLiveHealthSnapshot, isTrue);
    expect(directory.items.value, isEmpty);
    expect(directory.state.value, AdminSystemActivityDirectoryState.unavailable);
  });

  test('an older health-only failure cannot erase a newer health snapshot',
      () async {
    final olderResponse = Completer<Map<String, dynamic>>();
    final newerResponse = Completer<Map<String, dynamic>>();
    var requests = 0;
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) async => const [],
      healthFetch: (_) =>
          requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refreshHealth();
    await _settle();
    final newer = directory.refreshHealth();
    await _settle();
    newerResponse.complete(_health(latency: 24));
    await newer;
    olderResponse.completeError(StateError('older health request failed'));
    await older;

    expect(directory.health.value?.dbLatencyMs, 24);
    expect(directory.hasLiveHealthSnapshot, isTrue);
  });

  test('an older health-only success cannot clear a newer health failure',
      () async {
    final olderResponse = Completer<Map<String, dynamic>>();
    final newerResponse = Completer<Map<String, dynamic>>();
    var requests = 0;
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) async => const [],
      healthFetch: (_) =>
          requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refreshHealth();
    await _settle();
    final newer = directory.refreshHealth();
    await _settle();
    newerResponse.completeError(StateError('newer health request failed'));
    await newer;
    olderResponse.complete(_health(latency: 12));
    await older;

    expect(directory.health.value, isNull);
    expect(directory.hasLiveHealthSnapshot, isFalse);
  });

  test('a full refresh supersedes an older health-only read', () async {
    final activityResponse = Completer<List<Map<String, dynamic>>>();
    final olderHealth = Completer<Map<String, dynamic>>();
    final fullHealth = Completer<Map<String, dynamic>>();
    var healthRequests = 0;
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) => activityResponse.future,
      healthFetch: (_) => healthRequests++ == 0
          ? olderHealth.future
          : fullHealth.future,
    );

    final healthOnly = directory.refreshHealth();
    await _settle();
    final full = directory.refresh();
    await _settle();
    activityResponse.complete([_activity('full', 'Full refresh activity')]);
    await _settle();
    fullHealth.complete(_health(latency: 24));
    await full;
    olderHealth.complete(_health(latency: 12));
    await healthOnly;

    expect(directory.items.value.single.id, 'full');
    expect(directory.health.value?.dbLatencyMs, 24);
    expect(directory.state.value, AdminSystemActivityDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
  });

  test('a newer health-only read supersedes a full refresh health read',
      () async {
    final activityResponse = Completer<List<Map<String, dynamic>>>();
    final fullHealth = Completer<Map<String, dynamic>>();
    final healthOnly = Completer<Map<String, dynamic>>();
    var healthRequests = 0;
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) => activityResponse.future,
      healthFetch: (_) => healthRequests++ == 0
          ? fullHealth.future
          : healthOnly.future,
    );

    final full = directory.refresh();
    await _settle();
    activityResponse.complete([_activity('full', 'Full refresh activity')]);
    await _settle();
    final newerHealthOnly = directory.refreshHealth();
    await _settle();
    healthOnly.complete(_health(latency: 24));
    await newerHealthOnly;
    fullHealth.complete(_health(latency: 12));
    await full;

    expect(directory.items.value.single.id, 'full');
    expect(directory.health.value?.dbLatencyMs, 24);
    expect(directory.hasLiveHealthSnapshot, isTrue);
    expect(directory.state.value, AdminSystemActivityDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
  });

  test('incomplete health-only data never becomes verified live health',
      () async {
    final directory = _directory(
      isSuperAdmin: true,
      fetch: (_) async => const [],
      healthFetch: (_) async => <String, dynamic>{
        'apiOnline': true,
        'databaseOnline': true,
        'dbLatencyMs': 12,
        'uptimeSeconds': 3600,
      },
    );

    await directory.refreshHealth();

    expect(directory.health.value, isNull);
    expect(directory.hasLiveHealthSnapshot, isFalse);
    expect(directory.items.value, isEmpty);
    expect(directory.state.value, AdminSystemActivityDirectoryState.unavailable);
  });
  test('logout invalidates pending activity and health responses', () async {
    final response = Completer<List<Map<String, dynamic>>>();
    final directory = _directory(fetch: (_) => response.future);
    final pending = directory.refresh();
    await _settle();
    directory.invalidateAndClear();
    response.complete([_activity('old-account', 'Old account data')]);
    await pending;
    expect(directory.items.value, isEmpty);
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.state.value, AdminSystemActivityDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);

    final health = Completer<Map<String, dynamic>>();
    final healthDirectory = _directory(fetch: (_) async => [], healthFetch: (_) => health.future, isSuperAdmin: true);
    final pendingHealth = healthDirectory.refreshHealth();
    await _settle();
    healthDirectory.invalidateAndClear();
    health.complete(_validHealth);
    await pendingHealth;
    expect(healthDirectory.health.value, isNull);
    expect(healthDirectory.hasLiveHealthSnapshot, isFalse);
  });

}

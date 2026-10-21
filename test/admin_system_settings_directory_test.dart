import 'dart:async';

import 'package:civic_voice/features/admin/models/admin_system_settings_data.dart';
import 'package:civic_voice/features/admin/services/admin_system_settings_directory.dart';
import 'package:flutter_test/flutter_test.dart';

const _confirmedSettings = {
  'sessionTimeout': '30 minutes',
  'auditLogging': false,
  'allowNewAccountCreation': false,
};

const _laterSettings = {
  'sessionTimeout': '15 minutes',
  'auditLogging': false,
  'allowNewAccountCreation': true,
};

const _savedSettings = {
  'sessionTimeout': '60 minutes',
  'auditLogging': true,
  'allowNewAccountCreation': true,
};

SystemSettingsData _draft() => const SystemSettingsData(
  maintenanceMode: false,
  sessionTimeout: '60 minutes',
  auditLogging: true,
  publicStatusPage: false,
  allowNewAccountCreation: true,
);

AdminSystemSettingsDirectory _directory({
  required Future<Map<String, dynamic>> Function(String) fetch,
  required Future<Map<String, dynamic>> Function(
    String,
    Map<String, dynamic>,
  ) update,
  Future<String?> Function()? tokenProvider,
  Future<Map<String, dynamic>> Function(String)? sessionFetch,
}) =>
    AdminSystemSettingsDirectory.forTesting(
      firebaseAvailable: () => true,
      tokenProvider: tokenProvider ?? (() async => 'test-token'),
      settingsFetcher: fetch,
      sessionSettingsFetcher: sessionFetch ?? fetch,
      settingsUpdater: update,
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a delayed stale refresh never re-enters loading after a save', () async {
    final firstToken = Completer<String?>();
    var tokenRequests = 0;
    var fetchCalls = 0;
    final directory = _directory(
      fetch: (_) async {
        fetchCalls += 1;
        return _confirmedSettings;
      },
      update: (_, _) async => _savedSettings,
      tokenProvider: () {
        tokenRequests += 1;
        return tokenRequests == 1
            ? firstToken.future
            : Future<String?>.value('test-token');
      },
    );

    final oldRefresh = directory.refresh();
    await directory.save(_draft());
    firstToken.complete('test-token');
    await oldRefresh;

    expect(fetchCalls, 0);
    expect(directory.settings.value, SystemSettingsData.fromApi(_savedSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, isNull);
  });

  test('a full refresh remains responsible for loading around a timeout read',
      () async {
    final fullResponse = Completer<Map<String, dynamic>>();
    final timeoutResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) => fullResponse.future,
      sessionFetch: (_) => timeoutResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final fullRefresh = directory.refresh();
    await _settle();
    final timeoutRefresh = directory.refreshSessionTimeout();
    await _settle();
    timeoutResponse.complete({'sessionTimeout': '60 minutes'});
    await timeoutRefresh;

    expect(directory.state.value, AdminSystemSettingsDirectoryState.loading);
    fullResponse.complete(_confirmedSettings);
    await fullRefresh;

    expect(directory.settings.value, SystemSettingsData.fromApi(_confirmedSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('an older timeout read cannot overwrite a newer full snapshot',
      () async {
    final timeoutResponse = Completer<Map<String, dynamic>>();
    final fullResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) => fullResponse.future,
      sessionFetch: (_) => timeoutResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final timeoutRead = directory.refreshSessionTimeout();
    await _settle();
    final fullRefresh = directory.refresh();
    await _settle();
    fullResponse.complete(_confirmedSettings);
    await fullRefresh;
    timeoutResponse.complete({'sessionTimeout': '60 minutes'});
    await timeoutRead;

    expect(directory.settings.value, SystemSettingsData.fromApi(_confirmedSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('a failed newer full refresh does not fabricate a timeout snapshot',
      () async {
    final timeoutResponse = Completer<Map<String, dynamic>>();
    final fullResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) => fullResponse.future,
      sessionFetch: (_) => timeoutResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final timeoutRead = directory.refreshSessionTimeout();
    await _settle();
    final fullRefresh = directory.refresh();
    await _settle();
    fullResponse.completeError(StateError('network unavailable'));
    await expectLater(fullRefresh, throwsStateError);
    timeoutResponse.complete({'sessionTimeout': '60 minutes'});
    await timeoutRead;

    expect(directory.settings.value.sessionTimeout, '60 minutes');
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.state.value, AdminSystemSettingsDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, isNotNull);
  });

  test('an older refresh cannot overwrite a newer validated save', () async {
    final refreshResponse = Completer<Map<String, dynamic>>();
    final saveResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) => refreshResponse.future,
      update: (_, _) => saveResponse.future,
    );

    final refresh = directory.refresh();
    await _settle();
    final save = directory.save(_draft());
    saveResponse.complete(_savedSettings);
    await save;
    refreshResponse.complete(_confirmedSettings);
    await refresh;

    expect(directory.settings.value, SystemSettingsData.fromApi(_savedSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, isNull);
  });

  test('a failed save leaves an active refresh free to confirm data',
      () async {
    final refreshResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) => refreshResponse.future,
      update: (_, _) async => throw StateError('server rejected update'),
    );

    final refresh = directory.refresh();
    await _settle();
    await expectLater(directory.save(_draft()), throwsStateError);
    refreshResponse.complete(_confirmedSettings);
    await refresh;

    expect(directory.settings.value, SystemSettingsData.fromApi(_confirmedSettings));
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
  });

  test('multiple full refreshes apply only the most recently started result',
      () async {
    final firstResponse = Completer<Map<String, dynamic>>();
    final secondResponse = Completer<Map<String, dynamic>>();
    var calls = 0;
    final directory = _directory(
      fetch: (_) => calls++ == 0 ? firstResponse.future : secondResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final first = directory.refresh();
    await _settle();
    final second = directory.refresh();
    await _settle();
    secondResponse.complete(_laterSettings);
    await second;
    firstResponse.complete(_confirmedSettings);
    await first;

    expect(directory.settings.value, SystemSettingsData.fromApi(_laterSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
  });

  test('a newer successful refresh clears loading while an older read is pending',
      () async {
    final olderResponse = Completer<Map<String, dynamic>>();
    final newerResponse = Completer<Map<String, dynamic>>();
    var calls = 0;
    final directory = _directory(
      fetch: (_) => calls++ == 0 ? olderResponse.future : newerResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final older = directory.refresh();
    await _settle();
    expect(directory.loading.value, isTrue);
    final newer = directory.refresh();
    await _settle();
    newerResponse.complete(_laterSettings);
    await newer;

    expect(directory.settings.value, SystemSettingsData.fromApi(_laterSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.loading.value, isFalse);

    olderResponse.complete(_confirmedSettings);
    await older;
    expect(directory.loading.value, isFalse);
    expect(directory.settings.value, SystemSettingsData.fromApi(_laterSettings));
  });

  test('a newer failed refresh clears loading while an older read is pending',
      () async {
    final olderResponse = Completer<Map<String, dynamic>>();
    final newerResponse = Completer<Map<String, dynamic>>();
    var calls = 0;
    final directory = _directory(
      fetch: (_) => calls++ == 0 ? olderResponse.future : newerResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerResponse.completeError(StateError('newer request failed'));
    await expectLater(newer, throwsStateError);

    expect(directory.state.value, AdminSystemSettingsDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, contains('newer request failed'));

    olderResponse.complete(_confirmedSettings);
    await older;
    expect(directory.state.value, AdminSystemSettingsDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, contains('newer request failed'));
  });

  test('a latest failed refresh retains a confirmed snapshot as stale',
      () async {
    final failedResponse = Completer<Map<String, dynamic>>();
    var calls = 0;
    final directory = _directory(
      fetch: (_) => calls++ == 0 ? Future.value(_confirmedSettings) : failedResponse.future,
      update: (_, _) async => _savedSettings,
    );
    await directory.refresh();

    final latest = directory.refresh();
    await _settle();
    expect(directory.loading.value, isTrue);
    failedResponse.completeError(StateError('latest request failed'));
    await expectLater(latest, throwsStateError);

    expect(directory.settings.value, SystemSettingsData.fromApi(_confirmedSettings));
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminSystemSettingsDirectoryState.failed);
    expect(directory.loading.value, isFalse);
  });

  test('a stale failed refresh cannot replace a newer successful save',
      () async {
    final refreshFailure = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) => refreshFailure.future,
      update: (_, _) async => _savedSettings,
    );

    final refresh = directory.refresh();
    await _settle();
    await directory.save(_draft());
    refreshFailure.completeError(StateError('network unavailable'));
    await expectLater(refresh, throwsStateError);

    expect(directory.settings.value, SystemSettingsData.fromApi(_savedSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.error.value, isNull);
  });

  test('a malformed save response does not replace confirmed settings',
      () async {
    final directory = _directory(
      fetch: (_) async => _confirmedSettings,
      update: (_, _) async => {'sessionTimeout': '60 minutes'},
    );
    await directory.refresh();

    await expectLater(directory.save(_draft()), throwsFormatException);

    expect(directory.settings.value, SystemSettingsData.fromApi(_confirmedSettings));
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
  });

  test('a delayed session-timeout read cannot overwrite a newer save', () async {
    final timeoutResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      fetch: (_) async => _confirmedSettings,
      sessionFetch: (_) => timeoutResponse.future,
      update: (_, _) async => _savedSettings,
    );

    final timeoutRead = directory.refreshSessionTimeout();
    await _settle();
    await directory.save(_draft());
    timeoutResponse.complete({'sessionTimeout': '30 minutes'});
    await timeoutRead;

    expect(directory.settings.value, SystemSettingsData.fromApi(_savedSettings));
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('a standalone timeout read updates only its supported field', () async {
    final directory = _directory(
      fetch: (_) async => _confirmedSettings,
      sessionFetch: (_) async => {'sessionTimeout': '60 minutes'},
      update: (_, _) async => _savedSettings,
    );

    await directory.refreshSessionTimeout();

    expect(directory.settings.value.sessionTimeout, '60 minutes');
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.state.value, AdminSystemSettingsDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);
  });

  test('normal validated refresh and save responses remain authoritative',
      () async {
    final directory = _directory(
      fetch: (_) async => _confirmedSettings,
      update: (_, _) async => _savedSettings,
    );

    await directory.refresh();
    await directory.save(_draft());

    expect(directory.settings.value, SystemSettingsData.fromApi(_savedSettings));
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminSystemSettingsDirectoryState.loaded);
  });
}

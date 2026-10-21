import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../models/admin_system_settings_data.dart';

/// Provenance of the System Settings snapshot currently held by this
/// directory. A [loaded] snapshot may be empty only if a future contract adds
/// optional fields; [unavailable] is never a confirmed server result.
enum AdminSystemSettingsDirectoryState { unavailable, loading, loaded, failed }

/// Real, process-wide source of truth for ADM-007 System Settings — a
/// `ValueNotifier` singleton, the same pattern as every other `*Directory`
/// in this app. Backed by a real civic_voice_api endpoint
/// (GET/PATCH /api/admin/settings) — [refresh]/[save] are the only ways
/// [settings] changes now, replacing the earlier local-only mock that
/// reset on every app restart and never left the device.
class AdminSystemSettingsDirectory {
  AdminSystemSettingsDirectory._({
    bool Function()? firebaseAvailable,
    Future<String?> Function()? tokenProvider,
    Future<Map<String, dynamic>> Function(String token)? settingsFetcher,
    Future<Map<String, dynamic>> Function(String token)? sessionSettingsFetcher,
    Future<Map<String, dynamic>> Function(
      String token,
      Map<String, dynamic> fields,
    )? settingsUpdater,
  })  : _firebaseAvailable = firebaseAvailable ?? (() => Firebase.apps.isNotEmpty),
        _tokenProvider = tokenProvider ?? _firebaseIdToken,
        _settingsFetcher = settingsFetcher ??
            ((token) => ApiClient.instance.getAdminSettings(idToken: token)),
        _sessionSettingsFetcher = sessionSettingsFetcher ??
            ((token) => ApiClient.instance.getSessionSettings(idToken: token)),
        _settingsUpdater = settingsUpdater ??
            ((token, fields) => ApiClient.instance.updateAdminSettings(
                  idToken: token,
                  fields: fields,
                ));

  static final AdminSystemSettingsDirectory instance =
      AdminSystemSettingsDirectory._();

  static Future<String?> _firebaseIdToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return currentUser.getIdToken();
  }

  /// Isolated request hooks for directory tests. Production always uses the
  /// Firebase and API-client callbacks above; fixtures cannot become a
  /// production fallback through this constructor.
  @visibleForTesting
  factory AdminSystemSettingsDirectory.forTesting({
    required bool Function() firebaseAvailable,
    required Future<String?> Function() tokenProvider,
    required Future<Map<String, dynamic>> Function(String token) settingsFetcher,
    required Future<Map<String, dynamic>> Function(String token)
        sessionSettingsFetcher,
    required Future<Map<String, dynamic>> Function(
      String token,
      Map<String, dynamic> fields,
    ) settingsUpdater,
  }) =>
      AdminSystemSettingsDirectory._(
        firebaseAvailable: firebaseAvailable,
        tokenProvider: tokenProvider,
        settingsFetcher: settingsFetcher,
        sessionSettingsFetcher: sessionSettingsFetcher,
        settingsUpdater: settingsUpdater,
      );

  final bool Function() _firebaseAvailable;
  final Future<String?> Function() _tokenProvider;
  final Future<Map<String, dynamic>> Function(String token) _settingsFetcher;
  final Future<Map<String, dynamic>> Function(String token)
      _sessionSettingsFetcher;
  final Future<Map<String, dynamic>> Function(
    String token,
    Map<String, dynamic> fields,
  ) _settingsUpdater;

  // A PATCH response is authoritative for the settings revision it confirms.
  // Full reads own the directory's loading/state/error lifecycle. A
  // session-timeout read is deliberately independent: it may update only its
  // one field and can never cancel a full read or leave that read's loading
  // state unresolved.
  int _operationSequence = 0;
  int _latestFullRefreshOperation = 0;
  int _latestSessionTimeoutOperation = 0;
  int _latestSaveOperation = 0;
  int _settingsRevision = 0;
  int _fullSnapshotGeneration = 0;

  /// A conservative local fallback for non-UI consumers such as the idle
  /// timer. [hasLiveSnapshot] remains false until the backend confirms every
  /// supported setting, so this value must never be presented as platform
  /// configuration.
  final ValueNotifier<SystemSettingsData> settings = ValueNotifier(
    const SystemSettingsData(
      maintenanceMode: false,
      sessionTimeout: '30 minutes',
      auditLogging: false,
      publicStatusPage: false,
      allowNewAccountCreation: false,
    ),
  );
  final ValueNotifier<AdminSystemSettingsDirectoryState> state = ValueNotifier(
    AdminSystemSettingsDirectoryState.unavailable,
  );
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool hasLiveSnapshot = false;

  bool get canRefresh =>
      _firebaseAvailable() && FirebaseAuth.instance.currentUser != null;

  bool _canApplyFullRefresh(int operation, int revision) =>
      operation == _latestFullRefreshOperation &&
      revision == _settingsRevision;

  bool _canApplySessionTimeout(
    int operation,
    int revision,
    int fullSnapshotGeneration,
  ) =>
      operation == _latestSessionTimeoutOperation &&
      revision == _settingsRevision &&
      fullSnapshotGeneration == _fullSnapshotGeneration;

  Future<void> refresh() async {
    final operation = ++_operationSequence;
    final revision = _settingsRevision;
    _latestFullRefreshOperation = operation;

    if (!_firebaseAvailable()) {
      if (_canApplyFullRefresh(operation, revision)) {
        loading.value = false;
        state.value = hasLiveSnapshot
            ? AdminSystemSettingsDirectoryState.failed
            : AdminSystemSettingsDirectoryState.unavailable;
      }
      throw StateError('System Settings is unavailable without Firebase');
    }
    final String? token;
    try {
      token = await _tokenProvider();
    } catch (exception) {
      if (_canApplyFullRefresh(operation, revision)) {
        loading.value = false;
        error.value = exception.toString();
        state.value = hasLiveSnapshot
            ? AdminSystemSettingsDirectoryState.failed
            : AdminSystemSettingsDirectoryState.unavailable;
      }
      rethrow;
    }
    if (token == null) {
      const message = 'A signed-in Admin is required';
      if (_canApplyFullRefresh(operation, revision)) {
        loading.value = false;
        error.value = message;
        state.value = hasLiveSnapshot
            ? AdminSystemSettingsDirectoryState.failed
            : AdminSystemSettingsDirectoryState.unavailable;
      }
      throw StateError(message);
    }
    // The token can arrive after a newer save or full refresh. Do not let a
    // superseded request enter loading or clear a newer error/success state.
    if (!_canApplyFullRefresh(operation, revision)) return;
    loading.value = true;
    state.value = AdminSystemSettingsDirectoryState.loading;
    error.value = null;
    try {
      final response = await _settingsFetcher(token);
      final parsed = SystemSettingsData.fromApi(response);
      if (_canApplyFullRefresh(operation, revision)) {
        settings.value = parsed;
        hasLiveSnapshot = true;
        _fullSnapshotGeneration += 1;
        state.value = AdminSystemSettingsDirectoryState.loaded;
      }
    } catch (exception) {
      if (_canApplyFullRefresh(operation, revision)) {
        error.value = exception.toString();
        state.value = hasLiveSnapshot
            ? AdminSystemSettingsDirectoryState.failed
            : AdminSystemSettingsDirectoryState.unavailable;
      }
      rethrow;
    } finally {
      // Loading belongs only to the latest full refresh. A stale older read
      // must not keep the screen busy after a newer result has settled.
      if (_canApplyFullRefresh(operation, revision)) {
        loading.value = false;
      }
    }
  }

  /// Fetches the one setting every authenticated role needs without
  /// exposing the Super Admin-only settings endpoint or its other values.
  Future<void> refreshSessionTimeout() async {
    final operation = ++_operationSequence;
    final revision = _settingsRevision;
    final fullSnapshotGeneration = _fullSnapshotGeneration;
    _latestSessionTimeoutOperation = operation;
    if (!_firebaseAvailable()) return;
    final token = await _tokenProvider();
    if (token == null) throw StateError('A signed-in user is required');
    if (!_canApplySessionTimeout(
      operation,
      revision,
      fullSnapshotGeneration,
    )) {
      return;
    }
    final response = await _sessionSettingsFetcher(token);
    final timeout = response['sessionTimeout'];
    if (timeout is! String || !kSessionTimeoutOptions.contains(timeout)) {
      throw const FormatException('Session settings response is incomplete');
    }
    if (_canApplySessionTimeout(
      operation,
      revision,
      fullSnapshotGeneration,
    )) {
      settings.value = settings.value.copyWith(sessionTimeout: timeout);
    }
  }

  /// Saves [draft] for real — only the three server-backed fields are
  /// actually sent (see [SystemSettingsData.fromApi]'s doc comment).
  /// Throws [ApiException] on failure (e.g. a non-Super-Admin session);
  /// callers show that message rather than a generic one.
  Future<void> save(SystemSettingsData draft) async {
    final operation = ++_operationSequence;
    _latestSaveOperation = operation;
    final token = await _tokenProvider();
    if (token == null) throw StateError('A signed-in Admin is required');
    if (operation != _latestSaveOperation) return;
    final response = await _settingsUpdater(token, {
      'sessionTimeout': draft.sessionTimeout,
      'auditLogging': draft.auditLogging,
      'allowNewAccountCreation': draft.allowNewAccountCreation,
    });
    final parsed = SystemSettingsData.fromApi(response);
    if (operation != _latestSaveOperation) return;

    settings.value = parsed;
    hasLiveSnapshot = true;
    _settingsRevision += 1;
    // A successful save becomes the authoritative settings revision, so any
    // pending full read is stale and must no longer hold the loading spinner.
    loading.value = false;
    error.value = null;
    state.value = AdminSystemSettingsDirectoryState.loaded;
  }
}

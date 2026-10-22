import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../models/admin_system_activity_data.dart';
import 'admin_session.dart';

/// Provenance of the administrative audit snapshot held by this directory.
/// An empty [loaded] snapshot is a real server result; [unavailable] is not.
enum AdminSystemActivityDirectoryState { unavailable, loading, loaded, failed }

class AdminSystemActivityDirectory {
  AdminSystemActivityDirectory._({
    bool Function()? firebaseAvailable,
    Future<String?> Function()? tokenProvider,
    Future<List<Map<String, dynamic>>> Function(String token)? activityFetcher,
    Future<Map<String, dynamic>> Function(String token)? healthFetcher,
    bool Function()? isSuperAdmin,
  })  : _firebaseAvailable = firebaseAvailable ?? (() => Firebase.apps.isNotEmpty),
        _tokenProvider = tokenProvider ?? _firebaseIdToken,
        _activityFetcher = activityFetcher ??
            ((token) => ApiClient.instance.listAdminActivity(idToken: token)),
        _healthFetcher = healthFetcher ??
            ((token) => ApiClient.instance.getAdminHealth(idToken: token)),
        _isSuperAdmin = isSuperAdmin ?? (() => AdminSession.instance.isSuperAdmin);

  static final instance = AdminSystemActivityDirectory._();

  static Future<String?> _firebaseIdToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return currentUser.getIdToken();
  }

  /// Isolated request hooks for deterministic directory tests. Production
  /// continues to use Firebase and the approved Admin API endpoints.
  @visibleForTesting
  factory AdminSystemActivityDirectory.forTesting({
    required bool Function() firebaseAvailable,
    required Future<String?> Function() tokenProvider,
    required Future<List<Map<String, dynamic>>> Function(String token)
        activityFetcher,
    required Future<Map<String, dynamic>> Function(String token) healthFetcher,
    required bool Function() isSuperAdmin,
  }) =>
      AdminSystemActivityDirectory._(
        firebaseAvailable: firebaseAvailable,
        tokenProvider: tokenProvider,
        activityFetcher: activityFetcher,
        healthFetcher: healthFetcher,
        isSuperAdmin: isSuperAdmin,
      );

  final bool Function() _firebaseAvailable;
  final Future<String?> Function() _tokenProvider;
  final Future<List<Map<String, dynamic>>> Function(String token)
      _activityFetcher;
  final Future<Map<String, dynamic>> Function(String token) _healthFetcher;
  final bool Function() _isSuperAdmin;

  final ValueNotifier<List<ActivityItem>> items = ValueNotifier(
    const <ActivityItem>[],
  );
  final ValueNotifier<SystemHealthStats?> health = ValueNotifier(null);
  final ValueNotifier<AdminSystemActivityDirectoryState> state = ValueNotifier(
    AdminSystemActivityDirectoryState.unavailable,
  );
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool hasLiveSnapshot = false;
  bool hasLiveHealthSnapshot = false;

  /// Last-started refresh wins. A response may update the visible activity,
  /// loading, error, and activity provenance only while its revision is current.
  int _refreshRevision = 0;

  /// Health reads have their own ordering lane. Both a health-only read and a
  /// full Activity refresh can request health, but neither may publish a
  /// response after a newer health request has started. This intentionally
  /// does not own Activity loading, error, or record state.
  int _healthRefreshRevision = 0;

  bool get canRefresh => _firebaseAvailable();

  bool _isCurrentRefresh(int revision) => revision == _refreshRevision;

  bool _isCurrentHealthRefresh(int revision) =>
      revision == _healthRefreshRevision;

  void _publishFailure(int revision, Object exception) {
    if (!_isCurrentRefresh(revision)) return;
    error.value = exception.toString();
    state.value = hasLiveSnapshot
        ? AdminSystemActivityDirectoryState.failed
        : AdminSystemActivityDirectoryState.unavailable;
  }

  /// Fence all authenticated work before removing the previous account's data.
  void invalidateAndClear() {
    ++_refreshRevision;
    ++_healthRefreshRevision;
    hasLiveSnapshot = false;
    hasLiveHealthSnapshot = false;
    loading.value = false;
    error.value = null;
    items.value = const <ActivityItem>[];
    health.value = null;
    state.value = AdminSystemActivityDirectoryState.unavailable;
  }

  Future<void> refresh() async {
    final revision = ++_refreshRevision;
    // A new full refresh invalidates health from an older full or health-only
    // read immediately, even while this refresh is waiting for credentials.
    final healthFenceRevision = ++_healthRefreshRevision;
    if (!_firebaseAvailable()) {
      if (_isCurrentRefresh(revision)) {
        loading.value = false;
        _publishFailure(
          revision,
          StateError('System Activity is unavailable without Firebase'),
        );
      }
      throw StateError('System Activity is unavailable without Firebase');
    }
    final String? token;
    try {
      token = await _tokenProvider();
    } catch (exception) {
      if (_isCurrentRefresh(revision)) {
        loading.value = false;
        _publishFailure(revision, exception);
      }
      rethrow;
    }
    if (!_isCurrentRefresh(revision)) return;
    if (token == null) {
      const message = 'A signed-in Admin is required';
      loading.value = false;
      _publishFailure(revision, StateError(message));
      throw StateError(message);
    }
    loading.value = true;
    state.value = AdminSystemActivityDirectoryState.loading;
    error.value = null;
    try {
      final response = await _activityFetcher(token);
      if (!_isCurrentRefresh(revision)) return;
      items.value = response.map(ActivityItem.fromApi).toList();
      hasLiveSnapshot = true;
      state.value = AdminSystemActivityDirectoryState.loaded;
      if (_isSuperAdmin()) {
        final healthRevision = ++_healthRefreshRevision;
        await _refreshHealth(idToken: token, healthRevision: healthRevision);
      } else {
        if (!_isCurrentRefresh(revision) ||
            !_isCurrentHealthRefresh(healthFenceRevision)) {
          return;
        }
        health.value = null;
        hasLiveHealthSnapshot = false;
      }
    } catch (exception) {
      _publishFailure(revision, exception);
      rethrow;
    } finally {
      if (_isCurrentRefresh(revision)) loading.value = false;
    }
  }

  Future<void> refreshHealth({String? idToken}) async {
    final healthRevision = ++_healthRefreshRevision;
    await _refreshHealth(
      idToken: idToken,
      healthRevision: healthRevision,
    );
  }

  Future<void> _refreshHealth({
    String? idToken,
    required int healthRevision,
  }) async {
    if (!_isCurrentHealthRefresh(healthRevision)) return;
    if (!_firebaseAvailable() || !_isSuperAdmin()) {
      if (_isCurrentHealthRefresh(healthRevision)) {
        hasLiveHealthSnapshot = false;
        health.value = null;
      }
      return;
    }
    try {
      final token = idToken ?? await _tokenProvider();
      if (token == null) throw StateError('A signed-in Admin is required');
      final response = await _healthFetcher(token);
      if (!_isCurrentHealthRefresh(healthRevision)) return;
      health.value = SystemHealthStats.fromApi(response);
      hasLiveHealthSnapshot = true;
    } catch (_) {
      if (_isCurrentHealthRefresh(healthRevision)) {
        hasLiveHealthSnapshot = false;
        health.value = null;
      }
    }
  }
}

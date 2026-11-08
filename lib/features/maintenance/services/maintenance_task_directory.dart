import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../services/api_client.dart';
import '../../admin/models/admin_maintenance_team_data.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../models/maintenance_task.dart';
import 'maintenance_session.dart';
import 'maintenance_update_service.dart';

/// In-memory source of truth for the current technician's assigned tasks —
/// mirrors [MaintenanceTeamDirectory]'s shape (a `ValueNotifier` singleton)
/// so every screen in the MNT flow reads/writes the same task records
/// instead of each carrying its own disconnected mock copy. Update Progress
/// writes through here on save, so Dashboard/Assigned Tasks/Task Completed
/// all see the same status change immediately.
class MaintenanceTaskDirectory {
  MaintenanceTaskDirectory._({
    MaintenanceSession? session,
    bool Function()? live,
    String? Function()? owner,
    Future<List<Map<String, dynamic>>> Function()? fetch,
  }) : _session = session ?? MaintenanceSession.instance,
       _live = live ?? (() => Firebase.apps.isNotEmpty),
       _owner = owner ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _fetch = fetch ?? _fetchCurrent {
    _session.profile.addListener(_observeScope);
    _observeScope();
  }

  @visibleForTesting
  factory MaintenanceTaskDirectory.forTesting({
    required MaintenanceSession session,
    required String? Function() owner,
    required Future<List<Map<String, dynamic>>> Function() fetch,
  }) => MaintenanceTaskDirectory._(
    session: session,
    live: () => true,
    owner: owner,
    fetch: fetch,
  );

  final MaintenanceSession _session;
  final bool Function() _live;
  final String? Function() _owner;
  final Future<List<Map<String, dynamic>>> Function() _fetch;
  int _scopeRevision = 0;
  (String?, String, String, String, String?)? _observedScope;

  static Future<List<Map<String, dynamic>>> _fetchCurrent() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in technician is required');
    return ApiClient.instance.listReports(idToken: token);
  }

  void _observeScope() {
    if (!_live()) return;
    final profile = _session.profile.value;
    final scope = (
      _owner(),
      profile.publicId,
      profile.region,
      profile.assembly,
      profile.teamId,
    );
    if (_observedScope == scope) return;
    _observedScope = scope;
    ++_scopeRevision;
    tasks.value = const [];
    hasLiveSnapshot = false;
    error.value = null;
  }

  static final MaintenanceTaskDirectory instance = MaintenanceTaskDirectory._();

  /// The signed-in technician's public account identifier.
  static String get currentUserId =>
      MaintenanceSession.instance.profile.value.publicId;

  final ValueNotifier<List<MaintenanceTask>> tasks = ValueNotifier(
    Firebase.apps.isEmpty ? mockMaintenanceTasks() : const <MaintenanceTask>[],
  );
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool hasLiveSnapshot = false;
  final _updates = MaintenanceUpdateService();
  int _sessionRevision = 0;
  int _refreshRevision = 0;
  void clearSession() {
    ++_sessionRevision;
    ++_refreshRevision;
    tasks.value = const [];
    loading.value = false;
    error.value = null;
    hasLiveSnapshot = false;
    ++_scopeRevision;
    _observedScope = null;
  }

  Future<void> refresh() async {
    if (!_live()) return;
    _observeScope();
    final revision = _sessionRevision, refresh = ++_refreshRevision;
    final owner = _owner();
    int? readScope;
    loading.value = true;
    error.value = null;
    try {
      await _session.refresh();
      if (revision != _sessionRevision ||
          refresh != _refreshRevision ||
          owner != _owner()) {
        return;
      }
      final scope = readScope = _scopeRevision;
      if (_session.profile.value.teamId == null) {
        tasks.value = const [];
        hasLiveSnapshot = true;
        return;
      }
      final response = await _fetch();
      if (revision != _sessionRevision ||
          refresh != _refreshRevision ||
          scope != _scopeRevision ||
          owner != _owner()) {
        return;
      }
      tasks.value = response.map(MaintenanceTask.fromApi).toList();
      hasLiveSnapshot = true;
    } catch (exception) {
      if (revision == _sessionRevision &&
          refresh == _refreshRevision &&
          owner == _owner() &&
          (readScope == null || readScope == _scopeRevision)) {
        error.value = exception.toString();
      }
      rethrow;
    } finally {
      if (revision == _sessionRevision && refresh == _refreshRevision) {
        loading.value = false;
      }
    }
  }

  MaintenanceTask? taskById(String taskId) {
    for (final task in tasks.value) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  void updateTask(MaintenanceTask updated) {
    tasks.value = [
      for (final task in tasks.value)
        if (task.id == updated.id) updated else task,
    ];
  }

  Future<MaintenanceTask> updateTaskOnServer(
    MaintenanceTask task, {
    required MaintenanceTaskStatus status,
    String? notes,
    List<String> evidencePhotoPaths = const [],
  }) async {
    final revision = _sessionRevision;
    final scope = _scopeRevision;
    if (!task.needsEvidence) throw StateError('This task is read-only');
    if (!canSubmitEvidence(task)) throw StateError('Task is outside your team');
    if (status == MaintenanceTaskStatus.pendingApproval) {
      throw StateError('Choose Completed to submit evidence');
    }
    final submitting = status == MaintenanceTaskStatus.completed;
    await MaintenanceUpdateService.validate(
      status: status,
      notes: notes ?? '',
      photos: evidencePhotoPaths,
      checkFiles: Firebase.apps.isNotEmpty,
    );
    if (revision != _sessionRevision || scope != _scopeRevision) {
      throw StateError('Your session changed');
    }
    if (Firebase.apps.isEmpty) {
      final updated = task.copyWith(
        status: submitting
            ? MaintenanceTaskStatus.pendingApproval
            : MaintenanceTaskStatus.inProgress,
        fieldIssueNotes: status == MaintenanceTaskStatus.failed ? notes : null,
        resolutionPhotoUrls: submitting ? evidencePhotoPaths : null,
        completionSubmittedAt: submitting ? DateTime.now() : null,
        clearSendBack: submitting,
        completionNotes: submitting ? notes : null,
        progressNotes:
            status == MaintenanceTaskStatus.inProgress &&
                notes?.trim().isNotEmpty == true
            ? notes!.trim()
            : null,
        completedAtLabel: status == MaintenanceTaskStatus.completed
            ? 'Just now'
            : null,
      );
      updateTask(updated);
      return updated;
    }
    final identity = FirebaseAuth.instance.currentUser?.uid;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in technician is required');
    void checkOwnership() {
      if (revision != _sessionRevision ||
          scope != _scopeRevision ||
          identity != FirebaseAuth.instance.currentUser?.uid ||
          !canSubmitEvidence(taskById(task.id) ?? task)) {
        throw StateError('Your session or task access changed. Refresh Tasks.');
      }
    }

    final updated = await _updates.save(
      task,
      status: status,
      notes: notes ?? '',
      photos: evidencePhotoPaths,
      checkOwnership: checkOwnership,
      update: (id, fields, photos) => ApiClient.instance.updateReport(
        id,
        idToken: token,
        fields: fields,
        resolutionPhotoPaths: photos,
      ),
    );
    checkOwnership();
    ++_refreshRevision;
    updateTask(updated);
    return updated;
  }

  /// The team a task was assigned to — a Municipal Officer assigns a
  /// report to a whole [MaintenanceTeam], not individual technicians, so
  /// every one of that team's members sees the same task.
  MaintenanceTeam? teamForTask(MaintenanceTask task) =>
      MaintenanceTeamDirectory.instance.teamById(task.teamId);

  /// Any member of the assigned team may submit; the officer reviews it.
  /// Server-side authorization remains authoritative for real requests.
  bool canSubmitEvidence(MaintenanceTask task) {
    if (!task.needsEvidence) return false;
    if (!_live()) return true;
    return _session.authenticated &&
        _session.verifiedOwner != null &&
        _session.verifiedOwner == _owner() &&
        _session.profile.value.teamId == task.teamId;
  }

  @visibleForTesting
  void dispose() {
    clearSession();
    _session.profile.removeListener(_observeScope);
    tasks.dispose();
    loading.dispose();
    error.dispose();
  }
}

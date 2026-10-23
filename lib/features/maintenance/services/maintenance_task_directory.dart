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
  MaintenanceTaskDirectory._();

  static final MaintenanceTaskDirectory instance = MaintenanceTaskDirectory._();

  /// The signed-in technician's own account — the same real Admin-
  /// provisioned Maintenance Team record (Yaw Asare, already a member of
  /// `TEAM-0001` "Kumasi Central Crew" in [MaintenanceTeamDirectory]) that
  /// Profile now displays, rather than an unrelated made-up name with no
  /// backing account. This is what "my team" and the evidence-upload lead
  /// check below are actually computed against.
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
  }

  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    final revision = _sessionRevision, refresh = ++_refreshRevision;
    loading.value = true;
    error.value = null;
    try {
      await MaintenanceSession.instance.refresh();
      if (revision != _sessionRevision) return;
      final identity = FirebaseAuth.instance.currentUser;
      final token = await identity?.getIdToken();
      if (token == null) throw StateError('A signed-in technician is required');
      final response = await ApiClient.instance.listReports(idToken: token);
      if (revision != _sessionRevision ||
          refresh != _refreshRevision ||
          identity?.uid != FirebaseAuth.instance.currentUser?.uid) {
        return;
      }
      tasks.value = response.map(MaintenanceTask.fromApi).toList();
      hasLiveSnapshot = true;
    } catch (exception) {
      if (revision == _sessionRevision && refresh == _refreshRevision) {
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
    if (revision != _sessionRevision) throw StateError('Your session changed');
    if (Firebase.apps.isEmpty) {
      final updated = task.copyWith(
        status: submitting
            ? MaintenanceTaskStatus.pendingApproval
            : MaintenanceTaskStatus.inProgress,
        fieldIssueNotes: status == MaintenanceTaskStatus.failed ? notes : null,
        resolutionPhotoUrls: submitting ? evidencePhotoPaths : null,
        completionSubmittedAt: submitting ? DateTime.now() : null,
        clearSendBack: submitting,
        completionNotes: notes,
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
    if (Firebase.apps.isEmpty) return true;
    return MaintenanceSession.instance.profile.value.teamId == task.teamId;
  }
}

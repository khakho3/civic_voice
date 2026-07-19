import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../services/api_client.dart';
import '../../admin/models/admin_maintenance_team_data.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../models/maintenance_task.dart';
import 'maintenance_session.dart';

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
    mockMaintenanceTasks(),
  );
  bool hasLiveSnapshot = false;

  Future<void> refresh() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in technician is required');
    final response = await ApiClient.instance.listReports(idToken: token);
    tasks.value = response.map(MaintenanceTask.fromApi).toList();
    hasLiveSnapshot = true;
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
    if (Firebase.apps.isEmpty) {
      final updated = task.copyWith(
        status: status,
        completionNotes: notes,
        completedAtLabel: status == MaintenanceTaskStatus.completed
            ? 'Just now'
            : null,
      );
      updateTask(updated);
      return updated;
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in technician is required');
    final fields = <String, String>{
      if (status == MaintenanceTaskStatus.assigned ||
          status == MaintenanceTaskStatus.inProgress)
        'status': 'IN_PROGRESS',
      if (status == MaintenanceTaskStatus.completed) ...{
        'status': 'RESOLVED',
        'progressPercent': '100',
        'resolutionNotes': notes ?? '',
        'maintenanceFailureNotes': '',
      },
      if (status == MaintenanceTaskStatus.failed) ...{
        'status': 'IN_PROGRESS',
        'progressPercent': '0',
        'maintenanceFailureNotes': notes ?? '',
      },
      if (notes?.trim().isNotEmpty == true &&
          status != MaintenanceTaskStatus.failed)
        'resolutionNotes': notes!.trim(),
    };
    final response = await ApiClient.instance.updateReport(
      task.apiId ?? task.id,
      idToken: token,
      fields: fields,
      resolutionPhotoPaths: evidencePhotoPaths,
    );
    final updated = MaintenanceTask.fromApi(response);
    updateTask(updated);
    return updated;
  }

  /// The team a task was assigned to — a Municipal Officer assigns a
  /// report to a whole [MaintenanceTeam], not individual technicians, so
  /// every one of that team's members sees the same task.
  MaintenanceTeam? teamForTask(MaintenanceTask task) =>
      MaintenanceTeamDirectory.instance.teamById(task.teamId);

  /// Whether [currentUserId] may submit completion evidence for [task].
  ///
  /// If the team has a lead, only the lead may submit — once one member
  /// submits, [updateTask] above updates the single shared task record, so
  /// every teammate immediately sees it as done rather than each having
  /// their own separate copy to individually mark complete. If the team
  /// has no lead set (or can't be resolved at all), any member may submit,
  /// since there's no one designated to be the sole submitter.
  bool canSubmitEvidence(MaintenanceTask task) {
    final team = teamForTask(task);
    final leadUserId =
        team?.leadUserId ??
        (MaintenanceSession.instance.profile.value.teamId == task.teamId
            ? MaintenanceSession.instance.profile.value.teamLeadUserId
            : null);
    if (leadUserId == null) return true;
    return leadUserId == currentUserId;
  }
}

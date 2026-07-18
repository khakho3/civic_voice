import 'package:flutter/foundation.dart';

import '../../admin/models/admin_maintenance_team_data.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../models/maintenance_task.dart';

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
  static const currentUserId = 'CV-USER-0104';

  final ValueNotifier<List<MaintenanceTask>> tasks = ValueNotifier(
    mockMaintenanceTasks(),
  );

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
    if (team == null || team.leadUserId == null) return true;
    return team.leadUserId == currentUserId;
  }
}

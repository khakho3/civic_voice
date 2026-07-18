import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_severity.dart';

/// A maintenance task's lifecycle state — what Dashboard/Assigned Tasks list
/// by, what Update Progress writes to, and what Task Details/Task Completed
/// both read back. One enum shared by every screen in the flow, replacing
/// four previously-separate, disconnected notions of "status" (a private
/// enum on Dashboard, a raw `String` on Assigned Tasks, a hardcoded label on
/// Task Details, another private enum on Update Progress) that had no way to
/// agree with each other.
///
/// Not simply [ReportStatus] (the citizen-facing report pipeline shared
/// across Citizen/Municipal/Ministry) — a task can be marked [failed]
/// (attempted, couldn't complete), which has no equivalent report-facing
/// state; [ReportStatus.rejected] means something different (the report
/// itself was invalid/duplicate). Colors are still deliberately the same
/// [AppColors] tokens [ReportStatus] uses for the states that do overlap
/// (assigned/inProgress/resolved), so the two read as the same visual
/// language even though they're separate types.
enum MaintenanceTaskStatus {
  assigned('Assigned', AppColors.statusAssigned),
  inProgress('In Progress', AppColors.statusInProgress),
  completed('Completed', AppColors.statusResolved),
  failed('Failed', AppColors.statusRejected);

  const MaintenanceTaskStatus(this.label, this.color);

  final String label;
  final Color color;

  /// Text color for [color] rendered on its own low-alpha tint (badges) —
  /// mirrors [ReportStatus.badgeTextColor] exactly for the three states
  /// this shares the same underlying [AppColors] token with.
  Color badgeTextColor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      MaintenanceTaskStatus.assigned =>
        isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
      MaintenanceTaskStatus.inProgress =>
        isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
      MaintenanceTaskStatus.completed => AppColors.statusResolved,
      MaintenanceTaskStatus.failed => AppColors.statusRejected,
    };
  }
}

/// One assigned maintenance task, threaded by [id] through the whole MNT
/// flow (Dashboard/Assigned Tasks list it → Task Details shows it → Update
/// Progress mutates its status/notes → Task Completed reads back the same
/// record) via [MaintenanceTaskDirectory] — replacing the previous four
/// screens' four independent hardcoded mock values (different titles,
/// different fake IDs, no shared identity), where tapping any task always
/// landed on the same static "Broken Street Light"/"#TASK-8821" regardless
/// of which one was tapped.
class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.status,
    required this.eta,
    required this.distanceLabel,
    required this.teamNote,
    required this.teamId,
    this.reportPhotoCount = 0,
    this.completionNotes,
    this.completedAtLabel,
    this.completedWeekday,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String locationLabel;
  final double latitude;
  final double longitude;

  /// Inherited straight from the citizen's original report — set during
  /// the Municipal Officer's own triage/review (MUN-003 Report Review), the
  /// same [ReportSeverity] a report already carries before it's ever
  /// assigned to a maintenance team. Not a value a technician sets or a
  /// maintenance-side concept invented independently — this is the answer
  /// to "what sets task priority": whoever reviewed the underlying report.
  final ReportSeverity priority;
  final MaintenanceTaskStatus status;

  /// The [MaintenanceTeam.teamId] (see the Admin module's own
  /// `admin_maintenance_team_data.dart`) this task was assigned to — a
  /// Municipal Officer assigns a report to a whole team, not individual
  /// technicians, so every member of that team sees this same task.
  final String teamId;

  /// Short field-facing label — e.g. "On site", "Today 2:30 PM".
  final String eta;

  final String distanceLabel;

  /// Short crew-status note shown on the Assigned Tasks card, e.g. "Team
  /// active - 2 members" or a scheduled time.
  final String teamNote;

  /// How many photos the citizen attached to the original report — shown
  /// as a placeholder-illustrated count on Task Details (no real photo
  /// storage/CDN yet), distinct from the completion evidence a technician
  /// captures in Update Progress.
  final int reportPhotoCount;

  /// Set once [status] reaches [MaintenanceTaskStatus.completed] or
  /// [MaintenanceTaskStatus.failed] — the work notes entered on Update
  /// Progress, read back verbatim on Task Completed.
  final String? completionNotes;

  /// Set alongside [completionNotes] — a display-ready timestamp label
  /// (mock data has no real clock to derive this from).
  final String? completedAtLabel;

  /// 0 (Monday) through 6 (Sunday) — which bar of Dashboard's "Weekly
  /// Completion" chart this task counts toward. Only meaningful once
  /// [status] is [MaintenanceTaskStatus.completed].
  final int? completedWeekday;

  bool get needsEvidence =>
      status != MaintenanceTaskStatus.completed &&
      status != MaintenanceTaskStatus.failed;

  /// Whether this task's own fields mention [query] — used by Assigned
  /// Tasks' search field.
  bool matches(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return true;
    return [
      title,
      locationLabel,
      category,
      eta,
      distanceLabel,
      teamNote,
      status.label,
      priority.label,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }

  MaintenanceTask copyWith({
    MaintenanceTaskStatus? status,
    String? completionNotes,
    String? completedAtLabel,
    int? completedWeekday,
  }) {
    return MaintenanceTask(
      id: id,
      title: title,
      description: description,
      category: category,
      locationLabel: locationLabel,
      latitude: latitude,
      longitude: longitude,
      priority: priority,
      status: status ?? this.status,
      eta: eta,
      distanceLabel: distanceLabel,
      teamNote: teamNote,
      teamId: teamId,
      reportPhotoCount: reportPhotoCount,
      completionNotes: completionNotes ?? this.completionNotes,
      completedAtLabel: completedAtLabel ?? this.completedAtLabel,
      completedWeekday: completedWeekday ?? this.completedWeekday,
    );
  }
}

/// Placeholder content matching the approved MNT-00x designs, used until the
/// Cloud Firestore-backed task assignment service is wired up. Five tasks —
/// enough to give Dashboard's weekly-completion chart and Assigned Tasks'
/// status/priority filters real variety, rather than the 2-5 disconnected
/// entries the four screens each hardcoded separately before.
List<MaintenanceTask> mockMaintenanceTasks() {
  return const [
    MaintenanceTask(
      id: 'MNT-1001',
      title: 'Broken Street Light at Main Ave',
      description:
          'Light flickers and creates safety hazard for pedestrians and '
          'vehicles at night.',
      category: 'Street Lighting',
      locationLabel: '242 Main Avenue, Central District',
      latitude: 6.5244,
      longitude: 3.3792,
      priority: ReportSeverity.high,
      status: MaintenanceTaskStatus.inProgress,
      eta: 'On site',
      distanceLabel: '1.2 km',
      teamNote: 'Team active - 2 members',
      teamId: 'TEAM-0001',
      reportPhotoCount: 2,
    ),
    MaintenanceTask(
      id: 'MNT-1002',
      title: 'Pothole Repair Request',
      description:
          'Deep pothole spanning both lanes, drivers swerving to avoid it.',
      category: 'Road Repair',
      locationLabel: 'Elm Street & 4th Cross',
      latitude: 6.5312,
      longitude: 3.3689,
      priority: ReportSeverity.medium,
      status: MaintenanceTaskStatus.assigned,
      eta: 'Today 2:30 PM',
      distanceLabel: '3.8 km',
      teamNote: 'Today, 2:30 PM',
      teamId: 'TEAM-0001',
      reportPhotoCount: 1,
    ),
    MaintenanceTask(
      id: 'MNT-1003',
      title: 'Oak St Pothole',
      description: 'Shallow pothole reported near the downtown crossing.',
      category: 'Road Repair',
      locationLabel: '1242 Oak Street, Downtown',
      latitude: 6.5201,
      longitude: 3.3765,
      priority: ReportSeverity.low,
      status: MaintenanceTaskStatus.assigned,
      eta: 'Tomorrow 9:00 AM',
      distanceLabel: '2.1 km',
      teamNote: 'Tomorrow, 9:00 AM',
      teamId: 'TEAM-0001',
      reportPhotoCount: 1,
    ),
    MaintenanceTask(
      id: 'MNT-1004',
      title: 'Hydrant Maintenance',
      description: 'Routine inspection and valve service for fire hydrant.',
      category: 'Utilities',
      locationLabel: 'West Park Perimeter',
      latitude: 6.5178,
      longitude: 3.3821,
      priority: ReportSeverity.low,
      status: MaintenanceTaskStatus.completed,
      eta: 'Completed',
      distanceLabel: '0.9 km',
      teamNote: 'Closed out',
      teamId: 'TEAM-0001',
      completionNotes:
          'Valve serviced and pressure-tested. No leaks found; hydrant '
          'returned to full service.',
      completedAtLabel: 'Oct 10, 11:15 AM',
      completedWeekday: 4,
    ),
    MaintenanceTask(
      id: 'MNT-1005',
      title: 'Street Light Follow-up',
      description: 'Second visit to confirm the earlier ballast repair held.',
      category: 'Street Lighting',
      locationLabel: 'Maple Ave & 5th Crossing',
      latitude: 6.5299,
      longitude: 3.3711,
      priority: ReportSeverity.medium,
      status: MaintenanceTaskStatus.completed,
      eta: 'Completed',
      distanceLabel: '1.6 km',
      teamNote: 'Closed out',
      teamId: 'TEAM-0001',
      completionNotes:
          'Ballast replacement confirmed stable. Light cycling normally '
          'across three consecutive nights.',
      completedAtLabel: 'Oct 12, 07:40 PM',
      completedWeekday: 2,
    ),
  ];
}

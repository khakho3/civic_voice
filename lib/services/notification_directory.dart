import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../features/admin/services/admin_user_directory.dart';
import '../features/admin/models/admin_user_management_data.dart';
import '../features/citizen/services/report_crud_service.dart';
import '../features/maintenance/models/maintenance_task.dart';
import '../features/maintenance/services/maintenance_task_directory.dart';
import '../features/municipal/services/municipal_report_directory.dart';
import '../features/municipal/services/municipal_session.dart';
import '../features/maintenance/services/maintenance_session.dart';
import '../models/notification_item.dart';
import '../models/report_status.dart';

/// The one shared, real "have I seen this" ledger every module's
/// notifications read through. Content is never duplicated into a second
/// list — each `for*()` method below computes notifications fresh from
/// whichever real directory the event actually happened in
/// (`MunicipalReportDirectory`, `MaintenanceTaskDirectory`, Citizen's
/// `ReportCrudService`), so a notification can never disagree with the
/// record it's about. Only read/unread state is genuinely new and
/// session-persisted here, mirroring the `AdminUserDirectory`/
/// `MaintenanceTeamDirectory`/`MunicipalReportDirectory` `ValueNotifier`
/// pattern used everywhere else in this app.
class NotificationDirectory {
  NotificationDirectory._();

  static final NotificationDirectory instance = NotificationDirectory._();

  final ValueNotifier<Set<String>> readIds = ValueNotifier(<String>{});
  static const _readIdsKey = 'notification_read_ids';

  /// "Clear all" ledger — mirrors [readIds] exactly, but for dismissal
  /// rather than read state. Notifications have no separate stored row to
  /// delete (every `for*()` method computes them fresh from real report/
  /// task/account state — see the class doc comment), so "clear" can't be
  /// a real delete without risking the underlying record. Instead this
  /// tracks which already-seen notification ids the user dismissed, and
  /// every `for*()` result filters them out. Because ids encode status
  /// (e.g. `citizen-report-<id>-<status>`), a later status change mints a
  /// new id that isn't in this set, so a dismissed notification correctly
  /// reappears once there's something genuinely new to say — clearing
  /// never permanently silences a report/task/account going forward.
  final ValueNotifier<Set<String>> dismissedIds = ValueNotifier(<String>{});
  static const _dismissedIdsKey = 'notification_dismissed_ids';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    readIds.value = (preferences.getStringList(_readIdsKey) ?? const <String>[])
        .toSet();
    dismissedIds.value =
        (preferences.getStringList(_dismissedIdsKey) ?? const <String>[])
            .toSet();
  }

  bool isRead(String id) => readIds.value.contains(id);

  void markRead(String id) {
    if (readIds.value.contains(id)) return;
    readIds.value = {...readIds.value, id};
    _persist(_readIdsKey, readIds.value);
  }

  void markAllRead(Iterable<String> ids) {
    final updated = {...readIds.value, ...ids};
    if (updated.length == readIds.value.length) return;
    readIds.value = updated;
    _persist(_readIdsKey, readIds.value);
  }

  bool isDismissed(String id) => dismissedIds.value.contains(id);

  /// Dismisses every currently-visible notification in [ids] — "Clear
  /// all". Pass the caller's own already-filtered id list (e.g.
  /// `forCitizen().map((n) => n.id)`), never every id that's ever existed.
  void clearAll(Iterable<String> ids) {
    final updated = {...dismissedIds.value, ...ids};
    if (updated.length == dismissedIds.value.length) return;
    dismissedIds.value = updated;
    _persist(_dismissedIdsKey, dismissedIds.value);
  }

  void _persist(String key, Set<String> values) {
    final sorted = values.toList()..sort();
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.setStringList(key, sorted));
      return;
    }
    unawaited(
      SharedPreferences.getInstance().then((instance) {
        _preferences = instance;
        instance.setStringList(key, sorted);
      }),
    );
  }

  /// The one signal every bell/tab dot badge reads — just handed a
  /// different, already-filtered `items` list per surface.
  bool hasUnread(List<NotificationItem> items) =>
      items.any((item) => !item.read);

  NotificationItem _build({
    required String id,
    required NotificationType type,
    required String title,
    required String message,
    required String category,
    required String timeLabel,
    required IconData icon,
    required Color color,
    String? referenceId,
  }) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      category: category,
      timeLabel: timeLabel,
      icon: icon,
      color: color,
      read: isRead(id),
      referenceId: referenceId,
    );
  }

  /// A citizen's own reports, mapped 1:1 by current status.
  List<NotificationItem> forCitizen() {
    final reports = ReportCrudService.instance.reports.value;
    final items = [
      for (final report in reports)
        _build(
          id: 'citizen-report-${report.id}-${report.status.name}',
          type: switch (report.status) {
            ReportStatus.submitted => NotificationType.citizenReportSubmitted,
            ReportStatus.underReview =>
              NotificationType.citizenReportUnderReview,
            ReportStatus.assigned => NotificationType.citizenReportAssigned,
            ReportStatus.inProgress => NotificationType.citizenReportInProgress,
            ReportStatus.resolved => NotificationType.citizenReportResolved,
            ReportStatus.rejected => NotificationType.citizenReportRejected,
          },
          title: switch (report.status) {
            ReportStatus.submitted => 'Report submitted',
            ReportStatus.underReview => 'Report under review',
            ReportStatus.assigned => 'Report assigned',
            ReportStatus.inProgress => 'Report moved to In Progress',
            ReportStatus.resolved => 'Report resolved',
            ReportStatus.rejected => 'Report rejected',
          },
          message: switch (report.status) {
            ReportStatus.submitted =>
              'Your report has been submitted and is waiting for review.',
            ReportStatus.underReview =>
              'Your report is being reviewed by the civic team.',
            ReportStatus.assigned =>
              'Your report was assigned to a maintenance team.',
            ReportStatus.inProgress =>
              'The maintenance team has started work on this report.',
            ReportStatus.resolved =>
              'The responsible team has marked this report as resolved.',
            ReportStatus.rejected =>
              report.rejectionReason?.trim().isNotEmpty == true
                  ? 'Reason: ${report.rejectionReason}'
                  : 'Your report was reviewed and could not be accepted.',
          },
          category: switch (report.status) {
            ReportStatus.submitted || ReportStatus.underReview => 'Report',
            ReportStatus.assigned || ReportStatus.inProgress => 'Status',
            ReportStatus.resolved => 'Resolved',
            ReportStatus.rejected => 'Rejected',
          },
          timeLabel: report.timeLabel,
          icon: report.status.icon,
          color: report.status.color,
          referenceId: report.id,
        ),
    ];
    return items.where((item) => !isDismissed(item.id)).toList();
  }

  /// Reports newly submitted to Municipal's Inbox, awaiting triage — the
  /// same source `MunicipalReportDirectory` powers Inbox/Active/Dashboard.
  List<NotificationItem> forMunicipal() {
    final officerId = MunicipalSession.instance.profile.value.employeeId;
    final reports = MunicipalReportDirectory.instance.reports.value.where(
      (r) => r.status == ReportStatus.submitted,
    );
    final items = [
      for (final report in reports)
        _build(
          id: 'municipal-$officerId-report-${report.referenceId}',
          type: NotificationType.municipalNewIncomingReport,
          title: 'New incoming report',
          message: '${report.title} was just submitted.',
          category: 'New',
          timeLabel: report.timeAgo,
          icon: AppIcons.inbox,
          color: AppColors.primary,
          referenceId: report.referenceId,
        ),
      for (final report in MunicipalReportDirectory.instance.reports.value)
        if (report.status == ReportStatus.inProgress)
          _build(
            id: 'municipal-$officerId-report-${report.referenceId}-in-progress',
            type: NotificationType.municipalMaintenanceStarted,
            title: 'Maintenance work started',
            message:
                '${report.teamName ?? 'The assigned team'} started work on ${report.referenceId}.',
            category: 'Progress',
            timeLabel: report.updatedLabel ?? 'Recently',
            icon: AppIcons.statusInProgress,
            color: ReportStatus.inProgress.color,
            referenceId: report.referenceId,
          )
        else if (report.status == ReportStatus.resolved)
          _build(
            id: 'municipal-$officerId-report-${report.referenceId}-resolved',
            type: NotificationType.municipalReportResolved,
            title: 'Report resolved',
            message:
                '${report.teamName ?? 'The assigned team'} completed ${report.referenceId}.',
            category: 'Resolved',
            timeLabel: report.updatedLabel ?? 'Recently',
            icon: AppIcons.statusResolved,
            color: ReportStatus.resolved.color,
            referenceId: report.referenceId,
          ),
      for (final report in MunicipalReportDirectory.instance.reports.value)
        if (report.maintenanceFailureNotes?.trim().isNotEmpty == true)
          _build(
            id: 'municipal-$officerId-maintenance-${report.referenceId}',
            type: NotificationType.municipalMaintenanceEscalation,
            title: 'Maintenance needs attention',
            message: '${report.referenceId}: ${report.maintenanceFailureNotes}',
            category: 'Escalation',
            timeLabel: report.updatedLabel ?? 'Recently',
            icon: AppIcons.warning,
            color: AppColors.warning,
            referenceId: report.referenceId,
          ),
    ];
    return items.where((item) => !isDismissed(item.id)).toList();
  }

  /// Live account events visible within the signed-in Admin's already scoped
  /// user directory. This is deliberately separate from the full audit log.
  List<NotificationItem> forAdmin() {
    final users = AdminUserDirectory.instance.users.value;
    final items = [
      for (final user in users)
        if (user.status == AdminUserStatus.inactive)
          _build(
            id: 'admin-user-${user.userId}-inactive',
            type: NotificationType.adminUserDeactivated,
            title: 'Account deactivated',
            message: '${user.name} can no longer sign in.',
            category: 'Security',
            timeLabel: 'Current status',
            icon: AppIcons.permissionDenied,
            color: AppColors.error,
            referenceId: user.userId,
          )
        else if (DateTime.now().difference(user.accountCreated).inDays <= 7)
          _build(
            id: 'admin-user-${user.userId}-created',
            type: NotificationType.adminUserCreated,
            title: 'New account created',
            message: '${user.name} joined as ${user.role.label}.',
            category: 'Account',
            timeLabel: 'Recently',
            icon: AppIcons.profile,
            color: AppColors.primary,
            referenceId: user.userId,
          ),
    ];
    return items.where((item) => !isDismissed(item.id)).toList();
  }

  /// Current task events for the signed-in technician's exact team.
  List<NotificationItem> forMaintenance() {
    final tasks = MaintenanceTaskDirectory.instance.tasks.value;
    final items = [
      for (final task in tasks)
        _build(
          id:
              'maintenance-${MaintenanceSession.instance.profile.value.publicId}'
              '-task-${task.id}-${task.status.name}',
          type: switch (task.status) {
            MaintenanceTaskStatus.assigned =>
              NotificationType.maintenanceTaskAssigned,
            MaintenanceTaskStatus.inProgress =>
              NotificationType.maintenanceTaskInProgress,
            MaintenanceTaskStatus.completed || MaintenanceTaskStatus.failed =>
              NotificationType.maintenanceTaskCompleted,
          },
          title: switch (task.status) {
            MaintenanceTaskStatus.assigned => 'New task assigned',
            MaintenanceTaskStatus.inProgress => 'Team task in progress',
            MaintenanceTaskStatus.completed => 'Team task completed',
            MaintenanceTaskStatus.failed => 'Team task needs attention',
          },
          message: switch (task.status) {
            MaintenanceTaskStatus.assigned =>
              '${task.title} was assigned to your team.',
            MaintenanceTaskStatus.inProgress =>
              'Your team has started work on ${task.id}.',
            MaintenanceTaskStatus.completed =>
              '${task.id} was marked completed.',
            MaintenanceTaskStatus.failed =>
              '${task.id} could not be completed and needs attention.',
          },
          category: switch (task.status) {
            MaintenanceTaskStatus.assigned => 'New',
            MaintenanceTaskStatus.inProgress => 'Progress',
            MaintenanceTaskStatus.completed => 'Completed',
            MaintenanceTaskStatus.failed => 'Attention',
          },
          timeLabel: task.teamNote,
          icon: switch (task.status) {
            MaintenanceTaskStatus.assigned => AppIcons.statusAssigned,
            MaintenanceTaskStatus.inProgress => AppIcons.statusInProgress,
            MaintenanceTaskStatus.completed => AppIcons.statusResolved,
            MaintenanceTaskStatus.failed => AppIcons.statusRejected,
          },
          color: task.status.color,
          referenceId: task.id,
        ),
    ];
    return items.where((item) => !isDismissed(item.id)).toList();
  }

  /// Reports resolved anywhere in the country — Ministry's national
  /// oversight remit, so unlike Municipal this is deliberately not
  /// assembly-scoped.
  List<NotificationItem> forMinistry() {
    final reports = MunicipalReportDirectory.instance.reports.value.where(
      (r) => r.status == ReportStatus.resolved,
    );
    final items = [
      for (final report in reports)
        _build(
          id: 'ministry-report-${report.referenceId}',
          type: NotificationType.ministryReportResolvedNational,
          title: 'Report resolved',
          message: '${report.title} was marked resolved.',
          category: 'Resolved',
          timeLabel: report.updatedLabel ?? report.timeAgo,
          icon: AppIcons.statusResolved,
          color: ReportStatus.resolved.color,
          referenceId: report.referenceId,
        ),
    ];
    return items.where((item) => !isDismissed(item.id)).toList();
  }
}

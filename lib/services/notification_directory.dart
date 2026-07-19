import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../features/admin/services/admin_maintenance_team_directory.dart';
import '../features/citizen/services/report_crud_service.dart';
import '../features/maintenance/models/maintenance_task.dart';
import '../features/maintenance/services/maintenance_task_directory.dart';
import '../features/municipal/services/municipal_report_directory.dart';
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
  SharedPreferences? _preferences;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    readIds.value = (preferences.getStringList(_readIdsKey) ?? const <String>[])
        .toSet();
  }

  bool isRead(String id) => readIds.value.contains(id);

  void markRead(String id) {
    if (readIds.value.contains(id)) return;
    readIds.value = {...readIds.value, id};
    _persistReadIds();
  }

  void markAllRead(Iterable<String> ids) {
    final updated = {...readIds.value, ...ids};
    if (updated.length == readIds.value.length) return;
    readIds.value = updated;
    _persistReadIds();
  }

  void _persistReadIds() {
    final values = readIds.value.toList()..sort();
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.setStringList(_readIdsKey, values));
      return;
    }
    unawaited(
      SharedPreferences.getInstance().then((instance) {
        _preferences = instance;
        instance.setStringList(_readIdsKey, values);
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
    return [
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
              'Your report was reviewed and could not be accepted.',
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
  }

  /// Reports newly submitted to Municipal's Inbox, awaiting triage — the
  /// same source `MunicipalReportDirectory` powers Inbox/Active/Dashboard.
  List<NotificationItem> forMunicipal() {
    final reports = MunicipalReportDirectory.instance.reports.value.where(
      (r) => r.status == ReportStatus.submitted,
    );
    return [
      for (final report in reports)
        _build(
          id: 'municipal-report-${report.referenceId}',
          type: NotificationType.municipalNewIncomingReport,
          title: 'New incoming report',
          message: '${report.title} was just submitted.',
          category: 'New',
          timeLabel: report.timeAgo,
          icon: AppIcons.inbox,
          color: AppColors.primary,
          referenceId: report.referenceId,
        ),
    ];
  }

  /// Tasks newly assigned to the signed-in technician's own team.
  List<NotificationItem> forMaintenance() {
    final currentUserId = MaintenanceTaskDirectory.currentUserId;
    String? myTeamId;
    for (final team in MaintenanceTeamDirectory.instance.teams.value) {
      if (team.memberUserIds.contains(currentUserId)) {
        myTeamId = team.teamId;
        break;
      }
    }
    final tasks = MaintenanceTaskDirectory.instance.tasks.value.where(
      (t) => t.status == MaintenanceTaskStatus.assigned && t.teamId == myTeamId,
    );
    return [
      for (final task in tasks)
        _build(
          id: 'maintenance-task-${task.id}',
          type: NotificationType.maintenanceTaskAssigned,
          title: 'New task assigned',
          message: '${task.title} was just assigned to your team.',
          category: 'New',
          timeLabel: 'Just now',
          icon: AppIcons.task,
          color: MaintenanceTaskStatus.assigned.color,
          referenceId: task.id,
        ),
    ];
  }

  /// Reports resolved anywhere in the country — Ministry's national
  /// oversight remit, so unlike Municipal this is deliberately not
  /// assembly-scoped.
  List<NotificationItem> forMinistry() {
    final reports = MunicipalReportDirectory.instance.reports.value.where(
      (r) => r.status == ReportStatus.resolved,
    );
    return [
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
  }
}

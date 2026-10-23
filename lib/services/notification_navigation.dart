import '../features/citizen/models/civic_report.dart';
import '../features/maintenance/models/maintenance_task.dart';
import '../features/municipal/models/incoming_report.dart';
import '../models/app_role.dart';
import '../models/notification_inbox.dart';
import '../features/citizen/services/report_crud_service.dart';
import '../features/municipal/services/municipal_report_directory.dart';
import '../features/municipal/models/resolved_report.dart';
import '../features/maintenance/services/maintenance_task_directory.dart';

class InboxNavigation {
  const InboxNavigation(this.route, [this.arguments]);
  final String route;
  final Object? arguments;
}

/// Resolve against freshly authorized records, never a stale push URL/status.
Future<InboxNavigation> resolveInboxNotification(
  InboxNotification item,
  AppRole role, {
  Future<List<CivicReport>> Function()? citizenReports,
  Future<List<MaintenanceTask>> Function()? maintenanceTasks,
  Future<List<IncomingReportItem>> Function()? municipalReports,
}) async {
  if (!inboxDestination(item.destination, role)) {
    throw StateError('Notification access changed');
  }
  final id = item.reportId;
  switch (role) {
    case AppRole.systemAdministrator:
      return const InboxNavigation('/admin/system-activity');
    case AppRole.ministrySupervisor:
      return const InboxNavigation('/ministry/reports');
    case AppRole.citizen:
      if (id == null) return const InboxNavigation('/citizen/reports');
      final reports = citizenReports != null
          ? await citizenReports()
          : await (() async {
              await ReportCrudService.instance.refresh();
              return ReportCrudService.instance.reports.value;
            })();
      final matches = reports.where((report) => report.id == id);
      if (matches.isEmpty) throw StateError('Report no longer available');
      return InboxNavigation(
        Uri(
          path: '/citizen/report-tracking',
          queryParameters: {'reportId': matches.first.id},
        ).toString(),
      );
    case AppRole.maintenanceTeam:
      if (id == null) {
        return const InboxNavigation('/maintenance/assigned-tasks');
      }
      final tasks = maintenanceTasks != null
          ? await maintenanceTasks()
          : await (() async {
              await MaintenanceTaskDirectory.instance.refresh();
              return MaintenanceTaskDirectory.instance.tasks.value;
            })();
      final matches = tasks.where((task) => task.id == id || task.apiId == id);
      if (matches.isEmpty) throw StateError('Task no longer available');
      return InboxNavigation(
        Uri(
          path: '/maintenance/task-details',
          queryParameters: {'taskId': matches.first.id},
        ).toString(),
      );
    case AppRole.municipalOfficer:
      if (id == null) return const InboxNavigation('/municipal/inbox');
      final reports = municipalReports != null
          ? await municipalReports()
          : await (() async {
              await MunicipalReportDirectory.instance.refresh();
              return MunicipalReportDirectory.instance.reports.value;
            })();
      final matches = reports.where(
        (report) => report.referenceId == id || report.apiId == id,
      );
      if (matches.isEmpty) throw StateError('Report no longer available');
      final report = matches.first;
      final path = switch (report.status) {
        ReportStatus.resolved ||
        ReportStatus.rejected => '/municipal/resolution-details',
        ReportStatus.assigned ||
        ReportStatus.inProgress ||
        ReportStatus.pendingApproval => '/municipal/report-progress',
        _ => '/municipal/report-review',
      };
      return InboxNavigation(
        Uri(
          path: path,
          queryParameters: {'reportId': report.referenceId},
        ).toString(),
        report.status.isClosed ? ResolvedReportItem.fromReport(report) : report,
      );
  }
}

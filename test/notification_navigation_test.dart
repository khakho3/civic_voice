import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/models/notification_inbox.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/models/resolved_report.dart';
import 'package:civic_voice/services/notification_navigation.dart';

InboxNotification notification(String destination) => InboxNotification(
  id: 'n1',
  title: 'Update',
  body: 'Report update',
  createdAt: DateTime.utc(2026),
  read: false,
  destination: destination,
);
void main() {
  for (final entry in {
    AppRole.citizen: ['/app/reports', '/citizen/reports'],
    AppRole.municipalOfficer: ['/app/municipal/inbox', '/municipal/inbox'],
    AppRole.maintenanceTeam: [
      '/app/maintenance/tasks',
      '/maintenance/assigned-tasks',
    ],
    AppRole.ministrySupervisor: ['/app/ministry/reports', '/ministry/reports'],
    AppRole.systemAdministrator: [
      '/app/admin/activity',
      '/admin/system-activity',
    ],
  }.entries) {
    test('${entry.key} opens its own native destination', () async {
      expect(
        (await resolveInboxNotification(
          notification(entry.value.first),
          entry.key,
        )).route,
        entry.value.last,
      );
    });
  }
  test(
    'cross-role destination is rejected before looking up records',
    () async {
      var loads = 0;
      await expectLater(
        resolveInboxNotification(
          notification('/app/admin/activity'),
          AppRole.citizen,
          citizenReports: () async {
            loads++;
            return [];
          },
        ),
        throwsStateError,
      );
      expect(loads, 0);
    },
  );
  test('citizen can open only a freshly permitted report ID', () async {
    final item = notification('/app/reports?report=internal-report');
    await expectLater(
      resolveInboxNotification(
        item,
        AppRole.citizen,
        citizenReports: () async => [],
      ),
      throwsStateError,
    );
    final target = await resolveInboxNotification(
      item,
      AppRole.citizen,
      citizenReports: () async => [
        const CivicReport(
          id: 'internal-report',
          title: 'Fixture',
          location: 'Street',
          timeLabel: '',
          status: ReportStatus.submitted,
        ),
      ],
    );
    expect(target.route, '/citizen/report-tracking?reportId=internal-report');
  });
  for (final status in ReportStatus.values) {
    test(
      'municipal stale review link follows current ${status.name}',
      () async {
        final report = IncomingReportItem(
          apiId: 'internal-report',
          referenceId: 'CV-FIXTURE',
          title: 'Fixture',
          description: '',
          locationLabel: 'Street',
          category: ReportCategory.sanitation,
          status: status,
          timeAgo: '',
        );
        final target = await resolveInboxNotification(
          notification('/app/municipal/report-review?reportId=internal-report'),
          AppRole.municipalOfficer,
          municipalReports: () async => [report],
        );
        final route = status.isClosed
            ? 'resolution-details'
            : [
                ReportStatus.assigned,
                ReportStatus.inProgress,
                ReportStatus.pendingApproval,
              ].contains(status)
            ? 'report-progress'
            : 'report-review';
        expect(target.route, '/municipal/$route?reportId=CV-FIXTURE');
        expect(
          target.arguments,
          status.isClosed ? isA<ResolvedReportItem>() : same(report),
        );
      },
    );
  }
  test('maintenance resolves server ID to public task ID', () async {
    const task = MaintenanceTask(
      id: 'TASK-FIXTURE',
      apiId: 'internal-report',
      title: 'Fixture',
      description: '',
      category: '',
      locationLabel: '',
      latitude: 5,
      longitude: 0,
      status: MaintenanceTaskStatus.assigned,
      eta: '',
      distanceLabel: '',
      teamNote: '',
      teamId: 'team',
    );
    final target = await resolveInboxNotification(
      notification('/app/maintenance/task-details/internal-report'),
      AppRole.maintenanceTeam,
      maintenanceTasks: () async => [task],
    );
    expect(target.route, '/maintenance/task-details?taskId=TASK-FIXTURE');
    await expectLater(
      resolveInboxNotification(
        notification('/app/maintenance/task-details/foreign'),
        AppRole.maintenanceTeam,
        maintenanceTasks: () async => [task],
      ),
      throwsStateError,
    );
  });
}

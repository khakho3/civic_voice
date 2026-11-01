import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/screens/assigned_tasks_screen.dart';
import 'package:civic_voice/features/maintenance/screens/update_progress_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_inbox_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_review_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_verification_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_assign_team_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_active_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolved_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolution_details_screen.dart';

import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/features/municipal/services/municipal_report_directory.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/models/resolved_report.dart';
import 'package:civic_voice/features/admin/models/admin_maintenance_team_data.dart';
import 'package:civic_voice/features/admin/services/admin_maintenance_team_directory.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/models/ghana_assemblies_data.dart';

const _task = MaintenanceTask(
  id: 'LAYOUT-TASK',
  title: 'Fixture street light repair',
  description: 'Replace the damaged fixture at the market junction.',
  category: 'Infrastructure',
  locationLabel: 'Market junction',
  latitude: 6.69,
  longitude: -1.62,
  status: MaintenanceTaskStatus.inProgress,
  eta: '2 hours',
  distanceLabel: '1 km',
  teamNote: 'Inspect wiring first.',
  teamId: 'LAYOUT-TEAM',
);

IncomingReportItem _report(String id, String title, ReportStatus status) =>
    IncomingReportItem(
      apiId: id,
      referenceId: id,
      title: title,
      description: 'Fixture report describing damage at the market junction.',
      locationLabel: 'Market junction',
      category: ReportCategory.infrastructure,
      status: status,
      timeAgo: '1 hour ago',
      reviewerPublicId: 'LAYOUT-OFFICER',
      reviewerName: 'Fixture Officer',
      reviewedByCurrentUser: true,
      citizenName: 'Fixture Citizen',
      teamName: status == ReportStatus.submitted ? null : 'Fixture repair crew',
      progressPercent: status == ReportStatus.resolved ? 100 : 40,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 3),
      resolutionNotes: 'Fixture repair inspected and accepted.',
    );

void main() {
  setUp(() {
    final previous = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previous);
  });
  final incoming = _report(
    'LAYOUT-INBOX',
    'Fixture incoming street damage',
    ReportStatus.submitted,
  );
  final active = _report(
    'LAYOUT-ACTIVE',
    'Fixture active drain repair',
    ReportStatus.inProgress,
  );
  final resolved = _report(
    'LAYOUT-RESOLVED',
    'Fixture resolved road repair',
    ReportStatus.resolved,
  );
  setUp(() {
    final maintenance = MaintenanceTaskDirectory.instance;
    final municipal = MunicipalReportDirectory.instance;
    final teams = MaintenanceTeamDirectory.instance;
    final oldTasks = maintenance.tasks.value;
    final oldMaintenanceLoading = maintenance.loading.value;
    final oldMaintenanceError = maintenance.error.value;
    final oldMaintenanceLive = maintenance.hasLiveSnapshot;
    final oldReports = municipal.reports.value;
    final oldMunicipalLoading = municipal.loading.value;
    final oldMunicipalError = municipal.error.value;
    final oldMunicipalLive = municipal.hasLiveSnapshot;
    final oldChanged = Set<String>.of(municipal.changedReferences);
    final oldDrafts = {
      for (final entry in municipal.verificationDrafts.entries)
        entry.key: Set<int>.of(entry.value),
    };
    final oldTeams = teams.teams.value;
    addTearDown(() {
      maintenance.tasks.value = oldTasks;
      maintenance.loading.value = oldMaintenanceLoading;
      maintenance.error.value = oldMaintenanceError;
      maintenance.hasLiveSnapshot = oldMaintenanceLive;
      municipal.reports.value = oldReports;
      municipal.loading.value = oldMunicipalLoading;
      municipal.error.value = oldMunicipalError;
      municipal.hasLiveSnapshot = oldMunicipalLive;
      municipal.changedReferences
        ..clear()
        ..addAll(oldChanged);
      municipal.verificationDrafts
        ..clear()
        ..addAll(oldDrafts);
      teams.teams.value = oldTeams;
    });
    maintenance.tasks.value = [_task];
    maintenance.loading.value = false;
    maintenance.error.value = null;
    maintenance.hasLiveSnapshot = true;
    municipal.reports.value = [incoming, active, resolved];
    municipal.loading.value = false;
    municipal.error.value = null;
    // Select the directory-backed list instead of ResolvedReportItem.mock().
    municipal.hasLiveSnapshot = true;
    municipal.changedReferences.clear();
    municipal.verificationDrafts.clear();
    teams.teams.value = [
      MaintenanceTeam(
        teamId: 'LAYOUT-TEAM',
        name: 'Fixture repair crew',
        region: Region.ashanti,
        assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
        memberUserIds: const ['LAYOUT-TECH'],
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  });
  final screens = <String, Widget Function()>{
    'maintenance dashboard': () => const DashboardScreen(),
    'maintenance tasks': () => const AssignedTasksScreen(),
    'maintenance editor': () => UpdateProgressScreen(task: _task),
    'municipal dashboard': () => const MunicipalDashboardScreen(),
    'municipal inbox': () => const MunicipalInboxScreen(),
    'municipal review': () =>
        const MunicipalReportReviewScreen(referenceId: 'LAYOUT-INBOX'),
    'municipal verification': () =>
        const MunicipalVerificationScreen(referenceId: 'LAYOUT-INBOX'),
    'municipal assignment': () =>
        const MunicipalAssignTeamScreen(referenceId: 'LAYOUT-INBOX'),
    'municipal active': () => const MunicipalActiveReportsScreen(),
    'municipal resolved': () => const MunicipalResolvedReportsScreen(),
    'municipal resolution': () => MunicipalResolutionDetailsScreen(
      referenceId: resolved.referenceId,
      data: ResolvedReportItem.fromReport(resolved),
    ),
  };
  final expectedContent = <String, List<String>>{
    'maintenance dashboard': [_task.title],
    'maintenance tasks': [_task.title],
    'maintenance editor': [_task.title, 'In Progress'],
    'municipal dashboard': [incoming.title, 'Fixture repair crew'],
    'municipal inbox': [incoming.title],
    'municipal review': [incoming.title, 'Fixture Citizen'],
    'municipal verification': [incoming.title, 'Issue confirmed'],
    'municipal assignment': [incoming.title, 'Fixture repair crew'],
    'municipal active': [active.title],
    'municipal resolved': [resolved.title],
    'municipal resolution': [
      resolved.title,
      'Fixture repair inspected and accepted.',
    ],
  };
  for (final screen in screens.entries) {
    for (final width in [320.0, 390.0, 412.0, 768.0]) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets('${screen.key} width=$width dark=$dark scale=$scale', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            final prior = FlutterError.onError;
            FlutterError.onError = (details) {
              debugPrint(details.toString());
              prior?.call(details);
            };
            addTearDown(() => FlutterError.onError = prior);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: screen.value(),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // A successful build alone does not prove a populated state.
            for (final content in expectedContent[screen.key]!) {
              final target = find.text(content);
              final vertical = find
                  .byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        axisDirectionToAxis(widget.axisDirection) ==
                            Axis.vertical,
                  )
                  .first;
              final position = tester.state<ScrollableState>(vertical).position;
              position.jumpTo(position.minScrollExtent);
              await tester.pumpAndSettle();
              for (
                var step = 0;
                target.evaluate().isEmpty && step < 40;
                step++
              ) {
                await tester.drag(vertical, const Offset(0, -180));
                await tester.pumpAndSettle();
              }
              expect(
                target,
                findsWidgets,
                reason: '${screen.key} must contain fixture content: $content',
              );
              // Center content below the fixed detail header.
              await Scrollable.ensureVisible(
                tester.element(target.first),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(
                target.hitTestable(),
                findsWidgets,
                reason: '${screen.key} must visibly display $content',
              );
              expect(tester.takeException(), isNull);
            }
            // Inspect content below the first viewport as well as the header.
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isNotEmpty) {
              await tester.drag(scrollables.first, const Offset(0, -700));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          });
        }
      }
    }
  }
}

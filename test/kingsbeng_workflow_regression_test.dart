import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/task_details_screen.dart';
import 'package:civic_voice/features/maintenance/screens/task_completed_screen.dart';
import 'package:civic_voice/features/maintenance/screens/update_progress_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/models/report_progress_data.dart';
import 'package:civic_voice/features/municipal/screens/municipal_active_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_progress_screen.dart';
import 'package:civic_voice/features/municipal/services/municipal_report_directory.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/notification_directory.dart';

Map<String, dynamic> fixture(String status) => {
  'id': 'workflow-test-id',
  'publicReference': 'CV-WORKFLOW-TEST',
  'title': 'Completion workflow test',
  'location': 'Kumasi Market Road',
  'status': status,
  'category': 'Infrastructure',
  'description': 'Damaged road surface.',
  'assignedTeamId': 'TEAM-0001',
  'assignedTeamName': 'Current team',
  'progressPercent': status == 'PENDING_APPROVAL' ? 100 : 70,
  'assignedAt': '2026-10-10T08:00:00Z',
  'startedAt': '2026-10-10T09:00:00Z',
  if (status == 'PENDING_APPROVAL')
    'completionSubmittedAt': '2026-10-11T12:00:00Z',
  'resolutionNotes': 'Road repaired and safe for use.',
  'photoUrls': <String>[],
  'resolutionPhotoUrls': status == 'PENDING_APPROVAL'
      ? <String>['https://example.invalid/completion.jpg']
      : <String>[],
};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'workflow-test');
    final municipal = MunicipalReportDirectory.instance;
    final previousReports = municipal.reports.value;
    final previousChanges = municipal.changedReferences.toSet();
    final oldTasks = MaintenanceTaskDirectory.instance.tasks.value;
    final oldCitizen = ReportCrudService.instance.reports.value;
    addTearDown(() {
      municipal.reports.value = previousReports;
      municipal.changedReferences
        ..clear()
        ..addAll(previousChanges);
      MaintenanceTaskDirectory.instance.tasks.value = oldTasks;
      ReportCrudService.instance.reports.value = oldCitizen;
    });
    municipal.reports.value = [
      IncomingReportItem.fromApi(fixture('PENDING_APPROVAL')),
    ];
    MaintenanceTaskDirectory.instance.tasks.value = [
      MaintenanceTask.fromApi(fixture('IN_PROGRESS')),
    ];
  });

  test(
    'pending approval is open, readonly to crew and separate from work percent',
    () {
      final task = MaintenanceTask.fromApi(fixture('PENDING_APPROVAL'));
      expect(task.status, MaintenanceTaskStatus.pendingApproval);
      expect(task.needsEvidence, isFalse);
      expect(ReportStatus.pendingApproval.isClosed, isFalse);
      expect(ReportStatus.pendingApproval.progressPercent, 90);
      expect(task.completionSubmittedAt, DateTime.utc(2026, 10, 11, 12));
      final progress = ReportProgressData.fromReport(
        IncomingReportItem.fromApi(fixture('PENDING_APPROVAL')),
      );
      expect(progress.completionPercent, 100);
      expect(progress.timeline.last.label, 'Submitted for Approval');
      expect(progress.timeline.where((step) => step.isCurrent), hasLength(1));
    },
  );

  test('unsupported maintenance statuses never become assigned', () {
    expect(
      () => MaintenanceTask.fromApi(fixture('FUTURE_STATUS')),
      throwsFormatException,
    );
  });

  test(
    'crew completion submits notes and photos for approval, never resolves',
    () async {
      final directory = MaintenanceTaskDirectory.instance;
      final task = directory.tasks.value.single;
      final updated = await directory.updateTaskOnServer(
        task,
        status: MaintenanceTaskStatus.completed,
        notes: 'Repair completed safely.',
        evidencePhotoPaths: ['first.jpg', 'second.jpg', 'third.jpg'],
      );
      expect(updated.status, MaintenanceTaskStatus.pendingApproval);
      expect(updated.resolutionPhotoUrls, hasLength(3));
      expect(updated.completionSubmittedAt, isNotNull);
      expect(updated.needsEvidence, isFalse);
      expect(
        () => directory.updateTaskOnServer(
          updated,
          status: MaintenanceTaskStatus.completed,
          notes: 'Repair completed safely.',
          evidencePhotoPaths: ['one', 'two', 'three'],
        ),
        throwsStateError,
      );
    },
  );

  test(
    'completion rejects incomplete evidence before mutating the task',
    () async {
      final directory = MaintenanceTaskDirectory.instance;
      final task = directory.tasks.value.single;
      await expectLater(
        directory.updateTaskOnServer(
          task,
          status: MaintenanceTaskStatus.completed,
          notes: 'Repair completed safely.',
          evidencePhotoPaths: ['one.jpg'],
        ),
        throwsFormatException,
      );
      expect(
        directory.tasks.value.single.status,
        MaintenanceTaskStatus.inProgress,
      );
    },
  );

  test(
    'send back requires a reason, approval requires a still-pending record',
    () async {
      final directory = MunicipalReportDirectory.instance;
      await expectLater(
        directory.sendBackCompletion('CV-WORKFLOW-TEST', ' '),
        throwsArgumentError,
      );
      expect(
        directory.reports.value.single.status,
        ReportStatus.pendingApproval,
      );
      await directory.sendBackCompletion(
        'CV-WORKFLOW-TEST',
        'Fill the remaining gap.',
      );
      expect(directory.reports.value.single.status, ReportStatus.inProgress);
      expect(
        directory.reports.value.single.sendBackReason,
        'Fill the remaining gap.',
      );
      await expectLater(
        directory.approveCompletion('CV-WORKFLOW-TEST'),
        throwsStateError,
      );
    },
  );

  test(
    'returned work preserves the original start and clears reason on resubmission',
    () async {
      final json = fixture('IN_PROGRESS')..['sendBackReason'] = 'Fill the gap.';
      final task = MaintenanceTask.fromApi(json);
      MaintenanceTaskDirectory.instance.tasks.value = [task];
      expect(task.needsEvidence, isTrue);
      final updated = await MaintenanceTaskDirectory.instance
          .updateTaskOnServer(
            task,
            status: MaintenanceTaskStatus.completed,
            notes: 'Gap filled and checked.',
            evidencePhotoPaths: ['one', 'two', 'three'],
          );
      expect(updated.startedAt, task.startedAt);
      expect(updated.sendBackReason, isNull);
      expect(updated.status, MaintenanceTaskStatus.pendingApproval);
    },
  );

  test('Citizen pending message names municipal confirmation', () {
    ReportCrudService.instance.reports.value = [
      const CivicReport(
        id: 'workflow-citizen',
        title: 'Road repair',
        location: 'Kumasi',
        timeLabel: 'Now',
        status: ReportStatus.pendingApproval,
      ),
    ];
    expect(
      NotificationDirectory.instance.forCitizen().single.message,
      contains('municipal confirmation'),
    );
  });

  testWidgets('pending record remains in active list and its pending filter', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MunicipalActiveReportsScreen(
          onReportTap: (r) => opened = r.referenceId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Completion workflow test'), findsOneWidget);
    await tester.tap(find.text('Awaiting Confirmation').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completion workflow test'));
    expect(opened, 'CV-WORKFLOW-TEST');
  });

  testWidgets('approve asks first, cancel preserves pending, confirm closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalReportProgressScreen(
          referenceId: 'CV-WORKFLOW-TEST',
          status: ReportStatus.pendingApproval,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve & Close'));
    await tester.pumpAndSettle();
    expect(find.text('Approve and close?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      MunicipalReportDirectory.instance.reports.value.single.status,
      ReportStatus.pendingApproval,
    );
    await tester.tap(find.text('Approve & Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve & Close').last);
    await tester.pumpAndSettle();
    expect(
      MunicipalReportDirectory.instance.reports.value.single.status,
      ReportStatus.resolved,
    );
    expect(find.text('Report Resolved Successfully'), findsOneWidget);
    expect(find.byIcon(AppIcons.more), findsNothing);
  });

  testWidgets('incomplete pending evidence cannot be approved', (tester) async {
    final json = fixture('PENDING_APPROVAL')
      ..['resolutionPhotoUrls'] = <String>[];
    MunicipalReportDirectory.instance.reports.value = [
      IncomingReportItem.fromApi(json),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalReportProgressScreen(
          referenceId: 'CV-WORKFLOW-TEST',
          status: ReportStatus.pendingApproval,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Approve & Close'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Send Back'), findsOneWidget);
  });

  testWidgets(
    'send back validates empty reason then shows the recorded outcome',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const MunicipalReportProgressScreen(
            referenceId: 'CV-WORKFLOW-TEST',
            status: ReportStatus.pendingApproval,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to Team'));
      await tester.pumpAndSettle();
      expect(find.text('Explain what needs to be corrected.'), findsOneWidget);
      expect(
        MunicipalReportDirectory.instance.reports.value.single.status,
        ReportStatus.pendingApproval,
      );
      await tester.enterText(find.byType(TextField), 'Fill the remaining gap.');
      await tester.tap(find.text('Return to Team'));
      await tester.pumpAndSettle();
      expect(find.text('Completion sent back'), findsOneWidget);
      expect(
        MunicipalReportDirectory.instance.reports.value.single.sendBackReason,
        'Fill the remaining gap.',
      );
    },
  );

  testWidgets(
    'pending detail and editor are readonly without an Update Progress action',
    (tester) async {
      final task = MaintenanceTask.fromApi(fixture('PENDING_APPROVAL'));
      MaintenanceTaskDirectory.instance.tasks.value = [task];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: TaskDetailsScreen(task: task),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Update Progress'), findsNothing);
      expect(find.text('Submitted for approval'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: UpdateProgressScreen(task: task),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save Update'),
      );
      expect(button.onPressed, isNull);
    },
  );

  for (final width in [320.0, 390.0, 412.0, 768.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'approval/pending screens fit ${width.toInt()} in ${dark ? 'dark' : 'light'}',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final priorErrorHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            debugPrint(details.toString());
            priorErrorHandler?.call(details);
          };
          addTearDown(() => FlutterError.onError = priorErrorHandler);
          final task = MaintenanceTask.fromApi(fixture('PENDING_APPROVAL'));
          for (final screen in <Widget>[
            const MunicipalReportProgressScreen(
              referenceId: 'CV-WORKFLOW-TEST',
              status: ReportStatus.pendingApproval,
            ),
            TaskDetailsScreen(task: task),
            TaskCompletedScreen(task: task, onNavigateToDashboard: () {}),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: screen,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: screen.runtimeType.toString(),
            );
            await tester.pumpWidget(const SizedBox.shrink());
          }
        },
      );
    }
  }

  testWidgets('native page loader is static when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const GhanaLoadingIndicator(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('Loading'), findsOneWidget);
  });
}

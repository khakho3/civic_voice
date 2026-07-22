import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/services/admin_maintenance_team_directory.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/task_details_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/main.dart' as app;

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  int _counter = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    _counter += 1;
    return XFile('test-maintenance-evidence-$_counter.jpg');
  }
}

/// Stands in for the real platform channel implementation, which never
/// resolves in a widget test (there's no host app registered to answer
/// it) rather than throwing — see the identical fake in
/// ministry_widget_test.dart for the full explanation.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  Uri? lastLaunchedUri;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUri = Uri.parse(url);
    return true;
  }
}

/// Snapshots the live `MaintenanceTaskDirectory` task list and restores it
/// after the test — for tests that write task status through the real
/// directory singleton, which otherwise leaks into every later test in
/// this file (e.g. the Notifications test's own "Pothole Repair Request
/// was just assigned" assertion depends on MNT-1002 still being
/// `assigned`).
void _preserveMaintenanceTaskDirectory() {
  final original = MaintenanceTaskDirectory.instance.tasks.value;
  addTearDown(() => MaintenanceTaskDirectory.instance.tasks.value = original);
}

Future<void> _attachThreeEvidencePhotos(WidgetTester tester) async {
  for (final label in ['Add 1', 'Add 2', 'Add 3']) {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    if (find.text('Allow Camera').evaluate().isNotEmpty) {
      await tester.tap(find.text('Allow Camera'));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  setUpAll(() {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();
  });

  testWidgets(
    'Maintenance task details explains an omitted description and previews report photos',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final task = MaintenanceTask.fromApi({
        'id': 'report-with-photo',
        'publicReference': 'CV-2026-PHOTO01',
        'title': 'Broken traffic light',
        'description': '',
        'location': 'Chantan Junction',
        'status': 'ASSIGNED',
        'photoUrls': <String>['http://example.invalid/report-photo.jpg'],
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TaskDetailsScreen(task: task),
        ),
      );
      await tester.pump();

      expect(
        find.text('No additional description was provided by the reporter.'),
        findsOneWidget,
      );
      expect(find.text('Report Photos (1)'), findsOneWidget);
      final thumbnail = find.byKey(
        const ValueKey(
          'maintenance-report-photo-http://example.invalid/report-photo.jpg',
        ),
      );
      expect(thumbnail, findsOneWidget);

      await tester.tap(thumbnail);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);
    },
  );

  testWidgets('Maintenance dashboard fits narrow phones without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const app.CivicVoiceApp(initialRoute: app.AppRoutes.maintenanceDashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Yaw'), findsOneWidget);
    expect(find.text('Weekly Completion'), findsOneWidget);
    expect(find.text('Scheduled Work'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Maintenance dashboard shows real stats and only open tasks in Scheduled '
    'Work',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // 5 mock tasks: 1 in progress, 2 assigned, 2 already completed.
      expect(find.text('Assigned Tasks'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // Assigned Tasks stat card.
      expect(find.text('Active Work'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Needs Rework'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // Needs Rework — none failed.

      // Only open tasks (not the two already-completed ones) show up here.
      expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);
      expect(find.text('Hydrant Maintenance'), findsNothing);
    },
  );

  testWidgets('Maintenance tasks page fits narrow phones without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const app.CivicVoiceApp(
        initialRoute: app.AppRoutes.maintenanceAssignedTasks,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);
    expect(find.text('View').first, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maintenance progress status rules require evidence and notes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const app.CivicVoiceApp(
        initialRoute: app.AppRoutes.maintenanceUpdateProgress,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Update'));
    await tester.tap(find.text('Save Update'));
    await tester.pumpAndSettle();

    // Shown twice by design — the inline field error plus a SnackBar, since
    // this form is long enough that the inline error can be scrolled
    // off-screen from where the Save button lives.
    expect(
      find.text(
        'Completion notes are required. Describe the work completed in at least 10 characters.',
      ),
      findsWidgets,
    );

    await tester.enterText(
      find.byType(EditableText).first,
      'Completed the required repair.',
    );
    await tester.ensureVisible(find.text('Save Update'));
    await tester.tap(find.text('Save Update'));
    await tester.pumpAndSettle();

    expect(find.text('Attach 3 photos to mark this completed.'), findsWidgets);

    await tester.enterText(find.byType(EditableText).first, '');
    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Update'));
    await tester.tap(find.text('Save Update'));
    await tester.pumpAndSettle();

    expect(
      find.text('Failure note must explain why the task failed.'),
      findsWidgets,
    );
  });

  testWidgets(
    'Maintenance Discard Draft asks for confirmation before clearing entered '
    'notes and evidence',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceUpdateProgress,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(EditableText).first,
        'Made real progress on this today.',
      );
      await tester.ensureVisible(find.text('Discard Draft'));
      await tester.tap(find.text('Discard Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Discard draft?'), findsOneWidget);

      // Cancel — the note survives.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Made real progress on this today.'), findsOneWidget);

      await tester.ensureVisible(find.text('Discard Draft'));
      await tester.tap(find.text('Discard Draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Made real progress on this today.'), findsNothing);
    },
  );

  testWidgets(
    'Maintenance Discard Draft skips the confirmation when there is nothing '
    'to lose',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceUpdateProgress,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Discard Draft'));
      await tester.tap(find.text('Discard Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Discard draft?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Maintenance tasks route to their own Task Details, not a shared static '
    'one',
    (WidgetTester tester) async {
      // Regression: every task in Assigned Tasks used to open the exact
      // same hardcoded "Broken Street Light"/"#TASK-8821" Task Details
      // screen regardless of which row was tapped. Confirms two different
      // tasks now open two different, correctly-identified records.
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceAssignedTasks,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Broken Street Light at Main Ave'));
      await tester.pumpAndSettle();

      expect(find.text('Broken Street Light at Main Ave'), findsWidgets);
      expect(find.text('#MNT-1001'), findsOneWidget);
      expect(find.text('242 Main Avenue, Central District'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pothole Repair Request'));
      await tester.pumpAndSettle();

      expect(find.text('Pothole Repair Request'), findsWidgets);
      expect(find.text('#MNT-1002'), findsOneWidget);
      expect(find.text('Elm Street & 4th Cross'), findsOneWidget);
      // Confirms this is genuinely a different record, not the first task's
      // data reused.
      expect(find.text('242 Main Avenue, Central District'), findsNothing);
    },
  );

  testWidgets('Maintenance routes connect dashboard, tasks, details, progress, '
      'completion, and profile — merged evidence flow, no separate Upload '
      'Evidence step', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const app.CivicVoiceApp(initialRoute: app.AppRoutes.maintenanceDashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Yaw'), findsOneWidget);
    expect(find.text('Scheduled Work'), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Search assigned tasks...'), findsOneWidget);
    expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);

    await tester.tap(find.text('Broken Street Light at Main Ave'));
    await tester.pumpAndSettle();

    expect(
      find.text('Problem Description', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Report Photos (2)'), findsOneWidget);
    expect(find.text('Problem Location'), findsOneWidget);
    expect(
      find.text('Assignment received by maintenance team'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('View Map'));
    await tester.tap(find.text('View Map'));
    await tester.pumpAndSettle();

    expect(find.text('Report Location'), findsOneWidget);
    expect(find.text('Read only'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Update Progress'));
    await tester.tap(find.text('Update Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Update Progress'), findsWidgets);
    expect(find.text('Work Notes'), findsOneWidget);
    expect(find.text('#MNT-1001'), findsWidgets);

    await tester.ensureVisible(find.text('Completed'));
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    await _attachThreeEvidencePhotos(tester);

    await tester.enterText(
      find.byType(EditableText).first,
      'Replaced the damaged wiring and verified the light is working.',
    );
    await tester.ensureVisible(find.text('Save Update'));
    await tester.tap(find.text('Save Update'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // No separate evidence-upload step — saving a Completed update lands
    // straight on Task Completed with the real task's own data.
    expect(find.text('Task Completed'), findsWidgets);
    expect(find.text('Task Summary'), findsOneWidget);
    expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);
    expect(
      find.text(
        'Replaced the damaged wiring and verified the light is working.',
      ),
      findsOneWidget,
    );
    expect(find.text('Go to Dashboard'), findsOneWidget);

    await tester.ensureVisible(find.text('Go to Dashboard'));
    await tester.tap(find.text('Go to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduled Work'), findsOneWidget);
    expect(find.text('Update Progress'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const app.CivicVoiceApp(initialRoute: app.AppRoutes.maintenanceProfile),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    // Matches both the header's name display and the now-editable Full
    // Name field's current value — the real Admin-provisioned account
    // (Yaw Asare, MNT-000004) this screen now reads from.
    expect(find.text('Yaw Asare'), findsNWidgets(2));
  });

  testWidgets(
    'Maintenance a task marked Completed updates Dashboard and Assigned '
    'Tasks immediately',
    (WidgetTester tester) async {
      // Regression: the four MNT screens used to each carry their own
      // disconnected mock task list, so completing a task anywhere never
      // moved that task off Dashboard's "Scheduled Work" or Assigned
      // Tasks' queue.
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _preserveMaintenanceTaskDirectory();

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceAssignedTasks,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pothole Repair Request'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Update Progress'));
      await tester.tap(find.text('Update Progress'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Completed'));
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      await _attachThreeEvidencePhotos(tester);

      await tester.enterText(
        find.byType(EditableText).first,
        'Pothole filled and surface leveled.',
      );
      await tester.ensureVisible(find.text('Save Update'));
      await tester.tap(find.text('Save Update'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Task Completed'), findsWidgets);

      // Task Completed is a drill-down with no bottom nav of its own —
      // jump directly to Dashboard/Tasks to confirm MaintenanceTaskDirectory
      // (a process-wide singleton) reflects the update everywhere, not just
      // on the screen that wrote it.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pothole Repair Request'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceAssignedTasks,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pothole Repair Request'), findsNothing);
    },
  );

  testWidgets(
    'Maintenance Profile header profile avatar and bottom nav both use the '
    'no-filled-pill active style shared with every other module',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Maintenance Task Details Open in Maps launches a maps app for the '
    "task's location",
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final original = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.maintenanceTaskDetails,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Open in Maps'));
      await tester.tap(find.text('Open in Maps'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(fake.lastLaunchedUri, isNotNull);
    },
  );

  testWidgets('Maintenance Update Progress blocks evidence submission when the '
      'signed-in technician is not the team lead', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Team-lead gating: swap the lead away from the signed-in account
    // (Yaw Asare) so this exercises the "not the lead" branch, then
    // restore it — other tests in this file rely on Yaw Asare being the
    // lead of the one mock team.
    final team = MaintenanceTeamDirectory.instance.teamById('TEAM-0001')!;
    MaintenanceTeamDirectory.instance.updateTeam(
      team.copyWith(leadUserId: 'MNT-000010'),
    );
    addTearDown(
      () => MaintenanceTeamDirectory.instance.updateTeam(
        team.copyWith(leadUserId: 'MNT-000004'),
      ),
    );

    await tester.pumpWidget(
      const app.CivicVoiceApp(
        initialRoute: app.AppRoutes.maintenanceUpdateProgress,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Completed'));
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Only Kojo Mensah-Boateng can submit'),
      findsOneWidget,
    );
    expect(find.text('Add 1'), findsNothing);
  });

  testWidgets(
    'Maintenance Profile has a real Edit toggle — Save/Cancel only appear '
    'once editing, and Cancel discards changes',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.maintenanceProfile),
      );
      await tester.pumpAndSettle();

      // Read-only by default — no Save/Cancel sitting around with nothing
      // to enter edit mode through.
      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      expect(find.byIcon(AppIcons.edit), findsOneWidget);
      expect(find.text('System Preferences'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Session'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.edit));
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // The Edit affordance itself is gone while already editing.
      expect(find.byIcon(AppIcons.edit), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Someone Else');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Matches both the header's name display and the read-only Full Name
      // field — the original name, not the discarded edit.
      expect(find.text('Yaw Asare'), findsNWidgets(2));
      expect(find.text('Someone Else'), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
    },
  );

  testWidgets('Maintenance Notifications shows new task assignments for the '
      "technician's own team and marks them read on open", (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _preserveMaintenanceTaskDirectory();
    MaintenanceTaskDirectory.instance.tasks.value = mockMaintenanceTasks();

    await tester.pumpWidget(
      const app.CivicVoiceApp(
        initialRoute: app.AppRoutes.maintenanceNotifications,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New task assigned'), findsWidgets);
    expect(
      find.text('Pothole Repair Request was assigned to your team.'),
      findsOneWidget,
    );
    expect(find.text('Team task in progress'), findsWidgets);
    expect(find.text('Team task completed'), findsWidgets);
  });
}

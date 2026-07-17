import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

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

void main() {
  setUpAll(() {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();
  });

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

    expect(find.text('Good Morning, Marcus'), findsOneWidget);
    expect(find.text('Weekly Completion'), findsOneWidget);
    expect(find.text('Scheduled Work'), findsOneWidget);
  });

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
    expect(find.text('View Task Details').first, findsOneWidget);
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

    expect(
      find.text('Attach 3 photos to mark this completed.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Update'));
    await tester.tap(find.text('Save Update'));
    await tester.pumpAndSettle();

    expect(
      find.text('Failure note must explain why the task failed.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Maintenance routes connect dashboard, tasks, details, progress, evidence, '
    'completion, and profile',
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

      expect(find.text('Good Morning, Marcus'), findsOneWidget);
      expect(find.text('Scheduled Work'), findsOneWidget);

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Search assigned tasks...'), findsOneWidget);
      expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);

      await tester.tap(find.text('View Task Details').first);
      await tester.pumpAndSettle();

      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Broken Street Light'), findsOneWidget);
      expect(find.text('Problem Description'), findsOneWidget);
      expect(find.text('Report Photos'), findsOneWidget);
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

      expect(find.text('Update Task Progress'), findsOneWidget);
      expect(find.text('Work Notes'), findsOneWidget);

      await tester.ensureVisible(find.text('Completed'));
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      for (final label in ['Add 1', 'Add 2', 'Add 3']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        if (find.text('Allow Camera').evaluate().isNotEmpty) {
          await tester.tap(find.text('Allow Camera'));
          await tester.pumpAndSettle();
        }
      }

      await tester.enterText(
        find.byType(EditableText).first,
        'Replaced the damaged wiring and verified the light is working.',
      );
      await tester.ensureVisible(find.text('Save Update'));
      await tester.tap(find.text('Save Update'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Resolution Evidence'), findsOneWidget);
      expect(find.text('Submit Resolution'), findsOneWidget);

      await tester.ensureVisible(find.text('Submit Resolution'));
      await tester.tap(find.text('Submit Resolution'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Task Completed'), findsOneWidget);
      expect(find.text('Task Summary'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.maintenanceProfile),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      // Matches both the header's name display and the now-editable Full
      // Name field's current value.
      expect(find.text('Marcus Johnson'), findsNWidgets(2));
    },
  );
}

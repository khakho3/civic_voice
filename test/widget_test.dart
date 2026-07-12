import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/municipal/models/active_report.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/screens/municipal_active_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_assign_team_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_inbox_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_progress_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_review_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_verification_screen.dart';

void main() {
  testWidgets('Municipal Dashboard renders its loaded state', (
    WidgetTester tester,
  ) async {
    // Tall surface so the Dashboard's scrollable content renders in full —
    // ListView only builds what's within the viewport.
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Explicit loaded state — independent of whatever initialState main.dart
    // happens to be set to for manual preview of other states.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalDashboardScreen(
          initialState: MunicipalDashboardViewState.loaded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CivicVoice'), findsOneWidget);
    expect(find.text('Recent Reports'), findsOneWidget);
    expect(find.text('Assignment Summary'), findsOneWidget);
  });

  for (final state in MunicipalInboxViewState.values) {
    testWidgets('Municipal Inbox renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalInboxScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Municipal Inbox search filters the list down to No-Results', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalInboxScreen(
          initialState: MunicipalInboxViewState.loaded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Traffic Light Malfunction'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Pothole on Main St',
    );
    await tester.pumpAndSettle();

    expect(find.text('Traffic Light Malfunction'), findsNothing);
    expect(find.text('No reports match your filters'), findsOneWidget);

    await tester.tap(find.text('Clear all filters'));
    await tester.pumpAndSettle();

    expect(find.text('Traffic Light Malfunction'), findsOneWidget);
  });

  testWidgets(
    'Municipal Inbox No-Results does not overflow with the keyboard open, '
    'and hides the bottom nav while it is',
    (WidgetTester tester) async {
      // A realistic phone height (not the artificially tall surface the
      // other tests use) so a keyboard inset actually squeezes the layout —
      // this is what caught the real-device overflow.
      tester.view.physicalSize = const Size(428, 926);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalInboxScreen(
            initialState: MunicipalInboxViewState.noResults,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate the on-screen keyboard opening (a realistic height, roughly
      // matching what actually happened on-device).
      tester.view.viewInsets = const FakeViewPadding(bottom: 340);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('No reports match your filters'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Inbox survives typing character-by-character with the '
    'keyboard open, crossing into and back out of No-Results',
    (WidgetTester tester) async {
      // Reproduces the real-device crash report exactly: realistic phone
      // size, keyboard already open, typing one character at a time (not
      // setting the whole string in one enterText call) as the filtered
      // list transitions from results -> no-results -> results again.
      tester.view.physicalSize = const Size(428, 926);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalInboxScreen(
            initialState: MunicipalInboxViewState.loaded,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 340);
      await tester.pumpAndSettle();

      // "trafi" is deliberately not a substring of "Traffic Light
      // Malfunction" (double f) — matches results until the last keystroke,
      // then crosses into No-Results, exactly like the bug report.
      var typed = '';
      for (final char in 'trafi'.split('')) {
        typed += char;
        await tester.enterText(find.byType(TextField), typed);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'after typing "$typed"');
      }

      expect(find.text('No reports match your filters'), findsOneWidget);

      // And back out, character by character, returning to real results.
      while (typed.isNotEmpty) {
        typed = typed.substring(0, typed.length - 1);
        await tester.enterText(find.byType(TextField), typed);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'after deleting back to "$typed"',
        );
      }

      expect(find.text('Traffic Light Malfunction'), findsOneWidget);
    },
  );

  for (final state in MunicipalReportReviewViewState.values) {
    testWidgets('Municipal Report Review renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalReportReviewScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Municipal Report Review shows the full report in its loaded state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalReportReviewScreen(
          initialState: MunicipalReportReviewViewState.loaded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report Review'), findsOneWidget);
    expect(find.text('#REQ-8421'), findsOneWidget);
    expect(find.text('John Smith'), findsOneWidget);
    expect(find.text('Pothole on Main St.'), findsOneWidget);
    expect(find.text('Evidence (2)'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Verify Report'), findsOneWidget);
  });

  testWidgets(
    'Municipal Report Review No-Evidence shows the inline empty state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalReportReviewScreen(
            initialState: MunicipalReportReviewViewState.noEvidence,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evidence (0)'), findsOneWidget);
      expect(find.text('No photos attached'), findsOneWidget);
    },
  );

  testWidgets('Tapping an Incoming Report navigates to Report Review', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    IncomingReportItem? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MunicipalInboxScreen(
          initialState: MunicipalInboxViewState.loaded,
          onReportTap: (report) => tapped = report,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Traffic Light Malfunction'));
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(tapped!.title, 'Traffic Light Malfunction');
  });

  for (final state in MunicipalVerificationViewState.values) {
    testWidgets('Municipal Verification renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalVerificationScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Municipal Verification only enables Verify Report once every '
    'checklist item is confirmed',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      Widget verifyButton() => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Verify Report'),
          matching: find.byType(FilledButton),
        ),
      );

      expect((verifyButton() as FilledButton).onPressed, isNull);

      for (final label in [
        'Issue confirmed',
        'Photos reviewed',
        'Location validated',
        'Not duplicate',
        'Citizen contacted',
      ]) {
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect((verifyButton() as FilledButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Municipal Verification quick-reason chip fills the rejection reason '
    'field',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MunicipalVerificationScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicate Report'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Duplicate Report');
    },
  );

  testWidgets(
    'Municipal Verification Rejected message does not claim a reason was '
    'given when the Optional field was left empty',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MunicipalVerificationScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reject Report'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('The citizen has been notified of the rejection.'), findsOneWidget);
      expect(
        find.text('The citizen has been notified with the provided reason.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Municipal Verification Rejected message confirms the reason when one '
    'was actually provided',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MunicipalVerificationScreen()),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Not a real pothole.');
      await tester.tap(find.text('Reject Report'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(
        find.text('The citizen has been notified with the provided reason.'),
        findsOneWidget,
      );
    },
  );

  for (final state in MunicipalAssignTeamViewState.values) {
    testWidgets('Municipal Assign Team renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalAssignTeamScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Municipal Assign Team shows the report and every team in its loaded state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalAssignTeamScreen(
          initialState: MunicipalAssignTeamViewState.loaded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#REQ-8421'), findsOneWidget);
    expect(find.text('Severe Pothole on Main St.'), findsOneWidget);
    expect(find.text('Unit Alpha'), findsOneWidget);
    expect(find.text('Unit Bravo'), findsOneWidget);
    expect(find.text('Unit Charlie'), findsOneWidget);
    expect(find.text('Unit Delta'), findsOneWidget);
    // Unit Alpha is pre-selected, matching every approved reference frame.
    expect(
      find.text('Unit Alpha will be dispatched to this location — '
          'estimated arrival in 12 min.'),
      findsOneWidget,
    );
  });

  testWidgets('Municipal Assign Team "Available" filter hides busy and off-duty teams', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalAssignTeamScreen()),
    );
    await tester.pumpAndSettle();

    // 'Available' also appears as the availability badge on Alpha/Bravo's
    // team cards further down — the filter chip is the first match, since
    // the filter row renders above the team list.
    await tester.tap(find.text('Available').first);
    await tester.pumpAndSettle();

    expect(find.text('Unit Alpha'), findsOneWidget);
    expect(find.text('Unit Bravo'), findsOneWidget);
    expect(find.text('Unit Charlie'), findsNothing);
    expect(find.text('Unit Delta'), findsNothing);
  });

  testWidgets('Municipal Assign Team search narrows the team list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalAssignTeamScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bravo');
    await tester.pumpAndSettle();

    expect(find.text('Unit Alpha'), findsNothing);
    expect(find.text('Unit Bravo'), findsOneWidget);
    expect(find.text('Unit Charlie'), findsNothing);
    expect(find.text('Unit Delta'), findsNothing);
  });

  testWidgets('Municipal Assign Team tapping a team selects it, and off-duty teams cannot be selected', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalAssignTeamScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unit Bravo'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Unit Bravo will be dispatched'),
      findsOneWidget,
    );

    // Unit Delta is off-duty — tapping it must not change the selection.
    await tester.tap(find.text('Unit Delta'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Unit Bravo will be dispatched'),
      findsOneWidget,
    );
    expect(find.textContaining('Unit Delta will be dispatched'), findsNothing);
  });

  testWidgets('Municipal Assign Team submitting reaches the Team Assigned confirmation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalAssignTeamScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(
        of: find.text('Assign Team'),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('Team Assigned'), findsOneWidget);
    expect(
      find.text('Unit Alpha has been notified and will begin work shortly.'),
      findsOneWidget,
    );
  });

  for (final state in MunicipalActiveReportsViewState.values) {
    testWidgets('Municipal Active Reports renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalActiveReportsScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Municipal Active Reports shows every report in its loaded state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalActiveReportsScreen(
          initialState: MunicipalActiveReportsViewState.loaded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOWNTOWN ZONE'), findsOneWidget);
    expect(find.text('Severe Pothole on Main St.'), findsOneWidget);
    expect(find.text('Broken Streetlight'), findsOneWidget);
    expect(find.text('Overflowing Trash Bin'), findsOneWidget);
    expect(find.text('Water Leak Near Curb'), findsOneWidget);
    expect(find.text('Sidewalk Crack'), findsOneWidget);
    expect(find.text('5 reports'), findsOneWidget);
  });

  testWidgets('Municipal Active Reports "In Progress" filter hides assigned and resolved reports', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalActiveReportsScreen()),
    );
    await tester.pumpAndSettle();

    // 'In Progress' also appears as the status badge on matching report
    // cards further down — the filter chip is the first match, since the
    // filter row renders above the report list.
    await tester.tap(find.text('In Progress').first);
    await tester.pumpAndSettle();

    expect(find.text('Severe Pothole on Main St.'), findsOneWidget);
    expect(find.text('Overflowing Trash Bin'), findsOneWidget);
    expect(find.text('Broken Streetlight'), findsNothing);
    expect(find.text('Water Leak Near Curb'), findsNothing);
    expect(find.text('Sidewalk Crack'), findsNothing);
  });

  testWidgets('Municipal Active Reports search narrows the report list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalActiveReportsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Cedar');
    await tester.pumpAndSettle();

    expect(find.text('Water Leak Near Curb'), findsOneWidget);
    expect(find.text('Severe Pothole on Main St.'), findsNothing);
    expect(find.text('Broken Streetlight'), findsNothing);
    expect(find.text('Overflowing Trash Bin'), findsNothing);
    expect(find.text('Sidewalk Crack'), findsNothing);
  });

  testWidgets('Tapping an Active Report fires onReportTap with that report', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ActiveReportItem? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MunicipalActiveReportsScreen(
          initialState: MunicipalActiveReportsViewState.loaded,
          onReportTap: (report) => tapped = report,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Severe Pothole on Main St.'));
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(tapped!.referenceId, 'REQ-8421');
  });

  testWidgets('Municipal Active Reports sort menu reorders the list by lowest progress', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalActiveReportsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest Progress'));
    await tester.pumpAndSettle();

    // Water Leak Near Curb (10%) should now sort above Sidewalk Crack
    // (100%) — confirms the sort actually reordered the list rather than
    // being a decorative no-op menu.
    final waterLeakY = tester.getTopLeft(find.text('Water Leak Near Curb')).dy;
    final sidewalkY = tester.getTopLeft(find.text('Sidewalk Crack')).dy;
    expect(waterLeakY, lessThan(sidewalkY));
  });

  testWidgets(
    'Municipal Active Reports is a tab-shell screen: bottom nav stays visible '
    'and switches to Dashboard/Inbox',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var dashboardTapped = false;
      var inboxTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalActiveReportsScreen(
            onNavigateToDashboard: () => dashboardTapped = true,
            onNavigateToInbox: () => inboxTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The bottom nav — not a back arrow — is how this screen is reached
      // and left, matching every other list screen in the module.
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(AppIcons.back), findsNothing);

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      expect(inboxTapped, isTrue);
      expect(dashboardTapped, isFalse);

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);
    },
  );

  for (final state in MunicipalReportProgressViewState.values) {
    testWidgets('Municipal Report Progress renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalReportProgressScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Municipal Report Progress shows the full report in its loaded state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalReportProgressScreen(
          initialState: MunicipalReportProgressViewState.loaded,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#REQ-8421'), findsOneWidget);
    expect(find.text('Main St. Pothole Repair'), findsOneWidget);
    expect(find.text('North District, Zone 4'), findsOneWidget);
    expect(find.text('Officer J. Sterling'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('Unit Alpha'), findsOneWidget);

    final markResolved = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Mark Resolved'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(markResolved.onPressed, isNotNull);
  });

  testWidgets(
    'Municipal Report Progress Missing Evidence disables Mark Resolved '
    'until a photo is added',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalReportProgressScreen(
            initialState: MunicipalReportProgressViewState.missingEvidence,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evidence Required'), findsOneWidget);
      expect(find.text('0 Photos'), findsOneWidget);
      final disabled = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Mark Resolved (Upload Required)'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(disabled.onPressed, isNull);

      await tester.tap(find.text('Add Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Mark Resolved'), findsOneWidget);
      final enabled = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Mark Resolved'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(enabled.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Municipal Report Progress Mark Resolved reaches the resolved '
    'confirmation with the correct case summary',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalReportProgressScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.ancestor(
          of: find.text('Mark Resolved'),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('Report Resolved Successfully'), findsOneWidget);
      // Regression check: the approved frame's case-recap card showed an
      // unrelated case (a different reference ID and title) rather than
      // the report that was actually just resolved.
      expect(find.text('CASE REQ-8421'), findsOneWidget);
      expect(find.text('Main St. Pothole Repair'), findsOneWidget);
      expect(find.text('Street Light Outage — Main St & 4th'), findsNothing);
    },
  );

  testWidgets(
    'Municipal Report Progress Offline stays fully interactive (non-blocking, '
    'unlike other screens\' offline states)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalReportProgressScreen(
            initialState: MunicipalReportProgressViewState.offline,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline Mode'), findsOneWidget);
      expect(find.text('Sync Pending'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);

      final markResolved = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Mark Resolved'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(markResolved.onPressed, isNotNull);
    },
  );

  testWidgets('Municipal Report Progress kebab menu offers Share Summary', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalReportProgressScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.more));
    await tester.pumpAndSettle();

    expect(find.text('Share Summary'), findsOneWidget);
  });
}

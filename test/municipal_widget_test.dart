import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/municipal/models/active_report.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/models/resolved_report.dart';
import 'package:civic_voice/features/municipal/screens/municipal_active_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_assign_team_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_inbox_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_profile_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_progress_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_report_review_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolution_details_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolved_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_verification_screen.dart';
import 'package:civic_voice/widgets/collapsible_list_header.dart';

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

  testWidgets(
    'Municipal Dashboard municipality card reads as assigned, not a picker '
    'the officer can open',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalDashboardScreen(
            initialState: MunicipalDashboardViewState.loaded,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MUNICIPALITY'), findsOneWidget);
      expect(find.text('Assigned by your administrator'), findsOneWidget);
      // A chevron-down is the "tap to open a picker" affordance — it must
      // not be present now that officers can't self-select a municipality.
      expect(find.byIcon(AppIcons.chevronDown), findsNothing);
    },
  );

  testWidgets(
    'Municipal routes connect dashboard, inbox, review, verification, active, '
    'resolved, details, and profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> advanceRoute() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.municipalDashboard),
      );
      await advanceRoute();

      expect(find.text('Recent Reports'), findsOneWidget);

      await tester.tap(find.text('Inbox'));
      await advanceRoute();

      expect(find.text('Incoming Reports'), findsOneWidget);

      await tester.tap(find.text('Traffic Light Malfunction'));
      await advanceRoute();

      expect(find.text('Report Review'), findsOneWidget);

      await tester.tap(find.text('Verify Report'));
      await advanceRoute();

      expect(find.text('Verify Report'), findsWidgets);

      await tester.tap(find.byIcon(AppIcons.back));
      await advanceRoute();

      expect(find.text('Report Review'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.back));
      await advanceRoute();

      expect(find.text('Incoming Reports'), findsOneWidget);

      await tester.tap(find.text('Active'));
      await advanceRoute();

      expect(find.text('Active Reports'), findsOneWidget);

      await tester.tap(find.text('Severe Pothole on Main St.'));
      await advanceRoute();

      expect(find.text('Report Progress'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.back));
      await advanceRoute();

      expect(find.text('Active Reports'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.statusResolved).last);
      await advanceRoute();

      expect(find.text('Resolved Reports'), findsOneWidget);

      final resolvedReport = find.textContaining('Streetlight Outage');
      await tester.ensureVisible(resolvedReport);
      await tester.tap(resolvedReport);
      await advanceRoute();

      expect(find.text('Resolution Details'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.back));
      await advanceRoute();

      expect(find.text('Resolved Reports'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.profile));
      await advanceRoute();

      expect(find.text('Municipal Profile'), findsOneWidget);
    },
  );

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

    await tester.enterText(find.byType(TextField), 'Pothole on Main St');
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
      expect(find.text('Home'), findsNothing);
      expect(find.text('No reports match your filters'), findsOneWidget);
    },
  );

  testWidgets('Municipal Inbox survives typing character-by-character with the '
      'keyboard open, crossing into and back out of No-Results', (
    WidgetTester tester,
  ) async {
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
  });

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

  testWidgets(
    'Municipal Report Review shows the full report in its loaded state',
    (WidgetTester tester) async {
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
    },
  );

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

  testWidgets('Municipal Verification only enables Verify Report once every '
      'checklist item is confirmed', (WidgetTester tester) async {
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
  });

  testWidgets(
    'Municipal Verification quick-reason chip fills the rejection reason '
    'field',
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
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reject Report'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(
        find.text('The citizen has been notified of the rejection.'),
        findsOneWidget,
      );
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
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Not a real pothole.');
      await tester.tap(find.text('Reject Report'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(
        find.text('The citizen has been notified with the provided reason.'),
        findsOneWidget,
      );
      // Regression check: the header status badge is a fixed widget.status
      // prop, not derived from _state — without tracking it explicitly it
      // would keep showing "Submitted" even after the report's rejected.
      expect(find.text('Submitted'), findsNothing);
      expect(find.text('Rejected'), findsOneWidget);
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

  testWidgets(
    'Municipal Assign Team shows the report and every team in its loaded state',
    (WidgetTester tester) async {
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
        find.text(
          'Unit Alpha will be dispatched to this location — '
          'estimated arrival in 12 min.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Municipal Assign Team "Available" filter hides busy and off-duty teams',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalAssignTeamScreen(),
        ),
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
    },
  );

  testWidgets('Municipal Assign Team search narrows the team list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalAssignTeamScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bravo');
    await tester.pumpAndSettle();

    expect(find.text('Unit Alpha'), findsNothing);
    expect(find.text('Unit Bravo'), findsOneWidget);
    expect(find.text('Unit Charlie'), findsNothing);
    expect(find.text('Unit Delta'), findsNothing);
  });

  testWidgets(
    'Municipal Assign Team tapping a team selects it, and off-duty teams cannot be selected',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalAssignTeamScreen(),
        ),
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
      expect(
        find.textContaining('Unit Delta will be dispatched'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Municipal Assign Team submitting reaches the Team Assigned confirmation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalAssignTeamScreen(),
        ),
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
      // Regression check: the header status badge is a fixed widget.status
      // prop, not derived from _state — without tracking it explicitly it
      // would keep showing "Under Review" even after a team's been assigned.
      expect(find.text('Under Review'), findsNothing);
      expect(find.text('Assigned'), findsOneWidget);
    },
  );

  for (final state in MunicipalActiveReportsViewState.values) {
    testWidgets(
      'Municipal Active Reports renders ${state.name} without error',
      (WidgetTester tester) async {
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
      },
    );
  }

  testWidgets(
    'Municipal Active Reports shows every report in its loaded state',
    (WidgetTester tester) async {
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

      expect(find.text('Active Reports'), findsOneWidget);
      expect(find.text('Severe Pothole on Main St.'), findsOneWidget);
      expect(find.text('Broken Streetlight'), findsOneWidget);
      expect(find.text('Overflowing Trash Bin'), findsOneWidget);
      expect(find.text('Water Leak Near Curb'), findsOneWidget);
      expect(find.text('Sidewalk Crack'), findsOneWidget);
      expect(find.text('5 reports'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Active Reports "In Progress" filter hides assigned and resolved reports',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalActiveReportsScreen(),
        ),
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
    },
  );

  testWidgets('Municipal Active Reports search narrows the report list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalActiveReportsScreen(),
      ),
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

  testWidgets(
    'Municipal Active Reports sort menu reorders the list by lowest progress',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalActiveReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lowest Progress'));
      await tester.pumpAndSettle();

      // Water Leak Near Curb (10%) should now sort above Sidewalk Crack
      // (100%) — confirms the sort actually reordered the list rather than
      // being a decorative no-op menu.
      final waterLeakY = tester
          .getTopLeft(find.text('Water Leak Near Curb'))
          .dy;
      final sidewalkY = tester.getTopLeft(find.text('Sidewalk Crack')).dy;
      expect(waterLeakY, lessThan(sidewalkY));
    },
  );

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
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(AppIcons.back), findsNothing);

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      expect(inboxTapped, isTrue);
      expect(dashboardTapped, isFalse);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);
    },
  );

  for (final state in MunicipalReportProgressViewState.values) {
    testWidgets(
      'Municipal Report Progress renders ${state.name} without error',
      (WidgetTester tester) async {
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
      },
    );
  }

  testWidgets(
    'Municipal Report Progress shows the full report in its loaded state',
    (WidgetTester tester) async {
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
    },
  );

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

  testWidgets('Municipal Report Progress Mark Resolved reaches the resolved '
      'confirmation with the correct case summary', (
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
    // Regression check: the header status badge is a fixed widget.status
    // prop, not derived from _state — without tracking it explicitly it
    // would keep showing "In Progress" even after the report's resolved.
    expect(find.text('In Progress'), findsNothing);
    expect(find.text('Resolved'), findsWidgets);
  });

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

  for (final state in MunicipalResolvedReportsViewState.values) {
    testWidgets(
      'Municipal Resolved Reports renders ${state.name} without error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(428, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MunicipalResolvedReportsScreen(initialState: state),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Municipal Resolved Reports shows stats and every report in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalResolvedReportsScreen(
            initialState: MunicipalResolvedReportsViewState.loaded,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resolved Reports'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('Streetlight Outage — 4th Ave'), findsOneWidget);
      expect(find.text('Pothole Cluster — Elm Rd'), findsOneWidget);
      expect(find.text('Graffiti Removal — Bridge'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Resolved Reports "Public Works" filter hides other departments',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalResolvedReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 'Public Works' also appears as the department line on matching report
      // cards further down — the filter chip is the first match, since the
      // filter row renders above the report list. It's the last chip in a
      // horizontally-scrolling row, so it needs scrolling into view before
      // it can be tapped.
      final publicWorksChip = find.text('Public Works').first;
      await tester.ensureVisible(publicWorksChip);
      await tester.pumpAndSettle();
      await tester.tap(publicWorksChip);
      await tester.pumpAndSettle();

      expect(find.text('Streetlight Outage — 4th Ave'), findsOneWidget);
      expect(find.text('Graffiti Removal — Bridge'), findsOneWidget);
      expect(find.text('Pothole Cluster — Elm Rd'), findsNothing);
    },
  );

  testWidgets('Municipal Resolved Reports search narrows the report list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MunicipalResolvedReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Elm');
    await tester.pumpAndSettle();

    expect(find.text('Pothole Cluster — Elm Rd'), findsOneWidget);
    expect(find.text('Streetlight Outage — 4th Ave'), findsNothing);
    expect(find.text('Graffiti Removal — Bridge'), findsNothing);
  });

  testWidgets('Tapping a Resolved Report fires onReportTap with that report', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ResolvedReportItem? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MunicipalResolvedReportsScreen(
          initialState: MunicipalResolvedReportsViewState.loaded,
          onReportTap: (report) => tapped = report,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Streetlight Outage — 4th Ave'));
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(tapped!.referenceId, 'REQ-8355');
  });

  testWidgets(
    'Municipal Resolved Reports is a tab-shell screen: bottom nav stays visible '
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
          home: MunicipalResolvedReportsScreen(
            onNavigateToDashboard: () => dashboardTapped = true,
            onNavigateToInbox: () => inboxTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      // 'Resolved' text also appears on every report card's status badge —
      // check the nav item's icon instead, which is distinct from the
      // badge's icon (statusResolved vs success).
      expect(find.byIcon(AppIcons.statusResolved), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(AppIcons.back), findsNothing);

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      expect(inboxTapped, isTrue);
      expect(dashboardTapped, isFalse);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);
    },
  );

  for (final state in MunicipalResolutionDetailsViewState.values) {
    testWidgets(
      'Municipal Resolution Details renders ${state.name} without error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(428, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MunicipalResolutionDetailsScreen(initialState: state),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Municipal Resolution Details shows the full record in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalResolutionDetailsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resolution Details'), findsOneWidget);
      expect(find.text('#REQ-8355'), findsOneWidget);
      expect(find.text('Streetlight Outage — 4th Ave'), findsOneWidget);
      expect(find.text('Verified Evidence'), findsOneWidget);
      expect(find.text('Resolution Timeline'), findsOneWidget);
      expect(find.text('Share Summary'), findsOneWidget);
      expect(find.text('Archive Report'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Inbox search field collapses on scroll-down and reappears on scroll-up',
    (WidgetTester tester) async {
      // A realistic phone height (not the extra-tall size used elsewhere to
      // avoid clipping) so the list actually overflows and can be scrolled.
      tester.view.physicalSize = const Size(428, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MunicipalInboxScreen()),
      );
      await tester.pumpAndSettle();

      // The header's own box shrinks to heightFactor 0 when collapsed; a
      // descendant like TextField keeps its natural layout size regardless
      // (Align doesn't constrain its child), so measure the keyed wrapper.
      final headerFinder = find.byKey(const ValueKey('collapsible_header'));
      final expandedHeight = tester.getSize(headerFinder).height;
      expect(expandedHeight, greaterThan(0));

      // Drag on the report list itself (not a specific card's text, which
      // can scroll off-screen and fail the drag's hit test) to scroll down.
      final listFinder = find.byType(ListView).last;
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getSize(headerFinder).height, lessThan(1));

      await tester.drag(listFinder, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(headerFinder).height,
        greaterThan(expandedHeight / 2),
      );
    },
  );

  testWidgets(
    'Municipal Active Reports search field collapses on scroll-down and reappears on scroll-up',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalActiveReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(const ValueKey('collapsible_header'));
      final expandedHeight = tester.getSize(headerFinder).height;

      final listFinder = find.byType(ListView).last;
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getSize(headerFinder).height, lessThan(1));

      await tester.drag(listFinder, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(headerFinder).height,
        greaterThan(expandedHeight / 2),
      );
    },
  );

  testWidgets(
    'Municipal Resolved Reports search field collapses on scroll-down and '
    'reappears on scroll-up, while the stats row scrolls as ordinary '
    'content',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalResolvedReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(const ValueKey('collapsible_header'));
      final searchExpandedHeight = tester.getSize(headerFinder).height;
      expect(searchExpandedHeight, greaterThan(0));
      // The stats row is regular scrolling content now, not collapsible
      // chrome — it's always in the tree regardless of header state.
      // ("Resolved" also labels each card's own status badge, hence
      // findsWidgets rather than findsOneWidget.)
      expect(find.text('Resolved'), findsWidgets);

      final listFinder = find.byType(ListView).last;
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getSize(headerFinder).height, lessThan(1));
      expect(find.text('Resolved'), findsWidgets);

      await tester.drag(listFinder, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(headerFinder).height,
        greaterThan(searchExpandedHeight / 2),
      );
    },
  );

  testWidgets(
    'CollapsibleListHeader: header reveals immediately on any upward '
    'scroll, not just once the list is back at the top',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CollapsibleListHeader(
              header: const SizedBox(height: 60, child: Text('header')),
              child: ListView.builder(
                itemCount: 30,
                itemBuilder: (context, index) =>
                    SizedBox(height: 60, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(const ValueKey('collapsible_header'));
      final listFinder = find.byType(ListView);
      final expandedHeight = tester.getSize(headerFinder).height;
      expect(expandedHeight, greaterThan(0));

      // Scroll down well past the very top: header hides.
      await tester.drag(listFinder, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getSize(headerFinder).height, lessThan(1));

      // A small upward scroll, nowhere near the top, still brings it back
      // — no 50%-of-header or "reached the top" threshold to clear first.
      await tester.drag(listFinder, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(headerFinder).height,
        greaterThan(expandedHeight / 2),
      );
    },
  );

  testWidgets(
    'CollapsibleListHeader: chrome can still be pulled back when collapsing '
    'it left the list with nothing to scroll',
    (WidgetTester tester) async {
      // Regression: on Resolved Reports (3 cards), hiding the search bar
      // freed enough room that the whole list fit its viewport —
      // maxScrollExtent hit 0, pixels got clamped to 0, and with default
      // clamping physics the list stopped accepting drags entirely, so no
      // gesture could ever bring the chrome back. Content here is sized to
      // reproduce exactly that: it overflows while the chrome is expanded,
      // but fits once the chrome is hidden.
      tester.view.physicalSize = const Size(428, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CollapsibleListHeader(
              header: const SizedBox(height: 60, child: Text('header')),
              child: ListView.builder(
                // Mirrors the screens' lists — without this, the list
                // rejects drags outright once its content fits.
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 8,
                itemBuilder: (context, index) =>
                    SizedBox(height: 105, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(const ValueKey('collapsible_header'));
      final listFinder = find.byType(ListView);
      final headerExpandedHeight = tester.getSize(headerFinder).height;

      // Collapse the chrome; the freed space lets the list fit entirely.
      await tester.drag(listFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getSize(headerFinder).height, lessThan(1));

      // Pull back down: even with nothing left to scroll, the drag must
      // still bring the header back.
      await tester.drag(listFinder, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(headerFinder).height,
        greaterThan(headerExpandedHeight / 2),
      );
    },
  );

  testWidgets(
    'Municipal Dashboard header profile avatar opens Municipal Profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var profileTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalDashboardScreen(
            onProfileTap: () => profileTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.profile));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    },
  );

  for (final state in MunicipalProfileViewState.values) {
    testWidgets('Municipal Profile renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalProfileScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Municipal Profile shows the full account in its loaded state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MunicipalProfileScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Municipal Profile'), findsOneWidget);
    expect(find.text('ID MC-4092'), findsOneWidget);
    expect(find.text('Alex Johnston'), findsOneWidget);
    expect(find.text('Senior Municipal Coordinator'), findsOneWidget);
    expect(find.text('Verified Official'), findsOneWidget);
    expect(find.text('alex.johnston@city.gov'), findsOneWidget);
    expect(find.text('(555) 128-4092'), findsOneWidget);
    expect(find.text('Urban Planning & Dev'), findsOneWidget);
    expect(find.text('Director M. Chen'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Two-Factor Authentication'), findsOneWidget);
    expect(find.text('Login Sessions'), findsOneWidget);
  });

  testWidgets('Municipal Profile Change Password fires onChangePassword', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MunicipalProfileScreen(onChangePassword: () => tapped = true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets(
    'Municipal Profile Error state previews a blank Full Name validation '
    'failure',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalProfileScreen(
            initialState: MunicipalProfileViewState.error,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Email/Phone are locked (admin-set, not self-editable — see
      // [_ProfileEditForm]'s own doc comment), so Full Name is the only
      // field left that can fail validation.
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Full name is required'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Profile kebab menu Edit Profile opens the edit form with '
    'current values',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      // Matches both the header's name display and the Full Name field's
      // current value.
      expect(find.text('Alex Johnston'), findsNWidgets(2));
      expect(find.text('alex.johnston@city.gov'), findsOneWidget);
      expect(find.text('(555) 128-4092'), findsOneWidget);
      // Department is shown but locked, not part of the editable form.
      expect(find.text('Set by your administrator'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Profile kebab menu offers Settings alongside Edit Profile '
    'and Log Out',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var settingsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MunicipalProfileScreen(
            onSettingsTap: () => settingsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.more));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(settingsTapped, isTrue);
    },
  );

  testWidgets(
    'Municipal Profile Save fails validation on an empty Full Name, '
    'without leaving the edit form',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalProfileScreen(
            initialState: MunicipalProfileViewState.editing,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      // Still editing — a failed save must not silently drop the user back
      // to the read-only view.
      expect(find.text('Personal Information'), findsOneWidget);
    },
  );

  testWidgets(
    'Municipal Profile Save succeeds with valid data and shows the updated '
    'name back in the read-only view',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalProfileScreen(
            initialState: MunicipalProfileViewState.editing,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Jordan Reyes');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Profile saved successfully'), findsOneWidget);
      expect(find.text('Municipal Profile'), findsOneWidget);
      expect(find.text('Jordan Reyes'), findsOneWidget);

      // Let the success banner's auto-dismiss timer run to completion —
      // otherwise it's still pending when the widget tree gets torn down
      // at the end of the test.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Municipal Profile Cancel discards edits and returns to the read-only '
    'view',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MunicipalProfileScreen(
            initialState: MunicipalProfileViewState.editing,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Someone Else');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Municipal Profile'), findsOneWidget);
      expect(find.text('Alex Johnston'), findsOneWidget);
      expect(find.text('Someone Else'), findsNothing);
    },
  );
}

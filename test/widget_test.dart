import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_inbox_screen.dart';

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
}

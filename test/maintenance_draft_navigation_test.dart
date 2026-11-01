import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/update_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    final previous = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previous);
  });
  for (final draft in ['status', 'whitespace', 'callback stays']) {
    testWidgets('Back protects $draft draft', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Task list')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => UpdateProgressScreen(
            task: mockMaintenanceTasks().first,
            onBack: draft == 'callback stays' ? () {} : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (draft == 'status') {
        await tester.tap(find.text('Field issue'));
      } else {
        await tester.enterText(
          find.byType(TextField),
          draft == 'whitespace' ? '   ' : 'Keep these repair notes',
        );
      }
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pumpAndSettle();
      expect(find.text('Discard draft?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateProgressScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard draft?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      if (draft == 'callback stays') {
        expect(find.byType(UpdateProgressScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Discard draft?'), findsOneWidget);
      } else {
        expect(find.text('Task list'), findsOneWidget);
      }
    });
  }
  for (final discard in [false, true]) {
    testWidgets(
      'status draft resets without false dirty guard discard=$discard',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.light,
            home: const Scaffold(body: Text('Task list')),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                UpdateProgressScreen(task: mockMaintenanceTasks().first),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Field issue'));
        await tester.pumpAndSettle();
        if (discard) {
          await tester.ensureVisible(find.text('Discard Draft'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Discard Draft'));
          await tester.pumpAndSettle();
          expect(find.text('Discard draft?'), findsOneWidget);
          await tester.tap(find.text('Discard'));
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.text('In Progress'));
          await tester.pumpAndSettle();
        }
        // Reverting or explicitly discarding the only edit restores clean state.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Discard draft?'), findsNothing);
        expect(find.text('Task list'), findsOneWidget);
      },
    );
  }
  for (final systemBack in [false, true]) {
    testWidgets('unsaved notes survive cancelled Back system=$systemBack', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Task list')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => UpdateProgressScreen(
            task: mockMaintenanceTasks().first,
            onBack: () => navigator.currentState!.maybePop(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Repair notes still in progress.',
      );
      await tester.pump();
      Future<void> back() async {
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byIcon(AppIcons.back));
        }
        await tester.pumpAndSettle();
      }

      await back();
      expect(find.text('Discard draft?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Repair notes still in progress.'), findsOneWidget);
      await back();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Task list'), findsOneWidget);
      expect(find.byType(UpdateProgressScreen), findsNothing);
    });
  }
}

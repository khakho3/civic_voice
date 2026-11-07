import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/widgets/glass_card.dart';
import 'package:civic_voice/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader(AppTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await loader.load();
  });

  const states = {
    'IN_PROGRESS': MaintenanceTaskStatus.inProgress,
    'PENDING_APPROVAL': MaintenanceTaskStatus.pendingApproval,
  };

  for (final (width, scale) in [(320.0, 2.0), (390.0, 2.0), (390.0, 1.0)]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'Scheduled badges fit and align top trailing at $width, ${scale}x, $direction',
        (tester) async {
          tester.view.physicalSize = Size(width, 2000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final directory = MaintenanceTaskDirectory.instance.tasks;
          final original = directory.value;
          addTearDown(() => directory.value = original);
          directory.value = [
            for (final state in states.keys)
              MaintenanceTask.fromApi({
                'id': state,
                'title': 'Drain inspection $state',
                'location': 'Main Avenue',
                'status': state,
              }),
          ];
          String? openedTask;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Directionality(textDirection: direction, child: child!),
              ),
              home: DashboardScreen(
                onOpenTaskDetails: (taskId) => openedTask = taskId,
              ),
            ),
          );
          await tester.pumpAndSettle();

          for (final entry in states.entries) {
            final card = find.ancestor(
              of: find.text('Drain inspection ${entry.key}'),
              matching: find.byType(GlassCard),
            );
            final badge = find.descendant(
              of: card,
              matching: find.byType(TintedBadge),
            );
            final label = find.descendant(
              of: badge,
              matching: find.text(entry.value.label),
            );
            await tester.ensureVisible(card);
            final content = tester.getRect(
              find.byWidget(tester.widget<GlassCard>(card).child),
            );
            final badgeRect = tester.getRect(badge);
            final paragraph = tester.renderObject<RenderParagraph>(label);
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(badgeRect.top, closeTo(content.top, 0.5));
            if (direction == TextDirection.ltr) {
              expect(badgeRect.right, closeTo(content.right, 0.5));
            } else {
              expect(badgeRect.left, closeTo(content.left, 0.5));
            }
            await tester.tapAt(
              tester.getRect(card).bottomCenter -
                  const Offset(0, AppSpacing.sm),
            );
            expect(openedTask, entry.key);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

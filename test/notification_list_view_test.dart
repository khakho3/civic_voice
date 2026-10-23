import 'package:flutter/services.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/models/notification_item.dart';
import 'package:civic_voice/widgets/notification_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'denying device notifications keeps the in-app inbox readable and tappable',
    (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => 0,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      NotificationItem? opened;
      const item = NotificationItem(
        id: 'permission-test',
        type: NotificationType.citizenReportSubmitted,
        title: 'Report submitted',
        message: 'CV-TEST: Overflowing gutter',
        category: 'Reports',
        timeLabel: 'Now',
        icon: AppIcons.report,
        color: AppColors.statusSubmitted,
        read: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NotificationListView(
              notifications: const [item],
              emptyTitle: 'Empty',
              emptyMessage: 'No updates',
              onTap: (value) => opened = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Device Notifications Are Off'), findsOneWidget);
      expect(find.text('CV-TEST: Overflowing gutter'), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
      await tester.ensureVisible(find.text('Report submitted'));
      await tester.tap(find.text('Report submitted'));
      expect(opened?.id, item.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Clear all confirms before removing every notification', (
    tester,
  ) async {
    var cleared = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationListView(
            notifications: const [
              NotificationItem(
                id: 'n1',
                type: NotificationType.citizenReportSubmitted,
                title: 'Report submitted',
                message: 'Your report was received.',
                category: 'Reports',
                timeLabel: 'Just now',
                icon: AppIcons.report,
                color: AppColors.statusSubmitted,
                read: false,
              ),
            ],
            emptyTitle: 'No notifications',
            emptyMessage: 'You are all caught up.',
            onClearAll: () => cleared++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all notifications?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cleared, 0);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear all'));
    await tester.pumpAndSettle();
    expect(cleared, 1);
  });
}

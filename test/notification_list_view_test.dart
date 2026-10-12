import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/models/notification_item.dart';
import 'package:civic_voice/widgets/notification_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

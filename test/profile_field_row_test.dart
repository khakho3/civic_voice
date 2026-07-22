import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/widgets/profile_field_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('locked profile fields stay read-only without a padlock', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProfileFieldRow(
            label: 'Admin ID',
            value: 'ADM-000001',
            locked: true,
          ),
        ),
      ),
    );

    expect(find.text('Admin ID'), findsOneWidget);
    expect(find.text('ADM-000001'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byIcon(AppIcons.security), findsNothing);
  });
}

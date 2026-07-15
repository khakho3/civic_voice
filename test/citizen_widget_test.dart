import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Citizen Dashboard shows the signed-in citizen and quick actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CitizenDashboardScreen()),
    );
    await tester.pump();

    expect(find.text('Good Morning, Amina Mensah'), findsOneWidget);
    expect(find.text('Report a Community Issue'), findsOneWidget);
    expect(find.text('Report Now'), findsOneWidget);
  });
}

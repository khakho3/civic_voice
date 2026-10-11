import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/theme/theme_controller.dart';
import 'package:civic_voice/widgets/theme_preference_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ThemeController.mode.value = ThemeMode.system;
  });

  testWidgets('theme preference selects its value from the menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ThemePreferenceRow()),
      ),
    );

    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System (Default)'), findsNothing);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.text('System (Default)'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(ThemeController.mode.value, ThemeMode.dark);
    expect(find.text('System (Default)'), findsNothing);
  });
}

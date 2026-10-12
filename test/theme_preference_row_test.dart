import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/theme/theme_controller.dart';
import 'package:civic_voice/features/admin/screens/admin_profile_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_profile_screen.dart';
import 'package:civic_voice/features/maintenance/screens/profile_screen.dart'
    as mnt;
import 'package:civic_voice/features/ministry/screens/ministry_profile_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_profile_screen.dart';
import 'package:civic_voice/services/app_cache_service.dart';
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

  testWidgets('leading icon follows the chosen theme; the value stays hidden', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ThemePreferenceRow()),
      ),
    );

    Finder rowIcon(IconData icon) => find.descendant(
      of: find.byType(ThemePreferenceRow),
      matching: find.byIcon(icon),
    );

    for (final (mode, icon, label) in const [
      (ThemeMode.system, AppIcons.systemTheme, 'System (Default)'),
      (ThemeMode.light, AppIcons.sun, 'Light'),
      (ThemeMode.dark, AppIcons.moon, 'Dark'),
    ]) {
      ThemeController.mode.value = mode;
      await tester.pump();
      expect(rowIcon(icon), findsOneWidget, reason: mode.name);
      // The chosen value is announced, never shown in the row itself.
      expect(find.text(label), findsNothing, reason: mode.name);
      final node = tester.getSemantics(find.bySemanticsLabel('Theme'));
      expect(node.value, label, reason: mode.name);
      expect(node.hint, 'Choose app theme', reason: mode.name);
    }
    handle.dispose();
  });

  testWidgets('System keeps its own icon while the OS appearance is dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    ThemeController.mode.value = ThemeMode.system;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: ThemePreferenceRow()),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ThemePreferenceRow),
        matching: find.byIcon(AppIcons.systemTheme),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(AppIcons.moon), findsNothing);
  });

  group('every Profile uses the chosen-theme icon', () {
    final profiles = <String, Widget Function()>{
      'Citizen': () => const CitizenProfileScreen(),
      'Municipal': () => const MunicipalProfileScreen(),
      'Ministry': () => const MinistryProfileScreen(),
      'Maintenance': () => const mnt.ProfileScreen(),
      'Admin': () => const AdminProfileScreen(),
    };
    for (final entry in profiles.entries) {
      testWidgets(entry.key, (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await AppCacheService.instance.initialize();
        tester.view.physicalSize = const Size(428, 2800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ThemeController.mode.value = ThemeMode.light;

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: entry.value()),
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(ThemePreferenceRow),
            matching: find.byIcon(AppIcons.sun),
          ),
          findsOneWidget,
        );
        ThemeController.mode.value = ThemeMode.dark;
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(ThemePreferenceRow),
            matching: find.byIcon(AppIcons.moon),
          ),
          findsOneWidget,
        );
      });
    }
  });
}

import 'package:civic_voice/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ThemeController.mode.value = ThemeMode.light;
  });

  test('defaults to light when the user has not chosen a theme', () async {
    ThemeController.mode.value = ThemeMode.dark;

    await ThemeController.loadSavedTheme();

    expect(ThemeController.mode.value, ThemeMode.light);
  });

  for (final selectedMode in ThemeMode.values) {
    test('restores saved ${selectedMode.name} theme after restart', () async {
      await ThemeController.setThemeMode(selectedMode);

      // Simulate a fresh process whose in-memory notifier has returned to its
      // first-launch default before startup reloads the persisted preference.
      ThemeController.mode.value = selectedMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
      await ThemeController.loadSavedTheme();

      expect(ThemeController.mode.value, selectedMode);
    });
  }
}

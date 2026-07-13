import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ThemeController {
  const ThemeController._();

  static const String _themeModeKey = 'theme_mode';
  static const String _darkValue = 'dark';
  static const String _lightValue = 'light';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static Future<void> loadSavedTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);
    mode.value = savedMode == _darkValue ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool enabled) async {
    mode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _themeModeKey,
      enabled ? _darkValue : _lightValue,
    );
  }
}

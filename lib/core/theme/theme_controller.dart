import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ThemeController {
  const ThemeController._();

  static const String _themeModeKey = 'theme_mode';
  static const String _darkValue = 'dark';
  static const String _lightValue = 'light';
  static const String _systemValue = 'system';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static Future<void> loadSavedTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);
    // No saved preference yet means the user has never explicitly chosen —
    // follow the platform brightness rather than defaulting to light,
    // matching every other module's ThemeMode.system default.
    mode.value = switch (savedMode) {
      _darkValue => ThemeMode.dark,
      _lightValue => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  /// Binary light/dark toggle — used by modules whose own appearance
  /// control is still a single Switch (e.g. Citizen Profile) rather than
  /// the three-way System/Light/Dark control ([setThemeMode]).
  static Future<void> setDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  static Future<void> setThemeMode(ThemeMode newMode) async {
    mode.value = newMode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, switch (newMode) {
      ThemeMode.dark => _darkValue,
      ThemeMode.light => _lightValue,
      ThemeMode.system => _systemValue,
    });
  }
}

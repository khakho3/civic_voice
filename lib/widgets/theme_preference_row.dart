import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';

/// The three-way System/Light/Dark theme control shown in every module's
/// profile "System Preferences" section — originally Admin-only, promoted
/// here since [ThemeController.setDarkMode]'s own doc comment already
/// names the binary Switch (kept only for Citizen's own profile screen) as
/// the lesser option. Stacked (label above, full-width control below)
/// rather than inline — a 3-segment button needs more width than a
/// label-left/control-right row leaves it on a narrow phone.
class ThemePreferenceRow extends StatelessWidget {
  const ThemePreferenceRow({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(AppIcons.systemTheme, size: AppIconSize.sm),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(AppIcons.sun, size: AppIconSize.sm),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(AppIcons.moon, size: AppIconSize.sm),
                ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (selected) =>
                  ThemeController.setThemeMode(selected.first),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../services/app_haptics.dart';
import 'profile_preference_row.dart';

/// Compact System/Light/Dark menu for every Profile preference group.
///
/// The visible row deliberately omits a duplicate selected-value label: its
/// leading icon reflects the choice (System, sun for Light, moon for Dark),
/// a far-right chevron opens the menu, the open menu marks the current
/// choice with a check, and the row exposes the value semantically. A manual choice beats the OS; System follows it live
/// ([ThemeController] stays the single source of truth).
class ThemePreferenceRow extends StatefulWidget {
  const ThemePreferenceRow({super.key});

  @override
  State<ThemePreferenceRow> createState() => _ThemePreferenceRowState();
}

class _ThemePreferenceRowState extends State<ThemePreferenceRow> {
  final MenuController _menuController = MenuController();

  static const _options = <({ThemeMode mode, String label, IconData icon})>[
    (
      mode: ThemeMode.system,
      label: 'System (Default)',
      icon: AppIcons.systemTheme,
    ),
    (mode: ThemeMode.light, label: 'Light', icon: AppIcons.sun),
    (mode: ThemeMode.dark, label: 'Dark', icon: AppIcons.moon),
  ];

  void _select(ThemeMode mode) {
    AppHaptics.activate();
    _menuController.close();
    unawaited(ThemeController.setThemeMode(mode));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        final selected = _options.firstWhere((option) => option.mode == mode);
        return MenuAnchor(
          controller: _menuController,
          consumeOutsideTap: true,
          alignmentOffset: const Offset(AppSpacing.md, 0),
          style: const MenuStyle(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: AppSpacing.xs),
            ),
          ),
          menuChildren: [
            for (final option in _options)
              MenuItemButton(
                onPressed: () => _select(option.mode),
                leadingIcon: Icon(option.icon, size: AppIconSize.sm),
                trailingIcon: option.mode == mode
                    ? Icon(
                        AppIcons.success,
                        size: AppIconSize.sm,
                        semanticLabel: 'Selected',
                        color: AppSemanticColors.of(context).actionText,
                      )
                    : null,
                child: Text(option.label),
              ),
          ],
          builder: (context, controller, _) => Semantics(
            button: true,
            label: 'Theme',
            value: selected.label,
            hint: 'Choose app theme',
            excludeSemantics: true,
            child: ProfilePreferenceRow(
              // The leading icon shows the chosen option (System keeps its
              // own icon even while the OS flips light/dark); the value
              // itself stays out of the visible row.
              icon: selected.icon,
              label: 'Theme',
              trailing: Icon(
                AppIcons.chevronDown,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        );
      },
    );
  }
}

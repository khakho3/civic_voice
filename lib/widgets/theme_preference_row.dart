import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';

/// Compact System/Light/Dark menu for every Profile preference group.
///
/// The visible row deliberately omits a duplicate selected-value label; the
/// menu provides the selected checkmark and the row exposes it semantically.
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
    _menuController.close();
    unawaited(ThemeController.setThemeMode(mode));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        final selected = _options.firstWhere((option) => option.mode == mode);
        return MenuAnchor(
          controller: _menuController,
          consumeOutsideTap: true,
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
                    ? const Icon(AppIcons.success, size: AppIconSize.sm)
                    : null,
                child: Text(option.label),
              ),
          ],
          builder: (context, controller, _) => Semantics(
            button: true,
            label: 'Theme',
            value: selected.label,
            hint: 'Choose app theme',
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                borderRadius: AppRadius.allSm,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppDimensions.controlHeightStandard,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.systemTheme,
                          size: AppIconSize.md,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Theme',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Icon(
                          AppIcons.chevronDown,
                          size: AppIconSize.sm,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

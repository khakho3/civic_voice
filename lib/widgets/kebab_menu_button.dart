import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Thin [PopupMenuButton] wrapper fixing a real, reported UX bug in the
/// default configuration: [PopupMenuButton]'s default `position` is
/// [PopupMenuPosition.over], which draws the opened menu directly on top of
/// its own trigger icon instead of below it — so opening the menu covers
/// the very icon that opened it. `position: PopupMenuPosition.under` opens
/// the menu right below the trigger instead, the behavior every caller
/// actually wants. Native menu-route scrolling (`showMenu`'s own height
/// constraints) already kicks in for item lists too long to fit on screen —
/// nothing extra needed here to get that for free.
///
/// Global (`lib/widgets/`), not module-scoped: every kebab menu in the app
/// (User Management's per-user actions, Municipal's report/profile menus)
/// shares this same trigger-overlap bug, so it's fixed once here rather
/// than per call site.
class KebabMenuButton<T> extends StatelessWidget {
  const KebabMenuButton({
    super.key,
    required this.itemBuilder,
    this.icon,
    this.iconColor,
    this.tooltip,
    this.onSelected,
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final IconData? icon;
  final Color? iconColor;
  final String? tooltip;
  final PopupMenuItemSelected<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      position: PopupMenuPosition.under,
      tooltip: tooltip,
      icon: Icon(icon ?? AppIcons.more, size: AppIconSize.md, color: iconColor),
      itemBuilder: itemBuilder,
      onSelected: onSelected,
    );
  }
}

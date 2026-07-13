import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CivicTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CivicTopBar({
    super.key,
    this.title = 'CivicVoice',
    this.showNotifications = true,
    this.onBack,
  });

  final String title;
  final bool showNotifications;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: theme.extension<AppSemanticColors>()!.glassSurface
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.75 : 0.8),
      elevation: AppElevation.level1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.04),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      shape: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
          width: 0.667,
        ),
      ),
      titleSpacing: AppSpacing.md,
      leadingWidth: 84,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md, top: 2, bottom: 2),
        child: onBack == null
            ? _BrandMark(tooltip: title)
            : _ChromeIconButton(
                icon: AppIcons.back,
                tooltip: 'Back',
                onPressed: onBack,
              ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: AppFontWeight.bold,
        ),
      ),
      actions: [
        if (showNotifications)
          const _ChromeIconButton(
            icon: AppIcons.notifications,
            tooltip: 'Notifications',
          )
        else
          const SizedBox(width: 52),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

class CivicBottomNav extends StatelessWidget {
  const CivicBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<AppSemanticColors>()!.glassSurface;
    final glassFill = glass.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.75 : 0.8,
    );

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
          final fabSize = compact ? 56.0 : 64.0;

          return SizedBox(
            height: compact ? 82 : 88,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: AppComponentRadius.bottomSheet,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: AppGlassBlur.medium,
                        sigmaY: AppGlassBlur.medium,
                      ),
                      child: Container(
                        height: compact ? 74 : 80,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.sm,
                          horizontalPadding,
                          AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: glassFill,
                          borderRadius: AppComponentRadius.bottomSheet,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.36,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BottomNavItem(
                                icon: AppIcons.home,
                                label: 'Home',
                                selected: selectedIndex == 0,
                                compact: compact,
                                onTap: () => onDestinationSelected(0),
                              ),
                            ),
                            Expanded(
                              child: _BottomNavItem(
                                icon: AppIcons.report,
                                label: 'Reports',
                                selected: selectedIndex == 1,
                                compact: compact,
                                onTap: () => onDestinationSelected(1),
                              ),
                            ),
                            const Expanded(child: SizedBox.shrink()),
                            Expanded(
                              child: _BottomNavItem(
                                icon: AppIcons.notifications,
                                label: 'Alerts',
                                selected: selectedIndex == 3,
                                compact: compact,
                                onTap: () => onDestinationSelected(3),
                              ),
                            ),
                            Expanded(
                              child: _BottomNavItem(
                                icon: AppIcons.profile,
                                label: 'Profile',
                                selected: selectedIndex == 4,
                                compact: compact,
                                onTap: () => onDestinationSelected(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Tooltip(
                    message: 'Create report',
                    child: Material(
                      color: AppColors.primary,
                      elevation: AppElevation.level3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.28),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onDestinationSelected(2),
                        child: SizedBox.square(
                          dimension: fabSize,
                          child: Icon(
                            AppIcons.add,
                            color: Colors.white,
                            size: compact
                                ? AppIconSize.standard
                                : AppIconSize.lg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Image.asset(AppAssets.logoApp, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.primary : theme.colorScheme.secondary;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: AppRadius.allLg,
        onTap: onTap,
        child: SizedBox(
          height: compact ? 52 : 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: compact ? AppIconSize.md : AppIconSize.standard,
              ),
              SizedBox(height: compact ? 2 : AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: compact ? 10 : null,
                  fontWeight: selected
                      ? AppFontWeight.semiBold
                      : AppFontWeight.medium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.tooltip,
    this.outlined = false,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.allLg,
          border: outlined
              ? Border.all(color: theme.colorScheme.outline)
              : null,
        ),
        child: IconButton(onPressed: onPressed ?? () {}, icon: Icon(icon)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';

/// Header chrome for citizen screens — a [GlassBar] floating in a [Stack]
/// above scrollable content, matching Admin/Municipal/Ministry's own
/// header exactly (never [Scaffold.appBar]/`flexibleSpace`, since
/// [GlassBar] is built to sit over content that scrolls underneath its
/// blur, not inside an AppBar's own opaque layout slot).
///
/// Only [isHomeTab] shows the logo — inline next to the "CivicVoice"
/// wordmark, left-aligned, the same lockup Municipal's dashboard tab uses.
/// Citizen has no drawer, so there's no leading hamburger to visually
/// balance a centered logo against the way Admin's does — every other
/// screen (tab root or back-button drill-down alike) shows a plain
/// [TextTheme.titleMedium] title, not [AppColors.primary]-tinted.
class CivicTopBar extends StatelessWidget {
  const CivicTopBar({
    super.key,
    this.title = 'CivicVoice',
    this.showNotifications = true,
    this.onBack,
    this.isHomeTab = false,
  });

  final String title;
  final bool showNotifications;
  final VoidCallback? onBack;
  final bool isHomeTab;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return GlassBar(
      border: Border(bottom: BorderSide(color: semantic.glassBorder)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppDimensions.headerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                if (onBack != null) ...[
                  _ChromeIconButton(
                    icon: AppIcons.back,
                    tooltip: 'Back',
                    onPressed: onBack,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: isHomeTab
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppAssets.logoApp,
                              width: AppIconSize.xl,
                              height: AppIconSize.xl,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'CivicVoice',
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          title,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (showNotifications)
                  _ChromeIconButton(
                    icon: AppIcons.notifications,
                    tooltip: 'Notifications',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The top/bottom inset every citizen screen's scrollable content must
/// reserve in its own padding so nothing renders permanently hidden behind
/// the glass header/nav — mirrors `MunicipalScaffold.contentPadding`
/// exactly. Screens add this to their own [ListView]/[SingleChildScrollView]
/// padding rather than wrapping `body` in an outer [Padding], since an
/// outer wrapper would shrink the scrollable's box instead of letting its
/// content actually scroll underneath the chrome.
EdgeInsets civicContentPadding(BuildContext context) {
  final viewPadding = MediaQuery.paddingOf(context);
  return EdgeInsets.only(
    top: viewPadding.top + AppDimensions.headerHeight,
    bottom: viewPadding.bottom + AppDimensions.bottomNavHeight,
  );
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final fabSize = compact ? 56.0 : 64.0;
        final barHeight = (compact ? 74.0 : 80.0) + bottomInset;

        return SizedBox(
          width: double.infinity,
          child: SizedBox(
            height: barHeight + 8,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GlassBar(
                    borderRadius: AppComponentRadius.bottomSheet,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.36),
                    ),
                    child: Container(
                      height: barHeight,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm + bottomInset,
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
          ),
        );
      },
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
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.controlHeightStandard,
      height: AppDimensions.controlHeightStandard,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        child: InkWell(
          borderRadius: AppRadius.allLg,
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: AppIconSize.md,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

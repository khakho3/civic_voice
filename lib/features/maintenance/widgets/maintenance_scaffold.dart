import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../widgets/glass_bar.dart';
import '../../../widgets/unread_dot_badge.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../services/maintenance_task_directory.dart';

/// Primary bottom-navigation destinations for the Maintenance Team module —
/// Dashboard (MNT-001), Assigned Tasks (MNT-002), Profile (MNT-007). Task
/// Details/Update Progress/Task Completed are drill-downs reached by tapping
/// a task, not tab slots (same shape as Municipal Officer's report-handling
/// screens, which use `MunicipalDetailHeader`/[DetailHeader] instead of a
/// persistent bottom nav) — this module's own screens previously kept a
/// 3-tab `NavigationBar` pinned on every one of those drill-downs too, which
/// this scaffold intentionally does not carry forward.
enum MaintenanceTab {
  dashboard(label: 'Home', icon: AppIcons.home, headerTitle: 'CivicVoice'),
  tasks(label: 'Tasks', icon: AppIcons.task, headerTitle: 'Assigned Tasks'),
  // Matches the concise title used by the other module profile screens.
  profile(label: 'Profile', icon: AppIcons.profile, headerTitle: 'Profile');

  const MaintenanceTab({
    required this.label,
    required this.icon,
    required this.headerTitle,
  });

  final String label;
  final IconData icon;
  final String headerTitle;
}

/// Shared shell (header + bottom navigation) for Maintenance Team screens —
/// the same "Header ↓ Primary Content ↓ Navigation" shape as
/// [MinistryScaffold]/`MunicipalScaffold`/`AdminScaffold`, generic over
/// [MaintenanceTab] instead. Replaces the raw `Scaffold(appBar: AppBar(...),
/// bottomNavigationBar: NavigationBar(...))` every Maintenance screen used
/// to build independently. It supplies the same glass treatment and plain
/// color/weight active-tab style as the other modules, plus shared access to
/// notifications.
class MaintenanceScaffold extends StatelessWidget {
  const MaintenanceScaffold({
    super.key,
    required this.body,
    required this.selectedTab,
    this.onNotificationsTap,
    this.onTabSelected,
    this.hideBottomNav = false,
  });

  final Widget body;
  final MaintenanceTab selectedTab;
  final VoidCallback? onNotificationsTap;

  final ValueChanged<MaintenanceTab>? onTabSelected;

  /// Hides the floating bottom nav — used while Profile is mid-edit, where
  /// switching tabs mid-form is more likely a mistake than an intent, and
  /// where it would otherwise sit on top of that screen's own sticky Save
  /// bar (matching [AdminScaffold]'s identical `hideBottomNav`).
  final bool hideBottomNav;

  /// The top/bottom inset every [body] must reserve in its own scrollable
  /// content so nothing sits permanently hidden behind the glass header/nav.
  static EdgeInsets contentPadding(BuildContext context) {
    final viewPadding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return EdgeInsets.only(
      top: viewPadding.top + AppDimensions.headerHeight,
      bottom:
          viewPadding.bottom +
          (viewInsets.bottom > 0
              ? viewInsets.bottom
              : AppDimensions.bottomNavHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      // Header/nav are Align-positioned in a Stack, not real Scaffold slots
      // — the default (true) resize shrank the whole Stack a frame behind
      // keyboardVisible above during the keyboard's open/close animation,
      // producing a brief mismatched-position flash. False keeps them
      // pinned to the true screen edges always; [contentPadding] reserves
      // the keyboard's own height instead so scrollable content still
      // clears it.
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(child: body),
            Align(
              alignment: Alignment.topCenter,
              child: _Header(
                tab: selectedTab,
                onNotificationsTap: onNotificationsTap,
              ),
            ),
            if (!keyboardVisible && !hideBottomNav)
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomNav(
                  selected: selectedTab,
                  onSelected: onTabSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    this.onNotificationsTap,
  });

  final MaintenanceTab tab;
  final VoidCallback? onNotificationsTap;

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
                Expanded(
                  child: tab == MaintenanceTab.dashboard
                      ? Row(
                          children: [
                            Image.asset(
                              AppAssets.logoApp,
                              width: AppIconSize.xl,
                              height: AppIconSize.xl,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                'CivicVoice',
                                style: textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          tab.headerTitle,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    MaintenanceTaskDirectory.instance.tasks,
                    MaintenanceTeamDirectory.instance.teams,
                    NotificationDirectory.instance.readIds,
                  ]),
                  builder: (context, _) => UnreadDotBadge(
                    show: NotificationDirectory.instance.hasUnread(
                      NotificationDirectory.instance.forMaintenance(),
                    ),
                    child: _IconButton(
                      icon: AppIcons.notifications,
                      onPressed: onNotificationsTap,
                      semantic: semantic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.semantic,
    this.onPressed,
  });

  final IconData icon;
  final AppSemanticColors semantic;
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
          child: Icon(
            icon,
            size: AppIconSize.md,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, this.onSelected});

  final MaintenanceTab selected;
  final ValueChanged<MaintenanceTab>? onSelected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return GlassBar(
      border: Border(top: BorderSide(color: semantic.glassBorder)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                for (final tab in MaintenanceTab.values) ...[
                  Expanded(
                    child: _NavItem(
                      tab: tab,
                      isSelected: tab == selected,
                      onTap: onSelected == null ? null : () => onSelected!(tab),
                    ),
                  ),
                  if (tab != MaintenanceTab.values.last)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Active state is a plain color/weight change — no filled pill background
/// — matching every other module's bottom nav (Citizen's `CivicBottomNav`,
/// Ministry/Municipal/Admin's own `_NavItem`s).
class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.isSelected, this.onTap});

  final MaintenanceTab tab;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isSelected
        ? AppColors.primary
        : (isDark ? AppColorsDark.secondaryText : AppColorsLight.secondaryText);

    return InkWell(
      borderRadius: AppRadius.allLg,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tab == MaintenanceTab.tasks)
              AnimatedBuilder(
                animation: Listenable.merge([
                  MaintenanceTaskDirectory.instance.tasks,
                  MaintenanceTeamDirectory.instance.teams,
                  NotificationDirectory.instance.readIds,
                ]),
                builder: (context, _) => UnreadDotBadge(
                  show: NotificationDirectory.instance.hasUnread(
                    NotificationDirectory.instance.forMaintenance(),
                  ),
                  child: Icon(
                    tab.icon,
                    size: AppIconSize.md,
                    color: foreground,
                  ),
                ),
              )
            else
              Icon(tab.icon, size: AppIconSize.md, color: foreground),
            const SizedBox(height: AppSpacing.xs),
            Text(
              tab.label,
              style: textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: isSelected
                    ? AppFontWeight.semiBold
                    : AppFontWeight.medium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

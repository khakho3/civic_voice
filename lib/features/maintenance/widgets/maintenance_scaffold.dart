import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';

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
  // Deliberately just "Profile", not "My Profile" — the profile body's own
  // headline already reads "My Profile"; a matching header title would
  // duplicate that text on-screen for no reason.
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
/// to build independently — which meant an opaque, non-glass header, a
/// Material 3 filled-pill active-tab indicator (every other module's nav
/// uses a plain color/weight change instead, no pill), and no header
/// shortcut to Profile.
class MaintenanceScaffold extends StatelessWidget {
  const MaintenanceScaffold({
    super.key,
    required this.body,
    required this.selectedTab,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onTabSelected,
  });

  final Widget body;
  final MaintenanceTab selectedTab;
  final VoidCallback? onNotificationsTap;

  /// Opens Maintenance Profile — shown on every tab rather than just
  /// [MaintenanceTab.profile], matching Ministry/Municipal's own header
  /// avatar (account access isn't tied to one tab's content).
  final VoidCallback? onProfileTap;
  final ValueChanged<MaintenanceTab>? onTabSelected;

  /// The top/bottom inset every [body] must reserve in its own scrollable
  /// content so nothing sits permanently hidden behind the glass header/nav.
  static EdgeInsets contentPadding(BuildContext context) {
    final viewPadding = MediaQuery.paddingOf(context);
    return EdgeInsets.only(
      top: viewPadding.top + AppDimensions.headerHeight,
      bottom: viewPadding.bottom + AppDimensions.bottomNavHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
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
                onProfileTap: onProfileTap,
              ),
            ),
            if (!keyboardVisible)
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
  const _Header({required this.tab, this.onNotificationsTap, this.onProfileTap});

  final MaintenanceTab tab;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

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
                _IconButton(
                  icon: AppIcons.notifications,
                  onPressed: onNotificationsTap,
                  semantic: semantic,
                ),
                // Omitted on the Profile tab itself — showing a "go to
                // profile" shortcut while already there duplicated the
                // Profile body's own identity block right below it.
                if (tab != MaintenanceTab.profile) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _ProfileButton(onTap: onProfileTap),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.controlHeightStandard,
      height: AppDimensions.controlHeightStandard,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: CircleAvatar(
              radius: AppIconSize.md / 2 + 2,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(
                AppIcons.profile,
                size: AppIconSize.sm,
                color: AppColors.primary,
              ),
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

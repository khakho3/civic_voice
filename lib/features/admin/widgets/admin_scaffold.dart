import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';

/// Primary bottom-navigation destinations for the System Administrator
/// module. The approved Figma export's nav bar ("Dashboard / Users / Roles
/// / Settings") maps directly onto four of the eight approved ADM-00x
/// screens (see "18 CivicVoice - System Administrator Screen
/// Specifications"): ADM-001 Admin Dashboard, ADM-002 User Management,
/// ADM-004 Role Management, ADM-007 System Settings — unlike the Ministry
/// Supervisor module's own export, this one didn't need correcting.
///
/// ADM-003 User Details, ADM-005 Category Management, and ADM-006 System
/// Activity are drill-downs (not tabs) per their own spec'd entry points.
/// ADM-008 Admin Profile has no visible entry point on this frame (no
/// header avatar, unlike every Ministry screen) — left unresolved pending
/// that screen's own export rather than guessed at now.
enum AdminTab {
  dashboard(label: 'Dashboard', icon: AppIcons.home, headerTitle: 'CivicVoice'),
  users(label: 'Users', icon: AppIcons.team, headerTitle: 'User Management'),
  roles(label: 'Roles', icon: AppIcons.shield, headerTitle: 'Role Management'),
  settings(
    label: 'Settings',
    icon: AppIcons.settings,
    headerTitle: 'System Settings',
  );

  const AdminTab({
    required this.label,
    required this.icon,
    required this.headerTitle,
  });

  /// Short label under the bottom-nav icon.
  final String label;
  final IconData icon;

  /// Full screen title shown in the header. Unused for [dashboard], whose
  /// header is the brand mark instead of a text title.
  final String headerTitle;
}

/// Shared shell (header + bottom navigation) for System Administrator
/// screens — the same "Header ↓ Primary Content ↓ Navigation" shell as
/// [MinistryScaffold]/`MunicipalScaffold`, generic over [AdminTab] instead.
///
/// Only [AdminTab.dashboard] shows the CivicVoice brand mark (logo +
/// wordmark) in its header — every other tab shows its own
/// [AdminTab.headerTitle] instead, the same convention every other module
/// uses. The approved ADM-001 export draws a hamburger-style glyph to the
/// left of "CivicVoice" — confirmed with the user that this is the logo
/// mark itself (matching every other module's `AppAssets.logoApp` brand
/// treatment), not a functional drawer trigger, so there's no separate
/// leading menu button here and no profile-avatar trailing button either
/// (that frame doesn't draw one).
///
/// Header and bottom nav are [GlassBar]s floating in a [Stack] above [body]
/// — [body] is positioned edge-to-edge behind them, so its content actually
/// scrolls underneath and gets frosted. [body] is expected to reserve
/// `MediaQuery.paddingOf(context).top + AppDimensions.headerHeight` of top
/// padding and `MediaQuery.paddingOf(context).bottom +
/// AppDimensions.bottomNavHeight` of bottom padding in its own scrollable
/// content so nothing renders permanently hidden underneath the chrome.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.body,
    required this.selectedTab,
    this.onNotificationsTap,
    this.onTabSelected,
  });

  final Widget body;
  final AdminTab selectedTab;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<AdminTab>? onTabSelected;

  /// The top/bottom inset every [body] must reserve in its own scrollable
  /// content so nothing sits permanently hidden behind the glass header/nav
  /// — see the class doc comment.
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
  const _Header({required this.tab, this.onNotificationsTap});

  final AdminTab tab;
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
                  child: tab == AdminTab.dashboard
                      ? Row(
                          children: [
                            Image.asset(
                              AppAssets.logoApp,
                              width: AppIconSize.xl,
                              height: AppIconSize.xl,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Flexible, not a mainAxisSize.min Row: on a
                            // narrow phone the notification icon alone can
                            // leave less than the brand text's natural
                            // width, and an unconstrained Text inside a
                            // shrink-wrapped Row overflows instead of
                            // yielding.
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

  final AdminTab selected;
  final ValueChanged<AdminTab>? onSelected;

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
                for (final tab in AdminTab.values) ...[
                  Expanded(
                    child: _NavItem(
                      tab: tab,
                      isSelected: tab == selected,
                      onTap: onSelected == null ? null : () => onSelected!(tab),
                    ),
                  ),
                  if (tab != AdminTab.values.last)
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

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.isSelected, this.onTap});

  final AdminTab tab;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isSelected
        ? Colors.white
        : (isDark ? AppColorsDark.secondaryText : AppColorsLight.secondaryText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: AppRadius.allLg,
        child: InkWell(
          borderRadius: AppRadius.allLg,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.icon, size: AppIconSize.md, color: foreground),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tab.label,
                style: textTheme.labelMedium?.copyWith(color: foreground),
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

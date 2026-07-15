import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';

/// Primary bottom-navigation destinations for the System Administrator
/// module. The approved Figma export's nav bar ("Dashboard / Users / Roles
/// / Settings") maps directly onto four of the eight approved ADM-00x
/// screens (see "18 CivicVoice - System Administrator Screen
/// Specifications"): ADM-001 Admin Dashboard, ADM-002 User Management,
/// ADM-004 Role Management, ADM-007 System Settings — confirmed as the
/// real nav against every other exported screen too (Role Management,
/// System Settings, and User Details all show this same four-tab bar;
/// only Admin Profile and System Activity's own frames show a different,
/// smaller "Dashboard / Activity / Settings / Profile" bar, which reads as
/// the same copy/paste drift already seen throughout this app rather than
/// a deliberate second nav — none of ADM-004/005/006/007/008 are spec'd
/// with an entry point other than "Admin Dashboard", so tab-bar residency
/// is our own call either way, and the 4-of-6 majority plus [MunicipalScaffold]'s
/// own precedent (Profile is never a persistent tab) both point the same
/// direction).
///
/// ADM-003 User Details, ADM-005 Category Management, and ADM-006 System
/// Activity are drill-downs (not tabs) per their own spec'd entry points.
/// ADM-008 Admin Profile is reached via [AdminScaffold]'s drawer (see its
/// own doc comment), not a tab.
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
  /// header is a centered logo mark instead of a text title.
  final String headerTitle;
}

/// Shared shell (header + drawer + bottom navigation) for System
/// Administrator screens — the same "Header ↓ Primary Content ↓
/// Navigation" shell as [MinistryScaffold]/`MunicipalScaffold`, generic
/// over [AdminTab] instead, plus a real navigation [Drawer] neither of
/// those modules needed.
///
/// [AdminTab.dashboard] shows a centered CivicVoice logo mark in its
/// header instead of a text title — every other tab shows its own
/// [AdminTab.headerTitle], the same convention every other module uses.
/// The full wordmark lockup (logo + "CivicVoice" text) lives only in the
/// drawer's own header, so it's never shown twice at once when the drawer
/// opens over the dashboard.
///
/// The leading hamburger glyph is a real drawer trigger, not decoration —
/// confirmed against every one of the six approved ADM-00x exports beyond
/// the dashboard, all of which draw the same glyph in the same position
/// regardless of which screen it is (a plain per-screen logo wouldn't make
/// sense on, say, User Details). The drawer itself only lists destinations
/// with no tab slot — ADM-008 Admin Profile and ADM-006 System Activity,
/// and later ADM-005 Category Management once it exists — since the four
/// [AdminTab]s are already one tap away on the always-visible bottom nav;
/// repeating them in the drawer would just be a second, slower path to the
/// same place.
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
    this.onOpenSystemActivity,
    this.onOpenProfile,
    this.headerTitle,
    this.hideBottomNav = false,
  });

  final Widget body;

  /// Which tab the bottom nav highlights — null shows none selected. Only
  /// a screen that's a tab's own root, or an exclusive drill-down from
  /// exactly one tab's own list (ADM-003 User Details, only ever reached
  /// by tapping a row in ADM-002 User Management), passes a real value.
  /// A screen reachable from more than one place, or from the drawer only
  /// — ADM-006 System Activity (Dashboard's card *and* every screen's
  /// drawer) and ADM-008 Admin Profile (drawer only) — passes null:
  /// highlighting a tab it doesn't actually belong to would just tell the
  /// user they're somewhere they're not.
  final AdminTab? selectedTab;

  /// Left unwired by every caller — there's no Notifications screen
  /// anywhere in the eight-screen ADM-00x spec, matching the Ministry
  /// Supervisor and Municipal Officer modules' own precedent of leaving
  /// this stub for now rather than inventing a destination.
  final VoidCallback? onNotificationsTap;
  final ValueChanged<AdminTab>? onTabSelected;

  /// Hides the floating bottom nav outright, same as it already hides
  /// while the keyboard is up — for a screen mid-edit (ADM-008 Admin
  /// Profile's own edit mode) where navigating away via the nav bar
  /// mid-form is more likely a mistake than an intent, and where it would
  /// otherwise sit directly on top of that screen's own sticky Save bar.
  final bool hideBottomNav;

  /// Opens ADM-006 System Activity — reachable from the drawer on every
  /// screen (Dashboard's own "Activity Monitoring" card is a second,
  /// shortcut path to the same destination, not a competing one).
  final VoidCallback? onOpenSystemActivity;

  /// Opens ADM-008 Admin Profile — the drawer is its only entry point.
  final VoidCallback? onOpenProfile;

  /// Overrides [AdminTab.headerTitle] for drill-down screens that inherit
  /// a tab's bottom-nav selection but need their own distinct header title
  /// — e.g. ADM-003 User Details keeps [AdminTab.users] selected (it's a
  /// drill-down from that list) but shows "User Details", not "User
  /// Management", in the header. Null for every screen that's a tab's own
  /// root, which is every screen so far except User Details.
  final String? headerTitle;

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
      drawer: _AdminDrawer(
        onOpenSystemActivity: onOpenSystemActivity,
        onOpenProfile: onOpenProfile,
      ),
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
                titleOverride: headerTitle,
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
    this.titleOverride,
  });

  final AdminTab? tab;
  final VoidCallback? onNotificationsTap;
  final String? titleOverride;

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
                _IconButton(
                  icon: AppIcons.menu,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  semantic: semantic,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: tab == AdminTab.dashboard && titleOverride == null
                      // A lone centered mark, not the full wordmark — the
                      // hamburger and bell are equal-width, so centering
                      // inside this Expanded lands the logo at the bar's
                      // true midpoint. The "CivicVoice" wordmark now lives
                      // only in the drawer, so it isn't shown twice at once
                      // when the drawer opens over this header. Only the
                      // literal Dashboard screen gets this treatment — a
                      // drill-down that keeps Dashboard selected as its
                      // parent tab (ADM-006 System Activity) still needs
                      // its own text title, via [titleOverride].
                      ? Center(
                          child: Image.asset(
                            AppAssets.logoApp,
                            width: AppIconSize.xl,
                            height: AppIconSize.xl,
                          ),
                        )
                      : Text(
                          titleOverride ?? tab?.headerTitle ?? '',
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

// ---------------------------------------------------------------------------
// Drawer
// ---------------------------------------------------------------------------

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({this.onOpenSystemActivity, this.onOpenProfile});

  final VoidCallback? onOpenSystemActivity;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
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
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: AppIcons.activityPulse,
              label: 'System Activity',
              onTap: onOpenSystemActivity == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onOpenSystemActivity!();
                    },
            ),
            _DrawerItem(
              icon: AppIcons.profile,
              label: 'Admin Profile',
              onTap: onOpenProfile == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onOpenProfile!();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, this.onSelected});

  final AdminTab? selected;
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

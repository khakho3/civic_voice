import '../../../services/notification_inbox_directory.dart';
import '../../../widgets/unread_dot_badge.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../services/app_haptics.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';
import '../services/admin_session.dart';

/// Primary bottom-navigation destinations for the System Administrator
/// module — revised from the originally-approved Figma nav ("Dashboard /
/// Users / Roles / Settings") per Francis's own usage-frequency call: Role
/// Management is reviewed rarely (it's a fixed, read-only tier catalog —
/// see [AdminRoleManagementScreen]'s own doc comment) and moved to the
/// drawer, while ADM-006 System Activity — an audit log an admin plausibly
/// checks every session — takes the freed tab slot instead. ADM-001 Admin
/// Dashboard, ADM-002 User Management, ADM-006 System Activity, ADM-007
/// System Settings are the four tabs now; ADM-004 Role Management and
/// ADM-008 Admin Profile both live in the drawer.
///
/// ADM-003 User Details and ADM-005 Category Management remain drill-downs
/// (not tabs), same as before.
enum AdminTab {
  dashboard(label: 'Home', icon: AppIcons.home, headerTitle: 'CivicVoice'),
  users(label: 'Users', icon: AppIcons.team, headerTitle: 'User Management'),
  activity(
    label: 'Activity',
    icon: AppIcons.activityPulse,
    headerTitle: 'System Activity',
  ),
  maintenance(
    label: 'Teams',
    icon: AppIcons.maintenanceTeam,
    headerTitle: 'Maintenance Teams',
  ),
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

/// Drawer-only destinations. [AdminDrawerDestination.maintenanceTeams]
/// deliberately covers the list, form, and detail route family.
enum AdminDrawerDestination { roleManagement, maintenanceTeams, adminProfile }

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
/// with no tab slot — ADM-004 Role Management and ADM-008 Admin Profile,
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
    this.onOpenRoleManagement,
    this.onOpenAlerts,
    this.onOpenMaintenanceTeams,
    this.onOpenProfile,
    this.onBack,
    this.headerTitle,
    this.hideBottomNav = false,
    this.activeDrawerDestination,
  });

  final Widget body;

  /// Which tab the bottom nav highlights — null shows none selected. Only
  /// a screen that's a tab's own root, or an exclusive drill-down from
  /// exactly one tab's own list (ADM-003 User Details, only ever reached
  /// by tapping a row in ADM-002 User Management), passes a real value.
  /// A screen reachable from the drawer only, with no tab slot of its own
  /// — ADM-004 Role Management and ADM-008 Admin Profile — passes null:
  /// highlighting a tab it doesn't actually belong to would just tell the
  /// user they're somewhere they're not. ADM-006 System Activity now has
  /// its own tab ([AdminTab.activity]) despite Dashboard's "Activity
  /// Monitoring" card being a second, shortcut path to the same place —
  /// same precedent as [AdminTab.users], also reachable from both its tab
  /// and Dashboard's own Management row.
  final AdminTab? selectedTab;

  /// Left unwired by every caller — there's no Notifications screen
  /// anywhere in the eight-screen ADM-00x spec, matching the Ministry
  /// Supervisor and Municipal Officer modules' own precedent of leaving
  /// this stub for now rather than inventing a destination.
  final VoidCallback? onNotificationsTap;
  final ValueChanged<AdminTab>? onTabSelected;

  /// Hides the floating bottom nav outright, either for a drill-down that
  /// should return through its header or for a screen mid-edit where the nav
  /// would conflict with the sticky Save bar.
  final bool hideBottomNav;

  /// The current destination when an Admin route belongs to the native drawer
  /// rather than a bottom-navigation tab. At most one drawer item can be
  /// selected at a time.
  final AdminDrawerDestination? activeDrawerDestination;

  /// Opens ADM-004 Role Management — the drawer is its only entry point
  /// now that it's no longer a bottom-nav tab (see [AdminTab]'s own doc
  /// comment for why).
  final VoidCallback? onOpenRoleManagement;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenMaintenanceTeams;

  /// Opens ADM-008 Admin Profile from Super Admin's drawer or regular Admin's
  /// header shortcut.
  final VoidCallback? onOpenProfile;

  /// Replaces the regular Admin's profile shortcut with a leading back
  /// button on drill-down screens such as the assembly Admin profile.
  final VoidCallback? onBack;

  /// Overrides [AdminTab.headerTitle] for drill-down screens that inherit
  /// a tab's bottom-nav selection but need their own distinct header title
  /// — e.g. ADM-003 User Details keeps [AdminTab.users] selected (it's a
  /// drill-down from that list) but shows "User Details", not "User
  /// Management", in the header. Null for every screen that's a tab's own
  /// root, which is every screen so far except User Details.
  final String? headerTitle;

  /// The top/bottom inset every [body] must reserve in its own scrollable
  /// content so nothing sits permanently hidden behind the glass header/nav
  /// — see the class doc comment. Reserves room for the keyboard instead of
  /// the (now-hidden) bottom nav while it's up, since [build] disables
  /// [Scaffold.resizeToAvoidBottomInset] — see that field's doc comment.
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
    final isSuperAdmin = AdminSession.instance.isSuperAdmin;
    return Scaffold(
      // The header/nav are Align-positioned in a Stack below, not real
      // Scaffold slots, so the default (true) resize made the *whole* Stack
      // — including the Align(bottom)-positioned nav — shrink and re-anchor
      // as the keyboard opened, one frame behind the keyboardVisible check
      // above during the transition. That mismatch was the "shadow"/flash
      // Francis saw. False keeps header/nav pinned to the true screen edges
      // always; [contentPadding] reserves the keyboard's own height instead
      // so scrollable content still clears it.
      resizeToAvoidBottomInset: false,
      drawer: isSuperAdmin
          ? _AdminDrawer(
              activeDestination: activeDrawerDestination,
              onOpenRoleManagement: onOpenRoleManagement,
              onOpenAlerts:
                  onOpenAlerts ??
                  (Firebase.apps.isEmpty
                      ? null
                      : () => Navigator.of(context).pushNamed('/admin/alerts')),
              onOpenMaintenanceTeams: onOpenMaintenanceTeams,
              onOpenProfile: onOpenProfile,
            )
          : null,
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
                onOpenProfile: onOpenProfile,
                onBack: onBack,
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
    this.onOpenProfile,
    this.onBack,
    this.titleOverride,
  });

  final AdminTab? tab;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onBack;
  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final isSuperAdmin = AdminSession.instance.isSuperAdmin;
    final showNormalAdminBrand =
        tab == AdminTab.dashboard && titleOverride == null;
    return GlassBar(
      border: Border(bottom: BorderSide(color: semantic.glassBorder)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppDimensions.headerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: isSuperAdmin
                ? Row(
                    children: [
                      _IconButton(
                        icon: AppIcons.menu,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        semanticLabel: 'Open navigation menu',
                        semantic: semantic,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (onBack != null) ...[
                        _IconButton(
                          icon: AppIcons.back,
                          onPressed: onBack,
                          semanticLabel: 'Go back',
                          semantic: semantic,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child:
                            tab == AdminTab.dashboard && titleOverride == null
                            ? Center(
                                child: Image.asset(
                                  AppAssets.logoApp,
                                  width: AppIconSize.lg,
                                  height: AppIconSize.lg,
                                ),
                              )
                            : Text(
                                titleOverride ?? tab?.headerTitle ?? '',
                                style: textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      AnimatedBuilder(
                        animation: NotificationInboxDirectory.instance,
                        builder: (context, child) => UnreadDotBadge(
                          show:
                              NotificationInboxDirectory.instance.unreadCount >
                              0,
                          child: child!,
                        ),
                        child: _IconButton(
                          icon: AppIcons.notifications,
                          onPressed: onNotificationsTap,
                          semanticLabel: 'Notifications',
                          semantic: semantic,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (onBack != null) ...[
                        _IconButton(
                          icon: AppIcons.back,
                          onPressed: onBack,
                          semanticLabel: 'Go back',
                          semantic: semantic,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: showNormalAdminBrand
                            ? Row(
                                children: [
                                  Image.asset(
                                    AppAssets.logoApp,
                                    width: AppIconSize.lg,
                                    height: AppIconSize.lg,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'CivicVoice',
                                      style: textTheme.titleLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                titleOverride ?? tab?.headerTitle ?? '',
                                style: textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (onBack == null) _ProfileButton(onTap: onOpenProfile),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Opens Admin Profile — a small circular avatar rather than a plain icon,
/// so it visually reads as "your account", matching Ministry/Municipal/
/// Maintenance's own header avatar.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({this.onTap});

  final VoidCallback? onTap;
  static const semanticLabel = 'Admin profile';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: SizedBox(
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
                      color: AppSemanticColors.of(context).actionText,
                    ),
                  ),
                ),
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
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final AppSemanticColors semantic;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: SizedBox(
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
  const _AdminDrawer({
    this.activeDestination,
    this.onOpenRoleManagement,
    this.onOpenAlerts,
    this.onOpenMaintenanceTeams,
    this.onOpenProfile,
  });

  final AdminDrawerDestination? activeDestination;
  final VoidCallback? onOpenRoleManagement;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenMaintenanceTeams;
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
                    width: AppIconSize.lg,
                    height: AppIconSize.lg,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('CivicVoice', style: textTheme.titleLarge),
                ],
              ),
            ),
            const Divider(height: 1),
            if (onOpenAlerts != null)
              _DrawerItem(
                icon: AppIcons.warning,
                label: 'Open alerts',
                selected: false,
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenAlerts!();
                },
              ),
            // An assembly Admin has no tiers to review or reassign — Role
            // Management is a Super Admin-only concern — so the item is
            // dropped entirely rather than shown disabled.
            if (AdminSession.instance.isSuperAdmin)
              _DrawerItem(
                icon: AppIcons.roleManagement,
                label: 'Role Management',
                selected:
                    activeDestination == AdminDrawerDestination.roleManagement,
                onTap: onOpenRoleManagement == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onOpenRoleManagement!();
                      },
              ),
            if (AdminSession.instance.canManageTeams)
              _DrawerItem(
                icon: AppIcons.maintenanceTeam,
                label: 'Maintenance Teams',
                selected:
                    activeDestination ==
                    AdminDrawerDestination.maintenanceTeams,
                onTap: onOpenMaintenanceTeams == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onOpenMaintenanceTeams!();
                      },
              ),
            _DrawerItem(
              icon: AppIcons.profile,
              label: 'Admin Profile',
              selected:
                  activeDestination == AdminDrawerDestination.adminProfile,
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
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = AppSemanticColors.of(context).actionText;
    return Semantics(
      selected: selected,
      child: ListTile(
        selected: selected,
        selectedColor: selectedColor,
        selectedTileColor: AppSemanticColors.of(
          context,
        ).actionFill.withValues(alpha: 0.10),
        leading: Icon(
          icon,
          color: selected ? selectedColor : colorScheme.onSurfaceVariant,
        ),
        title: Text(label),
        onTap: onTap,
        // The current route can intentionally have no navigation callback;
        // keep it enabled for selected-color contrast rather than rendering
        // the active destination as a disabled grey item.
        enabled: onTap != null || selected,
      ),
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
    // An assembly Admin has no System Settings to configure, so that tab
    // is dropped for them entirely rather than shown and then blocked.
    // Activity stays — see AdminSession.visibleActivity's own doc comment
    // — an assembly Admin gets their own region-scoped audit feed there,
    // just not the national health readout Super Admin also sees on it.
    final visibleTabs = AdminSession.instance.isSuperAdmin
        ? const [
            AdminTab.dashboard,
            AdminTab.users,
            AdminTab.activity,
            AdminTab.settings,
          ]
        : const [
            AdminTab.dashboard,
            AdminTab.users,
            AdminTab.activity,
            AdminTab.maintenance,
          ];
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
                for (final tab in visibleTabs) ...[
                  Expanded(
                    child: _NavItem(
                      tab: tab,
                      isSelected: tab == selected,
                      onTap: onSelected == null
                          ? null
                          : () {
                              AppHaptics.activate();
                              onSelected!(tab);
                            },
                    ),
                  ),
                  if (tab != visibleTabs.last)
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
/// — matching Citizen's own bottom nav (`CivicBottomNav`'s `_BottomNavItem`),
/// the approved target style for every module's nav.
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
        ? AppSemanticColors.of(context).actionText
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

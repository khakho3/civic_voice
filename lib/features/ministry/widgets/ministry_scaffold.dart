import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../widgets/glass_bar.dart';
import '../../../widgets/unread_dot_badge.dart';
import '../../municipal/services/municipal_report_directory.dart';

/// Primary bottom-navigation destinations for the Ministry Supervisor
/// module. The approved Figma export's nav bar showed "Dashboard / Analytics
/// / Services / Settings" — but neither "Services" nor "Settings" is one of
/// the six approved MIN-00x screens (see "17 CivicVoice - Ministry
/// Supervisor Screen Specifications"), and Settings specifically is a
/// cross-module concern out of scope for every role's module (the same
/// conclusion already reached for Municipal Officer). The four tabs here
/// keep the Figma's tab *count* and structure (a persistent bottom nav,
/// confirmed correct by its presence on every exported dashboard state) but
/// point each slot at a real spec screen: MIN-001 Dashboard, MIN-002
/// Analytics Dashboard, MIN-003 Municipal Performance, MIN-004 Reports
/// Overview. MIN-005 Report Insights is a drill-down from Analytics/Reports
/// (not a tab, per its own spec'd entry points), and MIN-006 Profile is
/// reached via the header avatar, matching Municipal Officer's own
/// (externally reviewed and confirmed correct) pattern rather than
/// occupying a fifth tab slot.
enum MinistryTab {
  dashboard(label: 'Home', icon: AppIcons.home, headerTitle: 'CivicVoice'),
  analytics(
    label: 'Analytics',
    icon: AppIcons.analytics,
    headerTitle: 'Analytics Dashboard',
  ),
  municipalities(
    label: 'Municipalities',
    icon: AppIcons.municipality,
    headerTitle: 'Municipal Performance',
  ),
  reports(
    label: 'Reports',
    icon: AppIcons.report,
    headerTitle: 'Reports Overview',
  );

  const MinistryTab({
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

/// Shared shell (header + bottom navigation) for Ministry Supervisor
/// screens — the same "Header ↓ Primary Content ↓ Navigation" shell as
/// Municipal Officer's `MunicipalScaffold`, generic over [MinistryTab]
/// instead. Kept module-scoped (parameterized by tab enum) rather than
/// promoted to `lib/widgets/` alongside [GlassBar]/`GlassCard`: unlike
/// those, this shell's public surface *is* the tab enum, so a shared
/// version would need to be generic in a way that adds real complexity for
/// only two current call sites — worth revisiting if a third role-scaffold
/// needs the identical shape.
///
/// Only [MinistryTab.dashboard] shows the CivicVoice brand mark in its
/// header — every other tab shows its own [MinistryTab.headerTitle]
/// instead, the same convention Municipal Officer uses.
///
/// Header and bottom nav are [GlassBar]s (real backdrop blur) floating in a
/// [Stack] above [body] — [body] is positioned edge-to-edge behind them, so
/// its content actually scrolls underneath and gets frosted. [body] is
/// expected to reserve `MediaQuery.paddingOf(context).top +
/// AppDimensions.headerHeight` of top padding and
/// `MediaQuery.paddingOf(context).bottom + AppDimensions.bottomNavHeight`
/// of bottom padding in its own scrollable content so nothing renders
/// permanently hidden underneath the chrome.
class MinistryScaffold extends StatelessWidget {
  const MinistryScaffold({
    super.key,
    required this.body,
    required this.selectedTab,
    this.headerSubtitle,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onTabSelected,
  });

  final Widget body;
  final MinistryTab selectedTab;

  /// Optional second line under the screen title — ignored for
  /// [MinistryTab.dashboard], whose header is the brand mark rather than a
  /// text title.
  final String? headerSubtitle;
  final VoidCallback? onNotificationsTap;

  /// Opens Ministry Profile (MIN-006) — the only entry point to it, shown
  /// on every tab rather than just Dashboard, since account access isn't
  /// tied to any one tab's content.
  final VoidCallback? onProfileTap;
  final ValueChanged<MinistryTab>? onTabSelected;

  /// The top/bottom inset every [body] must reserve in its own scrollable
  /// content so nothing sits permanently hidden behind the glass header/nav
  /// — see the class doc comment.
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
    // Hide the bottom nav while the keyboard is up — matches Municipal
    // Officer's scaffold: the nav has nothing to do with text entry, and
    // leaving it pinned above the keyboard wastes scarce vertical space.
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
                subtitle: headerSubtitle,
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
  const _Header({
    required this.tab,
    this.subtitle,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  final MinistryTab tab;
  final String? subtitle;
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
                  child: tab == MinistryTab.dashboard
                      ? Row(
                          children: [
                            Image.asset(
                              AppAssets.logoApp,
                              width: AppIconSize.xl,
                              height: AppIconSize.xl,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Flexible, not a mainAxisSize.min Row: on a
                            // narrow phone the notification/profile icons
                            // alone can leave less than the brand text's
                            // natural width, and an unconstrained Text
                            // inside a shrink-wrapped Row overflows instead
                            // of yielding.
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
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tab.headerTitle,
                              style: textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.96,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    MunicipalReportDirectory.instance.reports,
                    NotificationDirectory.instance.readIds,
                  ]),
                  builder: (context, _) => UnreadDotBadge(
                    show: NotificationDirectory.instance.hasUnread(
                      NotificationDirectory.instance.forMinistry(),
                    ),
                    child: _IconButton(
                      icon: AppIcons.notifications,
                      onPressed: onNotificationsTap,
                      semantic: semantic,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _ProfileButton(onTap: onProfileTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens Ministry Profile — a small circular avatar rather than a plain
/// icon, so it visually reads as "your account" distinct from the bell.
/// Matches Municipal Officer's header avatar treatment exactly (an icon
/// glyph, not the initials shown in the raw Figma export) — the same
/// account-entry affordance should look identical across every role's
/// scaffold, not vary per module.
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

  final MinistryTab selected;
  final ValueChanged<MinistryTab>? onSelected;

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
                for (final tab in MinistryTab.values) ...[
                  Expanded(
                    child: _NavItem(
                      tab: tab,
                      isSelected: tab == selected,
                      onTap: onSelected == null ? null : () => onSelected!(tab),
                    ),
                  ),
                  if (tab != MinistryTab.values.last)
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

  final MinistryTab tab;
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

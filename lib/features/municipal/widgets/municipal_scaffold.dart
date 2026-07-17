import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';

/// Primary bottom-navigation destinations for the Municipal Officer module —
/// exactly the four shown in the approved Figma frames. Do not add
/// destinations that aren't in the approved navigation architecture
/// (see docs/DEVELOPMENT_RULES.md — Navigation).
enum MunicipalTab {
  dashboard(label: 'Dashboard', icon: AppIcons.home, headerTitle: 'CivicVoice'),
  inbox(label: 'Inbox', icon: AppIcons.inbox, headerTitle: 'Incoming Reports'),
  active(
    label: 'Active',
    icon: AppIcons.analytics,
    headerTitle: 'Active Reports',
  ),
  resolved(
    label: 'Resolved',
    icon: AppIcons.statusResolved,
    headerTitle: 'Resolved Reports',
  );

  const MunicipalTab({
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

/// Shared shell (header + bottom navigation) for Municipal Officer screens —
/// the "Header ↓ Primary Content ↓ Navigation" pattern from the Design
/// System Requirements (§19.9 Screen Structure), reused across the module.
///
/// Only [MunicipalTab.dashboard] shows the CivicVoice brand mark in its
/// header — every other tab shows its own [MunicipalTab.headerTitle]
/// instead (e.g. "Incoming Reports", "Active Reports"), the same convention
/// most tab-based apps use: the brand mark lives on the home tab, and every
/// other tab is titled for what it actually shows. Besides matching that
/// convention, repeating the logo bar *and* an in-body headline on every
/// list screen was redundant chrome that ate vertical space the actual
/// content (search, filters, cards) needed more.
///
/// Header and bottom nav are [GlassBar]s (real backdrop blur, not just a
/// translucent color) floating in a [Stack] above [body] — [body] is
/// positioned edge-to-edge behind them, so its content actually scrolls
/// underneath and gets frosted, rather than the blur having nothing behind
/// it to blur. [body] is expected to reserve
/// `MediaQuery.paddingOf(context).top + AppDimensions.headerHeight` of top
/// padding and `MediaQuery.paddingOf(context).bottom +
/// AppDimensions.bottomNavHeight` of bottom padding in its own scrollable
/// content so nothing renders permanently hidden underneath the chrome.
class MunicipalScaffold extends StatelessWidget {
  const MunicipalScaffold({
    super.key,
    required this.body,
    required this.selectedTab,
    this.headerSubtitle,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onTabSelected,
  });

  final Widget body;
  final MunicipalTab selectedTab;

  /// Optional second line under the screen title (e.g. a zone/district
  /// scope) — ignored for [MunicipalTab.dashboard], whose header is the
  /// brand mark rather than a text title.
  final String? headerSubtitle;
  final VoidCallback? onNotificationsTap;

  /// Opens Municipal Profile (MUN-009) — the only entry point to it, shown
  /// on every tab rather than just Dashboard, since account access isn't
  /// tied to any one tab's content.
  final VoidCallback? onProfileTap;
  final ValueChanged<MunicipalTab>? onTabSelected;

  /// The top/bottom inset every [body] must reserve in its own scrollable
  /// content so nothing sits permanently hidden behind the glass header/nav
  /// — see the class doc comment. Screens add this to their own padding
  /// rather than [MunicipalScaffold] wrapping [body] in a `Padding` itself,
  /// since an outer wrapper would just shrink the scrollable's box instead
  /// of letting its content actually scroll underneath the chrome.
  static EdgeInsets contentPadding(BuildContext context) {
    final viewPadding = MediaQuery.paddingOf(context);
    return EdgeInsets.only(
      top: viewPadding.top + AppDimensions.headerHeight,
      bottom: viewPadding.bottom + AppDimensions.bottomNavHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide the bottom nav while the keyboard is up: it has nothing to do
    // with text entry, and leaving it pinned above the keyboard both wastes
    // scarce vertical space and risks pushing scrollable content into
    // overflow (e.g. an empty/no-results illustration that assumed the
    // nav's ~80px was available).
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: GestureDetector(
        // Tapping anywhere outside a focused text field dismisses the
        // keyboard, on top of the keyboard's own close button — standard
        // mobile convention, and without it the only way to dismiss is that
        // button (or focusing another field).
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

  final MunicipalTab tab;
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
                  child: tab == MunicipalTab.dashboard
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
                _IconButton(
                  icon: AppIcons.notifications,
                  onPressed: onNotificationsTap,
                  semantic: semantic,
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

/// Opens Municipal Profile — a small circular avatar rather than a plain
/// icon, so it visually reads as "your account" distinct from the bell.
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

  final MunicipalTab selected;
  final ValueChanged<MunicipalTab>? onSelected;

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
                for (final tab in MunicipalTab.values) ...[
                  Expanded(
                    child: _NavItem(
                      tab: tab,
                      isSelected: tab == selected,
                      onTap: onSelected == null ? null : () => onSelected!(tab),
                    ),
                  ),
                  if (tab != MunicipalTab.values.last)
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

  final MunicipalTab tab;
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
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Primary bottom-navigation destinations for the Municipal Officer module —
/// exactly the four shown in the approved Figma frames. Do not add
/// destinations that aren't in the approved navigation architecture
/// (see docs/DEVELOPMENT_RULES.md — Navigation).
enum MunicipalTab {
  dashboard(label: 'Dashboard', icon: AppIcons.home, headerTitle: 'CivicVoice'),
  inbox(label: 'Inbox', icon: AppIcons.inbox, headerTitle: 'Incoming Reports'),
  active(label: 'Active', icon: AppIcons.analytics, headerTitle: 'Active Reports'),
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
class MunicipalScaffold extends StatelessWidget {
  const MunicipalScaffold({
    super.key,
    required this.body,
    required this.selectedTab,
    this.headerSubtitle,
    this.onNotificationsTap,
    this.onTabSelected,
  });

  final Widget body;
  final MunicipalTab selectedTab;

  /// Optional second line under the screen title (e.g. a zone/district
  /// scope) — ignored for [MunicipalTab.dashboard], whose header is the
  /// brand mark rather than a text title.
  final String? headerSubtitle;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<MunicipalTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    // Hide the bottom nav while the keyboard is up: it has nothing to do
    // with text entry, and leaving it pinned above the keyboard both wastes
    // scarce vertical space and risks pushing scrollable content into
    // overflow (e.g. an empty/no-results illustration that assumed the
    // nav's ~80px was available).
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        // Tapping anywhere outside a focused text field dismisses the
        // keyboard, on top of the keyboard's own close button — standard
        // mobile convention, and without it the only way to dismiss is that
        // button (or focusing another field).
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              _Header(
                tab: selectedTab,
                subtitle: headerSubtitle,
                onNotificationsTap: onNotificationsTap,
              ),
              Expanded(child: body),
              if (!keyboardVisible)
                _BottomNav(selected: selectedTab, onSelected: onTabSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tab, this.subtitle, this.onNotificationsTap});

  final MunicipalTab tab;
  final String? subtitle;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.glassNavSurface,
        border: Border(bottom: BorderSide(color: semantic.glassBorder)),
      ),
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
                          style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
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
        ],
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
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: semantic.glassNavSurface,
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
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
    );
  }
}

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
        ? Colors.white
        : (isDark ? AppColorsDark.secondaryText : AppColorsLight.secondaryText);

    // The selected pill is inset within the 80px bar (not edge-to-edge) —
    // matches the approved Figma spec (80px bar containing a 64px pill) and
    // Material 3's own indicator convention: a compact floating capsule,
    // not a block that fills the whole nav bar height.
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_bar.dart';

/// Shared glass header for drill-down screens reached outside the bottom
/// nav (a screen whose spec'd entry/exit points aren't a tab slot) — a
/// leading icon (back arrow by default), a title, and an optional
/// [trailing] widget (a notifications bell, a "Save" text button, etc.).
///
/// Global (`lib/widgets/`) rather than module-scoped: originally built for
/// MIN-005 Report Insights, promoted here once MIN-006 Ministry Profile
/// needed the identical shell — any drill-down screen without a bottom nav
/// should reuse this rather than reimplementing it per screen. Mirrors
/// Municipal Officer's own `MunicipalDetailHeader` in shape (that one stays
/// module-scoped since it's parameterized around a report reference ID that
/// doesn't generalize here — see its own doc comment).
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.title,
    this.leadingIcon = AppIcons.back,
    this.onBack,
    this.trailing,
  });

  final String title;

  /// Defaults to a back arrow; a screen with an edit mode that should
  /// cancel (rather than navigate away) on this tap can swap in
  /// [AppIcons.close] instead.
  final IconData leadingIcon;

  final VoidCallback? onBack;

  /// Notifications bell, a "Save" text button, etc. — `null` renders no
  /// trailing content.
  final Widget? trailing;

  /// Top padding a screen's own scrollable body must reserve so its content
  /// doesn't start permanently hidden underneath this floating header.
  static double topInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + AppDimensions.headerHeight;

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
                SizedBox(
                  width: AppDimensions.controlHeightStandard,
                  height: AppDimensions.controlHeightStandard,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: Icon(leadingIcon, size: AppIconSize.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

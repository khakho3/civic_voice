import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'glass_bar.dart';

/// Shared glass header for single-report drill-down screens (Report Review,
/// Verification, Assign Team, Report Progress) — back arrow + title +
/// reference subtitle + optional trailing content (status badge, menu).
///
/// Real backdrop-blurred glass, same as [MunicipalScaffold]'s header —
/// callers must position this as a [Stack] overlay above their scrollable
/// body (see [topInset]) rather than a `Column` sibling, or the blur has
/// nothing behind it to blur.
class MunicipalDetailHeader extends StatelessWidget {
  const MunicipalDetailHeader({
    super.key,
    required this.title,
    required this.referenceId,
    this.subtitlePrefix = '#',
    this.leadingIcon = AppIcons.back,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String referenceId;

  /// Prefixed onto [referenceId] for the subtitle line — '#' for a report
  /// reference (the default, matching every existing caller), 'ID ' for an
  /// account identifier (Municipal Profile).
  final String subtitlePrefix;

  /// Defaults to a back arrow; Municipal Profile's editing mode swaps in a
  /// close (X) icon instead, since [onBack] there cancels the edit rather
  /// than navigating up a level.
  final IconData leadingIcon;

  final VoidCallback? onBack;

  /// Status badge, kebab menu, etc.
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
                IconButton(
                  onPressed: onBack,
                  icon: Icon(leadingIcon),
                  iconSize: AppIconSize.md,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$subtitlePrefix$referenceId',
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

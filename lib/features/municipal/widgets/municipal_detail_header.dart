import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';

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
      MediaQuery.paddingOf(context).top + _height(context);

  static double _height(BuildContext context) {
    // Reserve both text lines at the user's scale; body consumers use the
    // identical height through topInset so the first card stays below them.
    final textTheme = Theme.of(context).textTheme;
    double lineHeight(TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return math.max(
      AppDimensions.headerHeight,
      lineHeight(textTheme.titleMedium) +
          lineHeight(textTheme.bodySmall) +
          AppSpacing.sm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return GlassBar(
      border: Border(bottom: BorderSide(color: semantic.glassBorder)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height(context),
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
                if (trailing != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                    ),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

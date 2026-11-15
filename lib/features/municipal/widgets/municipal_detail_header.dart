import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_bar.dart';
import '../../../models/report_status.dart';
import '../../../widgets/status_badge.dart';

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
    this.status,
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

  /// Optional trailing content. With [status], this is one menu button.
  final Widget? trailing;

  /// Persistent report status. Moves below the title when it cannot fit at
  /// the current width/text scale, retaining the badge's intrinsic width.
  final ReportStatus? status;

  /// Status-aware counterpart of [topInset] for this header instance.
  double contentInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + _layout(context).height;

  ({double height, bool statusBelow}) _layout(BuildContext context) {
    final baseHeight = _height(context);
    if (status == null) return (height: baseHeight, statusBelow: false);
    final textTheme = Theme.of(context).textTheme;
    final safePadding = MediaQuery.paddingOf(context);
    final width =
        MediaQuery.sizeOf(context).width -
        safePadding.horizontal -
        AppSpacing.md * 2;
    TextPainter measure(String value, TextStyle? style, {double? maxWidth}) {
      return TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 2,
      )..layout(maxWidth: maxWidth ?? double.infinity);
    }

    final titleSize = measure(title, textTheme.titleMedium);
    final badgeSize = measure(
      status!.label,
      textTheme.labelSmall?.copyWith(fontWeight: AppFontWeight.semiBold),
    );
    const border = AppDimensions.borderWidthThin * 2;
    final badgeWidth =
        badgeSize.width + TintedBadge.contentPadding.horizontal + border;
    final controls = kMinInteractiveDimension * (trailing == null ? 1 : 2);
    final statusBelow =
        controls + AppSpacing.xs * 2 + titleSize.width + badgeWidth > width;
    titleSize.dispose();
    badgeSize.dispose();
    if (!statusBelow) return (height: baseHeight, statusBelow: false);
    final wrapped = measure(
      status!.label,
      textTheme.labelSmall?.copyWith(fontWeight: AppFontWeight.semiBold),
      maxWidth: math.max(
        0,
        width - TintedBadge.contentPadding.horizontal - border,
      ),
    );
    final height =
        baseHeight +
        wrapped.height +
        TintedBadge.contentPadding.vertical +
        border +
        AppSpacing.sm;
    wrapped.dispose();
    return (height: height, statusBelow: true);
  }

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
    final layout = _layout(context);
    return GlassBar(
      border: Border(bottom: BorderSide(color: semantic.glassBorder)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: layout.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                SizedBox(
                  height: _height(context),
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
                      if (status != null && !layout.statusBelow) ...[
                        const SizedBox(width: AppSpacing.xs),
                        ReportStatusBadge(status: status!),
                      ],
                      if (trailing != null && status != null)
                        SizedBox(
                          width: kMinInteractiveDimension,
                          child: trailing,
                        ),
                      if (trailing != null && status == null)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                          ),
                          child: trailing,
                        ),
                    ],
                  ),
                ),
                if (status != null && layout.statusBelow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ReportStatusBadge(status: status!, maxLines: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

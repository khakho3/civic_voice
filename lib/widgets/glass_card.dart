import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A translucent "glass" surface card — the repeated `GlassCard` component
/// used throughout the Civic Glass design system (stats, recent activity,
/// summaries, list rows).
///
/// Global (`lib/widgets/`) rather than module-scoped: originally built for
/// the Municipal Officer module, promoted here once the Ministry Supervisor
/// module needed the identical component — every module shares one card
/// treatment, not a per-module reimplementation of it.
///
/// No [BackdropFilter] here (unlike [GlassBar]) — this is deliberately
/// translucency-only. Cards repeat per list item (report cards, team
/// cards), and blurring each one individually on every scroll frame is a
/// real performance cost for no real payoff, since there's nothing
/// distinct stacked behind an individual card the way there is behind the
/// header/nav bars.
///
/// Per §19.10 Glass Usage Rules, glass is prohibited on input-heavy
/// forms/long-form content — screens with a form section keep that section
/// on a plain opaque surface instead of wrapping it in [GlassCard].
///
/// Weight is deliberately light by default (a faint hairline, no shadow) —
/// a card should read as a soft grouping, not a boxed panel. Pass
/// [elevated] for the rare surface that genuinely needs to float above its
/// surroundings (e.g. something stacked over other cards); everything else
/// should stay at the default.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.border,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When set, the card becomes tappable (ripple feedback) — used for
  /// selectable/navigable list rows.
  final VoidCallback? onTap;

  /// Overrides the default glass hairline — e.g. a thicker primary-colored
  /// border to highlight a selected list row.
  final Border? border;

  /// Opts into a visible shadow (`AppShadow.level1`) for a surface that
  /// needs to float above its surroundings. Default is flat/no shadow.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final decoration = BoxDecoration(
      color: semantic.glassCardSurface,
      border:
          border ??
          Border.all(
            color: semantic.glassBorder.withValues(
              alpha: semantic.glassBorder.a * 0.6,
            ),
          ),
      borderRadius: AppComponentRadius.card,
      boxShadow: elevated ? AppShadow.level1 : AppShadow.level0,
    );

    if (onTap == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: AppComponentRadius.card,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

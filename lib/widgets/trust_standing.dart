import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

import '../models/trust_standing.dart';
export '../models/trust_standing.dart' show TrustStandingData;

enum TrustStandingVariant { compact, detailed }

/// Shared reporting-standing presentation (C01 contract): the compact
/// variant for Citizen Home (stars, label, next milestone, optionally
/// tappable through to Profile) and the detailed variant for Profile (what
/// moves the standing, and the nearby-confirmation pause only when
/// [TrustStandingData.lowStanding]).
///
/// Never shown to guests, and never on Municipal review screens.
class TrustStanding extends StatelessWidget {
  const TrustStanding({
    super.key,
    required this.standing,
    this.variant = TrustStandingVariant.compact,
    this.onOpenDetail,
  });

  final TrustStandingData standing;
  final TrustStandingVariant variant;

  /// Compact only: opens the detailed Profile view.
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final secondary = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final head = Row(
      children: [
        FractionalStars(value: standing.stars, outOf: standing.outOf),
        const SizedBox(width: AppSpacing.sm),
        Text(
          standing.scoreLabel,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        head,
        const SizedBox(height: AppSpacing.xs),
        Text(
          standing.label,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        if (variant == TrustStandingVariant.compact) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(standing.milestone, style: secondary),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your standing grows as reports you submit are accepted and '
            'resolved, and dips when one is rejected. It starts partway up, '
            'so there is room to build it.',
            style: secondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(standing.milestone, style: secondary),
          if (standing.lowStanding) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: AppRadius.allSm,
              ),
              child: Text(
                "While your standing is this low, confirming other people's "
                'nearby reports is paused. Submitting reports that are '
                'accepted will restore it.',
                style: secondary,
              ),
            ),
          ],
        ],
      ],
    );

    final label = 'Your reporting standing: ${standing.readout}';
    if (variant == TrustStandingVariant.compact && onOpenDetail != null) {
      return Semantics(
        button: true,
        label: '$label. View details.',
        onTap: onOpenDetail,
        excludeSemantics: true,
        child: InkWell(
          onTap: onOpenDetail,
          borderRadius: AppRadius.allMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: body,
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        excluding: variant == TrustStandingVariant.compact,
        child: body,
      ),
    );
  }
}

/// Five painted stars with a filled layer clipped to any fraction of the
/// track — 3.5, 3.7 or 4.25 all render without per-step glyphs. Track uses
/// the outline neutral, fill the readable warning ink.
class FractionalStars extends StatelessWidget {
  const FractionalStars({
    super.key,
    required this.value,
    this.outOf = 5,
    this.starSize = AppIconSize.md,
  });

  final double value;
  final double outOf;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final count = outOf.round().clamp(1, 10);
    const gap = AppSpacing.xs / 2;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(count * starSize + (count - 1) * gap, starSize),
        painter: _StarsPainter(
          count: count,
          fraction: outOf <= 0 ? 0 : (value / outOf).clamp(0.0, 1.0),
          gap: gap,
          track: Theme.of(context).colorScheme.outline,
          fill: AppSemanticColors.of(context).warningText,
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({
    required this.count,
    required this.fraction,
    required this.gap,
    required this.track,
    required this.fill,
  });

  final int count;
  final double fraction;
  final double gap;
  final Color track;
  final Color fill;

  Path _stars(Size size) {
    final path = Path();
    final d = size.height;
    for (var i = 0; i < count; i++) {
      final cx = i * (d + gap) + d / 2;
      final cy = d / 2;
      final outer = d / 2;
      final inner = outer * 0.45;
      for (var p = 0; p < 10; p++) {
        final r = p.isEven ? outer : inner;
        final a = -math.pi / 2 + p * math.pi / 5;
        final point = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
        p == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stars = _stars(size);
    canvas.drawPath(stars, Paint()..color = track);
    // Fraction of the star area, not of the full width with gaps, so 3.5/5
    // fills exactly three and a half stars.
    final d = size.height;
    final starsFilled = fraction * count;
    final whole = starsFilled.floor();
    final width = whole * (d + gap) + (starsFilled - whole) * d;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, size.height));
    canvas.drawPath(stars, Paint()..color = fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarsPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}

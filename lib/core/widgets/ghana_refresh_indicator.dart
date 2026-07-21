import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A custom pull-to-refresh indicator that uses the Ghana Black Star during the
/// drag phase, and a sweeping Ghana flag linear progress bar during the load phase.
class GhanaRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  /// How far down the screen's own fixed header/chrome already reserves —
  /// every module scaffold paints its header as a separate, later Stack
  /// child *on top of* the body (so it can float above scrolling content),
  /// which means anything positioned from this widget's own `top: 0` paints
  /// underneath that header, not above it. Pass the same top inset the
  /// screen already uses for its list's own content padding (e.g.
  /// `AdminScaffold.contentPadding(context).top`) so the star/bar appear in
  /// the gap that opens up below the header as the user pulls, instead of
  /// hidden behind it. Defaults to 0 for a screen with no fixed header
  /// above its scrollable content.
  final double topOffset;

  const GhanaRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.topOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    const double indicatorHeight = 80.0;
    // Plain black reads as a void on a dark background — Ghana Gold keeps
    // the star clearly a star (and still visibly "the flag") in dark mode
    // instead of nearly vanishing against it.
    final starColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.ghanaGold
        : Colors.black;

    return CustomRefreshIndicator(
      // The package awaits this outside a try/catch of its own (only a
      // `finally` retracts the indicator regardless of outcome) — a
      // network failure inside a caller's refresh() would otherwise
      // surface as an unhandled async exception. Every caller wants the
      // same thing here (a failed pull-to-refresh should just quietly not
      // update the list, never crash or log a red error), so it's handled
      // once here instead of at every wiring site.
      onRefresh: () async {
        try {
          await onRefresh();
        } catch (_) {}
      },
      offsetToArmed: indicatorHeight,
      builder: (BuildContext context, Widget child, IndicatorController controller) {
        // Star owns every state before a refresh is actually running (drag,
        // released-but-not-armed retract, armed, settle-into-armed); bar owns
        // everything from the moment loading actually starts through its
        // post-load hold and retract. Together they cover every non-idle
        // IndicatorState with no state left uncovered by either — that gap
        // (a blank frame between the two) was the bug being fixed here.
        final showStar =
            controller.isDragging ||
            controller.isCanceling ||
            controller.isArmed ||
            controller.isSettling;
        final showBar =
            controller.isLoading ||
            controller.isComplete ||
            controller.isFinalizing;

        // controller.value runs 0..1.5 (IndicatorController.maxValue), not
        // 0..1 — the extra range is overscroll past "armed". Clamping keeps
        // layout extent (box height, content push-down) from overshooting
        // indicatorHeight during an aggressive pull.
        final pullFraction = controller.value.clamp(0.0, 1.0);

        return Stack(
          children: [
            // Phase A: The Mascot (Black Star) that pulls down.
            if (showStar)
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                height: indicatorHeight * pullFraction,
                child: Center(
                  child: Transform.scale(
                    scale: pullFraction,
                    child: Transform.rotate(
                      // Raw (unclamped) value on purpose: overpulling past
                      // armed keeps spinning it faster/further as tactile
                      // feedback, rather than capping mid-gesture.
                      angle: controller.value * 2 * math.pi,
                      // A hand-drawn 5-pointed star, not Icons.star — the
                      // Material glyph is rounded/generic and doesn't read
                      // as the flag's Black Star specifically. Drawing it
                      // with CustomPainter costs nothing extra in app size
                      // (no image asset) and paints via a GPU compositing
                      // layer under Transform, so rotating/scaling it every
                      // drag frame doesn't re-run the path math each time.
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CustomPaint(
                          painter: _StarPainter(color: starColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Phase B: The main content — pushed down 1:1 with the pull while
            // dragging/settling, then eased back up to 0 exactly once when
            // loading starts, so it hugs the top divider while the bar runs.
            _RefreshContent(
              controller: controller,
              indicatorHeight: indicatorHeight,
              showBar: showBar,
              child: child,
            ),

            // Phase C: The linear progress indicator — shown through loading,
            // its post-load hold, and its retract, matching showBar above.
            if (showBar)
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                child: const _GhanaLinearProgress(),
              ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Positions [child] under the pull indicator.
///
/// During drag/cancel/armed/settling it tracks `controller.value` directly,
/// frame-for-frame — no animation of its own, since the package already
/// drives that value with a real, eased [AnimationController] during
/// settling/canceling/finalizing, and 1:1 with the finger during a raw drag.
/// Re-animating an already-animating value on top (the previous
/// `TweenAnimationBuilder` with a `end` that changed every frame) was what
/// made the content visibly lag behind the finger throughout the whole drag.
///
/// The one moment that genuinely needs an animation this widget owns itself
/// is the instant loading starts: `controller.value` stays pinned at its
/// armed rest value for the entire loading/complete/finalizing stretch, but
/// content should snap up to 0 right when the bar takes over. That's a real
/// one-shot transition, triggered exactly once on the `showBar` flip.
class _RefreshContent extends StatefulWidget {
  const _RefreshContent({
    required this.controller,
    required this.indicatorHeight,
    required this.showBar,
    required this.child,
  });

  final IndicatorController controller;
  final double indicatorHeight;
  final bool showBar;
  final Widget child;

  @override
  State<_RefreshContent> createState() => _RefreshContentState();
}

class _RefreshContentState extends State<_RefreshContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void didUpdateWidget(covariant _RefreshContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBar && !oldWidget.showBar) {
      _snap.forward(from: 0.0);
    } else if (!widget.showBar && oldWidget.showBar) {
      _snap.value = 0.0;
    }
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pullFraction = widget.controller.value.clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _snap,
      builder: (context, child) {
        final settled = widget.showBar
            ? Curves.easeOut.transform(_snap.value)
            : 0.0;
        final offset = widget.indicatorHeight * pullFraction * (1.0 - settled);
        return Transform.translate(offset: Offset(0.0, offset), child: child);
      },
      child: widget.child,
    );
  }
}

class _GhanaLinearProgress extends StatefulWidget {
  const _GhanaLinearProgress();

  @override
  State<_GhanaLinearProgress> createState() => _GhanaLinearProgressState();
}

class _GhanaLinearProgressState extends State<_GhanaLinearProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hard-edged blocks, not a 5-stop blended gradient — smoothly blending
  // red into gold into green produced a lot of muddy in-between color that
  // read as a generic rainbow smear rather than the flag's three distinct
  // bands. Duplicating each color at both ends of its third of the tile
  // gives a sharp cut instead of a blend at 1/3 and 2/3; TileMode.repeated
  // then marches that same three-block tile across continuously.
  static const _colors = [
    AppColors.ghanaRed,
    AppColors.ghanaRed,
    AppColors.ghanaGold,
    AppColors.ghanaGold,
    AppColors.ghanaGreen,
    AppColors.ghanaGreen,
  ];
  static const _stops = [0.0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1.0];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-2.0 + (_controller.value * 2), 0.0),
                end: Alignment(-1.0 + (_controller.value * 2), 0.0),
                colors: _colors,
                stops: _stops,
                tileMode: TileMode.repeated,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A plain 5-pointed star (tip up), filled solid — CustomPainter instead
/// of an image asset, so this costs nothing in app size and scales/rotates
/// cleanly at any size instead of shipping a raster. Black in light mode
/// (the flag's actual Black Star); Ghana Gold in dark mode, where black
/// would all but vanish against the background.
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2;
    // ~0.4x outer is a bold, simple point — closer to how a small national
    // Black Star mark actually reads at 36px than a slender golden-ratio
    // star (~0.38x) that thins out to nearly invisible tips at this size.
    final innerRadius = outerRadius * 0.4;
    const points = 5;
    const angleStep = math.pi / points;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * angleStep;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      color != oldDelegate.color;
}

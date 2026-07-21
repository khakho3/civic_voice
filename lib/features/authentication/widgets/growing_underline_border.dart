import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// An [InputBorder] that draws only a bottom line, at a variable
/// [growth] (0 = invisible, 1 = full width) — the shape itself stays a
/// rounded rect (for the filled background + corner clipping), but the
/// visible *stroke* only ever appears along the bottom edge.
///
/// The reveal-from-the-left motion isn't hand-animated with a
/// `FocusNode`/`AnimationController` — [InputDecorator] already
/// smoothly interpolates between `enabledBorder` and `focusedBorder` on
/// every focus change via [InputBorder.lerp]. Overriding [lerpFrom]/
/// [lerpTo] to interpolate [growth] (alongside the usual color/width via
/// [BorderSide.lerp]) hooks straight into that existing animation, so a
/// field that goes from `growth: 0` at rest to `growth: 1` when focused
/// gets the underline growing left-to-right for free, no extra widget
/// plumbing needed at any auth screen call site.
class GrowingUnderlineBorder extends InputBorder {
  const GrowingUnderlineBorder({
    required super.borderSide,
    this.growth = 1.0,
    this.radius = const Radius.circular(12),
    this.baselineColor,
  });

  /// 0 = no visible line, 1 = full-width line, drawn left-to-right.
  final double growth;

  /// Corner rounding for the filled shape — independent of [growth];
  /// the fill/clip stays fully rounded even while the stroke is partial.
  final Radius radius;

  /// A faint, always-drawn full-width hairline beneath the growth-animated
  /// stroke — without it, `growth: 0` at rest left the field with no
  /// visible edge at all once its filled container was dropped in favor of
  /// a flat, icon-only look. Null omits it (the growth stroke alone is
  /// enough once a state is already at growth: 1, e.g. error borders).
  /// Deliberately not itself animated — it's a constant backdrop the
  /// accent stroke grows across, not a second thing competing for
  /// attention with the actual focus cue.
  final Color? baselineColor;

  @override
  bool get isOutline => false;

  // InputBorder's own default is true, which routes the fill through the
  // base InputBorder.paintInterior() stub — a plain canvas.drawRect, with
  // square corners, ignoring getOuterPath()'s rounding entirely. That's
  // what made the filled field look unclipped despite radius being set
  // here. false routes the fill through getOuterPath() instead (see
  // _InputBorderPainter.paint in the framework), which is the RRect this
  // class already defines below.
  @override
  bool get preferPaintInterior => false;

  GrowingUnderlineBorder _copyWith({
    BorderSide? borderSide,
    double? growth,
    Radius? radius,
    Color? baselineColor,
  }) {
    return GrowingUnderlineBorder(
      borderSide: borderSide ?? this.borderSide,
      growth: growth ?? this.growth,
      radius: radius ?? this.radius,
      baselineColor: baselineColor ?? this.baselineColor,
    );
  }

  @override
  InputBorder copyWith({BorderSide? borderSide}) =>
      _copyWith(borderSide: borderSide);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  InputBorder scale(double t) => _copyWith(borderSide: borderSide.scale(t));

  // InputDecorator drives this lerp over a fixed, framework-internal
  // 167ms (not publicly configurable via InputDecoration/InputBorder —
  // there's no duration parameter to reach for). Easing just the growth
  // value (not color/width, which stay linear) is the lever actually
  // available here: it can't make the transition take longer, but a
  // decelerating curve reads as more deliberate/soft than a linear
  // sweep across the same window.
  static const Curve _growthCurve = Curves.easeOut;

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is GrowingUnderlineBorder) {
      return GrowingUnderlineBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        growth:
            lerpDouble(a.growth, growth, _growthCurve.transform(t)) ?? growth,
        radius: Radius.lerp(a.radius, radius, t) ?? radius,
        baselineColor:
            Color.lerp(a.baselineColor, baselineColor, t) ?? baselineColor,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is GrowingUnderlineBorder) {
      return GrowingUnderlineBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        growth:
            lerpDouble(growth, b.growth, _growthCurve.transform(t)) ?? growth,
        radius: Radius.lerp(radius, b.radius, t) ?? radius,
        baselineColor:
            Color.lerp(baselineColor, b.baselineColor, t) ?? baselineColor,
      );
    }
    return super.lerpTo(b, t);
  }

  RRect _rRect(Rect rect) => RRect.fromRectAndRadius(rect, radius);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rRect(rect));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rRect(rect));

  // The bottom "hem" of the field's own rounded rect: bottom-left arc,
  // straight run, bottom-right arc. clockwise:false is correct for both
  // corners here — verified empirically (path-midpoint vs. hand-calculated
  // true corner-bulge geometry) rather than assumed, since the sign is easy
  // to get backwards and would silently draw an inverted curve.
  Path _bottomHem(Rect rect) {
    return Path()
      ..moveTo(rect.left, rect.bottom - radius.y)
      ..arcToPoint(
        Offset(rect.left + radius.x, rect.bottom),
        radius: radius,
        clockwise: false,
      )
      ..lineTo(rect.right - radius.x, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - radius.y),
        radius: radius,
        clockwise: false,
      );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final baseline = baselineColor;
    if (baseline != null) {
      canvas.drawPath(
        _bottomHem(rect),
        Paint()
          ..color = baseline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    final clampedGrowth = growth.clamp(0.0, 1.0);
    if (clampedGrowth <= 0 || borderSide == BorderSide.none) return;
    final metric = _bottomHem(rect).computeMetrics().first;
    // The bottom-left arc's tangent starts out vertical (it matches the
    // left edge's direction, not the bottom edge's) — animating growth
    // through it from t=0 meant the first several frames traced an
    // almost-invisible vertical curl before any left-to-right motion
    // showed at all, so eased growth read as "pops into place" instead of
    // "sweeps in". Drawing that corner in full the instant growth leaves 0
    // (same fixed anchor the flat-line version always had, just now
    // curve-correct) and animating only the straight run + closing
    // bottom-right corner keeps the actual visible motion horizontal.
    final leadInLength = (math.pi / 2) * radius.x;
    final growableLength = (metric.length - leadInLength).clamp(
      0.0,
      metric.length,
    );
    final grownEnd = leadInLength + growableLength * clampedGrowth;
    final grown = metric.extractPath(0, grownEnd);
    canvas.drawPath(grown, borderSide.toPaint()..strokeCap = StrokeCap.round);
  }
}

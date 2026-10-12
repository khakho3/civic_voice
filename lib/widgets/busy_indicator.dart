import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The shared busy-action indicator (F06): a small "searching" orb — a
/// faint ring with one bright point sweeping around it — for buttons and
/// other in-place work. It is the native equivalent of the web inline
/// `LoadingOrb` (the `thinking-orbs` npm package has no Flutter port).
///
/// Page loading keeps the existing native Ghana loaders; this is only for
/// a control or row that is busy.
///
/// * Ink comes from the host: by default the ambient [IconTheme] color,
///   which Material buttons set to their current (enabled or disabled)
///   foreground, so the orb matches gold-fill, outlined and text buttons
///   in both themes without the caller choosing a color.
/// * With reduced motion it draws one static frame.
/// * Its controller is created with this widget's ticker, so it stops
///   ticking while the route is hidden ([TickerMode]) and when disposed.
/// * It is decorative unless [semanticsLabel] is given, in which case the
///   label is announced once as a polite live region.
class BusyIndicator extends StatefulWidget {
  const BusyIndicator({
    super.key,
    this.size = AppIconSize.md,
    this.color,
    this.semanticsLabel,
  });

  /// Diameter; defaults to the 20px inline size.
  final double size;

  /// Overrides the host ink.
  final Color? color;

  /// Announced once when the indicator appears, e.g. "Saving changes".
  final String? semanticsLabel;

  /// One sweep of the bright point — a modest searching pace.
  static const Duration period = Duration(milliseconds: 1400);

  @override
  State<BusyIndicator> createState() => _BusyIndicatorState();
}

class _BusyIndicatorState extends State<BusyIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BusyIndicator.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink =
        widget.color ??
        IconTheme.of(context).color ??
        AppSemanticColors.of(context).actionText;
    final reduceMotion = AppMotion.reduceMotion(context);

    final orb = SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _OrbPainter(
            ink: ink,
            // Static frame: the point rests at the upper right.
            progress: reduceMotion ? null : _controller,
          ),
        ),
      ),
    );

    final label = widget.semanticsLabel;
    if (label == null) return ExcludeSemantics(child: orb);
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: orb,
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.ink, required this.progress})
    : super(repaint: progress);

  final Color ink;
  final Animation<double>? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide / 10;
    final radius = size.shortestSide / 2 - stroke;
    final turn = progress?.value ?? 0.125;
    final angle = turn * 2 * math.pi - math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ink.withValues(alpha: ink.a * 0.28),
    );

    // A short tail fading behind the point gives the sweep its direction.
    const tail = math.pi * 0.6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle - tail,
      tail,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        // Rotated rather than offset: SweepGradient clamps angles outside
        // 0..2π, which would flatten the tail near 12 o'clock.
        ..shader = SweepGradient(
          endAngle: tail,
          colors: [ink.withValues(alpha: 0), ink],
          transform: GradientRotation(angle - tail),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center + Offset(math.cos(angle), math.sin(angle)) * radius,
      stroke * 1.4,
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.progress != progress;
}

/// Swaps a button's label for [BusyIndicator] while [busy], keeping the
/// label's exact footprint so the button never jumps in width or height.
/// While busy the label leaves the semantics tree and [busyLabel] is
/// announced once instead.
class BusyLabel extends StatelessWidget {
  const BusyLabel({
    super.key,
    required this.busy,
    required this.child,
    this.busyLabel,
  });

  final bool busy;
  final Widget child;

  /// Spoken while busy, e.g. "Saving changes".
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
          visible: !busy,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: child,
        ),
        if (busy) BusyIndicator(semanticsLabel: busyLabel),
      ],
    );
  }
}

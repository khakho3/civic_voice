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
/// * Inside buttons, ink and track contrast against the actual button fill,
///   including its disabled state. Outside buttons, ink follows IconTheme.
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
    this.trackOpacity,
  });

  /// Diameter; defaults to the 20px inline size.
  final double size;

  /// Overrides the host ink.
  final Color? color;

  /// Announced once when the indicator appears, e.g. "Saving changes".
  final String? semanticsLabel;
  final double? trackOpacity;

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
    final buttonInk = _buttonBusyInk(context);
    final ink =
        widget.color ??
        buttonInk ??
        IconTheme.of(context).color ??
        AppSemanticColors.of(context).actionText;
    final reduceMotion = AppMotion.reduceMotion(context);

    final orb = SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _OrbPainter(
            ink: ink,
            trackOpacity:
                widget.trackOpacity ?? (buttonInk == null ? 0.28 : 0.7),
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
  _OrbPainter({
    required this.ink,
    required this.progress,
    required this.trackOpacity,
  }) : super(repaint: progress);

  final Color ink;
  final double trackOpacity;
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
        ..color = ink.withValues(alpha: ink.a * trackOpacity),
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
      oldDelegate.ink != ink ||
      oldDelegate.progress != progress ||
      oldDelegate.trackOpacity != trackOpacity;
}

/// Disabled buttons supply a deliberately muted IconTheme. Busy work still
/// needs a visible progress signal, so choose ink against the actual button
/// Material fill rather than inheriting that disabled foreground.
Color? _buttonBusyInk(BuildContext context) {
  var inButton = false;
  context.visitAncestorElements((element) {
    if (element.widget is ButtonStyleButton) {
      inButton = true;
      return false;
    }
    return true;
  });
  if (!inButton) return null;
  final theme = Theme.of(context);
  final fill =
      context.findAncestorWidgetOfExactType<Material>()?.color ??
      Colors.transparent;
  final background = Color.alphaBlend(fill, theme.colorScheme.surface);
  double contrast(Color ink) {
    final a = ink.computeLuminance(), b = background.computeLuminance();
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
  }

  final normal = theme.colorScheme.onSurface;
  if (contrast(normal) >= 4.5) return normal;
  return contrast(Colors.black) >= contrast(Colors.white)
      ? Colors.black
      : Colors.white;
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

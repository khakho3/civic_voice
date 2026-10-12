import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// One-shot horizontal shake for a field that just failed validation
/// (F05). Bump [trigger] (any changing value, typically an attempt
/// counter) to play it once; equal values never replay. Reduced motion
/// disables the movement — the error text and color still carry the state.
class ErrorShake extends StatefulWidget {
  const ErrorShake({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  /// Total shake duration.
  static const Duration duration = AppMotionDuration.moderate;

  @override
  State<ErrorShake> createState() => _ErrorShakeState();
}

class _ErrorShakeState extends State<ErrorShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ErrorShake.duration,
  );

  @override
  void didUpdateWidget(ErrorShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        widget.trigger != null &&
        !AppMotion.reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // Three decaying oscillations, at most 6px either side.
        const amplitude = AppSpacing.xs * 1.5;
        final offset = math.sin(t * math.pi * 6) * (1 - t) * amplitude;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
    );
  }
}

/// A success check that draws itself in once (F05) inside a tinted disc.
/// Reduced motion shows the finished mark immediately.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({super.key, this.size = AppIconSize.lg});

  final double size;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.duration(context, AppMotionDuration.emphasized),
        curve: AppMotionCurve.decelerate,
        builder: (context, progress, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: semantic.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: _CheckPainter(
              progress: progress,
              color: semantic.successText,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.28, w * 0.52)
      ..lineTo(w * 0.44, w * 0.67)
      ..lineTo(w * 0.73, w * 0.36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w / 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

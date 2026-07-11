import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A container with a dashed border — the visual signal for "nothing here
/// yet" inline empty states (e.g. Evidence Missing), distinct from the
/// solid borders used on real content cards. No package dependency: a
/// small self-contained painter.
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.borderRadius = AppComponentRadius.card,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: semantic.glassBorder,
        borderRadius: borderRadius,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppDimensions.borderWidthThin;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}

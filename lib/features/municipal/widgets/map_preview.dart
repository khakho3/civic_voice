import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Static placeholder for a report's location — approximates the approved
/// map-preview visual (street grid + pin + caption) without a real map.
///
/// Google Maps Flutter is an Issue 03 dependency that needs API key /
/// platform setup beyond this screen's scope; swap this for a real
/// `GoogleMap` widget once that's wired up.
class MapPreview extends StatelessWidget {
  const MapPreview({super.key, required this.locationLabel, this.onZoomTap});

  final String locationLabel;
  final VoidCallback? onZoomTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: AppComponentRadius.card,
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _StreetGridPainter(isDark: isDark),
            ),
            const Center(
              child: Icon(
                AppIcons.location,
                size: AppIconSize.lg,
                color: AppColors.primary,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        locationLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ZoomButton(onTap: onZoomTap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: AppRadius.allXs,
      child: InkWell(
        borderRadius: AppRadius.allXs,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(AppIcons.add, size: AppIconSize.sm, color: Colors.white),
        ),
      ),
    );
  }
}

class _StreetGridPainter extends CustomPainter {
  _StreetGridPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = isDark ? AppColorsDark.secondarySurface : AppColorsLight.secondarySurface,
    );

    final linePaint = Paint()
      ..color = (isDark ? AppColorsDark.border : AppColorsLight.border)
      ..strokeWidth = 2;

    for (var x = size.width * 0.15; x < size.width; x += size.width * 0.28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = size.height * 0.25; y < size.height; y += size.height * 0.4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_StreetGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

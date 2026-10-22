import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;

import '../core/theme/app_theme.dart';

/// The shared busy-action indicator (F06): the web searching particle globe
/// adapted to native Canvas for buttons and
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

  /// Long-running clock for continuous particle projection.
  static const Duration period = Duration(minutes: 20);

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
  void initState() {
    super.initState();
    _registerOrbLicense();
  }

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
                widget.trackOpacity ?? 0.7,
            // Reduced motion keeps a static particle globe.
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
    // Native adaptation of thinking-orbs' searching/globe projection and
    // 20px preset. It uses the same rotating particle sphere, not a ring spinner.
    final t =
        (progress?.value ?? 0.0002) *
        BusyIndicator.period.inSeconds *
        1.2 *
        2.665;
    final yaw = t * .5, tilt = .4 + .06 * math.sin(t * .35);
    final radius = size.shortestSide * .41;
    final center = size.center(Offset.zero);
    final scale = math.pow(size.shortestSide / 300, .6).toDouble() * 1.75;
    final dots =
        <({Offset point, double depth, double radius, double alpha})>[];
    for (var ring = 0; ring <= 6; ring++) {
      final lat = -math.pi / 2 + ring / 6 * math.pi;
      final cosLat = math.cos(lat), y = math.sin(lat);
      final count = math.max(1, (cosLat.abs() * 14).round());
      for (var item = 0; item < count; item++) {
        final lon = item / count * 2 * math.pi;
        final x = cosLat * math.cos(lon), z = cosLat * math.sin(lon);
        final x1 = x * math.cos(yaw) + z * math.sin(yaw);
        final z1 = -x * math.sin(yaw) + z * math.cos(yaw);
        final y1 = y * math.cos(tilt) - z1 * math.sin(tilt);
        final z2 = y * math.sin(tilt) + z1 * math.cos(tilt);
        final depth = (z2 + 1) / 2;
        final delta = math.atan2(
          math.sin(lon + yaw - t * 5.702),
          math.cos(lon + yaw - t * 5.702),
        );
        final boost = math.exp(-delta * delta / .18) * math.max(0, z2);
        dots.add((
          point: center + Offset(x1, -y1) * radius,
          depth: depth,
          radius: math.max(.3, (.6 + 1.7 * depth + boost) * scale),
          alpha:
              (trackOpacity + (1 - trackOpacity) * boost) * (.65 + .35 * depth),
        ));
      }
    }
    dots.sort((a, b) => a.depth.compareTo(b.depth));
    for (final dot in dots) {
      canvas.drawCircle(
        dot.point,
        dot.radius,
        Paint()..color = ink.withValues(alpha: ink.a * dot.alpha),
      );
    }
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

// MIT-licensed searching/globe adaptation; keep attribution in app licenses.
bool _orbLicenseRegistered = false;
void _registerOrbLicense() {
  if (_orbLicenseRegistered) return;
  _orbLicenseRegistered = true;
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['thinking-orbs (native searching adaptation)'],
      '''
MIT License

Copyright (c) 2026 Jakub Antalik

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

''',
    );
  });
}

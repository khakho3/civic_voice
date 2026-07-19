import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';

/// Full-screen evidence photo viewer — pinch-to-zoom, a glass circular
/// close button top-left, and a real Share action top-right (the OS share
/// sheet, via `share_plus`).
///
/// Local-file only for now: the only evidence photo currently backed by a
/// real image anywhere in the app is a citizen's own on-device submission
/// (`ReportTrackingScreen`). Every other evidence spot (Municipal Report
/// Review/Progress/Resolution Details, Maintenance Task Details) still
/// shows an honest "no photo yet" placeholder pending real Firebase
/// Storage URLs — see those screens' own placeholder widgets — so there's
/// nothing real to view/share there yet. Wiring a network-image variant in
/// here is a one-line addition once that data exists.
class EvidenceImageViewer extends StatelessWidget {
  const EvidenceImageViewer({super.key, required this.imagePath});

  final String imagePath;

  static Future<void> open(BuildContext context, String imagePath) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            EvidenceImageViewer(imagePath: imagePath),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _share() {
    return SharePlus.instance.share(
      imagePath.startsWith('http')
          ? ShareParams(text: imagePath)
          : ShareParams(files: [XFile(imagePath)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: imagePath.startsWith('http')
                    ? Image.network(imagePath, fit: BoxFit.contain)
                    : Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: SafeArea(
              child: _GlassCircleButton(
                icon: AppIcons.close,
                tooltip: 'Close',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: SafeArea(
              child: _GlassCircleButton(
                icon: AppIcons.share,
                tooltip: 'Share',
                onTap: _share,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlassBlur.medium,
          sigmaY: AppGlassBlur.medium,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: IconButton(
            tooltip: tooltip,
            icon: Icon(icon, color: Colors.white, size: AppIconSize.md),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}

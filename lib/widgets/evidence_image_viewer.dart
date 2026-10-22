import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';

/// Shared evidence gallery: swipe at normal scale, pinch/pan to inspect,
/// and share the currently selected image. Existing single-image calls work.
class EvidenceImageViewer extends StatefulWidget {
  const EvidenceImageViewer({
    super.key,
    required this.imagePath,
    this.imagePaths,
    this.initialIndex = 0,
  });
  final String imagePath;
  final List<String>? imagePaths;
  final int initialIndex;
  static Future<void> open(BuildContext context, String imagePath) =>
      openGallery(context, [imagePath]);
  static Future<void> openGallery(
    BuildContext context,
    List<String> paths, {
    int initialIndex = 0,
  }) {
    if (paths.isEmpty) return Future.value();
    final images = List<String>.unmodifiable(paths);
    final index = initialIndex.clamp(0, images.length - 1);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => EvidenceImageViewer(
          imagePath: images[index],
          imagePaths: images,
          initialIndex: index,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<EvidenceImageViewer> createState() => _EvidenceImageViewerState();
}

class _EvidenceImageViewerState extends State<EvidenceImageViewer> {
  late final List<String> _images = List.unmodifiable(
    widget.imagePaths ?? [widget.imagePath],
  );
  late int _index = widget.initialIndex.clamp(0, _images.length - 1);
  late final PageController _pages = PageController(initialPage: _index);
  final Map<int, TransformationController> _transforms = {};
  bool _zoomed = false;
  TransformationController _transform(int index) =>
      _transforms.putIfAbsent(index, TransformationController.new);
  @override
  void dispose() {
    _pages.dispose();
    for (final controller in _transforms.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _share() async {
    final path = _images[_index];
    await SharePlus.instance.share(
      path.startsWith('http')
          ? ShareParams(text: path)
          : ShareParams(files: [XFile(path)]),
    );
  }

  void _page(int index) {
    _transform(index).value = Matrix4.identity();
    setState(() {
      _index = index;
      _zoomed = false;
    });
  }

  void _move(int index) {
    final duration = AppMotion.duration(context, AppMotionDuration.standard);
    if (duration == Duration.zero) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(index, duration: duration, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _pages,
            itemCount: _images.length,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
            onPageChanged: _page,
            itemBuilder: (context, index) {
              final path = _images[index];
              final transform = _transform(index);
              return InteractiveViewer(
                key: ValueKey('evidence-gallery-page-$index'),
                transformationController: transform,
                minScale: 1,
                maxScale: 4,
                panEnabled: _zoomed,
                onInteractionUpdate: (_) {
                  final zoomed = transform.value.getMaxScaleOnAxis() > 1.01;
                  if (zoomed != _zoomed && index == _index) {
                    setState(() => _zoomed = zoomed);
                  }
                },
                child: Center(
                  child: path.startsWith('http')
                      ? Image.network(
                          path,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const _ImageLoadFailure(),
                        )
                      : Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const _ImageLoadFailure(),
                        ),
                ),
              );
            },
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
        if (_images.length > 1)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous photo',
                    color: Colors.white,
                    disabledColor: Colors.white38,
                    onPressed: _index > 0 ? () => _move(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '${_index + 1} / ${_images.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next photo',
                    color: Colors.white,
                    disabledColor: Colors.white38,
                    onPressed: _index < _images.length - 1
                        ? () => _move(_index + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _ImageLoadFailure extends StatelessWidget {
  const _ImageLoadFailure();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.imageUnavailable, color: Colors.white70),
        SizedBox(height: AppSpacing.sm),
        Text('Image unavailable', style: TextStyle(color: Colors.white70)),
      ],
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

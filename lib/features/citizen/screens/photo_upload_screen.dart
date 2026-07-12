import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/civic_glass_card.dart';
import '../models/photo_upload_view_state.dart';
import '../widgets/civic_app_chrome.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({
    super.key,
    this.initialState = PhotoUploadViewState.uploadComplete,
    this.initialPhotos = const [],
    this.reportTitle,
    this.reportDescription,
    this.reportCategory,
    this.reportLocationLabel,
    this.reportCommunity,
    this.reportLatitude,
    this.reportLongitude,
  });

  static const String routeName = '/citizen/photo-upload';

  final PhotoUploadViewState initialState;
  final List<XFile> initialPhotos;
  final String? reportTitle;
  final String? reportDescription;
  final String? reportCategory;
  final String? reportLocationLabel;
  final String? reportCommunity;
  final double? reportLatitude;
  final double? reportLongitude;

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  static const int _maxPhotos = 5;

  final ImagePicker _picker = ImagePicker();
  late PhotoUploadViewState _state;
  late final List<XFile> _photos;

  bool get _hasPhotos => _photos.isNotEmpty;
  bool get _isBlocked =>
      _state == PhotoUploadViewState.cameraDenied ||
      _state == PhotoUploadViewState.galleryDenied ||
      _state == PhotoUploadViewState.offline;

  @override
  void initState() {
    super.initState();
    _photos = List<XFile>.of(widget.initialPhotos);
    _state = _photos.isEmpty ? PhotoUploadViewState.empty : widget.initialState;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostData());
  }

  Future<void> _recoverLostData() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;

      if (response.exception != null) {
        setState(() => _state = PhotoUploadViewState.uploadFailed);
        return;
      }

      final recovered =
          response.files ?? [if (response.file != null) response.file!];
      if (recovered.isEmpty) return;

      final remaining = _maxPhotos - _photos.length;
      if (remaining <= 0) return;

      setState(() {
        _photos.addAll(recovered.take(remaining));
        _state = PhotoUploadViewState.uploadComplete;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = PhotoUploadViewState.uploadFailed);
    }
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= _maxPhotos) return;
    setState(() => _state = PhotoUploadViewState.cameraPermission);

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (!mounted) return;
      if (photo == null) {
        setState(
          () => _state = _photos.isEmpty
              ? PhotoUploadViewState.empty
              : PhotoUploadViewState.uploadComplete,
        );
        return;
      }
      setState(() {
        _photos.add(photo);
        _state = PhotoUploadViewState.uploadComplete;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _state = PhotoUploadViewState.cameraDenied);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = PhotoUploadViewState.uploadFailed);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_photos.length >= _maxPhotos) return;
    setState(() => _state = PhotoUploadViewState.galleryPermission);

    try {
      final remaining = _maxPhotos - _photos.length;
      final selected = await _picker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1600,
        limit: remaining,
      );
      if (!mounted) return;
      if (selected.isEmpty) {
        setState(
          () => _state = _photos.isEmpty
              ? PhotoUploadViewState.empty
              : PhotoUploadViewState.uploadComplete,
        );
        return;
      }
      setState(() {
        _photos.addAll(selected.take(remaining));
        _state = PhotoUploadViewState.uploadComplete;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _state = PhotoUploadViewState.galleryDenied);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = PhotoUploadViewState.uploadFailed);
    }
  }

  void _removePhoto(XFile photo) {
    setState(() {
      _photos.remove(photo);
      _state = _photos.isEmpty
          ? PhotoUploadViewState.empty
          : PhotoUploadViewState.uploadComplete;
    });
  }

  void _finishReport({required bool skippedPhotos}) {
    final title = widget.reportTitle ?? 'Report';
    final location = widget.reportCommunity ?? widget.reportLocationLabel;
    final photosText = skippedPhotos
        ? 'without photos'
        : '${_photos.length} photos';
    final locationText = location?.isNotEmpty == true ? ' for $location' : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title is ready $photosText$locationText.')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: CivicTopBar(
        title: 'Upload Photos',
        showNotifications: false,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.lg,
                horizontalPadding,
                132,
              ),
              children: [
                const _StepProgress(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Add Photos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Attach clear photos so the municipal team can understand the issue before assigning it.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _ReportSummaryCard(
                  title: widget.reportTitle,
                  category: widget.reportCategory,
                  description: widget.reportDescription,
                  locationLabel: widget.reportLocationLabel,
                  community: widget.reportCommunity,
                  latitude: widget.reportLatitude,
                  longitude: widget.reportLongitude,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PhotoUploadBanner(state: _state),
                _UploadActions(
                  disabled: _isBlocked,
                  uploading: _state == PhotoUploadViewState.uploading,
                  maxReached: _photos.length >= _maxPhotos,
                  onCamera: _takePhoto,
                  onGallery: _pickFromGallery,
                ),
                const SizedBox(height: AppSpacing.xl),
                _UploadedPhotosSection(
                  photos: _photos,
                  maxPhotos: _maxPhotos,
                  onRemovePhoto: _removePhoto,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _PhotoTipsCard(),
                const SizedBox(height: AppSpacing.lg),
                _PhotoActionsCard(
                  enabled: !_isBlocked,
                  hasPhotos: _hasPhotos,
                  onContinue: () => _finishReport(skippedPhotos: false),
                  onSkip: () => _finishReport(skippedPhotos: true),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CivicBottomNav(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Step 4 of 6', style: theme.textTheme.labelLarge),
            const Spacer(),
            Text(
              '65% complete',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: AppFontWeight.semiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.allXl,
          child: LinearProgressIndicator(
            value: 0.65,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({
    required this.title,
    required this.category,
    required this.description,
    required this.locationLabel,
    required this.community,
    required this.latitude,
    required this.longitude,
  });

  final String? title;
  final String? category;
  final String? description;
  final String? locationLabel;
  final String? community;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = latitude != null && longitude != null;
    final cleanTitle = title?.trim();
    final cleanDescription = description?.trim();
    final cleanLocation = locationLabel?.trim();
    final cleanCommunity = community?.trim();

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.reportVerified, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  cleanTitle?.isNotEmpty == true
                      ? cleanTitle!
                      : 'Current report',
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SummaryChip(
                icon: AppIcons.report,
                label: category?.isNotEmpty == true ? category! : 'Category',
              ),
              _SummaryChip(
                icon: hasLocation ? AppIcons.pinned : AppIcons.location,
                label: cleanLocation?.isNotEmpty == true
                    ? cleanLocation!
                    : hasLocation
                    ? 'Selected report location'
                    : 'No GPS yet',
              ),
              if (cleanCommunity?.isNotEmpty == true)
                _SummaryChip(icon: AppIcons.navigate, label: cleanCommunity!),
            ],
          ),
          if (cleanDescription?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              cleanDescription!,
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoUploadBanner extends StatelessWidget {
  const _PhotoUploadBanner({required this.state});

  final PhotoUploadViewState state;

  @override
  Widget build(BuildContext context) {
    final data = switch (state) {
      PhotoUploadViewState.empty => null,
      PhotoUploadViewState.uploadComplete => (
        AppIcons.success,
        AppColors.success,
        'Photos added',
        'Photos are ready for this report.',
      ),
      PhotoUploadViewState.cameraPermission => (
        AppIcons.permissionDenied,
        AppColors.warning,
        'Camera permission required',
        'Allow camera access to take a new report photo.',
      ),
      PhotoUploadViewState.cameraDenied => (
        AppIcons.permissionDenied,
        AppColors.error,
        'Camera access denied',
        'Enable camera permission or choose photos from your gallery.',
      ),
      PhotoUploadViewState.galleryPermission => (
        AppIcons.permissionDenied,
        AppColors.warning,
        'Gallery permission required',
        'Allow gallery access to attach existing photos.',
      ),
      PhotoUploadViewState.galleryDenied => (
        AppIcons.permissionDenied,
        AppColors.error,
        'Gallery access denied',
        'Enable gallery permission or take a new photo.',
      ),
      PhotoUploadViewState.uploading => (
        AppIcons.upload,
        AppColors.primary,
        'Uploading photos',
        'Keep the app open while the photos are added.',
      ),
      PhotoUploadViewState.uploadFailed => (
        AppIcons.uploadFailed,
        AppColors.error,
        'Upload failed',
        'Try again or continue without photos.',
      ),
      PhotoUploadViewState.offline => (
        AppIcons.offline,
        AppColors.warning,
        'You are offline',
        'Photos will be saved with the draft until connection returns.',
      ),
    };

    if (data == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: _InlineState(
        icon: data.$1,
        color: data.$2,
        title: data.$3,
        message: data.$4,
      ),
    );
  }
}

class _UploadActions extends StatelessWidget {
  const _UploadActions({
    required this.disabled,
    required this.uploading,
    required this.maxReached,
    required this.onCamera,
    required this.onGallery,
  });

  final bool disabled;
  final bool uploading;
  final bool maxReached;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final singleColumn = constraints.maxWidth < 340;
          final itemWidth = singleColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - AppSpacing.md) / 2;

          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: itemWidth,
                child: _UploadChoice(
                  icon: AppIcons.camera,
                  title: 'Take Photo',
                  subtitle: maxReached ? 'Maximum reached' : 'Use camera',
                  color: AppColors.primary,
                  disabled: disabled || uploading || maxReached,
                  onTap: onCamera,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _UploadChoice(
                  icon: AppIcons.upload,
                  title: 'Gallery',
                  subtitle: maxReached ? 'Maximum reached' : 'Choose files',
                  color: theme.colorScheme.secondary,
                  disabled: disabled || uploading || maxReached,
                  onTap: onGallery,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UploadChoice extends StatelessWidget {
  const _UploadChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = disabled ? theme.disabledColor : color;

    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: AppRadius.allLg,
        onTap: disabled ? null : onTap,
        child: _DashedBorderBox(
          color: effectiveColor.withValues(alpha: disabled ? 0.28 : 0.55),
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.all(AppSpacing.md),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppIconSize.xl,
                  height: AppIconSize.xl,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: effectiveColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: effectiveColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadedPhotosSection extends StatelessWidget {
  const _UploadedPhotosSection({
    required this.photos,
    required this.maxPhotos,
    required this.onRemovePhoto,
  });

  final List<XFile> photos;
  final int maxPhotos;
  final ValueChanged<XFile> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhotos = photos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Uploaded Photos', style: theme.textTheme.titleLarge),
            const Spacer(),
            Text(
              '${photos.length} / $maxPhotos photos',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: AppFontWeight.semiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (hasPhotos)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 360 ? 2 : 3;
              final gap = AppSpacing.sm * (columns - 1);
              final itemWidth = (constraints.maxWidth - gap) / columns;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final photo in photos)
                    SizedBox(
                      width: itemWidth,
                      child: _PhotoPreview(
                        photo: photo,
                        onRemove: () => onRemovePhoto(photo),
                      ),
                    ),
                ],
              );
            },
          )
        else
          CivicGlassCard(
            child: Row(
              children: [
                const Icon(AppIcons.imageUnavailable),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No photo selected yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: AppRadius.allLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: const Center(child: Icon(AppIcons.imageUnavailable)),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Material(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const SizedBox.square(
                    dimension: 28,
                    child: Icon(AppIcons.close, size: AppIconSize.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTipsCard extends StatelessWidget {
  const _PhotoTipsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tips = [
      'Capture the full issue and nearby landmark.',
      'Keep the photo clear and well lit.',
      'Avoid faces, plates, or private information.',
      'Use more than one angle when helpful.',
    ];

    return CivicGlassCard(
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.info, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Photography Tips', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final tip in tips) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  AppIcons.success,
                  size: AppIconSize.sm,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(tip, style: theme.textTheme.bodySmall)),
              ],
            ),
            if (tip != tips.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PhotoActionsCard extends StatelessWidget {
  const _PhotoActionsCard({
    required this.enabled,
    required this.hasPhotos,
    required this.onContinue,
    required this.onSkip,
  });

  final bool enabled;
  final bool hasPhotos;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: enabled ? onContinue : null,
            icon: const Icon(AppIcons.chevronRight),
            label: Text(hasPhotos ? 'Continue' : 'Continue Without Photos'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: enabled ? onSkip : null,
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderBox extends StatelessWidget {
  const _DashedBorderBox({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: AppRadius.lg),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      );
    final metric = path.computeMetrics().first;
    const dash = 8.0;
    const gap = 6.0;
    var distance = 0.0;

    while (distance < metric.length) {
      final next = distance + dash;
      final end = next > metric.length ? metric.length : next;
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}

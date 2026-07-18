import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';
import '../widgets/civic_glass_card.dart';
import '../services/report_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'report_submitted_screen.dart';

class ReviewReportScreen extends StatelessWidget {
  const ReviewReportScreen({
    super.key,
    this.reportTitle,
    this.reportDescription,
    this.reportCategory,
    this.reportLocationLabel,
    this.reportCommunity,
    this.reportLatitude,
    this.reportLongitude,
    this.reportRegion,
    this.photos = const [],
  });

  static const String routeName = '/citizen/review-report';

  final String? reportTitle;
  final String? reportDescription;
  final String? reportCategory;
  final String? reportLocationLabel;
  final String? reportCommunity;
  final double? reportLatitude;
  final double? reportLongitude;
  final Region? reportRegion;
  final List<XFile> photos;

  Future<void> _submit(BuildContext context) async {
    final report = await ReportCrudService.instance.createReport(
      ReportDraft(
        title: reportTitle ?? '',
        description: reportDescription ?? '',
        category: reportCategory ?? '',
        location: reportLocationLabel ?? '',
        community: reportCommunity ?? '',
        latitude: reportLatitude,
        longitude: reportLongitude,
        region: reportRegion,
        photoPaths: [for (final photo in photos) photo.path],
      ),
    );

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReportSubmittedScreen(
          referenceNumber: report.id,
          reportTitle: reportTitle,
          reportCategory: reportCategory,
          reportLocationLabel: reportLocationLabel,
          photoCount: photos.length,
        ),
      ),
    );
  }

  void _editPreviousStep(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;

    final chromeInset = civicContentPadding(context);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      // See create_report_screen.dart's build() for why this is false and
      // paired with the keyboardVisible-guarded nav below.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                chromeInset.top + AppSpacing.xl,
                horizontalPadding,
                chromeInset.bottom + AppSpacing.xl,
              ),
              children: [
                const _ReviewProgress(),
                const SizedBox(height: AppSpacing.xl),
                _ReportDetailsCard(
                  title: reportTitle,
                  description: reportDescription,
                ),
                const SizedBox(height: AppSpacing.lg),
                _CategoryCard(category: reportCategory),
                const SizedBox(height: AppSpacing.lg),
                _LocationCard(
                  locationLabel: reportLocationLabel,
                  community: reportCommunity,
                  latitude: reportLatitude,
                  longitude: reportLongitude,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PhotosCard(photos: photos),
                const SizedBox(height: AppSpacing.lg),
                _SubmitCard(
                  onSubmit: () => _submit(context),
                  onBack: () => _editPreviousStep(context),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(
              title: 'Review Report',
              showNotifications: false,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 2,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else if (index == 1) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      CitizenReportsScreen.routeName,
                      (route) => route.isFirst,
                    );
                  } else if (index == 3) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      CitizenAlertsScreen.routeName,
                      (route) => route.isFirst,
                    );
                  } else if (index == 4) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      CitizenProfileScreen.routeName,
                      (route) => route.isFirst,
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step 5 of 6',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: AppFontWeight.semiBold,
              ),
            ),
            const Spacer(),
            Text(
              '85% complete',
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
            value: 0.85,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ReportDetailsCard extends StatelessWidget {
  const _ReportDetailsCard({required this.title, required this.description});

  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanTitle = _clean(title);
    final cleanDescription = _clean(description);

    return _ReviewCard(
      icon: AppIcons.reportVerified,
      title: 'Report Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cleanTitle.isEmpty ? 'Untitled report' : cleanTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          if (cleanDescription.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(cleanDescription, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanCategory = _clean(category);

    return _ReviewCard(
      icon: AppIcons.report,
      title: 'Category (Auto-detected)',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppRadius.allLg,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          cleanCategory.isEmpty ? 'Not detected' : cleanCategory,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.locationLabel,
    required this.community,
    required this.latitude,
    required this.longitude,
  });

  final String? locationLabel;
  final String? community;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanLocation = _clean(locationLabel);
    final cleanCommunity = _clean(community);
    final hasCoordinates = latitude != null && longitude != null;
    final target = hasCoordinates ? LatLng(latitude!, longitude!) : null;

    return _ReviewCard(
      icon: AppIcons.location,
      title: 'Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.allLg,
            ),
            child: target == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.pinned, color: AppColors.primary),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Map preview appears after GPS capture',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('review-location'),
                        position: target,
                      ),
                    },
                    liteModeEnabled: true,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoLine(
            icon: AppIcons.pinned,
            text: cleanLocation.isEmpty
                ? 'Current GPS location selected'
                : cleanLocation,
          ),
          if (cleanCommunity.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(icon: AppIcons.navigate, text: cleanCommunity),
          ],
          if (hasCoordinates) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(
              icon: AppIcons.myLocation,
              text:
                  '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.photos});

  final List<XFile> photos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ReviewCard(
      icon: AppIcons.camera,
      title: 'Photos',
      trailingText: '${photos.length}',
      child: photos.isEmpty
          ? const _InfoLine(
              icon: AppIcons.imageUnavailable,
              text: 'No photos attached.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 340 ? 2 : 3;
                final gap = AppSpacing.sm * (columns - 1);
                final itemWidth = (constraints.maxWidth - gap) / columns;

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final photo in photos)
                      SizedBox(
                        width: itemWidth,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: AppRadius.allLg,
                            child: Image.file(
                              File(photo.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  ColoredBox(
                                    color:
                                        theme.colorScheme.surfaceContainerLow,
                                    child: const Center(
                                      child: Icon(AppIcons.imageUnavailable),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SubmitCard extends StatelessWidget {
  const _SubmitCard({required this.onSubmit, required this.onBack});

  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ready to submit',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your report will be sent to the civic team for review.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(AppIcons.statusSubmitted),
            label: const Text('Submit Report'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onBack,
            child: const Text('Back to Photos'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
              if (trailingText != null) _CountBadge(label: trailingText!),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.allLg,
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: AppIconSize.md),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

String _clean(String? value) => value?.trim() ?? '';

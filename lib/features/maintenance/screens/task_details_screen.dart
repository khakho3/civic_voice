import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/detail_header.dart';
import '../../../widgets/evidence_image_viewer.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';

/// MNT-003 — Maintenance Team Task Details.
///
/// A drill-down reached by tapping a task on Dashboard or Assigned Tasks —
/// same shape as Municipal Officer's own report-handling screens
/// (`MunicipalDetailHeader`, no persistent bottom nav) rather than the
/// 3-tab `NavigationBar` this screen previously kept pinned on itself
/// alongside every other screen in this flow (Update Progress, Task
/// Completed), none of which are tab roots.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({
    super.key,
    required this.task,
    this.onBack,
    this.onUpdateProgress,
  });

  final MaintenanceTask task;
  final VoidCallback? onBack;
  final VoidCallback? onUpdateProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _TaskDetailsContent(
              task: task,
              onUpdateProgress: onUpdateProgress,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: task.title,
              onBack: onBack,
              trailing: Chip(label: Text('#${task.id}')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailsContent extends StatelessWidget {
  const _TaskDetailsContent({
    required this.task,
    required this.onUpdateProgress,
  });

  final MaintenanceTask task;
  final VoidCallback? onUpdateProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final team = MaintenanceTaskDirectory.instance.teamForTask(task);
    final canUpdate =
        task.status != MaintenanceTaskStatus.completed &&
        task.status != MaintenanceTaskStatus.failed;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        DetailHeader.topInset(context) + AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TintedBadge(
                label: task.status.label,
                color: task.status.color,
                textColor: task.status.badgeTextColor(brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                AppIcons.team,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  task.teamName ?? team?.name ?? 'Unassigned team',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Problem Description', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Text(
              task.description.trim().isEmpty
                  ? 'No additional description was provided by the reporter.'
                  : task.description,
              style: textTheme.bodyMedium?.copyWith(
                color: task.description.trim().isEmpty
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
                fontWeight: task.description.trim().isEmpty
                    ? AppFontWeight.regular
                    : AppFontWeight.semiBold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(
                AppIcons.camera,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Report Photos (${task.reportPhotoCount})',
                style: textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (task.reportPhotoUrls.isEmpty)
            const _NoReportPhotos()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 4 / 3,
              ),
              itemCount: task.reportPhotoUrls.length,
              itemBuilder: (_, index) =>
                  _ReportPhotoTile(url: task.reportPhotoUrls[index]),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(
                AppIcons.pinned,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Problem Location', style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProblemLocationMap(task: task),
          const SizedBox(height: AppSpacing.lg),
          Text('Task Timeline', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _StatusPipeline(task: task),
          const SizedBox(height: AppSpacing.lg),
          if (canUpdate)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpdateProgress,
                icon: const Icon(AppIcons.edit),
                label: const Text('Update Progress'),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: AppComponentRadius.card,
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.permissionDenied,
                    size: AppIconSize.md,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      task.status == MaintenanceTaskStatus.completed
                          ? 'This task is completed and read-only.'
                          : 'This task was marked failed and is read-only.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Three steps derived from [MaintenanceTask.status] — replacing the
/// previous hardcoded three-step pipeline with fixed fake timestamps that
/// always showed "Work in progress" as the active step regardless of the
/// task's real status (even for a completed or failed task).
class _StatusPipeline extends StatelessWidget {
  const _StatusPipeline({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final status = task.status;
    final dispatched = status != MaintenanceTaskStatus.assigned;
    final resolved =
        status == MaintenanceTaskStatus.completed ||
        status == MaintenanceTaskStatus.failed;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PipelineStep(
            label: 'Assignment received by maintenance team',
            timestamp: 'Logged',
            color: semantic.success,
            icon: AppIcons.statusResolved,
            isActive: false,
          ),
          _PipelineStep(
            label: 'Crew dispatched to site',
            timestamp: dispatched ? 'Dispatched' : task.eta,
            color: dispatched ? semantic.success : AppColors.statusAssigned,
            icon: dispatched
                ? AppIcons.statusResolved
                : AppIcons.statusAssigned,
            isActive: !dispatched,
          ),
          _PipelineStep(
            label: status == MaintenanceTaskStatus.failed
                ? 'Work attempted'
                : 'Work in progress',
            timestamp: resolved ? 'Complete' : 'Current field status',
            color: resolved ? semantic.success : AppColors.statusInProgress,
            icon: resolved ? AppIcons.statusResolved : AppIcons.activityPulse,
            isActive: dispatched && !resolved,
            isLast: !resolved,
          ),
          if (resolved)
            _PipelineStep(
              label: status == MaintenanceTaskStatus.completed
                  ? 'Task completed'
                  : 'Task marked failed',
              timestamp: task.completedAtLabel ?? 'Just now',
              color: status == MaintenanceTaskStatus.completed
                  ? semantic.success
                  : semantic.error,
              icon: status == MaintenanceTaskStatus.completed
                  ? AppIcons.statusResolved
                  : AppIcons.statusRejected,
              isActive: true,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.label,
    required this.timestamp,
    required this.color,
    required this.icon,
    required this.isActive,
    this.isLast = false,
  });

  final String label;
  final String timestamp;
  final Color color;
  final IconData icon;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: AppIconSize.md, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: AppDimensions.borderWidthFocused,
                    color: colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isActive ? color : colorScheme.onSurface,
                      fontWeight: isActive
                          ? AppFontWeight.semiBold
                          : AppFontWeight.regular,
                    ),
                  ),
                  Text(
                    timestamp,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPhotoTile extends StatelessWidget {
  const _ReportPhotoTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('maintenance-report-photo-$url'),
          onTap: () => EvidenceImageViewer.open(context, url),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes == null
                          ? null
                          : progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!,
                    ),
                  ),
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                AppIcons.imageUnavailable,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoReportPhotos extends StatelessWidget {
  const _NoReportPhotos();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          Icon(AppIcons.imageUnavailable, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'The reporter did not attach any photos.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemLocationMap extends StatefulWidget {
  const _ProblemLocationMap({required this.task});

  final MaintenanceTask task;

  @override
  State<_ProblemLocationMap> createState() => _ProblemLocationMapState();
}

class _ProblemLocationMapState extends State<_ProblemLocationMap> {
  /// Apple Maps' web URL doubles as a universal link — iOS offers its
  /// native "Open in ..." chooser for it when other maps apps (Google
  /// Maps, etc.) are installed and registered as handlers, rather than
  /// forcing Apple Maps specifically. Android has no equivalent universal
  /// link, but a bare `geo:` URI is handled the same way by whichever
  /// map app(s) declare themselves a handler for it — straight to Google
  /// Maps on the common case of just one being installed.
  Future<void> _openInMaps(BuildContext context) async {
    final task = widget.task;
    final label = Uri.encodeComponent(task.locationLabel);
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse(
            'https://maps.apple.com/?ll=${task.latitude},${task.longitude}&q=$label',
          )
        : Uri.parse(
            'geo:${task.latitude},${task.longitude}?q=${task.latitude},${task.longitude}($label)',
          );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open a maps app on this device.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = LatLng(task.latitude, task.longitude);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 176,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: AppRadius.radiusMd),
            ),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: target,
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('maintenance-report-location'),
                      position: target,
                      infoWindow: InfoWindow(title: task.locationLabel),
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
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ReportLocationMapScreen(task: task),
                      ),
                    ),
                    icon: const Icon(AppIcons.navigate),
                    label: const Text('View Map'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      AppIcons.location,
                      size: AppIconSize.md,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.locationLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: AppFontWeight.semiBold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Read-only report location from live report data.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(context),
                    icon: const Icon(AppIcons.navigate),
                    label: const Text('Open in Maps'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportLocationMapScreen extends StatelessWidget {
  const _ReportLocationMapScreen({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = LatLng(task.latitude, task.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Location'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Chip(label: Text('Read only')),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 17),
            markers: {
              Marker(
                markerId: const MarkerId('maintenance-report-location-full'),
                position: target,
                infoWindow: InfoWindow(
                  title: task.locationLabel,
                  snippet: 'Report pin',
                ),
              ),
            },
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.location,
                        size: AppIconSize.md,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.locationLabel,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: AppFontWeight.semiBold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${task.latitude.toStringAsFixed(5)}, '
                              '${task.longitude.toStringAsFixed(5)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

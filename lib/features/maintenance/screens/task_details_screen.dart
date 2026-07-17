import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

/// MNT-003 — Maintenance Team Task Details.
class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTasks,
    this.onNavigateToProfile,
    this.onUpdateProgress,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onUpdateProgress;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  AppScreenState _state = AppScreenState.success;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.maybeOf(context)?.pop(),
        ),
        title: const Text('Task Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Chip(label: const Text('#TASK-8821')),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            widget.onNavigateToDashboard?.call();
          } else if (index == 1) {
            widget.onNavigateToTasks?.call();
          } else if (index == 2) {
            widget.onNavigateToProfile?.call();
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.error:
        return _ErrorView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.offline:
        return _OfflineView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.permission:
        return _PermissionView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.disabled:
      case AppScreenState.success:
        return _TaskDetailsContent(
          disabled: _state == AppScreenState.disabled,
          onUpdateProgress: widget.onUpdateProgress,
        );
    }
  }
}

class _TaskDetailsContent extends StatelessWidget {
  const _TaskDetailsContent({
    required this.disabled,
    required this.onUpdateProgress,
  });

  final bool disabled;
  final VoidCallback? onUpdateProgress;

  static const _TaskReportDetails _report = _TaskReportDetails(
    title: 'Broken Street Light',
    description:
        'Light flickers and creates safety hazard for pedestrians and vehicles at night.',
    locationLabel: '242 Main Avenue, Central District',
    latitude: 6.5244,
    longitude: 3.3792,
    photoUrls: [],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final firstPhotoUrl = _report.photoUrls.isNotEmpty
        ? _report.photoUrls[0]
        : null;
    final secondPhotoUrl = _report.photoUrls.length > 1
        ? _report.photoUrls[1]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(_report.title, style: textTheme.headlineSmall),
                ),
                const SizedBox(width: AppSpacing.sm),
                _PriorityBadge(color: semantic.error),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusBadge(
              label: 'Assigned',
              color: AppColors.statusAssigned,
              icon: AppIcons.statusAssigned,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Problem Description', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _report.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: AppFontWeight.semiBold,
                  ),
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
                Text('Report Photos', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _ReportPhotoTile(imageUrl: firstPhotoUrl)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _ReportPhotoTile(imageUrl: secondPhotoUrl)),
              ],
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
            _ProblemLocationMap(report: _report),
            const SizedBox(height: AppSpacing.lg),
            Text('Task Timeline', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            const _StatusPipeline(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: disabled ? null : onUpdateProgress,
                icon: const Icon(AppIcons.edit),
                label: const Text('Update Progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPipeline extends StatelessWidget {
  const _StatusPipeline();

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PipelineStep(
              label: 'Assignment received by maintenance team',
              timestamp: 'Oct 12, 12:05 PM',
              color: semantic.success,
              icon: AppIcons.statusResolved,
              isActive: false,
            ),
            _PipelineStep(
              label: 'Crew dispatched to site',
              timestamp: 'Oct 12, 12:30 PM',
              color: semantic.success,
              icon: AppIcons.statusResolved,
              isActive: false,
            ),
            _PipelineStep(
              label: 'Work in progress',
              timestamp: 'Current field status',
              color: AppColors.statusInProgress,
              icon: AppIcons.statusInProgress,
              isActive: true,
              isLast: true,
            ),
          ],
        ),
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

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        'High Priority',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ReportPhotoTile extends StatelessWidget {
  const _ReportPhotoTile({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: AppComponentRadius.card,
        ),
        child: imageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.camera, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Live report photo',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.imageUnavailable,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Photo unavailable',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProblemLocationMap extends StatelessWidget {
  const _ProblemLocationMap({required this.report});

  final _TaskReportDetails report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = LatLng(report.latitude, report.longitude);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 176,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: AppRadius.radiusMd,
              ),
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
                      infoWindow: InfoWindow(title: report.locationLabel),
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
                        builder: (_) =>
                            _ReportLocationMapScreen(report: report),
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
            child: Row(
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
                        report.locationLabel,
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
          ),
        ],
      ),
    );
  }
}

class _ReportLocationMapScreen extends StatelessWidget {
  const _ReportLocationMapScreen({required this.report});

  final _TaskReportDetails report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = LatLng(report.latitude, report.longitude);

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
                  title: report.locationLabel,
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
                              report.locationLabel,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: AppFontWeight.semiBold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${report.latitude.toStringAsFixed(5)}, '
                              '${report.longitude.toStringAsFixed(5)}',
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

class _TaskReportDetails {
  const _TaskReportDetails({
    required this.title,
    required this.description,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.photoUrls,
  });

  final String title;
  final String description;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final List<String> photoUrls;
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading task details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Syncing issue information, photos, map, and timeline.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: AppIconSize.xl, color: semantic.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load task',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try again without changing the maintenance workflow.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.error),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.offline,
              size: AppIconSize.xl,
              color: semantic.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reconnect to update progress or load evidence.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.warning),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.permissionDenied,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Permission required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maintenance access is required to view this assigned task.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.empty,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No task details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No assigned task information is available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

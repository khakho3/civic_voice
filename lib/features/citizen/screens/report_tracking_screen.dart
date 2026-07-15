import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/civic_glass_card.dart';
import '../models/civic_report.dart';
import '../services/report_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';

class ReportTrackingScreen extends StatelessWidget {
  const ReportTrackingScreen({
    super.key,
    required this.reportId,
  });

  static const String routeName = '/citizen/report-tracking';

  final String reportId;

  CivicReport? _findReport(List<CivicReport> reports) {
    for (final report in reports) {
      if (report.id == reportId) return report;
    }
    return null;
  }

  void _openDashboard(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenReportsScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openCreateReport(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CreateReportScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openAlerts(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenAlertsScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenProfileScreen.routeName,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;

    return Scaffold(
      extendBody: true,
      appBar: CivicTopBar(
        title: 'Track Report',
        showNotifications: false,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<CivicReport?>(
          stream: ReportCrudService.instance.watchReport(reportId),
          initialData: _findReport(ReportCrudService.instance.reports.value),
          builder: (context, snapshot) {
            final report = snapshot.data;

            if (report == null) {
              return _MissingReportState(
                horizontalPadding: horizontalPadding,
                onReports: () => _openReports(context),
              );
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                132,
              ),
              children: [
                _ReportSummaryCard(report: report),
                const SizedBox(height: AppSpacing.md),
                _CurrentStatusCard(report: report),
                const SizedBox(height: AppSpacing.md),
                _TrackingProgress(report: report),
                const SizedBox(height: AppSpacing.lg),
                _LatestUpdateCard(report: report),
                const SizedBox(height: AppSpacing.lg),
                _TrackingDetails(report: report),
                const SizedBox(height: AppSpacing.lg),
                _TrackingLocation(report: report),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CivicBottomNav(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            _openDashboard(context);
          } else if (index == 1) {
            _openReports(context);
          } else if (index == 2) {
            _openCreateReport(context);
          } else if (index == 3) {
            _openAlerts(context);
          } else if (index == 4) {
            _openProfile(context);
          }
        },
      ),
    );
  }
}

double _statusProgress(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => 0.25,
    ReportStatus.underReview => 0.5,
    ReportStatus.inProgress => 0.8,
    ReportStatus.resolved => 1,
  };
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = report.status.color(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppIconSize.xl,
                height: AppIconSize.xl,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.allLg,
                ),
                child: Icon(report.status.icon, color: statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      report.id,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusPill(status: report.status),
          const SizedBox(height: AppSpacing.md),
          _InfoLine(icon: AppIcons.location, label: report.location),
          const SizedBox(height: AppSpacing.sm),
          _InfoLine(
            icon: AppIcons.calendar,
            label: 'Submitted ${report.timeLabel}',
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allLg,
      backgroundColor: theme.colorScheme.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.allMd,
            ),
            child: const Icon(AppIcons.report, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  report.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  report.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SmallStatusPill(status: report.status),
        ],
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = report.status.color(context);
    final progress = _statusProgress(report.status);
    final percent = (progress * 100).round();

    return CivicGlassCard(
      borderRadius: AppRadius.allLg,
      backgroundColor: theme.colorScheme.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT STATUS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: AppFontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(report.status.icon, size: AppIconSize.sm, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  report.status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.allXl,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingProgress extends StatelessWidget {
  const _TrackingProgress({required this.report});

  final CivicReport report;

  static const List<ReportStatus> _steps = [
    ReportStatus.submitted,
    ReportStatus.underReview,
    ReportStatus.inProgress,
    ReportStatus.resolved,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(report.status);
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allLg,
      backgroundColor: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service progress timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < _steps.length; index++)
            _TimelineStep(
              status: _steps[index],
              complete: index <= currentIndex,
              active: index == currentIndex,
              isLast: index == _steps.length - 1,
              report: report,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.complete,
    required this.active,
    required this.isLast,
    required this.report,
  });

  final ReportStatus status;
  final bool complete;
  final bool active;
  final bool isLast;
  final CivicReport report;

  String get _title {
    return switch (status) {
      ReportStatus.submitted => 'Report submitted',
      ReportStatus.underReview => 'Under review',
      ReportStatus.inProgress => 'Assigned',
      ReportStatus.resolved => 'Resolved',
    };
  }

  String get _message {
    return switch (status) {
      ReportStatus.submitted =>
        'Reference ${report.id} was received by CivicVoice.',
      ReportStatus.underReview =>
        'The municipality confirmed the report details and location.',
      ReportStatus.inProgress =>
        'Field team assignment created for repair work.',
      ReportStatus.resolved => 'The repair is complete and the report is closed.',
    };
  }

  String get _time {
    if (!complete) return 'Not started';
    return switch (status) {
      ReportStatus.submitted => '09 Jul, 08:42',
      ReportStatus.underReview => '09 Jul, 10:15',
      ReportStatus.inProgress => '09 Jul, 12:30',
      ReportStatus.resolved => 'Not started',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status.color(context);
    final mutedColor = theme.colorScheme.outline;
    final dotColor = complete ? color : mutedColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: complete ? 0.12 : 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 2),
                ),
                child: Icon(status.icon, size: AppIconSize.sm, color: dotColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: dotColor.withValues(alpha: complete ? 0.28 : 0.16),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Opacity(
              opacity: complete ? 1 : 0.48,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SmallStatusPill(status: status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: AppFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestUpdateCard extends StatelessWidget {
  const _LatestUpdateCard({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updateText = switch (report.status) {
      ReportStatus.submitted =>
        'Your report was received and is waiting for review.',
      ReportStatus.underReview =>
        'The report details are being verified by the civic team.',
      ReportStatus.inProgress =>
        'Public Works started repair work for this report.',
      ReportStatus.resolved =>
        'The report has been resolved and closed.',
    };

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      backgroundColor: theme.colorScheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.xl,
            height: AppIconSize.xl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.allLg,
            ),
            child: const Icon(AppIcons.refresh, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest update',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  updateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  report.timeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: AppFontWeight.semiBold,
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

class _TrackingDetails extends StatelessWidget {
  const _TrackingDetails({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Category', value: report.category),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Community', value: report.community),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Photos', value: '${report.photoCount} attached'),
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingLocation extends StatelessWidget {
  const _TrackingLocation({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = report.latitude != null && report.longitude != null;

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.allLg,
            child: SizedBox(
              height: 160,
              child: hasCoordinates
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(report.latitude!, report.longitude!),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(report.id),
                          position: LatLng(report.latitude!, report.longitude!),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      alignment: Alignment.center,
                      child: const Icon(
                        AppIcons.pinned,
                        color: AppColors.primary,
                        size: AppIconSize.lg,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoLine(icon: AppIcons.location, label: report.location),
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final message = switch (report.status) {
      ReportStatus.submitted =>
        'Your report is waiting for review by the civic team.',
      ReportStatus.underReview =>
        'The responsible team is checking the report details.',
      ReportStatus.inProgress =>
        'Work is active. You will receive updates when progress changes.',
      ReportStatus.resolved =>
        'This report has been resolved. Thank you for improving the community.',
    };

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.xl,
            height: AppIconSize.xl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.allLg,
            ),
            child: const Icon(AppIcons.info, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What happens next',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.allXl,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  const _SmallStatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label.isEmpty ? 'Not provided' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: AppFontWeight.semiBold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingReportState extends StatelessWidget {
  const _MissingReportState({
    required this.horizontalPadding,
    required this.onReports,
  });

  final double horizontalPadding;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.xl,
        horizontalPadding,
        132,
      ),
      children: [
        CivicGlassCard(
          borderRadius: AppRadius.allXl,
          child: Column(
            children: [
              const Icon(
                AppIcons.empty,
                color: AppColors.primary,
                size: AppIconSize.xl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Report not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This report is not available in local CRUD yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onReports,
                child: const Text('Back to Reports'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

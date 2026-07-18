import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/report_progress_data.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/kebab_menu_button.dart';
import '../widgets/municipal_detail_header.dart';
import '../widgets/officer_contact_row.dart';
import '../../../widgets/status_badge.dart';

/// MUN-007 — Report Progress.
///
/// Approved states (Figma "07 - Report Progress" section): Default,
/// Loading, Missing Evidence, Success, Offline.
///
/// Missing Evidence isn't a separate content shape so much as a substate of
/// Default (zero evidence photos uploaded, which blocks "Mark Resolved") —
/// both share [_ProgressBody], differing only in `evidenceCount`, the same
/// pattern Verification/Report Review use for their own state families.
///
/// Reached only from MUN-006 Active Reports (a report already past
/// triage/assignment), never from Inbox, so unlike Report Review/
/// Verification/Assign Team there's no separate "return to Dashboard"
/// concept to distinguish from the header back arrow — both just pop back
/// to Active Reports.
enum MunicipalReportProgressViewState {
  loading,
  loaded,
  missingEvidence,
  success,
  offline,
}

class MunicipalReportProgressScreen extends StatefulWidget {
  const MunicipalReportProgressScreen({
    super.key,
    this.referenceId = 'REQ-8421',
    this.status = ReportStatus.inProgress,
    this.initialState = MunicipalReportProgressViewState.loaded,
    this.onBack,
  });

  final String referenceId;
  final ReportStatus status;
  final MunicipalReportProgressViewState initialState;

  /// Pops one level — wired to the header's back arrow and to Success's
  /// "Return to Active Reports" action (see the class doc comment for why
  /// those are the same callback here).
  final VoidCallback? onBack;

  @override
  State<MunicipalReportProgressScreen> createState() =>
      _MunicipalReportProgressScreenState();
}

class _MunicipalReportProgressScreenState
    extends State<MunicipalReportProgressScreen> {
  late MunicipalReportProgressViewState _state = widget.initialState;
  final ReportProgressData _data = ReportProgressData.mock();
  late int _evidenceCount =
      widget.initialState == MunicipalReportProgressViewState.missingEvidence
      ? 0
      : _data.caseSummary.evidencePhotoCount;
  final _timelineKey = GlobalKey();

  bool get _canResolve => _evidenceCount > 0;

  void _addEvidencePhoto() {
    setState(() => _evidenceCount++);
  }

  void _markResolved() {
    setState(() => _state = MunicipalReportProgressViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalReportProgressViewState.success);
      }
    });
  }

  void _retrySync() {
    setState(() => _state = MunicipalReportProgressViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalReportProgressViewState.loaded);
      }
    });
  }

  void _scrollToTimeline() {
    final timelineContext = _timelineKey.currentContext;
    if (timelineContext == null) return;
    Scrollable.ensureVisible(
      timelineContext,
      duration: AppMotion.duration(context, AppMotionDuration.moderate),
      curve: AppMotionCurve.standard,
    );
  }

  Future<void> _shareSummary() {
    return SharePlus.instance.share(
      ShareParams(
        text:
            'Case ${_data.referenceId} — ${_data.title}\n'
            'District: ${_data.districtLabel}\n'
            'Officer: ${_data.officerName}\n'
            'Status: ${_data.completionPercent}% complete\n'
            'Latest update (${_data.latestUpdateTeam}, '
            '${_data.latestUpdateTimeAgo}): ${_data.latestUpdateNote}',
        subject: 'CivicVoice case ${_data.referenceId} — progress',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showActionBar = _state != MunicipalReportProgressViewState.success;
    // widget.status is fixed at whatever it was when this screen opened —
    // it doesn't track _state, so without this the header would keep
    // showing e.g. "In Progress" even after the report's actually been
    // marked Resolved.
    final effectiveStatus = _state == MunicipalReportProgressViewState.success
        ? ReportStatus.resolved
        : widget.status;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: MunicipalDetailHeader.topInset(context)),
                  if (_state == MunicipalReportProgressViewState.offline)
                    const _OfflineBanner(),
                  Expanded(
                    child: switch (_state) {
                      MunicipalReportProgressViewState.loading =>
                        const _LoadingSkeleton(),
                      MunicipalReportProgressViewState.loaded ||
                      MunicipalReportProgressViewState.missingEvidence ||
                      MunicipalReportProgressViewState.offline => _ProgressBody(
                        data: _data,
                        evidenceCount: _evidenceCount,
                        cached:
                            _state == MunicipalReportProgressViewState.offline,
                        timelineKey: _timelineKey,
                        onAddEvidence: _addEvidencePhoto,
                        onRetrySync: _retrySync,
                      ),
                      MunicipalReportProgressViewState.success => _SuccessBody(
                        data: _data,
                        onReturnToActiveReports: widget.onBack,
                        onShareSummary: _shareSummary,
                      ),
                    },
                  ),
                  if (showActionBar)
                    _ActionBar(
                      canResolve: _canResolve,
                      onResolve: _markResolved,
                      onViewTimeline: _scrollToTimeline,
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: 'Report Progress',
              referenceId: widget.referenceId,
              onBack: widget.onBack,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReportStatusBadge(status: effectiveStatus),
                  KebabMenuButton<void>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: _shareSummary,
                        child: const Text('Share Summary'),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Offline banner
// ---------------------------------------------------------------------------

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    // Amber rather than the error-red used elsewhere (Report Review/
    // Verification/Assign Team/Active Reports): those banners mean "you're
    // disconnected and some actions are blocked," but this screen's offline
    // handling is deliberately non-blocking — the report stays fully
    // interactive and local changes just queue for sync (see the Sync
    // Pending card below), which reads as a lower-severity, warning-level
    // notice rather than a connectivity error.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            AppIcons.offline,
            size: AppIconSize.sm,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Offline Mode — Showing cached data from 12 mins ago',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (Loaded / Missing Evidence / Offline share this)
// ---------------------------------------------------------------------------

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.data,
    required this.evidenceCount,
    required this.cached,
    required this.timelineKey,
    required this.onAddEvidence,
    required this.onRetrySync,
  });

  final ReportProgressData data;
  final int evidenceCount;
  final bool cached;
  final GlobalKey timelineKey;
  final VoidCallback onAddEvidence;
  final VoidCallback onRetrySync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _SummaryCard(data: data),
        if (evidenceCount == 0) ...[
          const SizedBox(height: AppSpacing.md),
          _EvidenceRequiredCard(onUpload: onAddEvidence),
          const SizedBox(height: AppSpacing.md),
          _VisualEvidenceCard(
            photoCount: evidenceCount,
            onAddPhoto: onAddEvidence,
          ),
        ],
        if (cached) ...[
          const SizedBox(height: AppSpacing.md),
          _SyncPendingCard(
            pendingCount: data.cachedActivity.length,
            onRetry: onRetrySync,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _StatusTimelineCard(key: timelineKey, data: data),
        if (cached) ...[
          const SizedBox(height: AppSpacing.md),
          _RecentActivityCard(entries: data.cachedActivity),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final ReportProgressData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status already shows permanently in the header directly above
          // this card — repeating it here would be pure duplication, not a
          // second useful data point.
          Text(
            'REPORT ${data.referenceId}',
            style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
          ),
          const SizedBox(height: 2),
          Text(data.title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.location,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(data.districtLabel, style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OfficerContactRow(
            officerName: data.officerName,
            officerPhone: data.officerPhone,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Completion', style: textTheme.labelSmall),
              const Spacer(),
              Text('${data.completionPercent}%', style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: AppRadius.allXs,
            child: LinearProgressIndicator(
              value: data.completionPercent / 100,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRequiredCard extends StatelessWidget {
  const _EvidenceRequiredCard({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.warning,
                size: AppIconSize.md,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Evidence Required', style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Evidence must be uploaded before this report can be marked as '
            'resolved. This is a mandatory safety requirement.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(AppIcons.upload, size: AppIconSize.sm + 2),
            label: const Text('Upload Evidence'),
          ),
        ],
      ),
    );
  }
}

class _VisualEvidenceCard extends StatelessWidget {
  const _VisualEvidenceCard({
    required this.photoCount,
    required this.onAddPhoto,
  });

  final int photoCount;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Visual Evidence', style: textTheme.titleSmall),
              const Spacer(),
              Text('$photoCount Photos', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: onAddPhoto,
            borderRadius: AppComponentRadius.inputField,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: AppComponentRadius.inputField,
              ),
              child: Column(
                children: [
                  Icon(
                    AppIcons.add,
                    size: AppIconSize.md,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text('Add Photo', style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncPendingCard extends StatelessWidget {
  const _SyncPendingCard({required this.pendingCount, required this.onRetry});

  final int pendingCount;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.sync,
              size: AppIconSize.md,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Sync Pending', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You have $pendingCount local updates waiting to be uploaded.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refresh, size: AppIconSize.sm + 2),
            label: const Text('Retry Now'),
          ),
        ],
      ),
    );
  }
}

class _StatusTimelineCard extends StatelessWidget {
  const _StatusTimelineCard({super.key, required this.data});

  final ReportProgressData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Status Timeline', style: textTheme.titleSmall),
              const Spacer(),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final step in data.timeline) ...[
            _TimelineStepRow(step: step),
            if (step != data.timeline.last)
              const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: AppComponentRadius.inputField,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.latestUpdateTimeAgo,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('·', style: textTheme.labelSmall),
                    const SizedBox(width: 4),
                    Text(
                      data.latestUpdateTeam,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _NewBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(data.latestUpdateNote, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        'LIVE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.success,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.allXs,
      ),
      child: Text(
        'NEW',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({required this.step});

  final ProgressTimelineStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = step.isCurrent ? AppColors.primary : AppColors.success;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            step.isCurrent ? AppIcons.statusInProgress : AppIcons.success,
            size: AppIconSize.sm,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.label,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(step.timestamp, style: textTheme.bodySmall),
                ],
              ),
              Text(step.description, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.entries});

  final List<ActivityLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Activity', style: textTheme.titleSmall),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '(Cached)',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          for (final entry in entries) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  entry.timeAgo,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Text('·', style: textTheme.labelSmall),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(entry.description, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success
// ---------------------------------------------------------------------------

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.data,
    this.onReturnToActiveReports,
    this.onShareSummary,
  });

  final ReportProgressData data;
  final VoidCallback? onReturnToActiveReports;
  final VoidCallback? onShareSummary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 0),
          alignment: Alignment.center,
          child: const Icon(
            AppIcons.success,
            size: AppIconSize.lg,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Report Resolved Successfully',
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The civic issue has been addressed and verified by the '
          'assigned team.',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onReturnToActiveReports,
            child: const Text('Return to Active Reports'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onShareSummary,
            child: const Text('Share Summary'),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _CaseSummaryCard(summary: data.caseSummary),
      ],
    );
  }
}

class _CaseSummaryCard extends StatelessWidget {
  const _CaseSummaryCard({required this.summary});

  final CaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CASE ${summary.referenceId}',
                  style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
                ),
              ),
              ReportStatusBadge(status: ReportStatus.resolved),
            ],
          ),
          const SizedBox(height: 2),
          Text(summary.title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _LabeledValue(
            label: 'RESOLUTION DATE',
            value: summary.resolutionDate,
          ),
          const SizedBox(height: AppSpacing.sm),
          _LabeledValue(label: 'REPORTER', value: summary.reporterName),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Visual Evidence', style: textTheme.titleSmall),
              const Spacer(),
              Text(
                '${summary.evidencePhotoCount} Photos',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < summary.evidencePhotoCount; i++) ...[
                Expanded(child: _EvidenceThumbnail()),
                if (i != summary.evidencePhotoCount - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96)),
        const SizedBox(height: 2),
        Text(value, style: textTheme.titleSmall),
      ],
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppComponentRadius.inputField,
        ),
        child: Icon(
          AppIcons.camera,
          size: AppIconSize.lg,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainer;
    final highlight = Theme.of(context).colorScheme.surfaceContainerLow;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget block({double height = 96}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: AppRadius.allXs,
            ),
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        block(height: 140),
        Row(
          children: [
            Expanded(child: block(height: 64)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: block(height: 64)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: block(height: 64)),
          ],
        ),
        block(height: 220),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canResolve,
    required this.onResolve,
    required this.onViewTimeline,
  });

  final bool canResolve;
  final VoidCallback onResolve;
  final VoidCallback onViewTimeline;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canResolve ? onResolve : null,
              icon: const Icon(AppIcons.success, size: AppIconSize.sm + 2),
              label: Text(
                canResolve
                    ? 'Mark Resolved'
                    : 'Mark Resolved (Upload Required)',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewTimeline,
              icon: const Icon(AppIcons.eta, size: AppIconSize.sm + 2),
              label: const Text('View Timeline'),
            ),
          ),
        ],
      ),
    );
  }
}

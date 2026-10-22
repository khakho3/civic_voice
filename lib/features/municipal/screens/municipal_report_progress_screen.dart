import '../../../core/widgets/ghana_refresh_indicator.dart';
import 'package:flutter/material.dart';
import '../../../services/public_case_share.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/busy_indicator.dart';
import '../../../widgets/evidence_image_viewer.dart';
import '../../../widgets/app_state_message.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/report_progress_data.dart';
import '../models/incoming_report.dart';
import '../services/municipal_report_directory.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/kebab_menu_button.dart';
import '../widgets/municipal_detail_header.dart';
import '../widgets/officer_contact_row.dart';
import '../../../widgets/status_badge.dart';

/// Municipal monitoring is read-only while the crew works. Submitted
/// completion exposes evidence review, confirm-and-close, or a reasoned
/// return to the team. A server rejection never becomes local success.
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
  late ReportProgressData _data;
  bool _submitting = false;
  bool _decisionOpen = false;
  bool get _hasCompletionEvidence =>
      (_report?.resolutionNotes?.trim().isNotEmpty ?? false) &&
      (_report?.resolutionPhotoUrls.isNotEmpty ?? false);
  bool _sentBack = false;
  bool _missing = false;
  String? _actionError;
  IncomingReportItem? get _report =>
      MunicipalReportDirectory.instance.byReferenceId(widget.referenceId);
  late int _evidenceCount;

  @override
  void initState() {
    super.initState();
    final report = MunicipalReportDirectory.instance.byReferenceId(
      widget.referenceId,
    );
    _data =
        report != null &&
            (report.apiId != null ||
                report.status == ReportStatus.pendingApproval)
        ? ReportProgressData.fromReport(report)
        : ReportProgressData.mock();
    _evidenceCount =
        widget.initialState == MunicipalReportProgressViewState.missingEvidence
        ? 0
        : _data.caseSummary.evidencePhotoCount;
  }

  final _timelineKey = GlobalKey();

  Future<void> _approve() async {
    if (!_hasCompletionEvidence) return;
    if (_submitting ||
        _decisionOpen ||
        _report?.status != ReportStatus.pendingApproval) {
      return;
    }
    _decisionOpen = true;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Approve and close?',
      message:
          'Confirm that the completion notes and evidence show the work is finished. The report will close.',
      confirmLabel: 'Approve & Close',
    );
    _decisionOpen = false;
    if (!mounted || !confirmed) return;
    await _submitCompletion(approve: true);
  }

  Future<void> _sendBack() async {
    if (_submitting ||
        _decisionOpen ||
        _report?.status != ReportStatus.pendingApproval) {
      return;
    }
    _decisionOpen = true;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SendBackForm(),
    );
    _decisionOpen = false;
    if (!mounted || reason == null) return;
    await _submitCompletion(approve: false, reason: reason);
  }

  Future<void> _submitCompletion({
    required bool approve,
    String? reason,
  }) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _actionError = null;
    });
    try {
      if (approve) {
        await MunicipalReportDirectory.instance.approveCompletion(
          widget.referenceId,
        );
      } else {
        await MunicipalReportDirectory.instance.sendBackCompletion(
          widget.referenceId,
          reason!,
        );
      }
      if (!mounted) return;
      setState(() {
        _data = ReportProgressData.fromReport(_report!);
        _submitting = false;
        _sentBack = !approve;
        if (approve) _state = MunicipalReportProgressViewState.success;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _actionError =
              'The change could not be confirmed. Check your connection and permissions, then refresh before retrying.';
        });
      }
    }
  }

  Future<void> _retrySync() async {
    if (_submitting) return;
    // Keep the retry view in place; its action owns busy feedback.
    try {
      await MunicipalReportDirectory.instance.refresh();
      if (!mounted) return;
      setState(() {
        if (_report != null) _data = ReportProgressData.fromReport(_report!);
        _missing = _report == null;
        _state = MunicipalReportProgressViewState.loaded;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _state = MunicipalReportProgressViewState.offline);
      }
    }
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

  Future<void> _shareSummary() async {
    final outcome = await PublicCaseShare.share(
      PublicCaseSummary(
        reference: _data.referenceId,
        title: _data.title,
        status: _data.status.name,
        locality: _data.districtLabel,
      ),
    );
    if (!mounted) return;
    final message = PublicCaseShare.outcomeMessage(outcome);
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: outcome == PublicShareOutcome.failed
              ? SnackBarAction(
                  label: 'Copy',
                  onPressed: () async {
                    await PublicCaseShare.copy(
                      PublicCaseSummary(
                        reference: _data.referenceId,
                        title: _data.title,
                        status: _data.status.name,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTeam = _report?.assignedTeamId == null
        ? null
        : MaintenanceTeamDirectory.instance.teamById(_report!.assignedTeamId!);
    final showApproval =
        _report?.status == ReportStatus.pendingApproval &&
        _state == MunicipalReportProgressViewState.loaded &&
        !_sentBack;
    // widget.status is fixed at whatever it was when this screen opened —
    // it doesn't track _state, so without this the header would keep
    // showing e.g. "In Progress" even after the report's actually been
    // marked Resolved.
    final effectiveStatus = _state == MunicipalReportProgressViewState.success
        ? ReportStatus.resolved
        : _report?.status ?? widget.status;

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
                    child: _missing
                        ? AppStateMessage(
                            icon: AppIcons.empty,
                            title: 'Report not found',
                            message:
                                'This report may have been removed or is no longer in your scope.',
                            primaryActionLabel: 'Back to Active Reports',
                            onPrimaryAction: widget.onBack,
                          )
                        : _sentBack
                        ? Column(
                            children: [
                              Expanded(
                                child: AppStateMessage(
                                  icon: AppIcons.verify,
                                  title: 'Completion sent back',
                                  message:
                                      _report?.sendBackReason ??
                                      'The assigned team will receive your reason and can submit new evidence.',
                                  primaryActionLabel:
                                      'Return to Active Reports',
                                  onPrimaryAction: widget.onBack,
                                ),
                              ),
                              if (currentTeam?.leadName != null &&
                                  currentTeam?.leadPhone != null)
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: OfficerContactRow(
                                    officerName: currentTeam!.leadName!,
                                    officerPhone: currentTeam.leadPhone!,
                                    label: 'Team Lead',
                                    icon: AppIcons.team,
                                  ),
                                ),
                            ],
                          )
                        : switch (_state) {
                            MunicipalReportProgressViewState.loading =>
                              const GhanaLoadingIndicator(),
                            MunicipalReportProgressViewState.loaded ||
                            MunicipalReportProgressViewState.missingEvidence ||
                            MunicipalReportProgressViewState.offline =>
                              _ProgressBody(
                                data: _data,
                                evidenceCount: _evidenceCount,
                                cached:
                                    _state ==
                                    MunicipalReportProgressViewState.offline,
                                timelineKey: _timelineKey,
                                onRetrySync: _retrySync,
                              ),
                            MunicipalReportProgressViewState.success =>
                              _SuccessBody(
                                data: _data,
                                onReturnToActiveReports: widget.onBack,
                                onShareSummary: _shareSummary,
                              ),
                          },
                  ),
                  if (_actionError != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        _actionError!,
                        style: TextStyle(
                          color: AppSemanticColors.of(context).errorText,
                        ),
                      ),
                    ),
                  if (_actionError != null)
                    TextButton(
                      onPressed: _submitting ? null : _retrySync,
                      child: const Text('Refresh report'),
                    ),
                  if (showApproval && !_hasCompletionEvidence)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Completion notes and evidence are missing. Return the work to the team rather than approving it.',
                      ),
                    ),
                  if (showApproval)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed:
                                    _submitting || !_hasCompletionEvidence
                                    ? null
                                    : _approve,
                                child: BusyLabel(
                                  busy: _submitting,
                                  busyLabel: 'Saving completion decision',
                                  child: const Text('Approve & Close'),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _submitting ? null : _sendBack,
                              child: const Text('Send Back'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!showApproval &&
                      !_sentBack &&
                      _state != MunicipalReportProgressViewState.success)
                    TextButton(
                      onPressed: _scrollToTimeline,
                      child: const Text('View Timeline'),
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
                  Expanded(child: ReportStatusBadge(status: effectiveStatus)),
                  if (_state != MunicipalReportProgressViewState.success)
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
              'Offline Mode — Showing the last available report data',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppSemanticColors.of(context).warningText,
              ),
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
    required this.onRetrySync,
  });

  final ReportProgressData data;
  final int evidenceCount;
  final bool cached;
  final GlobalKey timelineKey;
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
        if (data.failureNote != null) ...[
          const SizedBox(height: AppSpacing.md),
          _FailureNoticeCard(reason: data.failureNote!),
        ],
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Completion evidence is supplied by the maintenance team. Officers review it here; they do not upload or mark work complete.',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(data.latestUpdateNote),
        for (final photo in data.evidencePhotoUrls)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: InkWell(
              onTap: () => EvidenceImageViewer.openGallery(
                context,
                data.evidencePhotoUrls,
                initialIndex: data.evidencePhotoUrls.indexOf(photo),
              ),
              child: Image.network(
                photo,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const Text('Evidence photo unavailable'),
              ),
            ),
          ),
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
              Expanded(
                child: Text(data.districtLabel, style: textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OfficerContactRow(
            officerName: data.officerName,
            officerPhone: data.officerPhone,
            label: 'Reviewing Officer',
            icon: AppIcons.municipalOfficer,
          ),
          if (data.maintenanceContactName != null &&
              data.maintenanceContactPhone != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OfficerContactRow(
              officerName: data.maintenanceContactName!,
              officerPhone: data.maintenanceContactPhone!,
              label: 'Maintenance Contact',
              icon: AppIcons.team,
            ),
          ],
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
              color: AppSemanticColors.of(context).actionText,
            ),
          ),
        ],
      ),
    );
  }
}

/// The maintenance team's reported reason the task couldn't be completed
/// (`Report.maintenanceFailureNotes`) — the report itself stays IN_PROGRESS
/// (there's no distinct failed status), so without this card the reason is
/// only ever visible in the notification that announced it, gone the
/// moment it's dismissed or scrolled past.
class _FailureNoticeCard extends StatelessWidget {
  const _FailureNoticeCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.warning, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs Attention',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppSemanticColors.of(context).warningText,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(reason, style: textTheme.bodySmall),
              ],
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
            child: Icon(
              AppIcons.sync,
              size: AppIconSize.md,
              color: AppSemanticColors.of(context).actionText,
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
          Text('Status Timeline', style: textTheme.titleSmall),
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
                    Expanded(
                      child: Text(
                        data.latestUpdateTeam,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppSemanticColors.of(context).actionText,
                        ),
                      ),
                    ),
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
            step.isCurrent && step.label == 'Submitted for Approval'
                ? AppIcons.verify
                : step.isCurrent
                ? AppIcons.statusInProgress
                : AppIcons.success,
            size: AppIconSize.sm,
            color: AppSemanticColors.of(context).onFillFor(color),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label, style: textTheme.titleSmall),
              Text(step.timestamp, style: textTheme.bodySmall),
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
                      color: AppSemanticColors.of(context).actionText,
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
          'The maintenance team completed the work and a municipal officer confirmed closure.',
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
        _CaseSummaryCard(
          summary: data.caseSummary,
          photos: data.evidencePhotoUrls,
        ),
      ],
    );
  }
}

class _CaseSummaryCard extends StatelessWidget {
  const _CaseSummaryCard({required this.summary, this.photos = const []});

  final CaseSummary summary;
  final List<String> photos;

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
          for (final photo in photos)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: InkWell(
                onTap: () => EvidenceImageViewer.open(context, photo),
                child: Image.network(
                  photo,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const Text('Evidence photo unavailable'),
                ),
              ),
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

class _SendBackForm extends StatefulWidget {
  const _SendBackForm();
  @override
  State<_SendBackForm> createState() => _SendBackFormState();
}

class _SendBackFormState extends State<_SendBackForm> {
  final _reason = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      MediaQuery.viewInsetsOf(context).bottom +
          MediaQuery.paddingOf(context).bottom +
          AppSpacing.md,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send Back', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Reason for returning the work',
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () {
              final value = _reason.text.trim();
              if (value.isEmpty) {
                setState(() => _error = 'Explain what needs to be corrected.');
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Return to Team'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/report_review_data.dart';
import '../widgets/dashed_border_box.dart';
import '../widgets/map_preview.dart';
import '../widgets/municipal_state_message.dart';
import '../widgets/status_badge.dart';

/// MUN-003 — Report Review.
///
/// Approved states (Figma "03 - Reports-Review" section): Default, Loading,
/// No-Evidence, Offline, Permission, Error.
///
/// No Success/Empty/Disabled: this is a single-report detail view, not a
/// list — there's nothing to be "empty", and a completed
/// Verify/Reject action navigates to MUN-004 rather than confirming inline.
///
/// Unlike Dashboard/Inbox, this screen has no bottom navigation (it's a
/// drill-down detail screen, not a tab destination) and its own header
/// shape, so it doesn't use [MunicipalScaffold].
enum MunicipalReportReviewViewState {
  loading,
  loaded,
  noEvidence,
  offline,
  error,
  permissionDenied,
}

class MunicipalReportReviewScreen extends StatefulWidget {
  const MunicipalReportReviewScreen({
    super.key,
    this.referenceId = 'REQ-8421',
    this.status = ReportStatus.submitted,
    this.initialState = MunicipalReportReviewViewState.loaded,
    this.onBack,
  });

  /// Known immediately from the Incoming Reports list the officer tapped
  /// from — shown in the header even while the rest of the detail loads.
  final String referenceId;
  final ReportStatus status;
  final MunicipalReportReviewViewState initialState;
  final VoidCallback? onBack;

  @override
  State<MunicipalReportReviewScreen> createState() =>
      _MunicipalReportReviewScreenState();
}

class _MunicipalReportReviewScreenState
    extends State<MunicipalReportReviewScreen> {
  late MunicipalReportReviewViewState _state = widget.initialState;
  final ReportReviewData _data = ReportReviewData.mock();
  final ReportReviewData _noEvidenceData = ReportReviewData.mock(
    withEvidence: false,
  );

  void _retry() {
    setState(() => _state = MunicipalReportReviewViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalReportReviewViewState.loaded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showActionBar =
        _state != MunicipalReportReviewViewState.error &&
        _state != MunicipalReportReviewViewState.permissionDenied;
    final actionsEnabled =
        _state == MunicipalReportReviewViewState.loaded ||
        _state == MunicipalReportReviewViewState.noEvidence;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ReviewHeader(
              referenceId: widget.referenceId,
              status: widget.status,
              onBack: widget.onBack,
            ),
            if (_state == MunicipalReportReviewViewState.offline)
              const _OfflineBanner(),
            Expanded(
              child: switch (_state) {
                MunicipalReportReviewViewState.loading =>
                  const _LoadingSkeleton(),
                MunicipalReportReviewViewState.loaded => _ReviewBody(
                  data: _data,
                ),
                MunicipalReportReviewViewState.noEvidence => _ReviewBody(
                  data: _noEvidenceData,
                ),
                MunicipalReportReviewViewState.offline => _ReviewBody(
                  data: _data,
                ),
                MunicipalReportReviewViewState.error => MunicipalStateMessage(
                  icon: AppIcons.warning,
                  badgeColor: AppColors.error,
                  primaryActionColor: AppColors.error,
                  title: 'Failed to load report',
                  message:
                      'We encountered a network issue while retrieving '
                      'this report. Check your connection and try again.',
                  primaryActionLabel: 'Try again',
                  onPrimaryAction: _retry,
                  secondaryActionLabel: 'Return to Dashboard',
                  onSecondaryAction: widget.onBack,
                ),
                MunicipalReportReviewViewState.permissionDenied =>
                  MunicipalStateMessage(
                    icon: AppIcons.permissionDenied,
                    badgeColor: AppColors.primary,
                    title: 'Access Restricted',
                    message:
                        'You do not have permission to view report details '
                        'for this district.',
                    // The approved frame shows "Return to Dashboard" twice
                    // (evidently a copy/paste slip) — using the same
                    // Request Access + Return pattern as Dashboard/Inbox's
                    // Permission states instead, for consistency.
                    primaryActionLabel: 'Request Access',
                    onPrimaryAction: () {},
                    secondaryActionLabel: 'Return to Dashboard',
                    onSecondaryAction: widget.onBack,
                  ),
              },
            ),
            if (showActionBar)
              _ActionBar(enabled: actionsEnabled, onReject: () {}, onVerify: () {}),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.referenceId,
    required this.status,
    this.onBack,
  });

  final String referenceId;
  final ReportStatus status;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.glassNavSurface,
        border: Border(bottom: BorderSide(color: semantic.glassBorder)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(AppIcons.back),
              iconSize: AppIconSize.md,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report Review', style: textTheme.titleMedium),
                  Text('#$referenceId', style: textTheme.bodySmall),
                ],
              ),
            ),
            ReportStatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(AppIcons.offline, size: AppIconSize.sm, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No internet connection — using cached data',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded / No-Evidence / Offline body
// ---------------------------------------------------------------------------

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.data});

  final ReportReviewData data;

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
        _SectionCard(
          icon: AppIcons.citizen,
          title: 'Citizen Information',
          child: _CitizenInfo(data: data),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          icon: AppIcons.report,
          title: 'Report Details',
          child: _ReportDetails(data: data),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          icon: AppIcons.camera,
          title: 'Evidence (${data.evidencePhotoUrls.length})',
          child: _EvidenceGallery(photoUrls: data.evidencePhotoUrls),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          icon: AppIcons.location,
          title: 'Location',
          child: MapPreview(locationLabel: data.locationLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          icon: AppIcons.task,
          title: 'Timeline',
          child: _Timeline(steps: data.timeline),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
              Icon(icon, size: AppIconSize.md, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _CitizenInfo extends StatelessWidget {
  const _CitizenInfo({required this.data});

  final ReportReviewData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                data.citizenName
                    .trim()
                    .split(RegExp(r'\s+'))
                    .map((part) => part.isEmpty ? '' : part[0])
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.citizenName, style: textTheme.titleSmall),
                Text(data.citizenPhone, style: textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.permissionDenied, size: AppIconSize.sm, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'PII Restricted. Use for official verification only. '
                  'Maintenance Teams and Ministry Supervisors cannot access '
                  'contact information.',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportDetails extends StatelessWidget {
  const _ReportDetails({required this.data});

  final ReportReviewData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.title, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(data.description, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _NeutralTag(label: data.category.label),
            ReportSeverityBadge(severity: data.severity, suffix: ' Priority'),
          ],
        ),
      ],
    );
  }
}

class _NeutralTag extends StatelessWidget {
  const _NeutralTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _EvidenceGallery extends StatelessWidget {
  const _EvidenceGallery({required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return DashedBorderBox(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.imageUnavailable,
                size: AppIconSize.md,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No photos attached',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The reporter did not include photo evidence with this '
              'submission.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        for (final url in photoUrls) ...[
          Expanded(child: _EvidenceThumbnail(placeholderId: url)),
          if (url != photoUrls.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({required this.placeholderId});

  // Real Firebase Storage URLs aren't wired up yet (Issue 03 dependency) —
  // rendering a labeled placeholder rather than a fake photo.
  final String placeholderId;

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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<ReportTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final step in steps) ...[
          _TimelineRow(step: step),
          if (step != steps.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step});

  final ReportTimelineStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final (Color badgeColor, Color iconColor) = switch (step.state) {
      TimelineStepState.completed => (AppColors.success, Colors.white),
      TimelineStepState.current => (AppColors.primary, Colors.white),
      TimelineStepState.pending => (
        colorScheme.surfaceContainer,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Icon(step.icon, size: AppIconSize.sm, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label, style: textTheme.titleSmall),
              Text(step.timestamp ?? 'Pending', style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton — 4 generic cards (Citizen/Report/Evidence/Location
// shape); Timeline is skipped and Reject/Verify Report stay visible
// (disabled), matching the approved frame.
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
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget block({double? width, double height = 14}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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

    Widget skeletonCard() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: AppComponentRadius.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(width: 120, height: 16),
            block(width: double.infinity),
            block(width: double.infinity),
            block(width: 180),
            const SizedBox(height: AppSpacing.xs),
            block(height: 80),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        skeletonCard(),
        skeletonCard(),
        skeletonCard(),
        skeletonCard(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.enabled,
    required this.onReject,
    required this.onVerify,
  });

  final bool enabled;
  final VoidCallback onReject;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            // Navigates to MUN-004 Verify/Reject Report (not built yet) to
            // capture the rejection reason — placeholder until that screen
            // exists.
            onPressed: enabled ? onReject : null,
            // Rejecting a report is a genuine destructive action (unlike a
            // "try again" retry), so it earns the Danger Button treatment —
            // kept outlined rather than filled so "Verify Report" remains
            // the single primary action per §19.12 Button Rule 1.
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(AppIcons.close, size: AppIconSize.sm + 2),
            label: const Text('Reject'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton.icon(
              // Navigates to MUN-004 Verify/Reject Report — placeholder
              // until that screen exists.
              onPressed: enabled ? onVerify : null,
              icon: const Icon(AppIcons.success, size: AppIconSize.sm + 2),
              label: const Text('Verify Report'),
            ),
          ),
        ],
      ),
    );
  }
}

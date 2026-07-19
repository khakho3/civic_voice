import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../models/resolved_report.dart';
import '../../../models/report_status.dart';
import '../../../widgets/glass_card.dart';
import '../widgets/municipal_detail_header.dart';

/// MUN-008 — Resolution Details (drill-down from Resolved Reports).
///
/// Approved states show only Default — no separate Loading/Error/Offline
/// frames like the other drill-down screens. A Loading skeleton is still
/// included (§19.18 prohibits blank screens on navigation), but Error/
/// Offline aren't invented: this is a read-only historical record, and if
/// it fails to load the officer can just back out and reopen it from the
/// list, which already has its own error/offline handling.
enum MunicipalResolutionDetailsViewState { loading, loaded }

class MunicipalResolutionDetailsScreen extends StatefulWidget {
  const MunicipalResolutionDetailsScreen({
    super.key,
    this.referenceId = 'REQ-8355',
    this.initialState = MunicipalResolutionDetailsViewState.loaded,
    this.onBack,
    this.onArchive,
    this.data,
  });

  final String referenceId;
  final MunicipalResolutionDetailsViewState initialState;
  final VoidCallback? onBack;

  /// No archive workflow is specified yet — there's no archived-reports
  /// list screen for a report to move *to*, so this stays a placeholder
  /// until that destination exists. "Share Summary" needed no such
  /// destination (see [_ActionBar]'s own `_shareSummary`) and is real now.
  final VoidCallback? onArchive;
  final ResolvedReportItem? data;

  @override
  State<MunicipalResolutionDetailsScreen> createState() =>
      _MunicipalResolutionDetailsScreenState();
}

class _MunicipalResolutionDetailsScreenState
    extends State<MunicipalResolutionDetailsScreen> {
  late final MunicipalResolutionDetailsViewState _state = widget.initialState;

  // Placeholder content pending the Cloud Firestore-backed service (Issue 03
  // dependency) — always the first mock report regardless of which list
  // item was actually tapped, the same simplification every other
  // list-to-detail flow in this module makes (e.g. Active Reports →
  // Report Progress).
  late final ResolvedReportItem _data =
      widget.data ?? ResolvedReportItem.mock().first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: MunicipalDetailHeader.topInset(context)),
                  Expanded(
                    child: switch (_state) {
                      MunicipalResolutionDetailsViewState.loading =>
                        const _LoadingSkeleton(),
                      MunicipalResolutionDetailsViewState.loaded =>
                        _DetailsBody(data: _data),
                    },
                  ),
                  if (_state == MunicipalResolutionDetailsViewState.loaded)
                    _ActionBar(data: _data, onArchive: widget.onArchive),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: _data.isRejected
                  ? 'Rejection Details'
                  : 'Resolution Details',
              referenceId: widget.referenceId,
              onBack: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.data});

  final ResolvedReportItem data;

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
        const SizedBox(height: AppSpacing.md),
        _StatsRow(data: data),
        const SizedBox(height: AppSpacing.md),
        _EvidenceCard(
          photoCount: data.evidencePhotoCount,
          photoUrls: data.evidencePhotoUrls,
          isRejected: data.isRejected,
        ),
        const SizedBox(height: AppSpacing.md),
        _TimelineCard(data: data),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final ResolvedReportItem data;

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
              Expanded(
                child: Text(
                  'REPORT ${data.referenceId}',
                  style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
                ),
              ),
              _ClosedBadge(status: data.status),
            ],
          ),
          const SizedBox(height: 2),
          Text(data.title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                AppIcons.location,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(data.locationLabel, style: textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Duration deliberately not repeated here — it's the first stat
          // in the row directly below this card.
          _LabeledValue(
            label: data.isRejected ? 'REJECTED ON' : 'RESOLVED ON',
            value: formatResolvedDate(data.resolvedDate),
          ),
        ],
      ),
    );
  }
}

class _ClosedBadge extends StatelessWidget {
  const _ClosedBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        border: Border.all(color: status.color.withValues(alpha: 0.24)),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: AppIconSize.sm, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.color,
              fontWeight: AppFontWeight.semiBold,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final ResolvedReportItem data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: AppIcons.eta,
            label: 'DURATION',
            value: '${data.durationDays}d',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            icon: AppIcons.analytics,
            label: 'SLA',
            value: '${data.slaPercent}%',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            icon: AppIcons.camera,
            label: 'EVIDENCE',
            value: '${data.evidencePhotoCount}',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.sm, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleMedium),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.photoCount,
    required this.photoUrls,
    required this.isRejected,
  });

  final int photoCount;
  final List<String> photoUrls;
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isRejected ? 'Submitted Evidence' : 'Verified Evidence',
                style: textTheme.titleSmall,
              ),
              const Spacer(),
              Text('$photoCount Photos', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (photoUrls.isEmpty)
            Text(
              isRejected
                  ? 'No citizen evidence was attached.'
                  : 'No resolution photos were uploaded.',
              style: textTheme.bodyMedium,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: photoUrls.length,
              itemBuilder: (_, index) =>
                  _VerifiedThumbnail(url: photoUrls[index]),
            ),
        ],
      ),
    );
  }
}

class _VerifiedThumbnail extends StatelessWidget {
  const _VerifiedThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppComponentRadius.inputField,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colorScheme.surfaceContainer,
                  child: Icon(
                    AppIcons.imageUnavailable,
                    size: AppIconSize.lg,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: AppRadius.allXs,
              ),
              child: Text(
                'VERIFIED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: AppFontWeight.semiBold,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.data});

  final ResolvedReportItem data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.isRejected ? 'Rejection Record' : 'Resolution Timeline',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.success,
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
                            data.isRejected ? 'Rejected' : 'Resolved',
                            style: textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${formatResolvedDate(data.resolvedDate)} · '
                          '${data.resolvedTimeLabel}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(data.resolutionNote, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
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
        block(height: 160),
        Row(
          children: [
            Expanded(child: block(height: 72)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: block(height: 72)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: block(height: 72)),
          ],
        ),
        block(height: 140),
        block(height: 100),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.data, this.onArchive});

  final ResolvedReportItem data;
  final VoidCallback? onArchive;

  Future<void> _shareSummary() {
    return SharePlus.instance.share(
      ShareParams(
        text:
            'Case ${data.referenceId} — ${data.title}\n'
            'Location: ${data.locationLabel}\n'
            '${data.isRejected ? 'Rejected' : 'Resolved'}: '
            '${data.resolvedDate.toLocal().toString().split(' ').first} '
            '(${data.durationDays} days, SLA ${data.slaPercent}%)\n\n'
            '${data.resolutionNote}',
        subject:
            'CivicVoice case ${data.referenceId} — '
            '${data.isRejected ? 'rejected' : 'resolved'}',
      ),
    );
  }

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
              onPressed: _shareSummary,
              icon: const Icon(AppIcons.share, size: AppIconSize.sm + 2),
              label: const Text('Share Summary'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onArchive,
              child: const Text('Archive Report'),
            ),
          ),
        ],
      ),
    );
  }
}

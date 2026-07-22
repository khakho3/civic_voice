import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/report_review_data.dart';
import '../services/municipal_report_directory.dart';
import '../widgets/dashed_border_box.dart';
import '../../../widgets/glass_card.dart';
import '../widgets/municipal_detail_header.dart';
import '../widgets/officer_contact_row.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/status_badge.dart';

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
    this.onNavigateToDashboard,
    this.onOpenVerification,
  });

  /// Known immediately from the Incoming Reports list the officer tapped
  /// from — shown in the header even while the rest of the detail loads.
  final String referenceId;
  final ReportStatus status;

  /// Wired by the app shell to navigate to MUN-004 Verify/Reject Report.
  /// Both the "Reject" and "Verify Report" buttons open the same screen —
  /// it's a single combined decision form, not two destinations.
  final VoidCallback? onOpenVerification;
  final MunicipalReportReviewViewState initialState;

  /// Pops one level — wired to the header's back arrow only.
  final VoidCallback? onBack;

  /// Returns all the way to the Dashboard tab — distinct from [onBack],
  /// which only pops one level. Wired to every "Return to Dashboard" /
  /// "Back to Dashboard" action.
  final VoidCallback? onNavigateToDashboard;

  @override
  State<MunicipalReportReviewScreen> createState() =>
      _MunicipalReportReviewScreenState();
}

class _MunicipalReportReviewScreenState
    extends State<MunicipalReportReviewScreen> {
  late MunicipalReportReviewViewState _state = widget.initialState;
  late ReportReviewData _data;
  final ReportReviewData _noEvidenceData = ReportReviewData.mock(
    withEvidence: false,
  );

  @override
  void initState() {
    super.initState();
    final report = MunicipalReportDirectory.instance.byReferenceId(
      widget.referenceId,
    );
    _data = report?.apiId == null
        ? ReportReviewData.mock()
        : ReportReviewData.fromReport(report!);
    if (report?.apiId != null && !report!.hasReviewer) {
      _claimReview();
    }
  }

  Future<void> _claimReview() async {
    try {
      final claimed = await MunicipalReportDirectory.instance
          .claimReviewOnServer(widget.referenceId);
      if (!mounted) return;
      setState(() => _data = ReportReviewData.fromReport(claimed));
    } catch (_) {
      try {
        await MunicipalReportDirectory.instance.refresh();
      } catch (_) {}
      final current = MunicipalReportDirectory.instance.byReferenceId(
        widget.referenceId,
      );
      if (!mounted) return;
      setState(() {
        if (current != null) _data = ReportReviewData.fromReport(current);
      });
    }
  }

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
    // Verify/Reject is the pre-assignment triage decision — once a report
    // has moved past that (Assigned/In Progress/Resolved/Rejected, e.g.
    // reached via MUN-006 Active Reports rather than the Inbox), that
    // decision has already been made and re-showing the action bar would
    // let an officer "verify" or "reject" a report that's already active.
    final pendingVerification =
        widget.status == ReportStatus.submitted ||
        widget.status == ReportStatus.underReview;
    final showActionBar =
        pendingVerification &&
        _state != MunicipalReportReviewViewState.error &&
        _state != MunicipalReportReviewViewState.permissionDenied;
    final actionsEnabled =
        _state == MunicipalReportReviewViewState.loaded ||
        _state == MunicipalReportReviewViewState.noEvidence;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: MunicipalDetailHeader.topInset(context)),
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
                      MunicipalReportReviewViewState.error => AppStateMessage(
                        icon: AppIcons.warning,
                        badgeColor: AppColors.error,
                        primaryActionColor: AppColors.error,
                        title: 'Failed to load report',
                        message:
                            'We encountered a network issue while '
                            'retrieving this report. Check your '
                            'connection and try again.',
                        primaryActionLabel: 'Try again',
                        onPrimaryAction: _retry,
                        secondaryActionLabel: 'Return to Dashboard',
                        onSecondaryAction: widget.onNavigateToDashboard,
                      ),
                      MunicipalReportReviewViewState.permissionDenied =>
                        AppStateMessage(
                          icon: AppIcons.permissionDenied,
                          badgeColor: AppColors.primary,
                          title: 'Access Restricted',
                          message:
                              'You do not have permission to view report '
                              'details for this district.',
                          // The approved frame shows "Return to Dashboard"
                          // twice (evidently a copy/paste slip) — using the
                          // same Request Access + Return pattern as
                          // Dashboard/Inbox's Permission states instead, for
                          // consistency.
                          primaryActionLabel: 'Request Access',
                          onPrimaryAction: () {},
                          secondaryActionLabel: 'Return to Dashboard',
                          onSecondaryAction: widget.onNavigateToDashboard,
                        ),
                    },
                  ),
                  if (showActionBar)
                    _ActionBar(
                      enabled: actionsEnabled && _data.canCurrentOfficerReview,
                      onReject: () => widget.onOpenVerification?.call(),
                      onVerify: () => widget.onOpenVerification?.call(),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: 'Report Review',
              referenceId: widget.referenceId,
              onBack: widget.onBack,
              trailing: ReportStatusBadge(status: widget.status),
            ),
          ),
        ],
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
          const Icon(
            AppIcons.offline,
            size: AppIconSize.sm,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No internet connection — using cached data',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.error),
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
          icon: AppIcons.phone,
          title: 'Contact Citizen',
          child: OfficerContactRow(
            officerName: data.citizenName,
            officerPhone: data.citizenPhone,
            label: 'Citizen',
          ),
        ),
        if (data.officerName != 'Not claimed yet') ...[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            icon: AppIcons.municipalOfficer,
            title: 'Review Ownership',
            child: Text(
              data.canCurrentOfficerReview
                  ? 'You are the reviewing officer for this report.'
                  : '${data.officerName} is currently reviewing this report. You can still view all updates.',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          icon: AppIcons.report,
          title: 'Report Details',
          child: _ReportDetails(data: data),
        ),
        if (data.confidence != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            icon: AppIcons.verify,
            title: 'Confidence Signals',
            child: _ConfidenceSignals(data: data),
          ),
        ],
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
          child: _ReportLocationMap(
            latitude: data.latitude,
            longitude: data.longitude,
            locationLabel: data.locationLabel,
          ),
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppIconSize.md,
                color: colorScheme.onSurfaceVariant,
              ),
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
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.citizenName, style: textTheme.titleSmall),
                  Text(data.citizenPhone, style: textTheme.bodySmall),
                  if (data.citizenLowTrust) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const _NeutralTag(label: 'Low-trust account'),
                  ],
                ],
              ),
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
              Icon(
                AppIcons.permissionDenied,
                size: AppIconSize.sm,
                color: AppColors.primary,
              ),
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
        _NeutralTag(label: data.category.label),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _ConfidenceSignals extends StatelessWidget {
  const _ConfidenceSignals({required this.data});

  final ReportReviewData data;

  @override
  Widget build(BuildContext context) {
    final confidence = data.confidence!;
    final score = confidence.score ?? 0;
    final (label, color) = switch (score) {
      < 40 => ('Low', AppColors.error),
      < 70 => ('Moderate', AppColors.warning),
      _ => ('High', AppColors.success),
    };
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.allXl,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$label confidence · $score/95',
            style: textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No automated check can certify certainty — this signal never '
          'reaches 100%.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _ConfidenceSignalLine(
          icon: AppIcons.myLocation,
          text:
              'Live GPS vs pin: ${_formatDistance(confidence.liveGpsDistanceMeters, missing: 'no live GPS fix')}',
        ),
        const SizedBox(height: AppSpacing.sm),
        _ConfidenceSignalLine(
          icon: AppIcons.camera,
          text:
              'Photo EXIF vs pin: ${_formatDistance(confidence.photoExifDistanceMeters, missing: 'no EXIF data found')}',
        ),
        const SizedBox(height: AppSpacing.sm),
        _ConfidenceSignalLine(
          icon: AppIcons.team,
          text:
              'Community confirmations: ${confidence.seconderCount ?? 0} of 5 cap — contributed ${confidence.seconderContribution ?? 0}/20 pts',
        ),
      ],
    );
  }

  static String _formatDistance(double? meters, {required String missing}) {
    if (meters == null) return missing;
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

class _ConfidenceSignalLine extends StatelessWidget {
  const _ConfidenceSignalLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppIconSize.sm,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: photoUrls.length,
      itemBuilder: (context, index) =>
          _EvidenceThumbnail(url: photoUrls[index]),
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(AppSpacing.md),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
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
    );
  }
}

/// A real, live map tile with a single marker at the report's location —
/// replaces the previous custom-painted placeholder now that a Google Maps
/// API key is already configured for this app (see
/// `LocationPickerScreen`'s own `GoogleMap` for the citizen-side precedent
/// this mirrors). Lite mode + every gesture disabled: a location preview,
/// not a picker — there's nothing here for an officer to drag or zoom.
class _ReportLocationMap extends StatelessWidget {
  const _ReportLocationMap({
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  final double latitude;
  final double longitude;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: AppComponentRadius.card,
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 16),
              markers: {
                Marker(
                  markerId: const MarkerId('report-location'),
                  position: target,
                ),
              },
              compassEnabled: false,
              liteModeEnabled: true,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  locationLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
            // Opens MUN-004 Verify/Reject Report to capture the decision
            // (and rejection reason, if any).
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
              // Opens MUN-004 Verify/Reject Report to capture the decision.
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/glass_card.dart';
import '../models/ministry_dashboard_data.dart';
import '../models/municipal_performance_data.dart';
import '../widgets/ministry_scaffold.dart';

/// MIN-001 — Ministry Dashboard.
///
/// Approved states (Figma "01 Dashboard/Ministry" export): Default,
/// Loading, Empty ("No Analytics Available"), Offline, Error ("Unable to
/// Load Dashboard"), Unauthorized ("Unauthorized Access") — no Success/
/// Disabled, matching Municipal Dashboard's reasoning: a read-only overview
/// screen has no completable action to confirm.
///
/// Unlike Municipal Dashboard (where Loading/Empty keep the page shell and
/// only swap data-driven parts), every non-Default/Loading state here is a
/// full-page [AppStateMessage] replacement — confirmed against the actual
/// exported frames, which show Empty/Offline/Error/Unauthorized each as a
/// single centered card with nothing else on the page. Unauthorized shows
/// no action buttons at all in the approved frame (unlike Municipal's
/// "Access Restricted", which offers Request Access/Return Home) — that
/// asymmetry is honored rather than smoothed over, since inventing actions
/// the design doesn't show would be adding a workflow that isn't approved.
enum MinistryDashboardViewState {
  loading,
  loaded,
  empty,
  offline,
  error,
  unauthorized,
}

class MinistryDashboardScreen extends StatefulWidget {
  const MinistryDashboardScreen({
    super.key,
    this.initialState = MinistryDashboardViewState.loaded,
    this.onNavigateToAnalytics,
    this.onNavigateToMunicipalities,
    this.onNavigateToReports,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onOpenMunicipality,
  });

  /// Testing hook: defaults to the normal loaded view. Pass a different
  /// value to preview another approved state until this screen is wired to
  /// a live Cloud Firestore stream (Issue 05 dependency).
  final MinistryDashboardViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs. Also the
  /// destination for the "Municipality Performance" card's "View All"
  /// and every row within it — was mistakenly pointed at
  /// [onNavigateToReports] before, landing on Reports Overview instead of
  /// the actual Municipal Performance screen the card is previewing.
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToMunicipalities;

  final VoidCallback? onNavigateToReports;

  /// Opens MIN-006 Ministry Profile — wired to the header's profile avatar.
  final VoidCallback? onProfileTap;

  /// Opens Ministry Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens the Municipal Officer contact detail screen for the tapped
  /// "Municipality Performance" row — each row is its own destination now,
  /// distinct from the section's "View All" (still [onNavigateToMunicipalities]).
  final ValueChanged<RegionalLeaderItem>? onOpenMunicipality;

  @override
  State<MinistryDashboardScreen> createState() =>
      _MinistryDashboardScreenState();
}

class _MinistryDashboardScreenState extends State<MinistryDashboardScreen> {
  late MinistryDashboardViewState _state = widget.initialState;
  final MinistryDashboardData _data = MinistryDashboardData.mock();

  void _retry() {
    setState(() => _state = MinistryDashboardViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MinistryDashboardViewState.loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinistryScaffold(
      selectedTab: MinistryTab.dashboard,
      onNotificationsTap: widget.onNotificationsTap,
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MinistryTab.analytics) widget.onNavigateToAnalytics?.call();
        if (tab == MinistryTab.municipalities) {
          widget.onNavigateToMunicipalities?.call();
        }
        if (tab == MinistryTab.reports) widget.onNavigateToReports?.call();
      },
      body: switch (_state) {
        MinistryDashboardViewState.loading => const _LoadingSkeleton(),
        MinistryDashboardViewState.loaded => _DashboardContent(
          data: _data,
          onViewAllMunicipalities: widget.onNavigateToMunicipalities,
          onOpenMunicipality: widget.onOpenMunicipality,
        ),
        MinistryDashboardViewState.empty => Padding(
          padding: MinistryScaffold.contentPadding(context),
          child: AppStateMessage(
            icon: AppIcons.report,
            badgeColor: AppColors.primary,
            title: 'No Analytics Available',
            message:
                'Aggregated ministry analytics will appear here once '
                'reports are available.',
            primaryActionLabel: 'Refresh',
            onPrimaryAction: _retry,
          ),
        ),
        MinistryDashboardViewState.offline => Padding(
          padding: MinistryScaffold.contentPadding(context),
          child: AppStateMessage(
            icon: AppIcons.offline,
            badgeColor: AppColors.error,
            title: 'You\'re offline',
            message: 'Check your connection and retry loading the dashboard.',
            primaryActionLabel: 'Retry connection',
            onPrimaryAction: _retry,
            primaryActionColor: AppColors.error,
          ),
        ),
        MinistryDashboardViewState.error => Padding(
          padding: MinistryScaffold.contentPadding(context),
          child: AppStateMessage(
            icon: AppIcons.warning,
            badgeColor: AppColors.error,
            title: 'Unable to Load Dashboard',
            message:
                'The ministry dashboard service could not return '
                'aggregated performance data right now.',
            primaryActionLabel: 'Try again',
            onPrimaryAction: _retry,
            primaryActionColor: AppColors.error,
          ),
        ),
        MinistryDashboardViewState.unauthorized => Padding(
          padding: MinistryScaffold.contentPadding(context),
          child: const AppStateMessage(
            icon: AppIcons.permissionDenied,
            badgeColor: AppColors.error,
            title: 'Unauthorized Access',
            message:
                'This read-only ministry dashboard requires supervisor '
                'permissions. No citizen personal information is available '
                'here.',
          ),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded content
// ---------------------------------------------------------------------------

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    this.onViewAllMunicipalities,
    this.onOpenMunicipality,
  });

  final MinistryDashboardData data;
  final VoidCallback? onViewAllMunicipalities;
  final ValueChanged<RegionalLeaderItem>? onOpenMunicipality;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = MinistryScaffold.contentPadding(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Text('Ministry Supervisor', style: textTheme.bodySmall),
        Text('National Dashboard', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xl),
        _StatsGrid(stats: data.stats),
        const SizedBox(height: AppSpacing.xl),
        _ReportStatisticsCard(reportStatistics: data.reportStatistics),
        const SizedBox(height: AppSpacing.xl),
        Text('Quick Insights', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _QuickInsightsGrid(insights: data.insights),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Municipality Performance',
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onViewAllMunicipalities,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in data.topMunicipalities)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _MunicipalityRow(
              item: item,
              onTap: onOpenMunicipality == null
                  ? null
                  : () => onOpenMunicipality!(item),
            ),
          ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final MinistryDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    // Row/Expanded rather than GridView.count(childAspectRatio: ...): an
    // aspect ratio scales cell *height* down together with width on
    // narrower phones, and this card's content needs a roughly fixed
    // absolute height regardless of width — an aspect ratio tuned to fit
    // at 428px overflowed by a few pixels at 375px. Letting each card size
    // to its own natural content height sidesteps that entirely.
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: AppIcons.report,
                  tint: AppColors.primary,
                  label: 'Total Reports',
                  value: _formatCount(stats.totalReports),
                  delta: '+${stats.totalReportsChangePercent}%',
                  deltaColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.warning,
                  tint: AppColors.statusUnderReview,
                  label: 'Under Review',
                  value: _formatCount(stats.underReview),
                  delta: '${stats.underReviewPercent}%',
                  deltaColor: AppColors.statusUnderReview,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: AppIcons.success,
                  tint: AppColors.statusResolved,
                  label: 'Resolved',
                  value: _formatCount(stats.resolved),
                  delta: '${stats.resolvedPercent}%',
                  deltaColor: AppColors.statusResolved,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.municipality,
                  tint: AppColors.statusAssigned,
                  label: 'Municipalities',
                  value: '${stats.activeMunicipalities}',
                  delta: 'Active',
                  deltaColor: AppColors.statusAssigned,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatCount(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    final rounded = (thousands * 10).round() / 10;
    return '${rounded % 1 == 0 ? rounded.toInt() : rounded}K';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String delta;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.lg,
            height: AppIconSize.lg,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: AppIconSize.sm + 2, color: tint),
          ),
          const Spacer(),
          Text(
            label,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: textTheme.titleLarge),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  delta,
                  style: textTheme.labelMedium?.copyWith(color: deltaColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportStatisticsCard extends StatelessWidget {
  const _ReportStatisticsCard({required this.reportStatistics});

  final ReportStatistics reportStatistics;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final maxValue = reportStatistics.monthlyValues.reduce(
      (a, b) => a > b ? a : b,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Report Statistics', style: textTheme.titleMedium),
              Icon(
                AppIcons.chartBreakdown,
                size: AppIconSize.md,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in reportStatistics.monthlyValues) ...[
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: value / maxValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (value != reportStatistics.monthlyValues.last)
                    const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  reportStatistics.rangeLabel,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                reportStatistics.totalLabel,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickInsightsGrid extends StatelessWidget {
  const _QuickInsightsGrid({required this.insights});

  final QuickInsights insights;

  @override
  Widget build(BuildContext context) {
    // Row/Expanded rather than GridView.count(childAspectRatio: ...) — see
    // _StatsGrid for why: an aspect ratio shrinks height together with
    // width on narrower phones, overflowing this card's fixed content.
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickInsightCard(
                  dotColor: AppColors.statusSubmitted,
                  label: 'Submitted',
                  sublabel: '${insights.submittedPercent}% of national reports',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickInsightCard(
                  dotColor: AppColors.statusUnderReview,
                  label: 'Under Review',
                  sublabel:
                      '${insights.underReviewPercent}% of national reports',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickInsightCard(
                  dotColor: AppColors.statusAssigned,
                  label: 'Assigned',
                  sublabel: '${insights.assignedPercent}% of national reports',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickInsightCard(
                  dotColor: AppColors.statusInProgress,
                  label: 'In Progress',
                  sublabel:
                      '${insights.inProgressPercent}% of national reports',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickInsightCard extends StatelessWidget {
  const _QuickInsightCard({
    required this.dotColor,
    required this.label,
    required this.sublabel,
  });

  final Color dotColor;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sublabel,
            style: textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MunicipalityRow extends StatelessWidget {
  const _MunicipalityRow({required this.item, this.onTap});

  final RegionalLeaderItem item;

  /// Opens the Municipal Officer contact detail screen for this specific
  /// municipality — each row is its own destination, distinct from the
  /// section's "View All" (the full Municipal Performance screen).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppDimensions.controlHeightStandard,
            height: AppDimensions.controlHeightStandard,
            decoration: BoxDecoration(
              color: semantic.iconBadgeSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.analytics,
              size: AppIconSize.md,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.resolvedPercent}% resolved · '
                  '${item.responseTimeLabel} response',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.chevronRight,
            size: AppIconSize.md,
            color: colorScheme.onSurfaceVariant,
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
    final chromeInset = MinistryScaffold.contentPadding(context);

    Widget block({double? width, double height = 16, double? radius}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: BorderRadius.circular(radius ?? 4),
            ),
          );
        },
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        block(width: 140, height: 14),
        const SizedBox(height: AppSpacing.sm),
        block(width: 220, height: 22),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 165 / 112,
          children: List.generate(4, (_) => block(radius: 12, height: 112)),
        ),
        const SizedBox(height: AppSpacing.xl),
        block(height: 260, radius: 12),
        const SizedBox(height: AppSpacing.xl),
        block(height: 260, radius: 12),
      ],
    );
  }
}

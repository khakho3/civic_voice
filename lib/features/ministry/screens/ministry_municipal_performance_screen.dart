import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/municipal_performance_data.dart';
import '../widgets/ministry_scaffold.dart';

/// MIN-003 — Municipal Performance Screen.
///
/// Approved states (Figma "03/Municipal" export): Default, Loading, Empty
/// ("No Performance Data"), No Results, Offline, Error ("Unable to Load
/// Performance"), Unauthorized — the same seven-state shape as MIN-002
/// Analytics Dashboard, including the scope-chip row staying visible and
/// interactive across Default/Empty/No Results and disabled (not removed)
/// for Offline/Error/Unauthorized.
///
/// The approved frame's header shows the CivicVoice brand mark rather than
/// an "Municipal Performance" title, and its bottom nav highlights
/// "Analytics" instead of this tab — both read as copy/paste leftovers from
/// the Analytics frame this one was likely duplicated from (the same
/// category of slip already corrected on every other screen this session),
/// not a deliberate departure from the header/nav convention every other
/// tab already follows. [MinistryScaffold]'s existing rule stands: only the
/// Dashboard tab shows the brand mark, every other tab shows its own title
/// — so the body doesn't repeat "Municipal Performance" as a redundant
/// headline the way MIN-001's brand-mark header needed one.
enum MinistryMunicipalPerformanceViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class MinistryMunicipalPerformanceScreen extends StatefulWidget {
  const MinistryMunicipalPerformanceScreen({
    super.key,
    this.initialState = MinistryMunicipalPerformanceViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToAnalytics,
    this.onNavigateToReports,
    this.onProfileTap,
  });

  final MinistryMunicipalPerformanceViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToReports;

  /// Opens MIN-006 Ministry Profile — wired to the header's profile avatar.
  final VoidCallback? onProfileTap;

  @override
  State<MinistryMunicipalPerformanceScreen> createState() =>
      _MinistryMunicipalPerformanceScreenState();
}

class _MinistryMunicipalPerformanceScreenState
    extends State<MinistryMunicipalPerformanceScreen> {
  late MinistryMunicipalPerformanceViewState _state = widget.initialState;
  final MunicipalPerformanceData _data = MunicipalPerformanceData.mock();
  PerformanceFilter _filter = PerformanceFilter.all;
  EfficiencyMetric _metric = EfficiencyMetric.response;

  void _retry() {
    setState(() => _state = MinistryMunicipalPerformanceViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MinistryMunicipalPerformanceViewState.loaded);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = PerformanceFilter.all;
      _state = MinistryMunicipalPerformanceViewState.loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Empty/No Results keep the chrome fixed (not collapsible) rather than
    // wrapping it in CollapsibleListHeader like Loaded does: their content
    // is a short, centered state card with nothing to scroll, so there's no
    // scroll gesture to drive a collapse in the first place. Offline/Error/
    // Unauthorized go a step further and disable the chrome entirely, same
    // as before.
    final chromeEnabled =
        _state == MinistryMunicipalPerformanceViewState.empty ||
        _state == MinistryMunicipalPerformanceViewState.noResults;

    // The approved frames use a longer subtitle on Default than on every
    // other state (which share a terser "Aggregated municipality metrics
    // only.") — honored as written rather than picking one for every state.
    final subtitle = _state == MinistryMunicipalPerformanceViewState.loaded
        ? 'Aggregated response and resolution metrics across '
              'municipalities.'
        : 'Aggregated municipality metrics only.';

    return MinistryScaffold(
      selectedTab: MinistryTab.municipalities,
      onNotificationsTap: () {},
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MinistryTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MinistryTab.analytics) widget.onNavigateToAnalytics?.call();
        if (tab == MinistryTab.reports) widget.onNavigateToReports?.call();
      },
      body: switch (_state) {
        MinistryMunicipalPerformanceViewState.loading =>
          const _LoadingSkeleton(),
        MinistryMunicipalPerformanceViewState.loaded => Padding(
          padding: EdgeInsets.only(
            top: MinistryScaffold.contentPadding(context).top,
          ),
          child: CollapsibleListHeader(
            header: _FilterChrome(
              subtitle: subtitle,
              filter: _filter,
              enabled: true,
              onFilterSelected: (f) => setState(() => _filter = f),
            ),
            child: _PerformanceContent(
              data: _data,
              metric: _metric,
              onMetricChanged: (m) => setState(() => _metric = m),
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(height: MinistryScaffold.contentPadding(context).top),
            _FilterChrome(
              subtitle: subtitle,
              filter: _filter,
              enabled: chromeEnabled,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
            ),
            Expanded(
              child: switch (_state) {
                MinistryMunicipalPerformanceViewState.loading ||
                MinistryMunicipalPerformanceViewState.loaded =>
                  const SizedBox.shrink(),
                MinistryMunicipalPerformanceViewState.empty => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noDataFile,
                    badgeColor: AppColors.primary,
                    title: 'No Performance Data',
                    message:
                        'Municipality performance metrics will appear '
                        'once aggregated reports are available.',
                    primaryActionLabel: 'Refresh',
                    onPrimaryAction: _retry,
                  ),
                ),
                MinistryMunicipalPerformanceViewState.noResults => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noFilterMatch,
                    badgeColor: AppColors.primary,
                    title: 'No Results',
                    message:
                        'No municipality performance records match the '
                        'selected filters.',
                    primaryActionLabel: 'Clear Filters',
                    onPrimaryAction: _clearFilters,
                  ),
                ),
                MinistryMunicipalPerformanceViewState.offline => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.offline,
                    badgeColor: AppColors.error,
                    title: 'You\'re offline',
                    message:
                        'Check your connection and retry loading '
                        'performance metrics.',
                    primaryActionLabel: 'Retry connection',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                MinistryMunicipalPerformanceViewState.error => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.warning,
                    badgeColor: AppColors.error,
                    title: 'Unable to Load Performance',
                    message:
                        'The performance service could not return '
                        'aggregated metrics right now.',
                    primaryActionLabel: 'Try again',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                MinistryMunicipalPerformanceViewState.unauthorized => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: const AppStateMessage(
                    icon: AppIcons.permissionDenied,
                    badgeColor: AppColors.error,
                    title: 'Unauthorized Access',
                    message:
                        'This read-only ministry performance screen '
                        'requires supervisor permissions.',
                  ),
                ),
              },
            ),
          ],
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chrome — subtitle + scope chips
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.subtitle,
    required this.filter,
    required this.enabled,
    this.onFilterSelected,
  });

  final String subtitle;
  final PerformanceFilter filter;
  final bool enabled;
  final ValueChanged<PerformanceFilter>? onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PerformanceFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final option = PerformanceFilter.values[index];
                return _ScopeChip(
                  label: option.label,
                  selected: option == filter,
                  onTap: enabled ? () => onFilterSelected?.call(option) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.primary : colorScheme.surfaceContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded content
// ---------------------------------------------------------------------------

class _PerformanceContent extends StatelessWidget {
  const _PerformanceContent({
    required this.data,
    required this.metric,
    required this.onMetricChanged,
  });

  final MunicipalPerformanceData data;
  final EfficiencyMetric metric;
  final ValueChanged<EfficiencyMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = MinistryScaffold.contentPadding(context);
    final trendValues = metric == EfficiencyMetric.response
        ? data.responseTrend
        : data.resolutionTrend;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: AppIcons.responseTime,
                  tint: AppColors.primary,
                  label: 'Avg Response',
                  value: data.stats.avgResponseLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.resolutionGauge,
                  tint: AppColors.statusResolved,
                  label: 'Resolution',
                  value: '${data.stats.resolutionPercent}%',
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
                  icon: AppIcons.achievement,
                  tint: AppColors.statusAssigned,
                  label: 'SLA Met',
                  value: '${data.stats.slaMetPercent}%',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.warning,
                  tint: AppColors.warning,
                  label: 'Backlog',
                  value: data.stats.backlogLabel,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Regional Leaders',
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // No dedicated "all leaders" screen is specified (MIN-003's
            // only exit point is Ministry Dashboard) — placeholder pending
            // spec, matching this module's other unwired actions.
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final leader in data.regionalLeaders)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _RegionalLeaderRow(item: leader),
          ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Efficiency Trend',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  for (final option in EfficiencyMetric.values) ...[
                    _MetricToggle(
                      label: option.label,
                      selected: option == metric,
                      onTap: () => onMetricChanged(option),
                    ),
                    if (option != EfficiencyMetric.values.last)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _BarChart(values: trendValues),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data.trendCaption,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;

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
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(value, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _RegionalLeaderRow extends StatelessWidget {
  const _RegionalLeaderRow({required this.item});

  final RegionalLeaderItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      // No detail screen is specified for a single municipality yet
      // (MIN-003's only exit point is Ministry Dashboard) — placeholder
      // pending spec.
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: AppDimensions.controlHeightStandard,
            height: AppDimensions.controlHeightStandard,
            decoration: BoxDecoration(
              color: item.rankColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              AppIcons.municipality,
              size: AppIconSize.md,
              color: item.rankColor,
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
                  '${item.resolvedPercent}% resolved · ${item.responseTimeLabel} response',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${item.resolvedPercent}',
            style: textTheme.titleLarge?.copyWith(color: item.rankColor),
          ),
          const SizedBox(width: 4),
          Icon(
            AppIcons.chevronRight,
            size: AppIconSize.sm,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.allSm,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? AppColors.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? AppFontWeight.semiBold : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values) ...[
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
            if (value != values.last) const SizedBox(width: AppSpacing.xs),
          ],
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
        block(height: 16),
        const SizedBox(height: AppSpacing.sm),
        block(height: 32),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            block(width: 72, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 72, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 72, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 88, height: 32, radius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: block(height: 100, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 100, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: block(height: 100, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 100, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        block(height: 200, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 260, radius: 12),
      ],
    );
  }
}

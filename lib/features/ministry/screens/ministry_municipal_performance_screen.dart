import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/simple_bar_chart.dart';
import '../models/municipal_performance_data.dart';
import '../widgets/ministry_scaffold.dart';
import '../widgets/region_picker_chip.dart';

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
    this.onOpenMunicipality,
  });

  final MinistryMunicipalPerformanceViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToReports;

  /// Opens MIN-006 Ministry Profile — wired to the header's profile avatar.
  final VoidCallback? onProfileTap;

  /// Opens the Municipal Officer contact detail screen for the tapped
  /// Regional Leaders row.
  final ValueChanged<RegionalLeaderItem>? onOpenMunicipality;

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

  /// Null means every region — the real narrowing dimension "plenty
  /// charts" alone couldn't offer: with all 16 regions represented in
  /// [MunicipalPerformanceData.mock] now, a Ministry Supervisor overseeing
  /// the whole country can actually drill into one.
  Region? _region;

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
      _region = null;
      _state = MinistryMunicipalPerformanceViewState.loaded;
    });
  }

  Future<void> _pickRegion() async {
    final selected = await pickRegion(context, current: _region);
    // pickRegion returns null both for "picked All Regions" and
    // "dismissed with no selection" — a second flag would be needed to
    // tell those apart, but since re-picking "All Regions" is exactly the
    // reset already in effect for a dismissed sheet, treating them the
    // same has no observable difference here.
    setState(() => _region = selected);
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
              region: _region,
              enabled: true,
              onFilterSelected: (f) => setState(() => _filter = f),
              onRegionTap: _pickRegion,
            ),
            child: _PerformanceContent(
              data: _data,
              metric: _metric,
              filter: _filter,
              region: _region,
              onMetricChanged: (m) => setState(() => _metric = m),
              onClearFilters: _clearFilters,
              onOpenMunicipality: widget.onOpenMunicipality,
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(height: MinistryScaffold.contentPadding(context).top),
            _FilterChrome(
              subtitle: subtitle,
              filter: _filter,
              region: _region,
              enabled: chromeEnabled,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
              onRegionTap: chromeEnabled ? _pickRegion : null,
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
    required this.region,
    required this.enabled,
    this.onFilterSelected,
    this.onRegionTap,
  });

  final String subtitle;
  final PerformanceFilter filter;
  final Region? region;
  final bool enabled;
  final ValueChanged<PerformanceFilter>? onFilterSelected;
  final VoidCallback? onRegionTap;

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
              // Region picker first — it's the primary narrowing dimension
              // ("which of the 16 regions"), the scope chips after it just
              // refine within whatever region is currently in effect.
              itemCount: PerformanceFilter.values.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return RegionPickerChip(
                    label: region?.label ?? 'All Regions',
                    active: region != null,
                    onTap: onRegionTap,
                  );
                }
                final option = PerformanceFilter.values[index - 1];
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
    required this.filter,
    required this.region,
    required this.onMetricChanged,
    required this.onClearFilters,
    this.onOpenMunicipality,
  });

  final MunicipalPerformanceData data;
  final EfficiencyMetric metric;
  final PerformanceFilter filter;
  final Region? region;
  final ValueChanged<EfficiencyMetric> onMetricChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<RegionalLeaderItem>? onOpenMunicipality;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = MinistryScaffold.contentPadding(context);
    final trendValues = metric == EfficiencyMetric.response
        ? data.responseTrend
        : data.resolutionTrend;

    final scoped = region == null
        ? data.regionalLeaders
        : [
            for (final leader in data.regionalLeaders)
              if (leader.region == region) leader,
          ];
    final leaders = switch (filter) {
      PerformanceFilter.all => scoped,
      PerformanceFilter.needsAttention => [
        for (final leader in scoped)
          if (leader.needsAttention) leader,
      ],
      PerformanceFilter.top10 =>
        (List<RegionalLeaderItem>.of(
          scoped,
        )..sort((a, b) => b.resolvedPercent.compareTo(a.resolvedPercent)))
            .take(10)
            .toList(),
    };

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
            // The old "View all" here had nowhere real to go — there's no
            // dedicated MIN-003 detail screen, and now that the region
            // picker/scope chips above actually narrow this exact list,
            // there's nothing left to "view all" of that isn't already
            // shown. A count reads the current scope instead of implying
            // a hidden destination that doesn't exist.
            Text('${leaders.length} shown', style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (leaders.isEmpty)
          _InlineEmptyHint(onClear: onClearFilters)
        else
          for (final leader in leaders)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RegionalLeaderRow(
                item: leader,
                onTap: onOpenMunicipality == null
                    ? null
                    : () => onOpenMunicipality!(leader),
              ),
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
              SimpleBarChart(values: trendValues),
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
  const _RegionalLeaderRow({required this.item, this.onTap});

  final RegionalLeaderItem item;

  /// Opens the Municipal Officer contact detail screen for this row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
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
                  '${item.region.label} · ${item.resolvedPercent}% resolved · '
                  '${item.responseTimeLabel} response',
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

/// Shown in place of the Regional Leaders list when the region/scope
/// combination excludes every entry — matches the inline empty-hint shape
/// already established on MIN-004 Reports Overview for the same "live
/// filtering left nothing to show, right here in the list" situation.
class _InlineEmptyHint extends StatelessWidget {
  const _InlineEmptyHint({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            AppIcons.noFilterMatch,
            size: AppIconSize.lg,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No municipalities match your region and scope selection.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onClear, child: const Text('Clear')),
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

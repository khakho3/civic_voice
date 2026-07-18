import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/simple_bar_chart.dart';
import '../models/ministry_analytics_data.dart';
import '../widgets/ministry_scaffold.dart';

/// MIN-002 — Analytics Dashboard.
///
/// Approved states (Figma "02/analytics" export): Default, Loading, Empty
/// ("No Analytics Available" — no data exists yet), "No Results" (data
/// exists but the current filter/date-range combination excludes all of
/// it), Offline, Error ("Unable to Load Analytics"), Unauthorized.
///
/// Unlike MIN-001 Dashboard (where every non-Default/Loading state fully
/// replaces the page), the date-range selector and dimension chips stay
/// visible and interactive across Default/Empty/No Results — confirmed
/// against the actual exported frames, all of which show that chrome above
/// the state card. They're disabled (not removed) for Offline/Error/
/// Unauthorized, where changing a filter can't do anything useful anyway.
enum MinistryAnalyticsViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class MinistryAnalyticsScreen extends StatefulWidget {
  const MinistryAnalyticsScreen({
    super.key,
    this.initialState = MinistryAnalyticsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToMunicipalities,
    this.onNavigateToReports,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onViewReportInsights,
  });

  final MinistryAnalyticsViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToMunicipalities;
  final VoidCallback? onNavigateToReports;

  /// Opens MIN-006 Ministry Profile — wired to the header's profile avatar.
  final VoidCallback? onProfileTap;

  /// Opens Ministry Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens MIN-005 Report Insights — wired to the "Trend Insights" callout,
  /// one of that screen's two spec'd entry points (the other is MIN-004
  /// Reports Overview's own "Report Insights" card).
  final VoidCallback? onViewReportInsights;

  @override
  State<MinistryAnalyticsScreen> createState() =>
      _MinistryAnalyticsScreenState();
}

class _MinistryAnalyticsScreenState extends State<MinistryAnalyticsScreen> {
  late MinistryAnalyticsViewState _state = widget.initialState;
  final MinistryAnalyticsData _data = MinistryAnalyticsData.mock();
  AnalyticsDimension _dimension = AnalyticsDimension.category;
  AnalyticsDateRange _dateRange = AnalyticsDateRange.last30Days;

  void _retry() {
    setState(() => _state = MinistryAnalyticsViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MinistryAnalyticsViewState.loaded);
    });
  }

  void _clearFilters() {
    setState(() {
      _dimension = AnalyticsDimension.category;
      _dateRange = AnalyticsDateRange.last30Days;
      _state = MinistryAnalyticsViewState.loaded;
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
        _state == MinistryAnalyticsViewState.empty ||
        _state == MinistryAnalyticsViewState.noResults;

    return MinistryScaffold(
      selectedTab: MinistryTab.analytics,
      onNotificationsTap: widget.onNotificationsTap,
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MinistryTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MinistryTab.municipalities) {
          widget.onNavigateToMunicipalities?.call();
        }
        if (tab == MinistryTab.reports) widget.onNavigateToReports?.call();
      },
      body: switch (_state) {
        MinistryAnalyticsViewState.loading => const _LoadingSkeleton(),
        MinistryAnalyticsViewState.loaded => Padding(
          padding: EdgeInsets.only(
            top: MinistryScaffold.contentPadding(context).top,
          ),
          child: CollapsibleListHeader(
            header: _FilterChrome(
              dateRange: _dateRange,
              dimension: _dimension,
              enabled: true,
              onDateRangeChanged: (r) => setState(() => _dateRange = r),
              onDimensionSelected: (d) => setState(() => _dimension = d),
            ),
            child: _AnalyticsContent(
              data: _data,
              dimension: _dimension,
              onViewReportInsights: widget.onViewReportInsights,
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(height: MinistryScaffold.contentPadding(context).top),
            _FilterChrome(
              dateRange: _dateRange,
              dimension: _dimension,
              enabled: chromeEnabled,
              onDateRangeChanged: chromeEnabled
                  ? (r) => setState(() => _dateRange = r)
                  : null,
              onDimensionSelected: chromeEnabled
                  ? (d) => setState(() => _dimension = d)
                  : null,
            ),
            Expanded(
              child: switch (_state) {
                MinistryAnalyticsViewState.loading ||
                MinistryAnalyticsViewState.loaded => const SizedBox.shrink(),
                MinistryAnalyticsViewState.empty => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noDataFile,
                    badgeColor: AppColors.primary,
                    title: 'No Analytics Available',
                    message:
                        'Aggregated analytics will appear here once '
                        'reports are available.',
                    primaryActionLabel: 'Refresh',
                    onPrimaryAction: _retry,
                  ),
                ),
                MinistryAnalyticsViewState.noResults => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noFilterMatch,
                    badgeColor: AppColors.primary,
                    title: 'No Results',
                    message:
                        'No aggregated analytics match the selected '
                        'filters.',
                    primaryActionLabel: 'Clear Filters',
                    onPrimaryAction: _clearFilters,
                  ),
                ),
                MinistryAnalyticsViewState.offline => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.offline,
                    badgeColor: AppColors.error,
                    title: 'You\'re offline',
                    message:
                        'Check your connection and retry loading '
                        'analytics.',
                    primaryActionLabel: 'Retry connection',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                MinistryAnalyticsViewState.error => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.warning,
                    badgeColor: AppColors.error,
                    title: 'Unable to Load Analytics',
                    message:
                        'The analytics service could not return '
                        'aggregated data right now.',
                    primaryActionLabel: 'Try again',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                MinistryAnalyticsViewState.unauthorized => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: const AppStateMessage(
                    icon: AppIcons.permissionDenied,
                    badgeColor: AppColors.error,
                    title: 'Unauthorized Access',
                    message:
                        'This read-only ministry analytics screen '
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
// Filter chrome — date range + dimension chips
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.dateRange,
    required this.dimension,
    required this.enabled,
    this.onDateRangeChanged,
    this.onDimensionSelected,
  });

  final AnalyticsDateRange dateRange;
  final AnalyticsDimension dimension;
  final bool enabled;
  final ValueChanged<AnalyticsDateRange>? onDateRangeChanged;
  final ValueChanged<AnalyticsDimension>? onDimensionSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          // A real DropdownButton — matches Admin System Activity's own
          // date-range control (_TimeRangeDropdown) — rather than a modal
          // bottom sheet, so the same kind of filter opens the same way
          // everywhere in the app.
          Material(
            color: colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AnalyticsDateRange>(
                  value: dateRange,
                  isExpanded: true,
                  borderRadius: AppComponentRadius.inputField,
                  icon: Icon(
                    AppIcons.chevronDown,
                    size: AppIconSize.md,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  selectedItemBuilder: (context) => [
                    for (final range in AnalyticsDateRange.values)
                      Row(
                        children: [
                          Icon(
                            AppIcons.calendar,
                            size: AppIconSize.md,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(range.label),
                        ],
                      ),
                  ],
                  items: [
                    for (final range in AnalyticsDateRange.values)
                      DropdownMenuItem(value: range, child: Text(range.label)),
                  ],
                  onChanged: enabled
                      ? (selected) {
                          if (selected != null) {
                            onDateRangeChanged?.call(selected);
                          }
                        }
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AnalyticsDimension.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final option = AnalyticsDimension.values[index];
                final selected = option == dimension;
                return _DimensionChip(
                  label: option.label,
                  selected: selected,
                  onTap: enabled
                      ? () => onDimensionSelected?.call(option)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionChip extends StatelessWidget {
  const _DimensionChip({
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

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.data,
    required this.dimension,
    this.onViewReportInsights,
  });

  final MinistryAnalyticsData data;
  final AnalyticsDimension dimension;
  final VoidCallback? onViewReportInsights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = MinistryScaffold.contentPadding(context);
    final breakdown = data.breakdownsByDimension[dimension]!;
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
                  label: 'Total Reports',
                  value: _formatThousands(data.totalReports),
                  delta: '+${data.totalReportsChangePercent}%',
                  deltaColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Resolution Rate',
                  value: '${data.resolutionRate}%',
                  delta: '+${data.resolutionRateChangePercent}%',
                  deltaColor: AppColors.statusResolved,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Report Trends', style: textTheme.titleMedium),
                  Icon(
                    AppIcons.trendUp,
                    size: AppIconSize.md,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SimpleBarChart(values: data.trendValues),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.trendStartLabel, style: textTheme.bodySmall),
                  Text(data.trendMidLabel, style: textTheme.bodySmall),
                  Text(data.trendEndLabel, style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dimension.label} Distribution',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in breakdown) ...[
                _BreakdownRow(item: item),
                if (item != breakdown.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Report Status', style: textTheme.titleMedium),
                  Icon(
                    AppIcons.chartBreakdown,
                    size: AppIconSize.md,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CustomPaint(
                      painter: _StatusDonutPainter(data.statusDistribution),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final slice in data.statusDistribution)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: slice.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    slice.label,
                                    style: textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TrendInsightsCallout(
          text: data.trendInsight,
          onViewReportInsights: onViewReportInsights,
        ),
      ],
    );
  }

  /// Comma thousands-separator (e.g. "12,482") — unlike MIN-001 Dashboard's
  /// stat cards, the approved MIN-002 frame shows the exact figure here
  /// rather than an abbreviated "12.5K", so this doesn't reuse Dashboard's
  /// abbreviating formatter.
  static String _formatThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

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
          Text(
            label,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            delta,
            style: textTheme.labelMedium?.copyWith(color: deltaColor),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item});

  final AnalyticsBreakdownItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${item.percent}%', style: textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: AppRadius.allXl,
          child: LinearProgressIndicator(
            value: item.percent / 100,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(item.color),
          ),
        ),
      ],
    );
  }
}

/// Doubles as the entry point into MIN-005 Report Insights when
/// [onViewReportInsights] is set — one of that screen's two spec'd entry
/// points, alongside MIN-004 Reports Overview's own "Report Insights" card.
class _TrendInsightsCallout extends StatelessWidget {
  const _TrendInsightsCallout({required this.text, this.onViewReportInsights});

  final String text;
  final VoidCallback? onViewReportInsights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: AppComponentRadius.card,
      child: InkWell(
        borderRadius: AppComponentRadius.card,
        onTap: onViewReportInsights,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppComponentRadius.card,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    AppIcons.trendUp,
                    size: AppIconSize.md,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Trend Insights',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (onViewReportInsights != null)
                    Icon(
                      AppIcons.chevronRight,
                      size: AppIconSize.sm,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(text, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

/// A ring chart with one arc segment per slice — the fixed "Report Status"
/// breakdown. Segment order/angles are illustrative: this is placeholder
/// data with no live backend to compute exact proportions from yet.
class _StatusDonutPainter extends CustomPainter {
  const _StatusDonutPainter(this.slices);

  final List<StatusSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.22;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.percent);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.percent / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
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
        block(height: 48, radius: 12),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
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
              Expanded(child: block(height: 88, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 88, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        block(height: 200, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 160, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 160, radius: 12),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/ministry_reports_data.dart';
import '../widgets/ministry_scaffold.dart';
import '../widgets/region_picker_chip.dart';

/// MIN-004 — Reports Overview.
///
/// Approved states (Figma "04/Overview" export): Default, Loading, Empty
/// ("No Reports"), No Results, Offline, Error ("Unable to Load Reports"),
/// Unauthorized — the same seven-state shape as MIN-002/MIN-003, including
/// the search+filter chrome staying visible and interactive across
/// Default/Empty/No Results and disabled (not removed) for Offline/Error/
/// Unauthorized.
///
/// The approved frame's body — a "Status Distribution" donut, "Top
/// Categories" bars, and "Regional Hotspots" map — is a near-exact reuse of
/// MIN-002 Analytics Dashboard's own body (down to matching figures), with
/// only the top chrome (search field + status chips instead of dimension
/// chips + date range) and header (hamburger + bell instead of a title)
/// changed. Per the spec ("17 CivicVoice - Ministry Supervisor Screen
/// Specifications", MIN-004), this screen's actual job is a *consolidated
/// list of reports* ("Report Summary Cards"), a distinct concern from
/// MIN-002's analytics visualizations and MIN-005 Report Insights' trend/
/// category/resolution analysis — so the body here is a real searchable,
/// filterable report list rather than a second copy of Analytics' charts.
/// Confirmed with the user rather than assumed silently, given how much of
/// the frame this departs from. The header/nav mismatches are the same
/// category of copy/paste slip corrected on every other screen this
/// session: [MinistryScaffold]'s existing rule stands (title + bell +
/// profile avatar for every non-Dashboard tab), and the Figma title text
/// itself ("Reports Overview") already matches [MinistryTab.reports].
enum MinistryReportsViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class MinistryReportsScreen extends StatefulWidget {
  const MinistryReportsScreen({
    super.key,
    this.initialState = MinistryReportsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToAnalytics,
    this.onNavigateToMunicipalities,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onViewReportInsights,
  });

  final MinistryReportsViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToMunicipalities;

  /// Opens MIN-006 Ministry Profile — wired to the header's profile avatar.
  final VoidCallback? onProfileTap;

  /// Opens Ministry Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens MIN-005 Report Insights — the spec'd exit point for this
  /// screen's "View Report Insights" action. Nullable: MIN-005 isn't built
  /// yet, matching this module's other unwired forward-references.
  final VoidCallback? onViewReportInsights;

  @override
  State<MinistryReportsScreen> createState() => _MinistryReportsScreenState();
}

class _MinistryReportsScreenState extends State<MinistryReportsScreen> {
  late MinistryReportsViewState _state = widget.initialState;
  final MinistryReportsData _data = MinistryReportsData.mock();
  final TextEditingController _searchController = TextEditingController();
  ReportStatusFilter _filter = ReportStatusFilter.all;
  String _query = '';

  /// Null means every region — narrows the national report list the same
  /// way MIN-003 Municipal Performance's own region picker does, reusing
  /// the same "chip opens a bottom sheet of all 16 regions" pattern.
  Region? _region;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _state = MinistryReportsViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MinistryReportsViewState.loaded);
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _filter = ReportStatusFilter.all;
      _region = null;
      _state = MinistryReportsViewState.loaded;
    });
  }

  Future<void> _pickRegion() async {
    final selected = await pickRegion(context, current: _region);
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
        _state == MinistryReportsViewState.empty ||
        _state == MinistryReportsViewState.noResults;

    return MinistryScaffold(
      selectedTab: MinistryTab.reports,
      onNotificationsTap: widget.onNotificationsTap,
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MinistryTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MinistryTab.analytics) widget.onNavigateToAnalytics?.call();
        if (tab == MinistryTab.municipalities) {
          widget.onNavigateToMunicipalities?.call();
        }
      },
      body: switch (_state) {
        MinistryReportsViewState.loading => const _LoadingSkeleton(),
        MinistryReportsViewState.loaded => Padding(
          padding: EdgeInsets.only(
            top: MinistryScaffold.contentPadding(context).top,
          ),
          child: CollapsibleListHeader(
            header: _FilterChrome(
              controller: _searchController,
              filter: _filter,
              region: _region,
              enabled: true,
              onQueryChanged: (q) => setState(() => _query = q),
              onFilterSelected: (f) => setState(() => _filter = f),
              onRegionTap: _pickRegion,
            ),
            child: _ReportsContent(
              data: _data,
              query: _query,
              filter: _filter,
              region: _region,
              onClearFilters: _clearFilters,
              onViewReportInsights: widget.onViewReportInsights,
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(height: MinistryScaffold.contentPadding(context).top),
            _FilterChrome(
              controller: _searchController,
              filter: _filter,
              region: _region,
              enabled: chromeEnabled,
              onQueryChanged: chromeEnabled
                  ? (q) => setState(() => _query = q)
                  : null,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
              onRegionTap: chromeEnabled ? _pickRegion : null,
            ),
            Expanded(
              child: switch (_state) {
                MinistryReportsViewState.loading ||
                MinistryReportsViewState.loaded => const SizedBox.shrink(),
                MinistryReportsViewState.empty => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noDataFile,
                    badgeColor: AppColors.primary,
                    title: 'No Reports',
                    message:
                        'Aggregated reports will appear here once ministry '
                        'report data is available.',
                    primaryActionLabel: 'Refresh',
                    onPrimaryAction: _retry,
                  ),
                ),
                MinistryReportsViewState.noResults => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noFilterMatch,
                    badgeColor: AppColors.primary,
                    title: 'No Results',
                    message:
                        'No aggregated reports match the current search '
                        'or filters.',
                    primaryActionLabel: 'Clear Filters',
                    onPrimaryAction: _clearFilters,
                  ),
                ),
                MinistryReportsViewState.offline => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.offline,
                    badgeColor: AppColors.error,
                    title: 'You\'re offline',
                    message: 'Check your connection and retry loading reports.',
                    primaryActionLabel: 'Retry connection',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                MinistryReportsViewState.error => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.warning,
                    badgeColor: AppColors.error,
                    title: 'Unable to Load Reports',
                    message:
                        'The reports service could not return aggregated '
                        'data right now.',
                    primaryActionLabel: 'Try again',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                MinistryReportsViewState.unauthorized => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: const AppStateMessage(
                    icon: AppIcons.permissionDenied,
                    badgeColor: AppColors.error,
                    title: 'Unauthorized Access',
                    message:
                        'This read-only ministry reports overview requires '
                        'supervisor permissions.',
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
// Filter chrome — search field + status chips
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.controller,
    required this.filter,
    required this.region,
    required this.enabled,
    this.onQueryChanged,
    this.onFilterSelected,
    this.onRegionTap,
  });

  final TextEditingController controller;
  final ReportStatusFilter filter;
  final Region? region;
  final bool enabled;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<ReportStatusFilter>? onFilterSelected;
  final VoidCallback? onRegionTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          Material(
            color: colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onQueryChanged,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search aggregated reports',
                border: InputBorder.none,
                prefixIcon: Icon(
                  AppIcons.search,
                  size: AppIconSize.md,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          AppIcons.close,
                          size: AppIconSize.md,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: enabled
                            ? () {
                                controller.clear();
                                onQueryChanged?.call('');
                              }
                            : null,
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Region picker last — status is the primary chip row here
              // (matching the approved MIN-004 chip row), region is the
              // additional narrowing dimension appended after it.
              itemCount: ReportStatusFilter.values.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                if (index == ReportStatusFilter.values.length) {
                  return RegionPickerChip(
                    label: region?.label ?? 'All Regions',
                    active: region != null,
                    onTap: onRegionTap,
                  );
                }
                final option = ReportStatusFilter.values[index];
                return _StatusChip(
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.selected, this.onTap});

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

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.data,
    required this.query,
    required this.filter,
    required this.region,
    required this.onClearFilters,
    this.onViewReportInsights,
  });

  final MinistryReportsData data;
  final String query;
  final ReportStatusFilter filter;
  final Region? region;
  final VoidCallback onClearFilters;
  final VoidCallback? onViewReportInsights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = MinistryScaffold.contentPadding(context);
    final filtered = data.reports
        .where(
          (r) =>
              filter.matches(r.status) &&
              r.matchesSearch(query) &&
              (region == null || r.region == region),
        )
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aggregated Reports',
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatThousands(data.stats.aggregatedReports),
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'National report volume · current period',
                style: textTheme.bodySmall,
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
                  label: 'Under Review',
                  value: _formatThousands(data.stats.underReview),
                  valueColor: AppColors.statusUnderReview,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Resolved',
                  value: _formatThousands(data.stats.resolved),
                  valueColor: AppColors.statusResolved,
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
                'Reports',
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${filtered.length} shown', style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (filtered.isEmpty)
          _InlineEmptyHint(onClear: onClearFilters)
        else
          for (final report in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ReportCard(item: report),
            ),
        const SizedBox(height: AppSpacing.md),
        _ReportInsightsCallout(onTap: onViewReportInsights),
      ],
    );
  }

  /// Comma thousands-separator (e.g. "24,812") — matches MIN-002 Analytics'
  /// own formatter convention for exact (not abbreviated) national figures.
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
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

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
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item});

  final ReportSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimensions.controlHeightStandard,
            height: AppDimensions.controlHeightStandard,
            decoration: BoxDecoration(
              color: item.status.color.withValues(alpha: 0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              item.status.icon,
              size: AppIconSize.md,
              color: item.status.color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.municipality} · ${item.category}',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: item.status),
              const SizedBox(height: AppSpacing.xs),
              Text(item.dateLabel, style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        status.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: status.color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

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
            'No reports match your search or filter.',
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

class _ReportInsightsCallout extends StatelessWidget {
  const _ReportInsightsCallout({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppIconSize.xl,
            height: AppIconSize.xl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.analytics,
              size: AppIconSize.md,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Insights', style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Explore trend, category, and resolution analysis across '
                  'all aggregated reports.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
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
            block(width: 56, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 88, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 72, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 88, height: 32, radius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        block(height: 88, radius: 12),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: block(height: 72, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 72, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 4; i++) ...[
          block(height: 72, radius: 12),
          const SizedBox(height: AppSpacing.sm),
        ],
        block(height: 88, radius: 12),
      ],
    );
  }
}

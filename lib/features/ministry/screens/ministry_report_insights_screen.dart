import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/civic_bottom_sheet.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/report_status.dart';
import '../models/ministry_report_insights_data.dart';

/// MIN-005 — Report Insights.
///
/// Approved states (Figma "05/Insight" export): Default, Loading, Empty
/// ("No Insights"), No Results, Offline, Error ("Unable to Load Insights"),
/// Unauthorized. Two of the exported folders were mislabeled relative to
/// their actual contents — "empty" holds the true no-data-yet state ("No
/// Insights") and "no insight" (despite its name) holds the filtered-to-
/// nothing state ("No Results", searchX icon, "Clear Filters" action).
/// Mapped by what's actually on each frame, not by folder name.
///
/// Unlike every other screen built so far, this one is **not** a bottom-nav
/// tab. Per the spec ("17 CivicVoice - Ministry Supervisor Screen
/// Specifications", MIN-005), its only entry points are Analytics Dashboard
/// and Reports Overview, and its only exit point is Ministry Dashboard — the
/// same drill-down shape as Municipal Officer's own detail screens (Report
/// Review, Resolution Details, etc.), which use a back-arrow header with no
/// bottom nav rather than [MunicipalScaffold]. The approved frame instead
/// shows the persistent 4-tab bottom nav with "Analytics" highlighted (plus
/// the leftover "Services"/"Settings" labels already corrected everywhere
/// else this session) — that reads as the same copy/paste-from-Analytics
/// slip as every other screen, compounded by the fact that the app's nav
/// already has its four real slots filled (Dashboard/Analytics/
/// Municipalities/Reports); there is no fifth slot for this screen to
/// occupy even if the frame intended one. Built as a drill-down instead,
/// with a back arrow returning to Ministry Dashboard (the spec's sole exit
/// point) regardless of which of the two entry points was used to arrive.
///
/// The frame also shows a filter/funnel icon twice — once in the header,
/// once at the end of the chip row — for what reads as the same "more
/// filters" action drawn in two places. Dropped both: the three chips
/// (date range/Category/Status) already cover 100% of the spec's "Filter
/// Selection" input and "Filter Insights" user action on their own, so a
/// fourth control duplicating them would have no distinct job to do.
enum MinistryReportInsightsViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class MinistryReportInsightsScreen extends StatefulWidget {
  const MinistryReportInsightsScreen({
    super.key,
    this.initialState = MinistryReportInsightsViewState.loaded,
    this.onBack,
    this.onViewFocusSummary,
    this.data,
    this.dataForFilters,
    this.onRefresh,
  });

  final MinistryReportInsightsViewState initialState;

  /// Returns to Ministry Dashboard — the spec's only exit point, regardless
  /// of whether this screen was reached from Analytics or Reports Overview.
  final VoidCallback? onBack;

  /// Retained for source compatibility with the app shell. Focus Summary is
  /// deliberately unavailable until I06 supplies a grounded implementation.
  final VoidCallback? onViewFocusSummary;
  final MinistryReportInsightsData? data;
  final MinistryReportInsightsData Function(
    InsightsDateRange dateRange,
    InsightsCategoryFilter category,
    InsightsStatusFilter status,
  )?
  dataForFilters;
  final Future<void> Function()? onRefresh;

  @override
  State<MinistryReportInsightsScreen> createState() =>
      _MinistryReportInsightsScreenState();
}

class _MinistryReportInsightsScreenState
    extends State<MinistryReportInsightsScreen> {
  late MinistryReportInsightsViewState _state = widget.initialState;
  MinistryReportInsightsData? get _data =>
      widget.dataForFilters?.call(_dateRange, _category, _status) ??
      widget.data;
  InsightsDateRange _dateRange = InsightsDateRange.last30Days;
  InsightsCategoryFilter _category = InsightsCategoryFilter.all;
  InsightsStatusFilter _status = InsightsStatusFilter.all;

  Future<void> _retry() async {
    final refresh = widget.onRefresh;
    if (refresh == null) return;
    setState(() => _state = MinistryReportInsightsViewState.loading);
    try {
      await refresh();
      if (mounted) setState(() => _state = MinistryReportInsightsViewState.loaded);
    } catch (_) {
      if (mounted) setState(() => _state = MinistryReportInsightsViewState.error);
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRange = InsightsDateRange.last30Days;
      _category = InsightsCategoryFilter.all;
      _status = InsightsStatusFilter.all;
      _state = MinistryReportInsightsViewState.loaded;
    });
  }

  Future<void> _pickDateRange() async {
    final selected = await showCivicBottomSheet<InsightsDateRange>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in InsightsDateRange.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _dateRange
                    ? Icon(
                        AppIcons.success,
                        color: AppSemanticColors.of(context).actionText,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _dateRange = selected);
  }

  Future<void> _pickCategory() async {
    final selected = await showCivicBottomSheet<InsightsCategoryFilter>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in InsightsCategoryFilter.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _category
                    ? Icon(
                        AppIcons.success,
                        color: AppSemanticColors.of(context).actionText,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _category = selected);
  }

  Future<void> _pickStatus() async {
    final selected = await showCivicBottomSheet<InsightsStatusFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in InsightsStatusFilter.values)
                ListTile(
                  title: Text(option.label),
                  trailing: option == _status
                      ? Icon(
                          AppIcons.success,
                          color: AppSemanticColors.of(context).actionText,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) setState(() => _status = selected);
  }

  @override
  Widget build(BuildContext context) {
    // Empty/No Results keep the chrome fixed (not collapsible) rather than
    // wrapping it in CollapsibleListHeader like Loaded does: their content
    // is a short, centered state card with nothing to scroll, so there's no
    // scroll gesture to drive a collapse in the first place. Offline/Error/
    // Unauthorized go a step further and disable the chrome entirely, same
    // as before.
    final data = _data;
    final hasActiveFilters =
        _dateRange != InsightsDateRange.last30Days ||
        _category != InsightsCategoryFilter.all ||
        _status != InsightsStatusFilter.all;
    final viewState = _state == MinistryReportInsightsViewState.loaded &&
            (data == null || data.totalReports == 0)
        ? hasActiveFilters
            ? MinistryReportInsightsViewState.noResults
            : MinistryReportInsightsViewState.empty
        : _state;
    final chromeEnabled =
        viewState == MinistryReportInsightsViewState.empty ||
        viewState == MinistryReportInsightsViewState.noResults;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: switch (viewState) {
              MinistryReportInsightsViewState.loading =>
                const _LoadingSkeleton(),
              MinistryReportInsightsViewState.loaded => Padding(
                padding: EdgeInsets.only(top: DetailHeader.topInset(context)),
                child: CollapsibleListHeader(
                  header: _FilterChrome(
                    dateRangeLabel: _dateRange.label,
                    categoryLabel: _category.label,
                    statusLabel: _status.label,
                    enabled: true,
                    onDateRangeTap: _pickDateRange,
                    onCategoryTap: _pickCategory,
                    onStatusTap: _pickStatus,
                  ),
                  child: _InsightsContent(
                    data: data!,
                  ),
                ),
              ),
              _ => Column(
                children: [
                  SizedBox(height: DetailHeader.topInset(context)),
                  _FilterChrome(
                    dateRangeLabel: _dateRange.label,
                    categoryLabel: _category.label,
                    statusLabel: _status.label,
                    enabled: chromeEnabled,
                    onDateRangeTap: chromeEnabled ? _pickDateRange : null,
                    onCategoryTap: chromeEnabled ? _pickCategory : null,
                    onStatusTap: chromeEnabled ? _pickStatus : null,
                  ),
                  Expanded(
                    child: switch (viewState) {
                      MinistryReportInsightsViewState.loading ||
                      MinistryReportInsightsViewState.loaded =>
                        const SizedBox.shrink(),
                      MinistryReportInsightsViewState.empty => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppStateMessage(
                          icon: AppIcons.insight,
                          badgeColor: AppColors.primary,
                          title: 'No Insights',
                          message:
                              'Aggregated report insights will appear once '
                              'enough reporting data is available.',
                          primaryActionLabel: 'Refresh',
                          onPrimaryAction:
                              widget.onRefresh == null ? null : _retry,
                        ),
                      ),
                      MinistryReportInsightsViewState.noResults => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppStateMessage(
                          icon: AppIcons.noFilterMatch,
                          badgeColor: AppColors.primary,
                          title: 'No Results',
                          message:
                              'No report insights match the selected '
                              'filters.',
                          primaryActionLabel: 'Clear Filters',
                          onPrimaryAction: _clearFilters,
                        ),
                      ),
                      MinistryReportInsightsViewState.offline => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppStateMessage(
                          icon: AppIcons.offline,
                          badgeColor: AppColors.error,
                          title: 'You\'re offline',
                          message:
                              'Check your connection and retry loading '
                              'report insights.',
                          primaryActionLabel: 'Retry connection',
                          onPrimaryAction:
                              widget.onRefresh == null ? null : _retry,
                          primaryActionColor: AppColors.error,
                        ),
                      ),
                      MinistryReportInsightsViewState.error => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppStateMessage(
                          icon: AppIcons.warning,
                          badgeColor: AppColors.error,
                          title: 'Unable to Load Insights',
                          message:
                              'The insights service could not return '
                              'aggregated analysis right now.',
                          primaryActionLabel: 'Try again',
                          onPrimaryAction:
                              widget.onRefresh == null ? null : _retry,
                          primaryActionColor: AppColors.error,
                        ),
                      ),
                      MinistryReportInsightsViewState.unauthorized => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: const AppStateMessage(
                          icon: AppIcons.permissionDenied,
                          badgeColor: AppColors.error,
                          title: 'Unauthorized Access',
                          message:
                              'This read-only ministry report insights '
                              'screen requires supervisor permissions.',
                        ),
                      ),
                    },
                  ),
                ],
              ),
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'Report Insights',
              onBack: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chrome — date range + category + status chips
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.dateRangeLabel,
    required this.categoryLabel,
    required this.statusLabel,
    required this.enabled,
    this.onDateRangeTap,
    this.onCategoryTap,
    this.onStatusTap,
  });

  final String dateRangeLabel;
  final String categoryLabel;
  final String statusLabel;
  final bool enabled;
  final VoidCallback? onDateRangeTap;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _FilterChip(
              label: dateRangeLabel,
              selected: true,
              onTap: onDateRangeTap,
            ),
            const SizedBox(width: AppSpacing.xs),
            _FilterChip(
              label: categoryLabel,
              selected: false,
              onTap: onCategoryTap,
            ),
            const SizedBox(width: AppSpacing.xs),
            _FilterChip(
              label: statusLabel,
              selected: false,
              onTap: onStatusTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppSemanticColors.of(context).actionFill
          : colorScheme.surfaceContainer,
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
              color: selected
                  ? AppSemanticColors.of(context).onAction
                  : colorScheme.onSurfaceVariant,
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

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.data});

  final MinistryReportInsightsData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Category Peak',
                  value: data.categoryPeakLabel,
                  delta: '${data.categoryPeakCount} reports',
                  deltaColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Resolution',
                  value: '${data.resolutionPercent}%',
                  delta:
                      '${data.count(ReportStatus.resolved)} reports resolved',
                  deltaColor: AppColors.statusResolved,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StatusBreakdown(data: data),
        const SizedBox(height: AppSpacing.lg),
        Text('Critical Insights', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final insight in data.criticalInsights)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CriticalInsightRow(item: insight),
          ),
        const SizedBox(height: AppSpacing.md),
        _StrategicFocusCard(text: data.strategicFocusText),
      ],
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.data});

  final MinistryReportInsightsData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Breakdown', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final status in ReportStatus.values)
                Text(
                  '${status.label}: ${data.count(status)}',
                  style: textTheme.bodySmall,
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
          Text(
            value,
            style: textTheme.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

class _CriticalInsightRow extends StatelessWidget {
  const _CriticalInsightRow({required this.item});

  final CriticalInsightItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: AppDimensions.controlHeightStandard,
            height: AppDimensions.controlHeightStandard,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: AppIconSize.md,
              color: AppSemanticColors.of(context).foregroundFor(item.tint),
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
                Text(
                  item.subtitle,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategicFocusCard extends StatelessWidget {
  const _StrategicFocusCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.xl,
                height: AppIconSize.xl,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.insight,
                  size: AppIconSize.md,
                  color: AppSemanticColors.of(context).actionText,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Strategic Focus', style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Focus Summary is unavailable until I06 provides a grounded AI insight.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: const Text('View focus summary'),
            ),
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
    final topInset = DetailHeader.topInset(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
        topInset + AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            block(width: 72, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 88, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 72, height: 32, radius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: block(height: 96, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 96, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 3; i++) ...[
          block(height: 72, radius: 12),
          const SizedBox(height: AppSpacing.sm),
        ],
        block(height: 200, radius: 12),
      ],
    );
  }
}

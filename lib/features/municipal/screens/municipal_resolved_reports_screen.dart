import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/resolved_report.dart';
import '../../../models/report_status.dart';
import '../services/municipal_report_directory.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../widgets/municipal_scaffold.dart';
import '../widgets/municipal_search_field.dart';
import '../../../widgets/app_state_message.dart';

/// MUN-008 — Resolved Reports.
///
/// Approved states (Figma "08 Resolved Reports" section): Default, Loading,
/// Empty ("No Resolved Reports Yet"), Offline — no Error state in the
/// approved frames (unlike MUN-006 Active Reports), so none is invented
/// here; a read-only historical list failing to load isn't meaningfully
/// different from it being offline.
///
/// A bottom-nav tab destination ([MunicipalTab.resolved]), matching
/// MUN-006 Active Reports' resolution: the approved frames show a
/// back-arrow header, but every other list screen in this module is a tab
/// root with [MunicipalScaffold]'s persistent glass chrome, and this is
/// the same browsable-list shape. The header's "128 THIS MONTH" subtitle
/// wasn't carried over — it just repeats the "Resolved · 128 · This month"
/// stat card already in the body, and no other tab header shows a
/// subtitle. The frame's kebab (⋮) menu wasn't carried over either, for
/// the same reason: every sibling tab header uses the notification bell,
/// and nothing on this screen needs a menu the bell/visible actions don't
/// already cover.
enum MunicipalResolvedReportsViewState { loading, loaded, empty, offline }

class MunicipalResolvedReportsScreen extends StatefulWidget {
  const MunicipalResolvedReportsScreen({
    super.key,
    this.initialState = MunicipalResolvedReportsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToInbox,
    this.onNavigateToActiveReports,
    this.onProfileTap,
    this.onReportTap,
    this.onNotificationsTap,
  });

  final MunicipalResolvedReportsViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs, and to
  /// Empty's "View Active Reports" action.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToInbox;
  final VoidCallback? onNavigateToActiveReports;

  /// Opens MUN-009 Municipal Profile — wired to the header's profile
  /// avatar, now that it exists.
  final VoidCallback? onProfileTap;

  final ValueChanged<ResolvedReportItem>? onReportTap;
  final VoidCallback? onNotificationsTap;

  @override
  State<MunicipalResolvedReportsScreen> createState() =>
      _MunicipalResolvedReportsScreenState();
}

class _MunicipalResolvedReportsScreenState
    extends State<MunicipalResolvedReportsScreen> {
  late MunicipalResolvedReportsViewState _state = widget.initialState;
  late List<ResolvedReportItem> _data = _resolvedReports();
  final _searchController = TextEditingController();
  ResolvedReportFilter _filter = ResolvedReportFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Real filtering/search — matching the interactive treatment already
  /// established on MUN-005/MUN-006's lists, rather than the static
  /// mockup's non-functional chips.
  List<ResolvedReportItem> get _visibleReports {
    var reports = _data.toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      reports = reports
          .where(
            (r) =>
                r.referenceId.toLowerCase().contains(query) ||
                r.title.toLowerCase().contains(query) ||
                r.locationLabel.toLowerCase().contains(query),
          )
          .toList();
    }
    final now = DateTime.now();
    switch (_filter) {
      case ResolvedReportFilter.all:
        break;
      case ResolvedReportFilter.thisWeek:
        reports = reports
            .where((r) => now.difference(r.resolvedDate).inDays < 7)
            .toList();
      case ResolvedReportFilter.thisMonth:
        reports = reports
            .where((r) => now.difference(r.resolvedDate).inDays < 30)
            .toList();
    }
    return reports;
  }

  static List<ResolvedReportItem> _resolvedReports() {
    final reports = MunicipalReportDirectory.instance.reports.value;
    final live = MunicipalReportDirectory.instance.hasLiveSnapshot;
    return live
        ? reports
              .where(
                (report) =>
                    report.status == ReportStatus.resolved ||
                    report.status == ReportStatus.rejected,
              )
              .map(ResolvedReportItem.fromReport)
              .toList()
        : ResolvedReportItem.mock();
  }

  Future<void> _retryLoad() async {
    setState(() => _state = MunicipalResolvedReportsViewState.loading);
    try {
      await MunicipalReportDirectory.instance.refresh();
      if (mounted) {
        setState(() {
          _data = _resolvedReports();
          _state = MunicipalResolvedReportsViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = MunicipalResolvedReportsViewState.offline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chromeInset = MunicipalScaffold.contentPadding(context);
    return MunicipalScaffold(
      selectedTab: MunicipalTab.resolved,
      onNotificationsTap: widget.onNotificationsTap ?? () {},
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MunicipalTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MunicipalTab.inbox) widget.onNavigateToInbox?.call();
        if (tab == MunicipalTab.active) {
          widget.onNavigateToActiveReports?.call();
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: chromeInset.top),
          if (_state == MunicipalResolvedReportsViewState.offline)
            const _OfflineBanner(),
          Expanded(
            child: switch (_state) {
              MunicipalResolvedReportsViewState.loading =>
                const _LoadingSkeleton(),
              MunicipalResolvedReportsViewState.loaded => _ResolvedReportsBody(
                reports: _visibleReports,
                cached: false,
                searchController: _searchController,
                filter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
                onReportTap: widget.onReportTap,
              ),
              MunicipalResolvedReportsViewState.offline => _ResolvedReportsBody(
                reports: _visibleReports,
                cached: true,
                searchController: _searchController,
                filter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
                onReportTap: widget.onReportTap,
              ),
              MunicipalResolvedReportsViewState.empty => Padding(
                padding: EdgeInsets.only(bottom: chromeInset.bottom),
                child: AppStateMessage(
                  icon: AppIcons.empty,
                  badgeColor: AppColors.primary,
                  title: 'No Closed Reports Yet',
                  message:
                      'Resolved and rejected reports will appear here as a '
                      'durable case history.',
                  primaryActionLabel: 'View Active Reports',
                  onPrimaryAction: widget.onNavigateToActiveReports,
                  secondaryActionLabel: 'Refresh',
                  onSecondaryAction: _retryLoad,
                ),
              ),
            },
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
              'Offline Mode — showing cached closed reports',
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
// Body (Default / Offline share this — only `cached` differs)
// ---------------------------------------------------------------------------

class _ResolvedReportsBody extends StatelessWidget {
  const _ResolvedReportsBody({
    required this.reports,
    required this.cached,
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
    this.onReportTap,
  });

  final List<ResolvedReportItem> reports;
  final bool cached;
  final TextEditingController searchController;
  final ResolvedReportFilter filter;
  final ValueChanged<ResolvedReportFilter> onFilterChanged;
  final ValueChanged<ResolvedReportItem>? onReportTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stats = ResolvedReportStats.fromReports(reports);

    return CollapsibleListHeader(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MunicipalSearchField(
              controller: searchController,
              hintText: 'Search closed reports...',
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ResolvedReportFilter.values.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final option = ResolvedReportFilter.values[index];
                  return _FilterChip(
                    label: option.label,
                    selected: option == filter,
                    onTap: () => onFilterChanged(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Stats scroll with the list body, not the collapsible chrome — only
      // the search field/filter chips are transient chrome worth hiding on
      // scroll; a stats row is content, same as the cards below it.
      child: ListView(
        // Keeps the list draggable even once the collapsed chrome frees
        // enough room for all cards to fit the viewport — otherwise
        // maxScrollExtent hits 0, the default physics stop accepting
        // drags, and the hidden search chrome could never be pulled back
        // out.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl + MunicipalScaffold.contentPadding(context).bottom,
        ),
        children: [
          _StatsRow(stats: stats),
          const SizedBox(height: AppSpacing.md),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No closed reports match your search.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ResolvedReportCard(
                  report: report,
                  cached: cached,
                  onTap: onReportTap == null
                      ? null
                      : () => onReportTap!(report),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final ResolvedReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: AppIcons.success,
            label: 'Resolved',
            value: '${stats.resolvedThisMonth}',
            caption: 'This month',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: AppIcons.eta,
            label: 'Avg Time',
            value: '${stats.avgResolutionDays}d',
            caption: 'vs last month',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: AppIcons.analytics,
            label: 'SLA Met',
            value: '${stats.slaMetPercent}%',
            caption: 'This month',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleLarge),
          Text(
            caption,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : colorScheme.outline,
        ),
      ),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? AppColors.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedReportCard extends StatelessWidget {
  const _ResolvedReportCard({
    required this.report,
    required this.cached,
    this.onTap,
  });

  final ResolvedReportItem report;
  final bool cached;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.referenceId,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ClosedBadge(status: report.status),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            report.title,
            style: textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
                child: Text(
                  report.locationLabel,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.calendar,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                formatResolvedDate(report.resolvedDate),
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                AppIcons.eta,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.isRejected
                      ? 'Rejected after ${report.durationDays}d'
                      : 'Resolved in ${report.durationDays}d',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'View Details',
                style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
              Icon(
                AppIcons.chevronRight,
                size: AppIconSize.sm,
                color: AppColors.primary,
              ),
            ],
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

    Widget block({double? width, double height = 44}) {
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
              borderRadius: AppRadius.allXs,
            ),
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        block(height: 48),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            block(width: 64, height: 32),
            const SizedBox(width: AppSpacing.xs),
            block(width: 96, height: 32),
            const SizedBox(width: AppSpacing.xs),
            block(width: 96, height: 32),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: block(height: 72)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: block(height: 72)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: block(height: 72)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < 3; i++) ...[
          block(height: 150),
          if (i != 2) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

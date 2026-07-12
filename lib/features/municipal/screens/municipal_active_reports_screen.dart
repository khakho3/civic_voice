import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/active_report.dart';
import '../widgets/municipal_scaffold.dart';
import '../widgets/municipal_state_message.dart';
import '../widgets/status_badge.dart';

/// MUN-006 — Active Reports.
///
/// Approved states (Figma "06 - Active Reports" section): Default, Loading,
/// Empty ("No Active Reports"), Error ("Failed to Load Reports"), Offline.
///
/// A bottom-nav tab destination ([MunicipalTab.active]) like Dashboard/Inbox
/// — this is fundamentally a browsable list (search/filter/sort/tap-through),
/// the same shape as MUN-002 Incoming Reports, so it gets the same
/// [MunicipalScaffold] shell with persistent chrome. The approved frames show
/// a back-arrow header instead, but that reads as a stray leftover from a
/// detail-screen template (the same category of mockup slip already
/// corrected in [ActiveReportItem.mock] — Figma frame chrome, not app
/// content, so more prone to copy/paste drift) rather than a deliberate
/// "hide the tab bar when you tap this tab" instruction: [MunicipalTab] was
/// itself confirmed against an approved frame showing all four destinations
/// together, and reusing a persistent nav icon to trigger a chrome-free
/// drill-down would be inconsistent with how every other list screen in this
/// module behaves. "Active Reports" / the zone name are shown via
/// [MunicipalScaffold]'s header title/subtitle rather than an in-content
/// heading — only the Dashboard tab shows the CivicVoice brand mark there;
/// every other tab shows its own screen title.
enum MunicipalActiveReportsViewState { loading, loaded, empty, error, offline }

class MunicipalActiveReportsScreen extends StatefulWidget {
  const MunicipalActiveReportsScreen({
    super.key,
    this.zoneName = 'Downtown Zone',
    this.initialState = MunicipalActiveReportsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToInbox,
    this.onReportTap,
    this.onViewHistory,
    this.onSystemStatus,
  });

  final String zoneName;
  final MunicipalActiveReportsViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs, and to
  /// Empty's "Return to Dashboard" action.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToInbox;

  /// Opens the tapped report's full detail (Report Progress — every report
  /// listed here is already past triage, so Report Review's Verify/Reject
  /// decision doesn't apply).
  final ValueChanged<ActiveReportItem>? onReportTap;

  /// Wired to Empty's "View History" action — no destination screen exists
  /// yet (a future Resolved Reports history view), so this is a stub the
  /// app shell can wire up once that screen exists.
  final VoidCallback? onViewHistory;

  /// Wired to Error's "System Status" action — no status page exists yet,
  /// same as [onViewHistory].
  final VoidCallback? onSystemStatus;

  @override
  State<MunicipalActiveReportsScreen> createState() =>
      _MunicipalActiveReportsScreenState();
}

class _MunicipalActiveReportsScreenState
    extends State<MunicipalActiveReportsScreen> {
  late MunicipalActiveReportsViewState _state = widget.initialState;
  final List<ActiveReportItem> _data = ActiveReportItem.mock();
  final _searchController = TextEditingController();
  ActiveReportFilter _filter = ActiveReportFilter.all;
  ActiveReportSort _sort = ActiveReportSort.mostRecent;

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

  /// Real filtering/sorting/search — matching the interactive treatment
  /// already established on MUN-005's team list, rather than the static
  /// mockup's non-functional chips.
  List<ActiveReportItem> get _visibleReports {
    var reports = _data.toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      reports = reports
          .where(
            (r) =>
                r.referenceId.toLowerCase().contains(query) ||
                r.locationLabel.toLowerCase().contains(query),
          )
          .toList();
    }
    switch (_filter) {
      case ActiveReportFilter.all:
        break;
      case ActiveReportFilter.assigned:
        reports = reports.where((r) => r.status == ReportStatus.assigned).toList();
      case ActiveReportFilter.inProgress:
        reports = reports.where((r) => r.status == ReportStatus.inProgress).toList();
      case ActiveReportFilter.resolved:
        reports = reports.where((r) => r.status == ReportStatus.resolved).toList();
    }
    switch (_sort) {
      case ActiveReportSort.mostRecent:
        break;
      case ActiveReportSort.highestProgress:
        reports.sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
      case ActiveReportSort.lowestProgress:
        reports.sort((a, b) => a.progressPercent.compareTo(b.progressPercent));
    }
    return reports;
  }

  Future<void> _showSortMenu() async {
    final selected = await showModalBottomSheet<ActiveReportSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ActiveReportSort.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _sort
                    ? const Icon(AppIcons.success, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _sort = selected);
  }

  void _retryLoad() {
    setState(() => _state = MunicipalActiveReportsViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalActiveReportsViewState.loaded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MunicipalScaffold(
      selectedTab: MunicipalTab.active,
      // Notifications isn't one of the 9 approved MUN screens (Issue 03
      // §7) — left as a placeholder until that screen is specified.
      onNotificationsTap: () {},
      headerSubtitle: widget.zoneName.toUpperCase(),
      onTabSelected: (tab) {
        if (tab == MunicipalTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MunicipalTab.inbox) widget.onNavigateToInbox?.call();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_state == MunicipalActiveReportsViewState.offline)
            const _OfflineBanner(),
          Expanded(
            child: switch (_state) {
              MunicipalActiveReportsViewState.loading => const _LoadingSkeleton(),
              MunicipalActiveReportsViewState.loaded => _ActiveReportsBody(
                reports: _visibleReports,
                cached: false,
                searchController: _searchController,
                filter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
                onSortTap: _showSortMenu,
                onReportTap: widget.onReportTap,
              ),
              MunicipalActiveReportsViewState.offline => _ActiveReportsBody(
                reports: _visibleReports,
                cached: true,
                searchController: _searchController,
                filter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
                onSortTap: _showSortMenu,
                onReportTap: widget.onReportTap,
              ),
              MunicipalActiveReportsViewState.empty => MunicipalStateMessage(
                icon: AppIcons.empty,
                badgeColor: AppColors.primary,
                title: 'No Active Reports',
                message:
                    'There are no reports currently assigned to '
                    'maintenance teams in this zone. You\'re all caught up.',
                primaryActionLabel: 'View History',
                onPrimaryAction: widget.onViewHistory,
                secondaryActionLabel: 'Return to Dashboard',
                onSecondaryAction: widget.onNavigateToDashboard,
              ),
              MunicipalActiveReportsViewState.error => MunicipalStateMessage(
                icon: AppIcons.warning,
                badgeColor: AppColors.error,
                primaryActionColor: AppColors.error,
                title: 'Failed to Load Reports',
                message:
                    'We couldn\'t fetch the latest reports. Check your '
                    'connection and try again.',
                primaryActionLabel: 'Try again',
                onPrimaryAction: _retryLoad,
                secondaryActionLabel: 'System Status',
                onSecondaryAction: widget.onSystemStatus,
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
// Body (Default / Offline share this — only `cached` differs)
// ---------------------------------------------------------------------------

class _ActiveReportsBody extends StatelessWidget {
  const _ActiveReportsBody({
    required this.reports,
    required this.cached,
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
    required this.onSortTap,
    this.onReportTap,
  });

  final List<ActiveReportItem> reports;
  final bool cached;
  final TextEditingController searchController;
  final ActiveReportFilter filter;
  final ValueChanged<ActiveReportFilter> onFilterChanged;
  final VoidCallback onSortTap;
  final ValueChanged<ActiveReportItem>? onReportTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search report ID or street...',
                  prefixIcon: const Icon(AppIcons.search, size: AppIconSize.md),
                  suffixIcon: IconButton(
                    icon: const Icon(AppIcons.filter, size: AppIconSize.md),
                    onPressed: onSortTap,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ActiveReportFilter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final option = ActiveReportFilter.values[index];
                    return _FilterChip(
                      label: option.label,
                      selected: option == filter,
                      onTap: () => onFilterChanged(option),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${reports.length} report${reports.length == 1 ? '' : 's'}'
                    '${cached ? ' · cached' : ''}',
                    style: textTheme.bodySmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSortTap,
                    child: const Text('Sort'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: reports.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No reports match your search.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ActiveReportCard(
                      report: report,
                      onTap: onReportTap == null
                          ? null
                          : () => onReportTap!(report),
                    );
                  },
                ),
        ),
      ],
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
        side: BorderSide(color: selected ? AppColors.primary : colorScheme.outline),
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
              color: selected ? AppColors.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveReportCard extends StatelessWidget {
  const _ActiveReportCard({required this.report, this.onTap});

  final ActiveReportItem report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppComponentRadius.card,
        side: BorderSide(color: colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: AppComponentRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.referenceId, style: textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                          report.title,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ReportStatusBadge(status: report.status),
                ],
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'PROGRESS',
                    style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
                  ),
                  const Spacer(),
                  Text(
                    '${report.progressPercent}%',
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: AppRadius.allXs,
                child: LinearProgressIndicator(
                  value: report.progressPercent / 100,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainer,
                  color: report.status.color,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.surfaceContainer,
                    child: Icon(
                      AppIcons.team,
                      size: AppIconSize.sm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.teamName, style: textTheme.titleSmall),
                        Text(
                          'ETA ${report.etaLabel} · ${report.updatedLabel}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onTap,
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
            block(width: 112, height: 32),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < 4; i++) ...[
          block(height: 140),
          if (i != 3) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

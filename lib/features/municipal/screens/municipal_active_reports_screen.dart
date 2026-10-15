import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../models/report_status.dart';
import '../models/active_report.dart';
import '../models/incoming_report.dart';
import '../services/municipal_report_directory.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/text_filter_chips.dart';
import '../../../widgets/glass_dialog_backdrop.dart';
import '../widgets/municipal_scaffold.dart';
import '../widgets/municipal_search_field.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/status_badge.dart';

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
/// module behaves. "Active Reports" is shown via [MunicipalScaffold]'s
/// header title rather than an in-content heading — only the Dashboard tab
/// shows the CivicVoice brand mark there; every other tab shows its own
/// screen title. The approved frame's "DOWNTOWN ZONE" subtitle wasn't
/// carried over: it's not backed by any real scoping/filtering, and a
/// single-line header keeps this consistent with every other tab (none of
/// which show a subtitle).
enum MunicipalActiveReportsViewState { loading, loaded, empty, error, offline }

class MunicipalActiveReportsScreen extends StatefulWidget {
  const MunicipalActiveReportsScreen({
    super.key,
    this.initialState = MunicipalActiveReportsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToInbox,
    this.onNavigateToResolvedReports,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onReportTap,
    this.onSystemStatus,
  });

  final MunicipalActiveReportsViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs, and to
  /// Empty's "Return to Dashboard" action.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToInbox;

  /// Wired to the bottom nav's "Resolved" tab, and to Empty's "View
  /// History" action — both the same destination now that MUN-008
  /// Resolved Reports exists, so one callback covers both rather than
  /// keeping a separately named one that did the identical thing.
  final VoidCallback? onNavigateToResolvedReports;

  /// Opens MUN-009 Municipal Profile — wired to the header's profile
  /// avatar, now that it exists.
  final VoidCallback? onProfileTap;

  /// Opens Municipal Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens the tapped report's full detail (Report Progress — every report
  /// listed here is already past triage, so Report Review's Verify/Reject
  /// decision doesn't apply).
  final ValueChanged<IncomingReportItem>? onReportTap;

  /// Wired to Error's "System Status" action — no status page exists yet.
  final VoidCallback? onSystemStatus;

  @override
  State<MunicipalActiveReportsScreen> createState() =>
      _MunicipalActiveReportsScreenState();
}

class _MunicipalActiveReportsScreenState
    extends State<MunicipalActiveReportsScreen> {
  late MunicipalActiveReportsViewState _state = widget.initialState;

  static List<IncomingReportItem> _activeReportsFromDirectory() =>
      MunicipalReportDirectory.instance.reports.value
          .where(
            (r) =>
                r.status == ReportStatus.assigned ||
                r.status == ReportStatus.inProgress ||
                r.status == ReportStatus.pendingApproval ||
                r.status == ReportStatus.resolved,
          )
          .toList();

  /// Reads the live directory once per screen instance (same reactivity
  /// level as MaintenanceTeamDirectory's own consumers elsewhere) — only
  /// reports a team has actually taken on show up here, per the real
  /// Inbox/Active split.
  List<IncomingReportItem> _data = _activeReportsFromDirectory();
  final _searchController = TextEditingController();
  ActiveReportFilter _filter = ActiveReportFilter.all;
  ActiveReportSort _sort = ActiveReportSort.mostRecent;

  @override
  void initState() {
    super.initState();
    MunicipalReportDirectory.instance.reports.addListener(_directoryChanged);
    _searchController.addListener(() => setState(() {}));
  }

  void _directoryChanged() {
    if (mounted) setState(() => _data = _activeReportsFromDirectory());
  }

  @override
  void dispose() {
    MunicipalReportDirectory.instance.reports.removeListener(_directoryChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Real filtering/sorting/search — matching the interactive treatment
  /// already established on MUN-005's team list, rather than the static
  /// mockup's non-functional chips.
  List<IncomingReportItem> get _visibleReports {
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
        reports = reports
            .where((r) => r.status == ReportStatus.assigned)
            .toList();
      case ActiveReportFilter.inProgress:
        reports = reports
            .where((r) => r.status == ReportStatus.inProgress)
            .toList();
      case ActiveReportFilter.pendingApproval:
        reports = reports
            .where((r) => r.status == ReportStatus.pendingApproval)
            .toList();
      case ActiveReportFilter.resolved:
        reports = reports
            .where((r) => r.status == ReportStatus.resolved)
            .toList();
    }
    switch (_sort) {
      case ActiveReportSort.mostRecent:
        break;
      case ActiveReportSort.highestProgress:
        reports.sort(
          (a, b) => (b.progressPercent ?? 0).compareTo(a.progressPercent ?? 0),
        );
      case ActiveReportSort.lowestProgress:
        reports.sort(
          (a, b) => (a.progressPercent ?? 0).compareTo(b.progressPercent ?? 0),
        );
    }
    return reports;
  }

  Future<void> _showSortMenu() async {
    final selected = await showModalBottomSheet<ActiveReportSort>(
      context: context,
      builder: (context) => GlassDialogBackdrop(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in ActiveReportSort.values)
                ListTile(
                  title: Text(option.label),
                  trailing: option == _sort
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
    if (selected != null) setState(() => _sort = selected);
  }

  Future<void> _retryLoad() async {
    setState(() => _state = MunicipalActiveReportsViewState.loading);
    try {
      await MunicipalReportDirectory.instance.refresh();
      if (mounted) {
        setState(() {
          _data = _activeReportsFromDirectory();
          _state = MunicipalActiveReportsViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = MunicipalActiveReportsViewState.error);
      }
    }
  }

  /// Pull-to-refresh's silent counterpart to [_retryLoad] — see
  /// municipal_inbox_screen.dart's identical [_pullToRefresh] for why this
  /// doesn't drop into the full-screen loading state.
  Future<void> _pullToRefresh() async {
    await MunicipalReportDirectory.instance.refresh();
    if (mounted) setState(() => _data = _activeReportsFromDirectory());
  }

  @override
  Widget build(BuildContext context) {
    final chromeInset = MunicipalScaffold.contentPadding(context);
    return MunicipalScaffold(
      selectedTab: MunicipalTab.active,
      onNotificationsTap: widget.onNotificationsTap,
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MunicipalTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MunicipalTab.inbox) widget.onNavigateToInbox?.call();
        if (tab == MunicipalTab.resolved) {
          widget.onNavigateToResolvedReports?.call();
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: chromeInset.top),
          if (_state == MunicipalActiveReportsViewState.offline)
            const _OfflineBanner(),
          Expanded(
            child: switch (_state) {
              MunicipalActiveReportsViewState.loading =>
                const GhanaLoadingIndicator(),
              MunicipalActiveReportsViewState.loaded => GhanaRefreshIndicator(
                onRefresh: _pullToRefresh,
                child: _ActiveReportsBody(
                  reports: _visibleReports,
                  cached: false,
                  searchController: _searchController,
                  filter: _filter,
                  onFilterChanged: (filter) => setState(() => _filter = filter),
                  onSortTap: _showSortMenu,
                  onReportTap: widget.onReportTap,
                ),
              ),
              MunicipalActiveReportsViewState.offline => GhanaRefreshIndicator(
                onRefresh: _pullToRefresh,
                child: _ActiveReportsBody(
                  reports: _visibleReports,
                  cached: true,
                  searchController: _searchController,
                  filter: _filter,
                  onFilterChanged: (filter) => setState(() => _filter = filter),
                  onSortTap: _showSortMenu,
                  onReportTap: widget.onReportTap,
                ),
              ),
              MunicipalActiveReportsViewState.empty => Padding(
                padding: EdgeInsets.only(bottom: chromeInset.bottom),
                child: AppStateMessage(
                  icon: AppIcons.empty,
                  badgeColor: AppColors.primary,
                  title: 'No Active Reports',
                  message:
                      'There are no reports currently assigned to '
                      'maintenance teams in this zone. You\'re all caught up.',
                  primaryActionLabel: 'View History',
                  onPrimaryAction: widget.onNavigateToResolvedReports,
                  secondaryActionLabel: 'Return to Dashboard',
                  onSecondaryAction: widget.onNavigateToDashboard,
                ),
              ),
              MunicipalActiveReportsViewState.error => Padding(
                padding: EdgeInsets.only(bottom: chromeInset.bottom),
                child: AppStateMessage(
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppSemanticColors.of(context).errorText,
              ),
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

  final List<IncomingReportItem> reports;
  final bool cached;
  final TextEditingController searchController;
  final ActiveReportFilter filter;
  final ValueChanged<ActiveReportFilter> onFilterChanged;
  final VoidCallback onSortTap;
  final ValueChanged<IncomingReportItem>? onReportTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              hintText: 'Search report ID or street...',
              screenKey: 'municipal-active',
              results: (query) => [
                for (final item
                    in MunicipalReportDirectory.instance.reports.value.where(
                      (r) =>
                          !r.status.isClosed &&
                          r.status != ReportStatus.submitted &&
                          r.status != ReportStatus.underReview,
                    ))
                  if ('${item.referenceId} ${item.title} ${item.locationLabel}'
                      .toLowerCase()
                      .contains(query.toLowerCase()))
                    FocusedSearchResult(
                      title: item.title,
                      subtitle: item.referenceId,
                      onSelected: onReportTap == null
                          ? null
                          : () => onReportTap!(item),
                    ),
              ],
            ),
            TextFilterChips<ActiveReportFilter>(
              options: [
                for (final option in ActiveReportFilter.values)
                  TextFilterOption(value: option, label: option.label),
              ],
              selected: filter,
              onSelected: onFilterChanged,
              padding: EdgeInsets.zero,
            ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl + MunicipalScaffold.contentPadding(context).bottom,
        ),
        children: [
          Row(
            children: [
              Text(
                '${reports.length} report${reports.length == 1 ? '' : 's'}'
                '${cached ? ' · cached' : ''}',
                style: textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton(onPressed: onSortTap, child: const Text('Sort')),
            ],
          ),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No reports match your search.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          for (final report in reports)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ActiveReportCard(
                report: report,
                onTap: onReportTap == null ? null : () => onReportTap!(report),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveReportCard extends StatelessWidget {
  const _ActiveReportCard({required this.report, this.onTap});

  final IncomingReportItem report;
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
                '${report.progressPercent ?? 0}%',
                style: textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: AppRadius.allXs,
            child: LinearProgressIndicator(
              value: (report.progressPercent ?? 0) / 100,
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
                    Text(
                      report.teamName ?? 'Unassigned',
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      'Updated ${report.updatedLabel ?? '—'}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onTap,
                label: const Text('View Details'),
                icon: const Icon(AppIcons.chevronRight),
                iconAlignment: IconAlignment.end,
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

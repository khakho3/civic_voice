import 'dart:async';
import 'package:flutter/material.dart';
import '../../../widgets/civic_filter_chip.dart';
import '../../../widgets/search_filter_list.dart';
import '../../../widgets/focused_search.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/glass_card.dart';
import '../models/admin_system_activity_data.dart';
import '../models/admin_audit.dart';
import '../services/admin_activity_repository.dart';
import '../services/admin_read_failure.dart';
import '../services/admin_resource.dart';
import 'admin_activity_detail_screen.dart';
import '../services/admin_session.dart';
import '../services/admin_system_activity_directory.dart';
import '../services/admin_system_settings_directory.dart';
import '../widgets/admin_scaffold.dart';

const _kMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatTime12h(DateTime date) {
  final hour24 = date.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

String _formatActivityTimestamp(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return _formatTime12h(date);
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'Yesterday';
  }
  return '${date.day} ${_kMonthNames[date.month - 1]} ${date.year}';
}

/// ADM-006 — System Activity.
///
/// Approved states (Figma "05/System Activity" export): Default, Loading,
/// Empty ("No Activity"), No Results, Offline, Error ("Something went
/// wrong"), Unauthorized — the same seven-state shape as ADM-002 User
/// Management.
///
/// Split visibility, not a whole-screen Super Admin gate like
/// [AdminSystemSettingsScreen]/[AdminRoleManagementScreen]: [SystemHealthStats]
/// (API status/DB latency/uptime) is a national-scope infrastructure
/// readout, Super Admin-only, hidden entirely for an assembly Admin. The
/// audit feed below it is different — an assembly Admin gets it too, just
/// scoped down to their own jurisdiction (accounts provisioned in their
/// assembly, citizens registering from it) via
/// [AdminSession.visibleActivity], never the platform-wide events
/// (policy updates, scheduled backups) that stay Super Admin-only
/// alongside the health stats. `unauthorized` itself is reserved for a
/// non-admin session reaching this route directly, not for a normal
/// assembly Admin viewing their own feed.
///
/// [SystemHealthStats] renders as ordinary scrolling content, not part of
/// [SearchFilterList]'s sticky [SearchFilterList.header] — only
/// the filter chips/time-range dropdown are transient chrome worth hiding
/// on scroll; a health readout is content, same as the activity cards
/// below it.
///
/// "unauthorized" (dark only) pairs with "unauthprized" (a typo, light
/// only) as Unauthorized's two theme variants — the same kind of
/// split-across-two-folders slip already seen throughout this app.
///
/// Promoted to its own bottom-nav tab ([AdminTab.activity]) in place of
/// ADM-004 Role Management — see [AdminTab]'s own doc comment for why —
/// so [AdminScaffold.selectedTab] is [AdminTab.activity] here, same as any
/// other tab's own root screen. It's still also reachable via Dashboard's
/// "Activity Monitoring" card, the same "more than one entry point, still
/// a real tab root" shape [AdminTab.users] already has via Dashboard's own
/// Management row.
///
/// Severity ([ActivitySeverity]) drives each activity card's icon and
/// tint rather than a separate per-item icon field — the approved frame's
/// four icons (shield/sliders/cloud/key) line up one-to-one with its four
/// severities (Critical/Standard/Info/Alert) with no exceptions, so
/// tracking them as one property avoids a state where they could
/// disagree. Only [ActivitySeverity.critical] gets the whole-card red
/// border treatment, matching Role Management's Security Audit callout.
enum AdminSystemActivityViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class AdminSystemActivityScreen extends StatefulWidget {
  const AdminSystemActivityScreen({
    super.key,
    this.initialState = AdminSystemActivityViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToMaintenanceTeams,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.items,
    this.healthStats,
    this.onRefresh,
    this.activitySnapshotAvailable,
    this.healthSnapshotVerified,
    this.repository,
  });

  final AdminSystemActivityViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToMaintenanceTeams;

  /// Forwarded to [AdminScaffold]'s drawer.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;
  final List<ActivityItem>? items;
  final SystemHealthStats? healthStats;
  final Future<void> Function()? onRefresh;

  /// A non-null [items] value is an explicit fixture or parent-provided
  /// snapshot. Callers that know its provenance may override this value.
  final bool? activitySnapshotAvailable;

  /// Health supplied for an isolated fixture is labelled Sample unless the
  /// caller can verify it came from the approved health contract.
  final bool? healthSnapshotVerified;
  final AdminActivityRepository? repository;

  @override
  State<AdminSystemActivityScreen> createState() =>
      _AdminSystemActivityScreenState();
}

class _AdminSystemActivityScreenState extends State<AdminSystemActivityScreen> {
  late AdminSystemActivityViewState _state = widget.initialState;
  // A caller that supplies provenance owns that snapshot, even when an empty
  // test fixture happens to be identical to the directory's empty list.  When
  // provenance is omitted, the app shell's directory-list identity remains a
  // reactive directory path; other lists remain isolated fixtures.
  late final bool _usesDirectorySnapshot =
      widget.activitySnapshotAvailable == null &&
      (widget.items == null ||
          identical(
            widget.items,
            AdminSystemActivityDirectory.instance.items.value,
          ));

  bool get _hasActivitySnapshot =>
      widget.activitySnapshotAvailable ??
      (_usesDirectorySnapshot
          ? AdminSystemActivityDirectory.instance.hasLiveSnapshot
          : widget.items != null);

  List<ActivityItem> get _items => _usesDirectorySnapshot
      ? AdminSystemActivityDirectory.instance.items.value
      : (widget.items ?? const <ActivityItem>[]);

  SystemHealthStats? get _healthStats => _usesDirectorySnapshot
      ? AdminSystemActivityDirectory.instance.health.value
      : widget.healthStats;

  _HealthPresentation get _healthPresentation {
    if (_healthStats == null) return _HealthPresentation.unavailable;
    final verified =
        widget.healthSnapshotVerified ??
        (_usesDirectorySnapshot &&
            AdminSystemActivityDirectory.instance.hasLiveHealthSnapshot);
    return verified ? _HealthPresentation.live : _HealthPresentation.sample;
  }

  bool get _canRetry =>
      widget.onRefresh != null &&
      (!_usesDirectorySnapshot ||
          AdminSystemActivityDirectory.instance.canRefresh);
  bool get _showStaleActivity =>
      _usesDirectorySnapshot &&
      AdminSystemActivityDirectory.instance.state.value ==
          AdminSystemActivityDirectoryState.failed &&
      _hasActivitySnapshot;
  ActivityFilter _filter = ActivityFilter.all;
  ActivityTimeRange _timeRange = ActivityTimeRange.last24Hours;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.repository == null && _canRetry &&
        widget.initialState == AdminSystemActivityViewState.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await widget.onRefresh?.call();
        } catch (_) {
          if (mounted) {
            setState(
              () => _state = _hasActivitySnapshot
                  ? AdminSystemActivityViewState.loaded
                  : AdminSystemActivityViewState.error,
            );
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AdminSystemActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialState != oldWidget.initialState) {
      _state = widget.initialState;
    }
  }

  Future<void> _retry() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return;
    if (!_hasActivitySnapshot) {
      setState(() => _state = AdminSystemActivityViewState.loading);
    }
    try {
      await onRefresh();
      if (mounted) setState(() => _state = AdminSystemActivityViewState.loaded);
    } catch (_) {
      if (mounted) {
        setState(
          () => _state = _hasActivitySnapshot
              ? AdminSystemActivityViewState.loaded
              : AdminSystemActivityViewState.error,
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filter = ActivityFilter.all;
      _timeRange = ActivityTimeRange.last24Hours;
      _searchController.clear();
      _searchQuery = '';
      _state = AdminSystemActivityViewState.loaded;
    });
  }

  Widget _wrapWithRefresh(Widget child) {
    final onRefresh = widget.onRefresh;
    if (!_canRetry || onRefresh == null) return child;
    return GhanaRefreshIndicator(
      onRefresh: onRefresh,
      // The header paints on top of this content (a later sibling in
      // AdminScaffold's own Stack); child's own top SizedBox pushes its
      // content down but doesn't move where GhanaRefreshIndicator itself
      // anchors its star/bar, so this still needs to be set explicitly.
      topOffset: AdminScaffold.contentPadding(context).top,
      child: child,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chromeEnabled =
        _state == AdminSystemActivityViewState.empty ||
        _state == AdminSystemActivityViewState.noResults;
    return AnimatedBuilder(
      animation: _usesDirectorySnapshot
          ? Listenable.merge([
              AdminSystemActivityDirectory.instance.items,
              AdminSystemActivityDirectory.instance.health,
              AdminSystemActivityDirectory.instance.state,
            ])
          : const _NoopListenable(),
      builder: (context, _) {
        // Read these inside the reactive builder. Values captured before the
        // [AnimatedBuilder] retain the initial directory state after a
        // notifier update, which can leave an unavailable view on screen
        // while the directory is genuinely loading (or the reverse).
        final directoryLoading =
            _usesDirectorySnapshot &&
            AdminSystemActivityDirectory.instance.state.value ==
                AdminSystemActivityDirectoryState.loading;
        final directoryUnavailable =
            _usesDirectorySnapshot &&
            AdminSystemActivityDirectory.instance.state.value ==
                AdminSystemActivityDirectoryState.unavailable;

        return AdminScaffold(
      selectedTab: AdminTab.activity,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.maintenance) {
          widget.onNavigateToMaintenanceTeams?.call();
        }
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: widget.onNavigateToMaintenanceTeams,
      onOpenProfile: widget.onOpenProfile,
      body: widget.repository != null
          ? _LiveActivityBody(
              repository: widget.repository!,
              healthStats: _healthStats,
              healthPresentation: _healthPresentation,
            )
          : directoryLoading && !_hasActivitySnapshot
          ? const _LoadingSkeleton()
          : directoryUnavailable &&
                !_canRetry &&
                !_hasActivitySnapshot &&
                (_state == AdminSystemActivityViewState.loading ||
                    _state == AdminSystemActivityViewState.loaded)
          ? _UnavailableActivity(onRetry: _canRetry ? _retry : null)
          : _state == AdminSystemActivityViewState.loaded &&
                !_hasActivitySnapshot
          ? _UnavailableActivity(onRetry: _canRetry ? _retry : null)
          : switch (_state) {
                  AdminSystemActivityViewState.loading =>
                    const _LoadingSkeleton(),
        AdminSystemActivityViewState.loaded => _wrapWithRefresh(
          Column(
            children: [
                        SizedBox(
                          height: AdminScaffold.contentPadding(context).top,
                        ),
              Expanded(
                          child: SearchFilterList.builder(
                            headerBuilder: (compact) => _FilterChrome(
                              compact: compact,
                    filter: _filter,
                    searchController: _searchController,
                    enabled: true,
                              onFilterSelected: (f) =>
                                  setState(() => _filter = f),
                              onSearchChanged: (q) =>
                                  setState(() => _searchQuery = q),
                              results: (term) => [
                                for (final item
                                    in AdminSession.instance.visibleActivity(
                                      _items,
                                    ))
                                  if (_filter.matches(item) &&
                                      item.matchesTimeRange(_timeRange) &&
                                      item.matchesQuery(term))
                                    FocusedSearchResult(
                                      title: item.title,
                                      subtitle: item.description,
                  ),
                              ],
                            ),
                  child: _ActivityList(
                    healthStats: _healthStats,
                    healthPresentation: _healthPresentation,
                              items: AdminSession.instance.visibleActivity(
                                _items,
                              ),
                    liveAudit: _hasActivitySnapshot,
                    showStaleActivity: _showStaleActivity,
                    filter: _filter,
                    timeRange: _timeRange,
                    onTimeRangeChanged: (range) =>
                        setState(() => _timeRange = range),
                    searchQuery: _searchQuery,
                    onClearFilters: _clearFilters,
                  ),
                ),
              ),
            ],
          ),
        ),
        _ => Column(
          children: [
                      SizedBox(
                        height: AdminScaffold.contentPadding(context).top,
                      ),
            _FilterChrome(
              filter: _filter,
              searchController: _searchController,
              enabled: chromeEnabled,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
              onSearchChanged: chromeEnabled
                  ? (q) => setState(() => _searchQuery = q)
                  : null,
            ),
            Expanded(
              child: switch (_state) {
                AdminSystemActivityViewState.loading ||
                          AdminSystemActivityViewState.loaded =>
                            const SizedBox.shrink(),
                AdminSystemActivityViewState.empty => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.search,
                    badgeColor: AppColors.primary,
                    title: 'No Activity',
                    message:
                        'There are no audit events to display for the '
                        'selected period.',
                    bordered: true,
                  ),
                ),
                AdminSystemActivityViewState.noResults => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.search,
                    badgeColor: AppColors.primary,
                    title: 'No Results',
                    message:
                        'No activity matches the current search and '
                        'filter selection.',
                    primaryActionLabel: 'Clear Filters',
                    onPrimaryAction: _clearFilters,
                    bordered: true,
                  ),
                ),
                AdminSystemActivityViewState.offline => AppStateMessage(
                  icon: AppIcons.offline,
                  badgeColor: AppColors.error,
                  title: 'You\'re offline',
                  message:
                      'Check your connection and retry loading system '
                      'activity.',
                  primaryActionLabel: 'Retry connection',
                  onPrimaryAction: _canRetry ? _retry : null,
                  primaryActionColor: AppColors.error,
                  bordered: true,
                ),
                AdminSystemActivityViewState.error => AppStateMessage(
                  icon: AppIcons.warning,
                  badgeColor: AppColors.error,
                  title: 'Something went wrong',
                  message: 'Unable to load audit activity right now.',
                  primaryActionLabel: 'Retry',
                  onPrimaryAction: _canRetry ? _retry : null,
                  primaryActionColor: AppColors.error,
                  bordered: true,
                ),
                AdminSystemActivityViewState.unauthorized =>
                  const AppStateMessage(
                    icon: AppIcons.permissionDenied,
                    badgeColor: AppColors.error,
                    title: 'Unauthorized Access',
                    message:
                        'Administrative privileges are required to view '
                        'audit activity.',
                    bordered: true,
                  ),
              },
            ),
          ],
        ),
      },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chrome — filter chips, time-range dropdown
// ---------------------------------------------------------------------------

/// The live path uses the server's filters, scoped counts and cursor pages.
/// Fixture/preview callers above retain their explicit, Firebase-free snapshots.
class _LiveActivityBody extends StatefulWidget {
  const _LiveActivityBody({
    required this.repository,
    required this.healthStats,
    required this.healthPresentation,
  });
  final AdminActivityRepository repository;
  final SystemHealthStats? healthStats;
  final _HealthPresentation healthPresentation;
  @override
  State<_LiveActivityBody> createState() => _LiveActivityBodyState();
}

class _LiveActivityBodyState extends State<_LiveActivityBody> {
  late final _repo = widget.repository;
  late final _initialOwner = _repo.owner();
  late AdminResource<AuditPage> _source;
  final _scroll = ScrollController();
  final _refinements = <String, TextEditingController>{
    for (final key in ['action', 'actorId', 'subjectType', 'subjectId'])
      key: TextEditingController(),
  };
  final _query = <String, String>{};
  List<String?> _cursors = [null];
  ActivityTimeRange _range = ActivityTimeRange.last24Hours;
  String _search = '', _category = '', _severity = '', _outcome = '';
  String? _inputError;
  AuditPage? _verified;
  String? _verifiedOwner;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _setWindow();
    _create();
    if (_repo.owner() != null) {
      unawaited(AdminSystemActivityDirectory.instance.refreshHealth());
    }
  }

  void _setWindow() {
    _query.remove('from');
    _query.remove('to');
    if (_range.window != null) {
      _query['from'] = DateTime.now()
          .toUtc()
          .subtract(_range.window!)
          .toIso8601String();
    }
  }

  Future<void> _create() {
    _source = _repo.page({
      ..._query,
      if (_cursors.last != null) 'cursor': _cursors.last!,
    });
    return _source.load();
  }

  void _change(VoidCallback change, {bool page = false}) {
    setState(() {
      _source.dispose();
      change();
      if (!page) _cursors = [null];
      _verified = null;
      _verifiedOwner = null;
      _create();
    });
  }

  void _filter(String key, String value) {
    if (key == 'q' && value.trim().length > 200) {
      setState(() {
        _search = value;
        _inputError =
            'Search supports up to 200 characters. Results use the last valid search.';
      });
      return;
    }
    _change(() {
      if (key == 'q') _inputError = null;
      if (value.trim().isEmpty) {
        _query.remove(key);
      } else {
        _query[key] = value.trim();
      }
      if (key == 'q') _search = value.trim();
      if (key == 'category') _category = value;
      if (key == 'severity') _severity = value;
      if (key == 'outcome') _outcome = value;
    });
  }

  Future<void> _refresh() async {
    late Future<void> read;
    setState(() {
      _source.dispose();
      if (_range.window != null) _setWindow();
      read = _create();
    });
    await Future.wait([
      read,
      AdminSystemActivityDirectory.instance.refreshHealth(),
    ]);
  }

  Future<void> _open(AuditEvent event) async {
    if (_opening || _repo.owner() == null) return;
    _opening = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: AdminActivityDetailScreen.routeName,
          arguments: AuditDetailArguments(event.id),
        ),
        builder: (_) => AdminActivityDetailScreen(
          id: event.id,
          repository: _repo,
          fromActivity: true,
        ),
      ),
    );
    _opening = false;
  }

  Future<void> _customDates() async {
    final from = DateTime.tryParse(_query['from'] ?? '');
    final to = DateTime.tryParse(_query['to'] ?? '');
    final lastDay = to?.subtract(const Duration(days: 1));
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: from != null && lastDay != null
          ? DateTimeRange(
              start: DateTime(from.year, from.month, from.day),
              end: DateTime(lastDay.year, lastDay.month, lastDay.day),
            )
          : null,
    );
    if (!mounted || dates == null) return;
    _change(() {
      _range = ActivityTimeRange.allTime;
      _query['from'] = DateTime.utc(
        dates.start.year,
        dates.start.month,
        dates.start.day,
      ).toIso8601String();
      _query['to'] = DateTime.utc(
        dates.end.year,
        dates.end.month,
        dates.end.day,
      ).add(const Duration(days: 1)).toIso8601String();
    });
  }

  @override
  void dispose() {
    _source.dispose();
    _scroll.dispose();
    for (final controller in _refinements.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      _source,
      AdminActivityRepository.sessionChanges,
    ]),
    builder: (context, _) {
      final owner = _repo.owner();
      final denied =
          owner == null ||
          owner != _initialOwner ||
          _source.failure == AdminReadFailure.unauthorized;
      final fresh = _source.data;
      if (fresh != null) {
        _verified = fresh;
        _verifiedOwner = owner;
      }
      final page = denied
          ? null
          : fresh ?? (_verifiedOwner == owner ? _verified : null);
      return Column(
        children: [
          SizedBox(height: AdminScaffold.contentPadding(context).top),
          Expanded(
            child: denied
                ? const _ActivityAccessRequired()
                : SearchFilterList.builder(
                    headerBuilder: (compact) => SearchFilterHeader(
                      screenKey: 'admin-activity',
                      hintText: 'Search activity',
                      query: _search,
                      compact: compact,
                      onQueryChanged: (q) => _filter('q', q),
                      results: (term) => [
                        for (final event in page?.events ?? <AuditEvent>[])
                          if ('${event.item.title} ${event.item.description} ${event.fields['actorName'] ?? ''} ${event.item.tag}'
                              .toLowerCase()
                              .contains(term.toLowerCase()))
                            FocusedSearchResult(
                              title: event.item.title,
                              subtitle: auditTimestamp(event.item.timestamp),
                              onSelected: () => _open(event),
                            ),
                      ],
                      filters: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: auditCategories.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final category = auditCategories.entries.elementAt(
                              index,
                            );
                            return CivicFilterChip(
                              label: category.value,
                              selected: _category == category.key,
                              onTap: () => _filter('category', category.key),
                            );
                          },
                        ),
                      ),
                    ),
                    child: GhanaRefreshIndicator(
                      topOffset: 0,
                      onRefresh: _refresh,
                      child: ListView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AdminScaffold.contentPadding(context).bottom +
                              AppSpacing.xl,
                        ),
                        children: [
                          SizedBox(
                            child: _inputError == null
                                ? null
                                : Text(_inputError!),
                          ),
                          _TimeRangeDropdown(
                            value: _range,
                            enabled: true,
                            customSelected: _query.containsKey('to'),
                            onCustomDates: _customDates,
                            onChanged: (range) => _change(() {
                              _range = range;
                              _setWindow();
                            }),
                          ),
                          SizedBox(
                            child: _query.containsKey('to')
                                ? Text(
                                    '${_query['from']} to ${_query['to']} (end exclusive)',
                                  )
                                : null,
                          ),
                          ExpansionTile(
                            title: const Text('Refine activity'),
                            tilePadding: EdgeInsets.zero,
                            children: [
                              AppDropdownField<String>(
                                hint: 'Severity',
                                value: _severity,
                                items: [
                                  for (final v in [
                                    '',
                                    'INFO',
                                    'STANDARD',
                                    'ALERT',
                                    'CRITICAL',
                                  ])
                                    AppDropdownItem(
                                      value: v,
                                      label: v.isEmpty ? 'All severities' : v,
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) _filter('severity', v);
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppDropdownField<String>(
                                hint: 'Outcome',
                                value: _outcome,
                                items: [
                                  for (final v in [
                                    '',
                                    'SUCCESS',
                                    'FAILED',
                                    'DENIED',
                                    'UNKNOWN',
                                  ])
                                    AppDropdownItem(
                                      value: v,
                                      label: v.isEmpty ? 'All outcomes' : v,
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) _filter('outcome', v);
                                },
                              ),
                              for (final entry in _refinements.entries)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.sm,
                                  ),
                                  child: TextField(
                                    controller: entry.value,
                                    maxLength: 100,
                                    decoration: InputDecoration(
                                      labelText: const {
                                        'action': 'Action',
                                        'actorId': 'Actor ID',
                                        'subjectType': 'Target type',
                                        'subjectId': 'Target reference',
                                      }[entry.key],
                                    ),
                                    onSubmitted: (value) =>
                                        _filter(entry.key, value),
                                  ),
                                ),
                              TextButton(
                                onPressed: () => _change(() {
                                  _query.clear();
                                  _inputError = null;
                                  _search = '';
                                  _category = '';
                                  _severity = '';
                                  _outcome = '';
                                  for (final controller
                                      in _refinements.values) {
                                    controller.clear();
                                  }
                                  _range = ActivityTimeRange.last24Hours;
                                  _setWindow();
                                }),
                                child: const Text('Reset filters'),
                              ),
                            ],
                          ),
                          if (AdminSession.instance.isSuperAdmin) ...[
                            if (widget.healthStats != null)
                              _HealthStatsRow(
                                stats: widget.healthStats!,
                                presentation: widget.healthPresentation,
                              )
                            else
                              const _HealthUnavailableNotice(),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (_source.loading && page == null)
                            const SizedBox(
                              height: 180,
                              child: GhanaLoadingIndicator(
                                label: 'Loading activity',
                              ),
                            ),
                          if (_source.loading && page != null)
                            const Text('Updating activity…'),
                          if (_source.error != null) ...[
                            Text(
                              page == null
                                  ? 'Activity could not be verified.'
                                  : 'The latest activity could not be refreshed. Showing the last authorized snapshot.',
                            ),
                            TextButton(
                              onPressed: _source.load,
                              child: const Text('Retry'),
                            ),
                          ],
                          if (page != null) ...[
                            if (!page.collectionEnabled)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Text(
                                  'Audit collection is off. Existing history remains available; ordinary new events are not recorded.',
                                ),
                              ),
                            Text(
                              'Audit history',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${page.total} events · ${page.alertCount} alert events',
                            ),
                            const Text(
                              'Alert events are recorded warnings, not a count of unresolved incidents.',
                            ),
                            if (page.events.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: Text(
                                  'No activity matches your search and filters.',
                                ),
                              ),
                            for (final event in page.events)
                              Padding(
                                key: ValueKey('audit-event-${event.id}'),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: _ActivityCard(
                                  key: ValueKey(event.id),
                                  item: event.item,
                                  fullTimestamp: true,
                                  onOpen: () => _open(event),
                                ),
                              ),
                            Wrap(
                              spacing: AppSpacing.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton(
                                  onPressed:
                                      _source.loading || _cursors.length < 2
                                      ? null
                                      : () => _change(() {
                                          _cursors.removeLast();
                                        }, page: true),
                                  child: const Text('Previous'),
                                ),
                                Text('Page ${_cursors.length}'),
                                TextButton(
                                  onPressed:
                                      _source.loading ||
                                          page.nextCursor == null ||
                                          _cursors.contains(page.nextCursor)
                                      ? null
                                      : () => _change(() {
                                          _cursors.add(page.nextCursor);
                                        }, page: true),
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    },
  );
}

class _ActivityAccessRequired extends StatelessWidget {
  const _ActivityAccessRequired();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    padding: EdgeInsets.all(AppSpacing.md),
    child: AppStateMessage(
      icon: AppIcons.permissionDenied,
      badgeColor: AppColors.error,
      title: 'Administrative access required',
      message:
          'Sign in with an active administrator account to view audit activity.',
    ),
  );
}

class _NoopListenable implements Listenable {
  const _NoopListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _UnavailableActivity extends StatelessWidget {
  const _UnavailableActivity({this.onRetry});

  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AdminScaffold.contentPadding(context).top + AppSpacing.md,
        AppSpacing.md,
        AdminScaffold.contentPadding(context).bottom + AppSpacing.md,
      ),
      child: AppStateMessage(
        icon: AppIcons.offline,
        badgeColor: AppColors.error,
        title: 'Activity data unavailable',
        message:
            'Audit activity is unavailable until an authorized live snapshot is supplied.',
        primaryActionLabel: onRetry == null ? null : 'Retry',
        onPrimaryAction: retry == null ? null : () => retry(),
        primaryActionColor: AppColors.error,
        bordered: true,
      ),
    );
  }
}

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.filter,
    required this.searchController,
    required this.enabled,
    this.compact = false,
    this.results = emptySearchResults,
    this.onFilterSelected,
    this.onSearchChanged,
  });

  final ActivityFilter filter;
  final TextEditingController searchController;
  final bool enabled;
  final ValueChanged<ActivityFilter>? onFilterSelected;
  final ValueChanged<String>? onSearchChanged;

  final bool compact;
  final FocusedSearchResultsBuilder results;
  @override
  Widget build(BuildContext context) => SearchFilterHeader(
    screenKey: 'admin-activity',
                hintText: 'Search activity',
    query: searchController.text,
    enabled: enabled,
    compact: compact,
    results: results,
    onQueryChanged: (value) {
      searchController.text = value;
      onSearchChanged?.call(value);
                  },

    filters: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ActivityFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final option = ActivityFilter.values[index];
                  return CivicFilterChip(
                    label: option.label,
                    selected: option == filter,
            onTap: enabled ? () => onFilterSelected?.call(option) : null,
                  );
                },
              ),
            ),
    );
  }

enum _HealthPresentation { live, sample, unavailable }

class _HealthStatsRow extends StatelessWidget {
  const _HealthStatsRow({required this.stats, required this.presentation});

  final SystemHealthStats stats;
  final _HealthPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final isLive = presentation == _HealthPresentation.live;
    return Semantics(
      label: 'System health: ${isLive ? 'Live' : 'Sample'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLive ? 'Live system health' : 'Sample system health',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _HealthStatCard(
                    icon: AppIcons.activityPulse,
                    label: 'API Status',
                    value: stats.apiOnline ? 'Online' : 'Offline',
                    valueColor: stats.apiOnline
                        ? AppColors.statusResolved
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HealthStatCard(
                    icon: AppIcons.database,
                    label: 'DB Latency',
                    value: stats.databaseOnline
                        ? '${stats.dbLatencyMs}ms'
                        : 'Offline',
                    valueColor: stats.databaseOnline
                        ? AppColors.statusResolved
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HealthStatCard(
                    icon: AppIcons.resolutionGauge,
                    label: 'Uptime',
                    value: stats.uptimeLabel,
                    valueColor: AppColors.statusResolved,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthUnavailableNotice extends StatelessWidget {
  const _HealthUnavailableNotice();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'System health unavailable',
    child: GlassCard(
      child: Text(
        'System health unavailable until an authorized live snapshot is supplied.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _StaleActivityNotice extends StatelessWidget {
  const _StaleActivityNotice();

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Text(
      'The latest activity could not be refreshed. Showing the last authorized snapshot.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _HealthStatCard extends StatelessWidget {
  const _HealthStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
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
                  label,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


class _TimeRangeDropdown extends StatelessWidget {
  const _TimeRangeDropdown({
    required this.value,
    required this.enabled,
    this.onChanged,
    this.onCustomDates,
    this.customSelected = false,
  });

  final ActivityTimeRange value;
  final bool enabled;
  final ValueChanged<ActivityTimeRange>? onChanged;
  final VoidCallback? onCustomDates;
  final bool customSelected;
  static const _customDatesValue = 'custom-dates';

  @override
  Widget build(BuildContext context) {
    if (onCustomDates != null) {
      return AppDropdownField<Object>(
        key: const ValueKey('activity-time-range'),
        hint: '',
        value: customSelected ? _customDatesValue : value,
        leadingIcon: AppIcons.calendar,
        glass: true,
        items: [
          for (final range in ActivityTimeRange.values)
            AppDropdownItem<Object>(value: range, label: range.label),
          const AppDropdownItem<Object>(
            value: _customDatesValue,
            label: 'Custom dates (UTC)',
          ),
        ],
        onChanged: enabled
            ? (selected) {
                if (selected == _customDatesValue) {
                  onCustomDates!();
                } else if (selected is ActivityTimeRange) {
                  onChanged?.call(selected);
                }
              }
            : null,
      );
    }
    return AppDropdownField<ActivityTimeRange>(
      hint: '',
      value: value,
      leadingIcon: AppIcons.calendar,
      glass: true,
      items: [
        for (final range in ActivityTimeRange.values)
          AppDropdownItem(value: range, label: range.label),
      ],
      onChanged: enabled
          ? (selected) {
              if (selected != null) onChanged?.call(selected);
            }
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Activity list
// ---------------------------------------------------------------------------

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.healthStats,
    required this.healthPresentation,
    required this.items,
    required this.filter,
    required this.timeRange,
    required this.onTimeRangeChanged,
    required this.searchQuery,
    required this.onClearFilters,
    required this.liveAudit,
    required this.showStaleActivity,
  });

  final SystemHealthStats? healthStats;
  final _HealthPresentation healthPresentation;
  final List<ActivityItem> items;
  final ActivityFilter filter;
  final ActivityTimeRange timeRange;
  final ValueChanged<ActivityTimeRange> onTimeRangeChanged;
  final String searchQuery;
  final VoidCallback onClearFilters;
  final bool liveAudit;
  final bool showStaleActivity;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AdminScaffold.contentPadding(context).bottom;
    final settingsDirectory = AdminSystemSettingsDirectory.instance;
    // The directory's conservative local defaults are not server policy.
    // A confirmed settings snapshot, however, must override even a confirmed
    // historical activity snapshot so the feed is not presented as current
    // recording after audit logging has been disabled.
    final auditLoggingOn = settingsDirectory.hasLiveSnapshot
        ? settingsDirectory.settings.value.auditLogging
        : liveAudit;
    final filtered = items
        .where(
          (i) =>
              filter.matches(i) &&
              i.matchesTimeRange(timeRange) &&
              i.matchesQuery(searchQuery),
        )
        .toList();

    return ListView(
      // Stays draggable even when the collapsed chrome lets a short (e.g.
      // filtered-down) list fit the viewport — see Municipal's own list
      // screens for the failure mode this prevents.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _TimeRangeDropdown(
            value: timeRange,
            enabled: true,
            onChanged: onTimeRangeChanged,
          ),
        ),
        if (showStaleActivity) ...[
          const _StaleActivityNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        if (AdminSession.instance.isSuperAdmin && healthStats != null) ...[
          _HealthStatsRow(
            stats: healthStats!,
            presentation: healthPresentation,
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (AdminSession.instance.isSuperAdmin) ...[
          const _HealthUnavailableNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (!auditLoggingOn)
          const _AuditLoggingOffNotice()
        else if (filtered.isEmpty)
          _InlineEmptyHint(onClear: onClearFilters)
        else
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ActivityCard(item: item),
            ),
      ],
    );
  }
}

/// Shown instead of the activity feed when ADM-007 System Settings' "Audit
/// logging" is off — the feed reads from that same directory, so this is
/// the real, honest state of "there's nothing being recorded right now,"
/// not a cosmetic empty state.
class _AuditLoggingOffNotice extends StatelessWidget {
  const _AuditLoggingOffNotice();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            AppIcons.activityLog,
            size: AppIconSize.lg,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Audit logging is turned off',
            style: textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No administrative activity is being recorded. Turn it back on '
            'in System Settings to resume the audit trail.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            'No activity matches your filters.',
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    super.key,
    required this.item,
    this.onOpen,
    this.fullTimestamp = false,
  });

  final ActivityItem item;
  final VoidCallback? onOpen;
  final bool fullTimestamp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final critical = item.severity == ActivitySeverity.critical;

    return GlassCard(
      onTap: onOpen,
      border: critical
          ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.lg,
            height: AppIconSize.lg,
            decoration: BoxDecoration(
              color: item.severity.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.severity.icon,
              size: AppIconSize.sm + 2,
              color: item.severity.color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fullTimestamp) ...[
                  Text(
                    item.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: critical ? AppColors.error : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    auditTimestamp(item.timestamp),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: critical ? AppColors.error : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatActivityTimestamp(item.timestamp),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(item.description, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Pill(
                      label: item.severity.label,
                      color: item.severity.color,
                    ),
                    _Pill(label: item.tag, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppFontWeight.semiBold,
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final chromeInset = AdminScaffold.contentPadding(context);

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

    Widget cardBlock() => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(width: 32, height: 32, radius: 16),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(height: 14, width: 160),
                const SizedBox(height: AppSpacing.sm),
                block(height: 12),
                const SizedBox(height: AppSpacing.xs),
                block(height: 12, width: 180),
                const SizedBox(height: AppSpacing.sm),
                block(height: 20, width: 90, radius: 10),
              ],
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        block(height: 40, radius: 20),
        const SizedBox(height: AppSpacing.sm),
        block(height: 48, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 16, width: 120),
        const SizedBox(height: AppSpacing.sm),
        if (AdminSession.instance.isSuperAdmin) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: block(height: 76, radius: 12)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: block(height: 76, radius: 12)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: block(height: 76, radius: 12)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        cardBlock(),
        const SizedBox(height: AppSpacing.sm),
        cardBlock(),
        const SizedBox(height: AppSpacing.sm),
        cardBlock(),
      ],
    );
  }
}

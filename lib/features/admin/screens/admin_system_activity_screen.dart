import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/admin_system_activity_data.dart';
import '../services/admin_session.dart';
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
/// [CollapsibleListHeader]'s sticky [CollapsibleListHeader.header] — only
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

  @override
  State<AdminSystemActivityScreen> createState() =>
      _AdminSystemActivityScreenState();
}

class _AdminSystemActivityScreenState extends State<AdminSystemActivityScreen> {
  late AdminSystemActivityViewState _state = widget.initialState;
  SystemHealthStats? get _healthStats =>
      widget.healthStats ??
      (widget.items == null ? mockSystemHealthStats() : null);
  List<ActivityItem> get _items =>
      widget.items ??
      AdminSession.instance.visibleActivity(mockActivityItems());
  ActivityFilter _filter = ActivityFilter.all;
  ActivityTimeRange _timeRange = ActivityTimeRange.last24Hours;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.onRefresh != null &&
        widget.initialState == AdminSystemActivityViewState.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await widget.onRefresh?.call();
        } catch (_) {
          if (mounted) {
            setState(() => _state = AdminSystemActivityViewState.error);
          }
        }
      });
    }
  }

  Future<void> _retry() async {
    setState(() => _state = AdminSystemActivityViewState.loading);
    try {
      await (widget.onRefresh?.call() ??
          Future<void>.delayed(const Duration(milliseconds: 500)));
      if (mounted) setState(() => _state = AdminSystemActivityViewState.loaded);
    } catch (_) {
      if (mounted) setState(() => _state = AdminSystemActivityViewState.error);
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
    if (onRefresh == null) return child;
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
      body: switch (_state) {
        AdminSystemActivityViewState.loading => const _LoadingSkeleton(),
        AdminSystemActivityViewState.loaded => _wrapWithRefresh(
          Column(
            children: [
              SizedBox(height: AdminScaffold.contentPadding(context).top),
              Expanded(
                child: CollapsibleListHeader(
                  header: _FilterChrome(
                    filter: _filter,
                    timeRange: _timeRange,
                    searchController: _searchController,
                    enabled: true,
                    onFilterSelected: (f) => setState(() => _filter = f),
                    onTimeRangeChanged: (r) => setState(() => _timeRange = r),
                    onSearchChanged: (q) => setState(() => _searchQuery = q),
                  ),
                  child: _ActivityList(
                    healthStats: _healthStats,
                    items: _items,
                    liveAudit: widget.items != null,
                    filter: _filter,
                    timeRange: _timeRange,
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
            SizedBox(height: AdminScaffold.contentPadding(context).top),
            _FilterChrome(
              filter: _filter,
              timeRange: _timeRange,
              searchController: _searchController,
              enabled: chromeEnabled,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
              onTimeRangeChanged: chromeEnabled
                  ? (r) => setState(() => _timeRange = r)
                  : null,
              onSearchChanged: chromeEnabled
                  ? (q) => setState(() => _searchQuery = q)
                  : null,
            ),
            Expanded(
              child: switch (_state) {
                AdminSystemActivityViewState.loading ||
                AdminSystemActivityViewState.loaded => const SizedBox.shrink(),
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
                  onPrimaryAction: _retry,
                  primaryActionColor: AppColors.error,
                  bordered: true,
                ),
                AdminSystemActivityViewState.error => AppStateMessage(
                  icon: AppIcons.warning,
                  badgeColor: AppColors.error,
                  title: 'Something went wrong',
                  message: 'Unable to load audit activity right now.',
                  primaryActionLabel: 'Retry',
                  onPrimaryAction: _retry,
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
  }
}

// ---------------------------------------------------------------------------
// Filter chrome — filter chips, time-range dropdown
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.filter,
    required this.timeRange,
    required this.searchController,
    required this.enabled,
    this.onFilterSelected,
    this.onTimeRangeChanged,
    this.onSearchChanged,
  });

  final ActivityFilter filter;
  final ActivityTimeRange timeRange;
  final TextEditingController searchController;
  final bool enabled;
  final ValueChanged<ActivityFilter>? onFilterSelected;
  final ValueChanged<ActivityTimeRange>? onTimeRangeChanged;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              enabled: enabled,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              // Glass — see MunicipalSearchField's doc comment: search
              // containers are permitted glass per §19.10, but the global
              // inputDecorationTheme also backs actual forms (prohibited),
              // so this is an explicit per-instance fill, not a theme change.
              decoration: InputDecoration(
                filled: true,
                fillColor: semantic.glassSurface,
                isDense: true,
                hintText: 'Search activity',
                prefixIcon: const Icon(AppIcons.search, size: AppIconSize.sm),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(AppIcons.close, size: AppIconSize.sm),
                      tooltip: 'Clear search',
                      onPressed: enabled
                          ? () {
                              searchController.clear();
                              onSearchChanged?.call('');
                            }
                          : null,
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: AppComponentRadius.inputField,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ActivityFilter.values.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final option = ActivityFilter.values[index];
                  return _FilterChip(
                    label: option.label,
                    selected: option == filter,
                    onTap: enabled
                        ? () => onFilterSelected?.call(option)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TimeRangeDropdown(
              value: timeRange,
              enabled: enabled,
              onChanged: onTimeRangeChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Recent Activity', style: textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health stats — API status, DB latency, uptime
// ---------------------------------------------------------------------------

class _HealthStatsRow extends StatelessWidget {
  const _HealthStatsRow({required this.stats});

  final SystemHealthStats stats;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
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
    );
  }
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, this.onTap});

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

class _TimeRangeDropdown extends StatelessWidget {
  const _TimeRangeDropdown({
    required this.value,
    required this.enabled,
    this.onChanged,
  });

  final ActivityTimeRange value;
  final bool enabled;
  final ValueChanged<ActivityTimeRange>? onChanged;

  @override
  Widget build(BuildContext context) {
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
    required this.items,
    required this.filter,
    required this.timeRange,
    required this.searchQuery,
    required this.onClearFilters,
    required this.liveAudit,
  });

  final SystemHealthStats? healthStats;
  final List<ActivityItem> items;
  final ActivityFilter filter;
  final ActivityTimeRange timeRange;
  final String searchQuery;
  final VoidCallback onClearFilters;
  final bool liveAudit;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AdminScaffold.contentPadding(context).bottom;
    final auditLoggingOn =
        liveAudit ||
        AdminSystemSettingsDirectory.instance.settings.value.auditLogging;
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
        if (AdminSession.instance.isSuperAdmin && healthStats != null) ...[
          _HealthStatsRow(stats: healthStats!),
          const SizedBox(height: AppSpacing.md),
        ],
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
  const _ActivityCard({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final critical = item.severity == ActivitySeverity.critical;

    return GlassCard(
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/admin_system_activity_data.dart';
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
/// Management, including [CollapsibleListHeader] wrapping the stat cards
/// and filter chrome above the loaded list, and that chrome staying fixed
/// (not collapsible) but still interactive for Empty/No Results, then
/// disabled entirely for Offline/Error/Unauthorized.
///
/// "unauthorized" (dark only) pairs with "unauthprized" (a typo, light
/// only) as Unauthorized's two theme variants — the same kind of
/// split-across-two-folders slip already seen throughout this app.
///
/// This screen has no persistent tab slot of its own (see
/// [AdminScaffold]'s doc comment) and no single exclusive parent either —
/// it's reachable from both Dashboard's "Activity Monitoring" card and
/// every screen's drawer, unlike ADM-003 User Details' one-and-only path
/// through User Management. [AdminScaffold.selectedTab] is null here, so
/// the bottom nav shows no tab as active rather than falsely implying
/// this is Dashboard, while [AdminScaffold.headerTitle] still overrides
/// the header to read "System Activity".
///
/// Error/Offline/Unauthorized render as a floating card over dimmed stat
/// cards in the export, which this implementation keeps (unlike other
/// Admin screens' floating-card exports, normalized away elsewhere) —
/// this is the same "chrome visible but disabled" shape User Management's
/// own Offline/Error/Unauthorized states already use, not a one-off.
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
    this.onOpenProfile,
    this.onNotificationsTap,
  });

  final AdminSystemActivityViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  /// Forwarded to [AdminScaffold]'s drawer. Nullable: ADM-008 isn't built
  /// yet.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminSystemActivityScreen> createState() =>
      _AdminSystemActivityScreenState();
}

class _AdminSystemActivityScreenState extends State<AdminSystemActivityScreen> {
  late AdminSystemActivityViewState _state = widget.initialState;
  final SystemActivityStats _stats = mockSystemActivityStats();
  final List<ActivityItem> _items = mockActivityItems();
  ActivityFilter _filter = ActivityFilter.all;
  ActivityTimeRange _timeRange = ActivityTimeRange.last24Hours;

  void _retry() {
    setState(() => _state = AdminSystemActivityViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = AdminSystemActivityViewState.loaded);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = ActivityFilter.all;
      _timeRange = ActivityTimeRange.last24Hours;
      _state = AdminSystemActivityViewState.loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chromeEnabled =
        _state == AdminSystemActivityViewState.empty ||
        _state == AdminSystemActivityViewState.noResults;

    return AdminScaffold(
      selectedTab: null,
      headerTitle: 'System Activity',
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.roles) widget.onNavigateToRoles?.call();
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenProfile: widget.onOpenProfile,
      body: switch (_state) {
        AdminSystemActivityViewState.loading => const _LoadingSkeleton(),
        AdminSystemActivityViewState.loaded => Padding(
          padding: EdgeInsets.only(
            top: AdminScaffold.contentPadding(context).top,
          ),
          child: CollapsibleListHeader(
            header: _FilterChrome(
              stats: _stats,
              filter: _filter,
              timeRange: _timeRange,
              enabled: true,
              onFilterSelected: (f) => setState(() => _filter = f),
              onTimeRangeChanged: (r) => setState(() => _timeRange = r),
            ),
            child: _ActivityList(
              items: _items,
              filter: _filter,
              timeRange: _timeRange,
              onClearFilters: _clearFilters,
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(height: AdminScaffold.contentPadding(context).top),
            _FilterChrome(
              stats: _stats,
              filter: _filter,
              timeRange: _timeRange,
              enabled: chromeEnabled,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
              onTimeRangeChanged: chromeEnabled
                  ? (r) => setState(() => _timeRange = r)
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
// Filter chrome — stat cards, filter chips, time-range dropdown
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.stats,
    required this.filter,
    required this.timeRange,
    required this.enabled,
    this.onFilterSelected,
    this.onTimeRangeChanged,
  });

  final SystemActivityStats stats;
  final ActivityFilter filter;
  final ActivityTimeRange timeRange;
  final bool enabled;
  final ValueChanged<ActivityFilter>? onFilterSelected;
  final ValueChanged<ActivityTimeRange>? onTimeRangeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Events',
                      value: _formatThousands(stats.totalEvents),
                      delta: '+${stats.totalEventsChangePercent}%',
                      deltaColor: AppColors.statusResolved,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      label: 'Login Events',
                      value: _formatThousands(stats.loginEvents),
                      delta: '+${stats.loginEventsChangePercent}%',
                      deltaColor: AppColors.statusResolved,
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
                      label: 'Admin Actions',
                      value: '${stats.adminActions}',
                      delta: '${stats.adminActionsChangePercent}%',
                      deltaColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      label: 'Security Alerts',
                      value: '${stats.securityAlerts}',
                      badge: stats.securityAlertsBadge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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

  static String _formatThousands(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    return '${thousands.toStringAsFixed(1)}k';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.delta,
    this.deltaColor,
    this.badge,
  });

  final String label;
  final String value;
  final String? delta;
  final Color? deltaColor;
  final String? badge;

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
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (delta != null)
                Flexible(
                  child: Text(
                    delta!,
                    style: textTheme.labelMedium?.copyWith(color: deltaColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.allXl,
                  ),
                  child: Text(
                    badge!,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppComponentRadius.inputField,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ActivityTimeRange>(
            value: value,
            isExpanded: true,
            borderRadius: AppComponentRadius.inputField,
            icon: Icon(
              AppIcons.chevronDown,
              size: AppIconSize.sm,
              color: colorScheme.onSurfaceVariant,
            ),
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            selectedItemBuilder: (context) => [
              for (final range in ActivityTimeRange.values)
                Row(
                  children: [
                    Icon(
                      AppIcons.calendar,
                      size: AppIconSize.sm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(range.label),
                  ],
                ),
            ],
            items: [
              for (final range in ActivityTimeRange.values)
                DropdownMenuItem(value: range, child: Text(range.label)),
            ],
            onChanged: enabled
                ? (selected) {
                    if (selected != null) onChanged?.call(selected);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity list
// ---------------------------------------------------------------------------

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.items,
    required this.filter,
    required this.timeRange,
    required this.onClearFilters,
  });

  final List<ActivityItem> items;
  final ActivityFilter filter;
  final ActivityTimeRange timeRange;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AdminScaffold.contentPadding(context).bottom;
    final filtered = items
        .where((i) => filter.matches(i) && i.matchesTimeRange(timeRange))
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        if (filtered.isEmpty)
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: block(height: 76, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 76, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: block(height: 76, radius: 12)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block(height: 76, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        block(height: 40, radius: 20),
        const SizedBox(height: AppSpacing.sm),
        block(height: 48, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 16, width: 120),
        const SizedBox(height: AppSpacing.sm),
        cardBlock(),
        const SizedBox(height: AppSpacing.sm),
        cardBlock(),
        const SizedBox(height: AppSpacing.sm),
        cardBlock(),
      ],
    );
  }
}

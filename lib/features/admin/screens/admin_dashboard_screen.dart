import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../models/assembly.dart';
import '../../../utils/time_greeting.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/stat_tile.dart';
import '../models/admin_dashboard_data.dart';
import '../models/admin_system_activity_data.dart';
import '../services/admin_session.dart';
import '../services/admin_user_directory.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-001 — Admin Dashboard.
///
/// Approved states (Figma "01/Dashboard" export): Default, Loading,
/// Offline, Error ("Unable to Load Dashboard"), Unauthorized. Two exported
/// folders back the same Unauthorized state — "unauthorized" (light only)
/// and "unthorized" (a typo, dark only) — combined here as the one state's
/// two theme variants, the same kind of export slip as Ministry Municipal
/// Performance's "emty" folder.
///
/// No Empty/No Results states here (unlike every Analytics-style Ministry
/// screen): this dashboard has no filter/search chrome to exclude data
/// with, matching the spec's own "Validation Rules: None".
///
/// The bottom nav is Dashboard/Users/Activity/Settings — see [AdminTab]'s
/// own doc comment for why Role Management moved to the drawer in favor of
/// System Activity's tab slot. The header's leading glyph is the CivicVoice
/// logo mark, not a hamburger drawer trigger — see [AdminScaffold]'s own
/// doc comment.
///
/// Offline/Error/Unauthorized keep the "Platform Overview" title and API
/// status badge visible but visually de-emphasized (confirmed against the
/// approved frames — that block noticeably lightens in contrast versus
/// Default) while everything below it — stat cards, Management list, and
/// Activity Monitoring — is replaced by a single [AppStateMessage].
///
/// Post-launch revisions on top of the approved frame:
/// - The top "System Settings" CTA button was dropped — it pointed at the
///   exact same destination as the Management row's own "System Settings"
///   entry, one screen down, with nothing distinguishing when you'd use
///   one over the other.
/// - The subtitle ("Real-time metrics and system administrative
///   summary.") and the original uptime badge ("System Live: 99.9%
///   Uptime") were both dropped outright rather than replaced — the
///   badge was never backed by a real API health check and had no
///   action tied to it either way, so it was dead weight, not a metric
///   worth keeping in any form.
/// - Role Management/System Settings' Management-row entries only render
///   for a Super Admin session — an assembly Admin has neither to manage,
///   see [AdminSession].
enum AdminDashboardViewState { loading, loaded, offline, error, unauthorized }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    this.initialState = AdminDashboardViewState.loaded,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onNavigateToMaintenanceTeams,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.healthStats,
    this.onRefreshHealth,
  });

  final AdminDashboardViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs; also the
  /// destination for the matching "Management" row.
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer — also the
  /// destination for the matching "Management" row, so the row and the
  /// drawer item both land on the same screen rather than two competing
  /// paths.
  final VoidCallback? onNavigateToRoles;

  /// Also the destination for the matching "Management" row.
  final VoidCallback? onNavigateToSettings;

  /// Opens ADM-006 System Activity — the spec'd destination for "View
  /// System Activity", wired to both the Activity Monitoring card and the
  /// bottom nav's Activity tab (same destination, not two competing ones).
  final VoidCallback? onNavigateToActivity;

  final VoidCallback? onNavigateToMaintenanceTeams;

  /// Opens ADM-008 Admin Profile via [AdminScaffold]'s drawer. Nullable:
  /// ADM-008 isn't built yet.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;
  final SystemHealthStats? healthStats;
  final Future<void> Function()? onRefreshHealth;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminDashboardViewState _state = widget.initialState;
  AdminDashboardData _data = AdminDashboardData.current();
  Timer? _healthTimer;

  @override
  void initState() {
    super.initState();
    if (AdminSession.instance.isSuperAdmin && widget.onRefreshHealth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRefreshHealth?.call();
      });
      _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        widget.onRefreshHealth?.call();
      });
    }
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _state = AdminDashboardViewState.loading);
    try {
      await AdminUserDirectory.instance.refresh();
      if (mounted) {
        setState(() {
          _data = AdminDashboardData.current();
          _state = AdminDashboardViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = AdminDashboardViewState.error);
    }
  }

  /// Pull-to-refresh's silent counterpart to [_retry] — re-fetches and
  /// updates the dashboard in place without dropping into the full-screen
  /// loading state, since GhanaRefreshIndicator's own bar is already the
  /// loading affordance here.
  Future<void> _pullToRefresh() async {
    await AdminUserDirectory.instance.refresh();
    if (mounted) setState(() => _data = AdminDashboardData.current());
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.dashboard,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
        if (tab == AdminTab.maintenance) {
          widget.onNavigateToMaintenanceTeams?.call();
        }
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: widget.onNavigateToMaintenanceTeams,
      onOpenProfile: widget.onOpenProfile,
      body: switch (_state) {
        AdminDashboardViewState.loading => const _LoadingSkeleton(),
        _ => GhanaRefreshIndicator(
          onRefresh: _pullToRefresh,
          // The header paints on top of this body (a later sibling in
          // AdminScaffold's own Stack), so without this the pull indicator
          // would grow in from behind it.
          topOffset: AdminScaffold.contentPadding(context).top,
          child: _DashboardBody(
            state: _state,
            data: _state == AdminDashboardViewState.loaded
                ? AdminDashboardData.current()
                : _data,
            onRetry: _retry,
            onNavigateToUsers: widget.onNavigateToUsers,
            onNavigateToRoles: widget.onNavigateToRoles,
            onNavigateToSettings: widget.onNavigateToSettings,
            onNavigateToActivity: widget.onNavigateToActivity,
            healthStats: widget.healthStats,
          ),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.data,
    required this.onRetry,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.healthStats,
  });

  final AdminDashboardViewState state;
  final AdminDashboardData data;
  final VoidCallback onRetry;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;
  final SystemHealthStats? healthStats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = AdminScaffold.contentPadding(context);
    final loaded = state == AdminDashboardViewState.loaded;

    return ListView(
      // Stays draggable even when the content fits the viewport —
      // otherwise pull-to-refresh silently wouldn't trigger.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Opacity(
          opacity: loaded ? 1 : 0.5,
          child: AdminSession.instance.isSuperAdmin
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Platform Overview',
                        style: textTheme.headlineSmall,
                      ),
                    ),
                    _ApiStatusBadge(
                      stats: healthStats,
                      onTap: onNavigateToActivity,
                    ),
                  ],
                )
              : _AdminGreeting(assembly: AdminSession.instance.assembly),
        ),
        const SizedBox(height: AppSpacing.xl),
        switch (state) {
          // AdminDashboardViewState.loading never actually reaches this
          // widget (the parent screen routes it straight to
          // _LoadingSkeleton instead) — grouped in here only because Dart
          // requires this switch to be exhaustive.
          AdminDashboardViewState.loading ||
          AdminDashboardViewState.loaded => _LoadedContent(
            data: data,
            onNavigateToUsers: onNavigateToUsers,
            onNavigateToRoles: onNavigateToRoles,
            onNavigateToSettings: onNavigateToSettings,
            onNavigateToActivity: onNavigateToActivity,
          ),
          AdminDashboardViewState.offline => AppStateMessage(
            icon: AppIcons.offline,
            badgeColor: AppColors.error,
            title: 'You\'re offline',
            message:
                'Check your connection and retry loading administrator '
                'dashboard data.',
            primaryActionLabel: 'Retry connection',
            onPrimaryAction: onRetry,
            primaryActionColor: AppColors.error,
            bordered: true,
          ),
          AdminDashboardViewState.error => AppStateMessage(
            icon: AppIcons.warning,
            badgeColor: AppColors.error,
            title: 'Unable to Load Dashboard',
            message:
                'The administrative dashboard service could not return '
                'system data right now.',
            primaryActionLabel: 'Retry',
            onPrimaryAction: onRetry,
            primaryActionColor: AppColors.error,
            bordered: true,
          ),
          AdminDashboardViewState.unauthorized => const AppStateMessage(
            icon: AppIcons.permissionDenied,
            badgeColor: AppColors.error,
            title: 'Unauthorized Access',
            message:
                'Administrative privileges are required to access this '
                'module.',
            bordered: true,
          ),
        },
      ],
    );
  }
}

class _ApiStatusBadge extends StatefulWidget {
  const _ApiStatusBadge({required this.stats, this.onTap});

  final SystemHealthStats? stats;
  final VoidCallback? onTap;

  @override
  State<_ApiStatusBadge> createState() => _ApiStatusBadgeState();
}

class _ApiStatusBadgeState extends State<_ApiStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final online = stats?.apiOnline == true && stats?.databaseOnline == true;
    final checking = stats == null;
    final color = checking
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : online
        ? AppColors.statusResolved
        : AppColors.error;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(
                          alpha: reduceMotion
                              ? 0.25
                              : 0.15 + (_controller.value * 0.35),
                        ),
                        blurRadius: reduceMotion
                            ? 4
                            : 4 + (_controller.value * 6),
                        spreadRadius: reduceMotion ? 0 : _controller.value * 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'API: ${checking
                    ? 'Checking'
                    : online
                    ? 'Online'
                    : 'Offline'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Assembly-scoped ("normal", non-Super) Admin sessions get the same
/// time-based greeting + jurisdiction treatment Municipal Officer's own
/// Dashboard greeting already has — Super Admin keeps "Platform Overview"
/// instead
/// (see the switch above), since a national session has no single assembly
/// to greet them with.
class _AdminGreeting extends StatelessWidget {
  const _AdminGreeting({required this.assembly});

  final Assembly? assembly;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final assembly = this.assembly;
    final name =
        (assembly == null
                ? null
                : AdminUserDirectory.instance.correspondentAdminFor(assembly))
            ?.name ??
        AdminUserDirectory.instance.currentUser?.name ??
        'Administrator';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${timeBasedGreeting()}, $name', style: textTheme.headlineSmall),
        if (assembly != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                AppIcons.municipality,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  assembly.fullName,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded content
// ---------------------------------------------------------------------------

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({
    required this.data,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
  });

  final AdminDashboardData data;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stats = data.stats;

    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    // A zero delta (the real, unscored-yet path always reports 0 for both
    // — see AdminDashboardData.fromX) is not "up 0%", it's "nothing to
    // report" — coloring it success-green read as fake positive movement.
    Color deltaColorFor(num changePercent) =>
        changePercent > 0 ? AppColors.statusResolved : onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grounded in one light card rather than four separate ones, and
        // rather than floating loose on the canvas (the prior all-borderless
        // pass) — four different accent-colored icons with no boundary read
        // as scattered, not clean. Only Open Alerts keeps a semantic accent
        // (warning); the rest share one neutral tone so the alert is what
        // actually stands out.
        GlassCard(
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: AppIcons.team,
                        iconColor: AppColors.primary,
                        label: 'Total Users',
                        value: _formatThousands(stats.totalUsers),
                        delta: '+${stats.totalUsersChangePercent}%',
                        deltaColor: deltaColorFor(
                          stats.totalUsersChangePercent,
                        ),
                      ),
                    ),
                    const StatTileDivider(),
                    Expanded(
                      child: StatTile(
                        icon: AppIcons.shield,
                        iconColor: AppColors.primary,
                        label: 'Active Roles',
                        value: '${stats.activeRoles}',
                        delta: '+${stats.activeRolesChangePercent}%',
                        deltaColor: deltaColorFor(
                          stats.activeRolesChangePercent,
                        ),
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
                      child: StatTile(
                        icon: AppIcons.activityPulse,
                        iconColor: AppColors.primary,
                        label: 'Admin Actions',
                        value: stats.adminActionsLabel,
                        delta: '24h',
                        deltaColor: onSurfaceVariant,
                      ),
                    ),
                    const StatTileDivider(),
                    Expanded(
                      child: StatTile(
                        icon: AppIcons.warning,
                        iconColor: AppColors.warning,
                        label: 'Open Alerts',
                        value: '${stats.openAlerts}',
                        delta: 'Review',
                        deltaColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Management', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        // One grouped card with hairline dividers between rows — same
        // pattern SettingsSection uses — rather than three stacked cards.
        // ClipRRect here (GlassCard itself doesn't clip) keeps each row's
        // InkWell ripple from square-cornering past the card's rounded
        // edges on the first/last row.
        GlassCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppComponentRadius.card,
            child: Column(
              children: [
                _ManagementRow(
                  icon: AppIcons.team,
                  title: 'User Management',
                  subtitle: 'Manage administrator and staff accounts',
                  onTap: onNavigateToUsers,
                ),
                // Role Management and System Settings are Super Admin-only —
                // an assembly Admin has no tiers to review and no platform
                // config to touch, so these rows are dropped for them rather
                // than left as a tap-through to an Unauthorized screen.
                if (AdminSession.instance.isSuperAdmin) ...[
                  const Divider(height: 1),
                  _ManagementRow(
                    icon: AppIcons.roleManagement,
                    title: 'Role Management',
                    subtitle: 'Review privileges and access groups',
                    onTap: onNavigateToRoles,
                  ),
                  const Divider(height: 1),
                  _ManagementRow(
                    icon: AppIcons.settings,
                    title: 'System Settings',
                    subtitle: 'Governance-approved configuration',
                    onTap: onNavigateToSettings,
                  ),
                ],
              ],
            ),
          ),
        ),
        // This preview card's own content (AdminActivityItem, below) is
        // static, platform-wide-sounding mock copy, not scoped to any one
        // assembly — showing it to an assembly Admin would preview events
        // that don't match what they'd actually see after tapping through
        // to their own region-scoped System Activity feed. Kept Super
        // Admin-only for that reason, not because the destination itself
        // is gated anymore — see AdminSession.visibleActivity's own doc
        // comment for how an assembly Admin's own feed now works.
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          onTap: onNavigateToActivity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Activity Monitoring',
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    AppIcons.activityLog,
                    size: AppIconSize.md,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < data.activity.length; i++) ...[
                _ActivityRow(index: i + 1, item: data.activity[i]),
                if (i != data.activity.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Comma thousands-abbreviation (e.g. "12.4k") — matches the approved
  /// frame's lowercase "k" exactly (unlike Ministry Dashboard's own
  /// abbreviated stat, which uses an uppercase "K").
  static String _formatThousands(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    return '${thousands.toStringAsFixed(1)}k';
  }
}

class _ManagementRow extends StatelessWidget {
  const _ManagementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Plain row, not its own GlassCard — this sits inside one shared
    // grouping card (see _LoadedContent) with hairline Dividers between
    // rows, so an individual row needs its own tap ripple but not its own
    // boundary/background.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.lg, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: AppIconSize.sm,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.index, required this.item});

  final int index;
  final AdminActivityItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Text('$index', style: textTheme.labelSmall),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.caption,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        block(height: 24, width: 200),
        const SizedBox(height: AppSpacing.sm),
        block(height: 32, width: 180, radius: 20),
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
        block(height: 16, width: 120),
        const SizedBox(height: AppSpacing.sm),
        block(height: 72, radius: 12),
        const SizedBox(height: AppSpacing.sm),
        block(height: 72, radius: 12),
        const SizedBox(height: AppSpacing.sm),
        block(height: 72, radius: 12),
        const SizedBox(height: AppSpacing.lg),
        block(height: 220, radius: 12),
      ],
    );
  }
}

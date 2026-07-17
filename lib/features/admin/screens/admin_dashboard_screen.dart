import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/glass_card.dart';
import '../models/admin_dashboard_data.dart';
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
/// Two post-launch revisions on top of the approved frame:
/// - The top "System Settings" CTA button was dropped — it pointed at the
///   exact same destination as the Management row's own "System Settings"
///   entry, one screen down, with nothing distinguishing when you'd use
///   one over the other.
/// - The subtitle ("Real-time metrics and system administrative
///   summary.") was dropped, and the uptime badge ("System Live: 99.9%
///   Uptime") was replaced with a plain API Status badge in that same
///   spot — see [AdminDashboardData.apiStatusOnline]'s own doc comment.
enum AdminDashboardViewState { loading, loaded, offline, error, unauthorized }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    this.initialState = AdminDashboardViewState.loaded,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
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

  /// Opens ADM-008 Admin Profile via [AdminScaffold]'s drawer. Nullable:
  /// ADM-008 isn't built yet.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminDashboardViewState _state = widget.initialState;
  final AdminDashboardData _data = AdminDashboardData.mock();

  void _retry() {
    setState(() => _state = AdminDashboardViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = AdminDashboardViewState.loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.dashboard,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenProfile: widget.onOpenProfile,
      body: switch (_state) {
        AdminDashboardViewState.loading => const _LoadingSkeleton(),
        _ => _DashboardBody(
          state: _state,
          data: _data,
          onRetry: _retry,
          onNavigateToUsers: widget.onNavigateToUsers,
          onNavigateToRoles: widget.onNavigateToRoles,
          onNavigateToSettings: widget.onNavigateToSettings,
          onNavigateToActivity: widget.onNavigateToActivity,
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
  });

  final AdminDashboardViewState state;
  final AdminDashboardData data;
  final VoidCallback onRetry;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = AdminScaffold.contentPadding(context);
    final loaded = state == AdminDashboardViewState.loaded;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Opacity(
          opacity: loaded ? 1 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform Overview', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              _ApiStatusBadge(online: data.apiStatusOnline),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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

class _ApiStatusBadge extends StatelessWidget {
  const _ApiStatusBadge({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.statusResolved : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BreathingDot(color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'API Status: ${online ? 'Online' : 'Offline'}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: AppFontWeight.semiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A slow, gentle opacity pulse on the API status dot — reads as an
/// ambient "this is a live status, still updating" signal rather than the
/// loading skeleton's much faster shimmer (that one signals "content is
/// still arriving"; this one signals "content is current and alive").
class _BreathingDot extends StatefulWidget {
  const _BreathingDot({required this.color});

  final Color color;

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return _Dot(opacity: 1, color: widget.color);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity =
            0.35 + (Curves.easeInOut.transform(_controller.value) * 0.65);
        return _Dot(opacity: opacity, color: widget.color);
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity, required this.color});

  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: AppIcons.team,
                  tint: AppColors.primary,
                  label: 'Total Users',
                  value: _formatThousands(stats.totalUsers),
                  delta: '+${stats.totalUsersChangePercent}%',
                  deltaColor: AppColors.statusResolved,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.shield,
                  tint: AppColors.statusResolved,
                  label: 'Active Roles',
                  value: '${stats.activeRoles}',
                  delta: '+${stats.activeRolesChangePercent}%',
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
                  icon: AppIcons.activityPulse,
                  tint: AppColors.primary,
                  label: 'Admin Actions',
                  value: stats.adminActionsLabel,
                  delta: '24h',
                  deltaColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.warning,
                  tint: AppColors.warning,
                  label: 'Open Alerts',
                  value: '${stats.openAlerts}',
                  delta: 'Review',
                  deltaColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Management', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ManagementRow(
          icon: AppIcons.team,
          title: 'User Management',
          subtitle: 'Manage administrator and staff accounts',
          onTap: onNavigateToUsers,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ManagementRow(
          icon: AppIcons.roleManagement,
          title: 'Role Management',
          subtitle: 'Review privileges and access groups',
          onTap: onNavigateToRoles,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ManagementRow(
          icon: AppIcons.settings,
          title: 'System Settings',
          subtitle: 'Governance-approved configuration',
          onTap: onNavigateToSettings,
        ),
        const SizedBox(height: AppSpacing.lg),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  final IconData icon;
  final Color tint;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: AppIconSize.lg,
                height: AppIconSize.lg,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(icon, size: AppIconSize.sm + 2, color: tint),
              ),
              Text(
                delta,
                style: textTheme.labelMedium?.copyWith(color: deltaColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppDimensions.controlHeightStandard,
            height: AppDimensions.controlHeightStandard,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: AppIconSize.md, color: AppColors.primary),
          ),
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

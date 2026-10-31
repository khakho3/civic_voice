import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../services/admin_read_failure.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../models/admin_overview.dart';
import '../services/admin_overview_directory.dart';
import '../services/admin_resource.dart';
import '../services/admin_system_activity_directory.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_api_status_badge.dart';

/// Live Home uses server totals, never counts a bounded cached directory.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({
    super.key,
    this.directory,
    this.healthDirectory,
    required this.onUsers,
    required this.onTeams,
    required this.onActivity,
    required this.onAlerts,
    required this.onRoles,
    required this.onSettings,
    required this.onProfile,
    required this.onNotifications,
    this.superAdmin,
  });
  final AdminResource<AdminOverview>? directory;
  final AdminSystemActivityDirectory? healthDirectory;
  final VoidCallback onUsers,
      onTeams,
      onActivity,
      onAlerts,
      onRoles,
      onSettings,
      onProfile,
      onNotifications;
  final bool? superAdmin;
  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen>
    with WidgetsBindingObserver {
  Timer? _healthTimer;
  bool _requested = false;
  AdminSystemActivityDirectory get _health =>
      widget.healthDirectory ?? AdminSystemActivityDirectory.instance;
  bool get _superAdmin => widget.superAdmin ?? verifiedSuperAdmin;
  bool get _canCheckHealth =>
      _superAdmin &&
      (widget.directory == null || widget.healthDirectory != null);
  AdminResource<AdminOverview> get _source =>
      widget.directory ?? AdminOverviewDirectory.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_canCheckHealth) {
      unawaited(_health.refreshHealth());
      _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_canCheckHealth) {
          unawaited(_health.refreshHealth());
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requested = true;
        unawaited(_source.load());
      }
    });
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      _source.load(),
      if (_canCheckHealth) _health.refreshHealth(),
    ]);
  }

  bool get _overviewUnreachable =>
      _source.failure == AdminReadFailure.unreachable &&
      _source.failureSequence > _health.healthReadSequence;

  Widget _heading(BuildContext context, bool superAdmin) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        Expanded(
          child: Text(
            superAdmin ? 'Platform Overview' : 'Assembly Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (superAdmin) ...[
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
            child: AdminApiStatusBadge(
              stats: _health.hasLiveHealthSnapshot
                  ? _health.health.value
                  : null,
              offline:
                  adminServiceOffline(_health.healthFailure.value) ||
                  _overviewUnreachable,
              onTap: widget.onActivity,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _failureScreen(
    BuildContext context,
    bool superAdmin,
    EdgeInsets inset,
    AdminReadFailure failure,
  ) {
    final title = switch (failure) {
      AdminReadFailure.unreachable => 'Cannot reach CivicVoice',
      AdminReadFailure.service => 'Service unavailable',
      AdminReadFailure.unauthorized => 'Administrative access required',
      AdminReadFailure.unverified => 'Unable to load dashboard',
    };
    final message = switch (failure) {
      AdminReadFailure.unreachable =>
        "We couldn't reach the CivicVoice service. Check your connection or try again shortly.",
      AdminReadFailure.service =>
        'The CivicVoice service could not load the dashboard. Please try again shortly.',
      AdminReadFailure.unauthorized =>
        'Your account needs administrative access and a configured jurisdiction.',
      AdminReadFailure.unverified =>
        'The dashboard data could not be verified. Please try again.',
    };
    return GhanaRefreshIndicator(
      topOffset: inset.top,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              inset.top + AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _heading(context, superAdmin)),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: inset.bottom),
              child: Semantics(
                liveRegion: true,
                child: AppStateMessage(
                  icon: failure == AdminReadFailure.unauthorized
                      ? AppIcons.permissionDenied
                      : AppIcons.warning,
                  badgeColor: AppColors.error,
                  title: title,
                  message: message,
                  primaryActionLabel: 'Retry',
                  onPrimaryAction: _refresh,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _management(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: AppSemanticColors.of(context).actionText),
    title: Text(title, style: Theme.of(context).textTheme.titleSmall),
    subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => AdminScaffold(
    selectedTab: AdminTab.dashboard,
    onNotificationsTap: widget.onNotifications,
    onOpenRoleManagement: widget.onRoles,
    onOpenAlerts: widget.onAlerts,
    onOpenMaintenanceTeams: widget.onTeams,
    onOpenProfile: widget.onProfile,
    onTabSelected: (tab) {
      switch (tab) {
        case AdminTab.users:
          widget.onUsers();
        case AdminTab.activity:
          widget.onActivity();
        case AdminTab.settings:
          widget.onSettings();
        case AdminTab.maintenance:
          widget.onTeams();
        case AdminTab.dashboard:
          break;
      }
    },
    body: AnimatedBuilder(
      animation: Listenable.merge([
        _source,
        _health.health,
        _health.healthFailure,
      ]),
      builder: (context, _) {
        final data = _source.data,
            superAdmin = widget.superAdmin ?? verifiedSuperAdmin;
        final inset = AdminScaffold.contentPadding(context);
        final verifiedHealth = _health.hasLiveHealthSnapshot
            ? _health.health.value
            : null;
        final healthFailed =
            adminServiceOffline(_health.healthFailure.value) ||
            verifiedHealth != null &&
                (!verifiedHealth.apiOnline || !verifiedHealth.databaseOnline);
        if (_source.error != null ||
            healthFailed ||
            _requested && data == null && !_source.loading) {
          final failure = _source.failure == AdminReadFailure.unauthorized
              ? AdminReadFailure.unauthorized
              : healthFailed
              ? (_health.healthFailure.value ?? AdminReadFailure.service)
              : _source.failure == AdminReadFailure.unreachable &&
                    !_overviewUnreachable
              ? AdminReadFailure.unverified
              : _source.failure ?? AdminReadFailure.unverified;
          return _failureScreen(context, superAdmin, inset, failure);
        }
        return GhanaRefreshIndicator(
          onRefresh: _refresh,
          topOffset: inset.top,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              inset.top + AppSpacing.lg,
              AppSpacing.md,
              inset.bottom + AppSpacing.lg,
            ),
            children: [
              _heading(context, superAdmin),
              const SizedBox(height: AppSpacing.lg),
              // Pull/resume refresh already has its own feedback. Only a cold
              // load needs this row; adding it above verified cards shifts them.
              if ((_source.loading || !_requested) && data == null)
                const GhanaLoadingIndicator(label: 'Loading overview'),
              if (data != null) ...[
                _DashboardCard(
                  key: const ValueKey('admin-overview-stats'),
                  padding: const EdgeInsets.all(1),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Metric(
                                  'Total users',
                                  data.totalUsers,
                                  widget.onUsers,
                                  detail: 'Registered accounts in your scope',
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  'Active roles',
                                  data.activeRoles,
                                  widget.onUsers,
                                  detail: 'Among active registered accounts',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Metric(
                                  'Audit events',
                                  data.auditEvents24h,
                                  widget.onActivity,
                                  detail: 'Last 24 hours',
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  'Open alerts',
                                  data.openAlerts,
                                  widget.onAlerts,
                                  warning: true,
                                  detail:
                                      'Includes acknowledged · excludes resolved',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Positioned.fill(
                        child: Center(
                          child: VerticalDivider(width: 1, thickness: 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Management',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _DashboardCard(
                  key: const ValueKey('admin-overview-management'),
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _management(
                        AppIcons.team,
                        'User Management',
                        'Manage administrator and staff accounts',
                        widget.onUsers,
                      ),
                      const Divider(height: 1),
                      _management(
                        AppIcons.team,
                        'Maintenance Teams',
                        'Manage crews and membership',
                        widget.onTeams,
                      ),
                      if (superAdmin) ...[
                        const Divider(height: 1),
                        _management(
                          AppIcons.location,
                          'Report Routing',
                          'Resolve reports with an unknown assembly',
                          () => Navigator.of(
                            context,
                          ).pushNamed('/admin/report-routing'),
                        ),
                        const Divider(height: 1),
                        _management(
                          AppIcons.roleManagement,
                          'Role Management',
                          'Review privileges and access groups',
                          widget.onRoles,
                        ),
                        const Divider(height: 1),
                        _management(
                          AppIcons.settings,
                          'System Settings',
                          'Governance-approved configuration',
                          widget.onSettings,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _DashboardCard(
                  key: const ValueKey('admin-overview-activity'),
                  onTap: widget.onActivity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Activity Monitoring',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            AppIcons.activityLog,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!data.collectionEnabled)
                        const Text(
                          'Audit collection is off. Existing history remains available.',
                        ),
                      if (data.recent.isEmpty)
                        const Text('No recent activity.'),
                      for (var i = 0; i < data.recent.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow,
                                child: Text(
                                  '${i + 1}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.recent[i].title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${data.recent[i].tag} · ${data.recent[i].severity.label}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '${MaterialLocalizations.of(context).formatMediumDate(data.recent[i].timestamp)} · ${TimeOfDay.fromDateTime(data.recent[i].timestamp).format(context)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.label,
    this.value,
    this.onTap, {
    required this.detail,
    this.warning = false,
  });
  final String label, detail;
  final int value;
  final VoidCallback onTap;
  final bool warning;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
              letterSpacing: 0,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              letterSpacing: 0,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: warning ? AppSemanticColors.of(context).warningText : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              letterSpacing: 0,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppSemanticColors.of(context).glassBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/busy_indicator.dart';
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
  AdminResource<AdminOverview> get _source =>
      widget.directory ?? AdminOverviewDirectory.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.directory == null && verifiedSuperAdmin) {
      unawaited(AdminSystemActivityDirectory.instance.refreshHealth());
      _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (verifiedSuperAdmin) {
          unawaited(AdminSystemActivityDirectory.instance.refreshHealth());
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_source.load());
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
    if (state == AppLifecycleState.resumed) unawaited(_source.load());
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
      animation: _source,
      builder: (context, _) {
        final data = _source.data,
            superAdmin = widget.superAdmin ?? verifiedSuperAdmin;
        final inset = AdminScaffold.contentPadding(context);
        return GhanaRefreshIndicator(
          onRefresh: _source.load,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      superAdmin ? 'Platform Overview' : 'Assembly Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (superAdmin) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ValueListenableBuilder(
                      valueListenable:
                          AdminSystemActivityDirectory.instance.health,
                      builder: (context, health, _) => AdminApiStatusBadge(
                        stats:
                            AdminSystemActivityDirectory
                                .instance
                                .hasLiveHealthSnapshot
                            ? health
                            : null,
                        onTap: widget.onActivity,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Pull/resume refresh already has its own feedback. Only a cold
              // load needs this row; adding it above verified cards shifts them.
              if (_source.loading && data == null)
                const Center(
                  child: BusyIndicator(
                    semanticsLabel: 'Loading, please wait...',
                  ),
                ),
              if (_source.error != null ||
                  data == null && !_source.loading) ...[
                Text(
                  _source.error ??
                      'A verified administrator session is required.',
                ),
                TextButton(
                  onPressed: _source.loading ? null : _source.load,
                  child: const Text('Refresh overview'),
                ),
              ],
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

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

  @override
  Widget build(BuildContext context) => AdminScaffold(
    selectedTab: AdminTab.dashboard,
    onNotificationsTap: widget.onNotifications,
    onOpenRoleManagement: widget.onRoles,
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
              Text(
                superAdmin ? 'Platform Overview' : 'Assembly Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (superAdmin)
                ValueListenableBuilder(
                  valueListenable: AdminSystemActivityDirectory.instance.health,
                  builder: (context, health, _) => Text(
                    !AdminSystemActivityDirectory
                                .instance
                                .hasLiveHealthSnapshot ||
                            health == null
                        ? 'API status unavailable'
                        : health.apiOnline
                        ? 'API: Online'
                        : 'API: Offline',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (_source.loading)
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
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        'Total users',
                        data.totalUsers,
                        widget.onUsers,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Metric(
                        'Active roles',
                        data.activeRoles,
                        widget.onUsers,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        'Audit events (24h)',
                        data.auditEvents24h,
                        widget.onActivity,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Metric(
                        'Open alerts',
                        data.openAlerts,
                        widget.onAlerts,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Open alerts include acknowledged items and exclude resolved items.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Management',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListTile(
                  leading: const Icon(AppIcons.team),
                  title: const Text('User Management'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onUsers,
                ),
                ListTile(
                  leading: const Icon(AppIcons.team),
                  title: const Text('Maintenance Teams'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onTeams,
                ),
                if (superAdmin) ...[
                  ListTile(
                    leading: const Icon(AppIcons.roleManagement),
                    title: const Text('Role Management'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onRoles,
                  ),
                  ListTile(
                    leading: const Icon(AppIcons.settings),
                    title: const Text('System Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onSettings,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Activity Monitoring',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!data.collectionEnabled)
                  const Text(
                    'Audit collection is off. Existing history remains available.',
                  ),
                if (data.recent.isEmpty)
                  const Text('No activity recorded in your scope.'),
                for (final item in data.recent)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.tag} · ${item.severity.label}\n${item.timestamp}',
                    ),
                    onTap: widget.onActivity,
                  ),
                TextButton(
                  onPressed: widget.onActivity,
                  child: const Text('View system activity'),
                ),
                Text(
                  'Last checked ${data.checkedAt.toLocal()}',
                  style: Theme.of(context).textTheme.labelSmall,
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
  const _Metric(this.label, this.value, this.onTap);
  final String label;
  final int value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: InkWell(
      borderRadius: AppComponentRadius.card,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

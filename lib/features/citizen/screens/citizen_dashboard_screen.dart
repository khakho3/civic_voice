import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/civic_glass_card.dart';
import '../widgets/civic_status_panel.dart';
import '../models/citizen_profile.dart';
import '../models/civic_report.dart';
import '../models/dashboard_view_state.dart';
import '../services/dashboard_state_service.dart';
import '../services/location_service.dart';
import '../services/profile_crud_service.dart';
import '../services/report_crud_service.dart';
import '../../../widgets/stat_tile.dart';
import '../../../widgets/status_badge.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';
import 'report_tracking_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({
    super.key,
    this.initialState = DashboardViewState.empty,
  });

  static const String routeName = '/citizen/dashboard';

  final DashboardViewState initialState;

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _locationDialogVisible = false;
  final DashboardStateService _dashboardStateService =
      DashboardStateService.instance;
  final ReportCrudService _reportCrudService = ReportCrudService.instance;
  final ProfileCrudService _profileCrudService = ProfileCrudService.instance;
  final LocationService _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    _dashboardStateService.setState(widget.initialState);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkLocationAccess(requestPermission: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationAccess(requestPermission: false);
    }
  }

  Future<void> _checkLocationAccess({required bool requestPermission}) async {
    try {
      final status = await _locationService.checkAccessStatus(
        requestPermission: requestPermission,
      );
      if (!mounted) return;

      switch (status) {
        case LocationAccessStatus.gpsDisabled:
          _showLocationDialog(
            title: 'Turn on Location',
            message:
                'CivicVoice needs your phone location to show nearby reports and capture accurate report GPS.',
            actionLabel: 'Turn On Location',
            onAction: _locationService.openLocationSettings,
          );
        case LocationAccessStatus.permissionDenied:
          _dashboardStateService.setState(
            DashboardViewState.permissionRequired,
          );
          _showLocationDialog(
            title: 'Allow Location',
            message:
                'Please allow location permission so CivicVoice can attach GPS to your civic reports.',
            actionLabel: 'Allow Location',
            onAction: () => _checkLocationAccess(requestPermission: true),
          );
        case LocationAccessStatus.permissionDeniedForever:
          _dashboardStateService.setState(
            DashboardViewState.permissionRequired,
          );
          _showLocationDialog(
            title: 'Location Blocked',
            message:
                'Location permission is blocked. Open app settings and allow location access.',
            actionLabel: 'Open Settings',
            onAction: _locationService.openAppSettings,
          );
        case LocationAccessStatus.ready:
          if (_dashboardStateService.state.value ==
              DashboardViewState.permissionRequired) {
            final restoredState =
                widget.initialState == DashboardViewState.permissionRequired
                ? DashboardViewState.empty
                : widget.initialState;
            _dashboardStateService.setState(restoredState);
          }
        case LocationAccessStatus.unavailable:
        // Transient — leave dashboard state as-is; the next resume or
        // manual retry will re-check.
      }
    } catch (_) {
      // In tests or unsupported platforms the plugin can be unavailable; keep
      // the dashboard usable instead of blocking the app.
    }
  }

  Future<void> _showLocationDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) async {
    if (_locationDialogVisible || !mounted) return;
    _locationDialogVisible = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(AppIcons.location, color: AppColors.primary),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await onAction();
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    _locationDialogVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      // See create_report_screen.dart's build() for why this is false and
      // paired with the keyboardVisible-guarded nav below.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<DashboardViewState>(
              valueListenable: _dashboardStateService.state,
              builder: (context, dashboardState, _) {
                return ValueListenableBuilder<CitizenProfile>(
                  valueListenable: _profileCrudService.profile,
                  builder: (context, profile, _) {
                    return ValueListenableBuilder<List<CivicReport>>(
                      valueListenable: _reportCrudService.reports,
                      builder: (context, reports, _) {
                        return _DashboardBody(
                          state: dashboardState,
                          reports: reports,
                          displayName: profile.fullName,
                          onReset: _dashboardStateService.reset,
                          onOpenSettings: _locationService.openAppSettings,
                          onCreateReport: () => Navigator.of(
                            context,
                          ).pushNamed(CreateReportScreen.routeName),
                          onViewReports: () => Navigator.of(
                            context,
                          ).pushNamed(CitizenReportsScreen.routeName),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(showNotifications: false, isHomeTab: true),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  if (index == 1) {
                    Navigator.of(
                      context,
                    ).pushNamed(CitizenReportsScreen.routeName);
                    return;
                  }
                  if (index == 2) {
                    Navigator.of(
                      context,
                    ).pushNamed(CreateReportScreen.routeName);
                    return;
                  }
                  if (index == 3) {
                    Navigator.of(
                      context,
                    ).pushNamed(CitizenAlertsScreen.routeName);
                    return;
                  }
                  if (index == 4) {
                    Navigator.of(
                      context,
                    ).pushNamed(CitizenProfileScreen.routeName);
                    return;
                  }
                  setState(() => _selectedIndex = index);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.reports,
    required this.displayName,
    required this.onReset,
    required this.onOpenSettings,
    required this.onCreateReport,
    required this.onViewReports,
  });

  final DashboardViewState state;
  final List<CivicReport> reports;
  final String displayName;
  final VoidCallback onReset;
  final VoidCallback onOpenSettings;
  final VoidCallback onCreateReport;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    final reportState = switch (state) {
      DashboardViewState.content || DashboardViewState.empty =>
        reports.isEmpty ? DashboardViewState.empty : DashboardViewState.content,
      _ => state,
    };

    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotionDuration.standard),
      child: switch (reportState) {
        DashboardViewState.loading => const _DashboardLoading(),
        DashboardViewState.content => _DashboardContent(
          reports: reports,
          displayName: displayName,
          onViewReports: onViewReports,
        ),
        DashboardViewState.empty => _DashboardEmptyContent(
          displayName: displayName,
          onCreateReport: onCreateReport,
        ),
        DashboardViewState.success => _DashboardStatePanel(
          icon: AppIcons.success,
          title: 'Report submitted',
          message:
              'Your report was received and routed to the responsible civic team.',
          actionLabel: 'View My Reports',
          onAction: onViewReports,
        ),
        DashboardViewState.error => _DashboardStatePanel(
          icon: AppIcons.error,
          title: 'Reports could not load',
          message: 'Try again. No data was changed.',
          actionLabel: 'Try Again',
          onAction: onReset,
        ),
        DashboardViewState.offline => _DashboardStatePanel(
          icon: AppIcons.offline,
          title: 'You are offline',
          message: 'Saved dashboard content is shown until connection returns.',
          actionLabel: 'Show Saved Content',
          onAction: onReset,
        ),
        DashboardViewState.permissionRequired => _DashboardStatePanel(
          icon: AppIcons.permissionDenied,
          title: 'Permission required',
          message: 'Enable location permission to view nearby civic issues.',
          actionLabel: 'Open Settings',
          onAction: onOpenSettings,
        ),
        DashboardViewState.disabled => _DashboardContent(
          reports: <CivicReport>[],
          displayName: displayName,
          actionsDisabled: true,
          onViewReports: null,
        ),
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.reports,
    required this.displayName,
    required this.onViewReports,
    this.actionsDisabled = false,
  });

  final List<CivicReport> reports;
  final String displayName;
  final VoidCallback? onViewReports;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            civicContentPadding(context).top + AppSpacing.lg,
            horizontalPadding,
            civicContentPadding(context).bottom + AppSpacing.lg,
          ),
          children: [
            Text(
              'Good Morning, ${displayName.trim().isEmpty ? 'Citizen' : displayName.trim()}',
              style: compact
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Let's improve our community together.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ReportHeroCard(
              actionsDisabled: actionsDisabled,
              onReportNow: () =>
                  Navigator.of(context).pushNamed(CreateReportScreen.routeName),
              onViewReports: onViewReports,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (actionsDisabled) ...[
              const _InlineStateBanner(
                icon: AppIcons.warning,
                title: 'Actions disabled',
                message:
                    'Reporting is temporarily unavailable during maintenance.',
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            ValueListenableBuilder<CitizenProfile>(
              valueListenable: ProfileCrudService.instance.profile,
              builder: (context, profile, _) {
                if (!profile.isGuest) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: _InlineStateBanner(
                    icon: AppIcons.profile,
                    title: "You're browsing as a guest",
                    message:
                        'Reports you submit are saved and trackable right '
                        "here. Create a free account so they're tied to "
                        "you permanently, even if you switch devices.",
                    actionLabel: 'Create Account',
                    onAction: () =>
                        Navigator.of(context).pushNamed('/registration'),
                  ),
                );
              },
            ),
            const _QuickActionGrid(),
            const SizedBox(height: AppSpacing.xl),
            _AnalyticsRow(reports: reports),
            const SizedBox(height: AppSpacing.xl),
            _RecentReportsSection(
              reports: reports,
              onViewReports: onViewReports,
            ),
          ],
        );
      },
    );
  }
}

class _DashboardEmptyContent extends StatelessWidget {
  const _DashboardEmptyContent({
    required this.displayName,
    required this.onCreateReport,
  });

  final String displayName;
  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;

        return ListView(
          key: const ValueKey('dashboard-empty-content'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            civicContentPadding(context).top + AppSpacing.lg,
            horizontalPadding,
            civicContentPadding(context).bottom + AppSpacing.lg,
          ),
          children: [
            Text(
              'Good Morning, ${displayName.trim().isEmpty ? 'Citizen' : displayName.trim()}',
              style: compact
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Let's improve our community together.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ReportHeroCard(
              actionsDisabled: false,
              onReportNow: onCreateReport,
              onViewReports: null,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _QuickActionGrid(),
            const SizedBox(height: AppSpacing.xl),
            const _EmptyAnalyticsRow(),
            const SizedBox(height: AppSpacing.xl),
            _EmptyRecentReportsCard(onCreateReport: onCreateReport),
          ],
        );
      },
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard({
    required this.actionsDisabled,
    required this.onReportNow,
    required this.onViewReports,
  });

  final bool actionsDisabled;
  final VoidCallback onReportNow;
  final VoidCallback? onViewReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report a Community Issue',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Submit reports about roads, sanitation, lighting, water, security, or other public infrastructure issues.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: actionsDisabled ? null : onReportNow,
              child: const Text('Report Now'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: actionsDisabled ? null : onViewReports,
              child: const Text('View My Reports'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  static const _actions = [
    (AppIcons.add, 'Report Issue', 'Submit a new report'),
    (AppIcons.report, 'My Reports', 'View report history'),
    (AppIcons.pinned, 'Nearby Issues', 'See local activity'),
    (AppIcons.notificationsActive, 'Alerts', 'View notifications'),
  ];

  void _handleAction(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed(CreateReportScreen.routeName);
      case 1:
        Navigator.of(context).pushNamed(CitizenReportsScreen.routeName);
      case 2:
        _showNearbyIssues(context);
      case 3:
        Navigator.of(context).pushNamed(CitizenAlertsScreen.routeName);
    }
  }

  void _showNearbyIssues(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ValueListenableBuilder<List<CivicReport>>(
            valueListenable: ReportCrudService.instance.reports,
            builder: (context, reports, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby Issues',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Recent report activity around your community.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (reports.isEmpty)
                      CivicGlassCard(
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.empty,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'No nearby issues yet. Create the first report for your community.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: reports.take(5).length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            return _ReportListTile(
                              report: report,
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ReportTrackingScreen(
                                      reportId: report.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushNamed(CitizenReportsScreen.routeName);
                        },
                        icon: const Icon(AppIcons.report),
                        label: const Text('View All Reports'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        return GridView.builder(
          itemCount: _actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: compact ? 188 : 176,
          ),
          itemBuilder: (context, index) {
            final action = _actions[index];
            return _QuickActionCard(
              icon: action.$1,
              title: action.$2,
              subtitle: action.$3,
              onTap: () => _handleAction(context, index),
            );
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: CivicGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: AppIconSize.lg),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({required this.reports});

  final List<CivicReport> reports;

  @override
  Widget build(BuildContext context) {
    final submittedCount = reports.length;
    final reviewCount = reports
        .where(
          (report) =>
              report.status == ReportStatus.underReview ||
              report.status == ReportStatus.assigned ||
              report.status == ReportStatus.inProgress,
        )
        .length;
    final resolvedCount = reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: AppIcons.statusSubmitted,
            value: submittedCount.toString(),
            label: 'Submitted',
          ),
        ),
        const StatTileDivider(),
        Expanded(
          child: StatTile(
            icon: AppIcons.statusUnderReview,
            value: reviewCount.toString(),
            label: 'In Review',
          ),
        ),
        const StatTileDivider(),
        Expanded(
          child: StatTile(
            icon: AppIcons.statusResolved,
            value: resolvedCount.toString(),
            label: 'Resolved',
          ),
        ),
      ],
    );
  }
}

class _EmptyAnalyticsRow extends StatelessWidget {
  const _EmptyAnalyticsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: StatTile(
            icon: AppIcons.statusSubmitted,
            value: '0',
            label: 'Submitted',
          ),
        ),
        StatTileDivider(),
        Expanded(
          child: StatTile(
            icon: AppIcons.statusUnderReview,
            value: '0',
            label: 'In Review',
          ),
        ),
        StatTileDivider(),
        Expanded(
          child: StatTile(
            icon: AppIcons.statusResolved,
            value: '0',
            label: 'Resolved',
          ),
        ),
      ],
    );
  }
}

class _RecentReportsSection extends StatelessWidget {
  const _RecentReportsSection({
    required this.reports,
    required this.onViewReports,
  });

  final List<CivicReport> reports;
  final VoidCallback? onViewReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent Reports', style: theme.textTheme.titleLarge),
            ),
            TextButton(onPressed: onViewReports, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final report in reports.take(3)) ...[
          _ReportListTile(
            report: report,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportTrackingScreen(reportId: report.id),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _EmptyRecentReportsCard extends StatelessWidget {
  const _EmptyRecentReportsCard({required this.onCreateReport});

  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Reports', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        CivicGlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppIconSize.xl,
                height: AppIconSize.xl,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.allLg,
                ),
                child: const Icon(AppIcons.empty, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No reports yet', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your first report will appear here after submission.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: onCreateReport,
                        child: const Text('Report Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({required this.report, this.onTap});

  final CivicReport report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;

        return Semantics(
          button: onTap != null,
          label: 'Track ${report.title}',
          child: GestureDetector(
            onTap: onTap,
            child: CivicGlassCard(
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReportTileMainContent(report: report),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ReportStatusBadge(status: report.status),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _ReportTileMainContent(report: report)),
                        const SizedBox(width: AppSpacing.sm),
                        ReportStatusBadge(status: report.status),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportTileMainContent extends StatelessWidget {
  const _ReportTileMainContent({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          AppIcons.report,
          size: AppIconSize.md,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${report.location} - ${report.timeLabel}',
                style: theme.textTheme.labelSmall,
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

class _InlineStateBanner extends StatelessWidget {
  const _InlineStateBanner({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: theme.textTheme.bodySmall),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatePanel extends StatelessWidget {
  const _DashboardStatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey(title),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        civicContentPadding(context).top + AppSpacing.md,
        AppSpacing.md,
        civicContentPadding(context).bottom + AppSpacing.md,
      ),
      children: [
        const SizedBox(height: AppSpacing.xxl),
        CivicStatusPanel(
          icon: icon,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ],
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('dashboard-loading'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        civicContentPadding(context).top + AppSpacing.md,
        AppSpacing.md,
        civicContentPadding(context).bottom + AppSpacing.md,
      ),
      children: const [
        _SkeletonBlock(widthFactor: 0.86, height: 72),
        SizedBox(height: AppSpacing.md),
        _SkeletonBlock(widthFactor: 0.72, height: 24),
        SizedBox(height: AppSpacing.xl),
        _SkeletonBlock(widthFactor: 1, height: 292),
        SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: _SkeletonBlock(widthFactor: 1, height: 136)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _SkeletonBlock(widthFactor: 1, height: 136)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.allMd,
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

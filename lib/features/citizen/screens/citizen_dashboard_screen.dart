import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/civic_glass_card.dart';
import '../../../shared/widgets/civic_status_panel.dart';
import '../models/civic_report.dart';
import '../models/dashboard_view_state.dart';
import '../widgets/civic_app_chrome.dart';
import 'create_report_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({
    super.key,
    this.initialState = DashboardViewState.content,
  });

  static const String routeName = '/citizen/dashboard';

  final DashboardViewState initialState;

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen>
    with WidgetsBindingObserver {
  late DashboardViewState _state;
  int _selectedIndex = 0;
  bool _locationDialogVisible = false;

  static const List<CivicReport> _recentReports = [
    CivicReport(
      title: 'Street light outage',
      location: 'Victoria Island',
      timeLabel: '2h ago',
      status: ReportStatus.inProgress,
    ),
    CivicReport(
      title: 'Drainage blockage',
      location: 'Lekki Phase 1',
      timeLabel: 'Yesterday',
      status: ReportStatus.underReview,
    ),
    CivicReport(
      title: 'Pothole on service lane',
      location: 'Ikeja GRA',
      timeLabel: 'Jun 28',
      status: ReportStatus.resolved,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationAccess(requestPermission: true);
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (!serviceEnabled) {
        _showLocationDialog(
          title: 'Turn on Location',
          message:
              'CivicVoice needs your phone location to show nearby reports and capture accurate report GPS.',
          actionLabel: 'Turn On Location',
          onAction: Geolocator.openLocationSettings,
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() => _state = DashboardViewState.permissionRequired);
        _showLocationDialog(
          title: 'Allow Location',
          message:
              'Please allow location permission so CivicVoice can attach GPS to your civic reports.',
          actionLabel: 'Allow Location',
          onAction: () => _checkLocationAccess(requestPermission: true),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _state = DashboardViewState.permissionRequired);
        _showLocationDialog(
          title: 'Location Blocked',
          message:
              'Location permission is blocked. Open app settings and allow location access.',
          actionLabel: 'Open Settings',
          onAction: Geolocator.openAppSettings,
        );
        return;
      }

      if (_state == DashboardViewState.permissionRequired) {
        setState(() => _state = DashboardViewState.content);
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
    return Scaffold(
      extendBody: true,
      appBar: const CivicTopBar(),
      body: SafeArea(
        top: false,
        child: _DashboardBody(
          state: _state,
          onReset: () => setState(() => _state = DashboardViewState.content),
        ),
      ),
      bottomNavigationBar: CivicBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.of(context).pushNamed(CreateReportScreen.routeName);
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.onReset});

  final DashboardViewState state;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotionDuration.standard),
      child: switch (state) {
        DashboardViewState.loading => const _DashboardLoading(),
        DashboardViewState.content => const _DashboardContent(),
        DashboardViewState.empty => _DashboardStatePanel(
          icon: AppIcons.empty,
          title: 'No reports yet',
          message:
              'Create your first community report to start tracking progress.',
          actionLabel: 'Report Now',
          onAction: onReset,
        ),
        DashboardViewState.success => _DashboardStatePanel(
          icon: AppIcons.success,
          title: 'Report submitted',
          message:
              'Your report was received and routed to the responsible civic team.',
          actionLabel: 'View My Reports',
          onAction: onReset,
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
          onAction: onReset,
        ),
        DashboardViewState.disabled => const _DashboardContent(
          actionsDisabled: true,
        ),
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({this.actionsDisabled = false});

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
            AppSpacing.lg,
            horizontalPadding,
            120,
          ),
          children: [
            Text(
              'Good Morning, Abdul Malik',
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
            const _QuickActionGrid(),
            const SizedBox(height: AppSpacing.xl),
            const _AnalyticsRow(),
            const SizedBox(height: AppSpacing.xl),
            const _RecentReportsSection(),
            const SizedBox(height: AppSpacing.xl),
            const _CommunityUpdatesSection(),
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
  });

  final bool actionsDisabled;
  final VoidCallback onReportNow;

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
          FilledButton(
            onPressed: actionsDisabled ? null : onReportNow,
            child: const Text('Report Now'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: actionsDisabled ? null : () {},
            child: const Text('View My Reports'),
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
    (AppIcons.notificationsActive, 'Community', 'Read updates'),
  ];

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
            childAspectRatio: compact ? 0.95 : 1.18,
          ),
          itemBuilder: (context, index) {
            final action = _actions[index];
            return _QuickActionCard(
              icon: action.$1,
              title: action.$2,
              subtitle: action.$3,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppIconSize.xl,
            height: AppIconSize.xl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.allLg,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
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
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _AnalyticsCard(
            icon: AppIcons.statusSubmitted,
            count: '12',
            label: 'Submitted',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AnalyticsCard(
            icon: AppIcons.statusUnderReview,
            count: '5',
            label: 'In Review',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AnalyticsCard(
            icon: AppIcons.statusResolved,
            count: '7',
            label: 'Resolved',
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(count, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentReportsSection extends StatelessWidget {
  const _RecentReportsSection();

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
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final report in _CitizenDashboardScreenState._recentReports) ...[
          _ReportListTile(report: report),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;

        return CivicGlassCard(
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportTileMainContent(report: report),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusChip(status: report.status),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _ReportTileMainContent(report: report)),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusChip(status: report.status),
                  ],
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
        Container(
          width: AppIconSize.xl,
          height: AppIconSize.xl,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
          ),
          child: const Icon(AppIcons.report),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: AppIconSize.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppFontWeight.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityUpdatesSection extends StatelessWidget {
  const _CommunityUpdatesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Community Updates', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        const _UpdateCard(
          title: 'Water works scheduled',
          message: 'Maintenance begins Friday at 9:00 AM across Ward 4.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _UpdateCard(
          title: 'Sanitation response improved',
          message: 'Average closure time dropped to 3.2 days this month.',
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStateBanner extends StatelessWidget {
  const _InlineStateBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
      padding: const EdgeInsets.all(AppSpacing.md),
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
      padding: const EdgeInsets.all(AppSpacing.md),
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../utils/time_greeting.dart';
import '../models/dashboard_data.dart';
import '../models/incoming_report.dart';
import '../services/municipal_report_directory.dart';
import '../../../widgets/glass_card.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../widgets/municipal_scaffold.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/status_badge.dart';

/// MUN-001 — Municipal Dashboard.
///
/// Approved states (Figma "01 - Dashboard" section): Default, Loading,
/// Empty, Error, Offline, Permission — no Success/Disabled, since a
/// read-only overview screen has no completable action to confirm.
///
/// The module shell stays in place while the dashboard data loads.
enum MunicipalDashboardViewState {
  loading,
  loaded,
  empty,
  error,
  offline,
  permissionDenied,
}

class MunicipalDashboardScreen extends StatefulWidget {
  const MunicipalDashboardScreen({
    super.key,
    this.initialState = MunicipalDashboardViewState.loaded,
    this.data,
    this.onNavigateToInbox,
    this.onNavigateToActiveReports,
    this.onNavigateToResolvedReports,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onReportTap,
  });

  /// Testing hook: defaults to the normal loaded view. Pass a different
  /// value to preview another approved state until this screen is wired to
  /// a live Cloud Firestore stream (Issue 03 dependency).
  final MunicipalDashboardViewState initialState;
  final MunicipalDashboardData? data;

  /// Wired by the app shell so the bottom nav can actually switch screens
  /// now that both MUN-001 and MUN-002 exist.
  final VoidCallback? onNavigateToInbox;

  /// Wired by the app shell so the bottom nav's "Active" tab can switch to
  /// MUN-006 Active Reports, now that it exists.
  final VoidCallback? onNavigateToActiveReports;

  /// Wired by the app shell so the bottom nav's "Resolved" tab can switch
  /// to MUN-008 Resolved Reports, now that it exists.
  final VoidCallback? onNavigateToResolvedReports;

  /// Opens MUN-009 Municipal Profile — wired to the header's profile
  /// avatar, now that it exists.
  final VoidCallback? onProfileTap;

  /// Opens Municipal Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens MUN-004 Report Review for the tapped row — the same report
  /// shown here, since Recent Reports now reuses MUN-002 Incoming Reports'
  /// own [IncomingReportItem] list instead of a separate mock dataset.
  final ValueChanged<IncomingReportItem>? onReportTap;

  @override
  State<MunicipalDashboardScreen> createState() =>
      _MunicipalDashboardScreenState();
}

class _MunicipalDashboardScreenState extends State<MunicipalDashboardScreen> {
  late MunicipalDashboardViewState _state = widget.initialState;
  late MunicipalDashboardData _data =
      widget.data ?? MunicipalDashboardData.mock();

  @override
  void didUpdateWidget(covariant MunicipalDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        widget.initialState != oldWidget.initialState) {
      _data = widget.data ?? _data;
      _state = widget.initialState;
    }
  }

  Future<void> _retry() async {
    // Keep the retry view in place; its action owns busy feedback.
    try {
      await MunicipalReportDirectory.instance.refresh();
      if (mounted) {
        setState(() {
          _data = widget.data ?? MunicipalDashboardData.current();
          _state = _data.recentReports.isEmpty
              ? MunicipalDashboardViewState.empty
              : MunicipalDashboardViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = MunicipalDashboardViewState.error);
    }
  }

  Future<void> _pullRefresh() async {
    try {
      await MunicipalReportDirectory.instance.refresh();
      if (mounted) {
        setState(() {
          _data = MunicipalDashboardData.current();
          _state = _data.recentReports.isEmpty
              ? MunicipalDashboardViewState.empty
              : MunicipalDashboardViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = MunicipalDashboardViewState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MunicipalScaffold(
      selectedTab: MunicipalTab.dashboard,
      onNotificationsTap: widget.onNotificationsTap,
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MunicipalTab.inbox) widget.onNavigateToInbox?.call();
        if (tab == MunicipalTab.active) {
          widget.onNavigateToActiveReports?.call();
        }
        if (tab == MunicipalTab.resolved) {
          widget.onNavigateToResolvedReports?.call();
        }
      },
      body: GhanaRefreshIndicator(
        onRefresh: _pullRefresh,
        topOffset: MunicipalScaffold.contentPadding(context).top,
        child: switch (_state) {
          MunicipalDashboardViewState.loading => Padding(
            padding: MunicipalScaffold.contentPadding(context),
            child: const GhanaLoadingIndicator(label: 'Loading dashboard…'),
          ),
          MunicipalDashboardViewState.loaded => _DashboardContent(
            data: _data,
            empty: false,
            onViewAllReports: widget.onNavigateToInbox,
            onReportTap: widget.onReportTap,
          ),
          MunicipalDashboardViewState.empty => _DashboardContent(
            data: _data,
            onViewAllReports: widget.onNavigateToInbox,
            empty: true,
            onReportTap: widget.onReportTap,
          ),
          MunicipalDashboardViewState.error => Padding(
            padding: MunicipalScaffold.contentPadding(context),
            child: AppStateMessage(
              icon: AppIcons.warning,
              badgeColor: AppColors.error,
              title: 'Unable to load dashboard',
              message: 'Refresh the dashboard or try again in a few minutes.',
              primaryActionLabel: 'Try again',
              onPrimaryAction: _retry,
              primaryActionColor: AppColors.error,
              bordered: true,
            ),
          ),
          MunicipalDashboardViewState.offline => Padding(
            padding: MunicipalScaffold.contentPadding(context),
            child: AppStateMessage(
              icon: AppIcons.offline,
              badgeColor: AppColors.error,
              title: 'You\'re offline',
              message:
                  'Showing saved dashboard content until your connection returns.',
              primaryActionLabel: 'Retry connection',
              onPrimaryAction: _retry,
              primaryActionColor: AppColors.error,
              bordered: true,
            ),
          ),
          MunicipalDashboardViewState.permissionDenied => Padding(
            padding: MunicipalScaffold.contentPadding(context),
            child: AppStateMessage(
              icon: AppIcons.permissionDenied,
              badgeColor: AppColors.primary,
              title: 'Access Restricted',
              message:
                  'You currently do not have permission to view the Municipal '
                  'Dashboard for this district. Please request access from the '
                  'regional administrator.',
              primaryActionLabel: 'Request Access',
              // No access-request workflow is specified in Issue 03 —
              // placeholder pending spec.
              onPrimaryAction: null,
              secondaryActionLabel: 'Return to Home',
              onSecondaryAction: null,
              bordered: true,
            ),
          ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared content for Loaded / Empty
// ---------------------------------------------------------------------------

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.empty,
    this.onViewAllReports,
    this.onReportTap,
  });

  final MunicipalDashboardData data;
  final VoidCallback? onViewAllReports;
  final ValueChanged<IncomingReportItem>? onReportTap;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final stats = empty ? MunicipalDashboardStats.zero : data.stats;
    final chromeInset = MunicipalScaffold.contentPadding(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        _DashboardGreeting(
          officerName: data.officerName,
          municipalityName: data.municipalityName,
        ),
        const SizedBox(height: AppSpacing.md),
        _StatsGrid(stats: stats),
        const SizedBox(height: AppSpacing.xl),
        if (MunicipalReportDirectory.instance.reports.value.any(
          (r) => r.status.name == 'pendingApproval',
        )) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Awaiting Confirmation',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final report
                    in MunicipalReportDirectory.instance.reports.value.where(
                      (r) => r.status.name == 'pendingApproval',
                    ))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(report.title),
                    subtitle: Text(report.referenceId),
                    trailing: const Icon(AppIcons.chevronRight),
                    onTap: onReportTap == null
                        ? null
                        : () => onReportTap!(report),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _RecentReportsCard(
          reports: data.recentReports,
          isEmpty: empty,
          onViewAll: onViewAllReports,
          onReportTap: onReportTap,
        ),
        if (!empty) ...[
          const SizedBox(height: AppSpacing.xl),
          _AssignmentSummaryCard(items: data.assignmentSummary),
        ],
      ],
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting({
    required this.officerName,
    required this.municipalityName,
  });

  final String officerName;
  final String municipalityName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${timeBasedGreeting()}, $officerName',
          style: compact ? textTheme.headlineSmall : textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Plain text, no card/border: officers are scoped to a single
        // assembly by the System Administrator at account creation (Issue
        // 03 business rule) — there's no self-service switch workflow —
        // and assemblies can be District, Municipal, or Metropolitan, so a
        // fixed "MUNICIPALITY" label was often just wrong. The name alone
        // says what it needs to.
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
                municipalityName,
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
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final MunicipalDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale =
            (MediaQuery.textScalerOf(context).scale(AppFontSize.bodySmall) /
                    AppFontSize.bodySmall)
                .clamp(1.0, double.infinity);
        final isTablet = constraints.maxWidth / textScale >= 720;
        final isNarrow = constraints.maxWidth < 360;
        return GridView.count(
          crossAxisCount: isTablet
              ? 4
              : textScale > 1 &&
                    constraints.maxWidth / textScale <
                        AppBreakpoints.smallMobile
              ? 1
              : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: (isNarrow ? 144 : 132) * textScale,
          children: [
            _StatCard(
              label: 'New Reports',
              value: stats.newReports,
              icon: AppIcons.report,
            ),
            _StatCard(
              label: 'Under Review',
              value: stats.underReview,
              icon: AppIcons.statusUnderReview,
            ),
            _StatCard(
              label: 'Assigned',
              value: stats.assigned,
              icon: AppIcons.statusAssigned,
            ),
            _StatCard(
              label: 'Resolved',
              value: stats.resolved,
              icon: AppIcons.statusResolved,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

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
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ),
              Icon(
                icon,
                size: AppIconSize.md,
                color: AppSemanticColors.of(context).actionText,
              ),
            ],
          ),
          const Spacer(),
          Text('$value', style: textTheme.headlineLarge),
        ],
      ),
    );
  }
}

class _RecentReportsCard extends StatelessWidget {
  const _RecentReportsCard({
    required this.reports,
    required this.isEmpty,
    this.onViewAll,
    this.onReportTap,
  });

  final List<IncomingReportItem> reports;
  final bool isEmpty;
  final VoidCallback? onViewAll;
  final ValueChanged<IncomingReportItem>? onReportTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Reports',
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
          ),
          if (isEmpty)
            const _RecentReportsEmpty()
          else
            for (final report in reports)
              _RecentReportRow(
                report: report,
                isFirst: report == reports.first,
                onTap: onReportTap == null ? null : () => onReportTap!(report),
              ),
        ],
      ),
    );
  }
}

class _RecentReportRow extends StatelessWidget {
  const _RecentReportRow({
    required this.report,
    required this.isFirst,
    this.onTap,
  });

  final IncomingReportItem report;
  final bool isFirst;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: semantic.glassBorder)),
        ),
        child: Row(
          children: [
            const _ReportRowIcon(),
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
                          report.title,
                          style: textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(child: ReportStatusBadge(status: report.status)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${report.category.label} · ${report.timeAgo} · ${report.referenceId}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The generic report-row leading icon.
class _ReportRowIcon extends StatelessWidget {
  const _ReportRowIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.report,
      size: AppIconSize.lg,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

class _RecentReportsEmpty extends StatelessWidget {
  const _RecentReportsEmpty();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: semantic.iconBadgeSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.empty,
              size: AppIconSize.md,
              color: AppSemanticColors.of(context).actionText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No reports yet',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New municipal reports will appear here when residents submit them.',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AssignmentSummaryCard extends StatelessWidget {
  const _AssignmentSummaryCard({required this.items});

  final List<AssignmentProgress> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assignment Summary', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final item in items) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.teamName,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                ),
                Text(
                  '${(item.percent * 100).round()}%',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadius.allXl,
              child: LinearProgressIndicator(
                value: item.percent,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            if (item != items.last) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

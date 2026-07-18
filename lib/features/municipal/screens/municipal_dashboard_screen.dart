import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/dashboard_data.dart';
import '../models/incoming_report.dart';
import '../../../widgets/glass_card.dart';
import '../widgets/municipal_scaffold.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/status_badge.dart';

/// MUN-001 — Municipal Dashboard.
///
/// Approved states (Figma "01 - Dashboard" section): Default, Loading,
/// Empty, Error, Offline, Permission — no Success/Disabled, since a
/// read-only overview screen has no completable action to confirm.
///
/// Loading and Empty keep the page shell in place (municipality selector,
/// stats grid) and only swap the data-driven parts — they are not full-page
/// replacements. Error/Offline/Permission genuinely have nothing to show, so
/// those replace the whole body.
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
  final MunicipalDashboardData _data = MunicipalDashboardData.mock();

  void _retry() {
    setState(() => _state = MunicipalDashboardViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MunicipalDashboardViewState.loaded);
    });
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
      body: switch (_state) {
        MunicipalDashboardViewState.loading => _DashboardContent(
          data: _data,
          loading: true,
          empty: false,
          onViewAllReports: widget.onNavigateToInbox,
          onReportTap: widget.onReportTap,
        ),
        MunicipalDashboardViewState.loaded => _DashboardContent(
          data: _data,
          loading: false,
          empty: false,
          onViewAllReports: widget.onNavigateToInbox,
          onReportTap: widget.onReportTap,
        ),
        MunicipalDashboardViewState.empty => _DashboardContent(
          data: _data,
          onViewAllReports: widget.onNavigateToInbox,
          loading: false,
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
            onPrimaryAction: () {},
            secondaryActionLabel: 'Return to Home',
            onSecondaryAction: () {},
            bordered: true,
          ),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared shell for Loading / Loaded / Empty
// ---------------------------------------------------------------------------

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.loading,
    required this.empty,
    this.onViewAllReports,
    this.onReportTap,
  });

  final MunicipalDashboardData data;
  final VoidCallback? onViewAllReports;
  final ValueChanged<IncomingReportItem>? onReportTap;
  final bool loading;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final stats = empty ? MunicipalDashboardStats.zero : data.stats;
    final chromeInset = MunicipalScaffold.contentPadding(context);
    return ListView(
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
        if (loading) ...[
          const SizedBox(height: AppSpacing.sm),
          const _LoadingIndicatorRow(),
        ],
        const SizedBox(height: AppSpacing.xl),
        _StatsGrid(stats: stats, isLoading: loading),
        const SizedBox(height: AppSpacing.xl),
        _RecentReportsCard(
          reports: data.recentReports,
          isLoading: loading,
          isEmpty: empty,
          onViewAll: onViewAllReports,
          onReportTap: onReportTap,
        ),
        if (!loading && !empty) ...[
          const SizedBox(height: AppSpacing.xl),
          _AssignmentSummaryCard(items: data.assignmentSummary),
        ],
      ],
    );
  }
}

class _LoadingIndicatorRow extends StatelessWidget {
  const _LoadingIndicatorRow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: AppIconSize.sm,
          height: AppIconSize.sm,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Loading dashboard data', style: textTheme.bodySmall),
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
          'Good Morning, $officerName',
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
  const _StatsGrid({required this.stats, required this.isLoading});

  final MunicipalDashboardStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 189 / 128,
      children: [
        _StatCard(
          label: 'New Reports',
          value: stats.newReports,
          icon: AppIcons.report,
          isLoading: isLoading,
        ),
        _StatCard(
          label: 'Under Review',
          value: stats.underReview,
          icon: AppIcons.statusUnderReview,
          isLoading: isLoading,
        ),
        _StatCard(
          label: 'Assigned',
          value: stats.assigned,
          icon: AppIcons.statusAssigned,
          isLoading: isLoading,
        ),
        _StatCard(
          label: 'Resolved',
          value: stats.resolved,
          icon: AppIcons.statusResolved,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: isLoading
                    ? const _ShimmerBlock(height: 14, widthFactor: 0.7)
                    : Text(
                        label,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
              ),
              Container(
                width: AppIconSize.lg,
                height: AppIconSize.lg,
                decoration: BoxDecoration(
                  color: semantic.iconBadgeSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.sm + 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          isLoading
              ? const _ShimmerBlock(height: 28, widthFactor: 0.4)
              : Text('$value', style: textTheme.headlineLarge),
        ],
      ),
    );
  }
}

class _RecentReportsCard extends StatelessWidget {
  const _RecentReportsCard({
    required this.reports,
    required this.isLoading,
    required this.isEmpty,
    this.onViewAll,
    this.onReportTap,
  });

  final List<IncomingReportItem> reports;
  final bool isLoading;
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
                Text('Recent Reports', style: textTheme.titleMedium),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
          ),
          if (isLoading)
            for (var i = 0; i < 4; i++)
              _RecentReportRowSkeleton(isFirst: i == 0)
          else if (isEmpty)
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
                      ReportStatusBadge(status: report.status),
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

class _RecentReportRowSkeleton extends StatelessWidget {
  const _RecentReportRowSkeleton({required this.isFirst});

  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(height: 14, widthFactor: 0.7),
                SizedBox(height: AppSpacing.sm),
                _ShimmerBlock(height: 12, widthFactor: 0.45),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The generic report-row leading icon — real in every state (loading
/// included), matching the approved design.
class _ReportRowIcon extends StatelessWidget {
  const _ReportRowIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.controlHeightStandard,
      height: AppDimensions.controlHeightStandard,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: AppComponentRadius.inputField,
      ),
      child: Icon(
        AppIcons.report,
        size: AppIconSize.md,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
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
            child: const Icon(
              AppIcons.empty,
              size: AppIconSize.md,
              color: AppColors.primary,
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
                Text(
                  item.teamName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: AppFontWeight.medium,
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

// ---------------------------------------------------------------------------
// Shimmer skeleton primitive — used by loading sub-states above (blank
// screens are prohibited, §19.18).
// ---------------------------------------------------------------------------

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height, this.widthFactor = 1.0});

  final double height;

  /// Fraction of the available width the block should occupy (0.0–1.0).
  final double widthFactor;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
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

    return FractionallySizedBox(
      widthFactor: widget.widthFactor,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: AppRadius.allXs,
            ),
          );
        },
      ),
    );
  }
}

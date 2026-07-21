import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/civic_glass_card.dart';
import '../models/civic_report.dart';
import '../services/report_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_profile_screen.dart';
import 'create_report_screen.dart';
import 'report_tracking_screen.dart';

enum _ReportFilter {
  all('All'),
  underReview('Under Review'),
  inProgress('In Progress'),
  resolved('Resolved'),
  rejected('Rejected');

  const _ReportFilter(this.label);

  final String label;
}

class CitizenReportsScreen extends StatefulWidget {
  const CitizenReportsScreen({super.key});

  static const String routeName = '/citizen/reports';

  @override
  State<CitizenReportsScreen> createState() => _CitizenReportsScreenState();
}

class _CitizenReportsScreenState extends State<CitizenReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ReportFilter _filter = _ReportFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CivicReport> _applyFilters(List<CivicReport> reports) {
    final query = _searchController.text.trim().toLowerCase();

    return reports.where((report) {
      final matchesFilter = switch (_filter) {
        _ReportFilter.all => true,
        _ReportFilter.underReview => report.status == ReportStatus.underReview,
        _ReportFilter.inProgress =>
          report.status == ReportStatus.inProgress ||
              report.status == ReportStatus.assigned ||
              report.status == ReportStatus.submitted,
        _ReportFilter.resolved => report.status == ReportStatus.resolved,
        _ReportFilter.rejected => report.status == ReportStatus.rejected,
      };

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      return report.title.toLowerCase().contains(query) ||
          report.location.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query) ||
          report.referenceNumber.toLowerCase().contains(query);
    }).toList();
  }

  void _openDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openCreateReport() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CreateReportScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openAlerts() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenAlertsScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openProfile() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenProfileScreen.routeName,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      // See create_report_screen.dart's build() for why this is false and
      // paired with the keyboardVisible-guarded nav below.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<List<CivicReport>>(
              valueListenable: ReportCrudService.instance.reports,
              builder: (context, reports, _) {
                final visibleReports = _applyFilters(reports);
                final chromeInset = civicContentPadding(context);

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    chromeInset.top + AppSpacing.xl,
                    horizontalPadding,
                    chromeInset.bottom + AppSpacing.xl,
                  ),
                  children: [
                    const _ReportsIntro(),
                    const SizedBox(height: AppSpacing.lg),
                    _ReportsStatsRow(reports: reports),
                    const SizedBox(height: AppSpacing.lg),
                    _ReportsSearchField(controller: _searchController),
                    const SizedBox(height: AppSpacing.md),
                    _ReportFilterBar(
                      selected: _filter,
                      onSelected: (filter) => setState(() => _filter = filter),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (reports.isEmpty)
                      _ReportsEmptyState(onCreateReport: _openCreateReport)
                    else if (visibleReports.isEmpty)
                      const _NoFilteredReports()
                    else
                      for (final report in visibleReports) ...[
                        _ReportHistoryCard(report: report),
                        const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                );
              },
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(title: 'My Reports', showNotifications: false),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 1,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    _openDashboard();
                  } else if (index == 2) {
                    _openCreateReport();
                  } else if (index == 3) {
                    _openAlerts();
                  } else if (index == 4) {
                    _openProfile();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportsSearchField extends StatelessWidget {
  const _ReportsSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodySmall,
      // Glass — see MunicipalSearchField's doc comment.
      decoration: InputDecoration(
        filled: true,
        fillColor: semantic.glassSurface,
        isDense: true,
        prefixIcon: const Icon(AppIcons.search, size: AppIconSize.md),
        hintText: 'Search your reports',
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: controller.clear,
                icon: const Icon(AppIcons.close),
              ),
      ),
    );
  }
}

class _ReportFilterBar extends StatelessWidget {
  const _ReportFilterBar({required this.selected, required this.onSelected});

  final _ReportFilter selected;
  final ValueChanged<_ReportFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _ReportFilter.values) ...[
            ChoiceChip(
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
              label: Text(filter.label),
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: selected == filter
                    ? Colors.white
                    : theme.colorScheme.secondary,
                fontWeight: AppFontWeight.semiBold,
              ),
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              side: BorderSide(
                color: selected == filter
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  const _ReportHistoryCard({required this.report});

  final CivicReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = report.status.color;

    return CivicGlassCard(
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ReportInfoLine(
                      icon: AppIcons.location,
                      label: report.location,
                    ),
                  ],
                ),
              ),
              _StatusPill(label: report.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportProgress(status: report.status),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  report.referenceNumber.isEmpty
                      ? 'Reference pending'
                      : report.referenceNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReportTrackingScreen(reportId: report.id),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(104, 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: const Text('View Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsIntro extends StatelessWidget {
  const _ReportsIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your reports',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Only reports submitted from your citizen account are shown.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _ReportsStatsRow extends StatelessWidget {
  const _ReportsStatsRow({required this.reports});

  final List<CivicReport> reports;

  @override
  Widget build(BuildContext context) {
    final resolvedCount = reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;
    final activeCount = reports
        .where(
          (report) =>
              report.status != ReportStatus.resolved &&
              report.status != ReportStatus.rejected,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _ReportsStatCard(
            label: 'REPORTS',
            value: reports.length.toString(),
            subtitle: 'Submitted',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ReportsStatCard(
            label: 'RESOLVED',
            value: resolvedCount.toString(),
            subtitle: 'Closed',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ReportsStatCard(
            label: 'ACTIVE',
            value: activeCount.toString(),
            subtitle: 'In progress',
          ),
        ),
      ],
    );
  }
}

class _ReportsStatCard extends StatelessWidget {
  const _ReportsStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _ReportProgress extends StatelessWidget {
  const _ReportProgress({required this.status});

  final ReportStatus status;

  double get _progress {
    return switch (status) {
      ReportStatus.submitted => 0.2,
      ReportStatus.underReview => 0.4,
      ReportStatus.assigned => 0.6,
      ReportStatus.inProgress => 0.72,
      ReportStatus.resolved => 1,
      ReportStatus.rejected => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.allXl,
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 5,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.32),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

class _ReportInfoLine extends StatelessWidget {
  const _ReportInfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: AppIconSize.sm, color: theme.colorScheme.secondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState({required this.onCreateReport});

  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.empty,
              color: AppColors.primary,
              size: AppIconSize.lg,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No reports yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reports you submit will appear here for tracking.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCreateReport,
              child: const Text('Create Report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoFilteredReports extends StatelessWidget {
  const _NoFilteredReports();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      child: Row(
        children: [
          const Icon(AppIcons.search, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No reports match this search or filter.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/incoming_report.dart';
import '../widgets/collapsible_list_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/municipal_scaffold.dart';
import '../widgets/municipal_search_field.dart';
import '../widgets/municipal_state_message.dart';
import '../widgets/status_badge.dart';

/// MUN-002 — Incoming Reports (Figma section "02 - Incoming Messages").
///
/// Approved states: Default, Empty, Offline, No-Results, Permission,
/// Loading, Error — no Success/Disabled, matching MUN-001's reasoning (a
/// read-only list has no completable action to confirm).
///
/// Default/Empty/No-Results/Loading share one page shell (search, category
/// chips) and only swap the list area — Error/Offline/Permission replace
/// the whole body in a bordered card, confirmed against this screen's
/// approved frames (unlike MUN-001, which was flat/unbordered before being
/// retrofitted to match this same pattern). The screen title itself lives
/// in [MunicipalScaffold]'s header, not in this body content.
enum MunicipalInboxViewState {
  loading,
  loaded,
  empty,
  noResults,
  error,
  offline,
  permissionDenied,
}

class MunicipalInboxScreen extends StatefulWidget {
  const MunicipalInboxScreen({
    super.key,
    this.initialState = MunicipalInboxViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToActiveReports,
    this.onNavigateToResolvedReports,
    this.onProfileTap,
    this.onReportTap,
  });

  /// Testing hook: defaults to the normal loaded view. Pass a different
  /// value to preview another approved state until this screen is wired to
  /// a live Cloud Firestore stream (Issue 03 dependency).
  final MunicipalInboxViewState initialState;

  /// Wired by the app shell so the bottom nav can actually switch screens
  /// now that both MUN-001 and MUN-002 exist.
  final VoidCallback? onNavigateToDashboard;

  /// Wired by the app shell so the bottom nav's "Active" tab can switch to
  /// MUN-006 Active Reports, now that it exists.
  final VoidCallback? onNavigateToActiveReports;

  /// Wired by the app shell so the bottom nav's "Resolved" tab can switch
  /// to MUN-008 Resolved Reports, now that it exists.
  final VoidCallback? onNavigateToResolvedReports;

  /// Opens MUN-009 Municipal Profile — wired to the header's profile
  /// avatar, now that it exists.
  final VoidCallback? onProfileTap;

  /// Wired by the app shell to navigate to MUN-003 Report Review.
  final ValueChanged<IncomingReportItem>? onReportTap;

  @override
  State<MunicipalInboxScreen> createState() => _MunicipalInboxScreenState();
}

class _MunicipalInboxScreenState extends State<MunicipalInboxScreen> {
  late MunicipalInboxViewState _state = widget.initialState;
  final _searchController = TextEditingController();
  ReportCategory? _selectedCategory;
  late final List<IncomingReportItem> _reports =
      widget.initialState == MunicipalInboxViewState.empty
      ? const []
      : IncomingReportItem.mock();

  @override
  void initState() {
    super.initState();
    if (widget.initialState == MunicipalInboxViewState.noResults) {
      // Deliberately matches nothing in the mock dataset, exactly like the
      // approved No-Results reference frame.
      _searchController.text = 'Pothole on Main St';
    }
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IncomingReportItem> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _reports.where((report) {
      final matchesQuery =
          query.isEmpty || report.title.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == null || report.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty || _selectedCategory != null;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
    });
  }

  void _retry() {
    setState(() => _state = MunicipalInboxViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MunicipalInboxViewState.loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MunicipalScaffold(
      selectedTab: MunicipalTab.inbox,
      // Notifications isn't one of the 9 approved MUN screens (Issue 03
      // §7) — left as a placeholder until that screen is specified.
      onNotificationsTap: () {},
      onProfileTap: widget.onProfileTap,
      onTabSelected: (tab) {
        if (tab == MunicipalTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == MunicipalTab.active) {
          widget.onNavigateToActiveReports?.call();
        }
        if (tab == MunicipalTab.resolved) {
          widget.onNavigateToResolvedReports?.call();
        }
      },
      body: switch (_state) {
        MunicipalInboxViewState.loading => const _InboxContent(loading: true),
        MunicipalInboxViewState.loaded ||
        MunicipalInboxViewState.empty ||
        MunicipalInboxViewState.noResults => _InboxContent(
          loading: false,
          rawReports: _reports,
          filteredReports: _filtered,
          hasActiveFilters: _hasActiveFilters,
          searchController: _searchController,
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) =>
              setState(() => _selectedCategory = category),
          onClearFilters: _clearFilters,
          onReportTap: widget.onReportTap,
        ),
        MunicipalInboxViewState.error => Padding(
          padding: MunicipalScaffold.contentPadding(context),
          child: MunicipalStateMessage(
            icon: AppIcons.warning,
            badgeColor: AppColors.error,
            title: 'Unable to load reports',
            message: 'Refresh the inbox or try again in a few minutes.',
            primaryActionLabel: 'Try again',
            onPrimaryAction: _retry,
            primaryActionColor: AppColors.error,
            bordered: true,
          ),
        ),
        MunicipalInboxViewState.offline => Padding(
          padding: MunicipalScaffold.contentPadding(context),
          child: MunicipalStateMessage(
            icon: AppIcons.offline,
            badgeColor: AppColors.error,
            title: 'You\'re offline',
            message:
                'Check your connection and retry loading incoming reports.',
            primaryActionLabel: 'Retry connection',
            onPrimaryAction: _retry,
            primaryActionColor: AppColors.error,
            bordered: true,
          ),
        ),
        MunicipalInboxViewState.permissionDenied => Padding(
          padding: MunicipalScaffold.contentPadding(context),
          child: MunicipalStateMessage(
            icon: AppIcons.permissionDenied,
            badgeColor: AppColors.primary,
            title: 'Access Restricted',
            message:
                'You do not have permission to view incoming reports for this '
                'municipality.',
            primaryActionLabel: 'Request Access',
            // No access-request workflow is specified in Issue 03 —
            // placeholder pending spec.
            onPrimaryAction: () {},
            secondaryActionLabel: 'Return to Dashboard',
            onSecondaryAction: widget.onNavigateToDashboard,
            bordered: true,
          ),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared shell for Loading / Loaded / Empty / No-Results
// ---------------------------------------------------------------------------

class _InboxContent extends StatelessWidget {
  const _InboxContent({
    required this.loading,
    this.rawReports = const [],
    this.filteredReports = const [],
    this.hasActiveFilters = false,
    this.searchController,
    this.selectedCategory,
    this.onCategorySelected,
    this.onClearFilters,
    this.onReportTap,
  });

  final bool loading;
  final List<IncomingReportItem> rawReports;
  final List<IncomingReportItem> filteredReports;
  final bool hasActiveFilters;
  final TextEditingController? searchController;
  final ReportCategory? selectedCategory;
  final ValueChanged<ReportCategory?>? onCategorySelected;
  final VoidCallback? onClearFilters;
  final ValueChanged<IncomingReportItem>? onReportTap;

  @override
  Widget build(BuildContext context) {
    final isNoResults =
        !loading && rawReports.isNotEmpty && filteredReports.isEmpty;
    final isEmpty = !loading && rawReports.isEmpty;
    final topChromeInset = MunicipalScaffold.contentPadding(context).top;

    return Column(
      children: [
        SizedBox(height: topChromeInset),
        Expanded(
          child: CollapsibleListHeader(
            header: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MunicipalSearchField(
                    controller: searchController,
                    hintText: 'Search incoming reports...',
                    enabled: !loading,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (isNoResults)
                    _ActiveFilterTags(
                      query: searchController?.text.trim() ?? '',
                      category: selectedCategory,
                      onCategoryCleared: () => onCategorySelected?.call(null),
                      onQueryCleared: () => searchController?.clear(),
                    )
                  else
                    _CategoryChips(
                      selected: selectedCategory,
                      onSelected: loading ? null : onCategorySelected,
                    ),
                ],
              ),
            ),
            child: loading
                ? const _ReportListSkeleton()
                : isEmpty
                ? const _InboxEmpty()
                : isNoResults
                ? _InboxNoResults(onClearFilters: onClearFilters)
                : _ReportList(
                    reports: filteredReports,
                    onReportTap: onReportTap,
                  ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final ReportCategory? selected;
  final ValueChanged<ReportCategory?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'All New',
            isSelected: selected == null,
            onTap: onSelected == null ? null : () => onSelected(null),
          ),
          for (final category in ReportCategory.values) ...[
            const SizedBox(width: AppSpacing.sm),
            _CategoryChip(
              label: category.label,
              isSelected: selected == category,
              onTap: onSelected == null ? null : () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: isSelected ? AppColors.primary : colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : colorScheme.outline,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Center(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterTags extends StatelessWidget {
  const _ActiveFilterTags({
    required this.query,
    required this.category,
    required this.onQueryCleared,
    required this.onCategoryCleared,
  });

  final String query;
  final ReportCategory? category;
  final VoidCallback onQueryCleared;
  final VoidCallback onCategoryCleared;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (query.isNotEmpty)
            _FilterTag(label: '"$query"', onCleared: onQueryCleared),
          if (category != null) ...[
            if (query.isNotEmpty) const SizedBox(width: AppSpacing.sm),
            _FilterTag(
              label: 'Category: ${category!.label}',
              onCleared: onCategoryCleared,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, required this.onCleared});

  final String label;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.statusAssigned.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.statusAssigned.withValues(alpha: 0.24),
        ),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.statusAssigned,
            ),
          ),
          InkWell(
            onTap: onCleared,
            child: Icon(
              AppIcons.close,
              size: AppIconSize.sm,
              color: AppColors.statusAssigned,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report list
// ---------------------------------------------------------------------------

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, this.onReportTap});

  final List<IncomingReportItem> reports;
  final ValueChanged<IncomingReportItem>? onReportTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Stays draggable even when the collapsed chrome lets a short (e.g.
      // filtered-down) list fit the viewport — see Resolved Reports for
      // the failure mode this prevents.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MunicipalScaffold.contentPadding(context).bottom,
      ),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _ReportCard(
        report: reports[index],
        onTap: onReportTap == null ? null : () => onReportTap!(reports[index]),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, this.onTap});

  final IncomingReportItem report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ReportSeverityBadge(severity: report.severity),
                    ReportStatusBadge(status: report.status),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(report.timeAgo, style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(report.title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.description,
            style: textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ReportAvatar(photoUrl: report.photoUrl),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                AppIcons.location,
                size: AppIconSize.sm,
                color: AppColors.primary,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  'View Location',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CategoryTag(category: report.category),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportAvatar extends StatelessWidget {
  const _ReportAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.surfaceContainer,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Icon(
              AppIcons.task,
              size: AppIconSize.sm,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});

  final ReportCategory category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _ReportListSkeleton extends StatelessWidget {
  const _ReportListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MunicipalScaffold.contentPadding(context).bottom,
      ),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, _) => _ReportCardSkeleton(),
    );
  }
}

class _ReportCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: AppComponentRadius.card,
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBlock(height: 14, widthFactor: 0.3),
            SizedBox(height: AppSpacing.md),
            _ShimmerBlock(height: 16, widthFactor: 0.6),
            SizedBox(height: AppSpacing.sm),
            _ShimmerBlock(height: 14, widthFactor: 0.95),
            SizedBox(height: AppSpacing.xs),
            _ShimmerBlock(height: 14, widthFactor: 0.7),
            SizedBox(height: AppSpacing.md),
            _ShimmerBlock(height: 14, widthFactor: 0.4),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / No-Results — keep the page shell, only the list area swaps
// ---------------------------------------------------------------------------

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: semantic.iconBadgeSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.inbox,
              size: AppIconSize.lg,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No incoming reports',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All reports have been processed for your district. Enjoy the calm.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InboxNoResults extends StatelessWidget {
  const _InboxNoResults({this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: semantic.iconBadgeSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.inbox,
              size: AppIconSize.lg,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No reports match your filters',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try adjusting your search terms or filters to find what '
            'you\'re looking for.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClearFilters,
              child: const Text('Clear all filters'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centers [child] when it fits the available height; scrolls instead of
/// overflowing when it doesn't (keyboard open, large accessibility text
/// scale, small/split-screen devices). Deliberately a plain
/// SingleChildScrollView + ConstrainedBox — not a Sliver-based approach,
/// which proved fragile when the surrounding content structurally changes
/// on every keystroke (see search-filtering flow).
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // This sits inside the Expanded area below the header, whose box
    // extends to the true screen bottom (behind the glass bottom nav, so
    // list content can scroll under it) — without accounting for that, the
    // illustration would visually center a bit low, biased toward the
    // hidden strip behind the nav.
    final bottomChromeInset = MunicipalScaffold.contentPadding(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final verticalPadding = AppSpacing.xl * 2 + bottomChromeInset;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl + bottomChromeInset,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - verticalPadding).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton primitive — matches MUN-001's, kept local since it isn't
// promoted to a shared widget location yet.
// ---------------------------------------------------------------------------

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height, this.widthFactor = 1.0});

  final double height;
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

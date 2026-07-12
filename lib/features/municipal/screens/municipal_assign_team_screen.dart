import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/team_data.dart';
import '../widgets/glass_card.dart';
import '../widgets/municipal_detail_header.dart';
import '../widgets/municipal_search_field.dart';
import '../widgets/municipal_state_message.dart';
import '../widgets/status_badge.dart';

/// MUN-005 — Assign Maintenance Team.
///
/// Approved states (Figma "05 - Assigned Team" section): Default, Loading,
/// Empty ("No Teams Available"), Success ("Team Assigned"), Error
/// ("Assignment Failed"), Offline, Permission, Disabled.
///
/// Unlike Report Review/Verification, this screen has a single failure
/// point (the assignment submission, not a separate report-load failure),
/// so the approved "Error" state maps to that submission failure here.
///
/// No bottom navigation — a drill-down detail screen reached from
/// Verification's "Assign Maintenance Team" action, not a tab destination.
enum MunicipalAssignTeamViewState {
  loading,
  loaded,
  empty,
  assigned,
  error,
  offline,
  permissionDenied,
  disabled,
}

class MunicipalAssignTeamScreen extends StatefulWidget {
  const MunicipalAssignTeamScreen({
    super.key,
    this.referenceId = 'REQ-8421',
    this.status = ReportStatus.underReview,
    this.initialState = MunicipalAssignTeamViewState.loaded,
    this.onBack,
    this.onNavigateToDashboard,
  });

  final String referenceId;
  final ReportStatus status;
  final MunicipalAssignTeamViewState initialState;

  /// Pops one level — wired to the header's back arrow, and to
  /// Permission's single "Back" action (see below).
  final VoidCallback? onBack;

  /// Returns all the way to the Dashboard tab. Used by Empty/Assigned/Error.
  /// Deliberately *not* used by Permission here: unlike Report
  /// Review/Verification's Permission state, the approved MUN-005 frame
  /// shows a single "Back" action rather than "Return to Dashboard" — this
  /// screen is reached mid-flow from Verification, so returning to the
  /// report it's about is more useful than jumping to Dashboard.
  final VoidCallback? onNavigateToDashboard;

  @override
  State<MunicipalAssignTeamScreen> createState() =>
      _MunicipalAssignTeamScreenState();
}

class _MunicipalAssignTeamScreenState extends State<MunicipalAssignTeamScreen> {
  late MunicipalAssignTeamViewState _state = widget.initialState;
  final AssignTeamData _data = AssignTeamData.mock();
  final _searchController = TextEditingController();
  TeamFilter _filter = TeamFilter.all;

  // Unit Alpha (first/best match) pre-selected, matching every approved
  // frame that shows a selection already made.
  late String? _selectedTeamName = _data.teams.first.name;

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

  /// Real filtering/sorting/search — unlike the static mockup, which shows
  /// all 4 teams unchanged regardless of which filter chip is "selected".
  List<MaintenanceTeam> get _visibleTeams {
    var teams = _data.teams.toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      teams = teams
          .where(
            (t) =>
                t.name.toLowerCase().contains(query) ||
                t.specialty.toLowerCase().contains(query),
          )
          .toList();
    }
    switch (_filter) {
      case TeamFilter.all:
        break;
      case TeamFilter.available:
        teams = teams
            .where((t) => t.availability == TeamAvailability.available)
            .toList();
      case TeamFilter.nearest:
        teams.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case TeamFilter.highestRated:
        teams.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return teams;
  }

  MaintenanceTeam? get _selectedTeam {
    for (final team in _data.teams) {
      if (team.name == _selectedTeamName) return team;
    }
    return null;
  }

  void _selectTeam(MaintenanceTeam team) {
    if (team.availability == TeamAvailability.offDuty) return;
    setState(() => _selectedTeamName = team.name);
  }

  void _submitAssign() {
    setState(() => _state = MunicipalAssignTeamViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalAssignTeamViewState.assigned);
      }
    });
  }

  void _retryLoad() {
    setState(() => _state = MunicipalAssignTeamViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalAssignTeamViewState.loaded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showActionBar =
        _state == MunicipalAssignTeamViewState.loaded ||
        _state == MunicipalAssignTeamViewState.offline ||
        _state == MunicipalAssignTeamViewState.disabled;
    final interactive = _state == MunicipalAssignTeamViewState.loaded;
    final selected = _selectedTeam;
    final canAssign =
        interactive &&
        selected != null &&
        selected.availability != TeamAvailability.offDuty;
    // widget.status is fixed at whatever it was when this screen opened, so
    // without this the header would keep showing the pre-assignment status
    // (e.g. "Under Review") even after a team's actually been assigned.
    final effectiveStatus = _state == MunicipalAssignTeamViewState.assigned
        ? ReportStatus.assigned
        : widget.status;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: MunicipalDetailHeader.topInset(context)),
                  if (_state == MunicipalAssignTeamViewState.offline)
                    const _OfflineBanner(),
                  Expanded(
                    child: switch (_state) {
                      MunicipalAssignTeamViewState.loading =>
                        const _LoadingSkeleton(),
                      MunicipalAssignTeamViewState.loaded => _AssignBody(
                        data: _data,
                        teams: _visibleTeams,
                        filter: _filter,
                        onFilterChanged: (filter) =>
                            setState(() => _filter = filter),
                        searchController: _searchController,
                        selected: selected,
                        onSelect: _selectTeam,
                        enabled: true,
                      ),
                      MunicipalAssignTeamViewState.offline => _AssignBody(
                        data: _data,
                        teams: _visibleTeams,
                        filter: _filter,
                        onFilterChanged: (filter) =>
                            setState(() => _filter = filter),
                        searchController: _searchController,
                        selected: selected,
                        onSelect: _selectTeam,
                        enabled: true,
                      ),
                      MunicipalAssignTeamViewState.disabled => _AssignBody(
                        data: _data,
                        teams: _visibleTeams,
                        filter: _filter,
                        onFilterChanged: null,
                        searchController: _searchController,
                        selected: selected,
                        onSelect: (_) {},
                        enabled: false,
                        disabledCaption:
                            'This report is no longer available for assignment.',
                      ),
                      MunicipalAssignTeamViewState.empty =>
                        MunicipalStateMessage(
                          icon: AppIcons.team,
                          title: 'No Teams Available',
                          message:
                              'There are no maintenance teams available in this '
                              'district right now.',
                          primaryActionLabel: 'Refresh',
                          onPrimaryAction: _retryLoad,
                          secondaryActionLabel: 'Return to Dashboard',
                          onSecondaryAction: widget.onNavigateToDashboard,
                        ),
                      MunicipalAssignTeamViewState.assigned =>
                        MunicipalStateMessage(
                          icon: AppIcons.success,
                          badgeColor: AppColors.success,
                          title: 'Team Assigned',
                          message: selected == null
                              ? 'The maintenance team has been notified and will '
                                    'begin work shortly.'
                              : '${selected.name} has been notified and will begin '
                                    'work shortly.',
                          primaryActionLabel: 'Return to Dashboard',
                          onPrimaryAction: widget.onNavigateToDashboard,
                        ),
                      MunicipalAssignTeamViewState.error => MunicipalStateMessage(
                        icon: AppIcons.warning,
                        badgeColor: AppColors.error,
                        primaryActionColor: AppColors.error,
                        title: 'Assignment Failed',
                        message:
                            'We couldn\'t assign this team. Check your connection '
                            'and try again.',
                        primaryActionLabel: 'Try again',
                        onPrimaryAction: _submitAssign,
                        secondaryActionLabel: 'Back to Report',
                        onSecondaryAction: () => setState(
                          () => _state = MunicipalAssignTeamViewState.loaded,
                        ),
                      ),
                      MunicipalAssignTeamViewState.permissionDenied =>
                        MunicipalStateMessage(
                          icon: AppIcons.permissionDenied,
                          badgeColor: AppColors.primary,
                          title: 'Access Restricted',
                          message:
                              'You do not have permission to assign maintenance '
                              'teams for this district.',
                          primaryActionLabel: 'Back',
                          onPrimaryAction: widget.onBack,
                        ),
                    },
                  ),
                  if (showActionBar)
                    _ActionBar(enabled: canAssign, onAssign: _submitAssign),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: 'Assign Team',
              referenceId: widget.referenceId,
              onBack: widget.onBack,
              trailing: ReportStatusBadge(status: effectiveStatus),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offline banner
// ---------------------------------------------------------------------------

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            AppIcons.offline,
            size: AppIconSize.sm,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No internet connection — changes will sync when you\'re '
              'back online',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (Default / Offline / Disabled share this — only `enabled` differs)
// ---------------------------------------------------------------------------

class _AssignBody extends StatelessWidget {
  const _AssignBody({
    required this.data,
    required this.teams,
    required this.filter,
    required this.onFilterChanged,
    required this.searchController,
    required this.selected,
    required this.onSelect,
    required this.enabled,
    this.disabledCaption,
  });

  final AssignTeamData data;
  final List<MaintenanceTeam> teams;
  final TeamFilter filter;
  final ValueChanged<TeamFilter>? onFilterChanged;
  final TextEditingController searchController;
  final MaintenanceTeam? selected;
  final ValueChanged<MaintenanceTeam> onSelect;
  final bool enabled;
  final String? disabledCaption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _ReportSummaryCard(data: data),
        const SizedBox(height: AppSpacing.md),
        if (disabledCaption != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: AppComponentRadius.inputField,
            ),
            child: Text(disabledCaption!, style: textTheme.bodySmall),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        MunicipalSearchField(
          controller: searchController,
          hintText: 'Search teams...',
          enabled: enabled,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: TeamFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final option = TeamFilter.values[index];
              return _FilterChip(
                label: option.label,
                selected: option == filter,
                onTap: enabled && onFilterChanged != null
                    ? () => onFilterChanged!(option)
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (teams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'No teams match your search.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final team in teams) ...[
            _TeamCard(
              team: team,
              selected: selected?.name == team.name,
              enabled: enabled && team.availability != TeamAvailability.offDuty,
              onTap: () => onSelect(team),
            ),
            if (team != teams.last) const SizedBox(height: AppSpacing.sm),
          ],
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.md),
          _AssignmentSummaryCard(team: selected!),
        ],
      ],
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.data});

  final AssignTeamData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(data.locationSummary, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _NeutralTag(label: data.category.label),
              ReportSeverityBadge(severity: data.severity, suffix: ' Priority'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeutralTag extends StatelessWidget {
  const _NeutralTag({required this.label});

  final String label;

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
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : colorScheme.outline,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? AppColors.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.availability});

  final TeamAvailability availability;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = availability.color ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        availability.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MaintenanceTeam team;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Opacity(
      opacity: enabled || selected ? 1 : 0.5,
      child: GlassCard(
        onTap: enabled ? onTap : null,
        border: Border.all(
          color: selected ? AppColors.primary : semantic.glassBorder,
          width: selected ? 2 : 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, style: textTheme.titleSmall),
                      Text(team.specialty, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                _AvailabilityBadge(availability: team.availability),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  AppIcons.team,
                  size: AppIconSize.sm,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${team.leadName} · ${team.memberCount} members',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.location,
                      size: AppIconSize.sm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${team.distanceKm.toStringAsFixed(1)} km away',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.eta,
                      size: AppIconSize.sm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA ${team.etaMinutes} min',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.rating,
                      size: AppIconSize.sm,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team.rating.toStringAsFixed(1),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentSummaryCard extends StatelessWidget {
  const _AssignmentSummaryCard({required this.team});

  final MaintenanceTeam team;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
        borderRadius: AppComponentRadius.card,
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.info,
            size: AppIconSize.md,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${team.name} will be dispatched to this location — '
              'estimated arrival in ${team.etaMinutes} min.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
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

    Widget block({double height = 96}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        block(height: 100),
        const SizedBox(height: AppSpacing.sm),
        block(height: 44),
        block(height: 112),
        block(height: 112),
        block(height: 112),
        block(height: 112),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.enabled, required this.onAssign});

  final bool enabled;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled ? onAssign : null,
          icon: const Icon(AppIcons.statusAssigned, size: AppIconSize.sm + 2),
          label: const Text('Assign Team'),
        ),
      ),
    );
  }
}

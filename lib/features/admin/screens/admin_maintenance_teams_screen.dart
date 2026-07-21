import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/glass_fab.dart';
import '../../../widgets/kebab_menu_button.dart';
import '../models/admin_maintenance_team_data.dart';
import '../models/admin_user_management_data.dart';
import '../services/admin_maintenance_team_directory.dart';
import '../services/admin_session.dart';
import '../services/admin_user_directory.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/region_assembly_picker.dart';

enum AdminMaintenanceTeamsViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class AdminMaintenanceTeamsScreen extends StatefulWidget {
  const AdminMaintenanceTeamsScreen({
    super.key,
    this.initialState = AdminMaintenanceTeamsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onCreateTeam,
    this.onOpenTeamDetails,
  });

  final AdminMaintenanceTeamsViewState initialState;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onOpenProfile;

  /// Opens Admin Notifications (System Activity) — wired to the header's
  /// bell icon.
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onCreateTeam;
  final ValueChanged<MaintenanceTeam>? onOpenTeamDetails;

  @override
  State<AdminMaintenanceTeamsScreen> createState() =>
      _AdminMaintenanceTeamsScreenState();
}

class _AdminMaintenanceTeamsScreenState
    extends State<AdminMaintenanceTeamsScreen> {
  late AdminMaintenanceTeamsViewState _state = widget.initialState;
  final _searchController = TextEditingController();
  String _query = '';
  Region? _region;
  Assembly? _assembly;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _state = AdminMaintenanceTeamsViewState.loading);
    Future.delayed(AppMotionDuration.moderate, () {
      if (mounted) {
        setState(() => _state = AdminMaintenanceTeamsViewState.loaded);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _region = null;
      _assembly = null;
      _state = AdminMaintenanceTeamsViewState.loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chromeEnabled =
        _state == AdminMaintenanceTeamsViewState.empty ||
        _state == AdminMaintenanceTeamsViewState.noResults;
    return AdminScaffold(
      selectedTab: AdminTab.maintenance,
      headerTitle: 'Maintenance Teams',
      onTabSelected: _handleTab,
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: () {},
      onOpenProfile: widget.onOpenProfile,
      onNotificationsTap: widget.onNotificationsTap,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(context, chromeEnabled)),
          if (widget.onCreateTeam != null &&
              _state != AdminMaintenanceTeamsViewState.unauthorized)
            Positioned(
              right: AppSpacing.md,
              bottom:
                  AdminScaffold.contentPadding(context).bottom + AppSpacing.md,
              child: GlassFab(
                tooltip: 'Create maintenance team',
                onPressed: widget.onCreateTeam,
                icon: AppIcons.add,
              ),
            ),
        ],
      ),
    );
  }

  void _handleTab(AdminTab tab) {
    if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
    if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
    if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
    if (tab == AdminTab.maintenance) return;
    if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
  }

  Widget _buildBody(BuildContext context, bool chromeEnabled) {
    return switch (_state) {
      AdminMaintenanceTeamsViewState.loading => const _LoadingSkeleton(),
      AdminMaintenanceTeamsViewState.loaded => GhanaRefreshIndicator(
        onRefresh: MaintenanceTeamDirectory.instance.refreshForAdmin,
        // The header paints on top of this content (a later sibling in
        // AdminScaffold's own Stack); _TeamListView's own top SizedBox
        // pushes its content down but doesn't move where
        // GhanaRefreshIndicator itself anchors its star/bar.
        topOffset: AdminScaffold.contentPadding(context).top,
        child: ValueListenableBuilder<List<MaintenanceTeam>>(
          valueListenable: MaintenanceTeamDirectory.instance.teams,
          builder: (context, teams, _) {
            return _TeamListView(
              teams: AdminSession.instance.visibleTeams(teams),
              query: _query,
              region: _region,
              assembly: _assembly,
              searchController: _searchController,
              onQueryChanged: (value) => setState(() => _query = value),
              onRegionChanged: (region) => setState(() {
                _region = region;
                _assembly = null;
              }),
              onAssemblyChanged: (assembly) =>
                  setState(() => _assembly = assembly),
              onClearFilters: _clearFilters,
              onOpenTeam: widget.onOpenTeamDetails,
            );
          },
        ),
      ),
      _ => Column(
        children: [
          SizedBox(height: AdminScaffold.contentPadding(context).top),
          _TeamsChrome(
            controller: _searchController,
            enabled: chromeEnabled,
            query: _query,
            region: _region,
            assembly: _assembly,
            onQueryChanged: chromeEnabled
                ? (value) => setState(() => _query = value)
                : null,
            onRegionChanged: chromeEnabled
                ? (region) => setState(() {
                    _region = region;
                    _assembly = null;
                  })
                : null,
            onAssemblyChanged: chromeEnabled
                ? (assembly) => setState(() => _assembly = assembly)
                : null,
          ),
          Expanded(
            child: _StateMessage(
              state: _state,
              onRetry: _retry,
              onClear: _clearFilters,
            ),
          ),
        ],
      ),
    };
  }
}

class AdminMaintenanceTeamFormScreen extends StatefulWidget {
  const AdminMaintenanceTeamFormScreen({
    super.key,
    this.team,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onClose,
  });

  final MaintenanceTeam? team;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onOpenProfile;

  /// Opens Admin Notifications (System Activity) — wired to the header's
  /// bell icon.
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onClose;

  @override
  State<AdminMaintenanceTeamFormScreen> createState() =>
      _AdminMaintenanceTeamFormScreenState();
}

class _AdminMaintenanceTeamFormScreenState
    extends State<AdminMaintenanceTeamFormScreen> {
  final _nameController = TextEditingController();
  final _memberSearchController = TextEditingController();
  late Region? _region = widget.team?.region ?? AdminSession.instance.region;
  late Assembly? _assembly =
      widget.team?.assembly ?? AdminSession.instance.assembly;
  late Set<String> _selectedMemberIds = {...?widget.team?.memberUserIds};
  late String? _leadUserId = widget.team?.leadUserId;
  String _memberQuery = '';
  String? _nameError;
  String? _assemblyError;
  bool _saving = false;

  bool get _editing => widget.team != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.team?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  bool get _dirty {
    final original = widget.team;
    if (original == null) {
      return _nameController.text.trim().isNotEmpty ||
          _assembly != null ||
          _selectedMemberIds.isNotEmpty;
    }
    return _nameController.text.trim() != original.name ||
        _assembly?.name != original.assembly.name ||
        _assembly?.region != original.assembly.region ||
        !_sameIds(_selectedMemberIds, original.memberUserIds);
  }

  Future<void> _cancel() async {
    if (_dirty) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Discard team changes?',
        message: 'The team details you entered will be lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    widget.onClose?.call();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Team name is required';
    if (_assembly == null) errors['assembly'] = 'Select an assembly';
    setState(() {
      _nameError = errors['name'];
      _assemblyError = errors['assembly'];
    });
    if (errors.isNotEmpty || _assembly == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: _editing ? 'Save changes?' : 'Create team?',
      message: _editing
          ? 'This will update ${widget.team!.name} and its member list.'
          : '$name will be created for ${_assembly!.fullName}.',
      confirmLabel: _editing ? 'Save Changes' : 'Create Team',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      if (_editing) {
        await MaintenanceTeamDirectory.instance.updateTeamOnServer(
          widget.team!.copyWith(
            name: name,
            assembly: _assembly,
            memberUserIds: _selectedMemberIds.toList(),
            leadUserId: _leadUserId,
          ),
        );
      } else {
        await MaintenanceTeamDirectory.instance.createTeamOnServer(
          name: name,
          assembly: _assembly!,
          memberUserIds: _selectedMemberIds.toList(),
          leadUserId: _leadUserId,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final session = AdminSession.instance;
    final locked = !session.isSuperAdmin;
    return AdminScaffold(
      selectedTab: AdminTab.maintenance,
      headerTitle: _editing ? 'Edit Team' : 'Create Team',
      onTabSelected: _handleTab,
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: widget.onClose,
      onOpenProfile: widget.onOpenProfile,
      onNotificationsTap: widget.onNotificationsTap,
      hideBottomNav: true,
      body: ValueListenableBuilder<List<MaintenanceTeam>>(
        valueListenable: MaintenanceTeamDirectory.instance.teams,
        builder: (context, teams, _) {
          final assignedElsewhere = <String>{
            for (final team in teams)
              if (team.teamId != widget.team?.teamId) ...team.memberUserIds,
          };
          return ValueListenableBuilder<List<AdminUserItem>>(
            valueListenable: AdminUserDirectory.instance.users,
            builder: (context, users, _) {
              final eligible = _assembly == null
                  ? const <AdminUserItem>[]
                  : session
                        .eligibleMaintenanceMembers(users, _assembly!)
                        .where(
                          (user) => !assignedElsewhere.contains(user.userId),
                        )
                        .where((user) => user.matchesSearch(_memberQuery))
                        .toList();
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AdminScaffold.contentPadding(context).top + AppSpacing.md,
                  AppSpacing.md,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                ),
                children: [
                  _Section(
                    icon: AppIcons.maintenanceTeam,
                    title: 'Team Details',
                    child: Column(
                      children: [
                        _TextField(
                          label: 'Team Name',
                          controller: _nameController,
                          errorText: _nameError,
                          onChanged: (_) => setState(() => _nameError = null),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (locked)
                          _ReadOnlyField(
                            label: 'Assembly',
                            value: session.assembly?.fullName ?? 'Not assigned',
                          )
                        else
                          RegionAssemblyPicker(
                            region: _region,
                            assembly: _assembly,
                            assemblyErrorText: _assemblyError,
                            onRegionChanged: (region) => setState(() {
                              _region = region;
                              _assembly = null;
                              _selectedMemberIds = {};
                              _assemblyError = null;
                            }),
                            onAssemblyChanged: (assembly) => setState(() {
                              _assembly = assembly;
                              _selectedMemberIds = {};
                              _assemblyError = null;
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    icon: AppIcons.team,
                    title: 'Members',
                    child: _MemberPicker(
                      controller: _memberSearchController,
                      users: eligible,
                      selectedIds: _selectedMemberIds,
                      leadUserId: _leadUserId,
                      queryEnabled: _assembly != null,
                      onQueryChanged: (value) =>
                          setState(() => _memberQuery = value),
                      onToggle: (user) => setState(() {
                        if (_selectedMemberIds.contains(user.userId)) {
                          _selectedMemberIds.remove(user.userId);
                          if (_leadUserId == user.userId) {
                            // First remaining member (Set is insertion-
                            // ordered) inherits the lead — a team a lead
                            // just left shouldn't silently have none.
                            _leadUserId = _selectedMemberIds.isEmpty
                                ? null
                                : _selectedMemberIds.first;
                          }
                        } else {
                          _selectedMemberIds.add(user.userId);
                          // First person ticked becomes lead by default;
                          // reassign explicitly via the crown button.
                          _leadUserId ??= user.userId;
                        }
                      }),
                      onSetLead: (user) =>
                          setState(() => _leadUserId = user.userId),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _cancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: AppIconSize.sm,
                                  height: AppIconSize.sm,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_editing ? 'Save Changes' : 'Create Team'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleTab(AdminTab tab) {
    if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
    if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
    if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
    if (tab == AdminTab.maintenance) widget.onClose?.call();
    if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
  }
}

class AdminMaintenanceTeamDetailsScreen extends StatelessWidget {
  const AdminMaintenanceTeamDetailsScreen({
    super.key,
    required this.team,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onBackToTeams,
    this.onEditTeam,
    this.onOpenUserDetails,
  });

  final MaintenanceTeam team;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onOpenProfile;

  /// Opens Admin Notifications (System Activity) — wired to the header's
  /// bell icon.
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onBackToTeams;
  final ValueChanged<MaintenanceTeam>? onEditTeam;
  final ValueChanged<AdminUserItem>? onOpenUserDetails;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MaintenanceTeam>>(
      valueListenable: MaintenanceTeamDirectory.instance.teams,
      builder: (context, teams, _) {
        final current = MaintenanceTeamDirectory.instance.teamById(team.teamId);
        if (current == null) {
          return _MissingTeamScreen(
            onBackToTeams: onBackToTeams,
            onNavigateToDashboard: onNavigateToDashboard,
            onNavigateToUsers: onNavigateToUsers,
            onNavigateToRoles: onNavigateToRoles,
            onNavigateToSettings: onNavigateToSettings,
            onNavigateToActivity: onNavigateToActivity,
            onOpenProfile: onOpenProfile,
            onNotificationsTap: onNotificationsTap,
          );
        }
        return _TeamDetailsBody(
          team: current,
          onNavigateToDashboard: onNavigateToDashboard,
          onNavigateToUsers: onNavigateToUsers,
          onNavigateToRoles: onNavigateToRoles,
          onNavigateToSettings: onNavigateToSettings,
          onNavigateToActivity: onNavigateToActivity,
          onOpenProfile: onOpenProfile,
          onNotificationsTap: onNotificationsTap,
          onBackToTeams: onBackToTeams,
          onEditTeam: onEditTeam,
          onOpenUserDetails: onOpenUserDetails,
        );
      },
    );
  }
}

class _TeamListView extends StatelessWidget {
  const _TeamListView({
    required this.teams,
    required this.query,
    required this.region,
    required this.assembly,
    required this.searchController,
    required this.onQueryChanged,
    required this.onRegionChanged,
    required this.onAssemblyChanged,
    required this.onClearFilters,
    this.onOpenTeam,
  });

  final List<MaintenanceTeam> teams;
  final String query;
  final Region? region;
  final Assembly? assembly;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Region?> onRegionChanged;
  final ValueChanged<Assembly?> onAssemblyChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<MaintenanceTeam>? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final filtered = [
      for (final team in teams)
        if (team.matchesSearch(query) &&
            (region == null || team.region == region) &&
            (assembly == null ||
                (team.assembly.name == assembly!.name &&
                    team.assembly.region == assembly!.region)))
          team,
    ];
    final bottomInset = AdminScaffold.contentPadding(context).bottom;
    return Column(
      children: [
        SizedBox(height: AdminScaffold.contentPadding(context).top),
        _TeamsChrome(
          controller: searchController,
          enabled: true,
          query: query,
          region: region,
          assembly: assembly,
          onQueryChanged: onQueryChanged,
          onRegionChanged: onRegionChanged,
          onAssemblyChanged: onAssemblyChanged,
        ),
        Expanded(
          child: ListView(
            // Stays draggable even when a short/filtered list fits the
            // viewport — otherwise pull-to-refresh silently wouldn't
            // trigger.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              bottomInset + AppSpacing.xl,
            ),
            children: [
              if (teams.isEmpty)
                const _NoTeamsInScopeHint()
              else if (filtered.isEmpty)
                _InlineEmptyHint(onClear: onClearFilters)
              else
                for (final team in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TeamCard(
                      team: team,
                      onTap: onOpenTeam == null
                          ? null
                          : () => onOpenTeam!(team),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamsChrome extends StatelessWidget {
  const _TeamsChrome({
    required this.controller,
    required this.enabled,
    required this.query,
    required this.region,
    required this.assembly,
    this.onQueryChanged,
    this.onRegionChanged,
    this.onAssemblyChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String query;
  final Region? region;
  final Assembly? assembly;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<Region?>? onRegionChanged;
  final ValueChanged<Assembly?>? onAssemblyChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create, edit, and assign maintenance crews by assembly.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onQueryChanged,
            // Glass — see MunicipalSearchField's doc comment.
            decoration: InputDecoration(
              hintText: 'Search teams',
              prefixIcon: const Icon(AppIcons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: enabled
                          ? () {
                              controller.clear();
                              onQueryChanged?.call('');
                            }
                          : null,
                    ),
              filled: true,
              fillColor: semantic.glassSurface,
            ),
          ),
          if (AdminSession.instance.isSuperAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
            RegionAssemblyPicker(
              region: region,
              assembly: assembly,
              onRegionChanged: onRegionChanged ?? (_) {},
              onAssemblyChanged: onAssemblyChanged ?? (_) {},
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, this.onTap});

  final MaintenanceTeam team;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: AppIconSize.lg / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(
              AppIcons.maintenanceTeam,
              size: AppIconSize.md,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                _IconLine(
                  icon: AppIcons.municipality,
                  label: team.assembly.fullName,
                ),
                const SizedBox(height: AppSpacing.xs),
                _IconLine(
                  icon: AppIcons.team,
                  label:
                      '${team.memberUserIds.length} member${team.memberUserIds.length == 1 ? '' : 's'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamDetailsBody extends StatelessWidget {
  const _TeamDetailsBody({
    required this.team,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onBackToTeams,
    this.onEditTeam,
    this.onOpenUserDetails,
  });

  final MaintenanceTeam team;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onBackToTeams;
  final ValueChanged<MaintenanceTeam>? onEditTeam;
  final ValueChanged<AdminUserItem>? onOpenUserDetails;

  @override
  Widget build(BuildContext context) {
    final users = AdminUserDirectory.instance.users.value;
    final members = [
      for (final memberId in team.memberUserIds)
        for (final user in users)
          if (user.userId == memberId) user,
    ];
    return AdminScaffold(
      selectedTab: AdminTab.maintenance,
      headerTitle: 'Team Details',
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) onNavigateToDashboard?.call();
        if (tab == AdminTab.users) onNavigateToUsers?.call();
        if (tab == AdminTab.activity) onNavigateToActivity?.call();
        if (tab == AdminTab.maintenance) onBackToTeams?.call();
        if (tab == AdminTab.settings) onNavigateToSettings?.call();
      },
      onOpenRoleManagement: onNavigateToRoles,
      onOpenMaintenanceTeams: onBackToTeams,
      onOpenProfile: onOpenProfile,
      onNotificationsTap: onNotificationsTap,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AdminScaffold.contentPadding(context).top + AppSpacing.md,
          AppSpacing.md,
          AdminScaffold.contentPadding(context).bottom + AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBackToTeams,
                icon: const Icon(AppIcons.back),
                tooltip: 'Back to maintenance teams',
              ),
              const Spacer(),
              KebabMenuButton<String>(
                tooltip: 'Team actions',
                onSelected: (action) async {
                  if (action == 'edit') onEditTeam?.call(team);
                  if (action == 'delete') {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete team?',
                      message:
                          '${team.name} will be removed from maintenance team management.',
                      confirmLabel: 'Delete',
                      destructive: true,
                    );
                    if (!confirmed || !context.mounted) return;
                    try {
                      await MaintenanceTeamDirectory.instance
                          .deleteTeamOnServer(team);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                      return;
                    }
                    onBackToTeams?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Team')),
                  PopupMenuItem(value: 'delete', child: Text('Delete Team')),
                ],
              ),
            ],
          ),
          _Section(
            icon: AppIcons.maintenanceTeam,
            title: team.name,
            child: Column(
              children: [
                _ReadOnlyField(label: 'Team ID', value: team.teamId),
                const SizedBox(height: AppSpacing.sm),
                _ReadOnlyField(
                  label: 'Assembly',
                  value: team.assembly.fullName,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ReadOnlyField(label: 'Region', value: team.region.label),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            icon: AppIcons.team,
            title: 'Members',
            child: members.isEmpty
                ? Text(
                    'No maintenance staff have been added to this team yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                : Column(
                    children: [
                      for (final member in members) ...[
                        _MemberRow(
                          user: member,
                          isLead: member.userId == team.leadUserId,
                          onTap: onOpenUserDetails == null
                              ? null
                              : () => onOpenUserDetails!(member),
                          onRemove: () => _removeMember(context, member),
                        ),
                        if (member != members.last)
                          const Divider(height: AppSpacing.lg),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, AdminUserItem member) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove member?',
      message: 'Remove ${member.name} from ${team.name}?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    final updated = team.copyWith(
      memberUserIds: team.memberUserIds
          .where((id) => id != member.userId)
          .toList(),
      leadUserId: team.leadUserId == member.userId ? null : team.leadUserId,
    );
    try {
      await MaintenanceTeamDirectory.instance.updateTeamOnServer(updated);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _MemberPicker extends StatelessWidget {
  const _MemberPicker({
    required this.controller,
    required this.users,
    required this.selectedIds,
    required this.leadUserId,
    required this.queryEnabled,
    required this.onQueryChanged,
    required this.onToggle,
    required this.onSetLead,
  });

  final TextEditingController controller;
  final List<AdminUserItem> users;
  final Set<String> selectedIds;

  /// The current team lead, if any — only meaningful for a row that's also
  /// in [selectedIds]; the crown affordance is hidden for anyone not yet a
  /// member.
  final String? leadUserId;
  final bool queryEnabled;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AdminUserItem> onToggle;

  /// Explicitly reassigns the lead to this member — the escape hatch for
  /// when the default (first person ticked) isn't who should lead.
  final ValueChanged<AdminUserItem> onSetLead;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Column(
      children: [
        TextField(
          controller: controller,
          enabled: queryEnabled,
          onChanged: onQueryChanged,
          // Glass — see MunicipalSearchField's doc comment.
          decoration: InputDecoration(
            filled: true,
            fillColor: semantic.glassSurface,
            hintText: 'Search maintenance staff',
            prefixIcon: const Icon(AppIcons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!queryEnabled)
          Text(
            'Select an assembly before adding members.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else if (users.isEmpty)
          Text(
            'No available maintenance staff match this assembly and search. '
            'Workers already assigned to another team must be removed first.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          // CheckboxListTile paints its own background/ink on the nearest
          // Material ancestor — without this, that lands on _Section's own
          // colored Container instead and gets silently clipped/hidden.
          Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (final user in users)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selectedIds.contains(user.userId),
                    onChanged: (_) => onToggle(user),
                    title: Text(user.name),
                    subtitle: Text(user.phone),
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: selectedIds.contains(user.userId)
                        ? _LeadButton(
                            isLead: user.userId == leadUserId,
                            onTap: () => onSetLead(user),
                          )
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Crown toggle marking (or reassigning) a selected member as team lead —
/// only ever shown next to a member already on the team.
class _LeadButton extends StatelessWidget {
  const _LeadButton({required this.isLead, required this.onTap});

  final bool isLead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: isLead ? 'Team lead' : 'Make team lead',
      icon: Icon(
        AppIcons.teamLead,
        color: isLead ? AppColors.warning : colorScheme.onSurfaceVariant,
      ),
      onPressed: onTap,
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.user,
    this.onTap,
    required this.onRemove,
    this.isLead = false,
  });

  final AdminUserItem user;
  final VoidCallback? onTap;
  final VoidCallback onRemove;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppIconSize.md / 2,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                user.initials,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLead) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          AppIcons.teamLead,
                          size: AppIconSize.sm,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    user.phone,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            KebabMenuButton<String>(
              iconColor: colorScheme.onSurfaceVariant,
              onSelected: (action) {
                if (action == 'remove') onRemove();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'remove', child: Text('Remove from team')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.state,
    required this.onRetry,
    required this.onClear,
  });

  final AdminMaintenanceTeamsViewState state;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: switch (state) {
        AdminMaintenanceTeamsViewState.empty => AppStateMessage(
          icon: AppIcons.maintenanceTeam,
          badgeColor: AppColors.primary,
          title: 'No Teams',
          message: 'Maintenance teams will appear here once created.',
          primaryActionLabel: 'Refresh',
          onPrimaryAction: onRetry,
        ),
        AdminMaintenanceTeamsViewState.noResults => AppStateMessage(
          icon: AppIcons.noFilterMatch,
          badgeColor: AppColors.primary,
          title: 'No Results',
          message: 'No maintenance teams match the current filters.',
          primaryActionLabel: 'Clear Filters',
          onPrimaryAction: onClear,
        ),
        AdminMaintenanceTeamsViewState.offline => AppStateMessage(
          icon: AppIcons.offline,
          badgeColor: AppColors.error,
          title: 'You\'re offline',
          message: 'Check your connection and retry loading teams.',
          primaryActionLabel: 'Retry connection',
          onPrimaryAction: onRetry,
          primaryActionColor: AppColors.error,
        ),
        AdminMaintenanceTeamsViewState.error => AppStateMessage(
          icon: AppIcons.warning,
          badgeColor: AppColors.error,
          title: 'Unable to Load Teams',
          message: 'Maintenance team records could not load right now.',
          primaryActionLabel: 'Retry',
          onPrimaryAction: onRetry,
          primaryActionColor: AppColors.error,
        ),
        AdminMaintenanceTeamsViewState.unauthorized => const AppStateMessage(
          icon: AppIcons.permissionDenied,
          badgeColor: AppColors.error,
          title: 'Unauthorized Access',
          message: 'Admin privileges are required to manage maintenance teams.',
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _NoTeamsInScopeHint extends StatelessWidget {
  const _NoTeamsInScopeHint();

  @override
  Widget build(BuildContext context) {
    final session = AdminSession.instance;
    final scopeLabel = session.isSuperAdmin
        ? 'the system'
        : session.assembly?.fullName ?? 'your assembly';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            AppIcons.maintenanceTeam,
            size: AppIconSize.lg,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No maintenance teams in $scopeLabel yet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use the + button to create the first team.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyHint extends StatelessWidget {
  const _InlineEmptyHint({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            AppIcons.noFilterMatch,
            size: AppIconSize.lg,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No teams match your search or filter.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _MissingTeamScreen extends StatelessWidget {
  const _MissingTeamScreen({
    this.onBackToTeams,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
  });

  final VoidCallback? onBackToTeams;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.maintenance,
      headerTitle: 'Team Details',
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) onNavigateToDashboard?.call();
        if (tab == AdminTab.users) onNavigateToUsers?.call();
        if (tab == AdminTab.activity) onNavigateToActivity?.call();
        if (tab == AdminTab.maintenance) onBackToTeams?.call();
        if (tab == AdminTab.settings) onNavigateToSettings?.call();
      },
      onOpenRoleManagement: onNavigateToRoles,
      onOpenMaintenanceTeams: onBackToTeams,
      onOpenProfile: onOpenProfile,
      onNotificationsTap: onNotificationsTap,
      body: Padding(
        padding: AdminScaffold.contentPadding(context),
        child: AppStateMessage(
          icon: AppIcons.warning,
          badgeColor: AppColors.error,
          title: 'Team not found',
          message: 'This maintenance team may have been deleted.',
          primaryActionLabel: 'Back to Teams',
          onPrimaryAction: onBackToTeams,
          primaryActionColor: AppColors.error,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: AppIconSize.sm, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AdminScaffold.contentPadding(context).top + AppSpacing.md,
        AppSpacing.md,
        AdminScaffold.contentPadding(context).bottom + AppSpacing.xl,
      ),
      children: const [
        _SkeletonBlock(),
        SizedBox(height: AppSpacing.sm),
        _SkeletonBlock(),
        SizedBox(height: AppSpacing.sm),
        _SkeletonBlock(),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.xxxxl,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: AppComponentRadius.card,
      ),
    );
  }
}

bool _sameIds(Set<String> left, List<String> right) {
  final rightSet = right.toSet();
  return left.length == rightSet.length && left.containsAll(rightSet);
}

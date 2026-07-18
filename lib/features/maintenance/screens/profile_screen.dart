import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../models/team_availability.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_edit_action_bar.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/theme_preference_row.dart';
import '../../admin/models/admin_maintenance_team_data.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../../admin/services/admin_user_directory.dart';
import '../services/maintenance_task_directory.dart';
import '../widgets/maintenance_scaffold.dart';

/// MNT-007 — Maintenance Profile.
///
/// Reads the same real Admin-provisioned account
/// ([MaintenanceTaskDirectory.currentUserId], Yaw Asare) that Dashboard's
/// greeting and every task's team lookup already use, rather than an
/// unrelated made-up "Marcus Johnson" with no backing account, no real
/// assembly, and no real team membership to show here.
///
/// View/Edit is a real toggle now (matching Ministry/Municipal's own
/// profile screens) rather than an always-open Full Name field sitting next
/// to an always-visible "Save Changes" button with nothing to actually
/// enter edit mode through. Edit-mode entry is the "Personal Information"
/// section's own pencil icon — this screen is tab-embedded (a bottom nav
/// tab, not a drill-down), so it keeps that entry gesture rather than
/// Municipal/Ministry's kebab menu, matching Admin Profile's identical
/// tab-embedded shape.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTasks,
    this.onNotificationsTap,
    this.onChangePassword,
    this.onLogOut,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTasks;

  /// Opens Maintenance Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;

  /// Fired after the log-out confirmation dialog is accepted. Nullable:
  /// there's no real authentication flow to sign out of yet.
  final VoidCallback? onLogOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppScreenState _state = AppScreenState.success;

  late final _account = AdminUserDirectory.instance.userById(
    MaintenanceTaskDirectory.currentUserId,
  )!;
  late final _nameController = TextEditingController(text: _account.name);

  // Always locked (see [_PersonalInfoForm]'s own doc comment) — still real,
  // disposed controllers rather than ad-hoc ones rebuilt (and leaked) on
  // every frame, matching Ministry's identical treatment of its own
  // locked Email/Phone fields.
  late final _emailController = TextEditingController(text: _account.email);
  late final _phoneController = TextEditingController(text: _account.phone);

  bool _isEditing = false;
  String? _nameError;
  bool _changesSaved = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _changesSaved = false;
      _nameError = null;
    });
  }

  void _cancelEditing() {
    _nameController.text = _account.name;
    setState(() {
      _isEditing = false;
      _nameError = null;
    });
  }

  void _changeAvailability(MaintenanceTeam team, TeamAvailability value) {
    MaintenanceTeamDirectory.instance.updateTeam(
      team.copyWith(availability: value),
    );
    setState(() {});
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Full name is required.');
      return;
    }
    setState(() {
      _nameError = null;
      _isEditing = false;
      _changesSaved = true;
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message:
          "You'll need to sign back in to access the maintenance console.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onLogOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceScaffold(
      selectedTab: MaintenanceTab.profile,
      onNotificationsTap: widget.onNotificationsTap,
      hideBottomNav: _isEditing,
      onTabSelected: (tab) {
        if (tab == MaintenanceTab.dashboard) {
          widget.onNavigateToDashboard?.call();
        }
        if (tab == MaintenanceTab.tasks) widget.onNavigateToTasks?.call();
      },
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.error:
        return _ErrorView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.offline:
        return _OfflineView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.permission:
        return _PermissionView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.disabled:
        return _buildForm(context, disabled: true);
      case AppScreenState.success:
        return _buildForm(context);
    }
  }

  Widget _buildForm(BuildContext context, {bool disabled = false}) {
    MaintenanceTeam? team;
    for (final candidate in MaintenanceTeamDirectory.instance.teams.value) {
      if (candidate.memberUserIds.contains(_account.userId)) {
        team = candidate;
        break;
      }
    }

    final isTeamLead = team != null && team.leadUserId == _account.userId;
    return _ProfileForm(
      disabled: disabled,
      editing: _isEditing,
      nameController: _nameController,
      emailController: _emailController,
      phoneController: _phoneController,
      employeeId: _account.userId,
      district: _account.assembly?.fullName ?? 'Unassigned',
      teamName: team?.name ?? 'Not yet assigned to a team',
      isTeamLead: isTeamLead,
      availability: team?.availability,
      onAvailabilityChanged: disabled || !isTeamLead
          ? null
          : (value) => _changeAvailability(team!, value),
      nameError: _nameError,
      changesSaved: _changesSaved,
      onFieldChanged: disabled
          ? null
          : (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
      onEdit: disabled ? null : _startEditing,
      onSave: disabled ? null : _handleSave,
      onCancel: disabled ? null : _cancelEditing,
      onChangePassword: disabled ? null : widget.onChangePassword,
      onLogOut: disabled ? null : _confirmLogOut,
    );
  }
}

/// Email and Phone are always locked — an admin-provisioned account's
/// contact credentials are set by whoever provisioned it, not
/// self-editable (changing either means a real identity change: a
/// different sign-in email, a different verified number). Full Name is the
/// only field a maintenance technician can change here, and only once
/// [editing] is entered via the section's own Edit button.
class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.disabled,
    required this.editing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.employeeId,
    required this.district,
    required this.teamName,
    required this.isTeamLead,
    required this.availability,
    required this.onAvailabilityChanged,
    required this.nameError,
    required this.changesSaved,
    required this.onFieldChanged,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onChangePassword,
    required this.onLogOut,
  });

  final bool disabled;
  final bool editing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String employeeId;
  final String district;
  final String teamName;
  final bool isTeamLead;

  /// Null when the technician isn't on a team yet — no status to show.
  final TeamAvailability? availability;

  /// Null unless [isTeamLead] — only the lead sets their team's status.
  final ValueChanged<TeamAvailability>? onAvailabilityChanged;
  final String? nameError;
  final bool changesSaved;
  final ValueChanged<String>? onFieldChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final chromeInset = MaintenanceScaffold.contentPadding(context);

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  chromeInset.top + AppSpacing.md,
                  AppSpacing.md,
                  editing
                      ? AppSpacing.md
                      : chromeInset.bottom + AppSpacing.xl,
                ),
                children: [
                  Text('My Profile', style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Manage professional credentials',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (changesSaved) ...[
                    _SavedBanner(semantic: semantic),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ProfileHeaderCard(
                    name: nameController.text,
                    pills: [
                      _Pill(
                        label: isTeamLead
                            ? 'Maintenance Technician · Team Lead'
                            : 'Maintenance Technician',
                      ),
                    ],
                    editing: editing,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileSection(
                    icon: AppIcons.idCard,
                    title: 'Account Information',
                    children: [
                      const ProfileFieldRow(
                        label: 'Department',
                        value: 'Maintenance',
                        locked: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ProfileFieldRow(
                        label: 'Assembly',
                        value: district,
                        locked: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ProfileFieldRow(
                        label: 'Team',
                        value: teamName,
                        locked: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ProfileFieldRow(
                        label: 'Employee ID',
                        value: employeeId,
                        locked: true,
                      ),
                    ],
                  ),
                  if (availability != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _TeamStatusRow(
                      availability: availability!,
                      // Only the team lead sets this — everyone else on the
                      // team sees it read-only, matching the "lead does the
                      // one high-impact team action" rule already used for
                      // evidence submission.
                      onChanged: onAvailabilityChanged,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ProfileSection(
                    icon: AppIcons.profile,
                    title: 'Personal Information',
                    trailing: editing
                        ? null
                        : IconButton(
                            onPressed: onEdit,
                            icon: const Icon(
                              AppIcons.edit,
                              size: AppIconSize.sm,
                            ),
                            tooltip: 'Edit',
                          ),
                    children: [
                      ProfileFieldRow(
                        label: 'Full Name',
                        controller: nameController,
                        editable: editing,
                        onChanged: onFieldChanged,
                        errorText: nameError,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ProfileFieldRow(
                        label: 'Email',
                        controller: emailController,
                        caption: editing
                            ? 'Contact your administrator to change this'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ProfileFieldRow(
                        label: 'Phone',
                        controller: phoneController,
                        caption: editing
                            ? 'Contact your administrator to change this'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileSection(
                    icon: AppIcons.shield,
                    title: 'Security',
                    children: [
                      ProfileActionRow(
                        icon: AppIcons.password,
                        label: 'Change Password',
                        onTap: onChangePassword,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onLogOut,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text('Log Out'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileSection(
                    icon: AppIcons.systemTheme,
                    title: 'System Preferences',
                    children: const [
                      ThemePreferenceRow(),
                      Divider(height: AppSpacing.lg),
                      LanguagePreferenceRow(),
                    ],
                  ),
                ],
              ),
            ),
            // A sticky bar, not the last item in the scrollable list — on a
            // screen this long, a Save button that only appears after
            // scrolling all the way down is easy to miss entirely.
            if (editing)
              ProfileEditActionBar(onCancel: onCancel, onSave: onSave),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.semantic});
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.success.withValues(alpha: 0.08),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: semantic.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.success, color: semantic.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Changes saved',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: semantic.success),
                ),
                Text(
                  'Permitted profile fields were updated.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The team's own self-reported work status — read-only for a regular
/// member, a real tap-to-change control for the lead (see
/// [MaintenanceTeamDirectory.updateTeam] at the call site). This is what
/// Municipal's Assign Team actually reads now, so changing it here is a
/// real action, not a cosmetic toggle.
class _TeamStatusRow extends StatelessWidget {
  const _TeamStatusRow({required this.availability, this.onChanged});

  final TeamAvailability availability;
  final ValueChanged<TeamAvailability>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            AppIcons.activityPulse,
            size: AppIconSize.md,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              onChanged == null ? 'Team Status' : 'Team Status (you set this)',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onChanged == null)
            TintedBadge(
              label: availability.label,
              color: availability.color ?? colorScheme.onSurfaceVariant,
              textColor: availability.color ?? colorScheme.onSurfaceVariant,
            )
          else
            for (final option in TeamAvailability.values) ...[
              _AvailabilityChip(
                option: option,
                selected: option == availability,
                onTap: () => onChanged!(option),
              ),
              if (option != TeamAvailability.values.last)
                const SizedBox(width: AppSpacing.xs),
            ],
        ],
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TeamAvailability option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = option.color ?? colorScheme.onSurfaceVariant;
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? color : colorScheme.outline),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Text(
            option.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? color : colorScheme.onSurfaceVariant,
              fontWeight: selected ? AppFontWeight.semiBold : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading profile',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Retrieving maintenance staff information.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.profile,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No profile data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Staff profile information is not available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: AppIconSize.xl, color: semantic.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try again without exposing administrator-only information.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.error),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.offline,
              size: AppIconSize.xl,
              color: semantic.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reconnect to save profile changes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.warning),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.permissionDenied,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Permission required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maintenance profile access is required.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

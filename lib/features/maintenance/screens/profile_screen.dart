import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/glass_card.dart';
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
/// enter edit mode through.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTasks,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTasks;

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

  @override
  Widget build(BuildContext context) {
    return MaintenanceScaffold(
      selectedTab: MaintenanceTab.profile,
      onNotificationsTap: () {},
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

    return _ProfileForm(
      disabled: disabled,
      editing: _isEditing,
      nameController: _nameController,
      emailController: _emailController,
      phoneController: _phoneController,
      employeeId: _account.userId,
      district: _account.assembly?.fullName ?? 'Unassigned',
      teamName: team?.name ?? 'Not yet assigned to a team',
      isTeamLead: team != null && team.leadUserId == _account.userId,
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
    required this.nameError,
    required this.changesSaved,
    required this.onFieldChanged,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
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
  final String? nameError;
  final bool changesSaved;
  final ValueChanged<String>? onFieldChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            chromeInset.top + AppSpacing.md,
            AppSpacing.md,
            chromeInset.bottom + AppSpacing.xl,
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
            _ProfileHeaderBlock(
              name: nameController.text,
              isTeamLead: isTeamLead,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: AppIcons.maintenanceTeam,
                    label: 'Department',
                    value: 'Maintenance',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoTile(
                    icon: AppIcons.location,
                    label: 'Assembly',
                    value: district,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: AppIcons.team,
                    label: 'Team',
                    value: teamName,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoTile(
                    icon: AppIcons.idCard,
                    label: 'Employee ID',
                    value: employeeId,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Personal Information',
                    style: textTheme.titleMedium,
                  ),
                ),
                if (!editing)
                  SizedBox(
                    width: AppDimensions.controlHeightStandard,
                    height: AppDimensions.controlHeightStandard,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onEdit,
                        child: Icon(
                          AppIcons.edit,
                          size: AppIconSize.sm,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            editing
                ? _PersonalInfoForm(
                    nameController: nameController,
                    emailController: emailController,
                    phoneController: phoneController,
                    nameError: nameError,
                    onFieldChanged: onFieldChanged,
                  )
                : _PersonalInfoDisplay(
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                  ),
            if (editing) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onSave,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Matches Ministry/Municipal's own profile header shape — an initials
/// avatar (not a generic profile-icon glyph) and a tinted role pill under
/// the name, the same pattern those two modules already use rather than a
/// one-off treatment invented just for this screen.
class _ProfileHeaderBlock extends StatelessWidget {
  const _ProfileHeaderBlock({required this.name, required this.isTeamLead});

  final String name;
  final bool isTeamLead;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty ? '' : part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initials,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.allXl,
            ),
            child: Text(
              isTeamLead
                  ? 'Maintenance Technician · Team Lead'
                  : 'Maintenance Technician',
              style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only display of Name/Email/Phone — the default state, tapping the
/// section's Edit button (not this card) is how a technician gets into
/// [_PersonalInfoForm] instead. A plain opaque surface, not [GlassCard] —
/// matches Ministry's own `_PersonalInfoDisplay`: glass is prohibited on
/// input-heavy sections (§19.10), and this becomes one once editing.
class _PersonalInfoDisplay extends StatelessWidget {
  const _PersonalInfoDisplay({
    required this.name,
    required this.email,
    required this.phone,
  });

  final String name;
  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadOnlyField(label: 'Full Name', value: name),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyField(label: 'Email', value: email),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyField(label: 'Phone', value: phone),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
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
            style: textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PersonalInfoForm extends StatelessWidget {
  const _PersonalInfoForm({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.nameError,
    required this.onFieldChanged,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String? nameError;
  final ValueChanged<String>? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditableField(
            label: 'Full Name',
            controller: nameController,
            onChanged: onFieldChanged,
            errorText: nameError,
          ),
          const SizedBox(height: AppSpacing.md),
          _EditableField(
            label: 'Email',
            controller: emailController,
            enabled: false,
            caption: 'Contact your administrator to change this',
          ),
          const SizedBox(height: AppSpacing.md),
          _EditableField(
            label: 'Phone',
            controller: phoneController,
            enabled: false,
            caption: 'Contact your administrator to change this',
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.caption,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  /// False locks the field read-only — used for Email/Phone, which are
  /// admin-set rather than self-editable (see [_PersonalInfoForm]'s own
  /// doc comment).
  final bool enabled;

  /// Shown under a locked field to explain why it's disabled.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: colorScheme.surfaceContainer,
          borderRadius: AppComponentRadius.inputField,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            enabled: enabled,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              border: hasError
                  ? OutlineInputBorder(
                      borderRadius: AppComponentRadius.inputField,
                      borderSide: const BorderSide(color: AppColors.error),
                    )
                  : InputBorder.none,
              enabledBorder: hasError
                  ? OutlineInputBorder(
                      borderRadius: AppComponentRadius.inputField,
                      borderSide: const BorderSide(color: AppColors.error),
                    )
                  : InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: textTheme.labelSmall?.copyWith(color: AppColors.error),
          ),
        ] else if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
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

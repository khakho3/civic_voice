import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/confirm_dialog.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';
import '../services/admin_session.dart';
import '../services/admin_system_settings_directory.dart';
import '../services/admin_user_directory.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/region_assembly_picker.dart';

/// civic_voice_api's UserRole string for each provisionable [AppRole] —
/// the inverse of main.dart's _appRoleForBackendRole. System
/// Administrator always maps to 'ADMIN' regardless of [AdminTier]: the
/// backend has no tier concept yet (see the class doc comment below).
String _backendRoleFor(AppRole role) {
  return switch (role) {
    AppRole.municipalOfficer => 'MUNICIPAL',
    AppRole.maintenanceTeam => 'MAINTENANCE',
    AppRole.ministrySupervisor => 'MINISTRY',
    AppRole.systemAdministrator => 'ADMIN',
    AppRole.citizen => throw ArgumentError(
      'Citizens self-register, not admin-provisioned',
    ),
  };
}

/// Admin's missing account-creation surface — User Management and User
/// Details only ever let an admin list/edit/deactivate accounts that
/// already exist; there was no way to provision a new one. Citizens still
/// self-register (excluded from the role picker below), but the other four
/// roles — System Administrator, Ministry Supervisor, Municipal Officer,
/// Maintenance Team — are all admin-provisioned.
///
/// Which roles are even offered, and whether the jurisdiction picker is
/// editable at all, both come from [AdminSession]: a Super Admin session
/// sees every provisionable role and picks Region/Assembly freely; an
/// assembly Admin session only sees Municipal Officer/Maintenance Team
/// (they staff their own team, not the platform's admin roster) and has
/// Region/Assembly pre-locked to their own jurisdiction — an assembly
/// Admin can't provision an account outside the assembly they themselves
/// manage.
///
/// Selecting System Administrator reveals the Admin/Super Admin tier
/// choice (matching User Details' own requirement, per
/// [[admin-tier-in-user-creation]] — an account-creation surface must
/// expose the two tiers as distinct choices, not a generic "Admin"), and —
/// if that tier is Admin — the same jurisdiction picker Municipal
/// Officer/Maintenance Team need, since an assembly-scoped Admin account is
/// just as jurisdiction-bound as the staff it manages.
///
/// Creates for real against civic_voice_api (see [ApiClient.createStaffUser])
/// — a real Firebase account, mirrored Postgres row, and a real WittyFlow
/// temp-password SMS. Also mirrors the new account into [AdminUserDirectory]
/// so it shows back up in [AdminUserManagementScreen]'s list immediately,
/// since there's no "list all users" backend endpoint yet — that list is
/// still local/mock. Admin-tier and Region/Assembly scoping are real on
/// this screen but have no backend model yet, so they're only reflected in
/// that local mirror, not sent to or enforced by the server.
class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onNavigateToMaintenanceTeams,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onUserCreated,
  });

  final VoidCallback? onNavigateToDashboard;

  /// Also "Cancel"'s destination, and where a successful create returns
  /// to — same "the list is home" convention as User Details.
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onNavigateToMaintenanceTeams;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onNotificationsTap;

  /// Fired with the new record once it's been added to
  /// [AdminUserDirectory]. Nullable: nothing needs to react beyond the
  /// directory update yet.
  final ValueChanged<AdminUserItem>? onUserCreated;

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late AppRole _role = AdminSession.instance.creatableRoles.first;
  AdminTier _tier = AdminTier.admin;
  Region? _region = AdminSession.instance.region;
  Assembly? _assembly = AdminSession.instance.assembly;
  Map<String, String> _fieldErrors = const {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = AdminSession.instance;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final needsAssembly = AdminUserItem.roleRequiresAssembly(
      _role,
      _role == AppRole.systemAdministrator ? _tier : null,
    );

    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Full name is required';
    if (phone.isEmpty) errors['phone'] = 'Phone number is required';
    if (needsAssembly && _assembly == null) {
      errors['assembly'] = 'Select the assembly this account is scoped to';
    }

    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Create account?',
      message:
          '$name will be provisioned as a ${_role.label} with sign-in '
          'access to CivicVoice.',
      confirmLabel: 'Create',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    String? creationWarning;
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('Not signed in — sign in again and retry.');
      }
      final response = await ApiClient.instance.createStaffUser(
        idToken: idToken,
        fullName: name,
        phone: phone,
        role: _backendRoleFor(_role),
        adminTier: _role == AppRole.systemAdministrator ? _tier.name : null,
        region: needsAssembly
            ? (session.isSuperAdmin ? _region : session.region)?.name
            : null,
        assembly: needsAssembly
            ? (session.isSuperAdmin ? _assembly : session.assembly)?.name
            : null,
      );
      AdminUserDirectory.instance.upsertFromApi(
        response['user'] as Map<String, dynamic>,
      );
      creationWarning = response['warning'] as String?;
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create account. Try again.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final created = AdminUserDirectory.instance.users.value.first;
    widget.onUserCreated?.call(created);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creationWarning ??
                'Account created. A temporary password has been sent to '
                    '$phone via SMS.',
          ),
        ),
      );
    }
    widget.onNavigateToUsers?.call();
  }

  Future<void> _handleCancel() async {
    final hasInput =
        _nameController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty;
    if (hasInput) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Discard this account?',
        message: 'The details you\'ve entered so far will be lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    widget.onNavigateToUsers?.call();
  }

  @override
  Widget build(BuildContext context) {
    final session = AdminSession.instance;
    final needsAssembly = AdminUserItem.roleRequiresAssembly(
      _role,
      _role == AppRole.systemAdministrator ? _tier : null,
    );
    final isAdmin = _role == AppRole.systemAdministrator;
    final jurisdictionLocked = !session.isSuperAdmin;
    final chromeInset = AdminScaffold.contentPadding(context);
    final creationDisabled = !AdminSystemSettingsDirectory
        .instance
        .settings
        .value
        .allowNewAccountCreation;

    return AdminScaffold(
      selectedTab: AdminTab.users,
      headerTitle: 'Create User',
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
        if (tab == AdminTab.maintenance) {
          widget.onNavigateToMaintenanceTeams?.call();
        }
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: widget.onNavigateToMaintenanceTeams,
      onOpenProfile: widget.onOpenProfile,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          chromeInset.top + AppSpacing.md,
          AppSpacing.md,
          chromeInset.bottom + AppSpacing.xl,
        ),
        children: [
          if (creationDisabled) ...[
            const _AccountCreationFrozenBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
          Opacity(
            opacity: creationDisabled ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: creationDisabled,
              child: Column(
                children: [
                  if (jurisdictionLocked)
                    _Section(
                      icon: AppIcons.shieldAlert,
                      title: 'Your Jurisdiction',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You can only provision accounts within your '
                            'own assembly.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ReadOnlyField(
                            label: 'Assembly',
                            value: session.assembly?.fullName ?? 'Not assigned',
                          ),
                        ],
                      ),
                    ),
                  if (jurisdictionLocked) const SizedBox(height: AppSpacing.lg),
                  _Section(
                    icon: AppIcons.profile,
                    title: 'Account Details',
                    child: Column(
                      children: [
                        _TextField(
                          label: 'Full Name',
                          controller: _nameController,
                          errorText: _fieldErrors['name'],
                          onChanged: (_) => setState(() => _fieldErrors = {}),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _TextField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          errorText: _fieldErrors['phone'],
                          onChanged: (_) => setState(() => _fieldErrors = {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    icon: AppIcons.shield,
                    title: 'Access',
                    child: Column(
                      children: [
                        _LabeledDropdown<AppRole>(
                          label: 'Role',
                          value: _role,
                          items: session.creatableRoles,
                          itemLabel: (r) => r.label,
                          onChanged: (role) => setState(() {
                            _role = role;
                            _fieldErrors = {};
                          }),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _LabeledDropdown<AdminTier>(
                            label: 'Admin Tier',
                            value: _tier,
                            items: AdminTier.values,
                            itemLabel: (t) => t.label,
                            onChanged: (tier) => setState(() => _tier = tier),
                          ),
                        ],
                        if (needsAssembly && !jurisdictionLocked) ...[
                          const SizedBox(height: AppSpacing.sm),
                          RegionAssemblyPicker(
                            region: _region,
                            assembly: _assembly,
                            assemblyErrorText: _fieldErrors['assembly'],
                            onRegionChanged: (region) => setState(() {
                              _region = region;
                              _fieldErrors = {};
                            }),
                            onAssemblyChanged: (assembly) => setState(() {
                              _assembly = assembly;
                              _fieldErrors = {};
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _handleCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: (creationDisabled || _isSubmitting)
                      ? null
                      : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: AppIconSize.md,
                          height: AppIconSize.md,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSpacing.xs / 2,
                          ),
                        )
                      : const Text('Create User'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown when ADM-007 System Settings' "Allow new account creation" is
/// off — the form beneath stays visible (so an admin can see what a
/// pending draft would have looked like) but is frozen and un-submittable
/// rather than hidden outright.
class _AccountCreationFrozenBanner extends StatelessWidget {
  const _AccountCreationFrozenBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.permissionDenied,
            color: AppColors.warning,
            size: AppIconSize.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account creation is paused',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  'Turn "Allow new account creation" back on in System '
                  'Settings to provision new accounts.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                title,
                style: textTheme.titleMedium,
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
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: AppComponentRadius.inputField,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<T>(
      label: label,
      hint: '',
      value: value,
      items: [
        for (final item in items)
          AppDropdownItem(value: item, label: itemLabel(item)),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
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

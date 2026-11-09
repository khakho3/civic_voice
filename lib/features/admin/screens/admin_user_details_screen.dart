import '../../../widgets/form_section_card.dart';
import 'package:flutter/material.dart';

import '../../../utils/civic_date.dart';

import '../../../widgets/busy_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';
import '../services/admin_session.dart';
import '../services/admin_user_directory.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/region_assembly_picker.dart';

/// ADM-003 — User Details.
///
/// Approved states (Figma "07/Details" export): Default, Loading, Offline,
/// Error ("Something went wrong"), Unauthorized, Success. No Validation
/// state: the export shows one where both dropdowns turn red with "Select
/// a valid role"/"Select an account status" errors, but both fields are
/// always backed by a real, non-null enum value in this implementation —
/// there's no way to reach an unselected/invalid state through the UI, so
/// there's nothing for that validation to ever catch.
///
/// This is the screen [AppRole]/[AdminUserStatus]/[AdminTier] all
/// converge on: "Assigned Role" edits [AppRole] (reassigning which module
/// an account can open), "Account Status" edits [AdminUserStatus], and —
/// new here, not in the export — selecting [AppRole.systemAdministrator]
/// reveals an "Admin Tier" selector for [AdminTier]. Francis was explicit
/// that any account-creation/editing surface must expose Admin and Super
/// Admin as distinct choices rather than a single generic "Admin", so this
/// selector isn't optional polish.
///
/// The export's top badge reads "Platform User" — a placeholder that
/// doesn't correspond to anything (every account in this system has one of
/// the five real [AppRole]s) — replaced with a live pill reflecting
/// whichever role is currently selected in the form below, the same
/// "preview the pending change" treatment "Permissions Summary" gets too.
///
/// "User Information" (name/email/User ID) renders read-only: nothing in
/// the export suggests admins can rename another account or change its
/// email from here, and User ID is never editable anywhere.
///
enum AdminUserDetailsViewState { loading, loaded, offline, error, unauthorized }

class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({
    super.key,
    required this.user,
    this.initialState = AdminUserDetailsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onNavigateToMaintenanceTeams,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onSaveChanges,
  });

  final AdminUserItem user;
  final AdminUserDetailsViewState initialState;

  final VoidCallback? onNavigateToDashboard;

  /// Also "Cancel"'s destination — this screen is a drill-down from the
  /// user list, so both the bottom-nav "Users" tab and "Cancel" mean the
  /// same thing: go back without necessarily having saved.
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onNavigateToMaintenanceTeams;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onNotificationsTap;

  /// Receives the confirmed server record after a successful save.
  final ValueChanged<AdminUserItem>? onSaveChanges;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late AdminUserDetailsViewState _state = widget.initialState;
  late AdminUserItem _user = widget.user;
  late AppRole _role = widget.user.role;
  late AdminUserStatus _status = widget.user.status;
  late AdminTier? _tier = widget.user.adminTier;
  late Region? _region = widget.user.region;
  late Assembly? _assembly = widget.user.assembly;
  bool _showSuccess = false;
  bool _saving = false;
  bool _reloading = false;
  bool _needsReload = false;
  bool _missingUser = false;
  String? _feedback;

  bool get _dirty =>
      (_role, _status, _tier, _region, _assembly) != _access(_user);

  bool get _canReload =>
      _user.apiId != null && AdminUserDirectory.instance.canRefresh;

  (AppRole, AdminUserStatus, AdminTier?, Region?, Assembly?) _access(
    AdminUserItem user,
  ) => (user.role, user.status, user.adminTier, user.region, user.assembly);

  void _useRecord(AdminUserItem user, {bool keepDraft = false}) {
    if (!keepDraft || _access(_user) != _access(user)) {
      _role = user.role;
      _status = user.status;
      _tier = user.adminTier;
      _region = user.region;
      _assembly = user.assembly;
    }
    _user = user;
  }

  Future<void> _reload() async {
    if (!_canReload || _saving || _reloading) return;
    final directory = AdminUserDirectory.instance;
    final generation = directory.sessionGeneration;
    setState(() => _reloading = true);
    try {
      final user = await directory.reloadUser(_user.apiRecordId);
      if (!mounted || !directory.isSessionGenerationCurrent(generation)) return;
      setState(() {
        _missingUser = user == null;
        _state = user == null
            ? AdminUserDetailsViewState.error
            : AdminUserDetailsViewState.loaded;
        if (user != null) _useRecord(user, keepDraft: _dirty);
        _showSuccess = false;
        _feedback = null;
        _needsReload = false;
      });
    } catch (error) {
      if (!mounted || !directory.isSessionGenerationCurrent(generation)) return;
      final status = error is ApiException ? error.statusCode : null;
      setState(() {
        if (status == 401 || status == 403) {
          _state = AdminUserDetailsViewState.unauthorized;
        } else if (_state == AdminUserDetailsViewState.loaded) {
          _feedback = 'Could not reload the account. Try again.';
          _needsReload = true;
        } else {
          _state = status == 0
              ? AdminUserDetailsViewState.offline
              : AdminUserDetailsViewState.error;
        }
      });
    } finally {
      if (mounted && directory.isSessionGenerationCurrent(generation)) {
        setState(() => _reloading = false);
      }
    }
  }

  Future<void> _handleCancel() async {
    if (_dirty) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message:
            'Unsaved changes to ${_user.name}\'s account will be '
            'lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    widget.onNavigateToUsers?.call();
  }

  Future<void> _save() async {
    final directory = AdminUserDirectory.instance;
    if (_saving ||
        _reloading ||
        _needsReload ||
        directory.isOwnAccount(_user)) {
      return;
    }
    final generation = directory.sessionGeneration;
    final session = AdminSession.instance;
    // A session that can't edit roles/deactivate accounts never changed
    // _role/_status in the first place (their dropdowns render read-only —
    // see _DetailsForm), so these effectively no-op for that session but
    // stay here as a second guarantee against a stale/replayed save.
    final effectiveRole = session.canEditUserRoles ? _role : _user.role;
    final effectiveStatus = session.canDeactivateUsers ? _status : _user.status;
    final roleChanged = effectiveRole != _user.role;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Save access changes?',
      message: roleChanged
          ? '${_user.name}\'s role will change to '
                '${effectiveRole.label} and their account status will be '
                'updated.'
          : '${_user.name}\'s account status will be updated.',
      confirmLabel: 'Save Changes',
      destructive: roleChanged,
    );
    if (!confirmed ||
        !mounted ||
        _reloading ||
        _needsReload ||
        !directory.isSessionGenerationCurrent(generation)) {
      return;
    }

    final updated = _user.copyWith(
      role: effectiveRole,
      status: effectiveStatus,
      adminTier: effectiveRole == AppRole.systemAdministrator
          ? (_tier ?? AdminTier.admin)
          : null,
      region: AdminUserItem.roleRequiresAssembly(effectiveRole, _tier)
          ? _region
          : null,
      assembly: AdminUserItem.roleRequiresAssembly(effectiveRole, _tier)
          ? _assembly
          : null,
    );
    setState(() {
      _saving = true;
      _feedback = null;
      _showSuccess = false;
    });
    final AdminUserItem saved;
    try {
      saved = await directory.saveOnServer(updated);
    } catch (error) {
      if (!mounted || !directory.isSessionGenerationCurrent(generation)) return;
      final status = error is ApiException ? error.statusCode : null;
      final leadConflict =
          error is ApiException &&
          status == 409 &&
          error.message.startsWith('Reassign the lead for ');
      final rejected =
          status == 400 ||
          status == 401 ||
          status == 403 ||
          status == 422 ||
          leadConflict;
      setState(() {
        _saving = false;
        _needsReload = _canReload && !rejected;
        _feedback = switch (status) {
          409 when leadConflict => error.message,
          401 ||
          403 => 'Your account does not have access to save these changes.',
          400 || 422 =>
            'The account changes were rejected. Check the access settings and try again.',
          409 =>
            'The account update conflicts with another change. Reload its details before trying again.',
          404 => 'This account is no longer available. Reload its details.',
          _ when _needsReload =>
            'The account change could not be confirmed. Reload its details before trying again.',
          _ => 'Could not save changes right now.',
        };
      });
      return;
    }
    if (!mounted || !directory.isSessionGenerationCurrent(generation)) return;
    setState(() {
      _useRecord(saved);
      _saving = false;
      _showSuccess = widget.onNavigateToUsers == null;
    });
    widget.onSaveChanges?.call(saved);
    final returnToUsers = widget.onNavigateToUsers;
    if (returnToUsers != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes to ${saved.name} were saved.')),
      );
      returnToUsers();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownAccount = AdminUserDirectory.instance.isOwnAccount(_user);
    return AdminScaffold(
      selectedTab: AdminTab.users,
      headerTitle: 'User Details',
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
      body: _buildBody(context, ownAccount),
    );
  }

  Widget _buildBody(BuildContext context, bool ownAccount) {
    final body = switch (_state) {
      AdminUserDetailsViewState.loading => const _LoadingSkeleton(),
      AdminUserDetailsViewState.loaded => _DetailsForm(
        user: _user,
        role: _role,
        status: _status,
        tier: _tier,
        region: _region,
        assembly: _assembly,
        showSuccess: _showSuccess,
        canEditRole: !ownAccount && AdminSession.instance.canEditUserRoles,
        canEditStatus: !ownAccount && AdminSession.instance.canDeactivateUsers,
        onRoleChanged: (role) => setState(() {
          _role = role;
          _showSuccess = false;
          if (role == AppRole.systemAdministrator) {
            _tier ??= AdminTier.admin;
          } else {
            _tier = null;
          }
          if (!AdminUserItem.roleRequiresAssembly(role, _tier)) {
            _region = null;
            _assembly = null;
          }
        }),
        onStatusChanged: (status) => setState(() {
          _status = status;
          _showSuccess = false;
        }),
        onTierChanged: (tier) => setState(() {
          _tier = tier;
          _showSuccess = false;
          if (!AdminUserItem.roleRequiresAssembly(_role, tier)) {
            _region = null;
            _assembly = null;
          }
        }),
        onRegionChanged: (region) => setState(() {
          _region = region;
          _showSuccess = false;
        }),
        onAssemblyChanged: (assembly) => setState(() {
          _assembly = assembly;
          _showSuccess = false;
        }),
        onBack: _handleCancel,
        onCancel: _handleCancel,
        onSave: _save,
        saving: _saving,
        reloading: _reloading,
        feedback: _feedback,
        onReload: _needsReload ? _reload : null,
        ownAccount: ownAccount,
      ),
      _ => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: AdminScaffold.contentPadding(context),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: switch (_state) {
                AdminUserDetailsViewState.offline => AppStateMessage(
                  icon: AppIcons.offline,
                  badgeColor: AppColors.error,
                  title: 'You\'re offline',
                  message: _canReload
                      ? 'Check your connection and try loading the account again.'
                      : 'User details cannot be reloaded from this screen while offline.',
                  primaryActionLabel: _canReload ? 'Retry connection' : null,
                  onPrimaryAction: _reloading ? null : _reload,
                  bordered: true,
                ),
                AdminUserDetailsViewState.error => AppStateMessage(
                  icon: AppIcons.warning,
                  badgeColor: AppColors.error,
                  title: _missingUser
                      ? 'User details unavailable'
                      : 'Something went wrong',
                  message: _missingUser
                      ? 'This account could not be found in your user directory.'
                      : _canReload
                      ? 'Unable to load user details right now.'
                      : 'Unable to load user details right now. Reloading details is not available from this screen.',
                  primaryActionLabel: _canReload ? 'Retry' : null,
                  onPrimaryAction: _reloading ? null : _reload,
                  bordered: true,
                ),
                AdminUserDetailsViewState.unauthorized => const AppStateMessage(
                  icon: AppIcons.permissionDenied,
                  badgeColor: AppColors.error,
                  title: 'Unauthorized Access',
                  message:
                      'Administrative privileges are required to view '
                      'user details.',
                  bordered: true,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    };
    if (!_canReload ||
        _state == AdminUserDetailsViewState.unauthorized ||
        _state == AdminUserDetailsViewState.loading) {
      return body;
    }
    return GhanaRefreshIndicator(
      onRefresh: _reload,
      topOffset: AdminScaffold.contentPadding(context).top,
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Form
// ---------------------------------------------------------------------------

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({
    required this.user,
    required this.role,
    required this.status,
    required this.tier,
    required this.region,
    required this.assembly,
    required this.showSuccess,
    required this.canEditRole,
    required this.canEditStatus,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onTierChanged,
    required this.onRegionChanged,
    required this.onAssemblyChanged,
    required this.onSave,
    this.onBack,
    this.onCancel,
    this.saving = false,
    this.reloading = false,
    this.feedback,
    this.onReload,
    this.ownAccount = false,
  });

  final AdminUserItem user;
  final AppRole role;
  final AdminUserStatus status;
  final AdminTier? tier;
  final Region? region;
  final Assembly? assembly;
  final bool showSuccess;

  /// [AdminSession.canEditUserRoles] — an assembly Admin sees Assigned Role
  /// and Admin Tier as read-only text instead of dropdowns.
  final bool canEditRole;

  /// [AdminSession.canDeactivateUsers] — an assembly Admin sees Account
  /// Status as read-only text instead of a dropdown.
  final bool canEditStatus;
  final ValueChanged<AppRole> onRoleChanged;
  final ValueChanged<AdminUserStatus> onStatusChanged;
  final ValueChanged<AdminTier> onTierChanged;
  final ValueChanged<Region?> onRegionChanged;
  final ValueChanged<Assembly?> onAssemblyChanged;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final bool saving;
  final bool reloading;
  final String? feedback;
  final Future<void> Function()? onReload;
  final bool ownAccount;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final chromeInset = AdminScaffold.contentPadding(context);
    final isAdmin = role == AppRole.systemAdministrator;
    final needsAssembly = AdminUserItem.roleRequiresAssembly(role, tier);
    final preview = user.copyWith(
      role: role,
      status: status,
      adminTier: isAdmin ? (tier ?? AdminTier.admin) : null,
      region: needsAssembly ? region : null,
      assembly: needsAssembly ? assembly : null,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(AppIcons.back),
              tooltip: 'Back to user management',
            ),
          ],
        ),
        if (showSuccess) ...[
          const _SuccessBanner(),
          const SizedBox(height: AppSpacing.sm),
        ],
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppSemanticColors.of(context).glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _CompactIdentity(
              user: user,
              previewRole: role,
              previewStatus: status,
            ),
          ),
        ),
        if (ownAccount) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Your own account is read-only here. Use Profile to update your personal details.',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Account information',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReadOnlyField(label: 'Full Name', value: user.name),
              const SizedBox(height: AppSpacing.sm),
              _ReadOnlyField(label: 'Phone Number', value: user.phone),
              const SizedBox(height: AppSpacing.sm),
              _ReadOnlyField(
                label: 'Email',
                value: user.email ?? 'Not provided',
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReadOnlyField(label: 'User ID', value: user.userId),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Access',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canEditRole)
                _LabeledDropdown<AppRole>(
                  label: 'Assigned Role',
                  value: role,
                  items: AppRole.values,
                  itemLabel: (r) => r.label,
                  onChanged: onRoleChanged,
                )
              else
                _ReadOnlyField(label: 'Assigned Role', value: role.label),
              if (isAdmin) ...[
                const SizedBox(height: AppSpacing.sm),
                if (canEditRole)
                  _LabeledDropdown<AdminTier>(
                    label: 'Admin Tier',
                    value: tier ?? AdminTier.admin,
                    items: AdminTier.values,
                    itemLabel: (t) => t.label,
                    onChanged: onTierChanged,
                  )
                else
                  _ReadOnlyField(
                    label: 'Admin Tier',
                    value: (tier ?? AdminTier.admin).label,
                  ),
              ],
              if (needsAssembly) ...[
                const SizedBox(height: AppSpacing.sm),
                if (canEditRole)
                  RegionAssemblyPicker(
                    region: region,
                    assembly: assembly,
                    onRegionChanged: onRegionChanged,
                    onAssemblyChanged: onAssemblyChanged,
                  )
                else ...[
                  _ReadOnlyField(
                    label: 'Region',
                    value: region?.label ?? 'Not assigned',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReadOnlyField(
                    label: 'Assembly',
                    value: assembly?.name ?? 'Not assigned',
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.sm),
              if (canEditStatus)
                _LabeledDropdown<AdminUserStatus>(
                  label: 'Account Status',
                  value: status,
                  items: AdminUserStatus.values,
                  itemLabel: (s) => s.label,
                  onChanged: onStatusChanged,
                )
              else
                _ReadOnlyField(label: 'Account Status', value: status.label),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Permissions',
          child: preview.permissionSummary.isEmpty
              ? Text(
                  'No permissions granted.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final label in preview.permissionSummary)
                      _TagChip(label),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Account Activity',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActivityRow(
                label: 'Last sign-in',
                value: formatCivicTimestamp(user.lastSignIn),
              ),
              const Divider(height: AppSpacing.lg),
              _ActivityRow(
                label: 'Account created',
                value: formatCivicDate(user.accountCreated),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Administrative actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (feedback case final message?) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          if (onReload != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: reloading ? null : onReload,
                child: BusyLabel(
                  busy: reloading,
                  busyLabel: 'Reloading details',
                  child: const Text('Reload details'),
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed:
                    saving ||
                        reloading ||
                        onReload != null ||
                        ownAccount ||
                        (!canEditRole && !canEditStatus)
                    ? null
                    : onSave,
                child: BusyLabel(
                  busy: saving,
                  busyLabel: 'Saving changes',
                  child: const Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({
    required this.user,
    required this.previewRole,
    required this.previewStatus,
  });

  final AdminUserItem user;
  final AppRole previewRole;
  final AdminUserStatus previewStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actionColor = AppSemanticColors.of(context).actionText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              user.initials,
              style: textTheme.titleMedium?.copyWith(
                color: actionColor,
                fontWeight: AppFontWeight.semiBold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                label:
                    'User identity: ${user.name}, ${user.phone}, '
                    '${previewRole.label}',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user.phone,
                        style: textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      previewRole.label,
                      style: textTheme.bodyMedium?.copyWith(color: actionColor),
                    ),
                  ),
                  Semantics(
                    label: 'Account status: ${previewStatus.label}',
                    child: ExcludeSemantics(
                      child: _Pill(
                        label: previewStatus.label,
                        color: previewStatus.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: AppFontWeight.semiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FormSectionCard(title: title, child: child);
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: textTheme.bodyLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: AppFontWeight.semiBold,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusResolved.withValues(alpha: 0.1),
        borderRadius: AppComponentRadius.card,
        border: Border.all(
          color: AppColors.statusResolved.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.success,
            color: AppColors.statusResolved,
            size: AppIconSize.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Changes saved',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppSemanticColors.of(context).statusResolvedText,
                  ),
                ),
                Text(
                  'The user role and account status were updated '
                  'successfully.',
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
    final chromeInset = AdminScaffold.contentPadding(context);

    Widget block({double? width, double height = 16, double? radius}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: BorderRadius.circular(radius ?? 4),
            ),
          );
        },
      );
    }

    Widget sectionBlock({double height = 96}) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(height: 12, width: 100),
          const SizedBox(height: AppSpacing.sm),
          block(height: height),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: AppComponentRadius.card,
          ),
          child: Column(
            children: [
              block(width: 96, height: 96, radius: 48),
              const SizedBox(height: AppSpacing.md),
              block(height: 16, width: 160),
              const SizedBox(height: AppSpacing.xs),
              block(height: 12, width: 200),
              const SizedBox(height: AppSpacing.sm),
              block(height: 24, width: 140, radius: 20),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 130),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 100),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 60),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 60),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/biometric_lock_preference_row.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/haptics_preference_row.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_name_edit_sheet.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/profile_session_section.dart';
import '../../../widgets/profile_status_banner.dart';
import '../../../widgets/theme_preference_row.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../models/maintenance_profile.dart';
import '../services/maintenance_session.dart';
import '../widgets/maintenance_scaffold.dart';

/// MNT-007 — Maintenance Profile, on the shared grouped-list Profile system.
///
/// Reads the signed-in technician's real administrator-provisioned account
/// from [MaintenanceSession]. Department, Region, Assembly, Team and
/// Employee ID are administrator-controlled and read-only; Full Name is the
/// only self-editable field, through the shared name sheet opened from the
/// avatar pencil. The Team Lead pill appears only when this technician is
/// the team's *current* lead (resolved from the live team record first,
/// then the session), and an unassigned technician sees an honest "Not
/// assigned to a team" rather than a placeholder team.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTasks,
    this.onNotificationsTap,
    this.onChangePassword,
    this.onAbout,
    this.onLogOut,
    this.onSaveProfile,
    this.initialState = AppScreenState.success,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTasks;

  /// Opens Maintenance Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;

  /// Fired after the log-out confirmation dialog is accepted.
  final VoidCallback? onLogOut;
  final Future<bool> Function(String fullName)? onSaveProfile;

  /// Screen state, for previews and tests of the non-default states.
  final AppScreenState initialState;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppScreenState _state = widget.initialState;
  bool _changesSaved = false;

  Future<void> _startEditing(MaintenanceProfile profile) async {
    final saved = await showProfileNameEditSheet(
      context,
      initialName: profile.fullName,
      onSave: (name) async {
        final ok =
            await (widget.onSaveProfile?.call(name) ??
                Future<bool>.value(true));
        if (ok) MaintenanceSession.instance.updateProfile(fullName: name);
        return ok;
      },
    );
    if (!mounted || !saved) return;
    setState(() => _changesSaved = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _changesSaved = false);
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to sign back in to access the maintenance console.",
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
    void retry() => setState(() => _state = AppScreenState.success);
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(onRetry: retry);
      case AppScreenState.error:
        return _ErrorView(onRetry: retry);
      case AppScreenState.offline:
        return _OfflineView(onRetry: retry);
      case AppScreenState.permission:
        return _PermissionView(onRetry: retry);
      case AppScreenState.disabled:
        return _buildProfile(context, disabled: true);
      case AppScreenState.success:
        return _buildProfile(context);
    }
  }

  Widget _buildProfile(BuildContext context, {bool disabled = false}) {
    return ValueListenableBuilder<MaintenanceProfile>(
      valueListenable: MaintenanceSession.instance.profile,
      builder: (context, profile, _) => _ProfileContent(
        profile: profile,
        disabled: disabled,
        changesSaved: _changesSaved,
        onEdit: disabled ? null : () => _startEditing(profile),
        onChangePassword: disabled ? null : widget.onChangePassword,
        onAbout: disabled ? null : widget.onAbout,
        onLogOut: disabled ? null : _confirmLogOut,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.disabled,
    required this.changesSaved,
    required this.onEdit,
    required this.onChangePassword,
    required this.onAbout,
    required this.onLogOut,
  });

  final MaintenanceProfile profile;
  final bool disabled;
  final bool changesSaved;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;
  final VoidCallback? onLogOut;

  /// Current lead, resolved at read time: the live team record wins over
  /// the value cached at sign-in, so a lead change in Admin shows here on
  /// the next read without re-login.
  bool get _isCurrentLead {
    final teamId = profile.teamId;
    if (teamId == null || profile.publicId.isEmpty) return false;
    final leadUserId =
        MaintenanceTeamDirectory.instance.teamById(teamId)?.leadUserId ??
        profile.teamLeadUserId;
    return leadUserId != null && leadUserId == profile.publicId;
  }

  @override
  Widget build(BuildContext context) {
    final chromeInset = MaintenanceScaffold.contentPadding(context);
    final teamName = profile.teamName;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            chromeInset.top + AppSpacing.md,
            AppSpacing.md,
            chromeInset.bottom + AppSpacing.md,
          ),
          children: [
            if (changesSaved) ...[
              const ProfileStatusBanner(
                tone: ProfileBannerTone.success,
                title: 'Changes saved',
                message: 'Permitted profile fields were updated.',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            ProfileHeaderCard(
              name: profile.fullName,
              pills: ['Maintenance Team', if (_isCurrentLead) 'Team Lead'],
              onEdit: onEdit,
            ),
            ProfileSection(
              title: 'Account',
              children: [
                ProfileFieldRow(label: 'Phone number', value: profile.phone),
                const ProfileFieldRow(
                  label: 'Department',
                  value: 'Maintenance',
                  locked: true,
                ),
                ProfileFieldRow(
                  label: 'Region',
                  value: profile.region,
                  locked: true,
                ),
                ProfileFieldRow(
                  label: 'Assembly',
                  value: profile.assembly,
                  locked: true,
                ),
                ProfileFieldRow(
                  label: 'Team',
                  value: teamName == null || teamName.isEmpty
                      ? 'Not assigned to a team'
                      : teamName,
                  locked: true,
                ),
                ProfileFieldRow(
                  label: 'Employee ID',
                  value: profile.publicId,
                  locked: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const ProfileSection(
              title: 'Preferences',
              children: [
                ThemePreferenceRow(),
                HapticsPreferenceRow(),
                LanguagePreferenceRow(),
                BiometricLockPreferenceRow(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ProfileSection(
              children: [
                ProfileActionRow(
                  icon: AppIcons.info,
                  label: 'About CivicVoice',
                  onTap: onAbout,
                ),
                ProfileActionRow(
                  icon: AppIcons.password,
                  label: 'Change password',
                  onTap: onChangePassword,
                ),
              ],
            ),
            ProfileSessionSection(onLogOut: onLogOut),
          ],
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
              style: FilledButton.styleFrom(
                backgroundColor: semantic.error,
                foregroundColor: semantic.onError,
              ),
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
              color: semantic.warningText,
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

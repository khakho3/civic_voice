import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/biometric_lock_preference_row.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/haptics_preference_row.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_info_button.dart';
import '../../../widgets/profile_name_edit_sheet.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/profile_session_section.dart';
import '../../../widgets/profile_status_banner.dart';
import '../../../widgets/theme_preference_row.dart';
import '../models/admin_profile_data.dart';
import '../services/admin_session.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-008 — Admin Profile (Super and Assembly tiers), on the shared
/// grouped-list Profile system.
///
/// Approved states (Figma "03/Profile" export): Default, Edit, Loading,
/// Offline, Error ("Something went wrong"), Unauthorized, Validation,
/// Success ("Profile updated"). Load failures stay full-page
/// [AppStateMessage]s with error-red recovery.
///
/// Super Admin reaches this screen from [AdminScaffold]'s drawer and keeps
/// the tab shell with no selected tab. An Assembly Admin reaches it from
/// the header profile shortcut and gets a drill-down with ordinary Back
/// and no bottom navigation.
///
/// "Administrator Information" and "System Preferences" are the only
/// titled sections; About and Change Password sit in their own untitled
/// groups. The administrative scope stays behind the info button. Full
/// Name is the only self-editable field, through the shared name sheet
/// (which confirms before discarding unsaved changes); phone, department,
/// Admin ID and governance level are administrator-controlled and never
/// rewritten by a save — the screen shows the saved record afterwards.
enum AdminProfileViewState { loading, loaded, offline, error, unauthorized }

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({
    super.key,
    this.initialState = AdminProfileViewState.loaded,
    this.initialSaveState = AdminProfileSaveState.idle,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onChangePassword,
    this.onAbout,
    this.onNavigateToMaintenanceTeams,
    this.onSignOut,
    this.onNotificationsTap,
    this.initialData,
    this.onSaveProfile,
    this.onRetry,
    this.onBack,
  });

  final AdminProfileViewState initialState;

  /// Preview hook for the saved/failed banners. A real failed save keeps
  /// the edit sheet open with its own error instead.
  final AdminProfileSaveState initialSaveState;

  /// Wired by the app shell so Super Admin's bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onNavigateToMaintenanceTeams;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;

  /// Fired after the log-out confirmation dialog is accepted.
  final VoidCallback? onSignOut;

  final VoidCallback? onNotificationsTap;
  final AdminProfileData? initialData;
  final Future<bool> Function(String fullName)? onSaveProfile;
  final Future<void> Function()? onRetry;

  /// Returns an assembly-level Admin to the screen that opened Profile.
  /// Super Admin keeps its existing drawer and tab-shell navigation.
  final VoidCallback? onBack;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late AdminProfileViewState _state = widget.initialState;
  late AdminProfileSaveState _saveState = widget.initialSaveState;
  late AdminProfileData _profile = widget.initialData ?? mockAdminProfile();

  @override
  void didUpdateWidget(covariant AdminProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != null &&
        widget.initialData != oldWidget.initialData) {
      _profile = widget.initialData!;
    }
    if (widget.initialState != oldWidget.initialState) {
      _state = widget.initialState;
    }
  }

  Future<void> _retry() async {
    setState(() => _state = AdminProfileViewState.loading);
    try {
      await widget.onRetry?.call();
      if (mounted) {
        setState(() {
          _state = widget.initialData == null
              ? AdminProfileViewState.error
              : AdminProfileViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = AdminProfileViewState.error);
    }
  }

  Future<void> _startEdit() async {
    setState(() => _saveState = AdminProfileSaveState.idle);
    final saved = await showProfileNameEditSheet(
      context,
      initialName: _profile.fullName,
      confirmDiscard: true,
      onSave: (name) async {
        final save = widget.onSaveProfile;
        final ok = save == null
            ? await Future<bool>.delayed(
                const Duration(milliseconds: 500),
                () => true,
              )
            : await save(name);
        if (ok && mounted) {
          // Only the name changes; administrator-controlled fields keep
          // their saved values.
          setState(() => _profile = _profile.copyWith(fullName: name));
        }
        return ok;
      },
    );
    if (!mounted || !saved) return;
    setState(() => _saveState = AdminProfileSaveState.saved);
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to sign back in to access the admin console.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onSignOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = AdminSession.instance.isSuperAdmin;
    return AdminScaffold(
      activeDrawerDestination: AdminDrawerDestination.adminProfile,
      selectedTab: null,
      headerTitle: 'Admin Profile',
      hideBottomNav: !isSuperAdmin,
      onBack: isSuperAdmin ? null : widget.onBack,
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
      body: switch (_state) {
        AdminProfileViewState.loading => const _LoadingSkeleton(),
        AdminProfileViewState.loaded => _ProfileBody(
          profile: _profile,
          saveState: _saveState,
          onEdit: _startEdit,
          onChangePassword: widget.onChangePassword,
          onAbout: widget.onAbout,
          onLogOut: widget.onSignOut == null ? null : _confirmLogOut,
        ),
        _ => Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: AdminScaffold.contentPadding(context).top,
              bottom: AdminScaffold.contentPadding(context).bottom,
              left: AppSpacing.md,
              right: AppSpacing.md,
            ),
            child: switch (_state) {
              AdminProfileViewState.offline => AppStateMessage(
                icon: AppIcons.offline,
                badgeColor: AppColors.error,
                title: 'You\'re offline',
                message:
                    'Check your connection and retry loading '
                    'administrator profile.',
                primaryActionLabel: 'Retry connection',
                onPrimaryAction: _retry,
                primaryActionColor: AppColors.error,
                bordered: true,
              ),
              AdminProfileViewState.error => AppStateMessage(
                icon: AppIcons.warning,
                badgeColor: AppColors.error,
                title: 'Something went wrong',
                message: 'Unable to load administrator profile data right now.',
                primaryActionLabel: 'Retry',
                onPrimaryAction: _retry,
                primaryActionColor: AppColors.error,
                bordered: true,
              ),
              _ => const AppStateMessage(
                icon: AppIcons.permissionDenied,
                badgeColor: AppColors.error,
                title: 'Unauthorized Access',
                message:
                    'Administrative privileges are required to access '
                    'this profile.',
                bordered: true,
              ),
            },
          ),
        ),
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.saveState,
    required this.onEdit,
    this.onChangePassword,
    this.onAbout,
    this.onLogOut,
  });

  final AdminProfileData profile;
  final AdminProfileSaveState saveState;
  final VoidCallback onEdit;
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;
  final VoidCallback? onLogOut;

  @override
  Widget build(BuildContext context) {
    final chromeInset = AdminScaffold.contentPadding(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.md,
      ),
      children: [
        if (saveState == AdminProfileSaveState.saved) ...[
          const ProfileStatusBanner(
            tone: ProfileBannerTone.success,
            title: 'Profile updated',
            message: 'Administrator profile changes were saved successfully.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (saveState == AdminProfileSaveState.failed) ...[
          const ProfileStatusBanner(
            tone: ProfileBannerTone.error,
            title: 'Update Failed',
            message:
                'Administrator profile changes could not be saved. No '
                'changes were applied.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ProfileHeaderCard(
          name: profile.fullName,
          subtitle: 'Administrator account · Governance approved',
          onEdit: onEdit,
        ),
        ProfileSection(
          title: 'Administrator Information',
          trailing: ProfileInfoButton(
            title: 'Administrative Scope',
            message: 'This account can access these administrative areas:',
            items: profile.administrativeScope,
          ),
          children: [
            ProfileFieldRow(label: 'Full Name', value: profile.fullName),
            ProfileFieldRow(label: 'Phone Number', value: profile.phone),
            ProfileFieldRow(
              label: 'Department',
              value: profile.department,
              locked: true,
            ),
            ProfileFieldRow(
              label: 'Admin ID',
              value: profile.adminId,
              locked: true,
            ),
            ProfileFieldRow(
              label: 'Governance Level',
              value: profile.governanceLevel,
              locked: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const ProfileSection(
          title: 'System Preferences',
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
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          children: [
            ProfileActionRow(
              icon: AppIcons.password,
              label: 'Change Password',
              onTap: onChangePassword,
            ),
          ],
        ),
        ProfileSessionSection(onLogOut: onLogOut),
      ],
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

    Widget cardBlock({double height = 100}) => Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 220),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 130),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 140),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 140),
      ],
    );
  }
}

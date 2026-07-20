import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/kebab_menu_button.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_edit_action_bar.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/theme_preference_row.dart';
import '../models/ministry_profile_data.dart';

/// MIN-006 — Ministry Profile.
///
/// Approved states (Figma "06/profile" export): Default, Loading, Edit,
/// Validation ("Full name is required."), Success, Error, Offline,
/// Unauthorized.
///
/// Per the spec ("17 CivicVoice - Ministry Supervisor Screen
/// Specifications", MIN-006), entry and exit are both Ministry Dashboard —
/// the same drill-down shape as MIN-005 Report Insights, reached here via
/// the header's profile avatar rather than a tab. The approved frame shows
/// the same persistent 4-tab bottom nav (with mismatched "Directory"/
/// "Settings" labels and "Profile" highlighted) as every other screen's
/// copy/paste-from-Dashboard slip, and its own header shows a hamburger
/// menu rather than a title — both corrected the same way as MIN-005: a
/// [DetailHeader] with a back arrow, no bottom nav.
///
/// Unlike every other screen this session, Error/Offline/Unauthorized here
/// are a floating dialog over a dimmed, disabled backdrop of the profile
/// shell (not a full-page replacement) — confirmed against the approved
/// frames, which consistently show this treatment across all three states
/// with a matching "Back to Safety" action, not a one-off copy/paste
/// artifact the way the header/nav mismatches are.
///
/// Edit-mode entry is the header's kebab menu (matching every other
/// drill-down screen's profile — Municipal Officer's MUN-009), not the
/// frame's original "tap the whole Personal Information card" gesture,
/// which the earlier version of this screen's own doc comment flagged as
/// an unintentional Figma-export artifact rather than a deliberate
/// affordance. Once editing, the header's leading icon becomes a close (X)
/// that cancels rather than navigating away.
///
/// Log Out lives in the same kebab menu as Edit Profile, confirmed via
/// [showConfirmDialog] before firing — the spec lists a "Logout Button"
/// component and a "Logout" user action but no exported frame shows one
/// anywhere, so there was no original placement to be faithful to; this
/// matches Municipal Officer's own profile screen exactly rather than
/// inventing a third pattern.
enum MinistryProfileViewState {
  loading,
  view,
  edit,
  validation,
  success,
  error,
  offline,
  unauthorized,
}

class MinistryProfileScreen extends StatefulWidget {
  const MinistryProfileScreen({
    super.key,
    this.initialState = MinistryProfileViewState.view,
    this.onBack,
    this.onNotificationsTap,
    this.onChangePassword,
    this.onLogOut,
    this.profile,
    this.onSaveProfile,
  });

  final MinistryProfileViewState initialState;

  /// Returns to Ministry Dashboard — the spec's only entry and exit point.
  /// Also wired to the header's leading icon when not editing; during
  /// Edit/Validation that slot becomes a close (X) that cancels instead
  /// (see the class doc comment).
  final VoidCallback? onBack;

  final VoidCallback? onNotificationsTap;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;

  /// Fired after the log-out confirmation dialog is accepted. Nullable:
  /// there's no real authentication flow to sign out of yet.
  final VoidCallback? onLogOut;
  final MinistryProfileData? profile;
  final Future<bool> Function(String fullName)? onSaveProfile;

  @override
  State<MinistryProfileScreen> createState() => _MinistryProfileScreenState();
}

class _MinistryProfileScreenState extends State<MinistryProfileScreen> {
  late MinistryProfileViewState _state = widget.initialState;
  late MinistryProfileData _profile;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _profile = widget.profile ?? MinistryProfileData.mock();
    _nameController = TextEditingController(text: _profile.name);
    _phoneController = TextEditingController(text: _profile.phone);
    // The approved Validation frame shows a specific pre-filled failure
    // (an empty Full Name) rather than a blank-slate form — reproduce it so
    // `initialState: .validation` previews the actual frame.
    if (widget.initialState == MinistryProfileViewState.validation) {
      _nameController.text = '';
      _fieldErrors = {'name': 'Full name is required.'};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _fieldErrors = {};
      _state = MinistryProfileViewState.edit;
    });
  }

  void _cancelEdit() {
    _nameController.text = _profile.name;
    _phoneController.text = _profile.phone;
    setState(() {
      _fieldErrors = {};
      _state = MinistryProfileViewState.view;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Full name is required.';

    setState(() {
      _fieldErrors = errors;
      _state = MinistryProfileViewState.edit;
    });
    if (errors.isNotEmpty) return;

    setState(() => _state = MinistryProfileViewState.loading);
    final saved =
        await (widget.onSaveProfile?.call(name) ?? Future<bool>.value(true));
    if (!mounted) return;
    if (!saved) {
      setState(() => _state = MinistryProfileViewState.error);
      return;
    }
    setState(() {
      _profile = _profile.copyWith(name: name);
      _state = MinistryProfileViewState.success;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _state == MinistryProfileViewState.success) {
        setState(() => _state = MinistryProfileViewState.view);
      }
    });
  }

  void _retry() {
    setState(() => _state = MinistryProfileViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MinistryProfileViewState.view);
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to sign back in to access the ministry console.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onLogOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        _state == MinistryProfileViewState.edit ||
        _state == MinistryProfileViewState.validation;
    final showDialog =
        _state == MinistryProfileViewState.error ||
        _state == MinistryProfileViewState.offline ||
        _state == MinistryProfileViewState.unauthorized;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: DetailHeader.topInset(context)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: showDialog,
                      child: Column(
                        children: [
                          Expanded(
                            child: switch (_state) {
                              MinistryProfileViewState.loading =>
                                const _LoadingSkeleton(),
                              _ => _ProfileBody(
                                profile: _profile,
                                editing: isEditing,
                                showSuccessBanner:
                                    _state == MinistryProfileViewState.success,
                                nameController: _nameController,
                                phoneController: _phoneController,
                                fieldErrors: _fieldErrors,
                                onChangePassword: widget.onChangePassword,
                              ),
                            },
                          ),
                          if (isEditing)
                            ProfileEditActionBar(
                              onCancel: _cancelEdit,
                              onSave: _save,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (showDialog) ...[
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x80000000)),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: switch (_state) {
                          MinistryProfileViewState.error => AppStateMessage(
                            icon: AppIcons.warning,
                            badgeColor: AppColors.error,
                            title: 'Something went wrong',
                            message:
                                'Unable to load profile data. This could be '
                                'due to a temporary network issue or server '
                                'maintenance.',
                            primaryActionLabel: 'Retry',
                            onPrimaryAction: _retry,
                            secondaryActionLabel: 'Back to Safety',
                            onSecondaryAction: widget.onBack,
                            bordered: true,
                          ),
                          MinistryProfileViewState.offline => AppStateMessage(
                            icon: AppIcons.offline,
                            badgeColor: AppColors.error,
                            title: 'You\'re offline',
                            message:
                                'Check your connection and retry loading '
                                'profile data.',
                            primaryActionLabel: 'Retry connection',
                            onPrimaryAction: _retry,
                            secondaryActionLabel: 'Back to Safety',
                            onSecondaryAction: widget.onBack,
                            bordered: true,
                          ),
                          _ => AppStateMessage(
                            icon: AppIcons.permissionDenied,
                            badgeColor: AppColors.error,
                            title: 'Unauthorized Access',
                            message:
                                'You can only view and edit your own '
                                'ministry profile.',
                            secondaryActionLabel: 'Back to Safety',
                            onSecondaryAction: widget.onBack,
                            bordered: true,
                          ),
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'My Profile',
              leadingIcon: isEditing ? AppIcons.close : AppIcons.back,
              onBack: isEditing ? _cancelEdit : widget.onBack,
              trailing: isEditing
                  ? TextButton(onPressed: _save, child: const Text('Save'))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: AppDimensions.controlHeightStandard,
                          height: AppDimensions.controlHeightStandard,
                          child: Material(
                            color: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppComponentRadius.card,
                            ),
                            child: InkWell(
                              borderRadius: AppComponentRadius.card,
                              onTap: widget.onNotificationsTap,
                              child: Icon(
                                AppIcons.notifications,
                                size: AppIconSize.md,
                              ),
                            ),
                          ),
                        ),
                        KebabMenuButton<void>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: _startEditing,
                              child: const Text('Edit Profile'),
                            ),
                            PopupMenuItem(
                              onTap: _confirmLogOut,
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile body — shared shape for View/Success/Editing/dialog-backdrop
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.editing,
    this.showSuccessBanner = false,
    required this.nameController,
    required this.phoneController,
    this.fieldErrors = const {},
    this.onChangePassword,
  });

  final MinistryProfileData profile;
  final bool editing;
  final bool showSuccessBanner;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final Map<String, String> fieldErrors;
  final VoidCallback? onChangePassword;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        ProfileHeaderCard(
          name: profile.name,
          subtitle: profile.ministry,
          pills: [
            TintedBadge(
              label: profile.role,
              color: AppColors.primary,
              textColor: AppColors.primary,
            ),
            TintedBadge(
              label: 'ID ${profile.publicId}',
              color: AppColors.primary,
              textColor: AppColors.primary,
            ),
          ],
          editing: editing,
        ),
        if (showSuccessBanner) ...[
          const SizedBox(height: AppSpacing.md),
          const _SuccessBanner(),
        ],
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.profile,
          title: 'Personal Information',
          children: [
            ProfileFieldRow(
              label: 'Full Name',
              controller: nameController,
              editable: editing,
              errorText: fieldErrors['name'],
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
          icon: AppIcons.systemTheme,
          title: 'System Preferences',
          children: const [
            ThemePreferenceRow(),
            Divider(height: AppSpacing.lg),
            LanguagePreferenceRow(),
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
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.shieldAlert,
          title: 'Account Metadata',
          children: [
            Text(
              'Permissions are managed by administrators. This screen only '
              'allows editing your own profile.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final badge in profile.metadataBadges)
                  TintedBadge(
                    label: badge,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusResolved.withValues(alpha: 0.12),
        borderRadius: AppComponentRadius.card,
        border: Border.all(
          color: AppColors.statusResolved.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.success,
            size: AppIconSize.md,
            color: AppColors.statusResolved,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile updated', style: textTheme.titleSmall),
                Text(
                  'Your profile changes were saved successfully.',
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(height: AppSpacing.md),
            block(width: 160, height: 20),
            const SizedBox(height: AppSpacing.sm),
            block(width: 120, height: 16, radius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 140),
        const SizedBox(height: AppSpacing.sm),
        block(height: 180, radius: 12),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 80),
        const SizedBox(height: AppSpacing.sm),
        block(height: 120, radius: 12),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 100),
        const SizedBox(height: AppSpacing.sm),
        block(height: 120, radius: 12),
      ],
    );
  }
}

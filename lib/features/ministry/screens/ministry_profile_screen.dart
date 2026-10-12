import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/biometric_lock_preference_row.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/detail_header.dart';
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
import '../models/ministry_profile_data.dart';

/// MIN-006 — Ministry Profile, on the shared grouped-list Profile system.
///
/// Approved states (Figma "06/profile" export): Default, Loading, Edit,
/// Validation ("Full name is required."), Success, Error, Offline,
/// Unauthorized.
///
/// Entry and exit are both Ministry Dashboard (reached from the header
/// avatar), so the header is a [DetailHeader] with ordinary Back and no
/// bottom nav. Error/Offline/Unauthorized describe failing to *load* the
/// profile and stay a floating dialog over the dimmed, inert profile shell
/// with a "Back to Safety" action, matching the approved frames.
///
/// Editing is the shared name-only sheet opened from the avatar pencil;
/// the phone is administrator-controlled. [MinistryProfileViewState.edit]
/// and [MinistryProfileViewState.validation] open that sheet on the first
/// frame (Validation with the empty-name error shown). A failed save keeps
/// the sheet open rather than swapping to the load-failure dialog.
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
    this.onAbout,
    this.onLogOut,
    this.profile,
    this.onSaveProfile,
  });

  final MinistryProfileViewState initialState;

  /// Returns to Ministry Dashboard — the spec's only entry and exit point.
  final VoidCallback? onBack;

  final VoidCallback? onNotificationsTap;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;

  /// Fired after the log-out confirmation dialog is accepted.
  final VoidCallback? onLogOut;
  final MinistryProfileData? profile;
  final Future<bool> Function(String fullName)? onSaveProfile;

  @override
  State<MinistryProfileScreen> createState() => _MinistryProfileScreenState();
}

class _MinistryProfileScreenState extends State<MinistryProfileScreen> {
  late MinistryProfileViewState _state = switch (widget.initialState) {
    MinistryProfileViewState.edit ||
    MinistryProfileViewState.validation => MinistryProfileViewState.view,
    final state => state,
  };
  late MinistryProfileData _profile =
      widget.profile ?? MinistryProfileData.mock();

  @override
  void initState() {
    super.initState();
    final preview = widget.initialState;
    if (preview == MinistryProfileViewState.edit ||
        preview == MinistryProfileViewState.validation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startEditing(
            showValidation: preview == MinistryProfileViewState.validation,
          );
        }
      });
    }
  }

  Future<void> _startEditing({bool showValidation = false}) async {
    final saved = await showProfileNameEditSheet(
      context,
      initialName: showValidation ? '' : _profile.name,
      showValidationOnOpen: showValidation,
      onSave: (name) async {
        final ok =
            await (widget.onSaveProfile?.call(name) ??
                Future<bool>.value(true));
        if (ok && mounted) {
          setState(() => _profile = _profile.copyWith(name: name));
        }
        return ok;
      },
    );
    if (!mounted || !saved) return;
    setState(() => _state = MinistryProfileViewState.success);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _state == MinistryProfileViewState.success) {
        setState(() => _state = MinistryProfileViewState.view);
      }
    });
  }

  void _retry() {
    setState(() => _state = MinistryProfileViewState.loading);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
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
    final showDialog =
        _state == MinistryProfileViewState.error ||
        _state == MinistryProfileViewState.offline ||
        _state == MinistryProfileViewState.unauthorized;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _state == MinistryProfileViewState.loading
                ? Padding(
                    padding: EdgeInsets.only(
                      top: DetailHeader.topInset(context),
                    ),
                    child: const _LoadingSkeleton(),
                  )
                : IgnorePointer(
                    ignoring: showDialog,
                    child: ExcludeSemantics(
                      excluding: showDialog,
                      child: _ProfileBody(
                        profile: _profile,
                        showSuccessBanner:
                            _state == MinistryProfileViewState.success,
                        onEdit: _startEditing,
                        onChangePassword: widget.onChangePassword,
                        onAbout: widget.onAbout,
                        onLogOut: _confirmLogOut,
                      ),
                    ),
                  ),
          ),
          if (showDialog) ...[
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.scrimStrong.withValues(alpha: 0.48),
              ),
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
                        'Unable to load profile data. This could be due to a '
                        'temporary network issue or server maintenance.',
                    primaryActionLabel: 'Retry',
                    onPrimaryAction: _retry,
                    secondaryActionLabel: 'Back to Safety',
                    onSecondaryAction: widget.onBack,
                    bordered: true,
                  ),
                  MinistryProfileViewState.offline => AppStateMessage(
                    icon: AppIcons.offline,
                    badgeColor: AppColors.error,
                    title: "You're offline",
                    message:
                        'Check your connection and retry loading profile '
                        'data.',
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
                        'You can only view and edit your own ministry '
                        'profile.',
                    secondaryActionLabel: 'Back to Safety',
                    onSecondaryAction: widget.onBack,
                    bordered: true,
                  ),
                },
              ),
            ),
          ],
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'My Profile',
              onBack: widget.onBack,
              trailing: SizedBox(
                width: AppDimensions.controlHeightStandard,
                height: AppDimensions.controlHeightStandard,
                child: Material(
                  type: MaterialType.transparency,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppComponentRadius.card,
                  ),
                  child: InkWell(
                    borderRadius: AppComponentRadius.card,
                    onTap: widget.onNotificationsTap,
                    child: const Tooltip(
                      message: 'Notifications',
                      child: Icon(AppIcons.notifications, size: AppIconSize.md),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    this.showSuccessBanner = false,
    this.onEdit,
    this.onChangePassword,
    this.onAbout,
    this.onLogOut,
  });

  final MinistryProfileData profile;
  final bool showSuccessBanner;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;
  final VoidCallback? onLogOut;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        DetailHeader.topInset(context) + AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.md,
      ),
      children: [
        if (showSuccessBanner) ...[
          const ProfileStatusBanner(
            tone: ProfileBannerTone.success,
            title: 'Profile updated',
            message: 'Your profile changes were saved successfully.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ProfileHeaderCard(
          name: profile.name,
          subtitle: profile.ministry,
          pills: [profile.role],
          onEdit: onEdit,
        ),
        ProfileSection(
          trailing: ProfileInfoButton(
            title: 'Account Access',
            message:
                'Permissions are managed by administrators for this account:',
            items: profile.metadataBadges,
          ),
          children: [
            ProfileFieldRow(label: 'Phone number', value: profile.phone),
            ProfileFieldRow(
              label: 'Supervisor ID',
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

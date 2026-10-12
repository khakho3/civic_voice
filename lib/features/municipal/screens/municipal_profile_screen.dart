import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
import '../models/officer_profile.dart';
import '../widgets/municipal_detail_header.dart';

/// MUN-009 — Municipal Profile, on the shared grouped-list Profile system.
///
/// Approved states (Figma "09 - Profile" section): Default, Editing,
/// Loading, Success, Error, Offline.
///
/// Editing happens in the shared name-only sheet opened from the avatar
/// pencil: Full Name is the only self-editable field. Phone, Officer ID,
/// Assembly and Region are administrator-provisioned and stay read-only.
/// [MunicipalProfileViewState.editing] and [MunicipalProfileViewState.error]
/// remain as preview entry points: they open that sheet on the first frame
/// (Error with the blank-name validation already shown), so the approved
/// frames stay reachable without a second, inline editor. A failed save
/// keeps the sheet open with the entered name.
enum MunicipalProfileViewState {
  loading,
  loaded,
  editing,
  error,
  success,
  offline,
}

class MunicipalProfileScreen extends StatefulWidget {
  const MunicipalProfileScreen({
    super.key,
    this.initialState = MunicipalProfileViewState.loaded,
    this.onBack,
    this.onChangePassword,
    this.onAbout,
    this.onLogOut,
    this.initialProfile,
    this.onSaveProfile,
  });

  final MunicipalProfileViewState initialState;

  /// Pops one level — wired to the header's back arrow.
  final VoidCallback? onBack;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;

  /// Fired after the log-out confirmation dialog is accepted.
  final VoidCallback? onLogOut;
  final OfficerProfile? initialProfile;
  final Future<bool> Function(String fullName)? onSaveProfile;

  @override
  State<MunicipalProfileScreen> createState() => _MunicipalProfileScreenState();
}

class _MunicipalProfileScreenState extends State<MunicipalProfileScreen> {
  late MunicipalProfileViewState _state = switch (widget.initialState) {
    MunicipalProfileViewState.editing ||
    MunicipalProfileViewState.error => MunicipalProfileViewState.loaded,
    final state => state,
  };
  late OfficerProfile _profile = widget.initialProfile ?? OfficerProfile.mock();

  @override
  void initState() {
    super.initState();
    final previewEdit = widget.initialState;
    if (previewEdit == MunicipalProfileViewState.editing ||
        previewEdit == MunicipalProfileViewState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startEditing(
            showValidation: previewEdit == MunicipalProfileViewState.error,
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
    setState(() => _state = MunicipalProfileViewState.success);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _state == MunicipalProfileViewState.success) {
        setState(() => _state = MunicipalProfileViewState.loaded);
      }
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to sign back in to access the municipal console.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onLogOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _state == MunicipalProfileViewState.loading
                ? Padding(
                    padding: EdgeInsets.only(
                      top: MunicipalDetailHeader.topInset(context),
                    ),
                    child: const _LoadingSkeleton(),
                  )
                : _ProfileView(
                    profile: _profile,
                    state: _state,
                    onEdit: _startEditing,
                    onChangePassword: widget.onChangePassword,
                    onAbout: widget.onAbout,
                    onLogOut: _confirmLogOut,
                  ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: 'Municipal Profile',
              referenceId: _profile.employeeId,
              subtitlePrefix: 'ID ',
              onBack: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.profile,
    required this.state,
    this.onEdit,
    this.onChangePassword,
    this.onAbout,
    this.onLogOut,
  });

  final OfficerProfile profile;
  final MunicipalProfileViewState state;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;
  final VoidCallback? onLogOut;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MunicipalDetailHeader.topInset(context) + AppSpacing.md,
        AppSpacing.md,
        padding.bottom + AppSpacing.md,
      ),
      children: [
        if (state == MunicipalProfileViewState.offline) ...[
          const ProfileStatusBanner(
            tone: ProfileBannerTone.warning,
            title: "You're offline",
            message: "Profile changes can't be saved until you reconnect.",
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state == MunicipalProfileViewState.success) ...[
          const ProfileStatusBanner(
            tone: ProfileBannerTone.success,
            title: 'Profile saved successfully',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ProfileHeaderCard(
          name: profile.name,
          subtitle: profile.role,
          pills: [if (profile.verifiedOfficial) 'Verified Official'],
          onEdit: onEdit,
        ),
        ProfileSection(
          title: 'Account',
          children: [
            ProfileFieldRow(label: 'Phone number', value: profile.phone),
            ProfileFieldRow(
              label: 'Officer ID',
              value: profile.employeeId,
              locked: true,
            ),
            ProfileFieldRow(label: 'Assembly', value: profile.department),
            ProfileFieldRow(label: 'Region', value: profile.region),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(child: block(width: 80, height: 80, radius: 40)),
        const SizedBox(height: AppSpacing.md),
        Center(child: block(width: 160, height: 20)),
        const SizedBox(height: AppSpacing.sm),
        Center(child: block(width: 200, height: 14)),
        const SizedBox(height: AppSpacing.xl),
        block(height: 160, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 120, radius: 12),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/biometric_lock_preference_row.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_edit_action_bar.dart';
import '../../../widgets/profile_edit_button.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/profile_session_section.dart';
import '../../../widgets/theme_preference_row.dart';
import '../models/citizen_profile.dart';
import '../services/profile_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import '../widgets/nearby_seconding_preference_row.dart';
import 'citizen_tab_routes.dart';

/// CIT-006 — Citizen Profile.
///
/// Re-platformed onto the same shared profile widget library every other
/// module now uses (`ProfileHeaderCard`/`ProfileSection`/`ProfileFieldRow`/
/// `ProfileEditActionBar`) — this screen used to run its own parallel
/// design system (`CivicGlassCard`, a bespoke edit action bar, a large
/// "Edit Profile" `FilledButton`), which is what "sudoku"-clutter and the
/// oversized edit affordance both trace back to on this specific screen.
class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({
    super.key,
    this.onAbout,
    this.onRegister,
    this.onLogOut,
  });

  static const String routeName = '/citizen/profile';

  final VoidCallback? onAbout;
  final VoidCallback? onRegister;

  /// Fired after the sign-out confirmation dialog is accepted. Nullable:
  /// there's no real auth session to end yet.
  final VoidCallback? onLogOut;

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ProfileCrudService _profileCrudService = ProfileCrudService.instance;

  bool _isEditing = false;
  bool _showSaveSuccess = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncControllers(_profileCrudService.profile.value);
    _nameController.addListener(_refreshProfilePreview);
    _profileCrudService.profile.addListener(_syncControllersFromCrud);
  }

  @override
  void dispose() {
    _profileCrudService.profile.removeListener(_syncControllersFromCrud);
    _nameController.removeListener(_refreshProfilePreview);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _refreshProfilePreview() {
    if (mounted) setState(() {});
  }

  void _syncControllersFromCrud() {
    if (_isEditing) return;
    _syncControllers(_profileCrudService.profile.value);
    if (mounted) setState(() {});
  }

  void _syncControllers(CitizenProfile profile) {
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phone;
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _syncControllers(_profileCrudService.profile.value);
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    await _profileCrudService.updateProfile(
      _profileCrudService.profile.value.copyWith(
        fullName: _nameController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _isEditing = false;
      _showSaveSuccess = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSaveSuccess = false);
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to continue as a guest or sign back in.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onLogOut?.call();
  }

  String get _displayName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Citizen' : value;
  }

  void _openDashboard(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      citizenReportsTabRoute(context),
      (route) => route.isFirst,
    );
  }

  void _openCreateReport(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      citizenCreateReportTabRoute(context),
      (route) => route.isFirst,
    );
  }

  void _openAlerts(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      citizenAlertsTabRoute(context),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    final chromeInset = civicContentPadding(context);

    return Scaffold(
      // See create_report_screen.dart's build() for why this is false. This
      // screen also has its own sticky edit Save/Cancel bar at the bottom of
      // the content Column (not the nav) — the extra bottom padding below
      // replaces the room resizeToAvoidBottomInset used to make for it.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        chromeInset.top + AppSpacing.xl,
                        horizontalPadding,
                        _isEditing
                            ? MediaQuery.paddingOf(context).bottom +
                                  AppSpacing.xl
                            : chromeInset.bottom + AppSpacing.xl,
                      ),
                      children: [
                        if (_showSaveSuccess) ...[
                          const _SaveSuccessBanner(),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        ValueListenableBuilder<CitizenProfile>(
                          valueListenable: _profileCrudService.profile,
                          builder: (context, profile, _) {
                            return Column(
                              children: [
                                ProfileHeaderCard(
                                  name: _displayName,
                                  subtitle: profile.isGuest
                                      ? 'Browsing as guest'
                                      : 'Verified citizen',
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ProfileSection(
                                  icon: AppIcons.profile,
                                  title: 'Personal Information',
                                  trailing: _isEditing
                                      ? null
                                      : profile.isGuest
                                      ? TextButton(
                                          onPressed: widget.onRegister,
                                          child: const Text('Create Account'),
                                        )
                                      : ProfileEditButton(
                                          onPressed: _startEditing,
                                        ),
                                  children: [
                                    ProfileFieldRow(
                                      label: 'Full Name',
                                      controller: _nameController,
                                      editable: _isEditing,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    ProfileFieldRow(
                                      label: 'Phone Number',
                                      controller: _phoneController,
                                      editable: false,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const ProfileSection(
                                  icon: AppIcons.systemTheme,
                                  title: 'System Preferences',
                                  children: [
                                    ThemePreferenceRow(),
                                    Divider(height: AppSpacing.lg),
                                    LanguagePreferenceRow(),
                                    Divider(height: AppSpacing.lg),
                                    NearbySecondingPreferenceRow(),
                                    Divider(height: AppSpacing.lg),
                                    BiometricLockPreferenceRow(),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ProfileSection(
                                  icon: AppIcons.info,
                                  title: 'About',
                                  children: [
                                    ProfileActionRow(
                                      icon: AppIcons.info,
                                      label: 'About CivicVoice',
                                      onTap: widget.onAbout,
                                    ),
                                  ],
                                ),
                                if (!_isEditing) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  ProfileSessionSection(
                                    onLogOut: _confirmLogOut,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    ProfileEditActionBar(
                      onSave: _saveProfile,
                      onCancel: _cancelEditing,
                      saving: _saving,
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            // No onBack — this is a bottom-nav destination (index 4), not a
            // drill-down, matching every other primary tab in the module.
            // Exiting edit mode goes through the Cancel button in the edit
            // action bar below, not a header back arrow.
            child: CivicTopBar(
              title: _isEditing ? 'Edit Profile' : 'Profile',
              showNotifications: false,
            ),
          ),
          if (!_isEditing && !keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 4,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    _openDashboard(context);
                  } else if (index == 1) {
                    _openReports(context);
                  } else if (index == 2) {
                    _openCreateReport(context);
                  } else if (index == 3) {
                    _openAlerts(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SaveSuccessBanner extends StatelessWidget {
  const _SaveSuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.allLg,
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.success,
            size: AppIconSize.sm,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Profile saved successfully',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

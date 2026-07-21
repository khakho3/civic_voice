import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/glass_dialog_backdrop.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_edit_action_bar.dart';
import '../../../widgets/profile_edit_button.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/theme_preference_row.dart';
import '../models/citizen_profile.dart';
import '../services/profile_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';

enum _PhotoSheetAction { camera, gallery, remove }

/// CIT-006 — Citizen Profile.
///
/// Re-platformed onto the same shared profile widget library every other
/// module now uses (`ProfileHeaderCard`/`ProfileSection`/`ProfileFieldRow`/
/// `ProfileEditActionBar`) — this screen used to run its own parallel
/// design system (`CivicGlassCard`, a bespoke edit action bar, a large
/// "Edit Profile" `FilledButton`), which is what "sudoku"-clutter and the
/// oversized edit affordance both trace back to on this specific screen.
/// The real photo picker stays — `ProfileHeaderCard` gained real
/// photo/loading-spinner support specifically for this migration.
class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key, this.onLogOut});

  static const String routeName = '/citizen/profile';

  /// Fired after the sign-out confirmation dialog is accepted. Nullable:
  /// there's no real auth session to end yet.
  final VoidCallback? onLogOut;

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ProfileCrudService _profileCrudService = ProfileCrudService.instance;

  bool _isEditing = false;
  bool _photoUpdating = false;
  bool _showSaveSuccess = false;

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
    await _profileCrudService.updateProfile(
      _profileCrudService.profile.value.copyWith(
        fullName: _nameController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
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

  Future<void> _chooseProfilePhoto() async {
    final action = await showModalBottomSheet<_PhotoSheetAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return GlassDialogBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profile picture',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_PhotoSheetAction.camera),
                    icon: const Icon(AppIcons.camera),
                    label: const Text('Take Photo'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_PhotoSheetAction.gallery),
                    icon: const Icon(AppIcons.upload),
                    label: const Text('Choose from Gallery'),
                  ),
                  if (_profileCrudService.profile.value.photoPath != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_PhotoSheetAction.remove),
                      icon: const Icon(AppIcons.close, color: AppColors.error),
                      label: const Text(
                        'Remove Photo',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == _PhotoSheetAction.remove) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Remove profile photo?',
        message: 'Your profile will show your initials instead.',
        confirmLabel: 'Remove',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
      await _profileCrudService.updateProfilePhoto(null);
      return;
    }

    setState(() => _photoUpdating = true);
    try {
      final pickedPhoto = await _imagePicker.pickImage(
        source: action == _PhotoSheetAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 900,
      );
      if (!mounted || pickedPhoto == null) return;
      await _profileCrudService.updateProfilePhoto(pickedPhoto.path);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add profile picture.')),
      );
    } finally {
      if (mounted) setState(() => _photoUpdating = false);
    }
  }

  String get _displayName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Citizen' : value;
  }

  void _openDashboard(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenReportsScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openCreateReport(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CreateReportScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openAlerts(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenAlertsScreen.routeName,
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
                                  photoPath: profile.photoPath,
                                  photoUpdating: _photoUpdating,
                                  onEditPhoto: _chooseProfilePhoto,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ProfileSection(
                                  icon: AppIcons.profile,
                                  title: 'Personal Information',
                                  trailing: _isEditing
                                      ? null
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
                                  ],
                                ),
                                if (!_isEditing) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  ProfileSection(
                                    icon: AppIcons.shield,
                                    title: 'Session',
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: _confirmLogOut,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: BorderSide(
                                              color: AppColors.error.withValues(
                                                alpha: 0.4,
                                              ),
                                            ),
                                          ),
                                          child: const Text('Log Out'),
                                        ),
                                      ),
                                    ],
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
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(
              title: _isEditing ? 'Edit Profile' : 'Profile',
              showNotifications: false,
              onBack: () => _openDashboard(context),
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../widgets/confirm_dialog.dart';
import '../widgets/civic_glass_card.dart';
import '../models/citizen_profile.dart';
import '../services/profile_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';

enum _PhotoSheetAction { camera, gallery, remove }

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
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
    _locationController.addListener(_refreshProfilePreview);
    _profileCrudService.profile.addListener(_syncControllersFromCrud);
  }

  @override
  void dispose() {
    _profileCrudService.profile.removeListener(_syncControllersFromCrud);
    _nameController.removeListener(_refreshProfilePreview);
    _locationController.removeListener(_refreshProfilePreview);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
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
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _locationController.text = profile.primaryLocation;
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
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        primaryLocation: _locationController.text.trim(),
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
        return SafeArea(
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

  String get _wardLabel {
    final location = _locationController.text.trim();
    if (location.isEmpty) return 'Verified citizen';
    return 'Verified citizen - $location';
  }

  String get _initials {
    final words = _displayName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'CV';
    final first = words.first[0];
    final second = words.length > 1 ? words.last[0] : '';
    return '$first$second'.toUpperCase();
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
                                _ProfileIdentity(
                                  displayName: _displayName,
                                  subtitle: _wardLabel,
                                  initials: _initials,
                                  photoPath: profile.photoPath,
                                  isEditing: _isEditing,
                                  photoUpdating: _photoUpdating,
                                  onChoosePhoto: _chooseProfilePhoto,
                                  onEditProfile: _startEditing,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _PersonalInformationCard(
                                  isEditing: _isEditing,
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  phoneController: _phoneController,
                                  locationController: _locationController,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _SecurityCard(
                                  twoStepEnabled: profile.twoStepEnabled,
                                  onTwoStepChanged: (enabled) {
                                    _profileCrudService.updateTwoStep(enabled);
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const _AppearanceCard(),
                                if (!_isEditing) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  _LogOutCard(onLogOut: _confirmLogOut),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    _ProfileEditActionBar(
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

class _ProfileEditActionBar extends StatelessWidget {
  const _ProfileEditActionBar({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: semantic.glassSurface,
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSave,
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.displayName,
    required this.subtitle,
    required this.initials,
    required this.photoPath,
    required this.isEditing,
    required this.photoUpdating,
    required this.onChoosePhoto,
    required this.onEditProfile,
  });

  final String displayName;
  final String subtitle;
  final String initials;
  final String? photoPath;
  final bool isEditing;
  final bool photoUpdating;
  final VoidCallback onChoosePhoto;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: photoPath == null
                  ? Text(
                      initials,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: AppFontWeight.bold,
                      ),
                    )
                  : Image.file(
                      File(photoPath!),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
            ),
            if (photoUpdating)
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Tooltip(
                message: 'Change profile picture',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: photoUpdating ? null : onChoosePhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      AppIcons.camera,
                      color: Colors.white,
                      size: AppIconSize.sm,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        if (!isEditing) ...[
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;

              return FilledButton(
                onPressed: onEditProfile,
                style: FilledButton.styleFrom(
                  minimumSize: Size(compact ? 104 : 116, 42),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.md : AppSpacing.lg,
                  ),
                ),
                child: const Text('Edit Profile'),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PersonalInformationCard extends StatelessWidget {
  const _PersonalInformationCard({
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.locationController,
  });

  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileInfoField(
            icon: AppIcons.profile,
            label: 'Full name',
            controller: nameController,
            isEditing: isEditing,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileInfoField(
            icon: AppIcons.email,
            label: 'Email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            isEditing: isEditing,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileInfoField(
            icon: AppIcons.phone,
            label: 'Phone',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            isEditing: isEditing,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileInfoField(
            icon: AppIcons.location,
            label: 'Primary location',
            controller: locationController,
            isEditing: isEditing,
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoField extends StatelessWidget {
  const _ProfileInfoField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.isEditing,
    this.keyboardType,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.allXl,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIconSize.md,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: AppFontWeight.semiBold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        controller.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: AppFontWeight.semiBold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.twoStepEnabled,
    required this.onTwoStepChanged,
  });

  final bool twoStepEnabled;
  final ValueChanged<bool> onTwoStepChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SecurityRow(
            icon: AppIcons.password,
            title: 'Password',
            subtitle: 'Last changed 28 days ago',
            trailing: TextButton(onPressed: () {}, child: const Text('Manage')),
          ),
          const SizedBox(height: AppSpacing.md),
          _SecurityRow(
            icon: AppIcons.permissionDenied,
            title: 'Two-step verification',
            subtitle: 'Recommended for account safety',
            trailing: Switch(
              value: twoStepEnabled,
              onChanged: onTwoStepChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 315;

        final leadingContent = Row(
          children: [
            Container(
              width: AppIconSize.xl,
              height: AppIconSize.xl,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.allLg,
              ),
              child: Icon(icon, color: AppColors.primary, size: AppIconSize.md),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: stacked
              ? Column(
                  children: [
                    leadingContent,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: leadingContent),
                    const SizedBox(width: AppSpacing.sm),
                    FittedBox(fit: BoxFit.scaleDown, child: trailing),
                  ],
                ),
        );
      },
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, mode, _) {
          final darkMode = mode == ThemeMode.dark;

          return LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 300;
              final info = Row(
                children: [
                  AnimatedContainer(
                    duration: AppMotion.duration(
                      context,
                      AppMotionDuration.standard,
                    ),
                    curve: AppMotionCurve.standard,
                    width: AppIconSize.xl,
                    height: AppIconSize.xl,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: darkMode ? 0.16 : 0.1,
                      ),
                      borderRadius: AppRadius.allLg,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.duration(
                        context,
                        AppMotionDuration.standard,
                      ),
                      switchInCurve: AppMotionCurve.decelerate,
                      switchOutCurve: AppMotionCurve.accelerate,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        darkMode ? AppIcons.moon : AppIcons.sun,
                        key: ValueKey<bool>(darkMode),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AnimatedSwitcher(
                          duration: AppMotion.duration(
                            context,
                            AppMotionDuration.standard,
                          ),
                          switchInCurve: AppMotionCurve.decelerate,
                          switchOutCurve: AppMotionCurve.accelerate,
                          child: Text(
                            darkMode ? 'Dark mode' : 'Light mode',
                            key: ValueKey<bool>(darkMode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final toggle = Switch(
                value: darkMode,
                onChanged: ThemeController.setDarkMode,
              );

              if (stacked) {
                return Column(
                  children: [
                    info,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: toggle),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: AppSpacing.sm),
                  toggle,
                ],
              );
            },
          );
        },
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

class _LogOutCard extends StatelessWidget {
  const _LogOutCard({required this.onLogOut});

  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onLogOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}

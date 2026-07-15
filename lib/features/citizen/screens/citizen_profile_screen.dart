import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../widgets/civic_glass_card.dart';
import '../models/civic_report.dart';
import '../models/citizen_profile.dart';
import '../services/profile_crud_service.dart';
import '../services/report_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  static const String routeName = '/citizen/profile';

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
  final ReportCrudService _reportCrudService = ReportCrudService.instance;

  bool _isEditing = false;

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
    setState(() => _isEditing = false);
  }

  Future<void> _chooseProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
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
                  onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                  icon: const Icon(AppIcons.camera),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(ImageSource.gallery),
                  icon: const Icon(AppIcons.imageUnavailable),
                  label: const Text('Choose from Gallery'),
                ),
                if (_profileCrudService.profile.value.photoPath != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _profileCrudService.updateProfilePhoto(null);
                    },
                    icon: const Icon(AppIcons.close),
                    label: const Text('Use Initials Instead'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final pickedPhoto = await _imagePicker.pickImage(
        source: source,
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

    return Scaffold(
      extendBody: true,
      appBar: _ProfileTopBar(
        isEditing: _isEditing,
        onBack: () => _openDashboard(context),
        onEdit: _startEditing,
        onSave: _saveProfile,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.xl,
            horizontalPadding,
            132,
          ),
          children: [
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
                      onChoosePhoto: _chooseProfilePhoto,
                      onEditProfile: _startEditing,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ValueListenableBuilder<List<CivicReport>>(
                      valueListenable: _reportCrudService.reports,
                      builder: (context, reports, _) {
                        return _ProfileStatsGrid(reports: reports);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CivicBottomNav(
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
    );
  }
}

class _ProfileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileTopBar({
    required this.isEditing,
    required this.onBack,
    required this.onEdit,
    required this.onSave,
  });

  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: theme.extension<AppSemanticColors>()!.glassSurface,
      elevation: AppElevation.level1,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(AppIcons.back),
      ),
      centerTitle: true,
      title: Text(
        'Profile',
        style: theme.textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: AppFontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          tooltip: isEditing ? 'Save profile' : 'Edit profile',
          onPressed: isEditing ? onSave : onEdit,
          icon: Icon(isEditing ? AppIcons.success : AppIcons.edit),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
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
    required this.onChoosePhoto,
    required this.onEditProfile,
  });

  final String displayName;
  final String subtitle;
  final String initials;
  final String? photoPath;
  final bool isEditing;
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
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.26),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
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
            Positioned(
              right: 0,
              bottom: 2,
              child: Tooltip(
                message: 'Add profile picture',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onChoosePhoto,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      AppIcons.add,
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
              child: Text(isEditing ? 'Editing' : 'Edit Profile'),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileStatsGrid extends StatelessWidget {
  const _ProfileStatsGrid({required this.reports});

  final List<CivicReport> reports;

  @override
  Widget build(BuildContext context) {
    final resolvedCount = reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;
    final activeCount = reports
        .where((report) => report.status != ReportStatus.resolved)
        .length;
    final civicScore = reports.isEmpty
        ? '0.0'
        : (4 + (resolvedCount / reports.length)).clamp(0, 5).toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final spacing = compact ? AppSpacing.sm : AppSpacing.md;

        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: compact ? 1.42 : 1.62,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ProfileStatCard(
              label: 'REPORTS',
              value: reports.length.toString(),
              subtitle: 'Submitted',
            ),
            _ProfileStatCard(
              label: 'RESOLVED',
              value: resolvedCount.toString(),
              subtitle: 'Closed',
            ),
            _ProfileStatCard(
              label: 'ACTIVE',
              value: activeCount.toString(),
              subtitle: 'In progress',
            ),
            _ProfileStatCard(
              label: 'RATING',
              value: civicScore,
              subtitle: 'Civic score',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
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
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Manage'),
            ),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: trailing,
                    ),
                  ],
                )
              : Row(
              children: [
                    Expanded(child: leadingContent),
                    const SizedBox(width: AppSpacing.sm),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: trailing,
                    ),
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

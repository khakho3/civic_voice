import 'dart:async';
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
import '../../../widgets/trust_standing.dart';
import '../models/citizen_profile.dart';
import '../services/profile_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import '../widgets/nearby_seconding_preference_row.dart';
import 'citizen_tab_routes.dart';

/// CIT-006 — Citizen Profile, on the shared grouped-list Profile system.
///
/// Registered: identity hero with the avatar edit pencil (name-only sheet),
/// reporting standing directly below when the server supplied one, phone,
/// preferences, About, and Log out. Guest: an explicit Guest identity with
/// no edit, phone or standing, a Create Account callout explaining that
/// reports carry over, App Lock unavailable, and guest-accurate logout copy.
class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({
    super.key,
    this.onAbout,
    this.onRegister,
    this.onLogOut,
    this.standing,
  });

  static const String routeName = '/citizen/profile';

  final VoidCallback? onAbout;
  final VoidCallback? onRegister;

  /// Fired after the sign-out confirmation dialog is accepted.
  final VoidCallback? onLogOut;

  /// Optional presentation override. Live routes read the account-bound
  /// profile's server standing; guests always omit it.
  final TrustStandingData? standing;

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen>
    with WidgetsBindingObserver {
  final ProfileCrudService _profileCrudService = ProfileCrudService.instance;

  bool _showSaveSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_profileCrudService.refreshStanding());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_profileCrudService.refreshStanding());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startEditing(CitizenProfile profile) async {
    final saved = await showProfileNameEditSheet(
      context,
      initialName: profile.fullName,
      onSave: (name) async {
        // Re-read at save time so a newer profile published while the sheet
        // was open is not overwritten with stale fields.
        final current = _profileCrudService.profile.value;
        await _profileCrudService.updateProfile(
          current.copyWith(fullName: name),
        );
        return true;
      },
    );
    if (!mounted || !saved) return;
    setState(() => _showSaveSuccess = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSaveSuccess = false);
    });
  }

  Future<void> _confirmLogOut(bool guest) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: guest
          ? "You'll need to create an account or continue as a guest to "
                'report and track issues again.'
          : "You'll need to continue as a guest or sign back in.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onLogOut?.call();
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
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final chromeInset = civicContentPadding(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<CitizenProfile>(
              valueListenable: _profileCrudService.profile,
              builder: (context, profile, _) {
                final guest = profile.isGuest;
                final standing = guest
                    ? null
                    : widget.standing ?? profile.trustRating;
                return ListView(
                  // One 16px inset each side and one 16px visible gap above
                  // the bottom navigation.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    chromeInset.top + AppSpacing.md,
                    AppSpacing.md,
                    chromeInset.bottom + AppSpacing.md,
                  ),
                  children: [
                    if (_showSaveSuccess) ...[
                      const ProfileStatusBanner(
                        tone: ProfileBannerTone.success,
                        title: 'Profile saved successfully',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    ProfileHeaderCard(
                      name: guest
                          ? 'Guest'
                          : (profile.fullName.isEmpty
                                ? 'Citizen'
                                : profile.fullName),
                      subtitle: guest ? 'Browsing as guest' : null,
                      pills: [guest ? 'Guest' : 'Verified citizen'],
                      onEdit: guest ? null : () => _startEditing(profile),
                    ),
                    if (guest) ...[
                      _GuestAccountCallout(onRegister: widget.onRegister),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (standing != null) ...[
                      ProfileSection(
                        title: 'Your reporting standing',
                        children: [
                          Padding(
                            padding: ProfileRowMetrics.padding.copyWith(
                              top: AppSpacing.md,
                              bottom: AppSpacing.md,
                            ),
                            child: TrustStanding(
                              standing: standing,
                              variant: TrustStandingVariant.detailed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (!guest) ...[
                      ProfileSection(
                        children: [
                          ProfileFieldRow(
                            label: 'Phone number',
                            value: profile.phone.isEmpty
                                ? 'Not provided'
                                : profile.phone,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    ProfileSection(
                      title: 'Preferences',
                      children: [
                        const ThemePreferenceRow(),
                        const HapticsPreferenceRow(),
                        const LanguagePreferenceRow(),
                        const NearbySecondingPreferenceRow(),
                        BiometricLockPreferenceRow(guest: guest),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileSection(
                      children: [
                        ProfileActionRow(
                          icon: AppIcons.info,
                          label: 'About CivicVoice',
                          onTap: widget.onAbout,
                        ),
                      ],
                    ),
                    ProfileSessionSection(
                      onLogOut: () => _confirmLogOut(guest),
                    ),
                  ],
                );
              },
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            // A bottom-nav destination (index 4), not a drill-down: no Back.
            child: CivicTopBar(title: 'Profile', showNotifications: false),
          ),
          if (!keyboardVisible)
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

/// Guest-only Create Account callout: explains that this session's reports
/// carry over to the new account and that standing starts counting.
class _GuestAccountCallout extends StatelessWidget {
  const _GuestAccountCallout({required this.onRegister});

  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ProfileGroupTile(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Keep your reports with you',
                style: textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Create a free account so reports from this guest session stay '
              'tied to you across devices — and so your reporting standing '
              'starts counting.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRegister,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

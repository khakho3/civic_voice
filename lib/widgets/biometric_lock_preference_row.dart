import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_cache_service.dart';
import '../services/biometric_auth_service.dart';
import 'busy_indicator.dart';
import 'profile_preference_row.dart';

typedef BiometricAvailabilityChecker = Future<BiometricAvailability> Function();
typedef BiometricAuthenticator = Future<BiometricAuthResult> Function();

/// App Lock preference (P03) with the real native biometric gate: turning
/// it on requires a successful biometric check first, and the row reflects
/// the device's actual state — checking, enabled/off, not enrolled, or
/// unavailable. [guest] sessions always show it off and disabled ("Unavailable
/// for guests") regardless of device capability, since there is no account
/// to lock.
class BiometricLockPreferenceRow extends StatefulWidget {
  const BiometricLockPreferenceRow({
    super.key,
    this.checkAvailability,
    this.authenticate,
    this.guest = false,
  });

  final BiometricAvailabilityChecker? checkAvailability;
  final BiometricAuthenticator? authenticate;
  final bool guest;

  @override
  State<BiometricLockPreferenceRow> createState() =>
      _BiometricLockPreferenceRowState();
}

class _BiometricLockPreferenceRowState
    extends State<BiometricLockPreferenceRow> {
  bool _enabled = false;
  bool _loadingAvailability = true;
  bool _verifying = false;
  BiometricAvailability _availability = BiometricAvailability.noHardware;

  @override
  void initState() {
    super.initState();
    _enabled = AppCacheService.instance.biometricLockEnabled;
    if (!widget.guest) _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final availability =
        await (widget.checkAvailability ??
            BiometricAuthService.instance.checkAvailability)();
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _loadingAvailability = false;
      if (availability != BiometricAvailability.available && _enabled) {
        _enabled = false;
        unawaited(AppCacheService.instance.setBiometricLockEnabled(false));
      }
    });
  }

  Future<void> _setEnabled(bool value) async {
    if (!value) {
      setState(() => _enabled = false);
      await AppCacheService.instance.setBiometricLockEnabled(false);
      return;
    }

    setState(() => _verifying = true);
    final result =
        await (widget.authenticate ??
            BiometricAuthService.instance.authenticate)();
    if (result.successful) {
      await AppCacheService.instance.setBiometricLockEnabled(true);
    }
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _enabled = result.successful;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.guest) {
      return const ProfileSwitchRow(
        icon: AppIcons.biometricLock,
        label: 'App Lock',
        caption: 'Unavailable for guests',
        value: false,
        onChanged: null,
      );
    }

    if (!_loadingAvailability &&
        _availability != BiometricAvailability.available) {
      final colorScheme = Theme.of(context).colorScheme;
      return ProfilePreferenceRow(
        icon: AppIcons.biometricLock,
        label: 'App Lock',
        enabled: false,
        trailing: Text(
          _availability == BiometricAvailability.notEnrolled
              ? 'Biometrics not set up'
              : 'Unavailable',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final busy = _loadingAvailability || _verifying;
    return ProfileSwitchRow(
      icon: AppIcons.biometricLock,
      label: 'App Lock',
      value: _enabled,
      onChanged: busy ? null : _setEnabled,
      // Only the user-initiated verification shows the busy orb; the quiet
      // availability check on open just keeps the switch disabled.
      labelTrailing: _verifying
          ? const BusyIndicator(
              size: AppIconSize.sm,
              semanticsLabel: 'Verifying biometrics',
            )
          : null,
    );
  }
}

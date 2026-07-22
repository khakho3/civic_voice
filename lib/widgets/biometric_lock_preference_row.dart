import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_cache_service.dart';
import '../services/biometric_auth_service.dart';

typedef BiometricAvailabilityChecker = Future<BiometricAvailability> Function();
typedef BiometricAuthenticator = Future<BiometricAuthResult> Function();

class BiometricLockPreferenceRow extends StatefulWidget {
  const BiometricLockPreferenceRow({
    super.key,
    this.checkAvailability,
    this.authenticate,
  });

  final BiometricAvailabilityChecker? checkAvailability;
  final BiometricAuthenticator? authenticate;

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
    _loadAvailability();
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (!_loadingAvailability &&
        _availability != BiometricAvailability.available) {
      return Row(
        children: [
          Flexible(
            child: Text(
              'App Lock',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              _availability == BiometricAvailability.notEnrolled
                  ? 'Biometrics not set up'
                  : 'Unavailable',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _enabled,
        onChanged: _loadingAvailability || _verifying ? null : _setEnabled,
        title: Text('App Lock', style: textTheme.bodyLarge),
      ),
    );
  }
}

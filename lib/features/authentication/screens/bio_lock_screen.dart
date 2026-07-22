import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/app_cache_service.dart';
import '../../../services/biometric_auth_service.dart';
import '../widgets/auth_presentation.dart';

class BioLockScreen extends StatefulWidget {
  const BioLockScreen({
    super.key,
    required this.onAuthenticated,
    required this.onLogOut,
  });

  /// Fires on biometric success, or once the screen determines biometrics
  /// are no longer usable on this device. The caller decides what
  /// "unlocked" means.
  final VoidCallback onAuthenticated;

  /// Wired to the app's real shared sign-out path.
  final VoidCallback onLogOut;

  @override
  State<BioLockScreen> createState() => _BioLockScreenState();
}

enum _LockPhase { checkingAvailability, unavailable, prompting, failed }

class _BioLockScreenState extends State<BioLockScreen> {
  _LockPhase _phase = _LockPhase.checkingAvailability;
  BiometricAuthFailureReason _failureReason = BiometricAuthFailureReason.other;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final availability = await BiometricAuthService.instance
        .checkAvailability();
    if (!mounted) return;
    if (availability != BiometricAvailability.available) {
      setState(() => _phase = _LockPhase.unavailable);
      return;
    }
    setState(() => _phase = _LockPhase.prompting);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_phase != _LockPhase.prompting) {
      setState(() => _phase = _LockPhase.prompting);
    }
    final result = await BiometricAuthService.instance.authenticate();
    if (!mounted) return;
    if (result.successful) {
      widget.onAuthenticated();
      return;
    }
    final reason = result.failureReason ?? BiometricAuthFailureReason.other;
    setState(() {
      _failureReason = reason;
      _phase = reason == BiometricAuthFailureReason.unavailable
          ? _LockPhase.unavailable
          : _LockPhase.failed;
    });
  }

  Future<void> _continueWithoutBiometrics() async {
    await AppCacheService.instance.setBiometricLockEnabled(false);
    if (mounted) widget.onAuthenticated();
  }

  String get _failureMessage => switch (_failureReason) {
    BiometricAuthFailureReason.canceled => 'Verification was cancelled.',
    BiometricAuthFailureReason.lockedOut =>
      'Too many attempts. Wait a moment and try again, or log out.',
    BiometricAuthFailureReason.unavailable =>
      'Biometric authentication is no longer available on this device.',
    BiometricAuthFailureReason.other => 'Something went wrong.',
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AuthBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.standardMobile,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthBrandHeader(
                            title: _phase == _LockPhase.prompting
                                ? 'Verify Identity'
                                : 'App Lock',
                            supportingText: _phase == _LockPhase.prompting
                                ? "Confirm it's you to continue using CivicVoice."
                                : 'Protect your CivicVoice account with your device biometrics.',
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _LockContent(
                            phase: _phase,
                            failureMessage: _failureMessage,
                            onContinue: _continueWithoutBiometrics,
                            onRetry: _authenticate,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton.icon(
                            onPressed: widget.onLogOut,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            icon: const Icon(AppIcons.logOut),
                            label: const Text('Log Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockContent extends StatelessWidget {
  const _LockContent({
    required this.phase,
    required this.failureMessage,
    required this.onContinue,
    required this.onRetry,
  });

  final _LockPhase phase;
  final String failureMessage;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return switch (phase) {
      _LockPhase.checkingAvailability => const Center(
        child: CircularProgressIndicator(),
      ),
      _LockPhase.unavailable => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Biometric authentication is no longer available on this device.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
      _LockPhase.prompting => Column(
        children: [
          const Icon(
            AppIcons.biometricLock,
            size: AppIconSize.xl,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Waiting for verification…',
            style: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
          ),
        ],
      ),
      _LockPhase.failed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            failureMessage,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.biometricLock),
            label: const Text('Verify Identity'),
          ),
        ],
      ),
    };
  }
}

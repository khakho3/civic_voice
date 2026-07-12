import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

/// The approved Welcome Screen states.
enum WelcomeViewState { loading, offline }

/// AUTH-002 — CivicVoice Welcome Screen.
///
/// Supports:
/// - Loading state
/// - Offline state
/// - Light theme
/// - Dark theme
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.state = WelcomeViewState.loading,
    this.onLogin,
    this.onRegister,
  });

  final WelcomeViewState state;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  bool get _isOffline => state == WelcomeViewState.offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.standardMobile,
              ),
              child: Column(
                children: [
                  const _WelcomeLogo(),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Welcome to CivicVoice',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    'Report community issues, track progress, and help build '
                    'better communities across Ghana.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const _WelcomeIllustration(),

                  const SizedBox(height: AppSpacing.md),

                  _WelcomeStatePanel(state: state),

                  const SizedBox(height: AppSpacing.lg),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isOffline ? null : onLogin,
                      child: const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isOffline ? null : onRegister,
                      child: const Text('Register'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Only Citizens can create a new account.\n'
                    'Other user roles are created by an administrator.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays the CivicVoice application logo.
class _WelcomeLogo extends StatelessWidget {
  const _WelcomeLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label: 'CivicVoice logo',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: AppRadius.allSm,
        ),
        child: Image.asset(
          AppAssets.logoApp,
          width: AppIconSize.lg,
          height: AppIconSize.lg,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Displays the approved CivicVoice community illustration.
class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label: 'CivicVoice community illustration',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: AppComponentRadius.card,
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset(
            AppAssets.welcomeIllustration,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Displays either the loading or offline state.
class _WelcomeStatePanel extends StatelessWidget {
  const _WelcomeStatePanel({required this.state});

  final WelcomeViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final semanticColors =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    final bool isOffline = state == WelcomeViewState.offline;

    final String title = isOffline
        ? 'You are offline'
        : 'Checking secure session';

    final String message = isOffline
        ? 'Reconnect to continue to CivicVoice.'
        : 'Preparing CivicVoice securely.';

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: AppComponentRadius.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffline)
              Icon(
                AppIcons.offline,
                size: AppIconSize.standard,
                color: semanticColors.warning,
              )
            else
              SizedBox(
                width: AppIconSize.standard,
                height: AppIconSize.standard,
                child: CircularProgressIndicator(
                  strokeWidth: AppSpacing.xs / 2,
                  color: colorScheme.primary,
                ),
              ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: AppFontWeight.semiBold,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

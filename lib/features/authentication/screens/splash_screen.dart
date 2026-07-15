import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

/// The three approved visual states shown in the Stitch Splash Screen design.
enum SplashViewState { loading, error, offline }

/// AUTH-001 — CivicVoice Splash Screen.
///
/// This screen supports:
/// - Loading
/// - Startup error
/// - Offline
/// - Light theme
/// - Dark theme
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.state = SplashViewState.loading});

  final SplashViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.standardMobile,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _CivicVoiceLogo(),

                              const SizedBox(height: AppSpacing.md),

                              Text(
                                'CivicVoice',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xs),

                              Text(
                                'Report. Track. Resolve.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              _SplashStatePanel(state: state),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'VERSION 1.0',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the official CivicVoice in-app logo.
class _CivicVoiceLogo extends StatelessWidget {
  const _CivicVoiceLogo();

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

/// Displays the loading, startup error, or offline message.
class _SplashStatePanel extends StatelessWidget {
  const _SplashStatePanel({required this.state});

  final SplashViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final semanticColors =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    final String title;
    final String message;
    final Color statusColor;
    final IconData? statusIcon;
    final bool showLoadingIndicator;

    if (state == SplashViewState.error) {
      title = 'Startup failure';
      message = 'CivicVoice could not initialize. Try again.';
      statusColor = semanticColors.error;
      statusIcon = AppIcons.warning;
      showLoadingIndicator = false;
    } else if (state == SplashViewState.offline) {
      title = 'You are offline';
      message = 'Reconnect to continue to CivicVoice.';
      statusColor = semanticColors.warning;
      statusIcon = AppIcons.offline;
      showLoadingIndicator = false;
    } else {
      title = 'Checking secure session';
      message = 'Preparing CivicVoice securely.';
      statusColor = colorScheme.primary;
      statusIcon = null;
      showLoadingIndicator = true;
    }

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: AppRadius.allSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoadingIndicator)
              SizedBox(
                width: AppIconSize.md,
                height: AppIconSize.md,
                child: CircularProgressIndicator(
                  strokeWidth: AppSpacing.xs / 2,
                  color: statusColor,
                ),
              )
            else
              Icon(statusIcon, size: AppIconSize.md, color: statusColor),

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

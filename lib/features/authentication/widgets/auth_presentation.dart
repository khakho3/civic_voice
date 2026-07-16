import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

/// Restrained brand atmosphere shared by the input-heavy authentication flow.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -AppSpacing.xxxxl,
            right: -AppSpacing.xxxxl,
            child: _AmbientOrb(
              size: 192,
              color: colors.primary.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -AppSpacing.xxxxl,
            left: -AppSpacing.xxxxl,
            child: _AmbientOrb(
              size: 160,
              color: colors.primary.withValues(alpha: 0.06),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Shared canvas hierarchy: navigation and identity remain outside the form.
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.onBack,
    required this.title,
    required this.supportingText,
    required this.form,
    required this.footer,
  });

  final VoidCallback? onBack;
  final String title;
  final String supportingText;
  final Widget form;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
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
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: onBack,
                            tooltip: 'Go back',
                            icon: const Icon(AppIcons.back),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthBrandHeader(
                          title: title,
                          supportingText: supportingText,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AuthFormSurface(child: form),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.lg),
                        footer,
                      ],
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

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

/// Compact CivicVoice identity used before each authentication headline.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.supportingText,
  });

  final String title;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Semantics(
          image: true,
          label: 'CivicVoice logo',
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: AppRadius.allXl,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.16),
                  blurRadius: AppSpacing.lg,
                  offset: const Offset(0, AppSpacing.sm),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.allXl,
              child: Image.asset(
                AppAssets.iconFlat,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          supportingText,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Opaque, legible form surface with Civic Glass border and elevation tokens.
class AuthFormSurface extends StatelessWidget {
  const AuthFormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: semantic.glassBorder),
        borderRadius: AppRadius.allXl,
        boxShadow: AppShadow.level2,
      ),
      child: child,
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String hintText,
  required IconData prefixIcon,
  String? errorText,
  Widget? suffixIcon,
}) {
  final colors = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: AppRadius.allXl,
    borderSide: BorderSide(color: colors.outlineVariant),
  );

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: colors.onSurfaceVariant),
    suffixIcon: suffixIcon,
    errorText: errorText,
    filled: true,
    fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.48),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.allXl,
      borderSide: BorderSide(color: colors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.allXl,
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.allXl,
      borderSide: BorderSide(color: colors.error, width: 2),
    ),
  );
}

/// Accessible semantic alert used by all authentication view states.
class AuthStatusAlert extends StatelessWidget {
  const AuthStatusAlert({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.statusColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          borderRadius: AppRadius.allLg,
          boxShadow: AppShadow.level1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: statusColor, size: AppIconSize.standard),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.footer,
  });

  final VoidCallback? onBack;
  final String title;
  final String supportingText;
  final Widget form;

  /// Omitted (rather than a `SizedBox.shrink()` placeholder) on screens
  /// with no "go to a different auth screen" link to offer — e.g.
  /// Change Password, reached from an already-authenticated profile
  /// rather than the public onboarding flow.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
              ),
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
                          if (footer != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            footer!,
                          ],
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
          // AppAssets.logoApp, not iconFlat — iconFlat is the launcher
          // icon's flat, opaque source (solid background baked in, meant
          // for that one use), which looked like a boxed-in white square
          // sitting inside this header. logoApp is the transparent mark
          // every module's own header already uses, so this now matches
          // that same clean, unboxed treatment instead of a one-off style.
          child: Image.asset(
            AppAssets.logoApp,
            width: 76,
            height: 76,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
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
        border: Border.all(
          color: semantic.glassBorder.withValues(
            alpha: semantic.glassBorder.a * 0.7,
          ),
        ),
        borderRadius: AppRadius.allXl,
        boxShadow: AppShadow.level1,
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
    borderRadius: AppComponentRadius.inputField,
    borderSide: BorderSide(color: colors.outlineVariant),
  );

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: colors.onSurfaceVariant),
    suffixIcon: suffixIcon,
    errorText: errorText,
    filled: true,
    fillColor: colors.surfaceContainerHighest,
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: AppComponentRadius.inputField,
      borderSide: BorderSide(color: colors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppComponentRadius.inputField,
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppComponentRadius.inputField,
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

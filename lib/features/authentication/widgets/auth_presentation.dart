import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

import 'growing_underline_border.dart';

/// Restrained brand atmosphere shared by the input-heavy authentication flow.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    super.key,
    required this.child,
    this.emphasizeRecoveryGlass = false,
  });

  final Widget child;
  final bool emphasizeRecoveryGlass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    return ColoredBox(
      color: colors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (emphasizeRecoveryGlass) ...[
            Positioned(
              key: const ValueKey('recovery-auth-back-ambient'),
              top: -AppSpacing.xl,
              left: -AppSpacing.xxxxl,
              child: _AmbientOrb(
                size: AppSpacing.xxxxl * 2 + AppSpacing.xl,
                color: colors.primary.withValues(alpha: semantic.glassBorder.a),
              ),
            ),
            Positioned(
              key: const ValueKey('recovery-auth-form-ambient'),
              top: AppSpacing.xxxxl * 4,
              right: -AppSpacing.xxxxl,
              child: _AmbientOrb(
                size: AppSpacing.xxxxl * 3,
                color: colors.primary.withValues(alpha: semantic.glassBorder.a),
              ),
            ),
          ] else ...[
            Positioned(
              top: -AppSpacing.xxxxl,
              right: -AppSpacing.xxxxl,
              child: _AmbientOrb(
                size: AppSpacing.xxxxl * 3,
                color: colors.primary.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              bottom: -AppSpacing.xxxxl,
              left: -AppSpacing.xxxxl,
              child: _AmbientOrb(
                size: AppSpacing.xxxxl * 2 + AppSpacing.xl,
                color: colors.primary.withValues(alpha: 0.06),
              ),
            ),
          ],
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
    this.showIllustrationHero = false,
    this.useRecoveryGlass = false,
  });

  final VoidCallback? onBack;
  final String title;
  final String supportingText;
  final Widget form;
  final bool showIllustrationHero;
  final bool useRecoveryGlass;

  /// Omitted (rather than a `SizedBox.shrink()` placeholder) on screens
  /// with no "go to a different auth screen" link to offer — e.g.
  /// Change Password, reached from an already-authenticated profile
  /// rather than the public onboarding flow.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: showIllustrationHero
          ? _IllustrationAuthLayout(
              onBack: onBack,
              title: title,
              supportingText: supportingText,
              form: form,
              footer: footer,
            )
          : AuthBackdrop(
              emphasizeRecoveryGlass: useRecoveryGlass,
              child: _StandardAuthLayout(
                onBack: onBack,
                title: title,
                supportingText: supportingText,
                form: form,
                footer: footer,
                useRecoveryGlass: useRecoveryGlass,
              ),
            ),
    );
  }
}

class _StandardAuthLayout extends StatelessWidget {
  const _StandardAuthLayout({
    required this.onBack,
    required this.title,
    required this.supportingText,
    required this.form,
    required this.footer,
    required this.useRecoveryGlass,
  });

  final VoidCallback? onBack;
  final String title;
  final String supportingText;
  final Widget form;
  final Widget? footer;
  final bool useRecoveryGlass;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                        child: useRecoveryGlass
                            ? RecoveryAuthBackButton(onPressed: onBack)
                            : IconButton(
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
                      if (useRecoveryGlass)
                        RecoveryAuthFormSurface(child: form)
                      else
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
    );
  }
}

class _IllustrationAuthLayout extends StatelessWidget {
  const _IllustrationAuthLayout({
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
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final restingSheetTop = mediaQuery.size.height * 3 / 8;
    final minimumSheetTop =
        mediaQuery.padding.top +
        AppDimensions.controlHeightStandard +
        AppSpacing.xxl;
    final sheetTop = math.min(
      restingSheetTop,
      math.max(minimumSheetTop, restingSheetTop - mediaQuery.viewInsets.bottom),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AuthIllustrationHero(),
          Positioned.fill(
            child: AnimatedPadding(
              key: const ValueKey('auth-hero-sheet'),
              padding: EdgeInsets.only(top: sheetTop),
              duration: AppMotion.duration(
                context,
                AppMotionDuration.emphasized,
              ),
              curve: AppMotionCurve.emphasized,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.xl),
                    topRight: Radius.circular(AppSpacing.xl),
                  ),
                  boxShadow: [
                    for (final shadow in AppShadow.level2)
                      shadow.copyWith(offset: -shadow.offset),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.xl),
                    topRight: Radius.circular(AppSpacing.xl),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppGlassBlur.large,
                      sigmaY: AppGlassBlur.large,
                    ),
                    child: ColoredBox(
                      color: semantic.glassCardSurface,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          LayoutBuilder(
                            builder: (context, sheetConstraints) {
                              final bottomInset =
                                  MediaQuery.paddingOf(context).bottom +
                                  MediaQuery.viewInsetsOf(context).bottom;
                              final availableContentHeight =
                                  sheetConstraints.maxHeight -
                                  AppSpacing.xl -
                                  AppSpacing.lg -
                                  bottomInset;

                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.xl,
                                  AppSpacing.lg,
                                  AppSpacing.lg + bottomInset,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: AppBreakpoints.standardMobile,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: availableContentHeight < 0
                                            ? 0
                                            : availableContentHeight,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            AuthBrandHeader(
                                              title: title,
                                              supportingText: supportingText,
                                              showLogo: false,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            form,
                                            if (footer != null) ...[
                                              const Spacer(),
                                              const SizedBox(
                                                height: AppSpacing.lg,
                                              ),
                                              footer!,
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Divider(
                              height: AppDimensions.borderWidthThin,
                              thickness: AppDimensions.borderWidthThin,
                              color: semantic.glassBorder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _GlassBackButton(onPressed: onBack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen CivicVoice illustration shown only on Login and Registration.
class AuthIllustrationHero extends StatelessWidget {
  const AuthIllustrationHero({super.key});

  /// Left-biased landmark focal point for portrait crops. A centered square
  /// crop cuts into the start of the Black Star Square sign on tall phones;
  /// this keeps the landmark lettering and Ghana header deliberately framed.
  static const Alignment focalAlignment = Alignment(-0.45, -1);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'CivicVoice community reporting illustration',
      child: Image.asset(
        AppAssets.authHero,
        fit: BoxFit.cover,
        alignment: focalAlignment,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadow.level1,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlassBlur.large,
            sigmaY: AppGlassBlur.large,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: semantic.glassCardSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: semantic.glassBorder,
                width: AppDimensions.borderWidthThin,
              ),
            ),
            child: IconButton(
              onPressed: onPressed,
              tooltip: 'Go back',
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              icon: const Icon(AppIcons.back),
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
    this.showLogo = true,
  });

  final String title;
  final String supportingText;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        if (showLogo) ...[
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
        ],
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

/// Dense frosted form surface reserved for the compact recovery flow.
///
/// Forgot Password and OTP Verification carry one short, focused task each,
/// so this treatment can retain full readability while visually relating
/// them to the illustration-auth glass without adding that larger hero.
class RecoveryAuthFormSurface extends StatelessWidget {
  const RecoveryAuthFormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.allXl,
        boxShadow: AppShadow.level1,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.allXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlassBlur.medium,
            sigmaY: AppGlassBlur.medium,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: semantic.glassCardSurface,
              border: Border.all(
                color: semantic.glassBorder,
                width: AppDimensions.borderWidthThin,
              ),
              borderRadius: AppRadius.allXl,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact glass navigation control for the standard recovery canvas.
class RecoveryAuthBackButton extends StatelessWidget {
  const RecoveryAuthBackButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadow.level1,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlassBlur.small,
            sigmaY: AppGlassBlur.small,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: semantic.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: semantic.glassBorder,
                width: AppDimensions.borderWidthThin,
              ),
            ),
            child: IconButton(
              onPressed: onPressed,
              tooltip: 'Go back',
              constraints: BoxConstraints.tight(AppDimensions.touchTarget),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              icon: const Icon(AppIcons.back),
            ),
          ),
        ),
      ),
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

  // A flatter treatment: no filled container at all — just the prefix
  // icon and text sitting directly on the page — with
  // GrowingUnderlineBorder's radius zeroed out so its stroke is a plain
  // straight line instead of following a (now-nonexistent) rounded
  // container edge. Rest state's own accent stroke stays invisible
  // (growth: 0); a faint constant baseline (see baselineColor's own doc
  // comment) is what actually gives the field a visible edge at rest now
  // that there's no container doing that job. Focusing animates the
  // accent growing in left-to-right over that baseline (growth: 0 -> 1)
  // via InputBorder.lerp, same mechanism as before. An error shows the
  // underline immediately at full width since that's persistent, not a
  // momentary focus cue.
  final baselineColor = colors.outlineVariant.withValues(alpha: 0.5);
  final atRest = GrowingUnderlineBorder(
    borderSide: BorderSide(color: colors.outlineVariant),
    growth: 0,
    radius: Radius.zero,
    baselineColor: baselineColor,
  );
  final focused = GrowingUnderlineBorder(
    borderSide: BorderSide(color: colors.primary, width: 2),
    growth: 1,
    radius: Radius.zero,
    baselineColor: baselineColor,
  );
  final error = GrowingUnderlineBorder(
    borderSide: BorderSide(color: colors.error),
    growth: 1,
    radius: Radius.zero,
    baselineColor: baselineColor,
  );
  final focusedError = GrowingUnderlineBorder(
    borderSide: BorderSide(color: colors.error, width: 2),
    growth: 1,
    radius: Radius.zero,
    baselineColor: baselineColor,
  );

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: colors.onSurfaceVariant),
    suffixIcon: suffixIcon,
    errorText: errorText,
    filled: false,
    border: atRest,
    enabledBorder: atRest,
    disabledBorder: atRest,
    focusedBorder: focused,
    errorBorder: error,
    focusedErrorBorder: focusedError,
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

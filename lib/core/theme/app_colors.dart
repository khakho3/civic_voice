/// Civic Glass Design System — Color Tokens.
///
/// Source: CivicVoice Design System Requirements §19.3 (Color System).
///
/// Rules enforced by these tokens (see source §19.3):
/// - Pure white shall not be used as the primary application background.
/// - AA contrast compliance is mandatory; AAA is the target whenever practical.
/// - Color shall never be the sole indicator of status — pair with an icon and label
///   (see [AppSemantics] and [AppIcons]).
///
/// No screen should reference a raw [Color] literal. Always import this file.
library;

import 'package:flutter/material.dart';

/// Brand and semantic colors shared by both the light and dark themes.
abstract final class AppColors {
  const AppColors._();

  // Primary brand — §19.3 "Primary Brand Color".
  static const Color primary = Color(0xFFFCD116);
  static const Color primaryHover = Color(0xFFEBC00B);
  static const Color primaryPressed = Color(0xFFD7AB00);
  static const Color onPrimary = Color(0xFF241C06);
  static const Color primaryText = Color(0xFF765400);
  static const Color controlBorder = Color(0xFF82755B);
  static const Color focus = Color(0xFF765400);

  /// Slightly brighter gold action fill used by the dark theme.
  static const Color primaryDark = Color(0xFFFFD84D);
  static const Color primaryDarkHover = Color(0xFFFCD116);
  static const Color primaryDarkPressed = Color(0xFFEBC00B);

  // Semantic colors — §19.3 "Semantic Colors".
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  /// Text/icon ink on an [error] fill (a destructive button or badge).
  /// Brand [onPrimary] ink is only 3.50:1 on red; white is 4.83:1.
  static const Color onError = Color(0xFFFFFFFF);

  /// Fixed white ink for text and icons over photographs and the fixed
  /// charcoal scrim — never theme-dependent, since the image is not.
  static const Color onPhoto = Color(0xFFFFFFFF);

  /// Fixed neutral charcoal scrim behind text laid over imagery.
  static const Color scrimStrong = Color(0xFF101110);

  /// Readable text variants of the semantic hues for the light theme. The
  /// hues above are fills, dots, and tints; on a light surface most of them
  /// fall short of 4.5:1 as text, so text and icons use these instead.
  /// Mirrors web `--color-*-text` / `--status-*-text` in `tokens.css`.
  static const Color errorTextLight = Color(0xFFB91C1C);
  static const Color successTextLight = Color(0xFF126332);
  static const Color warningTextLight = Color(0xFF925700);
  static const Color infoTextLight = Color(0xFF1D4ED8);
  static const Color statusSubmittedTextLight = Color(0xFF1D4ED8);
  static const Color statusUnderReviewTextLight = Color(0xFF92400E);
  static const Color statusAssignedTextLight = Color(0xFF6D28D9);
  static const Color statusInProgressTextLight = Color(0xFF03699B);
  static const Color statusPendingApprovalTextLight = Color(0xFF115E59);
  static const Color statusResolvedTextLight = Color(0xFF126332);
  static const Color statusRejectedTextLight = Color(0xFFB91C1C);

  /// Dark-theme counterparts of the readable text variants above.
  static const Color errorTextDark = Color(0xFFFCA5A5);
  static const Color successTextDark = Color(0xFF86EFAC);
  static const Color warningTextDark = Color(0xFFFDBA74);
  static const Color infoTextDark = Color(0xFF93C5FD);
  static const Color statusSubmittedTextDark = Color(0xFF93C5FD);
  static const Color statusUnderReviewTextDark = Color(0xFFFDBA74);
  static const Color statusAssignedTextDark = Color(0xFFC4B5FD);
  static const Color statusInProgressTextDark = Color(0xFF7DD3FC);
  static const Color statusPendingApprovalTextDark = Color(0xFF5EEAD4);
  static const Color statusResolvedTextDark = Color(0xFF86EFAC);
  static const Color statusRejectedTextDark = Color(0xFFFCA5A5);

  // Report status colors — §19.3 "Status Colors". Always pair with a label and
  // icon (see [AppIcons] status group) — color alone must never carry meaning.
  static const Color statusSubmitted = Color(0xFF2563EB);
  static const Color statusUnderReview = Color(0xFFF59E0B);
  static const Color statusAssigned = Color(0xFF8B5CF6);
  static const Color statusInProgress = Color(0xFF0EA5E9);
  static const Color statusPendingApproval = Color(0xFF0D9488);
  static const Color statusResolved = Color(0xFF16A34A);
  static const Color statusRejected = Color(0xFFDC2626);

  // Ghana flag — used by GhanaRefreshIndicator's Black Star/flag-color
  // sweep, not part of §19.3's semantic palette. Named here instead of
  // inline so the same three colors used across that indicator's star and
  // bar aren't three separate hex literals.
  static const Color ghanaRed = Color(0xFFCE1126);
  static const Color ghanaGold = Color(0xFFFCD116);
  static const Color ghanaGreen = Color(0xFF006B3F);
}

/// Light theme surface, text, and border tokens — §19.3 "Light Theme".
abstract final class AppColorsLight {
  const AppColorsLight._();

  static const Color canvas = Color(0xFFFAFAF7);
  static const Color primarySurface = Color(0xFFFFFFFF);
  static const Color secondarySurface = Color(0xFFF1F2EB);

  /// rgba(255,255,255,0.65) — permitted only on navigation panels, cards,
  /// dialogs, bottom sheets, filters, and search containers (§19.10 Glass
  /// Usage Rules). Prohibited on long-form content, input-heavy forms,
  /// analytics charts, and large text sections.
  static const Color glassSurface = Color.fromRGBO(255, 255, 255, 0.92);

  /// Card-specific glass opacity (CL-001 "Card Opacity", pending formal
  /// definition). Denser card content needs more legibility than the generic
  /// [glassSurface], so approved screens tint [primarySurface] at a higher,
  /// near-opaque alpha instead. Confirmed against MUN-001 Dashboard
  /// (Light: rgba(255,255,255,0.88); Dark: rgba(17,24,39,0.88)).
  static const Color glassCardSurface = Color.fromRGBO(255, 255, 255, 0.92);

  /// Navigation-specific glass opacity (CL-001 "Navigation Opacity", pending
  /// formal definition). Originally sourced from MUN-001 Dashboard at 0.82
  /// alpha, which sat well above the ratified [glassSurface] baseline
  /// (0.65) and made the frost effect barely perceptible in practice.
  /// Lowered to 0.72 — still more opaque than [glassSurface] for chrome
  /// legibility over scrolled content, but moving toward the standard
  /// rather than further past it.
  static const Color glassNavSurface = Color.fromRGBO(250, 250, 247, 0.94);

  static const Color primaryText = Color(0xFF172019);
  static const Color secondaryText = Color(0xFF50594F);
  static const Color border = Color(0xFFDADDD3);

  /// Translucent hairline border used on glass surfaces (cards, glass
  /// buttons, navigation) instead of the solid [border] token — sourced from
  /// MUN-001 Dashboard (rgba(148,163,184,0.32)). Not yet formalized in the
  /// Design System Requirements; verify against additional approved screens.
  static const Color glassBorder = Color.fromRGBO(148, 163, 184, 0.32);

  /// Subtle primary-tint background for small icon badges (stat icons, brand
  /// mark). Sourced from MUN-001 Dashboard (#DBEAFE) — a distinct swatch, not
  /// an alpha blend of [AppColors.primary].
  static const Color iconBadgeSurface = Color(0xFFF8EFC9);

  /// Inverse surface for snackbars and tooltips: dark in the light theme.
  static const Color surfaceInverse = Color(0xFF172019);
  static const Color textInverse = Color(0xFFFAFAF7);
}

/// Dark theme surface, text, and border tokens — §19.3 "Dark Theme".
abstract final class AppColorsDark {
  const AppColorsDark._();

  static const Color canvas = Color(0xFF101110);
  static const Color primarySurface = Color(0xFF191B19);
  static const Color secondarySurface = Color(0xFF242724);

  /// rgba(15,23,42,0.75) — see [AppColorsLight.glassSurface] usage rules.
  static const Color glassSurface = Color.fromRGBO(25, 27, 25, 0.92);

  /// See [AppColorsLight.glassCardSurface] — [primarySurface] tinted at the
  /// same 0.88 alpha. Confirmed against MUN-001 Dashboard (rgba(17,24,39,0.88)).
  static const Color glassCardSurface = Color.fromRGBO(25, 27, 25, 0.94);

  /// See [AppColorsLight.glassNavSurface] — [canvas] tinted at 0.70 alpha
  /// (lowered from 0.82; see that token's doc comment).
  static const Color glassNavSurface = Color.fromRGBO(16, 17, 16, 0.88);

  static const Color primaryText = Color(0xFFF4F5EF);
  static const Color secondaryText = Color(0xFFBBC4B8);
  static const Color border = Color(0xFF41483F);

  /// See [AppColorsLight.glassBorder]. Confirmed against MUN-001 Dashboard —
  /// dark uses [secondaryText] at a much lower alpha rather than reusing the
  /// light theme's slate-400 value (rgba(203,213,225,0.18)).
  static const Color glassBorder = Color.fromRGBO(218, 224, 216, 0.24);

  /// See [AppColorsLight.iconBadgeSurface]. Confirmed against MUN-001
  /// Dashboard: dark mode reuses [secondarySurface] as a flat fill rather
  /// than a primary-tinted swatch (#1E293B, not an alpha blend).
  static const Color iconBadgeSurface = Color(0xFF303325);

  /// Surface for profile/preference rows, one step above [primarySurface]
  /// so grouped rows separate from the card behind them (web
  /// `--profile-row-surface`).
  static const Color profileRowSurface = Color(0xFF202320);
}

/// Glass-surface blur tokens.
///
/// Not yet formally quantified by the Design System Requirements (flagged as
/// pending in CL-001 "Blur Tokens"). These sigma values follow the documented
/// principle that "glass surfaces must maintain subtle elevation" (§19.8) and
/// should be superseded by an approved CL once formally specified.
abstract final class AppGlassBlur {
  const AppGlassBlur._();

  static const double small = 10.0;
  static const double medium = 20.0;
  static const double large = 30.0;
}

/// Theme-aware semantic colors that fall outside Material's [ColorScheme]
/// (success / warning / info / report-status colors). Registered on
/// [ThemeData.extensions] by [AppLightTheme] and [AppDarkTheme] so any screen
/// can reach them via [AppSemanticColors.of].
///
/// Fills and inks are deliberately separate. The hue fields ([success],
/// [statusSubmitted], …) are for fills, dots, bars, and tints. Text and icons
/// drawn directly on a surface use the matching `*Text` field, or
/// [foregroundFor] when the hue arrives as a parameter. Brand gold follows
/// the same split: [actionFill] is the button/FAB/selected-chip fill (with
/// [onAction] ink), and [actionText] is the brand-accent text/icon color on
/// ordinary surfaces — gold itself is 1.47:1 against white.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.statusSubmitted,
    required this.statusUnderReview,
    required this.statusAssigned,
    required this.statusInProgress,
    required this.statusPendingApproval,
    required this.statusResolved,
    required this.statusRejected,
    required this.glassSurface,
    required this.glassCardSurface,
    required this.glassNavSurface,
    required this.glassBorder,
    required this.iconBadgeSurface,
    required this.actionFill,
    required this.onAction,
    required this.actionText,
    required this.focus,
    required this.controlBorder,
    required this.onError,
    required this.errorText,
    required this.successText,
    required this.warningText,
    required this.infoText,
    required this.statusSubmittedText,
    required this.statusUnderReviewText,
    required this.statusAssignedText,
    required this.statusInProgressText,
    required this.statusPendingApprovalText,
    required this.statusResolvedText,
    required this.statusRejectedText,
    required this.surfaceInverse,
    required this.textInverse,
    required this.profileRowSurface,
  });

  /// The [AppSemanticColors] registered on the ambient theme, falling back
  /// to the token set for its brightness when a theme (e.g. a bare test
  /// `ThemeData`) has not registered the extension.
  static AppSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color statusSubmitted;
  final Color statusUnderReview;
  final Color statusAssigned;
  final Color statusInProgress;
  final Color statusPendingApproval;
  final Color statusResolved;
  final Color statusRejected;
  final Color glassSurface;
  final Color glassCardSurface;
  final Color glassNavSurface;
  final Color glassBorder;
  final Color iconBadgeSurface;

  /// Brand gold fill for primary buttons, the Create FAB, selected chips,
  /// and progress values. Always paired with [onAction] ink.
  final Color actionFill;

  /// Dark ink for text and icons on [actionFill].
  final Color onAction;

  /// Brand-accent text and icon color on ordinary surfaces: links, active
  /// navigation, icon badges, selected menu rows.
  final Color actionText;

  /// Keyboard focus ring and focused input outline.
  final Color focus;

  /// Outline for interactive controls (outlined buttons, chips).
  final Color controlBorder;

  /// Ink on an [error] fill (destructive buttons).
  final Color onError;

  final Color errorText;
  final Color successText;
  final Color warningText;
  final Color infoText;
  final Color statusSubmittedText;
  final Color statusUnderReviewText;
  final Color statusAssignedText;
  final Color statusInProgressText;
  final Color statusPendingApprovalText;
  final Color statusResolvedText;
  final Color statusRejectedText;

  /// Snackbar/tooltip surface: dark in the light theme, light in the dark.
  final Color surfaceInverse;

  /// Text on [surfaceInverse].
  final Color textInverse;

  /// Grouped profile/preference row surface.
  final Color profileRowSurface;

  /// The readable text/icon ink for [hue] when it is drawn directly on a
  /// surface (not as a fill). Known brand/semantic/status hues map to their
  /// accessible text variant for this theme; any other color is returned
  /// unchanged, since its caller has already chosen a foreground.
  ///
  /// Shared widgets that accept a "tint" or "badge" color use this for the
  /// glyph/label and keep the raw hue for the translucent background, so a
  /// caller passing `AppColors.primary` or `AppColors.warning` still gets
  /// legible text.
  Color foregroundFor(Color hue) {
    final value = hue.toARGB32();
    if (value == AppColors.primary.toARGB32() ||
        value == AppColors.primaryDark.toARGB32() ||
        value == AppColors.primaryPressed.toARGB32() ||
        value == AppColors.primaryHover.toARGB32()) {
      return actionText;
    }
    // Several status hues share a value with a semantic hue (submitted ==
    // info, resolved == success, rejected == error, under review ==
    // warning); each pair also shares its text variant, so first match wins.
    if (value == success.toARGB32()) return successText;
    if (value == warning.toARGB32()) return warningText;
    if (value == error.toARGB32()) return errorText;
    if (value == info.toARGB32()) return infoText;
    if (value == statusAssigned.toARGB32()) return statusAssignedText;
    if (value == statusInProgress.toARGB32()) return statusInProgressText;
    if (value == statusPendingApproval.toARGB32()) {
      return statusPendingApprovalText;
    }
    return hue;
  }

  /// The ink for text and icons drawn *on* a solid [fill] — brand gold gets
  /// [onAction], error red gets [onError], and any other fill gets whichever
  /// of the two contrasts more. Use this when a caller supplies a button or
  /// chip fill color, so a red button never inherits the theme's dark gold
  /// ink (3.50:1).
  Color onFillFor(Color fill) {
    final value = fill.toARGB32();
    if (value == actionFill.toARGB32() ||
        value == AppColors.primary.toARGB32() ||
        value == AppColors.primaryDark.toARGB32()) {
      return onAction;
    }
    if (value == error.toARGB32()) return onError;
    final fillLuminance = fill.computeLuminance();
    double contrast(Color ink) {
      final inkLuminance = ink.computeLuminance();
      final lighter = inkLuminance > fillLuminance
          ? inkLuminance
          : fillLuminance;
      final darker = inkLuminance > fillLuminance
          ? fillLuminance
          : inkLuminance;
      return (lighter + 0.05) / (darker + 0.05);
    }

    return contrast(onError) >= contrast(onAction) ? onError : onAction;
  }

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    statusSubmitted: AppColors.statusSubmitted,
    statusUnderReview: AppColors.statusUnderReview,
    statusAssigned: AppColors.statusAssigned,
    statusInProgress: AppColors.statusInProgress,
    statusPendingApproval: AppColors.statusPendingApproval,
    statusResolved: AppColors.statusResolved,
    statusRejected: AppColors.statusRejected,
    glassSurface: AppColorsLight.glassSurface,
    glassCardSurface: AppColorsLight.glassCardSurface,
    glassNavSurface: AppColorsLight.glassNavSurface,
    glassBorder: AppColorsLight.glassBorder,
    iconBadgeSurface: AppColorsLight.iconBadgeSurface,
    actionFill: AppColors.primary,
    onAction: AppColors.onPrimary,
    actionText: AppColors.primaryText,
    focus: AppColors.focus,
    controlBorder: AppColors.controlBorder,
    onError: AppColors.onError,
    errorText: AppColors.errorTextLight,
    successText: AppColors.successTextLight,
    warningText: AppColors.warningTextLight,
    infoText: AppColors.infoTextLight,
    statusSubmittedText: AppColors.statusSubmittedTextLight,
    statusUnderReviewText: AppColors.statusUnderReviewTextLight,
    statusAssignedText: AppColors.statusAssignedTextLight,
    statusInProgressText: AppColors.statusInProgressTextLight,
    statusPendingApprovalText: AppColors.statusPendingApprovalTextLight,
    statusResolvedText: AppColors.statusResolvedTextLight,
    statusRejectedText: AppColors.statusRejectedTextLight,
    surfaceInverse: AppColorsLight.surfaceInverse,
    textInverse: AppColorsLight.textInverse,
    profileRowSurface: AppColorsLight.primarySurface,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    statusSubmitted: AppColors.statusSubmitted,
    statusUnderReview: AppColors.statusUnderReview,
    statusAssigned: AppColors.statusAssigned,
    statusInProgress: AppColors.statusInProgress,
    statusPendingApproval: AppColors.statusPendingApproval,
    statusResolved: AppColors.statusResolved,
    statusRejected: AppColors.statusRejected,
    glassSurface: AppColorsDark.glassSurface,
    glassCardSurface: AppColorsDark.glassCardSurface,
    glassNavSurface: AppColorsDark.glassNavSurface,
    glassBorder: AppColorsDark.glassBorder,
    iconBadgeSurface: AppColorsDark.iconBadgeSurface,
    actionFill: AppColors.primaryDark,
    onAction: AppColors.onPrimary,
    actionText: AppColors.primaryDark,
    focus: AppColors.primaryDark,
    controlBorder: AppColors.controlBorder,
    onError: AppColors.onError,
    errorText: AppColors.errorTextDark,
    successText: AppColors.successTextDark,
    warningText: AppColors.warningTextDark,
    infoText: AppColors.infoTextDark,
    statusSubmittedText: AppColors.statusSubmittedTextDark,
    statusUnderReviewText: AppColors.statusUnderReviewTextDark,
    statusAssignedText: AppColors.statusAssignedTextDark,
    statusInProgressText: AppColors.statusInProgressTextDark,
    statusPendingApprovalText: AppColors.statusPendingApprovalTextDark,
    statusResolvedText: AppColors.statusResolvedTextDark,
    statusRejectedText: AppColors.statusRejectedTextDark,
    surfaceInverse: AppColorsDark.primaryText,
    textInverse: AppColorsLight.primaryText,
    profileRowSurface: AppColorsDark.profileRowSurface,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? statusSubmitted,
    Color? statusUnderReview,
    Color? statusAssigned,
    Color? statusInProgress,
    Color? statusPendingApproval,
    Color? statusResolved,
    Color? statusRejected,
    Color? glassSurface,
    Color? glassCardSurface,
    Color? glassNavSurface,
    Color? glassBorder,
    Color? iconBadgeSurface,
    Color? actionFill,
    Color? onAction,
    Color? actionText,
    Color? focus,
    Color? controlBorder,
    Color? onError,
    Color? errorText,
    Color? successText,
    Color? warningText,
    Color? infoText,
    Color? statusSubmittedText,
    Color? statusUnderReviewText,
    Color? statusAssignedText,
    Color? statusInProgressText,
    Color? statusPendingApprovalText,
    Color? statusResolvedText,
    Color? statusRejectedText,
    Color? surfaceInverse,
    Color? textInverse,
    Color? profileRowSurface,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      statusSubmitted: statusSubmitted ?? this.statusSubmitted,
      statusUnderReview: statusUnderReview ?? this.statusUnderReview,
      statusAssigned: statusAssigned ?? this.statusAssigned,
      statusInProgress: statusInProgress ?? this.statusInProgress,
      statusPendingApproval:
          statusPendingApproval ?? this.statusPendingApproval,
      statusResolved: statusResolved ?? this.statusResolved,
      statusRejected: statusRejected ?? this.statusRejected,
      glassSurface: glassSurface ?? this.glassSurface,
      glassCardSurface: glassCardSurface ?? this.glassCardSurface,
      glassNavSurface: glassNavSurface ?? this.glassNavSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      iconBadgeSurface: iconBadgeSurface ?? this.iconBadgeSurface,
      actionFill: actionFill ?? this.actionFill,
      onAction: onAction ?? this.onAction,
      actionText: actionText ?? this.actionText,
      focus: focus ?? this.focus,
      controlBorder: controlBorder ?? this.controlBorder,
      onError: onError ?? this.onError,
      errorText: errorText ?? this.errorText,
      successText: successText ?? this.successText,
      warningText: warningText ?? this.warningText,
      infoText: infoText ?? this.infoText,
      statusSubmittedText: statusSubmittedText ?? this.statusSubmittedText,
      statusUnderReviewText:
          statusUnderReviewText ?? this.statusUnderReviewText,
      statusAssignedText: statusAssignedText ?? this.statusAssignedText,
      statusInProgressText: statusInProgressText ?? this.statusInProgressText,
      statusPendingApprovalText:
          statusPendingApprovalText ?? this.statusPendingApprovalText,
      statusResolvedText: statusResolvedText ?? this.statusResolvedText,
      statusRejectedText: statusRejectedText ?? this.statusRejectedText,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      textInverse: textInverse ?? this.textInverse,
      profileRowSurface: profileRowSurface ?? this.profileRowSurface,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      info: mix(info, other.info),
      statusSubmitted: mix(statusSubmitted, other.statusSubmitted),
      statusUnderReview: mix(statusUnderReview, other.statusUnderReview),
      statusAssigned: mix(statusAssigned, other.statusAssigned),
      statusInProgress: mix(statusInProgress, other.statusInProgress),
      statusPendingApproval: mix(
        statusPendingApproval,
        other.statusPendingApproval,
      ),
      statusResolved: mix(statusResolved, other.statusResolved),
      statusRejected: mix(statusRejected, other.statusRejected),
      glassSurface: mix(glassSurface, other.glassSurface),
      glassCardSurface: mix(glassCardSurface, other.glassCardSurface),
      glassNavSurface: mix(glassNavSurface, other.glassNavSurface),
      glassBorder: mix(glassBorder, other.glassBorder),
      iconBadgeSurface: mix(iconBadgeSurface, other.iconBadgeSurface),
      actionFill: mix(actionFill, other.actionFill),
      onAction: mix(onAction, other.onAction),
      actionText: mix(actionText, other.actionText),
      focus: mix(focus, other.focus),
      controlBorder: mix(controlBorder, other.controlBorder),
      onError: mix(onError, other.onError),
      errorText: mix(errorText, other.errorText),
      successText: mix(successText, other.successText),
      warningText: mix(warningText, other.warningText),
      infoText: mix(infoText, other.infoText),
      statusSubmittedText: mix(statusSubmittedText, other.statusSubmittedText),
      statusUnderReviewText: mix(
        statusUnderReviewText,
        other.statusUnderReviewText,
      ),
      statusAssignedText: mix(statusAssignedText, other.statusAssignedText),
      statusInProgressText: mix(
        statusInProgressText,
        other.statusInProgressText,
      ),
      statusPendingApprovalText: mix(
        statusPendingApprovalText,
        other.statusPendingApprovalText,
      ),
      statusResolvedText: mix(statusResolvedText, other.statusResolvedText),
      statusRejectedText: mix(statusRejectedText, other.statusRejectedText),
      surfaceInverse: mix(surfaceInverse, other.surfaceInverse),
      textInverse: mix(textInverse, other.textInverse),
      profileRowSurface: mix(profileRowSurface, other.profileRowSurface),
    );
  }
}

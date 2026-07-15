/// Civic Glass Design System — Typography Tokens.
///
/// Source: CivicVoice Design System Requirements §19.4 (Typography System).
///
/// Rules enforced by these tokens (see source §19.4):
/// - Primary typeface is Inter; decorative fonts are prohibited.
/// - Approved weights only: Regular 400, Medium 500, SemiBold 600, Bold 700.
/// - Body text uses 16px by default; minimum body text size is 14px.
/// - Line height stays between 1.4x and 1.6x the font size.
/// - Text is left-aligned by default; large centered text blocks are prohibited.
/// - Dynamic text scaling must be supported (do not wrap these styles with
///   `MediaQuery(textScaler: TextScaler.noScaling)` or similar).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Approved Inter font weights — §19.4 "Approved Weights".
abstract final class AppFontWeight {
  const AppFontWeight._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

/// Approved type scale sizes, in logical pixels — §19.4 "Type Scale".
abstract final class AppFontSize {
  const AppFontSize._();

  static const double display = 40;
  static const double h1 = 32;
  static const double h2 = 24;
  static const double h3 = 20;
  static const double body = 16;
  static const double bodySmall = 14;
  static const double caption = 12;
}

/// Approved line-height multipliers — §19.4 Text Rule 2 (1.4x–1.6x font size).
abstract final class AppLineHeight {
  const AppLineHeight._();

  static const double tight = 1.4;
  static const double comfortable = 1.5;
  static const double relaxed = 1.6;
}

/// Inter type scale, built as [TextStyle] tokens and mapped onto Material 3's
/// [TextTheme] so every widget that reads `Theme.of(context).textTheme`
/// automatically renders in the approved Civic Glass scale.
abstract final class AppTypography {
  const AppTypography._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// 40px / Bold / 1.4x — page-level hero headings.
  static final TextStyle display = _inter(
    fontSize: AppFontSize.display,
    fontWeight: AppFontWeight.bold,
    height: AppLineHeight.tight,
  );

  /// 32px / Bold / 1.4x — screen titles.
  static final TextStyle h1 = _inter(
    fontSize: AppFontSize.h1,
    fontWeight: AppFontWeight.bold,
    height: AppLineHeight.tight,
  );

  /// 24px / SemiBold / 1.4x — section headings.
  static final TextStyle h2 = _inter(
    fontSize: AppFontSize.h2,
    fontWeight: AppFontWeight.semiBold,
    height: AppLineHeight.tight,
  );

  /// 20px / SemiBold / 1.5x — subsection headings.
  static final TextStyle h3 = _inter(
    fontSize: AppFontSize.h3,
    fontWeight: AppFontWeight.semiBold,
    height: AppLineHeight.comfortable,
  );

  /// 16px / Regular / 1.5x — default body text (Text Rule 1).
  static final TextStyle body = _inter(
    fontSize: AppFontSize.body,
    fontWeight: AppFontWeight.regular,
    height: AppLineHeight.comfortable,
  );

  /// 14px / Regular / 1.5x — the minimum permitted body text size.
  static final TextStyle bodySmall = _inter(
    fontSize: AppFontSize.bodySmall,
    fontWeight: AppFontWeight.regular,
    height: AppLineHeight.comfortable,
  );

  /// 12px / Medium / 1.6x — metadata, timestamps, helper text. Not a body
  /// text role, so it is exempt from the 14px body text minimum.
  static final TextStyle caption = _inter(
    fontSize: AppFontSize.caption,
    fontWeight: AppFontWeight.medium,
    height: AppLineHeight.relaxed,
  );

  /// Resolved Inter font family name, for widgets that need the family
  /// string directly instead of a full [TextStyle] (e.g. `DefaultTextStyle`
  /// overrides, PDF/print export).
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  /// Builds a full Material 3 [TextTheme] from the approved scale, tinted
  /// with the given theme's text colors (see [AppColorsLight] / [AppColorsDark]).
  static TextTheme textTheme({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return TextTheme(
      displayLarge: display.copyWith(color: primaryText),
      displayMedium: display.copyWith(color: primaryText),
      displaySmall: display.copyWith(color: primaryText),
      headlineLarge: h1.copyWith(color: primaryText),
      headlineMedium: h2.copyWith(color: primaryText),
      headlineSmall: h3.copyWith(color: primaryText),
      titleLarge: h3.copyWith(color: primaryText),
      titleMedium: body.copyWith(
        color: primaryText,
        fontWeight: AppFontWeight.semiBold,
      ),
      titleSmall: bodySmall.copyWith(
        color: primaryText,
        fontWeight: AppFontWeight.semiBold,
      ),
      bodyLarge: body.copyWith(color: primaryText),
      bodyMedium: body.copyWith(color: primaryText),
      bodySmall: bodySmall.copyWith(color: secondaryText),
      labelLarge: bodySmall.copyWith(
        color: primaryText,
        fontWeight: AppFontWeight.semiBold,
      ),
      labelMedium: caption.copyWith(
        color: secondaryText,
        fontWeight: AppFontWeight.semiBold,
      ),
      labelSmall: caption.copyWith(color: secondaryText),
    );
  }
}

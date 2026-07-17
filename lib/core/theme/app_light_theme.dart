/// Civic Glass Design System — Light Theme.
///
/// Composes every token file (colors, typography, spacing, radius,
/// elevation, icons) into a single Material 3 [ThemeData], so no screen ever
/// builds its own `ThemeData` or reaches for a raw color/size literal.
///
/// Source: CivicVoice Design System Requirements §19.3 "Light Theme".
library;

import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_icons.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Builds and exposes the approved Civic Glass light [ThemeData].
///
/// `surfaceTintColor` is pinned to [Colors.transparent] on every component
/// sub-theme below. Material 3 otherwise tints elevated surfaces with
/// `colorScheme.surfaceTint` automatically, which would silently shift the
/// approved surface hexes (§19.3) away from spec as elevation increases —
/// Governance Rule 1 prohibits introducing unapproved colors this way.
/// Hierarchy is instead communicated through [AppElevation] shadow/elevation
/// values alone.
abstract final class AppLightTheme {
  const AppLightTheme._();

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        // No "Secondary Brand" color has been formally approved yet (see
        // CL-001 Design Enhancement checklist). The approved Secondary Text
        // token is reused here as a neutral, accessible placeholder until a
        // brand secondary is defined.
        secondary: AppColorsLight.secondaryText,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColorsLight.primarySurface,
        onSurface: AppColorsLight.primaryText,
        surfaceContainerLowest: AppColorsLight.canvas,
        surfaceContainerLow: AppColorsLight.secondarySurface,
        surfaceContainer: AppColorsLight.secondarySurface,
        outline: AppColorsLight.border,
        outlineVariant: AppColorsLight.border,
        shadow: AppColorsLight.primaryText,
      );

  static final TextTheme _textTheme = AppTypography.textTheme(
    primaryText: AppColorsLight.primaryText,
    secondaryText: AppColorsLight.secondaryText,
  );

  /// The approved Civic Glass light theme.
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColorsLight.canvas,
    fontFamily: AppTypography.fontFamily,
    textTheme: _textTheme,
    splashFactory: InkSparkle.splashFactory,

    extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.light],

    iconTheme: const IconThemeData(
      color: AppColorsLight.primaryText,
      size: AppIconSize.standard,
    ),
    primaryIconTheme: const IconThemeData(
      color: Colors.white,
      size: AppIconSize.standard,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColorsLight.border,
      thickness: AppDimensions.borderWidthThin,
      space: 1,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsLight.primarySurface,
      foregroundColor: AppColorsLight.primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level0,
      scrolledUnderElevation: AppElevation.level1,
      centerTitle: false, // Text Rule 3: left-aligned by default.
      titleTextStyle: _textTheme.headlineSmall,
      iconTheme: const IconThemeData(
        color: AppColorsLight.primaryText,
        size: AppIconSize.standard,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColorsLight.primarySurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level1,
      shadowColor: AppColorsLight.primaryText,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.card,
      ),
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColorsLight.secondarySurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(color: AppColorsLight.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(color: AppColorsLight.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.borderWidthFocused,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderWidthFocused,
        ),
      ),
      labelStyle: _textTheme.bodyLarge,
      hintStyle: _textTheme.bodyLarge?.copyWith(
        color: AppColorsLight.secondaryText,
      ),
      errorStyle: _textTheme.bodySmall?.copyWith(color: AppColors.error),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColorsLight.border,
        disabledForegroundColor: AppColorsLight.secondaryText,
        // Intrinsic width by default — see textButtonTheme below.
        minimumSize: const Size(64, AppDimensions.controlHeightStandard),
        shape: const RoundedRectangleBorder(
          borderRadius: AppComponentRadius.button,
        ),
        textStyle: _textTheme.labelLarge,
        elevation: AppElevation.level0,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Intrinsic width by default — see textButtonTheme below.
        minimumSize: const Size(64, AppDimensions.controlHeightStandard),
        shape: const RoundedRectangleBorder(
          borderRadius: AppComponentRadius.button,
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColorsLight.secondaryText,
        side: const BorderSide(color: AppColorsLight.border),
        // Intrinsic width by default — see textButtonTheme below.
        minimumSize: const Size(64, AppDimensions.controlHeightStandard),
        shape: const RoundedRectangleBorder(
          borderRadius: AppComponentRadius.button,
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),

    // Every button theme above uses a 64px intrinsic-width minimum, not a
    // full-width default: some buttons need their natural width (e.g. a
    // "Reject" button beside an Expanded "Verify Report" in a Row), and a
    // widget wrapped in a full-width theme default cannot un-request that
    // width when placed in a context — like a Row — that gives it loose
    // constraints. Screens that want a full-width button wrap it explicitly
    // in Expanded/SizedBox(width: double.infinity) at the call site.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColorsLight.secondaryText,
        minimumSize: const Size(64, AppDimensions.controlHeightStandard),
        shape: const RoundedRectangleBorder(
          borderRadius: AppComponentRadius.button,
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsLight.primarySurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.dialog,
      ),
      titleTextStyle: _textTheme.headlineSmall,
      contentTextStyle: _textTheme.bodyMedium,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColorsLight.primarySurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColorsLight.primarySurface,
      elevation: AppElevation.level2,
      modalElevation: AppElevation.level2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.bottomSheet,
      ),
      showDragHandle: true,
      dragHandleColor: AppColorsLight.border,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColorsLight.primarySurface,
      surfaceTintColor: Colors.transparent,
      // No filled indicator pill — active state is icon/label color+weight
      // only, matching Citizen's hand-rolled bottom nav (the approved
      // target style for every module's nav, including Maintenance's
      // stock NavigationBar).
      indicatorColor: Colors.transparent,
      elevation: AppElevation.level1,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return _textTheme.labelMedium?.copyWith(
          color: selected ? AppColors.primary : AppColorsLight.secondaryText,
          fontWeight: selected ? AppFontWeight.semiBold : AppFontWeight.medium,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColorsLight.secondaryText,
          size: AppIconSize.standard,
        );
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColorsLight.secondarySurface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      disabledColor: AppColorsLight.secondarySurface,
      labelStyle: _textTheme.labelMedium,
      secondaryLabelStyle: _textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
      ),
      side: const BorderSide(color: AppColorsLight.border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsLight.primaryText,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(color: Colors.white),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      elevation: AppElevation.level2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.inputField,
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColorsLight.primaryText,
        borderRadius: AppRadius.allXs,
      ),
      textStyle: _textTheme.bodySmall?.copyWith(color: Colors.white),
    ),

    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.error,
      textColor: Colors.white,
    ),

    dividerColor: AppColorsLight.border,
    disabledColor: AppColorsLight.secondaryText,
    hintColor: AppColorsLight.secondaryText,
    highlightColor: AppColors.primary.withValues(alpha: 0.08),
    focusColor: AppColors.primary.withValues(alpha: 0.12),
  );
}

/// Civic Glass Design System — Dark Theme.
///
/// Structurally mirrors [AppLightTheme] section-for-section so the two stay
/// consistent as the system evolves — when you change a section here, change
/// the matching section there.
///
/// Source: CivicVoice Design System Requirements §19.3 "Dark Theme".
library;

import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_icons.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Builds and exposes the approved Civic Glass dark [ThemeData].
///
/// `surfaceTintColor` is pinned to [Colors.transparent] throughout — see
/// [AppLightTheme] for the rationale (preserving the approved §19.3 surface
/// hexes at every elevation level instead of Material 3's automatic tint).
abstract final class AppDarkTheme {
  const AppDarkTheme._();

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        // See AppLightTheme: no approved "Secondary Brand" color exists yet
        // (CL-001 pending). Secondary Text is reused as a neutral placeholder.
        secondary: AppColorsDark.secondaryText,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: const Color(0xFF111827),
        onSurface: AppColorsDark.primaryText,
        surfaceContainerLowest: AppColorsDark.canvas,
        surfaceContainerLow: AppColorsDark.secondarySurface,
        surfaceContainer: AppColorsDark.secondarySurface,
        outline: AppColorsDark.border,
        outlineVariant: AppColorsDark.border,
        shadow: Colors.black,
      );

  static final TextTheme _textTheme = AppTypography.textTheme(
    primaryText: AppColorsDark.primaryText,
    secondaryText: AppColorsDark.secondaryText,
  );

  /// The approved Civic Glass dark theme.
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColorsDark.canvas,
    fontFamily: AppTypography.fontFamily,
    textTheme: _textTheme,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: AppMotion.pageTransitionsTheme,

    extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.dark],

    iconTheme: const IconThemeData(
      color: AppColorsDark.primaryText,
      size: AppIconSize.standard,
    ),
    primaryIconTheme: const IconThemeData(
      color: Colors.white,
      size: AppIconSize.standard,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColorsDark.border,
      thickness: AppDimensions.borderWidthThin,
      space: 1,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.primarySurface,
      foregroundColor: AppColorsDark.primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level0,
      scrolledUnderElevation: AppElevation.level1,
      centerTitle: false, // Text Rule 3: left-aligned by default.
      titleTextStyle: _textTheme.headlineSmall,
      iconTheme: const IconThemeData(
        color: AppColorsDark.primaryText,
        size: AppIconSize.standard,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColorsDark.primarySurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level1,
      shadowColor: AppColorsDark.border,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.card,
      ),
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColorsDark.secondarySurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppComponentRadius.inputField,
        borderSide: const BorderSide(color: AppColorsDark.border),
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
        color: AppColorsDark.secondaryText,
      ),
      errorStyle: _textTheme.bodySmall?.copyWith(color: AppColors.error),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColorsDark.border,
        disabledForegroundColor: AppColorsDark.secondaryText,
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
        disabledForegroundColor: AppColorsDark.secondaryText,
        side: const BorderSide(color: AppColorsDark.border),
        minimumSize: const Size(64, AppDimensions.controlHeightStandard),
        shape: const RoundedRectangleBorder(
          borderRadius: AppComponentRadius.button,
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColorsDark.secondaryText,
        minimumSize: const Size(64, AppDimensions.controlHeightStandard),
        shape: const RoundedRectangleBorder(
          borderRadius: AppComponentRadius.button,
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),

    // See AppLightTheme for why these are glass (AppColorsDark.glassSurface)
    // rather than the opaque primary surface.
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsDark.glassSurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.dialog,
      ),
      titleTextStyle: _textTheme.headlineSmall,
      contentTextStyle: _textTheme.bodyMedium,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColorsDark.glassSurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColorsDark.glassSurface,
      elevation: AppElevation.level2,
      modalElevation: AppElevation.level2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.bottomSheet,
      ),
      showDragHandle: true,
      dragHandleColor: AppColorsDark.border,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColorsDark.primarySurface,
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
          color: selected ? AppColors.primary : AppColorsDark.secondaryText,
          fontWeight: selected ? AppFontWeight.semiBold : AppFontWeight.medium,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColorsDark.secondaryText,
          size: AppIconSize.standard,
        );
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColorsDark.secondarySurface,
      selectedColor: AppColors.primary.withValues(alpha: 0.24),
      disabledColor: AppColorsDark.secondarySurface,
      labelStyle: _textTheme.labelMedium,
      secondaryLabelStyle: _textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
      ),
      side: const BorderSide(color: AppColorsDark.border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsDark.secondarySurface,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(
        color: AppColorsDark.primaryText,
      ),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      elevation: AppElevation.level2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppComponentRadius.inputField,
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColorsDark.secondarySurface,
        borderRadius: AppRadius.allXs,
      ),
      textStyle: _textTheme.bodySmall?.copyWith(
        color: AppColorsDark.primaryText,
      ),
    ),

    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.error,
      textColor: Colors.white,
    ),

    dividerColor: AppColorsDark.border,
    disabledColor: AppColorsDark.secondaryText,
    hintColor: AppColorsDark.secondaryText,
    highlightColor: AppColors.primary.withValues(alpha: 0.16),
    focusColor: AppColors.primary.withValues(alpha: 0.20),
  );
}

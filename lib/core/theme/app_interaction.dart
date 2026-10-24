import 'package:flutter/material.dart';

/// Restrained touch feedback shared by cards, chips and Material actions.
/// Focus and hover keep the component defaults; keyboard focus stays visible.
abstract final class AppInteraction {
  static Color pressedTint(Color ink) => ink.withValues(alpha: 0.04);

  static WidgetStateProperty<Color?> overlay(Color ink) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) ||
            states.contains(WidgetState.focused)) {
          return null;
        }
        return states.contains(WidgetState.pressed) ? pressedTint(ink) : null;
      });
}

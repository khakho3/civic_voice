import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/busy_indicator.dart';

/// Compact map search, with the same 48px control and rounded shape as web.
/// Results remain owned by the picker; clearing also invalidates its search.
class LocationPickerSearchField extends StatelessWidget {
  const LocationPickerSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.searching = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search for a location',
          isDense: true,
          constraints: const BoxConstraints(minHeight: 48),
          prefixIcon: const Icon(AppIcons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: searching
              ? const SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: BusyIndicator(
                      size: 20,
                      semanticsLabel: 'Searching places',
                    ),
                  ),
                )
              : value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear location search',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(AppIcons.close, size: 20),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: AppRadius.allXl,
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.allXl,
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.allXl,
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class LocationPickerBusyStatus extends StatelessWidget {
  const LocationPickerBusyStatus({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    excludeSemantics: true,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: AppElevation.level2,
      borderRadius: AppRadius.allXl,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BusyIndicator(size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

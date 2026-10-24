import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_haptics.dart';
import 'civic_filter_chip.dart';

/// One option in a [TextFilterChips] row.
@immutable
class TextFilterOption<T> {
  const TextFilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Horizontally scrolling shared filter pills, with the accepted native
/// checkmark/selection motion and a 48px touch target.
///
/// Horizontal drags stay with the row and vertical ones go to the list
/// behind it, so pull-to-refresh and the collapsing header keep working.
class TextFilterChips<T> extends StatelessWidget {
  const TextFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final List<TextFilterOption<T>> options;
  final T selected;
  final bool enabled;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  /// Legacy label-height bound retained for existing row consumers.
  static const double chipHeight = AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.controlHeightStandard,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final option = options[index];
            return Center(
              child: CivicFilterChip(
                label: option.label,
                selected: option.value == selected,
                onTap: !enabled
                    ? null
                    : () {
                        if (option.value == selected) return;
                        AppHaptics.activate();
                        onSelected(option.value);
                      },
              ),
            );
          },
        ),
      ),
    );
  }
}

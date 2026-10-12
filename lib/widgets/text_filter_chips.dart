import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_haptics.dart';

/// One option in a [TextFilterChips] row.
@immutable
class TextFilterOption<T> {
  const TextFilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// The shared text-only filter chip row (F03): 40px stadium chips with
/// 14px medium labels and no leading icons, a neutral outline when idle and
/// the gold fill with dark ink when selected. The row scrolls horizontally
/// with no visible scrollbar; each chip keeps a 48px touch target even
/// though it draws at 40px.
///
/// Horizontal drags stay with the row and vertical ones go to the list
/// behind it, so pull-to-refresh and the collapsing header keep working.
class TextFilterChips<T> extends StatelessWidget {
  const TextFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final List<TextFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  /// Drawn chip height (web `--space-2xl`).
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
              child: _TextChip(
                label: option.label,
                selected: option.value == selected,
                onTap: () {
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

class _TextChip extends StatelessWidget {
  const _TextChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        // 48px hit area around the 40px drawn chip.
        height: AppDimensions.controlHeightStandard,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotionDuration.standard),
            curve: AppMotionCurve.standard,
            height: TextFilterChips.chipHeight,
            decoration: ShapeDecoration(
              color: selected ? semantic.actionFill : colorScheme.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? semantic.controlBorder
                      : colorScheme.outline,
                ),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: AppFontWeight.medium,
                        color: selected
                            ? semantic.onAction
                            : colorScheme.onSurface,
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

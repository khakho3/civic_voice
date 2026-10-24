import 'package:flutter/material.dart';

/// Shared filter pill, using the accepted alert screen's native selection and
/// checkmark animation. Filter values and single/multiple selection stay with
/// the caller. A null callback disables the entire control while busy.
class CivicFilterChip extends StatelessWidget {
  const CivicFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.leading,
    this.trailing,
    this.picker = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool picker;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animation = reduced
        ? ChipAnimationStyle(
            enableAnimation: AnimationStyle.noAnimation,
            selectAnimation: AnimationStyle.noAnimation,
            avatarDrawerAnimation: AnimationStyle.noAnimation,
            deleteDrawerAnimation: AnimationStyle.noAnimation,
          )
        : null;
    final text = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 4)],
        Text(label),
        if (trailing != null) ...[const SizedBox(width: 4), trailing!],
      ],
    );
    // Picker triggers keep button semantics; choices keep selected semantics.
    // Both use RawChip's native checkmark/drawer motion and the same theme.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: picker
          ? RawChip(
              key: ValueKey(reduced),
              label: text,
              selected: selected,
              showCheckmark: true,
              isEnabled: onTap != null,
              onPressed: onTap,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              chipAnimationStyle: animation,
            )
          : ChoiceChip(
              key: ValueKey(reduced),
              label: text,
              selected: selected,
              showCheckmark: true,
              onSelected: onTap == null ? null : (_) => onTap!(),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              chipAnimationStyle: animation,
            ),
    );
  }
}

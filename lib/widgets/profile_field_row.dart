import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A single label+value row inside a [ProfileSection] — read-only text by
/// default, a real [TextFormField] when [editable]. [locked] is the
/// distinct third state for fields that can never change at all (Employee
/// ID, Assembly) as opposed to fields merely not editable *right now*
/// (admin-set Email/Phone, which get [caption] instead) — things you can't
/// change should visibly say so, not just silently omit an input.
class ProfileFieldRow extends StatelessWidget {
  const ProfileFieldRow({
    super.key,
    required this.label,
    this.value,
    this.controller,
    this.editable = false,
    this.locked = false,
    this.onChanged,
    this.errorText,
    this.caption,
    this.keyboardType,
  }) : assert(
         (value != null) != (controller != null),
         'Pass exactly one of value or controller.',
       );

  final String label;

  /// The display/starting value — mutually exclusive with [controller].
  final String? value;

  /// A persistent controller, for screens that manage edit state that way
  /// (Municipal, Maintenance) rather than a draft-object + [onChanged]
  /// callback (Admin, Ministry) — mutually exclusive with [value].
  final TextEditingController? controller;
  final bool editable;

  /// Visibly muted value text + a small lock glyph next to the label — for
  /// fields that structurally can never change, not just admin-only ones.
  final bool locked;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  /// Shown under a locked/non-editable field to explain why, e.g. "Contact
  /// your administrator to change this." Ignored when [errorText] is set.
  final String? caption;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = errorText != null;
    final displayValue = controller?.text ?? value ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: textTheme.bodySmall),
            if (locked) ...[
              const SizedBox(width: 4),
              Icon(
                AppIcons.security,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        editable
            ? TextFormField(
                controller: controller,
                initialValue: controller == null ? value : null,
                onChanged: onChanged,
                keyboardType: keyboardType,
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error, width: 2),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: hasError
                          ? AppColors.error
                          : colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Text(
                  displayValue,
                  style: textTheme.bodyLarge?.copyWith(
                    color: locked ? colorScheme.onSurfaceVariant : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ] else if (caption != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

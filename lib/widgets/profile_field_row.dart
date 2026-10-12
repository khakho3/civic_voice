import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'profile_section.dart';

/// A single label+value row inside a [ProfileSection] — a 14px secondary
/// label over the value in medium weight, on the row's own surface.
///
/// Profiles are read-only in place: editing happens in the permission-
/// scoped name sheet (`showProfileNameEditSheet`), so most rows only pass
/// [value]. [editable] is kept for the few forms that still host an inline
/// field. [locked] marks fields that structurally never change (Employee
/// ID, Admin ID) with a muted value — no padlock icon — and [caption]
/// explains an administrator-controlled field.
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

  /// A persistent controller for an inline editable field — mutually
  /// exclusive with [value].
  final TextEditingController? controller;
  final bool editable;

  /// Visibly muted value text for fields that structurally can never change.
  final bool locked;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  /// Shown under the value to explain why it is not self-editable, e.g.
  /// "Contact your administrator to change this." Ignored when [errorText]
  /// is set.
  final String? caption;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final displayValue = controller?.text ?? value ?? '';
    final message = errorText ?? caption;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ProfileRowMetrics.minHeight),
      child: Padding(
        padding: ProfileRowMetrics.padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            editable
                ? TextFormField(
                    controller: controller,
                    initialValue: controller == null ? value : null,
                    onChanged: onChanged,
                    keyboardType: keyboardType,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: semantic.focus,
                          width: AppDimensions.borderWidthFocused,
                        ),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: semantic.error),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: semantic.error,
                          width: AppDimensions.borderWidthFocused,
                        ),
                      ),
                    ),
                  )
                : Text(
                    displayValue,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: AppFontWeight.medium,
                      color: locked ? colorScheme.onSurfaceVariant : null,
                    ),
                  ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: textTheme.bodySmall?.copyWith(
                  color: errorText != null
                      ? semantic.errorText
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

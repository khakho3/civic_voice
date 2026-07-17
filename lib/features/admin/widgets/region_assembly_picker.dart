import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';

/// Two-level jurisdiction picker — Region first, then the specific
/// Metropolitan/Municipal/District Assembly within it. The Assembly
/// dropdown is empty/disabled until a Region is chosen, and repopulates
/// from [ghanaAssemblies] every time the Region changes; picking a new
/// Region that doesn't contain the currently-selected [assembly]
/// automatically clears it, so the two fields can never end up
/// contradicting each other.
///
/// Shared by Create User and User Details — both need the same "which
/// assembly is this account scoped to" input.
class RegionAssemblyPicker extends StatelessWidget {
  const RegionAssemblyPicker({
    super.key,
    required this.region,
    required this.assembly,
    required this.onRegionChanged,
    required this.onAssemblyChanged,
    this.regionErrorText,
    this.assemblyErrorText,
  });

  final Region? region;
  final Assembly? assembly;
  final ValueChanged<Region?> onRegionChanged;
  final ValueChanged<Assembly?> onAssemblyChanged;
  final String? regionErrorText;
  final String? assemblyErrorText;

  @override
  Widget build(BuildContext context) {
    final assemblyOptions = region == null
        ? const <Assembly>[]
        : ghanaAssemblies[region] ?? const <Assembly>[];

    return Column(
      children: [
        _Dropdown<Region>(
          label: 'Region',
          hint: 'Select region',
          value: region,
          items: [
            for (final r in Region.values)
              DropdownMenuItem(value: r, child: Text(r.label)),
          ],
          errorText: regionErrorText,
          onChanged: (selected) {
            onRegionChanged(selected);
            if (assembly != null && assembly!.region != selected) {
              onAssemblyChanged(null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _Dropdown<Assembly>(
          label: 'Assembly',
          hint: region == null ? 'Select a region first' : 'Select assembly',
          value: assemblyOptions.contains(assembly) ? assembly : null,
          items: [
            for (final a in assemblyOptions)
              DropdownMenuItem(value: a, child: Text(a.fullName)),
          ],
          errorText: assemblyErrorText,
          onChanged: assemblyOptions.isEmpty ? null : onAssemblyChanged,
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: colorScheme.surfaceContainer,
          borderRadius: AppComponentRadius.inputField,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: hasError
                ? BoxDecoration(
                    borderRadius: AppComponentRadius.inputField,
                    border: Border.all(color: AppColors.error),
                  )
                : null,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                borderRadius: AppComponentRadius.inputField,
                hint: Text(
                  hint,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                icon: Icon(
                  AppIcons.chevronDown,
                  size: AppIconSize.sm,
                  color: colorScheme.onSurfaceVariant,
                ),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.labelSmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

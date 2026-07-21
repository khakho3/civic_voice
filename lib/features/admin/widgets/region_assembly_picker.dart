import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import '../../../widgets/app_dropdown_field.dart';

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
        AppDropdownField<Region>(
          label: 'Region',
          hint: 'Select region',
          value: region,
          items: [
            for (final r in Region.values)
              AppDropdownItem(value: r, label: r.label),
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
        AppDropdownField<Assembly>(
          label: 'Assembly',
          hint: region == null ? 'Select a region first' : 'Select assembly',
          value: assemblyOptions.contains(assembly) ? assembly : null,
          items: [
            for (final a in assemblyOptions)
              AppDropdownItem(value: a, label: a.fullName),
          ],
          errorText: assemblyErrorText,
          onChanged: assemblyOptions.isEmpty ? null : onAssemblyChanged,
        ),
      ],
    );
  }
}

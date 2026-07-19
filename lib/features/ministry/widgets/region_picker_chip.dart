import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';

/// Opens the "All Regions" + all 16 regions picker sheet, returning the
/// selection (`null` for "All Regions") — shared by Municipal Performance
/// and Reports Overview rather than each screen duplicating the same
/// `showModalBottomSheet` call.
///
/// `isScrollControlled: true` + a height-capped `ListView` (not a plain
/// `Column`, which is what this replaced) — 17 rows is taller than a
/// phone screen has room for below the status bar, and a bare `Column`
/// inside `SafeArea` has nothing forcing it to respect that limit, so it
/// silently overflowed rather than scrolling.
Future<Region?> pickRegion(BuildContext context, {required Region? current}) {
  return showModalBottomSheet<Region?>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All Regions'),
              trailing: current == null
                  ? const Icon(AppIcons.success, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop<Region?>(null),
            ),
            for (final region in Region.values)
              ListTile(
                title: Text(region.label),
                trailing: region == current
                    ? const Icon(AppIcons.success, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop<Region?>(region),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A chip that opens a region picker rather than toggling a mutually-
/// exclusive selection in place — a chevron distinguishes it from an
/// ordinary filter/scope chip at a glance, the same "chip as picker
/// trigger" shape already used for date range/category/status pickers on
/// MIN-002/MIN-005. Shared by MIN-003 Municipal Performance and MIN-004
/// Reports Overview, the two screens whose lists are large enough at
/// national scale to need narrowing by region, rather than each
/// reimplementing the same chip.
class RegionPickerChip extends StatelessWidget {
  const RegionPickerChip({
    super.key,
    required this.label,
    required this.active,
    this.onTap,
  });

  final String label;

  /// True once a specific region (not "All Regions") is selected — tints
  /// the chip the same way an actively-selected scope/status chip would.
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = active ? Colors.white : colorScheme.onSurfaceVariant;
    return Material(
      color: active ? AppColors.primary : colorScheme.surfaceContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.municipality,
                size: AppIconSize.sm,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
              const SizedBox(width: 2),
              Icon(
                AppIcons.chevronDown,
                size: AppIconSize.sm,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

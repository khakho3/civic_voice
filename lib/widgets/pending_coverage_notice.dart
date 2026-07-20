import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shown to a citizen when their report's region/assembly has no active
/// Municipal Officer covering it yet — used on both the post-submission
/// confirmation screen and the report tracking screen while the report sits
/// unclaimed. See reports.js's `hasMunicipalCoverage` for how this is
/// computed fresh on every read, so the notice disappears on its own once
/// an officer is provisioned for the area.
class PendingCoverageNotice extends StatelessWidget {
  const PendingCoverageNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.info, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No municipal officer is set up for your area yet. Your '
              "report is saved and will stay pending until one is added — "
              "you don't need to do anything else.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

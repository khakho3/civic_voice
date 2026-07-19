import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A minimal column bar chart — relative bar heights only, no axis/legend.
///
/// Global (`lib/widgets/`) rather than module-scoped: originally duplicated
/// verbatim across MIN-002 Analytics Dashboard and MIN-003 Municipal
/// Performance, promoted here once MIN-005 Report Insights needed the exact
/// same chart a third time — any screen plotting a simple trend row should
/// reuse this rather than reimplementing it per screen.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final calculatedMax = values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxValue = calculatedMax <= 0 ? 1 : calculatedMax;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values) ...[
            Expanded(
              child: FractionallySizedBox(
                heightFactor: value / maxValue,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            if (value != values.last) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

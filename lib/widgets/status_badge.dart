import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/report_severity.dart';
import '../models/report_status.dart';

/// Shared tinted-pill badge shape for [ReportStatusBadge] and
/// [ReportSeverityBadge] — promoted out of the Incoming Reports screen once
/// Report Review needed the same components.
class _TintedBadge extends StatelessWidget {
  const _TintedBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return _TintedBadge(
      label: status.label,
      color: status.color,
      textColor: status.badgeTextColor(brightness),
    );
  }
}

class ReportSeverityBadge extends StatelessWidget {
  const ReportSeverityBadge({super.key, required this.severity, this.suffix});

  final ReportSeverity severity;

  /// Appended to the label, e.g. " Priority" for Report Review's
  /// "High Priority" tag vs. Incoming Reports' bare "High".
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return _TintedBadge(
      label: suffix == null ? severity.label : '${severity.label}$suffix',
      color: severity.color,
      textColor: severity.badgeTextColor(brightness),
    );
  }
}

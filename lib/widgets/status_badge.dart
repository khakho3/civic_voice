import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/report_status.dart';

/// Shared tinted-pill badge shape for [ReportStatusBadge] — promoted out of
/// the Incoming Reports screen once Report Review needed the same
/// component. Public (not module-private) since other modules' own
/// status-like enums (e.g. Maintenance Team's `MaintenanceTaskStatus`) want
/// this exact pill treatment — a tinted, bordered label with no icon mixed
/// in — rather than each module building its own slightly-different badge
/// shape.
class TintedBadge extends StatelessWidget {
  const TintedBadge({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;

  /// Optional leading glyph — most badges stay text-only (the original
  /// intent here), but a few consolidated call sites (unread markers,
  /// verification pills) carry a small icon before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm - 2, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: AppFontWeight.semiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    return TintedBadge(
      label: status.label,
      color: status.color,
      textColor: status.badgeTextColor(brightness),
    );
  }
}

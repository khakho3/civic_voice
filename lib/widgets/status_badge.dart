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
///
/// [color] is the hue for the translucent fill and border. [textColor] is
/// mapped through [AppSemanticColors.foregroundFor], so a caller that
/// passes a raw brand/semantic/status hue (gold, amber, green…) still gets
/// that hue's readable text variant for the current theme; any other color
/// is used as given.
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
    final ink = AppSemanticColors.of(context).foregroundFor(textColor);
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
            Icon(icon, size: AppIconSize.sm - 2, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ink,
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

/// Text-only report status pill. The label carries the meaning (and is
/// what screen readers announce); the hue only tints the fill. Text uses
/// the theme's readable status ink for that hue rather than the hue itself
/// — the raw lifecycle hues are 2–4:1 as text on the tinted fill.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: TintedBadge(
        label: status.label,
        color: status.color,
        textColor: status.color,
      ),
    );
  }
}

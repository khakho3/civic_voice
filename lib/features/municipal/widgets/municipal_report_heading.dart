import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../../../widgets/status_badge.dart';

/// One title/status/reference hierarchy for Home, Inbox, Active and Closed.
/// At large text sizes the status gets its own line instead of squeezing the
/// report title or truncating a lifecycle label.
class MunicipalReportHeading extends StatelessWidget {
  const MunicipalReportHeading({
    super.key,
    required this.title,
    required this.referenceId,
    required this.status,
  });

  final String title;
  final String referenceId;
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleWidget = Text(title, style: textTheme.titleMedium);
    final badge = ReportStatusBadge(status: status, maxLines: 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale =
            MediaQuery.textScalerOf(context).scale(AppFontSize.bodySmall) /
            AppFontSize.bodySmall;
        final stacked =
            constraints.maxWidth / scale < AppBreakpoints.smallMobile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stacked) ...[
              Align(alignment: AlignmentDirectional.centerEnd, child: badge),
              const SizedBox(height: AppSpacing.sm),
              titleWidget,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: AppSpacing.sm),
                  badge,
                ],
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(referenceId, style: textTheme.bodySmall),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum ReportStatus {
  submitted,
  underReview,
  inProgress,
  resolved,
}

extension ReportStatusDetails on ReportStatus {
  String get label {
    return switch (this) {
      ReportStatus.submitted => 'Submitted',
      ReportStatus.underReview => 'Under Review',
      ReportStatus.inProgress => 'In Progress',
      ReportStatus.resolved => 'Resolved',
    };
  }

  IconData get icon {
    return switch (this) {
      ReportStatus.submitted => AppIcons.statusSubmitted,
      ReportStatus.underReview => AppIcons.statusUnderReview,
      ReportStatus.inProgress => AppIcons.statusInProgress,
      ReportStatus.resolved => AppIcons.statusResolved,
    };
  }

  Color color(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    return switch (this) {
      ReportStatus.submitted => colors.statusSubmitted,
      ReportStatus.underReview => colors.statusUnderReview,
      ReportStatus.inProgress => colors.statusInProgress,
      ReportStatus.resolved => colors.statusResolved,
    };
  }
}

class CivicReport {
  const CivicReport({
    required this.title,
    required this.location,
    required this.timeLabel,
    required this.status,
  });

  final String title;
  final String location;
  final String timeLabel;
  final ReportStatus status;
}

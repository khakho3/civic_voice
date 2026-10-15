import 'package:civic_voice/core/theme/app_colors.dart';
import 'package:civic_voice/core/theme/app_icons.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines the seven report lifecycle states in order', () {
    expect(ReportStatus.values, [
      ReportStatus.submitted,
      ReportStatus.underReview,
      ReportStatus.assigned,
      ReportStatus.inProgress,
      ReportStatus.pendingApproval,
      ReportStatus.resolved,
      ReportStatus.rejected,
    ]);
  });

  test('maps pending approval presentation and API values', () {
    final status = ReportStatus.pendingApproval;

    expect(status.label, 'Awaiting Confirmation');
    expect(status.progressPercent, 90);
    expect(status.apiValue, 'PENDING_APPROVAL');
    expect(status.color, AppColors.statusPendingApproval);
    expect(
      status.badgeTextColor(Brightness.light),
      AppColors.statusPendingApprovalTextLight,
    );
    expect(
      status.badgeTextColor(Brightness.dark),
      AppColors.statusPendingApprovalTextDark,
    );
    expect(status.icon, AppIcons.verify);
  });

  test('maps lifecycle progress percentages', () {
    const expectedProgress = {
      ReportStatus.submitted: 15,
      ReportStatus.underReview: 30,
      ReportStatus.assigned: 50,
      ReportStatus.inProgress: 70,
      ReportStatus.pendingApproval: 90,
      ReportStatus.resolved: 100,
      ReportStatus.rejected: 100,
    };

    for (final entry in expectedProgress.entries) {
      expect(entry.key.progressPercent, entry.value, reason: entry.key.name);
    }
  });

  test('keeps resolved and rejected outcomes distinct', () {
    expect(ReportStatus.resolved, isNot(ReportStatus.rejected));
    expect(ReportStatus.resolved.label, 'Resolved');
    expect(ReportStatus.rejected.label, 'Rejected');
    expect(ReportStatus.resolved.apiValue, 'RESOLVED');
    expect(ReportStatus.rejected.apiValue, 'REJECTED');
  });
}

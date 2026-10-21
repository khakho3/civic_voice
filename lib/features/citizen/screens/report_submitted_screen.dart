import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/pending_coverage_notice.dart';
import '../widgets/civic_glass_card.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_tab_routes.dart';
import 'create_report_screen.dart';
import 'report_tracking_screen.dart';

class ReportSubmittedScreen extends StatefulWidget {
  const ReportSubmittedScreen({
    super.key,
    this.referenceNumber,
    this.reportId,
    this.reportTitle,
    this.reportCategory,
    this.reportLocationLabel,
    this.photoCount = 0,
    this.hasMunicipalCoverage,
    this.returnToReports = false,
  });

  static const String routeName = '/citizen/report-submitted';

  final String? referenceNumber;
  final String? reportId;
  final String? reportTitle;
  final String? reportCategory;
  final String? reportLocationLabel;
  final int photoCount;
  final bool? hasMunicipalCoverage;
  final bool returnToReports;

  @override
  State<ReportSubmittedScreen> createState() => _ReportSubmittedScreenState();
}

class _ReportSubmittedScreenState extends State<ReportSubmittedScreen> {
  void _returnToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      citizenDashboardTabRoute(context),
      (route) => false,
    );
  }

  void _openReports() {
    if (widget.returnToReports) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == '/citizen/reports',
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      citizenReportsTabRoute(context),
      (route) => route.isFirst,
    );
  }

  void _submitAnother() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: CreateReportScreen.routeName),
        builder: (_) =>
            CreateReportScreen(returnToReports: widget.returnToReports),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final referenceNumber = widget.referenceNumber?.trim();
    final hasReference = referenceNumber?.isNotEmpty ?? false;
    final hasConfirmedSubmission =
        hasReference && (widget.reportId?.trim().isNotEmpty ?? false);

    final chromeInset = civicContentPadding(context);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      // See create_report_screen.dart's build() for why this is false and
      // paired with the keyboardVisible-guarded nav below.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                chromeInset.top + AppSpacing.xl,
                horizontalPadding,
                chromeInset.bottom + AppSpacing.xl,
              ),
              children: [
                if (hasConfirmedSubmission)
                  const _SuccessIntro()
                else
                  const _SubmissionUnavailableIntro(),
                const SizedBox(height: AppSpacing.xl),
                _ReferenceCard(
                  referenceNumber: hasReference ? referenceNumber : null,
                ),
                if (hasConfirmedSubmission &&
                    (widget.hasMunicipalCoverage == false ||
                    (widget.reportId != null &&
                        widget.hasMunicipalCoverage == null))) ...[
                  const SizedBox(height: AppSpacing.md),
                  PendingCoverageNotice(
                    coverageUnknown: widget.hasMunicipalCoverage == null,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (hasConfirmedSubmission) const _NextInfoCard(),
                const SizedBox(height: AppSpacing.lg),
                _ActionCard(
                  onTrack: hasConfirmedSubmission ? () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportTrackingScreen(
                          reportId: widget.reportId!,
                        ),
                      ),
                    );
                  } : null,
                  onDashboard: _returnToDashboard,
                  onAnother: _submitAnother,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(
              title: hasConfirmedSubmission
                  ? 'Submitted'
                  : 'Submission unavailable',
              showNotifications: false,
            ),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 1,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    _returnToDashboard();
                  } else if (index == 1) {
                    _openReports();
                  } else if (index == 2) {
                    _submitAnother();
                  } else if (index == 3) {
                    Navigator.of(context).pushAndRemoveUntil(
                      citizenAlertsTabRoute(context),
                      (route) => route.isFirst,
                    );
                  } else if (index == 4) {
                    Navigator.of(context).pushAndRemoveUntil(
                      citizenProfileTabRoute(context),
                      (route) => route.isFirst,
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessIntro extends StatelessWidget {
  const _SuccessIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            AppIcons.success,
            color: AppColors.success,
            size: 52,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Report Submitted\nSuccessfully',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppSemanticColors.of(context).actionText,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your report has been received and forwarded to the appropriate authority. You will receive updates as your report progresses.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SubmissionUnavailableIntro extends StatelessWidget {
  const _SubmissionUnavailableIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.info,
            color: AppSemanticColors.of(context).actionText,
            size: 52,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Submission confirmation unavailable',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppSemanticColors.of(context).actionText,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'A completed report was not supplied to this screen.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.referenceNumber});

  final String? referenceNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFERENCE NUMBER',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.7,
              fontWeight: AppFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            referenceNumber ?? 'Reference number unavailable',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextInfoCard extends StatelessWidget {
  const _NextInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.info,
                color: AppSemanticColors.of(context).actionText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'What Happens Next?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _BulletText(
            'A civic administrator will review your report for completeness and category accuracy.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _BulletText(
            "You'll be notified here in the app as your report progresses.",
          ),
          const SizedBox(height: AppSpacing.sm),
          const _BulletText(
            'You can track live status updates through My Reports.',
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '*',
          style: TextStyle(
            color: AppSemanticColors.of(context).actionText,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.onTrack,
    required this.onDashboard,
    required this.onAnother,
  });

  final VoidCallback? onTrack;
  final VoidCallback onDashboard;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onTrack != null) ...[
            FilledButton(
              onPressed: onTrack!,
              child: const Text('Track My Report'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton(
            onPressed: onDashboard,
            child: const Text('Return to Dashboard'),
          ),
          TextButton(
            onPressed: onAnother,
            child: const Text('Submit Another Report'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/civic_glass_card.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';
import 'report_tracking_screen.dart';

class ReportSubmittedScreen extends StatefulWidget {
  const ReportSubmittedScreen({
    super.key,
    this.referenceNumber,
    this.reportTitle,
    this.reportCategory,
    this.reportLocationLabel,
    this.photoCount = 0,
  });

  static const String routeName = '/citizen/report-submitted';

  final String? referenceNumber;
  final String? reportTitle;
  final String? reportCategory;
  final String? reportLocationLabel;
  final int photoCount;

  @override
  State<ReportSubmittedScreen> createState() => _ReportSubmittedScreenState();
}

class _ReportSubmittedScreenState extends State<ReportSubmittedScreen> {
  String? _rating;

  void _copyReference(String referenceNumber) {
    Clipboard.setData(ClipboardData(text: referenceNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference number copied.')),
    );
  }

  void _selectRating(String rating) {
    setState(() => _rating = rating);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final referenceNumber = widget.referenceNumber?.trim().isNotEmpty ?? false
        ? widget.referenceNumber!.trim()
        : 'CV-2026-004582';

    return Scaffold(
      extendBody: true,
      appBar: const CivicTopBar(title: 'Submitted', showNotifications: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.xl,
            horizontalPadding,
            132,
          ),
          children: [
            const _SuccessIntro(),
            const SizedBox(height: AppSpacing.xl),
            _ReferenceCard(
              referenceNumber: referenceNumber,
              onCopy: () => _copyReference(referenceNumber),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _TimelineSection(),
            const SizedBox(height: AppSpacing.xl),
            const _NextInfoCard(),
            const SizedBox(height: AppSpacing.lg),
            _FeedbackCard(selected: _rating, onSelected: _selectRating),
            const SizedBox(height: AppSpacing.lg),
            _ActionCard(
              onTrack: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ReportTrackingScreen(reportId: referenceNumber),
                  ),
                );
              },
              onDashboard: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              onAnother: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  CreateReportScreen.routeName,
                  (route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CivicBottomNav(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              CitizenReportsScreen.routeName,
              (route) => route.isFirst,
            );
          } else if (index == 2) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              CreateReportScreen.routeName,
              (route) => route.isFirst,
            );
          } else if (index == 3) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              CitizenAlertsScreen.routeName,
              (route) => route.isFirst,
            );
          } else if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              CitizenProfileScreen.routeName,
              (route) => route.isFirst,
            );
          }
        },
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
            color: AppColors.primary,
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

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({
    required this.referenceNumber,
    required this.onCopy,
  });

  final String referenceNumber;
  final VoidCallback onCopy;

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
            referenceNumber,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _StatusPill(),
          const SizedBox(height: AppSpacing.sm),
          Text('Submitted just now', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          const _EstimateBox(),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(AppIcons.copy),
            label: const Text('Copy Reference Number'),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.24)),
      ),
      child: Text(
        'Submitted',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.success,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _EstimateBox extends StatelessWidget {
  const _EstimateBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: [
          const Icon(AppIcons.statusUnderReview, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review Estimate', style: theme.textTheme.bodyMedium),
                Text(
                  'Within 24-48 hours',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            'Report Timeline',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _TimelineStep(
          status: _TimelineStatus.done,
          title: 'Report Submitted',
          subtitle: 'Completed just now',
        ),
        const _TimelineStep(
          status: _TimelineStatus.current,
          title: 'Under Review',
          subtitle: 'Estimated: Pending initial validation',
        ),
        const _TimelineStep(
          status: _TimelineStatus.future,
          title: 'Assigned to Department',
        ),
        const _TimelineStep(
          status: _TimelineStatus.future,
          title: 'Resolution in Progress',
        ),
        const _TimelineStep(status: _TimelineStatus.last, title: 'Resolved'),
      ],
    );
  }
}

enum _TimelineStatus { done, current, future, last }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.title,
    this.subtitle,
  });

  final _TimelineStatus status;
  final String title;
  final String? subtitle;

  bool get _active =>
      status == _TimelineStatus.done || status == _TimelineStatus.current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = switch (status) {
      _TimelineStatus.done => AppColors.success,
      _TimelineStatus.current => AppColors.warning,
      _TimelineStatus.future || _TimelineStatus.last =>
        theme.colorScheme.outline,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: status == _TimelineStatus.done
                    ? AppColors.success
                    : theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: status == _TimelineStatus.done
                    ? null
                    : Border.all(color: dotColor, width: 2),
              ),
              child: status == _TimelineStatus.done
                  ? const Icon(AppIcons.success, color: Colors.white, size: 15)
                  : Center(
                      child: status == _TimelineStatus.current
                          ? const Icon(
                              AppIcons.statusUnderReview,
                              color: AppColors.warning,
                              size: 13,
                            )
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
            ),
            if (status != _TimelineStatus.last)
              Container(
                width: 2,
                height: 48,
                color: status == _TimelineStatus.done
                    ? AppColors.success
                    : theme.colorScheme.outline,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _active ? null : theme.colorScheme.secondary,
                    fontWeight: _active
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
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
              const Icon(AppIcons.info, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'What Happens Next?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: AppFontWeight.bold,
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
            'You will receive a push notification and email once your report is assigned.',
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
        const Text(
          '*',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      (AppIcons.error, 'Poor'),
      (AppIcons.warning, 'Average'),
      (AppIcons.success, 'Good'),
      (AppIcons.badgeVerified, 'Excellent'),
    ];

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        children: [
          Text(
            'How was your reporting experience?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: AppFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final option in options)
                _FeedbackOption(
                  icon: option.$1,
                  label: option.$2,
                  selected: selected == option.$2,
                  onTap: () => onSelected(option.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackOption extends StatelessWidget {
  const _FeedbackOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppRadius.allMd,
          border: selected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : theme.colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.onTrack,
    required this.onDashboard,
    required this.onAnother,
  });

  final VoidCallback onTrack;
  final VoidCallback onDashboard;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: onTrack,
            child: const Text('Track My Report'),
          ),
          const SizedBox(height: AppSpacing.sm),
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

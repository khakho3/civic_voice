import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'civic_glass_card.dart';

class NearbySecondingReport {
  const NearbySecondingReport({
    required this.id,
    required this.reference,
    required this.title,
    required this.category,
    required this.distanceMeters,
    required this.seconderCount,
  });

  factory NearbySecondingReport.fromApi(Map<String, dynamic> json) {
    return NearbySecondingReport(
      id: json['id'] as String,
      reference: json['publicReference'] as String? ?? '',
      title: json['title'] as String? ?? 'Community issue',
      category: json['category'] as String? ?? 'General',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      seconderCount: (json['seconderCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String reference;
  final String title;
  final String category;
  final double distanceMeters;
  final int seconderCount;
}

class NearbySecondingCard extends StatelessWidget {
  const NearbySecondingCard({
    super.key,
    required this.report,
    required this.onConfirm,
    required this.onNotSure,
    this.busy = false,
  });

  final NearbySecondingReport report;
  final VoidCallback onConfirm;
  final VoidCallback onNotSure;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundedDistance = report.distanceMeters.round();

    return CivicGlassCard(
      key: ValueKey('nearby-seconding-${report.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(AppIcons.location, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Can you confirm this nearby report?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${report.category} · ${roundedDistance}m away',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(report.title, style: theme.textTheme.bodyLarge),
          if (report.reference.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              report.reference,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onNotSure,
                  child: const Text('Not sure'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onConfirm,
                  child: busy
                      ? const SizedBox.square(
                          dimension: AppIconSize.sm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Confirm it's still there"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

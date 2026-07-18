import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/municipal_performance_data.dart';

/// Drill-down opened from a Municipal Performance "Regional Leaders" row or
/// a Dashboard "Municipality Performance" row — the actual next step a
/// Ministry Supervisor takes once a performance number looks bad: a short
/// stats recap plus the assigned Municipal Officer's contact details, with
/// real Call/Message actions rather than another chart. Not spec'd as a
/// numbered MIN screen (it postdates the original Figma export), so it
/// follows the same no-bottom-nav drill-down shape as MIN-005 Report
/// Insights — [DetailHeader] + a back arrow to whichever screen opened it.
class MinistryMunicipalityDetailScreen extends StatelessWidget {
  const MinistryMunicipalityDetailScreen({
    super.key,
    required this.municipality,
    this.onBack,
  });

  final RegionalLeaderItem municipality;
  final VoidCallback? onBack;

  Future<void> _call(BuildContext context) => _launch(
    context,
    Uri(scheme: 'tel', path: municipality.officerPhone.replaceAll(' ', '')),
  );

  Future<void> _message(BuildContext context) => _launch(
    context,
    Uri(scheme: 'sms', path: municipality.officerPhone.replaceAll(' ', '')),
  );

  Future<void> _launch(BuildContext context, Uri uri) async {
    // A device/platform with no tel:/sms: handler (or, in tests, no plugin
    // implementation registered at all) throws rather than just returning
    // false — caught here so a missing handler surfaces as the same inline
    // "couldn't open" message instead of crashing the screen.
    var launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme} on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                DetailHeader.topInset(context) + AppSpacing.md,
                AppSpacing.md,
                bottomInset + AppSpacing.xl,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        municipality.region.label,
                        style: textTheme.bodySmall,
                      ),
                    ),
                    if (municipality.needsAttention)
                      _AttentionBadge(color: municipality.rankColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(municipality.name, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.resolutionGauge,
                          tint: municipality.rankColor,
                          label: 'Resolved',
                          value: '${municipality.resolvedPercent}%',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.responseTime,
                          tint: AppColors.primary,
                          label: 'Avg Response',
                          value: municipality.responseTimeLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Municipal Officer', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _OfficerContactCard(
                  municipality: municipality,
                  onCall: () => _call(context),
                  onMessage: () => _message(context),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(title: municipality.name, onBack: onBack),
          ),
        ],
      ),
    );
  }
}

class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        'Needs Attention',
        style: textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.lg,
            height: AppIconSize.lg,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: AppIconSize.sm + 2, color: tint),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(value, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// The screen's whole reason for existing — name, phone, and two real
/// actions front and center, not buried under analytics.
class _OfficerContactCard extends StatelessWidget {
  const _OfficerContactCard({
    required this.municipality,
    required this.onCall,
    required this.onMessage,
  });

  final RegionalLeaderItem municipality;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.xl,
                height: AppIconSize.xl,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.municipalOfficer,
                  size: AppIconSize.md,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      municipality.officerName,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      municipality.officerPhone,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(AppIcons.sms, size: AppIconSize.sm),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(AppIcons.phone, size: AppIconSize.sm),
                  label: const Text('Call'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

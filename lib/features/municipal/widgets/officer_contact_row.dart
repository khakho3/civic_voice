import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

/// Compact "which officer is handling this" row — a name plus real Call/
/// Message actions, reused across the report-detail screens (Report
/// Review, Verification, Assign Team, Report Progress) so anyone opening
/// a report (a Maintenance Team, another officer, Ministry) can see who
/// to reach without a separate lookup. Deliberately just a name and two
/// icon buttons, not a full contact card — [MinistryMunicipalityDetailScreen]
/// already owns that fuller "contact this officer" surface; this is a tiny
/// indication, not a second version of it.
class OfficerContactRow extends StatelessWidget {
  const OfficerContactRow({
    super.key,
    required this.officerName,
    required this.officerPhone,
  });

  final String officerName;
  final String officerPhone;

  Future<void> _call(BuildContext context) =>
      _launch(context, Uri(scheme: 'tel', path: _digits));

  Future<void> _message(BuildContext context) =>
      _launch(context, Uri(scheme: 'sms', path: _digits));

  String get _digits => officerPhone.replaceAll(' ', '');

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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          AppIcons.municipalOfficer,
          size: AppIconSize.sm,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Officer',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                officerName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: AppFontWeight.medium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Message $officerName',
          icon: const Icon(AppIcons.sms, size: AppIconSize.sm),
          onPressed: () => _message(context),
        ),
        IconButton(
          tooltip: 'Call $officerName',
          icon: const Icon(AppIcons.phone, size: AppIconSize.sm),
          onPressed: () => _call(context),
        ),
      ],
    );
  }
}

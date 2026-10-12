import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_haptics.dart';
import 'profile_section.dart';

/// Shared layout for every Profile preference row (P03): a deliberate
/// leading category icon, the label (with an optional caption), and a
/// trailing control — chevron, switch, badge or status text — all on the
/// same 16px inset and 64px height as the other Profile rows, so labels,
/// captions and trailing controls align across rows and roles.
class ProfilePreferenceRow extends StatelessWidget {
  const ProfilePreferenceRow({
    super.key,
    required this.icon,
    required this.label,
    this.caption,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Mutes the label for a preference that is unavailable here.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Transparent Material so the row works on its own (ListTile needs a
    // Material ancestor) and inherits the grouped tile's surface.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: ProfilePreferenceRow.contentPadding,
        minTileHeight: ProfileRowMetrics.minHeight,
        enabled: enabled,
        leading: ProfilePreferenceRow.leadingIcon(context, icon),
        title: Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            color: enabled ? null : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: caption == null
            ? null
            : Text(
                caption!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: trailing,
        onTap: onTap == null
            ? null
            : () {
                AppHaptics.activate();
                onTap!();
              },
      ),
    );
  }

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
  );

  /// The leading glyph every preference row uses: 24px, secondary ink.
  static Widget leadingIcon(BuildContext context, IconData icon) => Icon(
    icon,
    size: AppIconSize.standard,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// A [ProfilePreferenceRow] whose trailing control is a switch. Built on
/// [SwitchListTile] so the whole row toggles and is announced as one
/// switch.
class ProfileSwitchRow extends StatelessWidget {
  const ProfileSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
    this.labelTrailing,
    this.pulseOnToggle = true,
  });

  final IconData icon;
  final String label;
  final bool value;

  /// Whether toggling plays the activation pulse. The haptics row itself
  /// turns this off so switching haptics *off* never buzzes.

  /// Null disables the switch (checking, unavailable, saving).
  final ValueChanged<bool>? onChanged;
  final String? caption;

  /// Inline widget after the label, e.g. an information button.
  final Widget? labelTrailing;
  final bool pulseOnToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final title = Text(
      label,
      style: textTheme.bodyLarge?.copyWith(
        color: onChanged == null ? colorScheme.onSurfaceVariant : null,
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: ProfilePreferenceRow.contentPadding,
        minTileHeight: ProfileRowMetrics.minHeight,
        secondary: ProfilePreferenceRow.leadingIcon(context, icon),
        title: labelTrailing == null
            ? title
            : Row(
                children: [
                  Flexible(child: title),
                  const SizedBox(width: AppSpacing.xs),
                  labelTrailing!,
                ],
              ),
        subtitle: caption == null
            ? null
            : Text(
                caption!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        value: value,
        onChanged: onChanged == null
            ? null
            : (next) {
                if (pulseOnToggle) AppHaptics.activate();
                onChanged!(next);
              },
      ),
    );
  }
}

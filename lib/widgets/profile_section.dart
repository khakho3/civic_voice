import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// One grouped list of Profile rows: an optional plain inset label above
/// rows that sit on their own row surfaces, 2px apart, with coordinated
/// corners (rounded top on the first row, rounded bottom on the last, small
/// radii between). Matches the accepted compact grouped-list Profile (web
/// `profile-components.css`).
///
/// Section labels are text only — the rows carry the icons — and a section
/// may be untitled (About/Change password groups). Every row widget
/// ([ProfileFieldRow], [ProfileActionRow], the preference rows) owns its
/// own 16px inset and 64px minimum height, so the tile here is only the
/// shape. Never glass: a row can host an input.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    this.title,
    this.trailing,
    required this.children,
  });

  /// Plain section label; omit for an untitled group.
  final String? title;

  /// Optional control beside the label, e.g. a [ProfileInfoButton].
  final Widget? trailing;
  final List<Widget> children;

  /// Vertical gap between rows of one section.
  static const double rowGap = AppSpacing.xs / 2;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final rows = children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || trailing != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: title == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: AppFontWeight.medium,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: rowGap),
          ProfileGroupTile(
            position: ProfileGroupPosition.of(i, rows.length),
            child: rows[i],
          ),
        ],
      ],
    );
  }
}

/// Where a tile sits in its group, which decides its corners.
enum ProfileGroupPosition {
  only,
  first,
  middle,
  last;

  static ProfileGroupPosition of(int index, int count) {
    if (count == 1) return only;
    if (index == 0) return first;
    if (index == count - 1) return last;
    return middle;
  }

  BorderRadius get radius {
    const outer = Radius.circular(AppRadius.md);
    const inner = Radius.circular(AppRadius.xs);
    return switch (this) {
      only => const BorderRadius.all(outer),
      first => const BorderRadius.vertical(top: outer, bottom: inner),
      middle => const BorderRadius.all(inner),
      last => const BorderRadius.vertical(top: inner, bottom: outer),
    };
  }
}

/// The shaped row surface used by [ProfileSection], also used directly for
/// a standalone row (the logout action). Clips ink so a tappable row's
/// ripple follows the coordinated corners.
class ProfileGroupTile extends StatelessWidget {
  const ProfileGroupTile({
    super.key,
    this.position = ProfileGroupPosition.only,
    required this.child,
  });

  final ProfileGroupPosition position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppSemanticColors.of(context).profileRowSurface,
      shape: RoundedRectangleBorder(borderRadius: position.radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Shared inset/height for every Profile row so labels, captions, icons
/// and trailing controls line up across rows and roles.
abstract final class ProfileRowMetrics {
  const ProfileRowMetrics._();

  static const double minHeight = AppSpacing.xxxxl;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );
}
